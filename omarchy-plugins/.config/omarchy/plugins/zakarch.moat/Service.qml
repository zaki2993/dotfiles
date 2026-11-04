import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import "Model.js" as Model

// Moat: blocks distracting sites on a weekly schedule.
// The system lock (system/, runs as root) owns the real rules and /etc/hosts.
// This service saves the rules you want, mirrors the lock state, and closes
// blocked web app windows. Without the system lock it only closes windows.
Item {
  id: root

  property var shell: null
  property var manifest: null
  property string omarchyPath: Quickshell.env("OMARCHY_PATH") || "/usr/share/omarchy"

  readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/omarchy"
  readonly property string statePath: stateDir + "/zakarch.moat.json"
  readonly property string statusPath: "/var/lib/moat/status.json"
  readonly property string systemDir: String(Qt.resolvedUrl("system")).replace(/^file:\/\//, "")

  property bool loaded: false
  property var sites: []
  property var blocks: []
  property var unlock: null        // { id, requestedAt } while asking for a pass
  property int closedToday: 0
  property string closedDate: ""

  property var status: null        // last good /var/lib/moat/status.json
  property double now: Date.now()
  property double minute: Math.floor(now / 60000)
  property var _lastNotified: ({})

  // The helper writes status every 20 s; older than that means it stopped.
  readonly property bool installed: !!status && now - status.updatedAt < 90000
  readonly property bool stale: !!status && !installed
  readonly property var activeSites: installed ? status.sites : sites
  readonly property var activeBlocks: installed ? status.blocks : blocks
  readonly property var span: Model.span(activeBlocks, minute * 60000)
  readonly property bool inBlock: span.active
  readonly property var pass: installed && unlock && status.pass && status.pass.id === unlock.id ? status.pass : null
  readonly property bool passOpen: !!pass && pass.state === "open" && now < pass.until
  readonly property bool blocked: inBlock && !passOpen
  readonly property bool passUsedToday: installed && status.lastPassDay === Model.dayKey(new Date(now))
  // Edits the system lock hasn't taken yet because they loosen a running block.
  readonly property bool held: installed && inBlock
    && (JSON.stringify(sites) !== JSON.stringify(status.sites) || JSON.stringify(blocks) !== JSON.stringify(status.blocks))
  // Fraction of the running block still left, for the bar icon.
  readonly property real blockLeft: inBlock && span.end > span.start ? Math.max(0, Math.min(1, (span.end - now) / (span.end - span.start))) : 0

  // ── edits ─────────────────────────────────────────────────────────────────
  function save() { if (loaded) saveTimer.restart() }

  function siteLocked(d) { return inBlock && activeSites.indexOf(d) !== -1 }
  function blockLocked(b) { return inBlock && Model.hasBlock(activeBlocks, b) }

  function addSite(text) {
    var d = Model.cleanDomain(text)
    if (!d || sites.indexOf(d) !== -1 || sites.length >= Model.MAX_SITES) return false
    sites = sites.concat([d])
    save()
    return true
  }

  function addPreset(preset) {
    sites = Model.cleanSites(sites.concat(preset.sites))
    save()
  }

  function removeSite(d) {
    if (siteLocked(d)) return
    sites = sites.filter(function(s) { return s !== d })
    save()
  }

  // Returns "" when added, otherwise why not.
  function addBlock(days, start, end) {
    var s = Model.parseTime(start), e = Model.parseTime(end)
    if (!s || !e) return "Use times like 9, 13:30 or 17h"
    if (s === e) return "Start and end can't be the same"
    if (!days.length) return "Pick at least one day"
    var b = { days: days.slice().sort(function(x, y) { return x - y }), start: s, end: e }
    if (Model.hasBlock(blocks, b)) return "That block is already there"
    if (blocks.length >= Model.MAX_BLOCKS) return "Too many blocks"
    var next = Model.cleanBlocks(blocks.concat([b]))
    if (!Model.hasFreeTime(next)) return "Leave some free time in the week"
    blocks = next
    save()
    return ""
  }

  function removeBlock(b) {
    if (blockLocked(b)) return
    blocks = blocks.filter(function(x) { return Model.blockKey(x) !== Model.blockKey(b) })
    save()
  }

  function requestPass() {
    if (!installed || !inBlock || passUsedToday) return
    unlock = { id: Model.newId(), requestedAt: Date.now() }
    save()
  }

  function cancelPass() {
    if (!unlock) return
    unlock = null
    save()
  }

  onInBlockChanged: if (!inBlock && loaded) cancelPass()
  onBlockedChanged: if (blocked) scan()

  function installSystemLock() {
    var cmd = "sudo bash " + Util.shellQuote(systemDir + "/install.sh")
    Quickshell.execDetached([omarchyPath + "/bin/omarchy-launch-floating-terminal-with-presentation", cmd])
  }

  // ── closing blocked web apps ──────────────────────────────────────────────
  function scan() {
    if (blocked && activeSites.length && !clientsProc.running) clientsProc.running = true
  }

  // Needs the `window = "address:…"` selector: other forms close the focused window.
  function closeWindow(address) {
    var addr = String(address || "")
    if (!/^0x[0-9a-fA-F]+$/.test(addr)) return
    Quickshell.execDetached(["hyprctl", "dispatch", 'hl.dsp.window.close({ window = "address:' + addr + '" })'])
  }

  function enforce(raw) {
    if (!blocked) return
    var clients = []
    try { clients = JSON.parse(raw || "[]") } catch (e) { return }
    if (!Array.isArray(clients)) return
    var hits = []
    for (var i = 0; i < clients.length; i++) {
      var site = Model.siteFor(Model.windowHost(clients[i]), activeSites)
      if (!site) continue
      closeWindow(clients[i].address)
      if (hits.indexOf(site) === -1) hits.push(site)
    }
    if (!hits.length) return

    var today = Model.dayKey(new Date())
    if (closedDate !== today) { closedDate = today; closedToday = 0 }
    closedToday += hits.length
    save()

    var t = Date.now(), seen = Object.assign({}, _lastNotified)
    for (var j = 0; j < hits.length; j++) {
      if (t - (seen[hits[j]] || 0) < 8000) continue
      seen[hits[j]] = t
      var until = span.end ? " until " + Model.fmtWhen(span.end, t) : ""
      notify("Moat", Model.siteName(hits[j]) + " is blocked" + until + ".")
    }
    _lastNotified = seen
  }

  function notify(title, body) {
    Quickshell.execDetached([omarchyPath + "/bin/omarchy-notification-send", title, body, "-g", "󰌾"])
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (!root.blocked) return
      var name = String(event && event.name ? event.name : "")
      if (name === "openwindow" || name === "activewindowv2" || name === "windowtitlev2") scanDelay.restart()
    }
  }

  Timer { id: scanDelay; interval: 120; onTriggered: root.scan() }

  // Fallback for windows Hyprland didn't report.
  Timer {
    interval: 5000
    repeat: true
    running: root.blocked && root.activeSites.length > 0
    onTriggered: root.scan()
  }

  Process {
    id: clientsProc
    command: ["hyprctl", "clients", "-j"]
    stdout: StdioCollector { id: clientsOut }
    onExited: function(code) { if (code === 0) root.enforce(clientsOut.text) }
  }

  // ── system lock status ────────────────────────────────────────────────────
  function readStatus(raw) {
    var data = null
    try { data = JSON.parse(raw || "null") } catch (e) { return }
    if (!data || typeof data.updatedAt !== "number") return
    status = {
      updatedAt: data.updatedAt,
      sites: Model.cleanSites(data.sites),
      blocks: Model.cleanBlocks(data.blocks),
      pass: data.pass && typeof data.pass.id === "string" ? data.pass : null,
      lastPassDay: String(data.lastPassDay || "")
    }
  }

  FileView {
    id: statusFile
    path: root.statusPath
    watchChanges: true
    printErrors: false
    onLoaded: root.readStatus(text())
    onFileChanged: reload()
  }

  // ── persistence ───────────────────────────────────────────────────────────
  function hydrate(raw) {
    if (loaded) return
    var data = null
    try { data = JSON.parse(raw || "null") } catch (e) { data = null }
    var s = Model.normalize(data)
    sites = s.sites
    blocks = s.blocks
    unlock = s.unlock
    closedToday = s.closedDate === Model.dayKey(new Date()) ? s.closedToday : 0
    closedDate = s.closedDate
    loaded = true
    if (!data) save()
  }

  FileView {
    id: stateFile
    path: root.statePath
    watchChanges: false
    atomicWrites: true
    printErrors: false
    onLoaded: root.hydrate(text())
    onLoadFailed: root.hydrate("")
  }

  Timer {
    id: saveTimer
    interval: 200
    onTriggered: stateFile.setText(JSON.stringify({
      version: 1,
      sites: root.sites,
      blocks: root.blocks,
      unlock: root.unlock,
      closedToday: root.closedToday,
      closedDate: root.closedDate
    }, null, 2) + "\n")
  }

  Process {
    id: ensureDir
    command: ["mkdir", "-p", root.stateDir]
    onExited: stateFile.reload()
  }

  Component.onCompleted: ensureDir.running = true

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: {
      root.now = Date.now()
      var m = Math.floor(root.now / 60000)
      if (m !== root.minute) root.minute = m
      // Atomic writes can slip past the file watch.
      if (Math.floor(root.now / 1000) % 3 === 0) statusFile.reload()
    }
  }

  IpcHandler {
    target: "zakarch.moat"
    function status(): string {
      return JSON.stringify({ installed: root.installed, inBlock: root.inBlock, blocked: root.blocked,
        until: root.span.end, next: root.span.next, sites: root.activeSites, held: root.held })
    }
    function add(site: string): string { return root.addSite(site) ? "added" : "invalid" }
  }
}
