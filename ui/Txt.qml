import QtQuick
import "../core"

Text {
    property int size: 14
    property int weight: Font.Normal
    color: Theme.text
    font.family: Theme.font
    font.pixelSize: size
    font.weight: weight
}
