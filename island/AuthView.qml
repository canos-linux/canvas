import QtQuick
import "../core"
import "../services"
import "../ui"

FocusScope {
    id: av
    property bool active: false
    readonly property var f: Auth.flow

    onActiveChanged: if (active) { pw.text = ""; focusT.restart() }
    Timer { id: focusT; interval: 90; onTriggered: pw.focusInput() }

    Connections {
        target: av.f
        ignoreUnknownSignals: true
        function onIsResponseRequiredChanged() {
            if (av.f && av.f.isResponseRequired) { pw.text = ""; focusT.restart() }
        }
        function onAuthenticationFailed() { shake.restart() }
    }

    function ok() { if (f) f.submit(pw.text) }
    function cancel() { if (f) f.cancelAuthenticationRequest() }

    Keys.onEscapePressed: cancel()

    Item {
        id: box
        width: parent.width
        height: parent.height

        SequentialAnimation {
            id: shake
            loops: 2
            NumberAnimation { target: box; property: "x"; to: -10; duration: 50 }
            NumberAnimation { target: box; property: "x"; to: 10; duration: 80 }
            NumberAnimation { target: box; property: "x"; to: 0; duration: 50 }
        }

        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 22
            spacing: 12

            Row {
                spacing: 12
                Rectangle {
                    width: 40
                    height: 40
                    radius: 20
                    color: Theme.accent
                    Icon { anchors.centerIn: parent; text: "󰌾"; size: 20; hoverable: false; color: Theme.base }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Txt { text: Lang.t.authTitle; size: 16; weight: Font.Bold }
                    Txt {
                        width: 340
                        text: av.f ? av.f.message : ""
                        size: 12
                        color: Theme.subtext
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }
            }

            Field {
                id: pw
                width: parent.width
                password: !(av.f && av.f.responseVisible)
                placeholder: av.f && av.f.inputPrompt ? av.f.inputPrompt.replace(/:\s*$/, "") : Lang.t.wifiPassword
                onAccepted: av.ok()
                Keys.onEscapePressed: av.cancel()
            }

            Txt {
                visible: text !== ""
                text: av.f && av.f.failed ? Lang.t.authFailed : av.f && av.f.supplementaryIsError ? av.f.supplementaryMessage : ""
                size: 12
                color: "#ff8a8a"
            }

            Row {
                anchors.right: parent.right
                spacing: 8
                Pill { text: Lang.t.cancel; onClicked: av.cancel() }
                Pill { text: "OK"; primary: true; onClicked: av.ok() }
            }
        }
    }
}
