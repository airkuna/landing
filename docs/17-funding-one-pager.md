# Proof of Croatian Personhood — Funding One-Pager

**An open-source, eID-rooted onchain proof-of-personhood layer for Sybil-resistant EU digital democracy.**
Built by **ITalk d.o.o.** (airKUNA) · Gnosis Chain · Apache-2.0 / MIT · Zagreb, Croatia

---

## The problem

Onchain governance and public-goods funding are broken by **Sybil attacks**: one person spins up
thousands of wallets and drowns out honest voters. Existing fixes are weak or centralized —
biometrics (privacy-hostile), social graphs (collusion-prone), or single-company KYC (a new gatekeeper).

Meanwhile, every EU citizen is getting a **state-issued digital identity** (eIDAS 2.0 EUDI Wallet,
mandatory by end-2026; in Croatia already live as **Certilia**, eIDAS **High** assurance). That trust
anchor exists — but there is **no open, privacy-preserving bridge from it to a public blockchain.**

## What we build

A protocol that turns a **verified national eID login** into a **soulbound token (SBT)** on Gnosis Chain,
where **one person = one identity across any number of wallets**, enforced by a non-reversible
`nullifier = HMAC(OIB)` — the raw national ID **never touches the chain or any plaintext store** (GDPR by design).

- **Source-agnostic:** Certilia today, **EUDI Wallet (SD-JWT VC / mDoc)** tomorrow → works for all 27 EU states.
- **Composable:** a public-chain SBT usable by any DAO, quadratic-funding round, or onchain vote — unlike the
  EU's permissioned EBSI.
- **Private voting:** MACI / Semaphore zk-nullifiers give one-person-one-vote **without linking vote to citizen**,
  with receipt-freeness (anti-vote-buying).

## Why it's novel (verified prior-art scan)

Every component has neighbors (World ID, Rarimo/zkPassport, EBSI, Acurast), but **the specific bridge —
a *live national eID (OIDC)* → *onchain personhood SBT* — is an unoccupied space.** World ID uses biometrics;
Rarimo uses passport NFC; EBSI is permissioned and off-DeFi. **We root in the EU's own mandatory eID and land
it on a public, composable chain.** The nullifier-registry + zk design mirrors proven practice (World ID);
our differentiator is the **eID root + EU-standard alignment + Croatian first-mover.**

## Why fund it as a public good

- **100% open source** — contracts, verifier node, docs. ITalk is a **non-custodial software provider**;
  regulated identity issuance stays with licensed parties (AKD/Certilia, EUDI). Minimal GDPR surface.
- **EU-strategy aligned** — directly complements eIDAS 2.0 / EUDI Wallet rollout (2024–2027) with the
  self-sovereign, composable layer the regulation itself gestures at (Recital 14: "zero-knowledge proof").
- **Reusable by everyone** — municipalities, associations (*udruge*), cooperatives, DAOs, participatory budgets.

## What we're asking for

| Track | Program | Ask | Use |
|---|---|---|---|
| **Now** | **EU NGI Pilots** (cascade funding, no consortium needed) | **~€60,000** | MVP: `IdentityRegistry` + `PersonhoodSBT` + verifier-A (zkTLS-over-Certilia), open-sourced |
| Next | **Gnosis / GnosisDAO ecosystem grant** | €25–100k | Deploy, audit prep, Safe/relayer integration |
| Next | **Optimism RetroPGF / Octant / Gitcoin** | retro | Reward shipped public-good usage |
| Later | **Digital Europe / EUDI Large-Scale Pilot** (via consortium: POTENTIAL/EWC/NOBID/DC4EU) | consortium share | EUDI Wallet source (SD-JWT VC/mDoc), pan-EU |

## Milestones (12 months)

1. **M0–M3 — MVP:** nullifier registry + SBT contracts on Gnosis testnet; verifier-A (zkTLS/Certilia) PoC; mock issuer/verifier harness.
2. **M4–M6 — Pilot:** first real Croatian-eID mints; a live association (*udruga*) vote; nodes on the public map.
3. **M7–M9 — Privacy:** MACI/Semaphore anonymous voting; pepper threshold-custody.
4. **M10–M12 — Decentralize & EU:** optional Android verifier mesh (on Acurast substrate); EUDI Wallet verifier track; security audit.

## Team & assets

ITalk d.o.o. (est. 2016, Zagreb) — already ships the surrounding stack: **Certilia eID verification in production**
(`domovina-api`), a **self-custody EURe wallet + Safe/relayer rail** (`pay.domovina.ai`), an **out-of-band SMS
proof gateway** (`sms.domovina.ai`), and a **public GIS map of Croatia** (`karta`) to visualize the node network.
This protocol is the identity layer that ties them together.

**Contact:** ms@airkuna.com · italk.hr

> *Not investment/legal advice. Freedom-to-operate note: a formal patent/FTO review is planned before any
> commercialization; the protocol is released as an open public good, not a patented product.*
