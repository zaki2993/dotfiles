import QtQuick
import Quickshell
import Quickshell.Io
import "Model.js" as Model

Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool loaded: false
  property var plan: Model.empty()
  property string today: Model.dayKey(new Date())
  property int minutes: 0

  readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/omarchy/zakarch.loom"
  readonly property string statePath: stateDir + "/loom.json"

  readonly property var todayStats: Model.dayStats(plan, today)
  readonly property var next: Model.nextTask(plan, today, minutes)
  readonly property var thisWeek: Model.weave(plan, Model.weekStart(today))

  function commit(next) {
    if (!next) return false
    plan = next
    if (loaded) saveTimer.restart()
    return true
  }

  function addTask(day, text, goalId, start, end) { return commit(Model.addTask(plan, day, text, goalId, start, end)) }
  function editTask(day, id, text, start, end, goalId) { return commit(Model.editTask(plan, day, id, text, start, end, goalId)) }
  function toggleTask(day, id) { commit(Model.toggleTask(plan, day, id)) }
  function removeTask(day, id) { commit(Model.removeTask(plan, day, id)) }
  function cycleTaskGoal(day, id) { commit(Model.cycleTaskGoal(plan, day, id)) }
  function carryOver(from, to) { commit(Model.carryOver(plan, from, to)) }
  function addGoal(title) { return commit(Model.addGoal(plan, title)) }
  function removeGoal(id) { commit(Model.removeGoal(plan, id)) }
  function toggleGoal(id) { commit(Model.toggleGoal(plan, id)) }
  function setIntention(start, text) {
    if (Model.intention(plan, start) !== String(text || "").trim()) commit(Model.setIntention(plan, start, text))
  }

  function tick() {
    var d = new Date()
    today = Model.dayKey(d)
    minutes = d.getHours() * 60 + d.getMinutes()
  }

  function load(raw) {
    var data = null
    try { data = JSON.parse(raw || "null") } catch (e) { data = null }
    plan = Model.normalize(data)
    loaded = true
  }

  Component.onCompleted: {
    tick()
    ensureDir.running = true
  }

  Process {
    id: ensureDir
    command: ["mkdir", "-p", root.stateDir]
    onExited: stateFile.reload()
  }

  FileView {
    id: stateFile
    path: root.statePath
    watchChanges: false
    atomicWrites: true
    printErrors: false
    onLoaded: root.load(text())
    onLoadFailed: root.load("")
  }

  Timer {
    id: saveTimer
    interval: 200
    onTriggered: stateFile.setText(JSON.stringify(root.plan, null, 2) + "\n")
  }

  Timer {
    interval: 30000
    running: true
    repeat: true
    onTriggered: root.tick()
  }

  IpcHandler {
    target: "zakarch.loom"
    function add(text: string): string { return root.addTask(root.today, text, "") ? "added" : "empty" }
    function status(): string {
      return JSON.stringify({ today: root.today, done: root.todayStats.done, total: root.todayStats.total,
        next: root.next ? (root.next.time ? root.next.time + " " : "") + root.next.text : "" })
    }
  }
}
