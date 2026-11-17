# Canvas

The desktop of **[CanOS](https://canos-linux.github.io/)** – a shell for Hyprland, built with [Quickshell](https://quickshell.org).

**Yes, I CanOS.**

## Features

- **Living Island** – clock, music, volume, brightness, battery, workspaces and notifications in one island that grows when something happens
- **Control Center** – Wi-Fi, Bluetooth, audio devices and app volume, night light, power profiles, system rings
- **Notifications** – grouped by app, actions, inline replies, images, do not disturb
- **Settings** – look, island, displays (resolution, refresh rate, scale, arrange), touchpad, mouse, keyboard layouts, default apps, account, date & time, updates, system info
- App launcher, theme switcher (Super + T), power menu, area screenshots, clipboard history
- Lock screen with idle lock and lock on sleep, own polkit password dialog, battery warnings, charging animation
- Live wallpaper, glass look, colors generated from the theme
- Welcome app on first start
- English and German (`core/Lang.qml`)

## Run

```
bin/canvas start
```

Needs Hyprland ≥ 0.57 (Lua config), Quickshell, NetworkManager, BlueZ, PipeWire, UPower, power-profiles-daemon and hyprsunset. On CanOS everything is preinstalled.

## Commands

`canvas start|stop|restart|log` · `canvas launcher|themes|center|settings [page]|power|clipboard|screenshot|lock|welcome` · `canvas wifi|bluetooth|audio|micmute|nightlight|profile` · `canvas theme <name>` · `canvas notify <app> <title> <text>`

| Keys | Command |
| --- | --- |
| Super + D | `canvas launcher` |
| Super + T | `canvas themes` |
| Super + B | `canvas center` |
| Super + I | `canvas settings` |
| Super + V | `canvas clipboard` |
| Super + L | `canvas lock` |
| Print | `canvas screenshot` |

## License

GPL-3.0 – see [LICENSE](LICENSE). Made by the creator of CanOS.
