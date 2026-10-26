import QtQuick
import QtQuick.Shapes

// Bar glyph: a calendar page whose bar fills with today's progress.
Item {
  id: root

  property real progress: 0        // 0..1
  property color color: "#888888"

  readonly property real s: width / 16

  implicitWidth: 16
  implicitHeight: 16

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeColor: root.color
      strokeWidth: 1.4 * root.s
      fillColor: "transparent"
      capStyle: ShapePath.RoundCap
      PathRectangle { x: 2 * root.s; y: 3 * root.s; width: 12 * root.s; height: 11.5 * root.s; radius: 2 * root.s }
      PathMove { x: 5.5 * root.s; y: 1.5 * root.s }
      PathLine { x: 5.5 * root.s; y: 4.5 * root.s }
      PathMove { x: 10.5 * root.s; y: 1.5 * root.s }
      PathLine { x: 10.5 * root.s; y: 4.5 * root.s }
      PathMove { x: 2 * root.s; y: 6.8 * root.s }
      PathLine { x: 14 * root.s; y: 6.8 * root.s }
    }
  }

  Rectangle {
    x: 4.5 * root.s
    y: 9.6 * root.s
    width: 7 * root.s
    height: 1.6 * root.s
    radius: height / 2
    color: root.color
    opacity: 0.25
  }

  Rectangle {
    x: 4.5 * root.s
    y: 9.6 * root.s
    width: 7 * root.s * Math.max(0, Math.min(1, root.progress))
    height: 1.6 * root.s
    radius: height / 2
    color: root.color
    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
  }
}
