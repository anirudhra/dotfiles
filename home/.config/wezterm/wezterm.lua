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
else
	config.color_scheme = "Catppuccin Latte"
end

-- config.font = wezterm.font("JetBrains Mono Nerd Font")

if target_triple:find("apple-darwin") then
	-- macOS specific configurations
	config.font = wezterm.font("JetBrainsMono Nerd Font")
	config.font_size = 18
	config.macos_window_background_blur = 10
	config.send_composed_key_when_right_alt_is_pressed = true
	config.initial_rows = 48
	config.initial_cols = 150
	config.window_decorations = "MACOS_FORCE_ENABLE_SHADOW | RESIZE"
elseif target_triple:find("linux") then
	-- Linux specific configurations
	config.font = wezterm.font("JetBrains Mono Nerd Font")
	config.window_background_opacity = 0.9
	config.font_size = 11
	--config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
	-- config.window_decorations = "RESIZE"
	-- config.integrated_title_button_style = "Gnome"
	-- config.initial_rows = 28
	-- config.initial_cols = 100
else
	-- Default configurations for other platforms
	config.font_size = 11
end

-- Powerline statusbar on top right tab bar
local function segments_for_right_status(window)
	return {
		wezterm.strftime("%a %b %-d %H:%M"),
		wezterm.hostname(),
	}
end

wezterm.on("update-status", function(window, _)
	local SOLID_LEFT_ARROW = utf8.char(0xe0b2)
	local segments = segments_for_right_status(window)

	local color_scheme = window:effective_config().resolved_palette
	-- Note the use of wezterm.color.parse here, this returns
	-- a Color object, which comes with functionality for lightening
	-- or darkening the colour (amongst other things).
	local bg = wezterm.color.parse(color_scheme.background)
	local fg = color_scheme.foreground

	-- Each powerline segment is going to be coloured progressively
	-- darker/lighter depending on whether we're on a dark/light colour
	-- scheme. Let's establish the "from" and "to" bounds of our gradient.
	local gradient_to, gradient_from = bg, bg
	if appearance.is_dark() then
		gradient_from = gradient_to:lighten(0.2)
	else
		gradient_from = gradient_to:darken(0.2)
	end

	-- Yes, WezTerm supports creating gradients, because why not?! Although
	-- they'd usually be used for setting high fidelity gradients on your terminal's
	-- background, we'll use them here to give us a sample of the powerline segment
	-- colours we need.
	local gradient = wezterm.color.gradient(
		{
			orientation = "Horizontal",
			colors = { gradient_from, gradient_to },
		},
		#segments -- only gives us as many colours as we have segments.
	)

	-- We'll build up the elements to send to wezterm.format in this table.
	local elements = {}

	for i, seg in ipairs(segments) do
		local is_first = i == 1

		if is_first then
			table.insert(elements, { Background = { Color = "none" } })
		end
		table.insert(elements, { Foreground = { Color = gradient[i] } })
		table.insert(elements, { Text = SOLID_LEFT_ARROW })

		table.insert(elements, { Foreground = { Color = fg } })
		table.insert(elements, { Background = { Color = gradient[i] } })
		table.insert(elements, { Text = " " .. seg .. " " })
	end

	-- disabled when using bar.wizterm, they conflict
	--window:set_right_status(wezterm.format(elements))
end)

-- If you're using emacs you probably wanna choose a different leader here,
-- since we're gonna be making it a bit harder to CTRL + A for jumping to
-- the start of a line
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
	-- vim motion/tmux to move between panes
	move_pane("j", "Down"),
	move_pane("k", "Up"),
	move_pane("h", "Left"),
	move_pane("l", "Right"),
	-- super + , to open wezterm configuration
	{
		key = ",",
		mods = "SUPER",
		action = wezterm.action.SpawnCommandInNewTab({
			cwd = wezterm.home_dir,
			args = { "nvim", wezterm.config_file },
		}),
	},
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
			-- Ensures the keytable stays active after it handles its
			-- first keypress.
			one_shot = false,
			-- Deactivate the keytable after a timeout.
			timeout_milliseconds = 1000,
		}),
	},
}

-- plugins application to config
bar.apply_to_config(config, {
	modules = {
		spotify = {
			enabled = false,
		},
	},
})

-- tabline.apply_to_config(config)

-- Finally, return the configuration to wezterm:
return config
