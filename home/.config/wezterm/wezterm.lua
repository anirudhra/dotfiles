local wezterm = require("wezterm")
local target_triple = wezterm.target_triple
local mux = wezterm.mux
local config = wezterm.config_builder()

-- RENDERING & ANIMATION OPTIMIZATIONS
-- WebGpu is the modern cross-platform standard (Metal on macOS, Vulkan/OpenGL on Linux)
config.front_end = "WebGpu"
--config.term = "wezterm"

-- These settings prevent WezTerm from batching/throttling updates
-- which is what usually kills animations in the terminal.
-- In wezterm.lua
config.animation_fps = 120
config.max_fps = 120
-- config.webgpu_power_preference = "HighPerformance"

-- Enables Synchronized Updates (CSI 2026) required for Noice.nvim animations
config.enable_csi_u_key_encoding = true

-- Import appearance module
local appearance = require("appearance")
local bar = wezterm.plugin.require("https://github.com/adriankarlen/bar.wezterm")

if appearance.is_dark() then
	config.color_scheme = "Catppuccin Mocha"
else
	config.color_scheme = "Catppuccin Latte"
end

config.bold_brightens_ansi_colors = true

-- PLATFORM SPECIFIC CONFIGS
-- We pass true as the 4th argument to :find() to perform a raw text search.
-- This safely catches both x86_64-apple-darwin and aarch64-apple-darwin.
if target_triple:find("apple", 1, true) then
	config.font = wezterm.font("JetBrainsMono Nerd Font")
	config.font_size = 14
	config.window_decorations = "MACOS_FORCE_ENABLE_SHADOW | RESIZE"
	config.window_background_opacity = 0.95
	config.macos_window_background_blur = 10
	config.send_composed_key_when_right_alt_is_pressed = true
elseif target_triple:find("linux", 1, true) then
	config.font = wezterm.font("MesloLGS Nerd Font")
	config.font_size = 11
	wezterm.on("gui-startup", function(cmd)
		local tab, pane, window = mux.spawn_window(cmd or {})
		window:gui_window():maximize()
	end)
end

-- 3. KEYBINDINGS AND OTHER SETTINGS
config.leader = { key = "f", mods = "CTRL", timeout_milliseconds = 1000 }

local function move_pane(key, direction)
	return { key = key, mods = "CTRL", action = wezterm.action.ActivatePaneDirection(direction) }
end

local function resize_pane(key, direction)
	return { key = key, action = wezterm.action.AdjustPaneSize({ direction, 3 }) }
end

config.key_tables = {
	resize_panes = {
		resize_pane("j", "Down"),
		resize_pane("k", "Up"),
		resize_pane("h", "Left"),
		resize_pane("l", "Right"),
	},
}

config.keys = {
	{ key = "f", mods = "LEADER|CTRL", action = wezterm.action.SendKey({ key = "a", mods = "CTRL" }) },
	move_pane("j", "Down"),
	move_pane("k", "Up"),
	move_pane("h", "Left"),
	move_pane("l", "Right"),
	{
		key = ",",
		mods = "SUPER",
		action = wezterm.action.SpawnCommandInNewTab({
			cwd = wezterm.home_dir,
			args = { "nvim", wezterm.config_file },
		}),
	},
	{ key = "v", mods = "LEADER", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "h", mods = "LEADER", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{
		key = "r",
		mods = "LEADER",
		action = wezterm.action.ActivateKeyTable({
			name = "resize_panes",
			one_shot = false,
			timeout_milliseconds = 1000,
		}),
	},
}

bar.apply_to_config(config, {
	modules = {
		spotify = { enabled = false },
		tabs = { active_tab_fg = 4, inactive_tab_fg = 6, new_tab_fg = 2 },
		workspace = { enabled = false, color = 8 },
		leader = { enabled = true, color = 2 },
		zoom = { enabled = false, color = 4 },
		pane = { enabled = true, color = 7 },
		username = { enabled = true, color = 6 },
		hostname = { enabled = false, color = 8 },
		clock = { enabled = true, format = "%H:%M", color = 5 },
		cwd = { enabled = false, color = 7 },
	},
})

return config
