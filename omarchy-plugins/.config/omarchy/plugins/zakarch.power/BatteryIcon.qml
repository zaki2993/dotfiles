import QtQuick
import QtQuick.Shapes

// Bar glyph: a sideways battery whose fill matches the real charge.
// The terminal nub turns red while charging; the fill turns red when low.
Item {
  id: root

  property real level: 0          // 0..1
  property bool charging: false
  property bool low: false
  property color color: "#888888"
  property color lowColor: "#e06c75"

  readonly property real s: width / 16
  readonly property color fillColor: low ? lowColor : color

  // body
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeColor: root.color
      strokeWidth: 1.4 * root.s
      fillColor: "transparent"
      PathRectangle { x: 1 * root.s; y: 4.5 * root.s; width: 12.5 * root.s; height: 7 * root.s; radius: 2 * root.s }
    }
  }

  // terminal nub
  Rectangle {
    x: 14.3 * root.s; y: 6.5 * root.s
    width: 1.3 * root.s; height: 3 * root.s
    radius: 0.6 * root.s
    color: root.charging ? root.lowColor : root.color
  }

  // charge fill
  Rectangle {
    x: 2.8 * root.s; y: 6.3 * root.s
    height: 3.4 * root.s
    width: Math.max(root.level > 0 ? 1 * root.s : 0, 8.9 * root.s * Math.max(0, Math.min(1, root.level)))
    radius: 0.8 * root.s
    color: root.fillColor
  }
}
