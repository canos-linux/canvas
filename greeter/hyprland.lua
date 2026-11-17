-- Hyprland config for the CanOS login screen (greetd runs it as user "greeter")
local function read(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local s = f:read("*a")
  f:close()
  return s
end

local kb = read("/etc/X11/xorg.conf.d/00-keyboard.conf") or ""
local layout = kb:match('Option%s+"XkbLayout"%s+"([^"]*)"')
local variant = kb:match('Option%s+"XkbVariant"%s+"([^"]*)"')

hl.config({
  input = {
    kb_layout = (layout and layout ~= "") and layout or "us",
    kb_variant = variant or "",
    kb_options = "grp:alt_shift_toggle",
  },
  misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    force_default_wallpaper = 0,
    background_color = "rgb(0d0b14)",
    disable_watchdog_warning = true,
  },
  ecosystem = {
    no_update_news = true,
    no_donation_nag = true,
  },
  animations = {
    enabled = false,
  },
})

-- same display arrangement as the last user who changed it in Canvas Settings
local displays = read("/var/lib/canos/monitors.lua")
if displays then
  local fn = load(displays)
  if fn then pcall(fn) end
end

hl.on("hyprland.start", function()
  hl.exec_cmd("sh -c 'env QT_WAYLAND_DISABLE_WINDOWDECORATION=1 XDG_CACHE_HOME=/tmp/canos-greeter qs -p /usr/share/canvas/greeter/shell.qml; hyprctl dispatch \"hl.dsp.exit()\"'")
end)
