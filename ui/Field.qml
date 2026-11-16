import QtQuick
import "../core"

Rectangle {
    id: field
    property alias text: input.text
    property alias input: input
    property string placeholder: ""
    property bool password: false
    property bool reveal: false
    signal accepted()

    implicitHeight: 38
    radius: height / 2
    color: Theme.surfaceHigh
    border.width: 1
    border.color: input.activeFocus ? Theme.accent : "transparent"
    Behavior on border.color { ColorAnimation { duration: Theme.dur(180) } }

    function focusInput() { input.forceActiveFocus() }

    TextInput {
        id: input
        anchors.left: parent.left
        anchors.right: eye.visible ? eye.left : parent.right
        anchors.leftMargin: 16
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.text
        selectionColor: Theme.alpha(Theme.accent, 0.4)
        font.family: Theme.font
        font.pixelSize: 14
        clip: true
        echoMode: field.password && !field.reveal ? TextInput.Password : TextInput.Normal
        passwordCharacter: "•"
        Keys.onReturnPressed: field.accepted()
        Keys.onEnterPressed: field.accepted()
    }

    Txt {
        anchors.left: input.left
        anchors.verticalCenter: parent.verticalCenter
        visible: input.text === ""
        text: field.placeholder
        size: 14
        color: Theme.alpha(Theme.subtext, 0.6)
    }

    Icon {
        id: eye
        visible: field.password
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: field.reveal ? "󰈉" : "󰈈"
        size: 18
        color: field.reveal ? Theme.accent : Theme.subtext
        onClicked: field.reveal = !field.reveal
    }
}
