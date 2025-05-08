local wezterm = require 'wezterm'
local config = {}

-- use the config_builder which will help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

config.window_decorations = 'INTEGRATED_BUTTONS|TITLE'
config.enable_tab_bar = true

config.colors = {
    cursor_bg = '#ffffff',
    cursor_fg = '#0C0C0C',
    cursor_border = '#ffffff',
    tab_bar = {
        background = '#0d0e12',
        new_tab = {
            bg_color = '#040505',
            fg_color = '#e8e9eb',
        },
    }
}

-- BACKGROUND IMAGE
local use_background_image = 0 -- toggle this
local home = os.getenv("USERPROFILE")
local image_path = home .. "/Pictures/backgrounds/dm.png"

if use_background_image == 1 then
    config.window_background_image = image_path
else
    config.window_background_image = ""
end
config.window_background_opacity = 1.0

config.window_background_image_hsb = {
    brightness = 1.0,
    hue = 1.0,
    saturation = 1.0,
}

config.window_padding = {
    left = 8,
    right = 8,
    top = 8,
    bottom = 8,
}

config.font = wezterm.font("3270 Nerd Font", { weight = 400 })
config.font_size = 13.0
config.font_rasterizer = "FreeType"
config.freetype_render_target = "HorizontalLcd"

config.window_frame = {
    active_titlebar_bg = "#ffffff",
}

config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false

config.cursor_blink_rate = 500
config.cursor_blink_ease_in = "Linear"
config.cursor_blink_ease_out = "Linear"
config.default_cursor_style = "BlinkingBlock"
config.window_close_confirmation = "NeverPrompt"

config.skip_close_confirmation_for_processes_named = {
    "bash",
    "sh",
    "zsh",
    "fish",
    "tmux",
    "nu",
    "cmd",
    "powershell",
}

config.launch_menu = {
    {
        label = "PowerShell",
        args = { "powershell.exe" },
    },
    {
        label = "CMD",
        args = { "cmd.exe" },
    },
}
config.default_prog = { "powershell.exe" }

config.hide_tab_bar_if_only_one_tab = false
config.freetype_load_flags = 'NO_HINTING'
config.max_fps = 144

-- hide tab bar in full screen
function fullscreen_toggle(window, pane)
    local overrides = window:get_config_overrides() or {}
    local is_fullscreen = window:get_dimensions().is_full_screen
    
    if is_fullscreen then
        overrides.enable_tab_bar = false
        wezterm.sleep_ms(10)
	overrides.window_decorations = 'NONE'
        wezterm.log_info("Setting to fullscreen mode")
    else
        overrides.enable_tab_bar = true
	overrides.window_decorations = "INTEGRATED_BUTTONS|TITLE"
    end
    
    window:set_config_overrides(overrides)
end

wezterm.on('window-resized', fullscreen_toggle)

return config
