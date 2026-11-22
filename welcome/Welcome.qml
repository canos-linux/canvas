import QtQuick
import Quickshell
import Quickshell.Widgets
import "../core"
import "../services"
import "../ui"
import "../settings"

LazyLoader {
    active: IslandState.welcomeOpen || (Edition.ready && Displays.ready && !Edition.priv && !Config.opt.welcomeDone)

    FloatingWindow {
        id: win
        title: Lang.t.welcomeTitle
        implicitWidth: 780
        implicitHeight: 620
        color: Theme.base
        property int step: 0
        // display step only with more than one display
        readonly property int d: multi ? 1 : 0
        readonly property bool multi: Displays.count > 1
        readonly property int steps: (live ? 4 : 6) + d
        property var picked: ({ steam: true, discord: true, spotify: true })
        property bool wantSnapshots: true

        function setupSystem() {
            if (live) return
            const apps = Store.catalog.filter(a => picked[a.id])
            const extra = Config.opt.phone ? ["kdeconnect"] : []
            Store.installMany(apps, extra)
            if (wantSnapshots) snapLater.start()
        }

        Timer {
            id: snapLater
            interval: 1500
            repeat: true
            onTriggered: if (Store.busy === "") { stop(); Snapshots.setup() }
        }
        readonly property bool live: Quickshell.env("USER") === "liveuser"
        property bool displaysOn: false
        readonly property var kbOptions: [
            { code: "us", name: "English (US)" },
            { code: "gb", name: "English (UK)" },
            { code: "de", name: "Deutsch" },
            { code: "at", name: "Deutsch (AT)" },
            { code: "ch", name: "Deutsch (CH)" },
            { code: "tr", name: "Türkçe" },
            { code: "fr", name: "Français" },
            { code: "es", name: "Español" },
            { code: "it", name: "Italiano" }
        ]
        readonly property string kb: Config.opt.kbLayouts !== "" ? Config.opt.kbLayouts.split(",")[0] : Hypr.layoutCode

        function setKb(code) {
            Config.opt.kbLayouts = code
            HyprConf.save()
            // live session: the installer takes this layout as its default
            if (live) Quickshell.execDetached(["sh", "-c", "sudo -n localectl set-x11-keymap \"$1\"; sudo -n localectl set-keymap \"$1\" 2>/dev/null; true", "sh", code])
        }

        function showDisplays() {
            if (displaysOn) return
            displaysOn = true
            if (Displays.firstStart) Displays.enableAll()
        }

        function finish() {
            if (multi && !displaysOn && Displays.firstStart) Displays.enableAll()
            Config.opt.displaySetup = true
            if (!Config.opt.welcomeDone) setupSystem()
            Config.opt.welcomeDone = true
            IslandState.welcomeOpen = false
        }

        onStepChanged: if (multi && step === 1) showDisplays()

        onVisibleChanged: if (!visible) finish()
        Component.onCompleted: CurrentTheme.refresh()

        component Pill: Rectangle {
            id: pill
            property string label: ""
            property bool primary: false
            signal clicked()
            width: Math.max(110, pillTxt.implicitWidth + 40)
            height: 40
            radius: 20
            color: primary ? (pillArea.containsMouse ? Theme.accent2 : Theme.accent) : pillArea.containsMouse ? Theme.surfaceHigh : "transparent"
            border.width: primary ? 0 : 1
            border.color: Theme.alpha(Theme.text, 0.2)
            scale: pillArea.pressed ? 0.95 : 1
            Behavior on color { ColorAnimation { duration: 180 } }
            Behavior on scale { NumberAnimation { duration: 150 } }
            Txt {
                id: pillTxt
                anchors.centerIn: parent
                text: pill.label
                weight: Font.DemiBold
                color: pill.primary ? Theme.base : Theme.text
            }
            MouseArea {
                id: pillArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: pill.clicked()
            }
        }

        component Page: Item {
            property int index: 0
            width: parent.width
            height: parent.height
            opacity: win.step === index ? 1 : 0
            visible: opacity > 0
            x: win.step === index ? 0 : win.step > index ? -40 : 40
            Behavior on opacity { NumberAnimation { duration: Theme.dur(260) } }
            Behavior on x { NumberAnimation { duration: Theme.dur(320); easing.type: Easing.OutCubic } }
        }

        component Logo: Canvas {
            id: logo
            property color tint: Theme.accent
            width: 110
            height: 110
            onTintChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                const r = width * 0.38
                ctx.lineWidth = width * 0.075
                ctx.lineCap = "round"
                ctx.strokeStyle = tint
                ctx.beginPath()
                ctx.arc(width / 2, height / 2, r, Math.PI * 0.22, Math.PI * 1.78)
                ctx.stroke()
                ctx.fillStyle = tint
                ctx.beginPath()
                ctx.arc(width / 2 + r, height / 2, width * 0.06, 0, Math.PI * 2)
                ctx.fill()
            }
        }

        Item {
            id: body
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: footer.top
            anchors.margins: 40

            Page {
                index: 0
                Column {
                    anchors.centerIn: parent
                    spacing: 14
                    Logo { anchors.horizontalCenter: parent.horizontalCenter; width: 84; height: 84 }
                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Lang.t.welcomeTitle
                        size: 30
                        weight: Font.Bold
                    }
                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Lang.t.welcomeSub
                        size: 15
                        color: Theme.subtext
                        bottomPadding: 18
                    }
                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Lang.t.welcomeLang
                        size: 13
                        color: Theme.subtext
                    }
                    Segmented {
                        anchors.horizontalCenter: parent.horizontalCenter
                        options: ["English", "Deutsch"]
                        values: ["en", "de"]
                        value: Lang.code
                        onPicked: v => {
                            Config.opt.language = v
                            if (v === "de" && Config.opt.kbLayouts === "") win.setKb("de")
                        }
                    }
                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Lang.t.welcomeKeyboard
                        size: 13
                        color: Theme.subtext
                        topPadding: 10
                    }
                    Flow {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 560
                        spacing: 8
                        Repeater {
                            model: win.kbOptions
                            Rectangle {
                                id: chip
                                required property var modelData
                                readonly property bool on: win.kb === modelData.code
                                width: chipTxt.implicitWidth + 28
                                height: 32
                                radius: 16
                                color: on ? Theme.accent : chipArea.containsMouse ? Theme.surfaceHigh : Theme.alpha(Theme.surfaceHigh, 0.6)
                                Behavior on color { ColorAnimation { duration: Theme.dur(150) } }
                                Txt {
                                    id: chipTxt
                                    anchors.centerIn: parent
                                    text: chip.modelData.name
                                    size: 13
                                    color: chip.on ? Theme.base : Theme.text
                                    weight: chip.on ? Font.DemiBold : Font.Normal
                                }
                                MouseArea {
                                    id: chipArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: win.setKb(chip.modelData.code)
                                }
                            }
                        }
                    }
                }
            }

            Page {
                index: 1
                visible: win.multi && opacity > 0
                Column {
                    anchors.fill: parent
                    spacing: 6
                    Txt { text: Lang.t.welcomeDisplays; size: 26; weight: Font.Bold }
                    Txt { width: parent.width; text: Lang.t.welcomeDisplaysSub; size: 14; color: Theme.subtext; wrapMode: Text.WordWrap; bottomPadding: 10 }
                    Flickable {
                        width: parent.width
                        height: parent.height - y
                        contentHeight: dispPage.implicitHeight
                        clip: true
                        DisplayPage {
                            id: dispPage
                            width: parent.width
                            compact: true
                            visible: win.displaysOn
                        }
                    }
                }
            }

            Page {
                index: 1 + win.d
                Column {
                    anchors.fill: parent
                    spacing: 6
                    Txt { text: Lang.t.welcomeTheme; size: 26; weight: Font.Bold }
                    Txt { text: Lang.t.welcomeThemeSub; size: 14; color: Theme.subtext; bottomPadding: 18 }
                    Grid {
                        anchors.horizontalCenter: parent.horizontalCenter
                        columns: 3
                        spacing: 18
                        Repeater {
                            model: CurrentTheme.themes
                            Item {
                                id: card
                                required property var modelData
                                property bool current: modelData.name === CurrentTheme.name
                                width: 200
                                height: 140
                                ClippingRectangle {
                                    id: thumb
                                    width: parent.width
                                    height: 112
                                    radius: 16
                                    color: Theme.surfaceHigh
                                    border.width: card.current ? 3 : 1
                                    border.color: card.current ? Theme.accent : Theme.alpha(Theme.text, 0.15)
                                    scale: cardArea.containsMouse ? 1.04 : 1
                                    Behavior on scale { NumberAnimation { duration: Theme.dur(200) } }
                                    Image {
                                        anchors.fill: parent
                                        source: "file://" + card.modelData.dir + "/lock.png"
                                        sourceSize.width: 400
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                    }
                                }
                                Row {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: thumb.bottom
                                    anchors.topMargin: 8
                                    spacing: 7
                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 9
                                        height: 9
                                        radius: 5
                                        color: card.modelData.color
                                    }
                                    Txt {
                                        text: card.modelData.title && card.modelData.title !== card.modelData.name ? card.modelData.title : card.modelData.name.charAt(0).toUpperCase() + card.modelData.name.slice(1)
                                        weight: card.current ? Font.DemiBold : Font.Normal
                                    }
                                }
                                MouseArea {
                                    id: cardArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: CurrentTheme.apply(card.modelData)
                                }
                            }
                        }
                    }
                }
            }

            Page {
                index: 2 + win.d
                Column {
                    anchors.fill: parent
                    spacing: 6
                    Txt { text: Lang.t.welcomeTour; size: 26; weight: Font.Bold; bottomPadding: 18 }
                    Repeater {
                        model: [
                            { icon: "󱂬", text: Lang.t.tourIsland },
                            { icon: "󰍉", text: Lang.t.tourLauncher },
                            { icon: "󰏘", text: Lang.t.tourThemes },
                            { icon: "󰹑", text: Lang.t.tourShot },
                            { icon: "󰐥", text: Lang.t.tourPower },
                            { icon: "󰒓", text: Lang.t.tourSettings }
                        ]
                        Row {
                            required property var modelData
                            width: parent.width
                            spacing: 16
                            height: 50
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 38
                                height: 38
                                radius: 19
                                color: Theme.alpha(Theme.accent, 0.18)
                                Icon {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    size: 18
                                    color: Theme.accent
                                    hoverable: false
                                }
                            }
                            Txt {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 60
                                text: modelData.text
                                size: 14
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }

            Page {
                index: 3 + win.d
                visible: !win.live && opacity > 0
                Column {
                    anchors.fill: parent
                    spacing: 6
                    Txt { text: Lang.t.welcomeApps; size: 26; weight: Font.Bold }
                    Txt { text: Lang.t.welcomeAppsSub; size: 14; color: Theme.subtext; bottomPadding: 14 }
                    Grid {
                        anchors.horizontalCenter: parent.horizontalCenter
                        columns: 4
                        spacing: 10
                        Repeater {
                            model: Store.catalog.filter(a => ["steam", "discord", "spotify", "sober", "obs", "vscode", "libreoffice", "vlc", "gimp", "heroic", "prism", "telegram"].indexOf(a.id) !== -1)
                            Rectangle {
                                id: appTile
                                required property var modelData
                                readonly property bool on: win.picked[modelData.id] === true
                                width: 150
                                height: 58
                                radius: 18
                                color: on ? Theme.alpha(Theme.accent, 0.22) : tileHov.hovered ? Theme.surfaceHigh : Theme.surface
                                border.width: on ? 1 : 0
                                border.color: Theme.accent
                                Icon {
                                    id: chk
                                    anchors.left: parent.left
                                    anchors.leftMargin: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: appTile.on ? "󰄲" : "󰄱"
                                    size: 20
                                    color: appTile.on ? Theme.accent : Theme.subtext
                                    hoverable: false
                                }
                                Txt {
                                    anchors.left: chk.right
                                    anchors.leftMargin: 10
                                    anchors.right: parent.right
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: appTile.modelData.name
                                    weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }
                                HoverHandler { id: tileHov }
                                TapHandler {
                                    onTapped: {
                                        Sounds.play("click")
                                        const p = Object.assign({}, win.picked)
                                        p[appTile.modelData.id] = !appTile.on
                                        win.picked = p
                                    }
                                }
                            }
                        }
                    }
                    Txt { topPadding: 12; text: Lang.t.welcomeAppsMore; size: 12; color: Theme.subtext }
                }
            }

            Page {
                index: 4 + win.d
                visible: !win.live && opacity > 0
                Column {
                    anchors.fill: parent
                    spacing: 4
                    Txt { text: Lang.t.welcomeExtras; size: 26; weight: Font.Bold; bottomPadding: 14 }
                    Repeater {
                        model: [
                            { icon: "󰕾", title: Lang.t.sounds, sub: Lang.t.soundsSub, key: "sounds" },
                            { icon: "󰖲", title: Lang.t.widgetsOn, sub: Lang.t.widgetsOnSub, key: "widgets" },
                            { icon: "󰄜", title: Lang.t.phoneOn, sub: Lang.t.phoneOnSub, key: "phone" },
                            { icon: "󰆓", title: Lang.t.snapTitle, sub: Lang.t.snapWelcomeSub, key: "snap" }
                        ]
                        Item {
                            required property var modelData
                            readonly property bool on: modelData.key === "snap" ? win.wantSnapshots : Config.opt[modelData.key]
                            width: parent.width
                            height: 62
                            Icon { id: exIcon; anchors.verticalCenter: parent.verticalCenter; text: modelData.icon; size: 22; color: Theme.accent; hoverable: false }
                            Column {
                                anchors.left: exIcon.right
                                anchors.leftMargin: 16
                                anchors.right: exToggle.left
                                anchors.rightMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                Txt { text: modelData.title; size: 15; weight: Font.DemiBold }
                                Txt { width: parent.width; text: modelData.sub; size: 12; color: Theme.subtext; wrapMode: Text.WordWrap }
                            }
                            Toggle {
                                id: exToggle
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                checked: parent.on
                                onToggled: v => {
                                    if (modelData.key === "snap") win.wantSnapshots = v
                                    else Config.opt[modelData.key] = v
                                }
                            }
                        }
                    }
                }
            }

            Page {
                index: win.steps - 1
                Column {
                    anchors.centerIn: parent
                    spacing: 16
                    Logo { anchors.horizontalCenter: parent.horizontalCenter }
                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Yes, I CanOS."
                        size: 34
                        weight: Font.Bold
                    }
                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: win.live ? Lang.t.liveHint : Lang.t.welcomeReady
                        size: 15
                        color: Theme.subtext
                    }
                    Pill {
                        visible: win.live
                        anchors.horizontalCenter: parent.horizontalCenter
                        primary: true
                        label: Lang.t.install
                        onClicked: {
                            Quickshell.execDetached(["sh", "-c", "sudo -E calamares"])
                            win.finish()
                        }
                    }
                }
            }
        }

        Item {
            id: footer
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 30
            height: 40

            Pill {
                anchors.left: parent.left
                visible: win.step < win.steps - 1
                label: Lang.t.skip
                onClicked: win.finish()
            }

            Row {
                anchors.centerIn: parent
                spacing: 8
                Repeater {
                    model: win.steps
                    Rectangle {
                        required property int index
                        anchors.verticalCenter: parent.verticalCenter
                        width: win.step === index ? 22 : 8
                        height: 8
                        radius: 4
                        color: win.step === index ? Theme.accent : Theme.alpha(Theme.text, 0.25)
                        Behavior on width { NumberAnimation { duration: Theme.dur(250) } }
                    }
                }
            }

            Row {
                anchors.right: parent.right
                spacing: 10
                Pill {
                    visible: win.step > 0
                    label: Lang.t.back
                    onClicked: win.step -= 1
                }
                Pill {
                    primary: true
                    label: win.step === win.steps - 1 ? Lang.t.letsGo : Lang.t.next
                    onClicked: {
                        if (win.step === win.steps - 1) win.finish()
                        else win.step += 1
                    }
                }
            }
        }
    }
}
