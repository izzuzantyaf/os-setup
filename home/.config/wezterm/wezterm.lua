local wezterm = require("wezterm")

local config = wezterm.config_builder()

wezterm.on("gui-startup", function(cmd)
  local screen = wezterm.gui.screens().active
  local width = 1920
  local height = 1080

  local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
  local gui_window = window:gui_window()
  gui_window:set_inner_size(width, height)

  local x = screen.x + (screen.width - width) / 2
  local y = screen.y + (screen.height - height) / 2
  gui_window:set_position(x, y)
end)


config.font = wezterm.font("JetBrainsMono Nerd Font")
config.font_size = 14.0
config.window_background_opacity = 0.67
config.macos_window_background_blur = 67
config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "RESIZE"

config.window_frame = {
  font = config.font,
  font_size = config.font_size,
  border_left_width = "2px",
  border_right_width = "2px",
  border_bottom_height = "2px",
  border_top_height = "2px",
  border_left_color = "#333333",
  border_right_color = "#333333",
  border_bottom_color = "#333333",
  border_top_color = "#333333",
}

return config
