pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../core"

// Canvas Store: curated apps + search in the repos and Flathub; installs through pkexec (Canvas polkit) or flatpak --user
Singleton {
    id: root
    property bool open: false
    property var installed: ({})
    property bool hasFlatpak: false
    property string busy: ""
    property var queue: []
    property var results: []
    property bool searching: false
    property string error: ""
    signal done(string id, bool ok)

    readonly property var cats: ["featured", "games", "internet", "media", "creative", "office", "tools"]
    readonly property var catalog: [
        { id: "firefox", name: "Firefox", cat: "internet", pkg: "firefox", icon: "firefox", desc: { en: "Fast, private web browser", de: "Schneller, privater Webbrowser" } },
        { id: "chromium", name: "Chromium", cat: "internet", pkg: "chromium", icon: "chromium", desc: { en: "Open-source base of Chrome", de: "Open-Source-Basis von Chrome" } },
        { id: "brave", name: "Brave", cat: "internet", flatpak: "com.brave.Browser", icon: "com.brave.Browser", desc: { en: "Browser with built-in ad blocker", de: "Browser mit eingebautem Werbeblocker" } },
        { id: "discord", name: "Discord", cat: "internet", pkg: "discord", icon: "discord", featured: true, desc: { en: "Voice, video and text chat", de: "Sprach-, Video- und Textchat" } },
        { id: "telegram", name: "Telegram", cat: "internet", pkg: "telegram-desktop", icon: "org.telegram.desktop", desc: { en: "Fast messenger", de: "Schneller Messenger" } },
        { id: "signal", name: "Signal", cat: "internet", pkg: "signal-desktop", icon: "signal-desktop", desc: { en: "Private messenger", de: "Privater Messenger" } },
        { id: "thunderbird", name: "Thunderbird", cat: "internet", pkg: "thunderbird", icon: "thunderbird", desc: { en: "Email and calendar", de: "E-Mail und Kalender" } },
        { id: "qbittorrent", name: "qBittorrent", cat: "internet", pkg: "qbittorrent", icon: "qbittorrent", desc: { en: "Torrent client", de: "Torrent-Programm" } },
        { id: "zoom", name: "Zoom", cat: "internet", flatpak: "us.zoom.Zoom", icon: "us.zoom.Zoom", desc: { en: "Video meetings", de: "Videokonferenzen" } },
        { id: "steam", name: "Steam", cat: "games", pkg: "steam", icon: "steam", featured: true, desc: { en: "The biggest PC game store, with Proton", de: "Der größte PC-Spieleshop, mit Proton" } },
        { id: "sober", name: "Sober", cat: "games", flatpak: "org.vinegarhq.Sober", icon: "org.vinegarhq.Sober", featured: true, desc: { en: "Play Roblox on Linux", de: "Roblox auf Linux spielen" } },
        { id: "heroic", name: "Heroic", cat: "games", flatpak: "com.heroicgameslauncher.hgl", icon: "com.heroicgameslauncher.hgl", desc: { en: "Epic Games and GOG launcher", de: "Launcher für Epic Games und GOG" } },
        { id: "lutris", name: "Lutris", cat: "games", pkg: "lutris", icon: "lutris", desc: { en: "All your games in one place", de: "Alle deine Spiele an einem Ort" } },
        { id: "prism", name: "Prism Launcher", cat: "games", pkg: "prismlauncher", icon: "org.prismlauncher.PrismLauncher", desc: { en: "Minecraft launcher with mods", de: "Minecraft-Launcher mit Mods" } },
        { id: "bottles", name: "Bottles", cat: "games", flatpak: "com.usebottles.bottles", icon: "com.usebottles.bottles", desc: { en: "Run Windows programs", de: "Windows-Programme starten" } },
        { id: "protonup", name: "ProtonUp-Qt", cat: "games", flatpak: "net.davidotek.pupgui2", icon: "net.davidotek.pupgui2", desc: { en: "Install Proton-GE and more", de: "Proton-GE und mehr installieren" } },
        { id: "spotify", name: "Spotify", cat: "media", flatpak: "com.spotify.Client", icon: "com.spotify.Client", featured: true, desc: { en: "Music and podcasts", de: "Musik und Podcasts" } },
        { id: "vlc", name: "VLC", cat: "media", pkg: "vlc", icon: "vlc", desc: { en: "Plays every video and audio file", de: "Spielt jedes Video und jede Audiodatei" } },
        { id: "obs", name: "OBS Studio", cat: "media", pkg: "obs-studio", icon: "com.obsproject.Studio", featured: true, desc: { en: "Streaming and screen recording", de: "Streaming und Bildschirmaufnahme" } },
        { id: "audacity", name: "Audacity", cat: "media", pkg: "audacity", icon: "audacity", desc: { en: "Record and edit audio", de: "Audio aufnehmen und schneiden" } },
        { id: "kdenlive", name: "Kdenlive", cat: "media", pkg: "kdenlive", icon: "kdenlive", desc: { en: "Video editor", de: "Videoschnitt" } },
        { id: "gimp", name: "GIMP", cat: "creative", pkg: "gimp", icon: "gimp", desc: { en: "Photo editing", de: "Bildbearbeitung" } },
        { id: "krita", name: "Krita", cat: "creative", pkg: "krita", icon: "krita", desc: { en: "Digital painting", de: "Digital malen" } },
        { id: "inkscape", name: "Inkscape", cat: "creative", pkg: "inkscape", icon: "org.inkscape.Inkscape", desc: { en: "Vector graphics", de: "Vektorgrafik" } },
        { id: "blender", name: "Blender", cat: "creative", pkg: "blender", icon: "blender", desc: { en: "3D modeling and animation", de: "3D-Modellierung und Animation" } },
        { id: "libreoffice", name: "LibreOffice", cat: "office", pkg: "libreoffice-fresh", icon: "libreoffice-startcenter", featured: true, desc: { en: "Documents, spreadsheets, slides", de: "Texte, Tabellen, Präsentationen" } },
        { id: "obsidian", name: "Obsidian", cat: "office", pkg: "obsidian", icon: "obsidian", desc: { en: "Notes that link together", de: "Notizen, die sich verknüpfen" } },
        { id: "vscode", name: "VS Code", cat: "office", pkg: "code", icon: "com.visualstudio.code.oss", featured: true, desc: { en: "Code editor", de: "Code-Editor" } },
        { id: "intellij", name: "IntelliJ IDEA", cat: "office", flatpak: "com.jetbrains.IntelliJ-IDEA-Community", icon: "com.jetbrains.IntelliJ-IDEA-Community", desc: { en: "Java IDE", de: "Java-Entwicklungsumgebung" } },
        { id: "kdeconnect", name: "KDE Connect", cat: "tools", pkg: "kdeconnect", icon: "kdeconnect", desc: { en: "Connect your phone", de: "Handy verbinden" } },
        { id: "btop", name: "btop", cat: "tools", pkg: "btop", icon: "btop", desc: { en: "System monitor in the terminal", de: "Systemmonitor im Terminal" } },
        { id: "gparted", name: "GParted", cat: "tools", pkg: "gparted", icon: "gparted", desc: { en: "Manage partitions", de: "Partitionen verwalten" } },
        { id: "flatseal", name: "Flatseal", cat: "tools", flatpak: "com.github.tchx84.Flatseal", icon: "com.github.tchx84.Flatseal", desc: { en: "Permissions for Flatpak apps", de: "Rechte für Flatpak-Apps" } }
    ]

    function key(app) { return app.pkg ? "pkg:" + app.pkg : "fp:" + app.flatpak }
    function isInstalled(app) { return installed[key(app)] === true }
    function desc(app) { return typeof app.desc === "string" ? app.desc : (app.desc[Lang.code] || app.desc.en) }

    function refresh() { if (!scan.running) scan.running = true }

    function install(app) {
        if (busy !== "") {
            queue = queue.concat([{ app: app, remove: false }])
            return
        }
        run(app, false)
    }

    function remove(app) {
        if (busy !== "") return
        run(app, true)
    }

    // welcome setup: one password prompt for all repo packages, flatpaks afterwards
    function installMany(apps, extraPkgs) {
        const pkgs = apps.filter(a => a.pkg).map(a => a.pkg).concat(extraPkgs || [])
        const fps = apps.filter(a => a.flatpak).map(a => a.flatpak)
        if (pkgs.length === 0 && fps.length === 0) return
        busy = "batch"
        error = ""
        worker.target = null
        let cmd = ""
        if (pkgs.length > 0 || (fps.length > 0 && !hasFlatpak)) cmd += "pkexec pacman -S --needed --noconfirm " + pkgs.concat(fps.length > 0 ? ["flatpak"] : []).join(" ") + " || exit 1; "
        if (fps.length > 0) cmd += "flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo && flatpak install --user -y --noninteractive flathub " + fps.join(" ")
        worker.command = ["bash", "-c", "(" + cmd + ") 2>&1 | tail -3; exit ${PIPESTATUS[0]}"]
        worker.running = true
    }

    function launch(app) {
        const e = DesktopEntries.heuristicLookup(app.flatpak || app.icon || app.name) || DesktopEntries.heuristicLookup(app.name)
        if (e) e.execute()
        else if (app.flatpak) Quickshell.execDetached(["flatpak", "run", app.flatpak])
        else if (app.pkg) Quickshell.execDetached(["sh", "-c", app.pkg + " &"])
    }

    function run(app, rm) {
        error = ""
        busy = key(app)
        let cmd
        if (app.pkg) cmd = rm ? "pkexec pacman -Rns --noconfirm \"$1\"" : "pkexec pacman -S --needed --noconfirm \"$1\""
        else cmd = rm ? "flatpak uninstall --user -y --noninteractive \"$1\""
            : "command -v flatpak >/dev/null || pkexec pacman -S --needed --noconfirm flatpak || exit 1; flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo && flatpak install --user -y --noninteractive flathub \"$1\""
        worker.target = app
        worker.command = ["bash", "-c", cmd + " 2>&1 | tail -3; exit ${PIPESTATUS[0]}", "bash", app.pkg || app.flatpak]
        worker.running = true
    }

    Process {
        id: worker
        property var target: null
        stdout: StdioCollector { id: out }
        onExited: code => {
            const id = root.busy
            root.busy = ""
            if (code !== 0) root.error = (worker.target ? worker.target.name + ": " : "") + (out.text.trim().split("\n").pop() || "error " + code)
            Sounds.play(code === 0 ? "notif" : "error")
            root.done(id, code === 0)
            root.refresh()
            if (root.queue.length > 0) {
                const next = root.queue[0]
                root.queue = root.queue.slice(1)
                root.run(next.app, next.remove)
            }
        }
    }

    Process {
        id: scan
        command: ["sh", "-c", "pacman -Qq | sed 's/^/pkg:/'; command -v flatpak >/dev/null && { echo HAS_FLATPAK; flatpak list --app --columns=application 2>/dev/null | sed 's/^/fp:/'; }"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = {}
                let fp = false
                for (const l of text.split("\n")) {
                    if (l === "HAS_FLATPAK") fp = true
                    else if (l !== "") m[l.trim()] = true
                }
                root.installed = m
                root.hasFlatpak = fp
            }
        }
    }

    // search: repos (pacman -Ss) + Flathub (if flatpak is there)
    function search(q) {
        q = q.trim()
        if (q.length < 2) {
            results = []
            return
        }
        searcher.running = false
        searcher.command = ["sh", "-c", "pacman -Ss -- \"$1\" 2>/dev/null | head -60; echo '|||'; command -v flatpak >/dev/null && flatpak search --columns=name,description,application -- \"$1\" 2>/dev/null | head -20", "sh", q]
        searching = true
        searcher.running = true
    }

    Process {
        id: searcher
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("|||")
                const list = []
                const lines = (parts[0] || "").split("\n")
                for (let i = 0; i + 1 < lines.length; i += 2) {
                    const m = lines[i].match(/^(\S+)\/(\S+)\s/)
                    if (!m) { i--; continue }
                    list.push({ id: "s:" + m[2], name: m[2], pkg: m[2], icon: m[2], desc: lines[i + 1].trim(), repo: m[1] })
                }
                for (const l of (parts[1] || "").split("\n")) {
                    const f = l.split("\t")
                    if (f.length >= 3 && f[2].indexOf(".") > 0) list.push({ id: "f:" + f[2], name: f[0], flatpak: f[2], icon: f[2], desc: f[1], repo: "flathub" })
                }
                root.results = list.slice(0, 40)
                root.searching = false
            }
        }
    }

    onOpenChanged: if (open) refresh()
}
