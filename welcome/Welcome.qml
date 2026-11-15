import QtQuick
import Quickshell
import Quickshell.Widgets
import "../core"
import "../services"
import "../ui"

LazyLoader {
    active: IslandState.welcomeOpen || (Edition.ready && !Edition.priv && !Config.opt.welcomeDone)

    FloatingWindow {
        id: win
        title: Lang.t.welcomeTitle
        implicitWidth: 780
        implicitHeight: 540
        color: Theme.base
        property int step: 0
        readonly property int steps: 4

        function finish() {
            Config.opt.welcomeDone = true
            IslandState.welcomeOpen = false
        }

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
                    Logo { anchors.horizontalCenter: parent.horizontalCenter }
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
                        onPicked: v => Config.opt.language = v
                    }
                }
            }

            Page {
                index: 1
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
                                        text: card.modelData.name.charAt(0).toUpperCase() + card.modelData.name.slice(1)
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
                index: 2
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
                index: 3
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
                        text: Lang.t.welcomeReady
                        size: 15
                        color: Theme.subtext
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
