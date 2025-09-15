-- Pull in the wezterm API
local wezterm = require("wezterm")
local target_triple = wezterm.target_triple

-- This will hold the configuration.
local config = wezterm.config_builder()

-- plugins
local bar = wezterm.plugin.require("https://github.com/adriankarlen/bar.wezterm")
-- local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")

-- Import our new module appearance.lua (put this near the top of your wezterm.lua)
local appearance = require("appearance")

-- Use it!
if appearance.is_dark() then
	config.color_scheme = "Catppuccin Mocha"
	-- config.color_scheme = "Tokyo Night"
else
	config.color_scheme = "Catppuccin Latte"
end

config.bold_brightens_ansi_colors = true

if target_triple == "aarch64-apple-darwin" or target_triple == "x86_64-apple-darwin" then
	-- macOS specific configurations
	config.font = wezterm.font("JetBrainsMono Nerd Font")
	config.font_size = 14

	config.window_decorations = "MACOS_FORCE_ENABLE_SHADOW | RESIZE"

	if target_triple == "aarch64-apple-darwin" then
		config.window_background_opacity = 0.95
		config.macos_window_background_blur = 10
	end
	config.send_composed_key_when_right_alt_is_pressed = true

	config.initial_rows = 65
	config.initial_cols = 120
elseif target_triple == "x86_64-unknown-linux-gnu" then
	-- Linux specific configurations
	config.font = wezterm.font("JetBrains Mono Nerd Font")
	config.font_size = 11

	-- config.window_background_opacity = 0.95
	-- config.text_min_contrast_ratio = 4.5
	-- config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
	-- config.window_decorations = "RESIZE"
	-- config.integrated_title_button_style = "Gnome"

	-- config.initial_rows = 28
	-- config.initial_cols = 100
else
	-- Default configurations for other platforms
	config.font_size = 11
end

-- Configura leader key to be CTRL+F
config.leader = { key = "f", mods = "CTRL", timeout_milliseconds = 1000 }

-- shortcut function for pane movement in config.keys
local function move_pane(key, direction)
	return {
		key = key,
		mods = "CTRL",
		action = wezterm.action.ActivatePaneDirection(direction),
	}
end

-- function to get in to pane resize mode
local function resize_pane(key, direction)
	return {
		key = key,
		action = wezterm.action.AdjustPaneSize({ direction, 3 }),
	}
end

-- resize panes key tables
config.key_tables = {
	resize_panes = {
		resize_pane("j", "Down"),
		resize_pane("k", "Up"),
		resize_pane("h", "Left"),
		resize_pane("l", "Right"),
	},
}

-- Table mapping keypresses to actions
config.keys = {

	-- As Ctrl+F is leader, to actually send a Ctrl+A, press it twice
	{
		key = "f",
		-- When we're in leader mode _and_ CTRL + A is pressed...
		mods = "LEADER|CTRL",
		-- Actually send CTRL + A key to the terminal
		action = wezterm.action.SendKey({ key = "a", mods = "CTRL" }),
	},

	-- Pane navigation: vim motion/tmux to move between panes
	move_pane("j", "Down"),
	move_pane("k", "Up"),
	move_pane("h", "Left"),
	move_pane("l", "Right"),

	-- Config: Super + , to open wezterm configuration
	{
		key = ",",
		mods = "SUPER",
		action = wezterm.action.SpawnCommandInNewTab({
			cwd = wezterm.home_dir,
			args = { "nvim", wezterm.config_file },
		}),
	},

	-- Pane split: terminal pane split shortcuts
	{
		-- Horizontal split (creates new tab side by side)
		key = "v",
		mods = "LEADER",
		action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		-- Vertical split (window above/blelow)
		key = "h",
		mods = "LEADER",
		action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},

	-- Resize panes
	{
		-- When we push LEADER + R...
		key = "r",
		mods = "LEADER",
		-- Activate the `resize_panes` keytable
		action = wezterm.action.ActivateKeyTable({
			name = "resize_panes",
			-- Ensures the keytable stays active after it handles its first keypress
			one_shot = false,
			-- Deactivate the keytable after a timeout of 1sec
			timeout_milliseconds = 1000,
		}),
	},
}

-- plugins application to config
bar.apply_to_config(config, {
	--	padding = {
	--	left = 1,
	--	right = 1,
	--	tabs = {
	--		left = 0,
	--		right = 2,
	--	},
	--},
	modules = {
		spotify = {
			enabled = false,
		},
		tabs = {
			active_tab_fg = 4,
			inactive_tab_fg = 6,
			new_tab_fg = 2,
		},
		workspace = {
			enabled = false,
			color = 8,
		},
		leader = {
			enabled = true,
			color = 2,
		},
		zoom = {
			enabled = false,
			color = 4,
		},
		pane = {
			enabled = true,
			color = 7,
		},
		username = {
			enabled = true,
			color = 6,
		},
		hostname = {
			enabled = false,
			color = 8,
		},
		clock = {
			enabled = true,
			format = "%H:%M",
			color = 5,
		},
		cwd = {
			enabled = false,
			color = 7,
		},
	},
})

-- tabline.apply_to_config(config)

-- Finally, return the configuration to wezterm:
return config
