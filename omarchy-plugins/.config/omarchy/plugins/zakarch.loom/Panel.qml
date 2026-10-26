import QtQuick
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "zakarch.loom"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var svc: bar && bar.shell ? bar.shell.serviceFor(moduleName) : null
  readonly property var plan: svc ? svc.plan : Model.empty()
  readonly property string today: svc ? svc.today : Model.dayKey(new Date())

  property string tab: "week"
  property string selectedDay: today
  property int cursor: -1
  property string pickGoal: ""
  property string editingId: ""
  property bool editTyping: false
  property bool returnKey: false
  property string draftText: ""
  property string draftFrom: ""
  property string draftTo: ""
  property string draftGoal: ""

  readonly property string viewWeek: Model.weekStart(selectedDay)
  readonly property var days: Model.weekDays(viewWeek)
  readonly property var rows: Model.weave(plan, viewWeek)
  readonly property var tasks: Model.tasksFor(plan, selectedDay)
  readonly property var stats: Model.dayStats(plan, selectedDay)
  readonly property real dayRatio: stats.planned ? stats.worked / stats.planned : stats.total ? stats.done / stats.total : 0
  readonly property int carryCount: selectedDay === today ? Model.unfinished(plan, Model.addDays(today, -1)).length : 0
  readonly property var pickedGoal: Model.goalById(plan, pickGoal)
  readonly property bool addOpen: taskInput.activeFocus || taskInput.text !== "" || addFrom.hasFocus || addTo.hasFocus
    || addFrom.text !== "" || addTo.text !== "" || pickGoal !== ""
  readonly property bool typing: taskInput.activeFocus || goalInput.activeFocus || editTyping

  readonly property color fg: Color.popups.text
  readonly property color muted: Util.alpha(fg, 0.55)
  readonly property color accent: Color.accent
  readonly property string ff: bar ? bar.fontFamily : Style.font.family

  function sp(px) { return Style.space(px) }
  function goalColor(id) {
    var g = Model.goalById(plan, id)
    return g ? g.color : muted
  }

  onOpenedChanged: if (opened) {
    selectedDay = today
    cursor = -1
    tab = "week"
    pickGoal = ""
    editingId = ""
  }
  onSelectedDayChanged: {
    cursor = -1
    editingId = ""
  }
  onTabChanged: {
    cursor = -1
    editingId = ""
  }
  onEditingIdChanged: if (!editingId) editTyping = false

  function submitAdd() {
    if (!svc) return
    if (svc.addTask(selectedDay, taskInput.text, pickGoal, addFrom.text, addTo.text)) {
      taskInput.text = ""
      addFrom.text = ""
      addTo.text = ""
      taskInput.forceActiveFocus()
    }
  }

  function beginEdit(t) {
    draftText = t.text
    draftFrom = t.time
    draftTo = t.end
    draftGoal = t.goal
    editingId = t.id
  }

  function stopEditing() {
    editingId = ""
    release()
  }

  function moveDay(n) { selectedDay = Model.addDays(selectedDay, n) }
  function cyclePick() {
    var ids = [""].concat(plan.goals.map(function(g) { return g.id }))
    pickGoal = ids[(ids.indexOf(pickGoal) + 1) % ids.length]
  }
  function focusAdd() { (tab === "week" ? taskInput : goalInput).forceActiveFocus() }
  function release() { keys.forceActiveFocus() }

  function moveCursor(dx, dy) {
    if (tab === "week") {
      if (dx) moveDay(dx)
      if (dy && tasks.length) cursor = cursor < 0 ? 0 : (cursor + dy + tasks.length) % tasks.length
    } else {
      var g = plan.goals
      if (dy && g.length) cursor = cursor < 0 ? 0 : (cursor + dy + g.length) % g.length
    }
  }

  // Enter edits the task under the cursor, space marks it done.
  function activate() {
    var enter = returnKey
    returnKey = false
    if (!svc) return
    if (tab === "week" && tasks[cursor]) {
      if (enter) beginEdit(tasks[cursor])
      else svc.toggleTask(selectedDay, tasks[cursor].id)
    }
    else if (tab === "goals" && plan.goals[cursor]) svc.toggleGoal(plan.goals[cursor].id)
  }

  function removeAtCursor() {
    if (!svc) return
    if (tab === "week" && tasks[cursor]) {
      svc.removeTask(selectedDay, tasks[cursor].id)
      cursor = Math.min(cursor, tasks.length - 1)
    } else if (tab === "goals" && plan.goals[cursor]) {
      svc.removeGoal(plan.goals[cursor].id)
      cursor = Math.min(cursor, plan.goals.length - 1)
    }
  }

  function textKey(t) {
    if (t === "a" || t === "i" || t === "n") focusAdd()
    else if (t === "g") tab = tab === "week" ? "goals" : "week"
    else if (t === "t") selectedDay = today
    else if (t === "[") moveDay(-7)
    else if (t === "]") moveDay(7)
    else if (t === "c" && tab === "week" && svc && tasks[cursor]) svc.cycleTaskGoal(selectedDay, tasks[cursor].id)
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

  component Card: Rectangle {
    radius: root.sp(12)
    color: Util.alpha(root.fg, 0.035)
    border.width: 1
    border.color: Util.alpha(root.fg, 0.07)
  }

  // Small labelled time box for the task editor ("FROM 12:00").
  component TimeField: Rectangle {
    id: tf
    property string label: ""
    property alias text: tfInput.text
    property bool bad: false
    signal accepted()
    signal tabbed()
    signal edited()
    readonly property bool hasFocus: tfInput.activeFocus
    function focusInput() { tfInput.forceActiveFocus() }
    width: root.sp(104)
    height: root.sp(32)
    radius: root.sp(8)
    color: Util.alpha(root.fg, tfInput.activeFocus ? 0.06 : 0.03)
    border.width: 1
    border.color: bad ? Color.urgent : tfInput.activeFocus ? Util.alpha(root.accent, 0.8) : Util.alpha(root.fg, 0.10)
    Caps {
      id: tfLabel
      x: root.sp(10)
      anchors.verticalCenter: parent.verticalCenter
      text: tf.label
    }
    TextInput {
      id: tfInput
      anchors.left: tfLabel.right
      anchors.leftMargin: root.sp(8)
      anchors.right: parent.right
      anchors.rightMargin: root.sp(8)
      anchors.verticalCenter: parent.verticalCenter
      color: root.fg
      font.family: root.ff
      font.pixelSize: Style.font.body
      selectByMouse: true
      clip: true
      onAccepted: tf.accepted()
      onTextEdited: tf.edited()
      onActiveFocusChanged: root.editTyping = activeFocus
      Keys.onEscapePressed: root.stopEditing()
      Keys.onTabPressed: tf.tabbed()
      Text {
        visible: !tfInput.text
        text: "--:--"
        color: Util.alpha(root.fg, 0.3)
        font: tfInput.font
      }
    }
  }

  // One chip per open goal plus a "none" chip; the selected one is filled.
  component GoalChips: Flow {
    id: chips
    property string selected: ""
    property string noneLabel: "NONE"
    signal picked(string id)
    spacing: root.sp(4)
    Repeater {
      model: [{ id: "", title: chips.noneLabel, color: "" }].concat(root.plan.goals.filter(function(g) {
        return !g.done || g.id === chips.selected
      }))
      Rectangle {
        id: chip
        required property var modelData
        readonly property bool on: chips.selected === modelData.id
        readonly property color tint: modelData.color ? modelData.color : root.fg
        height: root.sp(24)
        width: chipText.x + chipText.implicitWidth + root.sp(10)
        radius: height / 2
        color: on ? Util.alpha(tint, 0.2) : chipMouse.containsMouse ? Util.alpha(root.fg, 0.08) : "transparent"
        border.width: 1
        border.color: on ? Util.alpha(tint, 0.8) : Util.alpha(root.fg, 0.12)
        Behavior on color { ColorAnimation { duration: 120 } }
        Rectangle {
          visible: !!chip.modelData.color
          x: root.sp(9)
          anchors.verticalCenter: parent.verticalCenter
          width: root.sp(7)
          height: width
          radius: width / 2
          color: chip.tint
        }
        Text {
          id: chipText
          x: chip.modelData.color ? root.sp(22) : root.sp(10)
          anchors.verticalCenter: parent.verticalCenter
          textFormat: Text.PlainText
          text: chip.modelData.color ? Model.shortTitle(chip.modelData.title) : chip.modelData.title
          color: chip.on ? chip.tint : root.fg
          font.family: root.ff
          font.pixelSize: Style.font.caption
          font.bold: true
        }
        MouseArea {
          id: chipMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: chips.picked(chip.modelData.id)
        }
      }
    }
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
    height: root.sp(36)
    radius: root.sp(9)
    color: Util.alpha(root.fg, focused ? 0.06 : 0.03)
    border.width: 1
    border.color: focused ? Util.alpha(root.accent, 0.8) : Util.alpha(root.fg, 0.10)
    Behavior on border.color { ColorAnimation { duration: 150 } }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keys
    contentWidth: panel.fittedContentWidth(root.sp(440))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keys
      anchors.fill: parent
      blocked: root.typing
      onCloseRequested: root.close()
      onMoveRequested: function(dx, dy) { root.moveCursor(dx, dy) }
      onReturnRequested: root.returnKey = true
      onActivateRequested: root.activate()
      onDeleteRequested: root.removeAtCursor()
      onTextKey: function(t) { root.textKey(t) }
      onTabRequested: function(d) {
        if (root.bar && typeof root.bar.switchPanelFrom === "function")
          root.bar.switchPanelFrom(root.hostWidget || root, d)
      }

      // Scrolls only when the panel is taller than the screen allows.
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
        spacing: root.sp(10)

        // ── hero: selected day, week, navigation ──────────────────────────
        Item {
          width: parent.width
          height: Math.max(bigDay.implicitHeight, heroRight.implicitHeight)

          Text {
            id: bigDay
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: Model.parseKey(root.selectedDay).getDate()
            color: root.selectedDay === root.today ? root.accent : root.fg
            font.family: root.ff
            font.pixelSize: Math.round(Style.font.displayLarge * 1.35)
            font.weight: Font.Light
            Behavior on color { ColorAnimation { duration: 200 } }
          }

          Column {
            anchors.left: bigDay.right
            anchors.leftMargin: root.sp(12)
            anchors.right: heroRight.left
            anchors.rightMargin: root.sp(8)
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.sp(3)
            Text {
              width: parent.width
              elide: Text.ElideRight
              text: Model.dayName(root.selectedDay)
              color: root.fg
              font.family: root.ff
              font.pixelSize: Style.font.heading
              font.bold: true
            }
            Caps {
              width: parent.width
              elide: Text.ElideRight
              text: "WEEK " + Model.isoWeek(root.viewWeek) + " · " + Model.weekLabel(root.viewWeek).toUpperCase()
            }
          }

          Column {
            id: heroRight
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.sp(6)

            Row {
              anchors.right: parent.right
              spacing: root.sp(4)
              Pill { label: "‹"; onClicked: root.moveDay(-7) }
              Pill {
                label: "TODAY"
                visible: root.selectedDay !== root.today
                onClicked: root.selectedDay = root.today
              }
              Pill { label: "›"; onClicked: root.moveDay(7) }
            }
            Row {
              anchors.right: parent.right
              spacing: root.sp(4)
              Pill { label: "WEEK"; active: root.tab === "week"; onClicked: root.tab = "week" }
              Pill { label: "GOALS"; active: root.tab === "goals"; onClicked: root.tab = "goals" }
            }
          }
        }

        // ── the week: one column per day ──────────────────────────────────
        Card {
          visible: root.tab === "week"
          width: parent.width
          height: week.height + root.sp(12)

          Row {
            id: week
            x: root.sp(6)
            y: root.sp(6)
            width: parent.width - root.sp(12)

            Repeater {
              model: root.days
              Rectangle {
                id: dayCell
                required property var modelData
                required property int index
                readonly property bool isToday: modelData === root.today
                readonly property bool picked: modelData === root.selectedDay
                readonly property var s: Model.dayStats(root.plan, modelData)
                readonly property real ratio: s.planned ? s.worked / s.planned : s.total ? s.done / s.total : 0
                width: week.width / 7
                height: root.sp(54)
                radius: root.sp(9)
                color: picked ? Util.alpha(root.accent, 0.12) : cellMouse.containsMouse ? Util.alpha(root.fg, 0.05) : "transparent"
                border.width: picked ? 1 : 0
                border.color: Util.alpha(root.accent, 0.4)
                Behavior on color { ColorAnimation { duration: 140 } }

                Column {
                  anchors.centerIn: parent
                  spacing: root.sp(3)
                  Caps {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Model.DAY_NAMES[dayCell.index].slice(0, 2).toUpperCase()
                    color: dayCell.isToday ? root.accent : root.muted
                  }
                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Model.parseKey(dayCell.modelData).getDate()
                    color: dayCell.isToday ? root.accent : root.fg
                    font.family: root.ff
                    font.pixelSize: Style.font.body
                    font.bold: dayCell.isToday || dayCell.picked
                  }
                  // Done out of planned for the day; hidden when nothing is planned.
                  Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: root.sp(22)
                    height: root.sp(3)
                    opacity: dayCell.s.total ? 1 : 0
                    Rectangle {
                      anchors.fill: parent
                      radius: height / 2
                      color: Util.alpha(root.fg, 0.12)
                    }
                    Rectangle {
                      width: parent.width * Math.min(1, dayCell.ratio)
                      height: parent.height
                      radius: height / 2
                      color: root.accent
                      Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    }
                  }
                }

                MouseArea {
                  id: cellMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.selectedDay = dayCell.modelData
                }
              }
            }
          }
        }

        // ── the selected day's tasks ──────────────────────────────────────
        Card {
          visible: root.tab === "week"
          width: parent.width
          height: dayCol.implicitHeight + root.sp(26)

          Column {
            id: dayCol
            x: root.sp(14)
            y: root.sp(13)
            width: parent.width - root.sp(28)
            spacing: root.sp(8)

            Item {
              width: parent.width
              height: dayTitle.implicitHeight
              Caps {
                id: dayTitle
                text: (root.selectedDay === root.today ? "TODAY" : Model.dayName(root.selectedDay).toUpperCase())
                  + " · " + Model.shortDate(root.selectedDay).toUpperCase()
              }
              Caps {
                anchors.right: parent.right
                text: root.stats.planned ? Model.fmtDuration(root.stats.worked) + " / " + Model.fmtDuration(root.stats.planned)
                  : root.stats.total ? root.stats.done + " / " + root.stats.total : ""
                color: root.stats.total && root.stats.done === root.stats.total ? root.accent : root.muted
              }
            }

            Item {
              width: parent.width
              height: root.sp(2)
              Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Util.alpha(root.fg, 0.08)
              }
              Rectangle {
                width: parent.width * Math.min(1, root.dayRatio)
                height: parent.height
                radius: height / 2
                color: root.accent
                Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
              }
            }

            Rectangle {
              visible: root.carryCount > 0
              width: parent.width
              height: root.sp(30)
              radius: root.sp(8)
              color: carryMouse.containsMouse ? Util.alpha(root.accent, 0.16) : Util.alpha(root.accent, 0.07)
              border.width: 1
              border.color: Util.alpha(root.accent, 0.4)
              Text {
                anchors.centerIn: parent
                text: "↻  Bring " + root.carryCount + " unfinished from yesterday"
                color: root.accent
                font.family: root.ff
                font.pixelSize: Style.font.bodySmall
                font.bold: true
              }
              MouseArea {
                id: carryMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.svc) root.svc.carryOver(Model.addDays(root.today, -1), root.today)
              }
            }

            Item {
              width: parent.width
              height: taskList.implicitHeight

              Column {
                id: taskList
                width: parent.width
                spacing: root.sp(2)

                Text {
                  visible: root.tasks.length === 0
                  width: parent.width
                  topPadding: root.sp(14)
                  bottomPadding: root.sp(14)
                  horizontalAlignment: Text.AlignHCenter
                  text: "Nothing planned yet."
                  color: root.muted
                  font.family: root.ff
                  font.pixelSize: Style.font.bodySmall
                }

                Repeater {
                  model: root.tasks
                  Rectangle {
                    id: task
                    required property var modelData
                    required property int index
                    readonly property color tc: root.goalColor(modelData.goal)
                    readonly property bool editing: root.editingId === modelData.id
                    readonly property bool hot: rowMouse.containsMouse || root.cursor === index
                    readonly property var preview: Model.readBlock(fromField.text, toField.text)
                    property bool invalid: false
                    width: taskList.width
                    height: editing ? rowArea.height + editor.implicitHeight + root.sp(12) : rowArea.height
                    radius: root.sp(8)
                    color: editing ? Util.alpha(root.fg, 0.05) : hot ? Util.alpha(root.fg, 0.06) : "transparent"
                    border.width: editing ? 1 : 0
                    border.color: Util.alpha(modelData.goal ? tc : root.fg, 0.3)
                    clip: true
                    Behavior on color { ColorAnimation { duration: 120 } }

                    function startEditing() {
                      editText.text = root.draftText
                      fromField.text = root.draftFrom
                      toField.text = root.draftTo
                      invalid = false
                      editText.forceActiveFocus()
                    }
                    function save() {
                      if (!root.svc) return
                      if (root.svc.editTask(root.selectedDay, modelData.id, editText.text, fromField.text, toField.text, root.draftGoal))
                        root.stopEditing()
                      else invalid = true
                    }
                    onEditingChanged: if (editing) startEditing()
                    Component.onCompleted: if (editing) startEditing()

                    Item {
                      id: rowArea
                      width: parent.width
                      height: root.sp(28)

                      // Click the row to edit it; the circle marks it done.
                      MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: task.editing ? root.stopEditing() : root.beginEdit(task.modelData)
                      }

                      Rectangle {
                        id: check
                        x: root.sp(8)
                        anchors.verticalCenter: parent.verticalCenter
                        width: root.sp(16)
                        height: width
                        radius: width / 2
                        color: task.modelData.done ? task.tc : checkMouse.containsMouse ? Util.alpha(task.tc, 0.25) : "transparent"
                        border.width: task.modelData.done ? 0 : 1.5
                        border.color: task.modelData.goal ? task.tc : Util.alpha(root.fg, 0.4)
                        Behavior on color { ColorAnimation { duration: 160 } }
                        Text {
                          anchors.centerIn: parent
                          visible: task.modelData.done
                          text: ""
                          color: Color.popups.background
                          font.family: root.ff
                          font.pixelSize: Style.font.caption
                        }
                        MouseArea {
                          id: checkMouse
                          anchors.fill: parent
                          anchors.margins: -root.sp(4)
                          hoverEnabled: true
                          cursorShape: Qt.PointingHandCursor
                          onClicked: if (root.svc) root.svc.toggleTask(root.selectedDay, task.modelData.id)
                        }
                      }

                      Caps {
                        id: timeText
                        visible: !!task.modelData.time
                        anchors.left: check.right
                        anchors.leftMargin: root.sp(10)
                        anchors.verticalCenter: parent.verticalCenter
                        text: task.modelData.time + (task.modelData.end ? "–" + task.modelData.end : "")
                        font.letterSpacing: 0.5
                      }

                      Text {
                        anchors.left: timeText.visible ? timeText.right : check.right
                        anchors.leftMargin: root.sp(10)
                        anchors.right: lengthText.left
                        anchors.rightMargin: root.sp(8)
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                        text: task.modelData.text
                        color: root.fg
                        opacity: task.modelData.done ? 0.45 : 1
                        font.family: root.ff
                        font.pixelSize: Style.font.body
                        font.strikeout: task.modelData.done
                      }

                      Caps {
                        id: lengthText
                        anchors.right: goalDot.left
                        anchors.rightMargin: root.sp(4)
                        anchors.verticalCenter: parent.verticalCenter
                        text: Model.duration(task.modelData) ? Model.fmtDuration(Model.duration(task.modelData)).toUpperCase() : ""
                        color: task.modelData.goal ? task.tc : root.muted
                      }

                      Rectangle {
                        id: goalDot
                        anchors.right: removeBtn.left
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root.plan.goals.length > 0
                        width: root.sp(16)
                        height: width
                        color: "transparent"
                        Rectangle {
                          anchors.centerIn: parent
                          width: root.sp(8)
                          height: width
                          radius: width / 2
                          color: task.modelData.goal ? task.tc : "transparent"
                          border.width: task.modelData.goal ? 0 : 1
                          border.color: Util.alpha(root.fg, 0.35)
                        }
                      }

                      Rectangle {
                        id: removeBtn
                        anchors.right: parent.right
                        anchors.rightMargin: root.sp(4)
                        anchors.verticalCenter: parent.verticalCenter
                        width: root.sp(20)
                        height: width
                        radius: width / 2
                        opacity: task.hot && !task.editing ? 1 : 0
                        color: removeMouse.containsMouse ? Util.alpha(Color.urgent, 0.25) : "transparent"
                        Text {
                          anchors.centerIn: parent
                          text: "×"
                          color: removeMouse.containsMouse ? Color.urgent : root.muted
                          font.family: root.ff
                          font.pixelSize: Style.font.body
                        }
                        MouseArea {
                          id: removeMouse
                          anchors.fill: parent
                          enabled: !task.editing
                          hoverEnabled: true
                          cursorShape: Qt.PointingHandCursor
                          onClicked: if (root.svc) root.svc.removeTask(root.selectedDay, task.modelData.id)
                        }
                      }
                    }

                    // ── editor ──────────────────────────────────────────
                    Column {
                      id: editor
                      visible: task.editing
                      x: root.sp(10)
                      y: rowArea.height + root.sp(2)
                      width: parent.width - root.sp(20)
                      spacing: root.sp(8)

                      Field {
                        width: parent.width
                        focused: editText.activeFocus
                        TextInput {
                          id: editText
                          anchors.left: parent.left
                          anchors.right: parent.right
                          anchors.leftMargin: root.sp(12)
                          anchors.rightMargin: root.sp(12)
                          anchors.verticalCenter: parent.verticalCenter
                          color: root.fg
                          font.family: root.ff
                          font.pixelSize: Style.font.body
                          selectByMouse: true
                          clip: true
                          onAccepted: task.save()
                          onTextEdited: root.draftText = text
                          onActiveFocusChanged: root.editTyping = activeFocus
                          Keys.onEscapePressed: root.stopEditing()
                          Keys.onTabPressed: fromField.focusInput()
                        }
                      }

                      Row {
                        spacing: root.sp(8)
                        TimeField {
                          id: fromField
                          label: "FROM"
                          bad: task.invalid && !task.preview
                          onEdited: root.draftFrom = text
                          onAccepted: task.save()
                          onTabbed: toField.focusInput()
                        }
                        TimeField {
                          id: toField
                          label: "TO"
                          bad: task.invalid && !task.preview
                          onEdited: root.draftTo = text
                          onAccepted: task.save()
                          onTabbed: editText.forceActiveFocus()
                        }
                        Caps {
                          anchors.verticalCenter: parent.verticalCenter
                          text: !task.preview ? "CHECK TIME"
                            : task.preview.end ? Model.fmtDuration(Model.duration(task.preview)).toUpperCase()
                            : task.preview.time ? "NO END" : "NO TIME"
                          color: !task.preview ? Color.urgent : root.muted
                        }
                      }

                      GoalChips {
                        visible: root.plan.goals.length > 0
                        width: parent.width
                        noneLabel: "NO GOAL"
                        selected: root.draftGoal
                        onPicked: function(id) { root.draftGoal = id }
                      }

                      Row {
                        anchors.right: parent.right
                        spacing: root.sp(6)
                        Pill {
                          label: "DELETE"
                          onClicked: {
                            if (root.svc) root.svc.removeTask(root.selectedDay, task.modelData.id)
                            root.stopEditing()
                          }
                        }
                        Pill { label: "CANCEL"; onClicked: root.stopEditing() }
                        Pill { label: "SAVE"; active: true; onClicked: task.save() }
                      }
                    }
                  }
                }
              }
            }

            Field {
              width: parent.width
              focused: taskInput.activeFocus

              Rectangle {
                id: pickDot
                x: root.sp(14)
                anchors.verticalCenter: parent.verticalCenter
                width: root.sp(10)
                height: width
                radius: width / 2
                color: root.pickedGoal ? root.pickedGoal.color : "transparent"
                border.width: root.pickedGoal ? 0 : 1.5
                border.color: Util.alpha(root.fg, 0.4)
              }

              TextInput {
                id: taskInput
                anchors.left: pickDot.right
                anchors.leftMargin: root.sp(12)
                anchors.right: parent.right
                anchors.rightMargin: root.sp(12)
                anchors.verticalCenter: parent.verticalCenter
                color: root.fg
                font.family: root.ff
                font.pixelSize: Style.font.body
                selectByMouse: true
                clip: true
                onAccepted: root.submitAdd()
                Keys.onEscapePressed: root.release()
                Keys.onTabPressed: addFrom.focusInput()

                Text {
                  visible: !taskInput.text
                  text: "Add a block…  12 -> 2 python for ai"
                  color: Util.alpha(root.fg, 0.35)
                  font: taskInput.font
                }
              }
            }

            // Time for the new block; empty uses a time typed in the text.
            Row {
              visible: root.addOpen
              spacing: root.sp(8)
              TimeField {
                id: addFrom
                label: "FROM"
                bad: !Model.readBlock(addFrom.text, addTo.text)
                onAccepted: root.submitAdd()
                onTabbed: addTo.focusInput()
              }
              TimeField {
                id: addTo
                label: "TO"
                bad: !Model.readBlock(addFrom.text, addTo.text)
                onAccepted: root.submitAdd()
                onTabbed: taskInput.forceActiveFocus()
              }
              Caps {
                readonly property var block: Model.readBlock(addFrom.text, addTo.text)
                anchors.verticalCenter: parent.verticalCenter
                text: !block ? "CHECK TIME" : block.end ? Model.fmtDuration(Model.duration(block)).toUpperCase() : ""
                color: !block ? Color.urgent : root.muted
              }
            }

            // Goal for the new block. Auto links it by name.
            GoalChips {
              visible: root.plan.goals.length > 0 && root.addOpen
              width: parent.width
              noneLabel: "AUTO"
              selected: root.pickGoal
              onPicked: function(id) {
                root.pickGoal = id
                taskInput.forceActiveFocus()
              }
            }
          }
        }

        // ── goals ─────────────────────────────────────────────────────────
        Card {
          visible: root.tab === "goals"
          width: parent.width
          height: goalCol.implicitHeight + root.sp(26)

          Column {
            id: goalCol
            x: root.sp(14)
            y: root.sp(13)
            width: parent.width - root.sp(28)
            spacing: root.sp(8)

            Item {
              width: parent.width
              height: goalsTitle.implicitHeight
              Caps { id: goalsTitle; text: "GOALS · " + root.plan.goals.length + " / " + Model.MAX_GOALS }
              Caps { anchors.right: parent.right; text: Model.weekLabel(root.viewWeek).toUpperCase() }
            }

            Repeater {
              model: root.rows
              Rectangle {
                id: goalRow
                required property var modelData
                required property int index
                readonly property var g: modelData.goal
                readonly property bool hot: goalMouse.containsMouse || root.cursor === index
                width: goalCol.width
                height: root.sp(56)
                radius: root.sp(10)
                color: hot ? Util.alpha(g.color, 0.08) : Util.alpha(root.fg, 0.02)
                border.width: 1
                border.color: hot ? Util.alpha(g.color, 0.45) : Util.alpha(root.fg, 0.06)
                Behavior on color { ColorAnimation { duration: 140 } }

                MouseArea {
                  id: goalMouse
                  anchors.fill: parent
                  hoverEnabled: true
                }

                Rectangle {
                  x: root.sp(8)
                  anchors.verticalCenter: parent.verticalCenter
                  width: root.sp(3)
                  height: parent.height - root.sp(20)
                  radius: width / 2
                  color: goalRow.g.color
                }

                // Finished checkbox.
                Rectangle {
                  id: goalCheck
                  x: root.sp(20)
                  anchors.verticalCenter: parent.verticalCenter
                  width: root.sp(18)
                  height: width
                  radius: width / 2
                  color: goalRow.g.done ? goalRow.g.color : goalCheckMouse.containsMouse ? Util.alpha(goalRow.g.color, 0.2) : "transparent"
                  border.width: goalRow.g.done ? 0 : 1.5
                  border.color: goalRow.g.color
                  Behavior on color { ColorAnimation { duration: 160 } }
                  Text {
                    anchors.centerIn: parent
                    visible: goalRow.g.done
                    text: ""
                    color: Color.popups.background
                    font.family: root.ff
                    font.pixelSize: Style.font.caption
                  }
                  MouseArea {
                    id: goalCheckMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.svc) root.svc.toggleGoal(goalRow.g.id)
                  }
                }

                Column {
                  anchors.left: goalCheck.right
                  anchors.leftMargin: root.sp(12)
                  anchors.right: removeGoal.left
                  anchors.rightMargin: root.sp(10)
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: root.sp(5)

                  Text {
                    width: parent.width
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    text: goalRow.g.title
                    color: root.fg
                    opacity: goalRow.g.done ? 0.5 : 1
                    font.family: root.ff
                    font.pixelSize: Style.font.body
                    font.bold: true
                    font.strikeout: goalRow.g.done
                  }

                  Caps {
                    width: parent.width
                    elide: Text.ElideRight
                    text: goalRow.g.done ? "FINISHED"
                      : goalRow.modelData.planned
                        ? Model.fmtDuration(goalRow.modelData.worked).toUpperCase() + " DONE · "
                          + Model.fmtDuration(goalRow.modelData.planned).toUpperCase() + " PLANNED THIS WEEK"
                        : ""
                    visible: text !== ""
                    color: goalRow.g.done ? goalRow.g.color : root.muted
                  }

                  // Hours done out of hours planned this week.
                  Item {
                    visible: !goalRow.g.done && goalRow.modelData.planned > 0
                    width: parent.width
                    height: root.sp(3)
                    Rectangle {
                      anchors.fill: parent
                      radius: height / 2
                      color: Util.alpha(goalRow.g.color, 0.18)
                    }
                    Rectangle {
                      width: parent.width * Math.min(1, goalRow.modelData.worked / Math.max(1, goalRow.modelData.planned))
                      height: parent.height
                      radius: height / 2
                      color: goalRow.g.color
                      Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    }
                  }
                }

                Pill {
                  id: removeGoal
                  anchors.right: parent.right
                  anchors.rightMargin: root.sp(10)
                  anchors.verticalCenter: parent.verticalCenter
                  label: "×"
                  opacity: goalRow.hot ? 1 : 0.35
                  onClicked: if (root.svc) root.svc.removeGoal(goalRow.g.id)
                }
              }
            }

            Field {
              visible: root.plan.goals.length < Model.MAX_GOALS
              width: parent.width
              focused: goalInput.activeFocus

              Rectangle {
                id: nextThread
                x: root.sp(14)
                anchors.verticalCenter: parent.verticalCenter
                width: root.sp(10)
                height: width
                radius: width / 2
                color: Model.freeColor(root.plan.goals)
              }
              TextInput {
                id: goalInput
                anchors.left: nextThread.right
                anchors.leftMargin: root.sp(12)
                anchors.right: parent.right
                anchors.rightMargin: root.sp(12)
                anchors.verticalCenter: parent.verticalCenter
                color: root.fg
                font.family: root.ff
                font.pixelSize: Style.font.body
                selectByMouse: true
                clip: true
                onAccepted: if (root.svc && root.svc.addGoal(text)) text = ""
                Keys.onEscapePressed: root.release()

                Text {
                  visible: !goalInput.text
                  text: "New goal…  Run, Read, Ship the app"
                  color: Util.alpha(root.fg, 0.35)
                  font: goalInput.font
                }
              }
            }

            Text {
              width: parent.width
              wrapMode: Text.WordWrap
              lineHeight: 1.2
              text: "Plan time blocks for a goal on the Week tab (12 -> 2 python for ai). It links by name, counts the hours, and you tick the goal when it's finished."
              color: root.muted
              font.family: root.ff
              font.pixelSize: Style.font.caption
            }
          }
        }

        Caps {
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          color: Util.alpha(root.fg, 0.3)
          elide: Text.ElideRight
          visible: root.tab === "week"
          text: root.editingId ? "ENTER SAVE · TAB NEXT · ESC CANCEL"
            : root.typing ? "ENTER ADD · TAB NEXT · ESC DONE"
            : "J K TASK · ENTER EDIT · SPACE DONE · A ADD · G GOALS"
        }
      }
      }
    }
  }
}
