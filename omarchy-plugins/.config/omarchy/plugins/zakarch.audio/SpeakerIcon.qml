import QtQuick
import QtQuick.Shapes

// Bar glyph: a rounded-outline speaker whose sound waves light up with volume,
// an X when muted, and outlined headphones for headsets.
Item {
  id: root

  property real volume: 0          // 0..1+
  property bool muted: false
  property bool headphones: false
  property color color: "#888888"

  readonly property real s: width / 16
  readonly property int waves: muted ? 0 : volume >= 0.67 ? 3 : volume >= 0.34 ? 2 : volume > 0 ? 1 : 0
  readonly property real dim: 0.24

  component Wave: Shape {
    property real r: 3
    property bool lit: false
    anchors.fill: parent
    opacity: lit ? 1 : root.dim
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeColor: root.color
      strokeWidth: 1.4 * root.s
      capStyle: ShapePath.RoundCap
      fillColor: "transparent"
      PathAngleArc {
        centerX: 7.7 * root.s; centerY: 8 * root.s
        radiusX: r * root.s; radiusY: r * root.s
        startAngle: -46; sweepAngle: 92
      }
    }
  }

  Item {
    anchors.fill: parent
    visible: !root.headphones

    // Outlined speaker cone with subtle duotone fill
    Shape {
      anchors.fill: parent
      preferredRendererType: Shape.CurveRenderer
      ShapePath {
        strokeColor: root.color
        strokeWidth: 1.4 * root.s
        joinStyle: ShapePath.RoundJoin
        capStyle: ShapePath.RoundCap
        fillColor: Qt.rgba(root.color.r, root.color.g, root.color.b, 0.14)
        startX: 1.6 * root.s; startY: 5.9 * root.s
        PathLine { x: 4.3 * root.s; y: 5.9 * root.s }
        PathLine { x: 7.6 * root.s; y: 3.1 * root.s }
        PathLine { x: 7.6 * root.s; y: 12.9 * root.s }
        PathLine { x: 4.3 * root.s; y: 10.1 * root.s }
        PathLine { x: 1.6 * root.s; y: 10.1 * root.s }
        PathLine { x: 1.6 * root.s; y: 5.9 * root.s }
      }
    }

    Item {
      anchors.fill: parent
      visible: !root.muted
      Wave { r: 2.6; lit: root.waves >= 1 }
      Wave { r: 4.9; lit: root.waves >= 2 }
      Wave { r: 7.2; lit: root.waves >= 3 }
    }

    // mute cross
    Shape {
      anchors.fill: parent
      visible: root.muted
      preferredRendererType: Shape.CurveRenderer
      ShapePath {
        strokeColor: root.color
        strokeWidth: 1.4 * root.s
        capStyle: ShapePath.RoundCap
        fillColor: "transparent"
        startX: 10.5 * root.s; startY: 5.8 * root.s
        PathLine { x: 14.7 * root.s; y: 10.2 * root.s }
        PathMove { x: 14.7 * root.s; y: 5.8 * root.s }
        PathLine { x: 10.5 * root.s; y: 10.2 * root.s }
      }
    }
  }

  // headphones (matching outlined duotone weight)
  Item {
    anchors.fill: parent
    visible: root.headphones
    opacity: root.muted ? 0.4 : 1

    Shape {
      anchors.fill: parent
      preferredRendererType: Shape.CurveRenderer
      ShapePath {
        strokeColor: root.color
        strokeWidth: 1.4 * root.s
        capStyle: ShapePath.RoundCap
        fillColor: "transparent"
        PathAngleArc {
          centerX: 8 * root.s; centerY: 8.8 * root.s
          radiusX: 5.8 * root.s; radiusY: 6.2 * root.s
          startAngle: 180; sweepAngle: 180
        }
      }
    }
    Shape {
      anchors.fill: parent
      preferredRendererType: Shape.CurveRenderer
      ShapePath {
        strokeColor: root.color
        strokeWidth: 1.4 * root.s
        joinStyle: ShapePath.RoundJoin
        fillColor: Qt.rgba(root.color.r, root.color.g, root.color.b, 0.14)
        PathRectangle { x: 1.4 * root.s; y: 8.6 * root.s; width: 3.3 * root.s; height: 5.2 * root.s; radius: 1.3 * root.s }
        PathRectangle { x: 11.3 * root.s; y: 8.6 * root.s; width: 3.3 * root.s; height: 5.2 * root.s; radius: 1.3 * root.s }
      }
    }
  }
}
