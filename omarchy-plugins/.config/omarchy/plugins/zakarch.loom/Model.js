.pragma library

// Goals are threads, days are columns, tasks are time blocks.
// Pure helpers, tested by `node --test check.js`.

var THREADS = ["#e8a87c", "#7ec4cf", "#b39ddb", "#a5d6a7", "#f48fb1", "#ffd54f"]
var MAX_GOALS = THREADS.length
var DAY_NAMES = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
var MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

// ── dates (local "YYYY-MM-DD" keys, weeks start Monday) ─────────────────────
function pad(n) { return (n < 10 ? "0" : "") + n }
function dayKey(d) { return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()) }
function parseKey(key) {
  var p = String(key).split("-")
  return new Date(Number(p[0]), Number(p[1]) - 1, Number(p[2]))
}
function addDays(key, n) {
  var d = parseKey(key)
  d.setDate(d.getDate() + n)
  return dayKey(d)
}
function dayIndex(key) { return (parseKey(key).getDay() + 6) % 7 }
function weekStart(key) { return addDays(key, -dayIndex(key)) }
function weekDays(start) {
  var out = []
  for (var i = 0; i < 7; i++) out.push(addDays(start, i))
  return out
}
function isoWeek(key) {
  var d = parseKey(addDays(key, 3 - dayIndex(key)))  // Thursday of this week
  var jan1 = new Date(d.getFullYear(), 0, 1)
  return 1 + Math.floor(Math.round((d - jan1) / 86400000) / 7)
}
function dayName(key) { return DAY_NAMES[dayIndex(key)] }
function shortDate(key) {
  var d = parseKey(key)
  return MONTHS[d.getMonth()] + " " + d.getDate()
}
function weekLabel(start) { return shortDate(start) + " – " + shortDate(addDays(start, 6)) }

// ── times ───────────────────────────────────────────────────────────────────
function validTime(t) { return typeof t === "string" && /^([01]\d|2[0-3]):[0-5]\d$/.test(t) }
function toMin(t) { var p = t.split(":"); return Number(p[0]) * 60 + Number(p[1]) }
function fromMin(m) { m = ((m % 1440) + 1440) % 1440; return pad(Math.floor(m / 60)) + ":" + pad(m % 60) }

// Block length in minutes; an end before the start runs past midnight.
function duration(t) {
  if (!t.time || !t.end) return 0
  var d = toMin(t.end) - toMin(t.time)
  return d > 0 ? d : d + 1440
}

function fmtDuration(min) {
  if (min <= 0) return "0h"
  if (min < 60) return min + "m"
  var h = Math.floor(min / 60), m = min % 60
  return h + "h" + (m ? pad(m) : "")
}

// One time token: "12", "2:30", "14h", "7pm". Bare hours 1–7 mean afternoon.
function readTime(tok, bare) {
  var m = String(tok).match(/^(\d{1,2})(?:[:.h](\d{2}))?h?\s*(am|pm)?$/i)
  if (!m) return -1
  var h = Number(m[1]), min = Number(m[2] || 0)
  if (min > 59) return -1
  if (m[3]) {
    if (h < 1 || h > 12) return -1
    h = h % 12 + (m[3].toLowerCase() === "pm" ? 12 : 0)
  } else if (bare && h >= 1 && h <= 7 && m[1].length === 1 && m[2] === undefined) {
    h += 12
  }
  return h <= 23 ? h * 60 + min : -1
}

// The end is the first matching clock time after the start ("12 -> 2" ends at 14:00).
function readEnd(tok, start) {
  var e = readTime(tok, false)
  if (e < 0) return -1
  if (/^0|am|pm/i.test(tok) || e >= 720) return e
  if (e > start) return e
  if (e + 720 > start) return e + 720
  return e
}

// "12 -> 2 Python", "9:30-11 Stats", "09:00 Gym", "7pm Call" → { time, end, text }
function parseEntry(input) {
  var text = String(input || "").trim()
  var tok = "(\\d{1,2}(?:[:.h]\\d{2})?h?\\s*(?:am|pm)?)"
  var m = text.match(new RegExp("^" + tok + "\\s*(?:->|→|–|-|to)\\s*" + tok + "\\s+(.+)$", "i"))
  if (m) {
    var s = readTime(m[1].trim(), true)
    var e = s >= 0 ? readEnd(m[2].trim(), s) : -1
    if (s >= 0 && e >= 0 && e !== s) return { time: fromMin(s), end: fromMin(e), text: m[3].trim() }
  }
  m = text.match(/^(\d{1,2}(?:[:.]\d{2}|h\d{2}|h)|\d{1,2}(?::\d{2})?\s*(?:am|pm))\s+(.+)$/i)
  if (m) {
    var t = readTime(m[1], false)
    if (t >= 0) return { time: fromMin(t), end: "", text: m[2].trim() }
  }
  return { time: "", end: "", text: text }
}

// ── state ───────────────────────────────────────────────────────────────────
function newId() { return Date.now().toString(36) + Math.floor(Math.random() * 1e6).toString(36) }

function empty() { return { version: 2, goals: [], tasks: {}, intentions: {} } }

function makeTask(t, changes) {
  var out = { id: t.id, text: t.text, goal: t.goal, time: t.time, end: t.end, done: t.done, created: t.created }
  for (var k in changes) out[k] = changes[k]
  return out
}

function normalize(raw) {
  var s = empty()
  if (!raw || typeof raw !== "object") return s
  if (Array.isArray(raw.goals)) {
    raw.goals.forEach(function(g) {
      if (!g || !String(g.title || "").trim() || s.goals.length >= MAX_GOALS) return
      s.goals.push({
        id: String(g.id || newId()),
        title: String(g.title).trim(),
        color: THREADS.indexOf(g.color) >= 0 ? g.color : freeColor(s.goals),
        done: g.done === true
      })
    })
  }
  if (raw.tasks && typeof raw.tasks === "object") {
    Object.keys(raw.tasks).forEach(function(day) {
      if (!/^\d{4}-\d{2}-\d{2}$/.test(day) || !Array.isArray(raw.tasks[day])) return
      var list = raw.tasks[day].filter(function(t) { return t && String(t.text || "").trim() }).map(function(t) {
        var task = { id: String(t.id || newId()), text: String(t.text).trim(), goal: String(t.goal || ""),
          time: validTime(t.time) ? t.time : "", end: validTime(t.end) ? t.end : "",
          done: t.done === true, created: Number(t.created) || 0 }
        if (!task.time) {
          // Older entries kept the time inside the text ("12 -> 2 python").
          var p = parseEntry(task.text)
          if (p.time) task = makeTask(task, { time: p.time, end: p.end, text: p.text,
            goal: task.goal || matchGoal(s.goals, p.text) })
        }
        if (task.goal && !goalById(s, task.goal)) task.goal = ""
        return task
      })
      if (list.length) s.tasks[day] = list
    })
  }
  if (raw.intentions && typeof raw.intentions === "object") {
    Object.keys(raw.intentions).forEach(function(w) {
      var text = String(raw.intentions[w] || "").trim()
      if (text) s.intentions[w] = text
    })
  }
  return s
}

function clone(s) {
  var tasks = {}
  Object.keys(s.tasks).forEach(function(d) { tasks[d] = s.tasks[d].slice() })
  var intentions = {}
  Object.keys(s.intentions).forEach(function(w) { intentions[w] = s.intentions[w] })
  return { version: 2, goals: s.goals.slice(), tasks: tasks, intentions: intentions }
}

function freeColor(goals) {
  for (var i = 0; i < THREADS.length; i++)
    if (!goals.some(function(g) { return g.color === THREADS[i] })) return THREADS[i]
  return THREADS[goals.length % THREADS.length]
}

function goalById(s, id) {
  for (var i = 0; i < s.goals.length; i++) if (s.goals[i].id === id) return s.goals[i]
  return null
}

// "finish python for ai" → "python for ai", for tight labels.
function shortTitle(title) { return String(title).replace(/^(finish|complete|do)\s+(the\s+)?/i, "") || title }

// Link a task to the unfinished goal sharing the most words with it.
var SKIP_WORDS = ["finish", "first", "version", "chapter", "start", "the", "and", "for", "with", "work", "working"]
function words(text) {
  return String(text).toLowerCase().split(/[^a-z0-9]+/).filter(function(w) {
    return w.length >= 3 && SKIP_WORDS.indexOf(w) < 0
  })
}
function matchGoal(goals, text) {
  var mine = words(text)
  var best = "", bestScore = 0
  goals.forEach(function(g) {
    if (g.done) return
    var score = words(g.title).filter(function(w) { return mine.indexOf(w) >= 0 }).length
    if (score > bestScore) { best = g.id; bestScore = score }
  })
  return best
}

// ── tasks ───────────────────────────────────────────────────────────────────
function tasksFor(s, day) {
  return (s.tasks[day] || []).slice().sort(function(a, b) {
    if (a.time && b.time && a.time !== b.time) return a.time < b.time ? -1 : 1
    if (!!a.time !== !!b.time) return a.time ? -1 : 1
    return a.created - b.created
  })
}

// From/To fields, when filled, win over a time typed in the text.
function addTask(s, day, input, goalId, start, end) {
  var entry = parseEntry(input)
  if (!entry.text) return null
  if (String(start || "").trim() || String(end || "").trim()) {
    var block = readBlock(start, end)
    if (!block) return null
    entry.time = block.time
    entry.end = block.end
  }
  var n = clone(s)
  var list = n.tasks[day] || []
  list.push({ id: newId(), text: entry.text, goal: goalById(s, goalId) ? goalId : matchGoal(s.goals, entry.text),
    time: entry.time, end: entry.end, done: false, created: Date.now() })
  n.tasks[day] = list
  return n
}

function mapTask(s, day, id, fn) {
  var n = clone(s)
  var list = (n.tasks[day] || []).map(function(t) { return t.id === id ? fn(t) : t }).filter(Boolean)
  if (list.length) n.tasks[day] = list
  else delete n.tasks[day]
  return n
}

// Read the editor's From/To fields: { time, end } or null when they don't make sense.
function readBlock(start, end) {
  var st = String(start || "").trim(), en = String(end || "").trim()
  if (!st) return en ? null : { time: "", end: "" }
  var s = readTime(st, true)
  if (s < 0) return null
  if (!en) return { time: fromMin(s), end: "" }
  var e = readEnd(en, s)
  if (e < 0 || e % 1440 === s) return null
  return { time: fromMin(s), end: fromMin(e) }
}

function editTask(s, day, id, text, start, end, goalId) {
  var t = String(text || "").trim()
  var block = readBlock(start, end)
  if (!t || !block) return null
  return mapTask(s, day, id, function(x) {
    return makeTask(x, { text: t, time: block.time, end: block.end, goal: goalById(s, goalId) ? goalId : "" })
  })
}

function toggleTask(s, day, id) { return mapTask(s, day, id, function(t) { return makeTask(t, { done: !t.done }) }) }

function removeTask(s, day, id) { return mapTask(s, day, id, function() { return null }) }

function cycleTaskGoal(s, day, id) {
  return mapTask(s, day, id, function(t) {
    var ids = [""].concat(s.goals.map(function(g) { return g.id }))
    return makeTask(t, { goal: ids[(ids.indexOf(t.goal) + 1) % ids.length] })
  })
}

function unfinished(s, day) { return (s.tasks[day] || []).filter(function(t) { return !t.done }) }

// Move unfinished tasks from one day onto another.
function carryOver(s, from, to) {
  var moving = unfinished(s, from)
  if (!moving.length || from === to) return s
  var n = clone(s)
  var kept = (n.tasks[from] || []).filter(function(t) { return t.done })
  if (kept.length) n.tasks[from] = kept
  else delete n.tasks[from]
  n.tasks[to] = (n.tasks[to] || []).concat(moving)
  return n
}

function dayStats(s, day) {
  var list = s.tasks[day] || []
  var st = { total: list.length, done: 0, planned: 0, worked: 0 }
  list.forEach(function(t) {
    st.planned += duration(t)
    if (t.done) { st.done++; st.worked += duration(t) }
  })
  return st
}

// Next unfinished task: a timed one still ahead of `minutes`, else an untimed one, else an overdue one.
function nextTask(s, day, minutes) {
  var open = tasksFor(s, day).filter(function(t) { return !t.done })
  for (var i = 0; i < open.length; i++)
    if (open[i].time && toMin(open[i].time) >= minutes) return open[i]
  var untimed = open.filter(function(t) { return !t.time })
  return untimed.length ? untimed[0] : open.length ? open[0] : null
}

// ── goals ───────────────────────────────────────────────────────────────────
function addGoal(s, title) {
  var t = String(title || "").trim()
  if (!t || s.goals.length >= MAX_GOALS) return null
  var n = clone(s)
  n.goals.push({ id: newId(), title: t, color: freeColor(s.goals), done: false })
  return n
}

function removeGoal(s, id) {
  var n = clone(s)
  n.goals = n.goals.filter(function(g) { return g.id !== id })
  Object.keys(n.tasks).forEach(function(d) {
    n.tasks[d] = n.tasks[d].map(function(t) { return t.goal !== id ? t : makeTask(t, { goal: "" }) })
  })
  return n
}

function toggleGoal(s, id) {
  var n = clone(s)
  n.goals = n.goals.map(function(g) {
    return g.id !== id ? g : { id: g.id, title: g.title, color: g.color, done: !g.done }
  })
  return n
}

function weekKey(start) { return parseKey(addDays(start, 3)).getFullYear() + "-W" + pad(isoWeek(start)) }

function setIntention(s, start, text) {
  var n = clone(s)
  var t = String(text || "").trim()
  if (t) n.intentions[weekKey(start)] = t
  else delete n.intentions[weekKey(start)]
  return n
}

function intention(s, start) { return s.intentions[weekKey(start)] || "" }

// One row per goal: per-day task counts, plus planned/worked minutes for the week.
function weave(s, start) {
  var days = weekDays(start)
  return s.goals.map(function(g) {
    var planned = 0, worked = 0
    var cells = days.map(function(d) {
      var mine = (s.tasks[d] || []).filter(function(t) { return t.goal === g.id })
      var finished = 0
      mine.forEach(function(t) {
        planned += duration(t)
        if (t.done) { finished++; worked += duration(t) }
      })
      return { planned: mine.length, done: finished }
    })
    return { goal: g, cells: cells, planned: planned, worked: worked }
  })
}
