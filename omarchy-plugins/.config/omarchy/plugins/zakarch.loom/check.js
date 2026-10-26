const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const vm = require("node:vm")
const { test } = require("node:test")

const Model = vm.createContext({})
vm.runInContext(fs.readFileSync(path.join(__dirname, "Model.js"), "utf8").replace(/^\.pragma library\s*/, ""), Model)

test("weeks start on Monday and carry ISO week numbers", () => {
  assert.equal(Model.weekStart("2026-10-26"), "2026-10-26")
  assert.equal(Model.weekStart("2026-11-01"), "2026-10-26")
  assert.equal(Model.weekStart("2026-10-31"), "2026-10-26")
  assert.equal(Model.isoWeek("2026-10-26"), 44)
  assert.equal(Model.isoWeek("2027-01-01"), 53)
  assert.equal(Model.isoWeek("2025-12-29"), 1)
  assert.equal(Model.weekKey("2025-12-29"), "2026-W01")
  assert.equal(Model.weekLabel("2026-10-26"), "Oct 26 – Nov 1")
  assert.equal(Model.addDays("2026-03-28", 2), "2026-03-30", "DST change doesn't skip a day")
})

test("reads time blocks the way they're typed", () => {
  const p = (s) => { const r = Model.parseEntry(s); return [r.time, r.end, r.text].join("|") }
  assert.equal(p("12 -> 2 python for ai"), "12:00|14:00|python for ai")
  assert.equal(p("3 -> 4 statistics"), "15:00|16:00|statistics")
  assert.equal(p("6 -> 1 working on my app"), "18:00|01:00|working on my app")
  assert.equal(p("9 -> 11 Gym"), "09:00|11:00|Gym")
  assert.equal(p("9:30-11 Stats"), "09:30|11:00|Stats")
  assert.equal(p("14h → 16h30 Mobile"), "14:00|16:30|Mobile")
  assert.equal(p("8am to 10am Run"), "08:00|10:00|Run")
  assert.equal(p("09:30 Gym"), "09:30||Gym")
  assert.equal(p("7pm Call mum"), "19:00||Call mum")
  assert.equal(p("14h Dentist"), "14:00||Dentist")
  assert.equal(p("3 sets of pushups"), "||3 sets of pushups")
  assert.equal(p("25:00 Nope"), "||25:00 Nope")
  assert.equal(p("Read"), "||Read")
  assert.equal(Model.duration({ time: "18:00", end: "01:00" }), 420)
  assert.equal(Model.fmtDuration(90), "1h30")
  assert.equal(Model.fmtDuration(120), "2h")
  assert.equal(Model.fmtDuration(45), "45m")
})

test("blocks link to the goal they mention and count hours", () => {
  let s = Model.empty()
  s = Model.addGoal(s, "finish python for ai")
  s = Model.addGoal(s, "finish statistics + chapter 1 proba")
  const [py, stats] = s.goals.map((g) => g.id)
  s = Model.addTask(s, "2026-10-26", "12 -> 2 python for ai", "")
  s = Model.addTask(s, "2026-10-26", "3 -> 4 statistics", "")
  s = Model.addTask(s, "2026-10-26", "6 -> 1 working on my app", "")
  const list = Model.tasksFor(s, "2026-10-26")
  assert.deepEqual(Array.from(list, (t) => t.goal), [py, stats, ""])
  s = Model.toggleTask(s, "2026-10-26", list[0].id)
  const day = Model.dayStats(s, "2026-10-26")
  assert.equal(day.planned, 600)
  assert.equal(day.worked, 120)
  const rows = Model.weave(s, "2026-10-26")
  assert.equal(rows[0].planned, 120)
  assert.equal(rows[0].worked, 120)
  assert.equal(rows[1].worked, 0)
  assert.equal(rows[0].cells[0].done, 1)

  s = Model.toggleGoal(s, py)
  assert.equal(s.goals[0].done, true)
  s = Model.addTask(s, "2026-10-27", "python again", "")
  assert.equal(s.tasks["2026-10-27"][0].goal, "", "finished goals don't pick up new blocks")
})

test("editing a task changes its text, time and goal", () => {
  let s = Model.addGoal(Model.empty(), "finish dev mobile sub")
  const goal = s.goals[0].id
  s = Model.addTask(s, "2026-10-26", "6 -> 1 working on my app", "")
  const id = s.tasks["2026-10-26"][0].id
  const b = (a, z) => { const r = Model.readBlock(a, z); return r ? r.time + "|" + r.end : null }
  assert.equal(b("18:00", "01:00"), "18:00|01:00", "zero-padded times are taken as typed")
  assert.equal(b("6", "10"), "18:00|22:00")
  assert.equal(b("9", ""), "09:00|")
  assert.equal(b("", ""), "|")
  assert.equal(b("", "2"), null, "an end needs a start")
  assert.equal(b("nope", ""), null)
  assert.equal(b("12", "12"), null)

  let n = Model.editTask(s, "2026-10-26", id, " mobile app ", "6", "10", goal)
  const t = n.tasks["2026-10-26"][0]
  assert.deepEqual([t.text, t.time, t.end, t.goal], ["mobile app", "18:00", "22:00", goal])
  n = Model.editTask(n, "2026-10-26", id, "mobile app", "", "", "")
  assert.deepEqual([n.tasks["2026-10-26"][0].time, n.tasks["2026-10-26"][0].goal], ["", ""])
  const added = Model.addTask(s, "2026-10-27", "mobile", "", "9", "11")
  assert.deepEqual([added.tasks["2026-10-27"][0].time, added.tasks["2026-10-27"][0].end], ["09:00", "11:00"])
  assert.equal(Model.addTask(s, "2026-10-27", "mobile", "", "", "11"), null)
  assert.equal(Model.editTask(s, "2026-10-26", id, "  ", "6", "", ""), null)
  assert.equal(Model.editTask(s, "2026-10-26", id, "x", "99", "", ""), null)
})

test("old entries with the time in the text are upgraded on load", () => {
  const raw = {
    goals: [{ id: "g1", title: "finish python for ai", color: "#e8a87c", target: 7 }],
    tasks: { "2026-10-26": [{ id: "a", text: "12 -> 2 python for ai", goal: "", time: "", done: false, created: 1 }] }
  }
  const s = Model.normalize(raw)
  const t = s.tasks["2026-10-26"][0]
  assert.equal(t.time, "12:00")
  assert.equal(t.end, "14:00")
  assert.equal(t.text, "python for ai")
  assert.equal(t.goal, "g1")
  assert.equal(s.goals[0].done, false)
})

test("tasks sort by time, carry over and drop with their day", () => {
  let s = Model.empty()
  s = Model.addTask(s, "2026-10-26", "Read", "")
  s = Model.addTask(s, "2026-10-26", "18:00 Run", "")
  s = Model.addTask(s, "2026-10-26", "07:00 Stretch", "")
  assert.deepEqual(Array.from(Model.tasksFor(s, "2026-10-26"), (t) => t.text), ["Stretch", "Run", "Read"])
  const run = Model.tasksFor(s, "2026-10-26")[1]
  s = Model.toggleTask(s, "2026-10-26", run.id)
  assert.equal(Model.nextTask(s, "2026-10-26", 8 * 60).text, "Read", "past timed tasks fall back to an untimed one")
  assert.equal(Model.nextTask(s, "2026-10-26", 6 * 60).text, "Stretch")
  s = Model.carryOver(s, "2026-10-26", "2026-10-27")
  assert.equal(Model.dayStats(s, "2026-10-26").total, 1, "done task stays behind")
  assert.equal(Model.dayStats(s, "2026-10-27").total, 2)
  s = Model.removeTask(s, "2026-10-26", run.id)
  assert.equal(s.tasks["2026-10-26"], undefined)
})

test("goals get free colors, cap at six and untag tasks when removed", () => {
  let s = Model.empty()
  for (let i = 0; i < 6; i++) s = Model.addGoal(s, "G" + i)
  assert.equal(Model.addGoal(s, "Seventh"), null)
  assert.equal(new Set(s.goals.map((g) => g.color)).size, 6)
  const first = s.goals[0]
  s = Model.addTask(s, "2026-10-28", "Thing", first.id)
  s = Model.removeGoal(s, first.id)
  s = Model.addGoal(s, "New")
  assert.equal(s.goals[5].color, first.color, "freed color is reused")
  assert.equal(s.tasks["2026-10-28"][0].goal, "")
})

test("intentions are stored per ISO week and bad files load empty", () => {
  let s = Model.setIntention(Model.empty(), "2026-10-26", "  Ship Loom  ")
  assert.equal(Model.intention(s, "2026-10-26"), "Ship Loom")
  assert.equal(Model.intention(s, "2026-11-02"), "")
  s = Model.normalize(JSON.parse(JSON.stringify(s)))
  assert.equal(Model.intention(s, "2026-10-26"), "Ship Loom")
  const bad = Model.normalize({ goals: [{ title: "" }, null], tasks: { nope: [], "2026-10-26": [{ text: " " }, { text: "ok", time: "99:99" }] } })
  assert.equal(bad.goals.length, 0)
  assert.equal(bad.tasks["2026-10-26"].length, 1)
  assert.equal(bad.tasks["2026-10-26"][0].time, "")
  assert.equal(Model.normalize(null).goals.length, 0)
})
