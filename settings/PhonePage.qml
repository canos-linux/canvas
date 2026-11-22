import QtQuick
import "../core"
import "../services"
import "../ui"

Column {
    id: page
    width: parent ? parent.width : 400
    onVisibleChanged: if (visible) Phone.refresh()

    SettingRow {
        title: Lang.t.phoneOn
        sub: Lang.t.phoneOnSub
        Toggle { checked: Config.opt.phone; onToggled: v => Config.opt.phone = v }
    }

    Column {
        width: parent.width
        visible: Config.opt.phone
        spacing: 10

        Row {
            visible: !Phone.installed
            spacing: 14
            topPadding: 6
            Txt {
                anchors.verticalCenter: parent.verticalCenter
                width: page.width - 160
                text: Lang.t.phoneMissing
                color: Theme.subtext
                wrapMode: Text.WordWrap
            }
            PillButton {
                anchors.verticalCenter: parent.verticalCenter
                text: Lang.t.phoneInstall
                primary: true
                onClicked: Phone.install()
            }
        }

        Txt {
            visible: Phone.installed
            width: page.width
            text: Phone.devices.length === 0 ? Lang.t.phoneNone : Lang.t.phoneHow
            size: 13
            color: Theme.subtext
            wrapMode: Text.WordWrap
            topPadding: 6
        }

        Repeater {
            model: Phone.devices
            Rectangle {
                width: page.width
                height: 120
                radius: 22
                color: Theme.surface

                Icon {
                    id: phIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.top: parent.top
                    anchors.topMargin: 20
                    text: "󰄜"
                    size: 30
                    color: modelData.reachable ? Theme.accent : Theme.subtext
                    hoverable: false
                }
                Column {
                    anchors.left: phIcon.right
                    anchors.leftMargin: 14
                    anchors.top: parent.top
                    anchors.topMargin: 18
                    Txt { text: modelData.name; size: 16; weight: Font.DemiBold }
                    Txt {
                        text: (modelData.paired ? (modelData.reachable ? Lang.t.phoneConnected : Lang.t.phoneAway) : Lang.t.phoneNotPaired) + (modelData.battery >= 0 ? "  ·  " + modelData.battery + " %" + (modelData.charging ? " ⚡" : "") : "")
                        size: 12
                        color: Theme.subtext
                    }
                }
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 16
                    spacing: 8
                    PillButton {
                        visible: !modelData.paired
                        text: Lang.t.phonePair
                        primary: true
                        onClicked: Phone.pair(modelData.id)
                    }
                    PillButton {
                        visible: modelData.paired && modelData.reachable
                        text: Lang.t.phoneRing
                        onClicked: Phone.ring(modelData.id)
                    }
                    PillButton {
                        visible: modelData.paired && modelData.reachable
                        text: Lang.t.phoneSendClip
                        onClicked: Phone.sendClipboard(modelData.id)
                    }
                    PillButton {
                        visible: modelData.paired
                        text: Lang.t.phoneUnpair
                        onClicked: Phone.unpair(modelData.id)
                    }
                }
            }
        }
    }
}
