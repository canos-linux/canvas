import QtQuick
import "../core"
import "../services"
import "../ui"

Column {
    id: page
    width: parent ? parent.width : 400
    spacing: 10
    property int confirm: -1
    onVisibleChanged: if (visible) Snapshots.refresh()

    Txt {
        width: parent.width
        text: Lang.t.snapAbout
        size: 13
        color: Theme.subtext
        wrapMode: Text.WordWrap
        bottomPadding: 6
    }

    Row {
        visible: Snapshots.checked && !Snapshots.ready
        spacing: 12
        PillButton {
            text: Lang.t.snapSetup
            primary: true
            busy: Snapshots.busy === "setup"
            enabled: Snapshots.busy === ""
            onClicked: Snapshots.setup()
        }
        Txt { anchors.verticalCenter: parent.verticalCenter; text: Lang.t.snapSetupSub; size: 12; color: Theme.subtext }
    }

    Row {
        visible: Snapshots.ready
        spacing: 12
        PillButton {
            text: Lang.t.snapCreate
            primary: true
            enabled: Snapshots.busy === ""
            onClicked: Snapshots.create(Lang.t.snapManual)
        }
        Spinner { visible: Snapshots.busy !== ""; anchors.verticalCenter: parent.verticalCenter }
    }

    Txt {
        visible: Snapshots.message !== ""
        width: parent.width
        text: Snapshots.message
        size: 13
        color: Theme.accent
        wrapMode: Text.WordWrap
    }

    Repeater {
        model: Snapshots.ready ? Snapshots.list : []
        Rectangle {
            required property var modelData
            width: page.width
            height: page.confirm === modelData.num ? 108 : 64
            radius: 18
            color: Theme.surface
            Behavior on height { NumberAnimation { duration: Theme.dur(200) } }
            clip: true

            Icon {
                id: snapIcon
                x: 18
                y: 20
                text: modelData.type === "pre" || modelData.type === "post" ? "󰏗" : "󰆓"
                size: 22
                color: Theme.accent
                hoverable: false
            }
            Column {
                x: 54
                y: 13
                width: parent.width - 230
                Txt { width: parent.width; text: modelData.desc || ("#" + modelData.num); weight: Font.DemiBold; elide: Text.ElideRight }
                Txt { text: "#" + modelData.num + "  ·  " + modelData.date; size: 12; color: Theme.subtext }
            }
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 14
                y: 15
                spacing: 6
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰆴"
                    size: 17
                    color: Theme.subtext
                    onClicked: Snapshots.remove(modelData.num)
                }
                PillButton {
                    text: Lang.t.snapRestore
                    enabled: Snapshots.busy === ""
                    onClicked: page.confirm = page.confirm === modelData.num ? -1 : modelData.num
                }
            }
            Row {
                visible: page.confirm === modelData.num
                x: 18
                y: 66
                spacing: 10
                Txt { anchors.verticalCenter: parent.verticalCenter; width: page.width - 190; text: Lang.t.snapConfirm; size: 12; color: Theme.subtext; wrapMode: Text.WordWrap }
                PillButton {
                    text: Lang.t.snapYes
                    primary: true
                    onClicked: {
                        Snapshots.restore(modelData.num)
                        page.confirm = -1
                    }
                }
            }
        }
    }
}
