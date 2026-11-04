.pragma library

// Moat: block distracting sites on a weekly schedule.
// Pure helpers, tested by `node --test check.js`. system/moat-helper (Python)
// repeats cleanSites, cleanBlocks, inBlock and the "stricter" rule; keep both in sync.

var DAY_SHORT = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
var DAY_LETTERS = ["M", "T", "W", "T", "F", "S", "S"]
var MAX_SITES = 200
var MAX_BLOCKS = 50
var WEEK_MIN = 7 * 24 * 60
var DOMAIN_RE = /^(?=.{1,253}$)([a-z0-9-]{1,63}\.)+[a-z]{2,63}$/

var PRESETS = [
  { name: "X", sites: ["x.com", "twitter.com"] },
  { name: "YouTube", sites: ["youtube.com", "youtu.be"] },
  { name: "Reddit", sites: ["reddit.com"] },
  { name: "Instagram", sites: ["instagram.com"] },
  { name: "TikTok", sites: ["tiktok.com"] },
  { name: "Facebook", sites: ["facebook.com"] }
]

function pad(n) { return (n < 10 ? "0" : "") + n }
function dayKey(d) { return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()) }

// ── sites ───────────────────────────────────────────────────────────────────
// "https://www.X.com/home" -> "x.com"; "" when it isn't a domain.
function cleanDomain(text) {
  var d = String(text || "").trim().toLowerCase()
  d = d.replace(/^[a-z]+:\/\//, "").split(/[\/?#:]/)[0].replace(/^www\./, "").replace(/\.$/, "")
  return DOMAIN_RE.test(d) ? d : ""
}

function cleanSites(list) {
  var out = []
  if (!Array.isArray(list)) return out
  for (var i = 0; i < list.length && out.length < MAX_SITES; i++) {
    var d = typeof list[i] === "string" ? cleanDomain(list[i]) : ""
    if (d && out.indexOf(d) === -1) out.push(d)
  }
  return out
}

function siteName(domain) {
  for (var i = 0; i < PRESETS.length; i++)
    if (PRESETS[i].sites.indexOf(domain) !== -1) return PRESETS[i].name
  return domain
}

function presetAdded(sites, preset) {
  for (var i = 0; i < preset.sites.length; i++)
    if (sites.indexOf(preset.sites[i]) === -1) return false
  return true
}

// Web app windows carry their site in the class: "chrome-www.youtube.com__-Default".
function windowHost(win) {
  var cls = String(win && (win["class"] || win.initialClass) || "")
  var m = cls.match(/^(?:chrome|chromium|brave|msedge|vivaldi)-([^_]+)__/i)
  return m ? m[1].toLowerCase() : ""
}

function siteFor(host, sites) {
  if (!host) return ""
  for (var i = 0; i < sites.length; i++)
    if (host === sites[i] || host.slice(-sites[i].length - 1) === "." + sites[i]) return sites[i]
  return ""
}

// ── times and blocks ────────────────────────────────────────────────────────
function validTime(t) { return typeof t === "string" && /^([01]\d|2[0-3]):[0-5]\d$/.test(t) }
function toMin(t) { var p = t.split(":"); return Number(p[0]) * 60 + Number(p[1]) }

// "9" -> "09:00"; also "9:30", "930", "17h", "17h30", "24" (midnight). "" when invalid.
function parseTime(text) {
  var m = String(text || "").trim().toLowerCase().match(/^(\d{1,2})(?:[:.h]?(\d{2}))?h?$/)
  if (!m) return ""
  var h = Number(m[1]), min = m[2] ? Number(m[2]) : 0
  if (h === 24 && min === 0) h = 0
  if (h > 23 || min > 59) return ""
  return pad(h) + ":" + pad(min)
}

function blockKey(b) { return b.days.join("") + "@" + b.start + "-" + b.end }

// Blocks are { days: [0..6, Monday first], start, end }. An end before the
// start runs past midnight and belongs to the start day.
function cleanBlocks(list) {
  var out = [], seen = {}
  if (!Array.isArray(list)) return out
  for (var i = 0; i < list.length && out.length < MAX_BLOCKS; i++) {
    var b = list[i]
    if (!b || !validTime(b.start) || !validTime(b.end) || b.start === b.end || !Array.isArray(b.days)) continue
    var days = []
    for (var d = 0; d < 7; d++) if (b.days.indexOf(d) !== -1) days.push(d)
    if (!days.length) continue
    var clean = { days: days, start: b.start, end: b.end }
    if (seen[blockKey(clean)]) continue
    seen[blockKey(clean)] = true
    out.push(clean)
  }
  return out
}

function inBlockMin(blocks, day, minute) {
  var prev = (day + 6) % 7
  for (var i = 0; i < blocks.length; i++) {
    var b = blocks[i], s = toMin(b.start), e = toMin(b.end)
    if (s < e) {
      if (b.days.indexOf(day) !== -1 && minute >= s && minute < e) return true
    } else {
      if (b.days.indexOf(day) !== -1 && minute >= s) return true
      if (b.days.indexOf(prev) !== -1 && minute < e) return true
    }
  }
  return false
}

function inBlock(blocks, date) {
  return inBlockMin(blocks, (date.getDay() + 6) % 7, date.getHours() * 60 + date.getMinutes())
}

// The block around nowMs { active, start, end } or the next one { next }.
// Walks minute by minute for up to a week, so touching blocks merge.
// A missing start/end/next is 0.
function span(blocks, nowMs) {
  var t = Math.floor(nowMs / 60000) * 60000
  var res = { active: inBlock(blocks, new Date(t)), start: 0, end: 0, next: 0 }
  if (!blocks.length) return res
  var i
  if (res.active) {
    for (i = 1; i <= WEEK_MIN; i++)
      if (!inBlock(blocks, new Date(t - i * 60000))) { res.start = t - (i - 1) * 60000; break }
    for (i = 1; i <= WEEK_MIN; i++)
      if (!inBlock(blocks, new Date(t + i * 60000))) { res.end = t + i * 60000; break }
  } else {
    for (i = 1; i <= WEEK_MIN; i++)
      if (inBlock(blocks, new Date(t + i * 60000))) { res.next = t + i * 60000; break }
  }
  return res
}

// A week with no free minute could never be edited again.
function hasFreeTime(blocks) {
  for (var day = 0; day < 7; day++)
    for (var m = 0; m < 1440; m++)
      if (!inBlockMin(blocks, day, m)) return true
  return false
}

// During a block the rules may only grow: keep every site and every block.
function isStricter(nextSites, nextBlocks, sites, blocks) {
  var i, keys = nextBlocks.map(blockKey)
  for (i = 0; i < sites.length; i++) if (nextSites.indexOf(sites[i]) === -1) return false
  for (i = 0; i < blocks.length; i++) if (keys.indexOf(blockKey(blocks[i])) === -1) return false
  return true
}

function hasBlock(blocks, b) { return blocks.map(blockKey).indexOf(blockKey(b)) !== -1 }

// ── state file ──────────────────────────────────────────────────────────────
function normalize(data) {
  data = data && typeof data === "object" ? data : {}
  var u = data.unlock
  return {
    sites: data.sites === undefined ? ["x.com", "twitter.com"] : cleanSites(data.sites),
    blocks: cleanBlocks(data.blocks),
    unlock: u && typeof u.id === "string" && u.id ? { id: u.id, requestedAt: Number(u.requestedAt) || 0 } : null,
    closedToday: Math.max(0, parseInt(data.closedToday, 10) || 0),
    closedDate: typeof data.closedDate === "string" ? data.closedDate : ""
  }
}

function newId() { return Date.now().toString(36) + Math.floor(Math.random() * 1e9).toString(36) }

// Six groups of five random letters to type out by hand.
function phrase() {
  var abc = "abcdefghjkmnpqrstuvwxyz", groups = []
  for (var g = 0; g < 6; g++) {
    var w = ""
    for (var i = 0; i < 5; i++) w += abc.charAt(Math.floor(Math.random() * abc.length))
    groups.push(w)
  }
  return groups.join(" ")
}

// ── labels ──────────────────────────────────────────────────────────────────
function describeDays(days) {
  var s = days.join(",")
  if (days.length === 7) return "Every day"
  if (s === "0,1,2,3,4") return "Weekdays"
  if (s === "5,6") return "Weekends"
  var run = days.length >= 3 && days[days.length - 1] - days[0] === days.length - 1
  if (run) return DAY_SHORT[days[0]] + "–" + DAY_SHORT[days[days.length - 1]]
  return days.map(function(d) { return DAY_SHORT[d] }).join(", ")
}

function fmtTime(ms) { var d = new Date(ms); return pad(d.getHours()) + ":" + pad(d.getMinutes()) }

// "17:00", "tomorrow 09:00" or "Mon 09:00".
function fmtWhen(ms, nowMs) {
  var d = new Date(ms), today = new Date(nowMs)
  var tomorrow = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 1)
  if (dayKey(d) === dayKey(today)) return fmtTime(ms)
  if (dayKey(d) === dayKey(tomorrow)) return "tomorrow " + fmtTime(ms)
  return DAY_SHORT[(d.getDay() + 6) % 7] + " " + fmtTime(ms)
}

// "2h 14m", "45m", "under 1m".
function fmtLeft(ms) {
  var min = Math.ceil(ms / 60000)
  if (ms <= 0) return "0m"
  if (min < 1) return "under 1m"
  if (min < 60) return min + "m"
  return Math.floor(min / 60) + "h" + (min % 60 ? " " + (min % 60) + "m" : "")
}

// "9:05" for short countdowns.
function fmtClock(ms) {
  var s = Math.max(0, Math.ceil(ms / 1000))
  return Math.floor(s / 60) + ":" + pad(s % 60)
}
