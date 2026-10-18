#!/usr/bin/env python3
"""iTunes Smart Playlist Synchronizer for OpenMediaVault / Docker Media Services."""

from __future__ import annotations

import argparse
from datetime import datetime
import hashlib
import os
from pathlib import Path
import plistlib
import shutil
import sys
import tarfile
from urllib.parse import unquote, urlparse

# --- Defaults ---
SERVER_BASE_DIRS = {
    "omv": Path("/mnt/storage/media/music"),
    "pve": Path("/mnt/pve-sata-ssd/ssd-media/media/music"),
}

BACKUPS_TO_KEEP = 3

CANDIDATE_XML_NAMES = [
    "iTunes Music Library.xml",
    "iTunes Library.xml",
    "Library.xml",
    "library.xml",
]

EXCLUDE_NAMES = {
    "Library",
    "Music",
    "Movies",
    "TV Shows",
    "Podcasts",
    "Audiobooks",
    "Genius",
    "All Songs",
    "Dead Tracks",
}


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Convert iTunes Smart Playlists to relative UTF-8 M3U8 files.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )

    parser.add_argument(
        "-s",
        "--server",
        choices=["omv", "pve"],
        default="omv",
        help="Target server profile controlling default base directory.",
    )
    parser.add_argument(
        "-f",
        "--force",
        action="store_true",
        help="Force regeneration of playlists even if the XML hash has not changed.",
    )
    parser.add_argument(
        "-m",
        "--music-dir",
        type=Path,
        default=None,
        help="Custom root path for music tracks (prefixes playlists with '<music-dir>/music/').",
    )
    parser.add_argument(
        "-p",
        "--playlists-dir",
        type=Path,
        default=None,
        help="Directory where output .m3u8 files are stored (defaults to <base-dir>/playlists).",
    )
    parser.add_argument(
        "-x",
        "--xml-file",
        type=Path,
        default=None,
        help="Full path to iTunes library XML file. If omitted, checks <base-dir>/library/.",
    )
    parser.add_argument(
        "--uid",
        type=int,
        default=int(os.environ.get("PUID", 1000)),
        help="User ID to apply when running with root privileges.",
    )
    parser.add_argument(
        "--gid",
        type=int,
        default=int(os.environ.get("PGID", 100)),
        help="Group ID to apply when running with root privileges.",
    )

    return parser.parse_args()


def safe_chown(path: Path, uid: int = 1000, gid: int = 100):
    if hasattr(os, "geteuid") and os.geteuid() == 0:
        try:
            os.chown(path, uid, gid)
        except OSError:
            pass


def resolve_xml_path(
    explicit_xml: Path | None,
    fallback_library_dir: Path,
) -> Path | None:
    if explicit_xml:
        expanded = explicit_xml.expanduser()
        return expanded if expanded.is_file() else None

    # Check candidate names directly
    for name in CANDIDATE_XML_NAMES:
        candidate = fallback_library_dir / name
        if candidate.is_file():
            return candidate

    # Case-insensitive fallback lookup in library folder
    if fallback_library_dir.is_dir():
        candidate_lower = {name.lower(): name for name in CANDIDATE_XML_NAMES}
        for entry in fallback_library_dir.iterdir():
            if entry.is_file() and entry.name.lower() in candidate_lower:
                return entry

    return None


def calculate_sha256(file_path: Path) -> str:
    # Use C-accelerated file_digest on Python 3.11+
    if hasattr(hashlib, "file_digest"):
        with open(file_path, "rb") as f:
            return hashlib.file_digest(f, "sha256").hexdigest()

    hasher = hashlib.sha256()
    with open(file_path, "rb") as f:
        while chunk := f.read(65536):
            hasher.update(chunk)
    return hasher.hexdigest()


def has_valid_playlists(playlists_dir: Path) -> bool:
    if not playlists_dir.is_dir():
        return False
    return any(playlists_dir.glob("*.m3u*"))


def clean_url_path(url_str: str) -> str:
    raw = unquote(urlparse(url_str).path)
    if len(raw) > 2 and raw[2] == ":":
        raw = raw[1:]
    return raw.rstrip("/")


def sync_playlists():
    args = parse_arguments()
    base_dir_selected = SERVER_BASE_DIRS[args.server]

    # 1. Resolve target directories
    playlists_dir = (
        args.playlists_dir.expanduser()
        if args.playlists_dir
        else base_dir_selected / "playlists"
    ).resolve()
    fallback_lib_dir = (base_dir_selected / "library").resolve()

    xml_path = resolve_xml_path(args.xml_file, fallback_lib_dir)
    if not xml_path:
        if args.xml_file:
            print(
                f"Error: Specified XML file not found at: "
                f"{args.xml_file.expanduser()}"
            )
        else:
            candidates_str = ", ".join(f"'{c}'" for c in CANDIDATE_XML_NAMES)
            print(
                f"Error: No iTunes XML found in {fallback_lib_dir}. "
                f"Checked: {candidates_str}"
            )
        sys.exit(1)

    xml_path = xml_path.resolve()
    hash_file = playlists_dir / f"{xml_path.name}.hash"
    current_hash = calculate_sha256(xml_path)
    stored_hash = hash_file.read_text().strip() if hash_file.is_file() else ""

    playlists_intact = has_valid_playlists(playlists_dir)

    if not args.force and current_hash == stored_hash and playlists_intact:
        print(
            f"No changes detected in '{xml_path.name}' "
            f"and playlists are present. Exiting."
        )
        sys.exit(0)

    if args.force:
        print(
            f"Force run enabled. Rebuilding playlists from '{xml_path}'..."
        )
    elif not playlists_intact and current_hash == stored_hash:
        print(
            f"Playlists directory '{playlists_dir.name}' "
            f"missing or empty. Generating playlists..."
        )
    else:
        print(f"New hash detected for '{xml_path.name}'. Parsing library...")

    with open(xml_path, "rb") as f:
        plist = plistlib.load(f)

    # 2. Extract base music folder prefix
    music_folder_url = plist.get("Music Folder")
    music_folder_prefix = (
        clean_url_path(music_folder_url) if music_folder_url else None
    )

    # 3. Map Track IDs to uniform relative paths
    tracks = {}
    for track_id, track in plist.get("Tracks", {}).items():
        location = track.get("Location")
        if not location:
            continue

        raw_path = clean_url_path(location)

        if music_folder_prefix and raw_path.startswith(music_folder_prefix):
            rel_str = raw_path[len(music_folder_prefix):].lstrip("/")
        else:
            parts = Path(raw_path).parts
            lower_parts = [p.lower() for p in parts]
            if "music" in lower_parts:
                last_idx = (
                    len(lower_parts) - 1 - lower_parts[::-1].index("music")
                )
                rel_str = "/".join(parts[last_idx + 1:])
            else:
                rel_str = "/".join(parts[-3:])

        rel_parts = Path(rel_str).parts
        if rel_parts and rel_parts[0].lower() == "music":
            rel_parts = rel_parts[1:]

        tracks[int(track_id)] = Path(*rel_parts).as_posix()

    # 4. Create isolated staging directory
    base_dir = playlists_dir.parent
    base_dir.mkdir(parents=True, exist_ok=True)
    safe_chown(base_dir, args.uid, args.gid)

    staging_dir = base_dir / f"{playlists_dir.name}_staging"
    if staging_dir.exists():
        shutil.rmtree(staging_dir)
    staging_dir.mkdir(parents=True, exist_ok=True)
    safe_chown(staging_dir, args.uid, args.gid)

    # 5. Determine prefix
    if args.music_dir:
        custom_base = str(args.music_dir).rstrip("/")
        music_prefix = f"{custom_base}/music"
    else:
        music_prefix = "../music"

    # 6. Extract and write Smart Playlists
    created_count = 0
    try:
        for pl in plist.get("Playlists", []):
            name = pl.get("Name", "").strip()
            if not name or name in EXCLUDE_NAMES or pl.get("Folder"):
                continue

            is_smart = "Smart Info" in pl
            items = pl.get("Playlist Items", [])

            if is_smart and items:
                safe_name = "".join(
                    c
                    for c in name
                    if c.isalnum() or c in (" ", "-", "_", ".")
                ).strip()
                playlist_file = staging_dir / f"{safe_name}.m3u8"

                with open(playlist_file, "w", encoding="utf-8") as out:
                    out.write("#EXTM3U\n")
                    for item in items:
                        tid = item.get("Track ID")
                        if tid in tracks:
                            out.write(f"{music_prefix}/{tracks[tid]}\n")

                safe_chown(playlist_file, args.uid, args.gid)
                created_count += 1

    except Exception as e:
        print(
            f"Error during playlist generation: {e}. "
            f"Aborting without altering existing playlists."
        )
        if staging_dir.exists():
            shutil.rmtree(staging_dir)
        sys.exit(1)

    # 7. Swap directories and archive previous playlists with rollback safety
    temp_old_dir = base_dir / f"{playlists_dir.name}_pending_backup"
    if temp_old_dir.exists():
        shutil.rmtree(temp_old_dir)

    has_existing_data = (
        playlists_dir.is_dir() and any(playlists_dir.iterdir())
    )

    try:
        if has_existing_data:
            shutil.move(str(playlists_dir), str(temp_old_dir))
        elif playlists_dir.exists():
            playlists_dir.rmdir()

        shutil.move(str(staging_dir), str(playlists_dir))
        safe_chown(playlists_dir, args.uid, args.gid)
    except Exception as swap_err:
        print(f"Error during directory swap: {swap_err}. Rolling back...")
        if temp_old_dir.exists() and not playlists_dir.exists():
            shutil.move(str(temp_old_dir), str(playlists_dir))
        if staging_dir.exists():
            shutil.rmtree(staging_dir)
        sys.exit(1)

    if has_existing_data:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        archive_name = f"{playlists_dir.name}_backup_{timestamp}.tar.gz"
        archive_path = base_dir / archive_name

        with tarfile.open(archive_path, "w:gz") as tar:
            tar.add(temp_old_dir, arcname=playlists_dir.name)

        safe_chown(archive_path, args.uid, args.gid)
        shutil.rmtree(temp_old_dir)
        print(
            f"Archived previous playlist generation to '{archive_path.name}'."
        )

        # Keep only the newest backups, sorted by filename timestamp.
        backups = sorted(
            (
                path
                for path in base_dir.glob(
                    f"{playlists_dir.name}_backup_*.tar.gz"
                )
                if path.is_file()
            ),
            key=lambda path: path.name,
            reverse=True,
        )

        for old_backup in backups[BACKUPS_TO_KEEP:]:
            try:
                old_backup.unlink()
                print(f"Deleted old backup '{old_backup.name}'.")
            except OSError as e:
                print(
                    f"Warning: Could not delete old backup "
                    f"'{old_backup.name}': {e}"
                )

    # 8. Save visible hash inside playlists directory
    final_hash_file = playlists_dir / f"{xml_path.name}.hash"
    final_hash_file.write_text(current_hash)
    safe_chown(final_hash_file, args.uid, args.gid)

    print(
        f"Successfully processed {created_count} "
        f"smart playlists into {playlists_dir}."
    )


if __name__ == "__main__":
    sync_playlists()
