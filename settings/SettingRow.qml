import QtQuick
import "../core"
import "../ui"

Item {
    id: row
    property string title: ""
    property string sub: ""
    default property alias control: holder.data
    width: parent ? parent.width : 400
    height: 66

    Column {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: holder.left
        anchors.rightMargin: 16
        spacing: 2
        Txt {
            text: row.title
            size: 15
            weight: Font.DemiBold
        }
        Txt {
            visible: text !== ""
            width: parent.width
            text: row.sub
            size: 12
            color: Theme.subtext
            wrapMode: Text.WordWrap
        }
    }

    Item {
        id: holder
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.alpha(Theme.text, 0.06)
    }
}
