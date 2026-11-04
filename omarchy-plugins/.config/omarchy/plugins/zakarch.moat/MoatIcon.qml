import QtQuick
import QtQuick.Shapes

// Bar glyph: a padlock. The shackle closes during a block and the bar
// inside drains as the block runs out.
Item {
  id: root

  property bool locked: false
  property real remaining: 0       // 0..1 of the block still to go
  property color color: "#888888"

  readonly property real s: width / 16
  property real lift: locked ? 0 : 1.6

  implicitWidth: 16
  implicitHeight: 16

  Behavior on lift { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeColor: root.color
      strokeWidth: 1.4 * root.s
      fillColor: "transparent"
      capStyle: ShapePath.RoundCap
      PathMove { x: 5.2 * root.s; y: (7.2 - root.lift) * root.s }
      PathLine { x: 5.2 * root.s; y: (4.8 - root.lift) * root.s }
      PathArc { x: 10.8 * root.s; y: (4.8 - root.lift) * root.s; radiusX: 2.8 * root.s; radiusY: 2.8 * root.s }
      PathLine { x: 10.8 * root.s; y: (root.locked ? 7.2 : 5.4 - root.lift) * root.s }
    }
    ShapePath {
      strokeColor: root.color
      strokeWidth: 1.4 * root.s
      fillColor: "transparent"
      PathRectangle { x: 3 * root.s; y: 7.2 * root.s; width: 10 * root.s; height: 7.3 * root.s; radius: 1.8 * root.s }
    }
  }

  Rectangle {
    x: 5.4 * root.s
    y: 10.15 * root.s
    width: 5.2 * root.s
    height: 1.4 * root.s
    radius: height / 2
    color: root.color
    opacity: 0.25
  }

  Rectangle {
    x: 5.4 * root.s
    y: 10.15 * root.s
    width: 5.2 * root.s * Math.max(0, Math.min(1, root.remaining))
    height: 1.4 * root.s
    radius: height / 2
    color: root.color
    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
  }
}
