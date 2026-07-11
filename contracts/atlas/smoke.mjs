#!/usr/bin/env node
/**
 * sol-atlas smoke test — validates the generated artifacts.
 * Run after `node atlas/generate.mjs`:
 *   node atlas/smoke.mjs
 */
import { readFileSync, existsSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { keccak256Hex, selector, loadConfig } from './generate.mjs'

const ATLAS_DIR = dirname(fileURLToPath(import.meta.url))
const OUT = join(ATLAS_DIR, 'out')

let failures = 0
let checks = 0
function assert(cond, msg) {
  checks++
  if (!cond) {
    failures++
    console.error(`  ✗ ${msg}`)
  }
}
const section = (s) => console.log(`\n${s}`)

// ── 0. keccak / selector self-test ──
section('keccak & selectors')
assert(keccak256Hex('') === 'c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470', 'keccak256("") vector')
assert(selector('totalSupply()') === '18160ddd', 'selector totalSupply()')
assert(selector('name()') === '06fdde03', 'selector name()')
assert(selector('symbol()') === '95d89b41', 'selector symbol()')

// ── 1. artifacts exist ──
section('artifacts')
for (const f of ['atlas.dbml', 'atlas-data.json', 'atlas-standalone.html'])
  assert(existsSync(join(OUT, f)), `out/${f} exists`)
if (failures) { console.error(`\nFAIL early: run node atlas/generate.mjs first`); process.exit(1) }

const data = JSON.parse(readFileSync(join(OUT, 'atlas-data.json'), 'utf8'))
const dbml = readFileSync(join(OUT, 'atlas.dbml'), 'utf8')
const standalone = readFileSync(join(OUT, 'atlas-standalone.html'), 'utf8')
const config = loadConfig()

// ── 2. exact contract count derived from config (optional contracts count only if present on disk) ──
section('contract inventory')
const expected = []
for (const p of config.projects)
  for (const c of p.contracts)
    if (!c.optional || existsSync(join(p.rootAbs, c.source))) expected.push(c.name)
assert(expected.length >= 6, `config resolves to >= 6 contracts (got ${expected.length})`)
assert(data.contracts.length === expected.length, `data has exactly ${expected.length} contracts (got ${data.contracts.length})`)
for (const name of expected)
  assert(data.contracts.some((c) => c.name === name), `contract ${name} present in data`)
for (const c of data.contracts) {
  assert(Array.isArray(c.storage), `${c.name}: storage layout present`)
  assert(Array.isArray(c.abi) && c.abi.length > 0, `${c.name}: ABI present`)
  assert(c.getters.every((g) => /^[0-9a-f]{8}$/.test(g.selector)), `${c.name}: all getter selectors are 4 bytes`)
}

// ── 3. machines ──
section('machines')
assert(data.machines.length >= 2, `>= 2 machines (got ${data.machines.length})`)
assert(data.machines.length === (config.machines || []).length, 'all configured machines loaded')

const abiFns = new Map(data.contracts.map((c) => [c.name, new Set(c.abi.filter((e) => e.type === 'function').map((e) => e.name))]))

for (const m of data.machines) {
  const fns = abiFns.get(m.contract)
  assert(fns, `${m.id}: machine contract ${m.contract} exists in atlas`)
  if (!fns) continue

  const stateIds = new Set(m.states.map((s) => s.id))
  assert(stateIds.size === m.states.length, `${m.id}: state ids unique`)
  assert(m.states.some((s) => s.kind === 'initial'), `${m.id}: has an initial state`)
  for (const s of m.states)
    assert(['initial', 'active', 'terminal'].includes(s.kind), `${m.id}: state ${s.id} kind valid (${s.kind})`)

  if (m.stateGetter) assert(fns.has(m.stateGetter), `${m.id}: stateGetter ${m.stateGetter}() in ABI`)

  for (const [i, t] of (m.transitions || []).entries()) {
    assert(stateIds.has(t.from) && stateIds.has(t.to), `${m.id} t#${i}: endpoints ${t.from}->${t.to} are defined states`)
    if (t.fn !== 'time')
      assert(fns.has(t.fn), `${m.id} t#${i}: fn ${t.fn}() exists in ${m.contract} ABI`)
    for (const se of t.sideEffects || []) {
      const seFns = abiFns.get(se.contract)
      assert(seFns && seFns.has(se.fn), `${m.id} t#${i}: side effect ${se.contract}.${se.fn}() exists in ABI`)
    }
    for (const money of t.money || [])
      assert(money.token && money.from && money.to, `${m.id} t#${i}: money edge has token/from/to`)
  }
  for (const o of m.overlays || []) {
    assert(fns.has(o.enterFn) && fns.has(o.exitFn), `${m.id}: overlay ${o.id} enter/exit fns in ABI`)
    for (const b of o.blocks || []) assert(fns.has(b), `${m.id}: overlay ${o.id} blocked fn ${b}() in ABI`)
  }
}

// crowdfund machine must cover all four invest paths + time edges + refunds
const pinka = data.machines.find((m) => m.id === 'pinka-crowdfund')
assert(pinka, 'pinka-crowdfund machine present')
if (pinka) {
  const paths = new Set(pinka.transitions.map((t) => t.path).filter(Boolean))
  for (const p of ['DIRECT_APPROVE', 'ERC677_TRANSFER', 'SEPA_IBAN', 'SAFE_DEPOSIT'])
    assert(paths.has(p), `pinka-crowdfund: invest path ${p} modeled`)
  assert(pinka.transitions.some((t) => t.fn === 'time'), 'pinka-crowdfund: has time-based transitions')
  assert(pinka.transitions.some((t) => t.fn === 'withdrawFunds' && t.money.length), 'pinka-crowdfund: withdrawFunds moves money')
  assert(pinka.transitions.some((t) => t.fn === 'claimRefund' && t.money.some((mo) => mo.to === 'burn')), 'pinka-crowdfund: claimRefund burns tokens')
  assert((pinka.overlays || []).some((o) => o.id === 'PAUSED'), 'pinka-crowdfund: pause overlay present')
}

// identity machine must be an explicit zero-money machine
const idm = data.machines.find((m) => m.id === 'identity-registry')
assert(idm, 'identity-registry machine present')
if (idm) {
  assert(idm.transitions.every((t) => (t.money || []).length === 0), 'identity-registry: zero money edges (visualizer must handle this)')
  assert(idm.transitions.some((t) => t.fn === 'claim' && (t.sideEffects || []).some((s) => s.fn === 'mint')), 'identity-registry: claim mints SBT')
  assert(idm.transitions.some((t) => t.fn === 'migrateAnchor' && (t.sideEffects || []).some((s) => s.fn === 'moveTo')), 'identity-registry: migrateAnchor moves SBT')
  assert(idm.transitions.some((t) => t.fn === 'reverify' && t.from === t.to), 'identity-registry: reverify is a self-loop')
}

// kuna machine must model the money flows (mint in, burn out) and the pause exception
const kuna = data.machines.find((m) => m.id === 'kuna-token')
assert(kuna, 'kuna-token machine present')
if (kuna) {
  assert(kuna.transitions.some((t) => t.fn === 'mint' && t.money.some((mo) => mo.from === 'mint')), 'kuna-token: mint creates KUNA')
  assert(kuna.transitions.some((t) => t.fn === 'burnFrom' && t.money.some((mo) => mo.to === 'burn')), 'kuna-token: burnFrom destroys KUNA')
  assert(kuna.transitions.some((t) => t.fn === 'transferAndCall' && t.money.length), 'kuna-token: ERC-677 path moves money')
  assert(kuna.transitions.some((t) => t.fn === 'transferGovernance' && t.from !== t.to), 'kuna-token: governance two-step lane modeled')
  assert(kuna.transitions.some((t) => t.fn === 'acceptGovernance'), 'kuna-token: acceptGovernance modeled')
  const kunaPause = (kuna.overlays || []).find((o) => o.id === 'PAUSED')
  assert(kunaPause, 'kuna-token: pause overlay present')
  if (kunaPause) assert(!kunaPause.blocks.includes('burnFrom'), 'kuna-token: burnFrom NOT pause-blocked (MiCA redemption right)')
}

// verifier node machine must mirror the doc lifecycle (pending → active → offline → ejected) + stake edges
const vnr = data.machines.find((m) => m.id === 'verifier-node-registry')
assert(vnr, 'verifier-node-registry machine present')
if (vnr) {
  for (const s of ['PENDING', 'ACTIVE', 'OFFLINE', 'EJECTED'])
    assert(vnr.states.some((st) => st.id === s), `verifier-node-registry: doc state ${s} present`)
  assert(vnr.states.find((s) => s.id === 'EJECTED')?.kind === 'terminal', 'verifier-node-registry: EJECTED is terminal')
  assert(vnr.transitions.some((t) => t.fn === 'register' && t.money.length), 'verifier-node-registry: register stakes xDAI')
  assert(vnr.transitions.some((t) => t.fn === 'eject' && t.money.some((mo) => String(mo.to).includes('treasury'))), 'verifier-node-registry: eject slashes to treasury')
  assert(vnr.transitions.some((t) => t.fn === 'withdrawStake' && t.from === t.to), 'verifier-node-registry: withdrawStake is a self-loop')
  assert(vnr.transitions.some((t) => t.fn === 'activate' && t.from === 'OFFLINE' && t.to === 'ACTIVE'), 'verifier-node-registry: offline reactivation modeled')
  assert(!vnr.transitions.some((t) => t.from === 'EJECTED'), 'verifier-node-registry: no transitions leave EJECTED')
}

// ── 4. refs — every endpoint must exist ──
section('refs')
assert(data.refs.length > 0, 'at least one ref discovered')
const contractCols = new Map(
  data.contracts.map((c) => [c.name, new Set(['_contract', ...c.storage.map((s) => s.label), ...c.immutableRefCols.map((s) => s.label)])]),
)
for (const r of data.refs) {
  assert(contractCols.has(r.from.contract), `ref from-contract ${r.from.contract} exists`)
  assert(contractCols.has(r.to.contract), `ref to-contract ${r.to.contract} exists`)
  if (r.from.field)
    assert(contractCols.get(r.from.contract)?.has(r.from.field), `ref field ${r.from.contract}.${r.from.field} is a column`)
  assert(['holds-address', 'calls', 'mints', 'burns'].includes(r.kind), `ref kind valid (${r.kind})`)
}
// the anchor refs of the two systems must have been found
const hasRef = (from, field, to) => data.refs.some((r) => r.from.contract === from && r.from.field === field && r.to.contract === to)
assert(hasRef('IdentityRegistry', 'verifier', 'EIP712Verifier'), 'IdentityRegistry.verifier -> EIP712Verifier')
assert(hasRef('IdentityRegistry', 'sbt', 'PersonhoodSBT'), 'IdentityRegistry.sbt -> PersonhoodSBT (immutable)')
assert(hasRef('PersonhoodSBT', 'registry', 'IdentityRegistry'), 'PersonhoodSBT.registry -> IdentityRegistry')
assert(hasRef('PinkaCrowdfund', 'token', 'PinkaToken'), 'PinkaCrowdfund.token -> PinkaToken (immutable)')
assert(hasRef('PinkaFactory', 'campaigns', 'PinkaCrowdfund'), 'PinkaFactory.campaigns -> PinkaCrowdfund (config)')
assert(data.refs.some((r) => r.kind === 'mints' && r.from.contract === 'PinkaCrowdfund' && r.to.contract === 'PinkaToken'), 'machine-derived mints edge')
assert(data.refs.some((r) => r.kind === 'burns' && r.from.contract === 'PinkaCrowdfund' && r.to.contract === 'PinkaToken'), 'machine-derived burns edge')

// ── 5. DBML grammar sanity: every Ref endpoint is a declared table.column ──
section('dbml')
const tableCols = new Map()
let current = null
for (const line of dbml.split('\n')) {
  const t = /^Table (\w+) \{/.exec(line)
  if (t) { current = t[1]; tableCols.set(current, new Set()); continue }
  if (/^\}/.test(line)) { current = null; continue }
  if (current) {
    const col = /^ {2}(\w+) /.exec(line)
    if (col && col[1] !== 'Note') tableCols.get(current).add(col[1])
  }
}
assert(tableCols.size === data.contracts.length, `DBML declares ${data.contracts.length} tables (got ${tableCols.size})`)
const refLines = dbml.split('\n').filter((l) => l.startsWith('Ref: '))
assert(refLines.length > 0, 'DBML has Ref lines')
for (const l of refLines) {
  const m = /^Ref: (\w+)\.(\w+) > (\w+)\.(\w+)/.exec(l)
  assert(m, `Ref line parses: ${l}`)
  if (!m) continue
  assert(tableCols.get(m[1])?.has(m[2]), `DBML ref source ${m[1]}.${m[2]} declared`)
  assert(tableCols.get(m[3])?.has(m[4]), `DBML ref target ${m[3]}.${m[4]} declared`)
}
assert(!/\t/.test(dbml), 'DBML has no tabs')
const braces = (dbml.match(/\{/g) || []).length - (dbml.match(/\}/g) || []).length
assert(braces === 0, 'DBML braces balanced')
for (const p of config.projects)
  assert(new RegExp(`^TableGroup ${p.id} \\{`, 'm').test(dbml), `DBML TableGroup ${p.id} present`)

// ── 6. standalone viewer ──
section('standalone viewer')
assert(standalone.includes('window.__ATLAS__ = {'), 'data inlined into standalone html')
assert(!standalone.includes('/*ATLAS:INLINE*/'), 'inline marker replaced')
assert(standalone.includes('drawMachine') && standalone.includes('drawSchema'), 'both views present in viewer code')
assert(standalone.includes('eth_call'), 'live mode present in viewer code')
const inlineJson = /window\.__ATLAS__ = (\{.*?\})\n<\/script>/s.exec(standalone)
assert(inlineJson, 'inlined data block found')
if (inlineJson) {
  const parsed = JSON.parse(inlineJson[1].replace(/<\\\//g, '</'))
  assert(parsed.contracts.length === data.contracts.length, 'inlined data matches atlas-data.json contract count')
}

// ── result ──
console.log(`\n${checks} checks, ${failures} failures`)
if (failures) process.exit(1)
console.log('SMOKE OK ✓')
