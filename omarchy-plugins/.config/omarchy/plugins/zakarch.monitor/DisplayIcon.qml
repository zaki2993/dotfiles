import QtQuick
import QtQuick.Shapes

// Bar glyph: a monitor with a small sun inside. The number of lit rays
// follows the brightness; a second screen peeks out behind when there are two.
Item {
  id: root

  property int brightness: -1      // 0..100, -1 hides the sun
  property bool multi: false
  property color color: "#888888"

  readonly property real s: width / 16
  readonly property real dx: multi ? -1 : 0
  readonly property real cx: 8 + dx
  readonly property real cy: 7
  readonly property int litRays: Math.round(Math.max(0, Math.min(100, brightness)) / 12.5)

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeColor: root.color
      strokeWidth: 1.4 * root.s
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin
      fillColor: "transparent"
      PathRectangle { x: (1.5 + root.dx) * root.s; y: 2.5 * root.s; width: 13 * root.s; height: 9 * root.s; radius: 1.8 * root.s }
      PathMove { x: root.cx * root.s; y: 11.5 * root.s }
      PathLine { x: root.cx * root.s; y: 13.8 * root.s }
      PathMove { x: (root.cx - 3) * root.s; y: 13.8 * root.s }
      PathLine { x: (root.cx + 3) * root.s; y: 13.8 * root.s }
    }
  }

  // second screen, only its top and right edges show
  Shape {
    anchors.fill: parent
    visible: root.multi
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeColor: root.color
      strokeWidth: 1.2 * root.s
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin
      fillColor: "transparent"
      startX: 3 * root.s; startY: 1 * root.s
      PathLine { x: 15.3 * root.s; y: 1 * root.s }
      PathLine { x: 15.3 * root.s; y: 9 * root.s }
    }
  }

  Item {
    anchors.fill: parent
    visible: root.brightness >= 0

    Rectangle {
      x: (root.cx - 1.2) * root.s; y: (root.cy - 1.2) * root.s
      width: 2.4 * root.s; height: width
      radius: width / 2
      color: root.color
    }

    Repeater {
      model: 8
      Shape {
        required property int index
        readonly property real a: index * Math.PI / 4 - Math.PI / 2
        anchors.fill: parent
        opacity: index < root.litRays ? 1 : 0.25
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
          strokeColor: root.color
          strokeWidth: 1.2 * root.s
          capStyle: ShapePath.RoundCap
          fillColor: "transparent"
          startX: (root.cx + Math.cos(a) * 2.4) * root.s; startY: (root.cy + Math.sin(a) * 2.4) * root.s
          PathLine { x: (root.cx + Math.cos(a) * 3.5) * root.s; y: (root.cy + Math.sin(a) * 3.5) * root.s }
        }
      }
    }
  }
}
