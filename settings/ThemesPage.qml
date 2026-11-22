import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../core"
import "../services"
import "../ui"

Column {
    id: page
    width: parent ? parent.width : 400
    spacing: 0
    readonly property var presets: ["#b9a4ff", "#7aa2ff", "#5ad1c9", "#8bd17c", "#ffd36b", "#ff9e64", "#ff7a93", "#e48cff"]
    readonly property var accents: { try { return JSON.parse(Config.opt.themeAccents) } catch (e) { return {} } }
    readonly property string currentAccent: accents[CurrentTheme.name] || ""
    property bool creating: false
    property var pictures: []
    property string pick: ""
    property string newColor: ""
    property string busyText: ""

    onVisibleChanged: if (visible) CurrentTheme.refresh()

    function setAccent(name, hex) {
        const a = Object.assign({}, accents)
        if (hex === "") delete a[name]
        else a[name] = hex
        Config.opt.themeAccents = JSON.stringify(a)
    }

    function isVideo(p) { return /\.(mp4|webm|mkv|mov)$/i.test(p) }

    function startCreate() {
        creating = true
        pick = ""
        newColor = ""
        nameField.text = ""
        finder.running = true
    }

    function create() {
        const title = nameField.text.trim() || Lang.t.themeMine
        if (pick === "") return
        let slug = title.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "") || "theme"
        const taken = CurrentTheme.allThemes.map(t => t.name)
        let s = slug, n = 2
        while (taken.indexOf(s) !== -1) s = slug + "-" + n++
        maker.slug = s
        maker.command = ["sh", "-c", `
d="$1/$2"; mkdir -p "$d" || exit 1
case "$3" in
  *.mp4|*.MP4|*.webm|*.mkv|*.mov) cp "$3" "$d/wallpaper.mp4" && { ffmpeg -y -loglevel error -ss 1 -i "$3" -frames:v 1 "$d/lock.png" || ffmpeg -y -loglevel error -i "$3" -frames:v 1 "$d/lock.png"; } ;;
  *) magick "$3" -resize '3840x2160>' "$d/lock.png" 2>/dev/null || cp "$3" "$d/lock.png" ;;
esac
[ -s "$d/lock.png" ] || { rm -rf "$d"; exit 1; }
c="$5"
[ -n "$c" ] || c=$(matugen image "$d/lock.png" -m dark --json hex --dry-run 2>/dev/null | tr -d '\\n ' | grep -o '"primary":{[^}]*"dark":{"color":"#[0-9a-fA-F]*"' | grep -o '#[0-9a-fA-F]*$')
[ -n "$c" ] || c="#b9a4ff"
printf '{\\n    "name": "%s",\\n    "color": "%s",\\n    "author": "%s"\\n}\\n' "$4" "$c" "$USER" > "$d/theme.json"
echo OK`, "sh", CurrentTheme.userRoot, s, pick, title.replace(/"/g, "'"), newColor]
        busyText = Lang.t.themeCreating
        maker.running = true
    }

    Process {
        id: maker
        property string slug: ""
        stdout: StdioCollector {
            onStreamFinished: {
                page.busyText = ""
                if (text.indexOf("OK") !== -1) {
                    if (page.newColor !== "") page.setAccent(maker.slug, page.newColor)
                    page.creating = false
                    CurrentTheme.refresh()
                    applyNew.restart()
                } else {
                    page.busyText = Lang.t.themeFailed
                }
            }
        }
    }

    Timer {
        id: applyNew
        interval: 700
        onTriggered: CurrentTheme.apply(CurrentTheme.themes.find(t => t.name === maker.slug))
    }

    Process {
        id: finder
        command: ["sh", "-c", "find \"$HOME/Pictures\" \"$HOME/Bilder\" \"$HOME/Downloads\" \"$HOME/Videos\" \"$HOME/Desktop\" -maxdepth 3 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.mp4' -o -iname '*.webm' \\) -not -path '*/Recordings/*' -printf '%T@ %p\\n' 2>/dev/null | sort -rn | head -48 | cut -d' ' -f2-"]
        stdout: StdioCollector {
            onStreamFinished: page.pictures = text.split("\n").filter(l => l !== "")
        }
    }

    // ---------- your themes ----------
    Item {
        width: parent.width
        height: 44
        visible: !page.creating
        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: Lang.t.themesYours
            size: 13
            weight: Font.DemiBold
            color: Theme.accent
        }
        PillButton {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: "+  " + Lang.t.themeNew
            primary: true
            onClicked: page.startCreate()
        }
    }

    Grid {
        visible: !page.creating
        columns: 3
        spacing: 12
        bottomPadding: 10
        Repeater {
            model: CurrentTheme.themes
            Item {
                id: tcard
                required property var modelData
                readonly property bool current: modelData.name === CurrentTheme.name
                width: (page.width - 24) / 3
                height: width * 0.62 + 30

                ClippingRectangle {
                    id: thumb
                    width: parent.width
                    height: parent.width * 0.62
                    radius: 16
                    color: Theme.surfaceHigh
                    border.width: tcard.current ? 2 : 0
                    border.color: Theme.accent
                    Image {
                        anchors.fill: parent
                        source: "file://" + tcard.modelData.dir + "/lock.png"
                        sourceSize.width: 320
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                    Rectangle {
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        anchors.margins: 8
                        width: 16
                        height: 16
                        radius: 8
                        color: page.accents[tcard.modelData.name] || tcard.modelData.color
                        border.width: 2
                        border.color: "#ffffff"
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            Sounds.play("click")
                            CurrentTheme.apply(tcard.modelData)
                        }
                    }
                    Rectangle {
                        visible: CurrentTheme.themes.length > 1
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 6
                        width: 28
                        height: 28
                        radius: 14
                        color: delHov.hovered ? "#e5484d" : Theme.alpha(Theme.base, 0.7)
                        Icon {
                            anchors.centerIn: parent
                            text: "󰆴"
                            size: 15
                            hoverable: false
                            color: "#ffffff"
                        }
                        HoverHandler { id: delHov }
                        TapHandler {
                            onTapped: {
                                Sounds.play("click")
                                CurrentTheme.remove(tcard.modelData)
                            }
                        }
                    }
                }
                Txt {
                    anchors.top: thumb.bottom
                    anchors.topMargin: 6
                    width: parent.width
                    text: tcard.modelData.title + (tcard.modelData.user ? "" : "  ·  " + Lang.t.themeBuiltIn)
                    size: 12
                    weight: tcard.current ? Font.DemiBold : Font.Normal
                    color: tcard.current ? Theme.text : Theme.subtext
                    elide: Text.ElideRight
                }
            }
        }
    }

    SettingRow {
        visible: !page.creating
        title: Lang.t.themeColor
        sub: page.currentAccent === "" ? Lang.t.themeColorAuto : Lang.t.themeColorOwn
        height: 76
        Row {
            spacing: 6
            Rectangle {
                width: 46
                height: 26
                radius: 13
                color: page.currentAccent === "" ? Theme.accent : Theme.surfaceHigh
                Txt {
                    anchors.centerIn: parent
                    text: "Auto"
                    size: 11
                    weight: Font.DemiBold
                    color: page.currentAccent === "" ? Theme.base : Theme.text
                }
                TapHandler { onTapped: { Sounds.play("click"); page.setAccent(CurrentTheme.name, "") } }
            }
            Repeater {
                model: page.presets
                Rectangle {
                    width: 26
                    height: 26
                    radius: 13
                    color: modelData
                    border.width: page.currentAccent.toLowerCase() === modelData ? 3 : 0
                    border.color: Theme.text
                    TapHandler { onTapped: { Sounds.play("click"); page.setAccent(CurrentTheme.name, modelData) } }
                }
            }
        }
    }

    Row {
        visible: !page.creating && CurrentTheme.hiddenList.length > 0
        spacing: 12
        topPadding: 6
        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: Lang.t.themesHidden.replace("%1", CurrentTheme.hiddenList.length)
            size: 12
            color: Theme.subtext
        }
        PillButton {
            text: Lang.t.themesRestore
            onClicked: CurrentTheme.restoreBuiltIn()
        }
    }

    // ---------- new theme ----------
    Column {
        visible: page.creating
        width: parent.width
        spacing: 12

        Row {
            spacing: 10
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰁍"
                size: 20
                onClicked: page.creating = false
            }
            Txt {
                anchors.verticalCenter: parent.verticalCenter
                text: Lang.t.themeNew
                size: 17
                weight: Font.Bold
            }
        }

        Field {
            id: nameField
            width: parent.width
            placeholder: Lang.t.themeName
        }

        Txt {
            text: Lang.t.themePick
            size: 13
            weight: Font.DemiBold
            color: Theme.accent
        }

        Txt {
            visible: page.pictures.length === 0
            width: parent.width
            text: Lang.t.themeNoPictures
            size: 12
            color: Theme.subtext
            wrapMode: Text.WordWrap
        }

        Flickable {
            width: parent.width
            height: Math.min(250, picGrid.height)
            contentHeight: picGrid.height
            clip: true
            Grid {
                id: picGrid
                columns: 4
                spacing: 8
                Repeater {
                    model: page.pictures
                    ClippingRectangle {
                        width: (page.width - 24) / 4
                        height: width * 0.62
                        radius: 12
                        color: Theme.surfaceHigh
                        border.width: page.pick === modelData ? 3 : 0
                        border.color: Theme.accent
                        Image {
                            anchors.fill: parent
                            visible: !page.isVideo(modelData)
                            source: visible ? "file://" + modelData : ""
                            sourceSize.width: 220
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                        Column {
                            visible: page.isVideo(modelData)
                            anchors.centerIn: parent
                            Icon { anchors.horizontalCenter: parent.horizontalCenter; text: "󰕧"; size: 24; hoverable: false; color: Theme.accent }
                            Txt { width: 110; horizontalAlignment: Text.AlignHCenter; text: modelData.split("/").pop(); size: 10; elide: Text.ElideMiddle; color: Theme.subtext }
                        }
                        TapHandler { onTapped: { Sounds.play("click"); page.pick = modelData } }
                    }
                }
            }
        }

        Field {
            width: parent.width
            placeholder: Lang.t.themePath
            onAccepted: if (text.trim() !== "") page.pick = text.trim().replace(/^~/, Quickshell.env("HOME"))
        }

        SettingRow {
            title: Lang.t.themeColor
            sub: page.newColor === "" ? Lang.t.themeColorAuto : Lang.t.themeColorOwn
            Row {
                spacing: 6
                Rectangle {
                    width: 46
                    height: 26
                    radius: 13
                    color: page.newColor === "" ? Theme.accent : Theme.surfaceHigh
                    Txt { anchors.centerIn: parent; text: "Auto"; size: 11; weight: Font.DemiBold; color: page.newColor === "" ? Theme.base : Theme.text }
                    TapHandler { onTapped: page.newColor = "" }
                }
                Repeater {
                    model: page.presets
                    Rectangle {
                        width: 26
                        height: 26
                        radius: 13
                        color: modelData
                        border.width: page.newColor === modelData ? 3 : 0
                        border.color: Theme.text
                        TapHandler { onTapped: page.newColor = modelData }
                    }
                }
            }
        }

        Row {
            spacing: 12
            PillButton {
                text: Lang.t.themeCreate
                primary: true
                enabled: page.pick !== "" && !maker.running
                onClicked: page.create()
            }
            Txt {
                anchors.verticalCenter: parent.verticalCenter
                text: page.busyText
                size: 12
                color: Theme.subtext
            }
        }
    }
}
