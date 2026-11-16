import QtQuick
import Quickshell
import Quickshell.Widgets
import "../core"
import "../services"
import "../ui"

ListView {
    id: list
    property int maxRows: 3
    width: parent ? parent.width : 0
    // the newest card is always fully visible, also with action buttons or a reply field
    readonly property int extra: model.length > 0 && (model[0].actions.length > 0 || model[0].reply) ? 44 : 0
    height: Math.min(contentHeight, maxRows * 74 + 22 + extra)
    spacing: 6
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    model: Notifs.sorted

    delegate: Column {
        id: d
        required property var modelData
        required property int index
        readonly property var e: modelData
        readonly property bool head: index === 0 || list.model[index - 1].app !== e.app
        readonly property string icon: Notifs.iconSource(e.icon)
        width: list.width
        spacing: 4

        Item {
            visible: d.head
            width: parent.width
            height: d.head ? 22 : 0
            Txt {
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                text: d.e.app
                size: 12
                weight: Font.DemiBold
                color: Theme.subtext
            }
            Icon {
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                text: "󰅖"
                size: 14
                color: Theme.subtext
                onClicked: Notifs.clearApp(d.e.app)
            }
        }

        Rectangle {
            id: card
            width: parent.width
            height: inner.implicitHeight + 20
            radius: 16
            color: d.e.urgent ? Theme.alpha("#ff6b6b", 0.18) : hov.hovered ? Theme.surfaceHigh : Theme.card
            opacity: 1 - Math.min(0.85, Math.abs(x) / width)
            Behavior on x { enabled: !drag.active; NumberAnimation { duration: Theme.dur(220); easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: Theme.dur(180) } }

            HoverHandler { id: hov }
            DragHandler {
                id: drag
                yAxis.enabled: false
                onActiveChanged: {
                    if (active) return
                    if (Math.abs(card.x) > card.width / 3) Notifs.remove(d.e.uid)
                    else card.x = 0
                }
            }
            TapHandler {
                gesturePolicy: TapHandler.ReleaseWithinBounds
                onTapped: if (d.e.hasDefault) Notifs.invoke(d.e.uid, "default")
            }

            Column {
                id: inner
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10
                anchors.leftMargin: 14
                spacing: 8

                Row {
                    width: parent.width
                    spacing: 12

                    Item {
                        width: 22
                        height: 22
                        anchors.verticalCenter: parent.verticalCenter
                        IconImage {
                            anchors.fill: parent
                            visible: d.icon !== ""
                            source: d.icon
                        }
                        Icon {
                            anchors.centerIn: parent
                            visible: d.icon === ""
                            text: "󰂚"
                            size: 18
                            color: Theme.accent
                            hoverable: false
                        }
                    }

                    Column {
                        width: parent.width - 34 - (thumb.visible ? 52 : 0) - (close.visible ? 22 : 0)
                        Txt {
                            width: parent.width
                            text: d.e.title
                            size: 13
                            weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                        Txt {
                            width: parent.width
                            visible: d.e.body !== ""
                            text: d.e.body
                            size: 12
                            color: Theme.subtext
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                        Txt {
                            text: Notifs.ago(d.e.time)
                            size: 11
                            color: Theme.alpha(Theme.subtext, 0.7)
                        }
                    }

                    ClippingRectangle {
                        id: thumb
                        visible: d.e.image !== ""
                        anchors.verticalCenter: parent.verticalCenter
                        width: 44
                        height: 44
                        radius: 10
                        color: "transparent"
                        Image {
                            anchors.fill: parent
                            source: d.e.image
                            fillMode: Image.PreserveAspectCrop
                            sourceSize.width: 88
                        }
                    }

                    Icon {
                        id: close
                        visible: hov.hovered
                        text: "󰅖"
                        size: 14
                        color: Theme.subtext
                        onClicked: Notifs.remove(d.e.uid)
                    }
                }

                Flow {
                    visible: d.e.actions.length > 0
                    width: parent.width
                    spacing: 6
                    Repeater {
                        model: d.e.actions.slice(0, 3)
                        Pill {
                            required property var modelData
                            implicitHeight: 28
                            text: modelData.text
                            onClicked: Notifs.invoke(d.e.uid, modelData.id)
                        }
                    }
                }

                Row {
                    visible: d.e.reply
                    width: parent.width
                    spacing: 6
                    Field {
                        id: answer
                        width: parent.width - send.width - 6
                        implicitHeight: 32
                        placeholder: d.e.replyHint || Lang.t.reply
                        onAccepted: Notifs.reply(d.e.uid, text)
                    }
                    Pill {
                        id: send
                        primary: true
                        implicitHeight: 32
                        icon: "󰒊"
                        onClicked: Notifs.reply(d.e.uid, answer.text)
                    }
                }
            }
        }
    }
}
