import QtQuick
import QtQuick.Shapes

// Bar glyph: line-drawn weather. `condition` is one of sun, moon, sun-cloud,
// moon-cloud, cloud, fog, drizzle, rain, sleet, snow, storm.
Item {
  id: root

  property string condition: "cloud"
  property color color: "#888888"

  readonly property real s: width / 16
  readonly property bool precip: ["drizzle", "rain", "sleet", "snow", "storm"].indexOf(condition) >= 0

  // Outline cloud, drawn in a 16-unit box and moved/scaled by ox, oy, k.
  component Cloud: Shape {
    property real ox: 0
    property real oy: 0
    property real k: 1
    function px(v) { return (ox + v * k) * root.s }
    function py(v) { return (oy + v * k) * root.s }
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeColor: root.color
      strokeWidth: 1.4 * root.s
      joinStyle: ShapePath.RoundJoin
      capStyle: ShapePath.RoundCap
      fillColor: "transparent"
      // three circles (left r2.5, top r3.6, right r2.5) joined at their
      // intersections over a flat base
      startX: px(4.6); startY: py(13)
      PathArc { x: px(4.81); y: py(8.01); radiusX: 2.5 * k * root.s; radiusY: radiusX; useLargeArc: true }
      PathArc { x: px(11.99); y: py(8); radiusX: 3.6 * k * root.s; radiusY: radiusX }
      PathArc { x: px(12); y: py(13); radiusX: 2.5 * k * root.s; radiusY: radiusX; useLargeArc: true }
      PathLine { x: px(4.6); y: py(13) }
    }
  }

  // Sun disc with rays; `rays` lists ray angles in degrees (0 = right).
  component Sun: Item {
    property real cx: 8
    property real cy: 8
    property real r: 2.8
    property real rayIn: 4.4
    property real rayOut: 6.2
    property var rays: [0, 45, 90, 135, 180, 225, 270, 315]
    anchors.fill: parent
    Rectangle {
      x: (cx - r) * root.s; y: (cy - r) * root.s
      width: r * 2 * root.s; height: width
      radius: width / 2
      color: "transparent"
      border.color: root.color
      border.width: 1.4 * root.s
    }
    Repeater {
      model: rays
      Shape {
        required property var modelData
        readonly property real a: modelData * Math.PI / 180
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
          strokeColor: root.color
          strokeWidth: 1.3 * root.s
          capStyle: ShapePath.RoundCap
          fillColor: "transparent"
          startX: (cx + Math.cos(a) * rayIn) * root.s; startY: (cy + Math.sin(a) * rayIn) * root.s
          PathLine { x: (cx + Math.cos(a) * rayOut) * root.s; y: (cy + Math.sin(a) * rayOut) * root.s }
        }
      }
    }
  }

  // Filled crescent opening to the right, centered on (cx, cy) with radius r.
  component Moon: Shape {
    property real cx: 8
    property real cy: 8
    property real r: 5.5
    readonly property real chordX: cx + r * 0.27
    readonly property real half: Math.sqrt(r * r - (r * 0.27) * (r * 0.27))
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeColor: "transparent"
      fillColor: root.color
      startX: chordX * root.s; startY: (cy - half) * root.s
      PathArc {
        x: chordX * root.s; y: (cy + half) * root.s
        radiusX: r * root.s; radiusY: radiusX
        useLargeArc: true
        direction: PathArc.Counterclockwise
      }
      PathArc {
        x: chordX * root.s; y: (cy - half) * root.s
        radiusX: r * 1.13 * root.s; radiusY: radiusX
        direction: PathArc.Clockwise
      }
    }
  }

  // Short slanted stroke (rain drop or fog bar) from (x1, y1) to (x2, y2).
  component Stroke: Shape {
    property real x1
    property real y1
    property real x2
    property real y2
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeColor: root.color
      strokeWidth: 1.4 * root.s
      capStyle: ShapePath.RoundCap
      fillColor: "transparent"
      startX: x1 * root.s; startY: y1 * root.s
      PathLine { x: x2 * root.s; y: y2 * root.s }
    }
  }

  component Flake: Rectangle {
    property real cx
    property real cy
    x: (cx - 0.9) * root.s; y: (cy - 0.9) * root.s
    width: 1.8 * root.s; height: width
    radius: width / 2
    color: root.color
  }

  // clear
  Sun { visible: root.condition === "sun" }
  Moon { visible: root.condition === "moon" }

  // partly cloudy: small sun / moon peeking over the top-right of a cloud
  Sun {
    visible: root.condition === "sun-cloud"
    cx: 10.6; cy: 5.2; r: 2.1; rayIn: 3.3; rayOut: 4.5
    rays: [180, 225, 270, 315, 0]
  }
  Moon { visible: root.condition === "moon-cloud"; cx: 11; cy: 5; r: 3.6 }
  Cloud { visible: root.condition === "sun-cloud" || root.condition === "moon-cloud"; ox: -0.6; oy: 2.4; k: 0.85 }

  // overcast
  Cloud { visible: root.condition === "cloud"; oy: -0.5 }

  // fog: cloud top with layered bars under it
  Item {
    anchors.fill: parent
    visible: root.condition === "fog"
    Cloud { oy: -3.5; k: 0.9; ox: 0.8 }
    Stroke { x1: 2.5; y1: 11.5; x2: 13.5; y2: 11.5 }
    Stroke { x1: 4.5; y1: 14.2; x2: 11.5; y2: 14.2 }
  }

  // precipitation: raised cloud with something falling out of it
  Cloud { visible: root.precip; oy: -3.5; k: 0.95; ox: 0.4 }

  Item {
    anchors.fill: parent
    visible: root.condition === "drizzle"
    Stroke { x1: 6.4; y1: 11.4; x2: 5.6; y2: 13.4 }
    Stroke { x1: 10.4; y1: 11.4; x2: 9.6; y2: 13.4 }
  }

  Item {
    anchors.fill: parent
    visible: root.condition === "rain"
    Stroke { x1: 5.2; y1: 11.2; x2: 4.2; y2: 14.4 }
    Stroke { x1: 8.4; y1: 11.2; x2: 7.4; y2: 14.4 }
    Stroke { x1: 11.6; y1: 11.2; x2: 10.6; y2: 14.4 }
  }

  Item {
    anchors.fill: parent
    visible: root.condition === "snow"
    Flake { cx: 5; cy: 12 }
    Flake { cx: 8.2; cy: 14 }
    Flake { cx: 11.4; cy: 12 }
  }

  Item {
    anchors.fill: parent
    visible: root.condition === "sleet"
    Stroke { x1: 5.2; y1: 11.2; x2: 4.2; y2: 14.4 }
    Flake { cx: 8.2; cy: 13 }
    Stroke { x1: 11.6; y1: 11.2; x2: 10.6; y2: 14.4 }
  }

  Shape {
    anchors.fill: parent
    visible: root.condition === "storm"
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeColor: "transparent"
      fillColor: root.color
      startX: 9.2 * root.s; startY: 9.6 * root.s
      PathLine { x: 6.2 * root.s; y: 12.9 * root.s }
      PathLine { x: 8.1 * root.s; y: 12.9 * root.s }
      PathLine { x: 7.2 * root.s; y: 15.6 * root.s }
      PathLine { x: 10.3 * root.s; y: 12 * root.s }
      PathLine { x: 8.5 * root.s; y: 12 * root.s }
      PathLine { x: 9.2 * root.s; y: 9.6 * root.s }
    }
  }
}
