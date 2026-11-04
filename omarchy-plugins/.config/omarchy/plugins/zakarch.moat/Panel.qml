import QtQuick
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "zakarch.moat"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var svc: bar && bar.shell ? bar.shell.serviceFor(moduleName) : null

  readonly property color fg: Color.popups.text
  readonly property color muted: Util.alpha(fg, 0.55)
  readonly property color accent: Color.accent
  readonly property string ff: bar ? bar.fontFamily : Style.font.family

  property var pickDays: [0, 1, 2, 3, 4]
  property string blockError: ""
  property string challenge: ""      // phrase to type for a pass; "" when not asking

  readonly property double now: svc ? svc.now : Date.now()
  readonly property bool typing: siteInput.activeFocus || fromInput.activeFocus || toInput.activeFocus || passInput.activeFocus

  readonly property string heroTitle: !svc ? "" : svc.passOpen ? "Pass open" : svc.inBlock ? "Blocked"
    : svc.activeBlocks.length ? "Free" : "No blocks yet"
  readonly property string heroMeta: {
    if (!svc) return ""
    if (svc.passOpen) return "Blocks again in " + Model.fmtClock(svc.pass.until - now)
    if (svc.inBlock) return "Until " + Model.fmtWhen(svc.span.end, now) + " · " + Model.fmtLeft(svc.span.end - now) + " left"
    if (svc.span.next) return "Next block " + Model.fmtWhen(svc.span.next, now) + " · in " + Model.fmtLeft(svc.span.next - now)
    return "Add a block below to start"
  }

  // idle | typing | sending | waiting | open | used
  readonly property string passState: {
    if (!svc) return "idle"
    if (svc.passOpen) return "open"
    if (svc.pass) return svc.pass.state === "waiting" ? "waiting" : "used"
    if (svc.unlock) return "sending"
    if (svc.passUsedToday) return "used"
    return challenge ? "typing" : "idle"
  }

  function sp(px) { return Style.space(px) }

  function toggleDay(d) {
    var next = pickDays.slice(), i = next.indexOf(d)
    if (i === -1) next.push(d)
    else next.splice(i, 1)
    pickDays = next.sort(function(a, b) { return a - b })
  }

  function submitBlock() {
    if (!svc) return
    blockError = svc.addBlock(pickDays, fromInput.text, toInput.text)
    if (!blockError) {
      fromInput.text = ""
      toInput.text = ""
      keys.forceActiveFocus()
    }
  }

  function submitSite() {
    if (svc && svc.addSite(siteInput.text)) siteInput.text = ""
  }

  function startChallenge() {
    challenge = Model.phrase()
    passInput.text = ""
    passInput.forceActiveFocus()
  }

  onOpenedChanged: if (!opened) {
    challenge = ""
    blockError = ""
  }

  // ── reusable bits ─────────────────────────────────────────────────────────
  component Caps: Text {
    textFormat: Text.PlainText
    color: root.muted
    font.family: root.ff
    font.pixelSize: Style.font.caption - 1
    font.bold: true
    font.letterSpacing: 1.4
  }

  component Body: Text {
    width: parent ? parent.width : implicitWidth
    textFormat: Text.PlainText
    wrapMode: Text.Wrap
    color: root.fg
    font.family: root.ff
    font.pixelSize: Style.font.body
  }

  component Card: Rectangle {
    radius: root.sp(12)
    color: Util.alpha(root.fg, 0.035)
    border.width: 1
    border.color: Util.alpha(root.fg, 0.07)
  }

  component Pill: Rectangle {
    id: pill
    property string label: ""
    property bool active: false
    signal clicked()
    height: root.sp(24)
    width: Math.max(height, pillText.implicitWidth + root.sp(18))
    radius: height / 2
    color: active ? Util.alpha(root.accent, 0.18) : pillMouse.containsMouse ? Util.alpha(root.fg, 0.09) : Util.alpha(root.fg, 0.03)
    border.width: 1
    border.color: active ? Util.alpha(root.accent, 0.6) : Util.alpha(root.fg, 0.10)
    Behavior on color { ColorAnimation { duration: 140 } }
    Text {
      id: pillText
      anchors.centerIn: parent
      text: pill.label
      color: pill.active ? root.accent : root.fg
      font.family: root.ff
      font.pixelSize: Style.font.caption
      font.bold: true
      font.letterSpacing: 1
    }
    MouseArea {
      id: pillMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: pill.clicked()
    }
  }

  component Field: Rectangle {
    property bool focused: false
    height: root.sp(34)
    radius: root.sp(9)
    color: Util.alpha(root.fg, focused ? 0.06 : 0.03)
    border.width: 1
    border.color: focused ? Util.alpha(root.accent, 0.8) : Util.alpha(root.fg, 0.10)
    Behavior on border.color { ColorAnimation { duration: 150 } }
  }

  component Input: TextInput {
    property string hint: ""
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: root.sp(10)
    anchors.rightMargin: root.sp(10)
    color: root.fg
    font.family: root.ff
    font.pixelSize: Style.font.body
    selectByMouse: true
    clip: true
    Keys.onEscapePressed: keys.forceActiveFocus()
    Text {
      visible: !parent.text
      text: parent.hint
      color: Util.alpha(root.fg, 0.3)
      font: parent.font
    }
  }

  // Trash glyph, or a lock while the running block keeps the item.
  component RemoveButton: Text {
    id: rm
    property bool locked: false
    signal clicked()
    text: locked ? "󰌾" : "󰆴"
    color: locked ? Util.alpha(root.fg, 0.3) : rmMouse.containsMouse ? Color.urgent : Util.alpha(root.fg, 0.4)
    font.family: root.ff
    font.pixelSize: Style.font.body
    MouseArea {
      id: rmMouse
      anchors.fill: parent
      anchors.margins: -root.sp(4)
      enabled: !rm.locked
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: rm.clicked()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keys
    contentWidth: panel.fittedContentWidth(root.sp(400))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keys
      anchors.fill: parent
      blocked: root.typing
      onCloseRequested: root.close()
      onTabRequested: function(d) {
        if (root.bar && typeof root.bar.switchPanelFrom === "function")
          root.bar.switchPanelFrom(root.hostWidget || root, d)
      }

      Flickable {
        id: scroller
        anchors.fill: parent
        contentHeight: content.implicitHeight
        interactive: contentHeight > height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
          id: content
          width: scroller.width
          spacing: root.sp(12)

          // ── hero: lock state ──────────────────────────────────────────────
          Item {
            width: parent.width
            height: Math.max(heroIcon.height, heroText.implicitHeight)

            MoatIcon {
              id: heroIcon
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              width: root.sp(44)
              height: width
              locked: root.svc ? root.svc.blocked : false
              remaining: root.svc ? root.svc.blockLeft : 0
              color: root.svc && root.svc.blocked ? root.accent : root.fg
            }

            Column {
              id: heroText
              anchors.left: heroIcon.right
              anchors.leftMargin: root.sp(14)
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              spacing: root.sp(2)
              Text {
                text: root.heroTitle
                color: root.fg
                font.family: root.ff
                font.pixelSize: Style.font.display
                font.weight: Font.Light
              }
              Text {
                width: parent.width
                text: root.heroMeta
                color: root.muted
                elide: Text.ElideRight
                font.family: root.ff
                font.pixelSize: Style.font.body
              }
              Text {
                visible: !!root.svc && root.svc.closedToday > 0
                text: root.svc ? "Closed " + root.svc.closedToday + " blocked app" + (root.svc.closedToday === 1 ? "" : "s") + " today" : ""
                color: root.muted
                font.family: root.ff
                font.pixelSize: Style.font.caption
              }
            }
          }

          // ── system lock missing ───────────────────────────────────────────
          Card {
            visible: !!root.svc && !root.svc.installed
            width: parent.width
            height: installCol.implicitHeight + root.sp(24)
            border.color: Util.alpha(Color.urgent, 0.4)
            Column {
              id: installCol
              x: root.sp(12)
              y: root.sp(12)
              width: parent.width - root.sp(24)
              spacing: root.sp(8)
              Body {
                text: root.svc && root.svc.stale ? "The system lock stopped running. Reinstall it to keep blocks enforced."
                  : "The system lock is off. Without it, blocks only close web app windows and are easy to skip."
              }
              Pill {
                label: "INSTALL SYSTEM LOCK"
                active: true
                onClicked: {
                  root.svc.installSystemLock()
                  root.close()
                }
              }
            }
          }

          Card {
            visible: !!root.svc && root.svc.held
            width: parent.width
            height: heldText.implicitHeight + root.sp(20)
            Body {
              id: heldText
              x: root.sp(12)
              y: root.sp(10)
              width: parent.width - root.sp(24)
              color: root.muted
              text: "Some edits loosen the running block. They apply when it ends."
            }
          }

          // ── emergency pass ────────────────────────────────────────────────
          Card {
            visible: !!root.svc && root.svc.installed && root.svc.inBlock
            width: parent.width
            height: passCol.implicitHeight + root.sp(24)
            Column {
              id: passCol
              x: root.sp(12)
              y: root.sp(12)
              width: parent.width - root.sp(24)
              spacing: root.sp(8)

              Caps { text: "EMERGENCY PASS" }
              Body {
                text: {
                  var s = root.svc, st = root.passState
                  if (!s) return ""
                  if (st === "open") return "Open. Blocks again in " + Model.fmtClock(s.pass.until - root.now) + "."
                  if (st === "waiting") return "Opens in " + Model.fmtClock(s.pass.from - root.now) + ". Still need it?"
                  if (st === "sending") return "Asking the system lock…"
                  if (st === "used") return "Today's pass is used. Back to work."
                  if (st === "typing") return "Type this to ask for 15 minutes. It opens 10 minutes later."
                  return "15 minutes of access, once a day, after a 10 minute wait."
                }
              }

              Text {
                visible: root.passState === "typing"
                width: parent.width
                text: root.challenge
                color: root.accent
                wrapMode: Text.Wrap
                font.family: root.ff
                font.pixelSize: Style.font.subtitle
                font.letterSpacing: 2
              }

              Field {
                visible: root.passState === "typing"
                width: parent.width
                focused: passInput.activeFocus
                Input {
                  id: passInput
                  property int lastLength: 0
                  hint: "Type it, no pasting"
                  selectByMouse: false
                  Keys.onPressed: function(event) { if (event.matches(StandardKey.Paste)) event.accepted = true }
                  onTextEdited: {
                    // Anything longer than one keystroke is a paste: start over.
                    if (text.length > lastLength + 1) text = ""
                    lastLength = text.length
                    if (text.trim() === root.challenge) {
                      root.challenge = ""
                      text = ""
                      keys.forceActiveFocus()
                      root.svc.requestPass()
                    }
                  }
                }
              }

              Row {
                spacing: root.sp(6)
                Pill {
                  visible: root.passState === "idle"
                  label: "I NEED IT"
                  onClicked: root.startChallenge()
                }
                Pill {
                  visible: root.passState === "typing"
                  label: "NEVER MIND"
                  onClicked: {
                    root.challenge = ""
                    keys.forceActiveFocus()
                  }
                }
                Pill {
                  visible: root.passState === "waiting" || root.passState === "sending"
                  label: "CANCEL"
                  onClicked: root.svc.cancelPass()
                }
              }
            }
          }

          // ── schedule ──────────────────────────────────────────────────────
          Caps { text: "SCHEDULE" }

          Column {
            width: parent.width
            spacing: root.sp(4)

            Repeater {
              model: root.svc ? root.svc.blocks : []
              delegate: Card {
                id: blockRow
                required property var modelData
                readonly property bool running: Model.inBlock([modelData], new Date(Math.floor(root.now / 60000) * 60000))
                width: parent.width
                height: root.sp(36)
                Rectangle {
                  visible: blockRow.running
                  x: root.sp(12)
                  anchors.verticalCenter: parent.verticalCenter
                  width: root.sp(6)
                  height: width
                  radius: width / 2
                  color: root.accent
                }
                Text {
                  x: root.sp(blockRow.running ? 26 : 12)
                  anchors.verticalCenter: parent.verticalCenter
                  text: Model.describeDays(blockRow.modelData.days)
                  color: root.fg
                  font.family: root.ff
                  font.pixelSize: Style.font.body
                }
                Text {
                  anchors.right: blockRm.left
                  anchors.rightMargin: root.sp(12)
                  anchors.verticalCenter: parent.verticalCenter
                  text: blockRow.modelData.start + " – " + blockRow.modelData.end
                  color: root.muted
                  font.family: root.ff
                  font.pixelSize: Style.font.body
                }
                RemoveButton {
                  id: blockRm
                  anchors.right: parent.right
                  anchors.rightMargin: root.sp(12)
                  anchors.verticalCenter: parent.verticalCenter
                  locked: !!root.svc && root.svc.blockLocked(blockRow.modelData)
                  onClicked: root.svc.removeBlock(blockRow.modelData)
                }
              }
            }
          }

          Flow {
            width: parent.width
            spacing: root.sp(4)
            Repeater {
              model: 7
              Pill {
                required property int index
                width: root.sp(28)
                label: Model.DAY_LETTERS[index]
                active: root.pickDays.indexOf(index) !== -1
                onClicked: root.toggleDay(index)
              }
            }
          }

          Row {
            width: parent.width
            spacing: root.sp(6)
            Field {
              width: (parent.width - addBlockBtn.width - root.sp(12)) / 2
              focused: fromInput.activeFocus
              Input {
                id: fromInput
                hint: "From  9"
                onAccepted: toInput.forceActiveFocus()
                Keys.onTabPressed: toInput.forceActiveFocus()
              }
            }
            Field {
              width: (parent.width - addBlockBtn.width - root.sp(12)) / 2
              focused: toInput.activeFocus
              Input {
                id: toInput
                hint: "To  17:30"
                onAccepted: root.submitBlock()
              }
            }
            Pill {
              id: addBlockBtn
              anchors.verticalCenter: parent.verticalCenter
              label: "ADD"
              active: fromInput.text !== "" && toInput.text !== ""
              onClicked: root.submitBlock()
            }
          }

          Text {
            visible: root.blockError !== ""
            text: root.blockError
            color: Color.urgent
            font.family: root.ff
            font.pixelSize: Style.font.caption
          }

          // ── sites ─────────────────────────────────────────────────────────
          Caps { text: "SITES" }

          Flow {
            width: parent.width
            spacing: root.sp(6)
            visible: !!root.svc && root.svc.sites.length > 0
            Repeater {
              model: root.svc ? root.svc.sites : []
              delegate: Rectangle {
                id: chip
                required property string modelData
                height: root.sp(26)
                width: chipText.implicitWidth + chipRm.implicitWidth + root.sp(28)
                radius: height / 2
                color: Util.alpha(root.fg, 0.04)
                border.width: 1
                border.color: Util.alpha(root.fg, 0.10)
                Text {
                  id: chipText
                  x: root.sp(10)
                  anchors.verticalCenter: parent.verticalCenter
                  text: chip.modelData
                  color: root.fg
                  font.family: root.ff
                  font.pixelSize: Style.font.caption
                }
                RemoveButton {
                  id: chipRm
                  anchors.right: parent.right
                  anchors.rightMargin: root.sp(9)
                  anchors.verticalCenter: parent.verticalCenter
                  font.pixelSize: Style.font.caption
                  locked: !!root.svc && root.svc.siteLocked(chip.modelData)
                  onClicked: root.svc.removeSite(chip.modelData)
                }
              }
            }
          }

          Field {
            width: parent.width
            focused: siteInput.activeFocus
            Input {
              id: siteInput
              hint: "Add a site, like reddit.com"
              onAccepted: root.submitSite()
            }
          }

          Flow {
            width: parent.width
            spacing: root.sp(4)
            Repeater {
              model: Model.PRESETS.filter(function(p) { return !root.svc || !Model.presetAdded(root.svc.sites, p) })
              Pill {
                required property var modelData
                label: "+ " + modelData.name.toUpperCase()
                onClicked: root.svc.addPreset(modelData)
              }
            }
          }
        }
      }
    }
  }
}
