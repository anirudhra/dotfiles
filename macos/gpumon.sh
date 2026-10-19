#!/bin/bash
# (c) Anirudh Acharya
# Wrapper around gpu.sh for continuous monitoring
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/gpu.sh" --watch "$@"
