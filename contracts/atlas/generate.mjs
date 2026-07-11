#!/usr/bin/env node
/**
 * sol-atlas generator.
 *
 * Reads atlas.config.json, runs `forge build` + `forge inspect` for every
 * registered contract, merges the hand-authored state machines and emits:
 *   out/atlas.dbml            — DBML schema (paste into dbdiagram.io)
 *   out/atlas-data.json       — merged model consumed by viewer.html
 *   out/atlas-standalone.html — viewer with the data inlined (file:// friendly)
 *
 * Zero npm dependencies — node:fs / node:path / node:child_process only.
 */
import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs'
import { spawnSync } from 'node:child_process'
import { dirname, resolve, join, isAbsolute } from 'node:path'
import { fileURLToPath } from 'node:url'
import { homedir } from 'node:os'

const ATLAS_DIR = dirname(fileURLToPath(import.meta.url))
const OUT_DIR = join(ATLAS_DIR, 'out')

// ─────────────────────────────────────────────────────────────
//  keccak-256 (needed for 4-byte selectors; BigInt implementation,
//  fine for the short inputs we hash). Exported for smoke.mjs.
// ─────────────────────────────────────────────────────────────

const M64 = (1n << 64n) - 1n
const RC = [
  0x0000000000000001n, 0x0000000000008082n, 0x800000000000808an, 0x8000000080008000n,
  0x000000000000808bn, 0x0000000080000001n, 0x8000000080008081n, 0x8000000000008009n,
  0x000000000000008an, 0x0000000000000088n, 0x0000000080008009n, 0x000000008000000an,
  0x000000008000808bn, 0x800000000000008bn, 0x8000000000008089n, 0x8000000000008003n,
  0x8000000000008002n, 0x8000000000000080n, 0x000000000000800an, 0x800000008000000an,
  0x8000000080008081n, 0x8000000000008080n, 0x0000000080000001n, 0x8000000080008008n,
]
// rho rotation offsets, indexed [x][y]
const RHO = [
  [0, 36, 3, 41, 18],
  [1, 44, 10, 45, 2],
  [62, 6, 43, 15, 61],
  [28, 55, 25, 21, 56],
  [27, 20, 39, 8, 14],
]
const rotl = (v, n) => n === 0 ? v : (((v << BigInt(n)) | (v >> BigInt(64 - n))) & M64)

function keccakF(A) {
  for (let round = 0; round < 24; round++) {
    // theta
    const C = []
    for (let x = 0; x < 5; x++) C[x] = A[x] ^ A[x + 5] ^ A[x + 10] ^ A[x + 15] ^ A[x + 20]
    for (let x = 0; x < 5; x++) {
      const D = C[(x + 4) % 5] ^ rotl(C[(x + 1) % 5], 1)
      for (let y = 0; y < 5; y++) A[x + 5 * y] ^= D
    }
    // rho + pi
    const B = new Array(25)
    for (let x = 0; x < 5; x++)
      for (let y = 0; y < 5; y++)
        B[y + 5 * ((2 * x + 3 * y) % 5)] = rotl(A[x + 5 * y], RHO[x][y])
    // chi
    for (let y = 0; y < 5; y++)
      for (let x = 0; x < 5; x++)
        A[x + 5 * y] = B[x + 5 * y] ^ ((~B[((x + 1) % 5) + 5 * y] & M64) & B[((x + 2) % 5) + 5 * y])
    // iota
    A[0] ^= RC[round]
  }
}

/** keccak256 of a UTF-8 string (or Uint8Array), hex output without 0x. */
export function keccak256Hex(input) {
  const msg = typeof input === 'string' ? new TextEncoder().encode(input) : input
  const rate = 136
  const padded = new Uint8Array(Math.ceil((msg.length + 1) / rate) * rate)
  padded.set(msg)
  padded[msg.length] |= 0x01
  padded[padded.length - 1] |= 0x80

  const A = new Array(25).fill(0n)
  for (let off = 0; off < padded.length; off += rate) {
    for (let j = 0; j < rate / 8; j++) {
      let lane = 0n
      for (let b = 7; b >= 0; b--) lane = (lane << 8n) | BigInt(padded[off + j * 8 + b])
      A[j] ^= lane
    }
    keccakF(A)
  }
  let out = ''
  for (let j = 0; j < 4; j++) {
    let lane = A[j]
    for (let b = 0; b < 8; b++) {
      out += (lane & 0xffn).toString(16).padStart(2, '0')
      lane >>= 8n
    }
  }
  return out
}

export const selector = (signature) => keccak256Hex(signature).slice(0, 8)

// ─────────────────────────────────────────────────────────────
//  forge helpers
// ─────────────────────────────────────────────────────────────

function findForge() {
  for (const cand of ['forge', join(homedir(), '.foundry/bin/forge')]) {
    const r = spawnSync(cand, ['--version'], { encoding: 'utf8' })
    if (r.status === 0) return cand
  }
  throw new Error('forge not found — install Foundry or put it on PATH')
}

function forgeJson(forge, cwd, args) {
  const r = spawnSync(forge, args, { cwd, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 })
  if (r.status !== 0) throw new Error(`forge ${args.join(' ')} (in ${cwd}) failed:\n${r.stderr || r.stdout}`)
  return JSON.parse(r.stdout)
}

// ─────────────────────────────────────────────────────────────
//  model building
// ─────────────────────────────────────────────────────────────

function buildContractModel(forge, project, contractCfg) {
  const layout = forgeJson(forge, project.rootAbs, ['inspect', contractCfg.name, 'storage-layout', '--json'])
  const abi = forgeJson(forge, project.rootAbs, ['inspect', contractCfg.name, 'abi', '--json'])

  const storage = (layout.storage || []).map((s) => ({
    label: s.label,
    type: layout.types?.[s.type]?.label ?? s.type,
    slot: s.slot,
    offset: s.offset,
  }))
  const storageLabels = new Set(storage.map((s) => s.label))

  // Parameterless view/pure functions — the live-mode surface.
  const getters = abi
    .filter((e) => e.type === 'function' && (e.stateMutability === 'view' || e.stateMutability === 'pure') && e.inputs.length === 0)
    .map((e) => ({
      name: e.name,
      selector: selector(`${e.name}()`),
      outputs: e.outputs.map((o) => ({ type: o.type, internalType: o.internalType || o.type })),
    }))

  // Getters with no backing storage variable = immutables / constants / derived views.
  const nonStorageGetters = getters.filter((g) => !storageLabels.has(g.name))
  // Contract-typed ones become pseudo-columns so cross-contract Refs can anchor on them.
  const immutableRefCols = nonStorageGetters
    .filter((g) => g.outputs.length === 1 && String(g.outputs[0].internalType).startsWith('contract '))
    .map((g) => ({ label: g.name, type: g.outputs[0].internalType, slot: null, offset: null, immutable: true }))

  return {
    name: contractCfg.name,
    project: project.id,
    source: contractCfg.source,
    storage,
    immutableRefCols,
    nonStorageGetters: nonStorageGetters.map((g) => ({ name: g.name, returns: g.outputs.map((o) => o.internalType).join(', ') })),
    getters,
    abi,
    functionNames: abi.filter((e) => e.type === 'function').map((e) => e.name),
    deployments: (project.deployments || []).filter((d) => !d.contract || d.contract === contractCfg.name),
  }
}

/** Resolve an internalType "contract X" or a variable name to a known contract. */
function resolveContract(contracts, { typeName, varName, preferProject }) {
  const byExact = (n) => contracts.filter((c) => c.name === n)
  const bySuffix = (n) => contracts.filter((c) => c.name.endsWith(n) && c.name !== n)
  let candidates = []
  if (typeName) {
    candidates = byExact(typeName)
    if (!candidates.length && typeName.startsWith('I')) {
      const base = typeName.slice(1)
      candidates = byExact(base)
      if (!candidates.length) candidates = bySuffix(base)
    }
  } else if (varName && varName.replace(/^_/, '').length >= 3) {
    const needle = varName.replace(/^_/, '').toLowerCase()
    candidates = contracts.filter((c) => c.name.toLowerCase().includes(needle))
  }
  if (candidates.length > 1 && preferProject) {
    const same = candidates.filter((c) => c.project === preferProject)
    if (same.length) candidates = same
  }
  return candidates[0] || null
}

function buildRefs(config, contracts, machines) {
  const refs = []
  const seen = new Set()
  const push = (ref) => {
    const key = `${ref.from.contract}.${ref.from.field ?? ''}->${ref.to.contract}:${ref.kind}`
    if (seen.has(key)) return
    seen.add(key)
    ref.crossProject = ref.from.project !== ref.to.project
    refs.push(ref)
  }
  const findContract = (name) => contracts.find((c) => c.name === name)

  // 1. explicit config refs
  for (const project of config.projects) {
    for (const r of project.refs || []) {
      const [fromContract, field] = r.from.split('.')
      const from = findContract(fromContract)
      const to = findContract(r.to)
      if (!from || !to) {
        console.warn(`  ! config ref skipped (unknown endpoint): ${r.from} -> ${r.to}`)
        continue
      }
      push({
        from: { project: from.project, contract: from.name, field },
        to: { project: to.project, contract: to.name },
        kind: r.kind || 'holds-address',
        note: r.note || '',
        source: 'config',
      })
    }
  }

  // 2. heuristics over storage columns + immutable pseudo-columns
  for (const c of contracts) {
    const cols = [...c.storage, ...c.immutableRefCols]
    for (const col of cols) {
      let target = null
      const m = /^contract (\w+)/.exec(col.type)
      if (m) target = resolveContract(contracts, { typeName: m[1], preferProject: c.project })
      else if (col.type === 'address') target = resolveContract(contracts, { varName: col.label, preferProject: c.project })
      if (target && target.name !== c.name) {
        push({
          from: { project: c.project, contract: c.name, field: col.label },
          to: { project: target.project, contract: target.name },
          kind: 'holds-address',
          note: col.immutable ? 'immutable' : `storage slot ${col.slot}`,
          source: 'heuristic',
        })
      }
    }
  }

  // 3. behavior edges derived from the machines (calls / mints / burns)
  for (const machine of machines) {
    const self = findContract(machine.contract)
    if (!self) continue
    const tokenContract = (tokenName) => {
      const t = machine.tokens?.[tokenName]
      return t && !t.external && t.contract ? findContract(t.contract) : null
    }
    for (const t of machine.transitions || []) {
      for (const se of t.sideEffects || []) {
        const target = findContract(se.contract)
        if (target) {
          push({
            from: { project: self.project, contract: self.name, field: null },
            to: { project: target.project, contract: target.name },
            kind: 'calls',
            note: `${t.fn} -> ${se.contract}.${se.fn}`,
            source: 'machine',
          })
        }
      }
      for (const money of t.money || []) {
        const target = tokenContract(money.token)
        if (!target) continue
        if (money.from === 'mint') {
          push({
            from: { project: self.project, contract: self.name, field: null },
            to: { project: target.project, contract: target.name },
            kind: 'mints',
            note: `${t.fn} mints ${money.token}`,
            source: 'machine',
          })
        }
        if (money.to === 'burn') {
          push({
            from: { project: self.project, contract: self.name, field: null },
            to: { project: target.project, contract: target.name },
            kind: 'burns',
            note: `${t.fn} burns ${money.token}`,
            source: 'machine',
          })
        }
      }
    }
  }

  return refs
}

// ─────────────────────────────────────────────────────────────
//  DBML emission
// ─────────────────────────────────────────────────────────────

const dbmlType = (t) => (/^[A-Za-z_][A-Za-z0-9_]*$/.test(t) ? t : `"${t.replace(/"/g, "'")}"`)
const dbmlNote = (s) => s.replace(/'/g, '’')

function emitDbml(config, contracts, refs) {
  const lines = []
  lines.push('// ── sol-atlas — generated schema, do not edit by hand ──')
  lines.push(`// Generated: ${new Date().toISOString()} by atlas/generate.mjs`)
  lines.push('//')
  lines.push('// HOW TO USE: open https://dbdiagram.io/d, create a new diagram and paste')
  lines.push('// this entire file into the DBML editor pane. Tables = contracts, rows =')
  lines.push('// storage variables (slot/offset in the row note). Rows noted "immutable"')
  lines.push('// are constructor-set immutables (not in storage) kept so Refs can anchor')
  lines.push('// on them. Refs = cross-contract address references (foreign keys).')
  lines.push('')
  lines.push('Project sol_atlas {')
  lines.push("  Note: 'EVM contract storage rendered as a relational schema'")
  lines.push('}')
  lines.push('')

  for (const c of contracts) {
    lines.push(`Table ${c.name} {`)
    lines.push("  _contract address [pk, note: 'the contract account itself (address)']")
    for (const s of c.storage) {
      const note = s.offset > 0 ? `slot ${s.slot}, offset ${s.offset}` : `slot ${s.slot}`
      lines.push(`  ${s.label} ${dbmlType(s.type)} [note: '${dbmlNote(note)}']`)
    }
    for (const col of c.immutableRefCols) {
      lines.push(`  ${col.label} ${dbmlType(col.type)} [note: 'immutable — constructor-set, not in storage']`)
    }
    lines.push("  Note: '''")
    lines.push(`  project: ${c.project} (${c.source})`)
    if (c.nonStorageGetters.length) {
      lines.push('  immutables / constants / derived views (parameterless getters without a storage slot):')
      for (const g of c.nonStorageGetters) lines.push(`    - ${dbmlNote(g.name)}() -> ${dbmlNote(g.returns)}`)
    }
    lines.push("  '''")
    lines.push('}')
    lines.push('')
  }

  for (const p of config.projects) {
    const members = contracts.filter((c) => c.project === p.id)
    if (!members.length) continue
    lines.push(`TableGroup ${p.id} {`)
    for (const c of members) lines.push(`  ${c.name}`)
    lines.push('}')
    lines.push('')
  }

  for (const r of refs) {
    if (!r.from.field) continue // behavior edges (calls/mints/burns) have no column — canvas only
    const comment = r.crossProject ? ' // cross-project' : ''
    lines.push(`Ref: ${r.from.contract}.${r.from.field} > ${r.to.contract}._contract${comment}`)
  }
  lines.push('')
  return lines.join('\n')
}

// ─────────────────────────────────────────────────────────────
//  main
// ─────────────────────────────────────────────────────────────

export function loadConfig() {
  const config = JSON.parse(readFileSync(join(ATLAS_DIR, 'atlas.config.json'), 'utf8'))
  for (const p of config.projects) {
    p.rootAbs = isAbsolute(p.root) ? p.root : resolve(ATLAS_DIR, p.root)
  }
  return config
}

function main() {
  const config = loadConfig()
  const forge = findForge()

  // sanity: keccak self-test so we never emit wrong selectors
  if (keccak256Hex('') !== 'c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470' ||
      selector('totalSupply()') !== '18160ddd') {
    throw new Error('keccak256 self-test failed')
  }

  const contracts = []
  for (const project of config.projects) {
    console.log(`• project ${project.id} (${project.rootAbs})`)
    if (!existsSync(project.rootAbs)) throw new Error(`project root not found: ${project.rootAbs}`)
    // --extra-output storageLayout: a plain `forge build` caches artifacts WITHOUT
    // the storage layout, which then makes `forge inspect ... storage-layout` fail.
    const build = spawnSync(forge, ['build', '--extra-output', 'storageLayout'], { cwd: project.rootAbs, encoding: 'utf8' })
    if (build.status !== 0) throw new Error(`forge build failed for ${project.id}:\n${build.stderr || build.stdout}`)

    for (const contractCfg of project.contracts) {
      const srcPath = join(project.rootAbs, contractCfg.source)
      if (!existsSync(srcPath)) {
        if (contractCfg.optional) {
          console.log(`  - ${contractCfg.name}: optional, source absent — skipped`)
          continue
        }
        throw new Error(`source missing for ${contractCfg.name}: ${srcPath}`)
      }
      let model
      try {
        model = buildContractModel(forge, project, contractCfg)
      } catch (e) {
        if (!String(e.message).includes('storage layout missing')) throw e
        // stale cache built without storageLayout output — clean and rebuild once
        console.log(`  ! stale artifact cache for ${contractCfg.name} — forge clean + rebuild`)
        spawnSync(forge, ['clean'], { cwd: project.rootAbs, encoding: 'utf8' })
        const rebuild = spawnSync(forge, ['build', '--extra-output', 'storageLayout'], { cwd: project.rootAbs, encoding: 'utf8' })
        if (rebuild.status !== 0) throw new Error(`forge rebuild failed for ${project.id}:\n${rebuild.stderr || rebuild.stdout}`)
        model = buildContractModel(forge, project, contractCfg)
      }
      console.log(`  - ${contractCfg.name}: ${model.storage.length} storage vars, ${model.getters.length} parameterless getters`)
      contracts.push(model)
    }
  }

  const machines = (config.machines || []).map((rel) => {
    const machine = JSON.parse(readFileSync(join(ATLAS_DIR, rel), 'utf8'))
    machine.file = rel
    return machine
  })
  console.log(`• machines: ${machines.map((m) => m.id).join(', ')}`)

  const refs = buildRefs(config, contracts, machines)
  console.log(`• refs: ${refs.length} (${refs.filter((r) => r.source === 'heuristic').length} heuristic, ${refs.filter((r) => r.source === 'config').length} config, ${refs.filter((r) => r.source === 'machine').length} machine-derived)`)

  const data = {
    generatedAt: new Date().toISOString(),
    projects: config.projects.map((p) => ({ id: p.id, name: p.name, root: p.rootAbs })),
    contracts,
    refs,
    machines,
  }

  mkdirSync(OUT_DIR, { recursive: true })

  const dbml = emitDbml(config, contracts, refs)
  writeFileSync(join(OUT_DIR, 'atlas.dbml'), dbml)
  console.log(`• wrote out/atlas.dbml (${dbml.length} bytes)`)

  const json = JSON.stringify(data, null, 2)
  writeFileSync(join(OUT_DIR, 'atlas-data.json'), json)
  console.log(`• wrote out/atlas-data.json (${json.length} bytes)`)

  const viewer = readFileSync(join(ATLAS_DIR, 'viewer.html'), 'utf8')
  const marker = 'window.__ATLAS__ = null /*ATLAS:INLINE*/'
  if (!viewer.includes(marker)) throw new Error('viewer.html is missing the ATLAS:INLINE marker')
  const inlined = viewer.replace(marker, `window.__ATLAS__ = ${JSON.stringify(data).replace(/<\//g, '<\\/')}`)
  writeFileSync(join(OUT_DIR, 'atlas-standalone.html'), inlined)
  console.log(`• wrote out/atlas-standalone.html (${inlined.length} bytes)`)
  console.log('done ✓')
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main()
}
