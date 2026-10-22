import QtQuick
import QtQuick.Shapes

// Bar glyph: wifi arcs that light up with signal strength, a small
// three-node tree for ethernet, and dimmed arcs with a slash when offline.
Item {
  id: root

  property string kind: "disconnected"   // wifi | ethernet | disconnected
  property int signal: -1                 // 0..100
  property color color: "#888888"

  readonly property real s: width / 16
  readonly property int bars: kind !== "wifi" ? 0
    : signal >= 75 ? 3 : signal >= 50 ? 2 : signal >= 25 ? 1 : 0
  readonly property real dim: 0.25

  component Arc: Shape {
    property real r: 4
    property bool lit: false
    anchors.fill: parent
    opacity: lit ? 1 : root.dim
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeColor: root.color
      strokeWidth: 1.6 * root.s
      capStyle: ShapePath.RoundCap
      fillColor: "transparent"
      PathAngleArc {
        centerX: 8 * root.s; centerY: 13.2 * root.s
        radiusX: r * root.s; radiusY: r * root.s
        startAngle: -135; sweepAngle: 90
      }
    }
  }

  Item {
    anchors.fill: parent
    visible: root.kind !== "ethernet"

    Arc { r: 3.8; lit: root.bars >= 1 }
    Arc { r: 7.2; lit: root.bars >= 2 }
    Arc { r: 10.6; lit: root.bars >= 3 }

    Rectangle {
      x: 6.7 * root.s; y: 11.9 * root.s
      width: 2.6 * root.s; height: width
      radius: width / 2
      color: root.color
      opacity: root.kind === "wifi" ? 1 : root.dim
    }

    // offline slash
    Shape {
      anchors.fill: parent
      visible: root.kind === "disconnected"
      preferredRendererType: Shape.CurveRenderer
      ShapePath {
        strokeColor: root.color
        strokeWidth: 1.6 * root.s
        capStyle: ShapePath.RoundCap
        fillColor: "transparent"
        startX: 3 * root.s; startY: 2.5 * root.s
        PathLine { x: 13 * root.s; y: 14 * root.s }
      }
    }
  }

  // ethernet
  Shape {
    anchors.fill: parent
    visible: root.kind === "ethernet"
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeColor: root.color
      strokeWidth: 1.4 * root.s
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin
      fillColor: "transparent"
      PathRectangle { x: 5.5 * root.s; y: 1.5 * root.s; width: 5 * root.s; height: 4 * root.s; radius: 1 * root.s }
      PathRectangle { x: 1.5 * root.s; y: 10.5 * root.s; width: 5 * root.s; height: 4 * root.s; radius: 1 * root.s }
      PathRectangle { x: 9.5 * root.s; y: 10.5 * root.s; width: 5 * root.s; height: 4 * root.s; radius: 1 * root.s }
      PathMove { x: 8 * root.s; y: 5.5 * root.s }
      PathLine { x: 8 * root.s; y: 8 * root.s }
      PathMove { x: 4 * root.s; y: 10.5 * root.s }
      PathLine { x: 4 * root.s; y: 8 * root.s }
      PathLine { x: 12 * root.s; y: 8 * root.s }
      PathLine { x: 12 * root.s; y: 10.5 * root.s }
    }
  }
}
