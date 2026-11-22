pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../core"

// Open-Meteo: free, no account
Singleton {
    id: root
    property bool ok: false
    property string place: ""
    property real temp: 0
    property int code: 0
    property real high: 0
    property real low: 0
    property bool day: true
    readonly property string icon: glyph(code, day)
    readonly property string label: Lang.t.weatherCodes[group(code)] || ""
    readonly property bool wanted: Config.opt.widgets && Config.opt.wWeather

    function group(c) {
        if (c === 0) return 0
        if (c <= 2) return 1
        if (c === 3) return 2
        if (c <= 48) return 3
        if (c <= 67 || (c >= 80 && c <= 82)) return 4
        if (c <= 77 || c === 85 || c === 86) return 5
        return 6
    }

    function glyph(c, d) {
        return [d ? "󰖙" : "󰖔", d ? "󰖕" : "󰼱", "󰖐", "󰖑", "󰖗", "󰖘", "󰖓"][group(c)]
    }

    function refresh() { if (!q.running) q.running = true }

    Process {
        id: q
        command: ["sh", "-c", `
city="$1"
if [ -n "$city" ]; then
  g=$(curl -fsm 10 "https://geocoding-api.open-meteo.com/v1/search?count=1&name=$(printf '%s' "$city" | sed 's/ /%20/g')") || exit 1
else
  g=$(curl -fsm 10 "http://ip-api.com/json/?fields=city,lat,lon" | sed 's/"city"/"name"/; s/"lat"/"latitude"/; s/"lon"/"longitude"/')
  printf '%s' "$g" | grep -q latitude || g=$(curl -fsm 10 "https://ipwho.is/" | sed 's/"city"/"name"/')
  printf '%s' "$g" | grep -q latitude || exit 1
fi
lat=$(printf '%s' "$g" | grep -o '"latitude": *[-0-9.]*' | head -1 | grep -o '[-0-9.]*$')
lon=$(printf '%s' "$g" | grep -o '"longitude": *[-0-9.]*' | head -1 | grep -o '[-0-9.]*$')
name=$(printf '%s' "$g" | grep -o '"name": *"[^"]*"' | head -1 | sed 's/.*"\\([^"]*\\)"$/\\1/')
[ -n "$lat" ] || exit 1
echo "NAME:$name"
curl -fsm 10 "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,weather_code,is_day&daily=temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=1"`, "sh", Config.opt.weatherCity]
        stdout: StdioCollector {
            onStreamFinished: {
                const i = text.indexOf("{", text.indexOf("\n"))
                try {
                    const nm = text.match(/^NAME:(.*)$/m)
                    const d = JSON.parse(text.slice(i))
                    root.place = nm ? nm[1] : ""
                    root.temp = d.current.temperature_2m
                    root.code = d.current.weather_code
                    root.day = d.current.is_day === 1
                    root.high = d.daily.temperature_2m_max[0]
                    root.low = d.daily.temperature_2m_min[0]
                    root.ok = true
                } catch (e) {
                    root.ok = false
                }
            }
        }
    }

    Timer {
        interval: 30 * 60 * 1000
        repeat: true
        running: root.wanted
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Connections {
        target: Config.opt
        function onWeatherCityChanged() { cityTimer.restart() }
    }

    Timer {
        id: cityTimer
        interval: 1500
        onTriggered: if (root.wanted) root.refresh()
    }
}
