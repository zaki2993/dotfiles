const assert = require("node:assert/strict")
const fs = require("node:fs")
const os = require("node:os")
const path = require("node:path")
const vm = require("node:vm")
const { execFileSync } = require("node:child_process")
const { test } = require("node:test")

const Model = vm.createContext({})
vm.runInContext(fs.readFileSync(path.join(__dirname, "Model.js"), "utf8").replace(/^\.pragma library\s*/, ""), Model)

// 2026-11-02 is a Monday. Local time, like the shell and the helper.
const plain = (v) => JSON.parse(JSON.stringify(v))
const at = (day, hh, mm) => new Date(2026, 10, 2 + day, hh, mm || 0).getTime()
const weekdays = { days: [0, 1, 2, 3, 4], start: "09:00", end: "17:00" }
const night = { days: [4], start: "22:00", end: "02:00" }

test("cleans domains and site lists", () => {
  assert.equal(Model.cleanDomain("https://www.X.com/home"), "x.com")
  assert.equal(Model.cleanDomain("reddit.com/r/all"), "reddit.com")
  assert.equal(Model.cleanDomain("m.youtube.com"), "m.youtube.com")
  assert.equal(Model.cleanDomain("youtube"), "")
  assert.equal(Model.cleanDomain("bad domain.com"), "")
  assert.equal(Model.cleanDomain("x.com\n0.0.0.0 evil"), "")
  assert.deepEqual(plain(Model.cleanSites(["X.com", "x.com", 5, "nope"])), ["x.com"])
  assert.deepEqual(plain(Model.normalize(null).sites), ["x.com", "twitter.com"])
  assert.deepEqual(plain(Model.normalize({ sites: [] }).sites), [])
})

test("finds the site of a web app window", () => {
  const sites = ["x.com", "youtube.com"]
  assert.equal(Model.siteFor(Model.windowHost({ class: "chrome-www.youtube.com__-Default" }), sites), "youtube.com")
  assert.equal(Model.siteFor(Model.windowHost({ class: "chrome-x.com__-Default" }), sites), "x.com")
  assert.equal(Model.siteFor(Model.windowHost({ class: "chrome-discord.com__channels_@me-Default" }), sites), "")
  assert.equal(Model.siteFor(Model.windowHost({ class: "chrome-notx.com__-Default" }), sites), "")
  assert.equal(Model.siteFor(Model.windowHost({ class: "chromium" }), sites), "")
})

test("parses typed times", () => {
  const p = (s) => Model.parseTime(s)
  assert.equal(p("9"), "09:00")
  assert.equal(p("9:30"), "09:30")
  assert.equal(p("930"), "09:30")
  assert.equal(p("17h"), "17:00")
  assert.equal(p("17h30"), "17:30")
  assert.equal(p("24"), "00:00")
  assert.equal(p("25"), "")
  assert.equal(p("9:75"), "")
  assert.equal(p("soon"), "")
})

test("keeps only valid blocks", () => {
  const out = Model.cleanBlocks([weekdays, weekdays, { days: [], start: "09:00", end: "10:00" },
    { days: [1], start: "10:00", end: "10:00" }, { days: [6, 6, 9, "1"], start: "08:00", end: "09:00" }])
  assert.deepEqual(plain(out), [weekdays, { days: [6], start: "08:00", end: "09:00" }])
})

test("knows when a block is running, also past midnight", () => {
  const b = [weekdays, night]
  assert.equal(Model.inBlock(b, new Date(at(0, 9))), true)
  assert.equal(Model.inBlock(b, new Date(at(0, 8, 59))), false)
  assert.equal(Model.inBlock(b, new Date(at(0, 17))), false)
  assert.equal(Model.inBlock(b, new Date(at(5, 10))), false, "Saturday is free")
  assert.equal(Model.inBlock(b, new Date(at(4, 23))), true, "Friday night")
  assert.equal(Model.inBlock(b, new Date(at(5, 1, 30))), true, "runs into Saturday")
  assert.equal(Model.inBlock(b, new Date(at(5, 2))), false)
  assert.equal(Model.inBlock(b, new Date(at(0, 1))), false, "Monday early isn't Sunday's block")
})

test("spans merge touching blocks and find the next one", () => {
  const b = [weekdays, { days: [0], start: "17:00", end: "18:00" }]
  const s = Model.span(b, at(0, 10, 30))
  assert.equal(s.active, true)
  assert.equal(s.start, at(0, 9))
  assert.equal(s.end, at(0, 18))
  const n = Model.span(b, at(4, 20))
  assert.equal(n.active, false)
  assert.equal(n.next, at(7, 9), "next Monday")
  assert.deepEqual(plain(Model.span([], at(0, 9))), { active: false, start: 0, end: 0, next: 0 })
})

test("refuses a week with no free time and loosening during a block", () => {
  const all = [{ days: [0, 1, 2, 3, 4, 5, 6], start: "00:00", end: "23:59" }, { days: [0, 1, 2, 3, 4, 5, 6], start: "23:59", end: "00:00" }]
  assert.equal(Model.hasFreeTime(all), false)
  assert.equal(Model.hasFreeTime([weekdays]), true)
  assert.equal(Model.isStricter(["x.com", "reddit.com"], [weekdays, night], ["x.com"], [weekdays]), true)
  assert.equal(Model.isStricter([], [weekdays], ["x.com"], [weekdays]), false)
  assert.equal(Model.isStricter(["x.com"], [{ days: [0, 1, 2, 3, 4], start: "09:00", end: "12:00" }], ["x.com"], [weekdays]), false)
})

test("labels", () => {
  assert.equal(Model.describeDays([0, 1, 2, 3, 4]), "Weekdays")
  assert.equal(Model.describeDays([5, 6]), "Weekends")
  assert.equal(Model.describeDays([0, 1, 2, 3, 4, 5, 6]), "Every day")
  assert.equal(Model.describeDays([1, 2, 3]), "Tue–Thu")
  assert.equal(Model.describeDays([0, 2]), "Mon, Wed")
  assert.equal(Model.fmtLeft(2 * 3600000 + 14 * 60000), "2h 14m")
  assert.equal(Model.fmtLeft(3600000), "1h")
  assert.equal(Model.fmtClock(9 * 60000 + 5000), "9:05")
  assert.equal(Model.fmtWhen(at(0, 17), at(0, 10)), "17:00")
  assert.equal(Model.fmtWhen(at(1, 9), at(0, 10)), "tomorrow 09:00")
  assert.equal(Model.fmtWhen(at(3, 9), at(0, 10)), "Thu 09:00")
  assert.match(Model.phrase(), /^[a-z]{5}( [a-z]{5}){5}$/)
})

// ── system/moat-helper, run against temp files ──────────────────────────────
function sandbox() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "moat-"))
  const f = (n) => path.join(dir, n)
  fs.writeFileSync(f("hosts"), "127.0.0.1 localhost\n")
  fs.writeFileSync(f("config.json"), JSON.stringify({ wants: f("wants.json"), sites: [], blocks: [] }))
  const run = (ms, extra) => execFileSync("python3", [path.join(__dirname, "system/moat-helper"),
    "--config", f("config.json"), "--state", f("status.json"), "--hosts", f("hosts"), "--now", String(ms / 1000)].concat(extra || []))
  const wants = (w) => fs.writeFileSync(f("wants.json"), JSON.stringify(w))
  const read = (n) => fs.readFileSync(f(n), "utf8")
  const status = () => JSON.parse(read("status.json"))
  return { run, wants, read, status, dir }
}

test("helper adopts rules, blocks in hosts, and refuses loosening during a block", () => {
  const s = sandbox()
  s.wants({ sites: ["x.com"], blocks: [weekdays] })
  s.run(at(0, 8))
  assert.deepEqual(s.status().sites, ["x.com"])
  assert.equal(s.status().blocked, false)
  assert.equal(s.read("hosts"), "127.0.0.1 localhost\n")

  s.run(at(0, 9))
  assert.equal(s.status().blocked, true)
  assert.match(s.read("hosts"), /^0\.0\.0\.0 x\.com$/m)
  assert.match(s.read("hosts"), /^:: www\.x\.com$/m)
  assert.match(s.read("hosts"), /^127\.0\.0\.1 localhost$/m)

  s.wants({ sites: [], blocks: [] })
  s.run(at(0, 10))
  assert.equal(s.status().held, true)
  assert.deepEqual(s.status().sites, ["x.com"], "kept during the block")

  s.wants({ sites: ["x.com", "reddit.com"], blocks: [weekdays] })
  s.run(at(0, 10, 1))
  assert.deepEqual(s.status().sites, ["x.com", "reddit.com"], "adding is fine")
  assert.match(s.read("hosts"), /reddit\.com/)

  assert.throws(() => s.run(at(0, 11), ["--uninstall"]), "no uninstall during a block")

  s.wants({ sites: [], blocks: [] })
  s.run(at(0, 17))
  assert.equal(s.status().held, false)
  assert.deepEqual(s.status().sites, [])
  assert.equal(s.read("hosts"), "127.0.0.1 localhost\n", "hosts back to how it was")
})

test("helper pass: waits 10 min, opens 15 min, once a day", () => {
  const s = sandbox()
  s.wants({ sites: ["x.com"], blocks: [weekdays] })
  s.run(at(0, 10))
  s.wants({ sites: ["x.com"], blocks: [weekdays], unlock: { id: "a" } })
  s.run(at(0, 10))
  assert.equal(s.status().pass.state, "waiting")
  assert.equal(s.status().pass.from, at(0, 10, 10))
  s.run(at(0, 10, 9))
  assert.equal(s.status().blocked, true)
  s.run(at(0, 10, 10))
  assert.equal(s.status().pass.state, "open")
  assert.equal(s.status().blocked, false)
  assert.doesNotMatch(s.read("hosts"), /x\.com/)
  s.run(at(0, 10, 25))
  assert.equal(s.status().pass.state, "done")
  assert.equal(s.status().blocked, true)

  s.wants({ sites: ["x.com"], blocks: [weekdays], unlock: { id: "b" } })
  s.run(at(0, 11))
  assert.equal(s.status().pass.state, "denied", "one pass a day")

  s.wants({ sites: ["x.com"], blocks: [weekdays], unlock: { id: "c" } })
  s.run(at(1, 10))
  assert.equal(s.status().pass.state, "waiting", "new day, new pass")
  s.wants({ sites: ["x.com"], blocks: [weekdays] })
  s.run(at(1, 10, 2))
  assert.equal(s.status().pass, null, "cancelled before it opened")
  s.wants({ sites: ["x.com"], blocks: [weekdays], unlock: { id: "d" } })
  s.run(at(1, 10, 3))
  assert.equal(s.status().pass.state, "waiting", "a cancelled pass isn't used up")
})

test("helper ignores bad input from the user file", () => {
  const s = sandbox()
  s.wants({ sites: ["x.com\n1.2.3.4 bank.com", "ok.com"], blocks: [weekdays, { days: [1], start: "x", end: "y" }] })
  s.run(at(0, 9))
  assert.deepEqual(s.status().sites, ["ok.com"])
  assert.equal(s.status().blocks.length, 1)
  assert.doesNotMatch(s.read("hosts"), /bank/)
  fs.writeFileSync(path.join(s.dir, "wants.json"), "{ not json")
  s.run(at(0, 9, 1))
  assert.deepEqual(s.status().sites, ["ok.com"], "keeps the last good rules")
})
