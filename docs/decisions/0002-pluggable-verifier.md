# 0002 — Pluggable verifier; MVP bez signer-mesha

Status: Accepted
Informed-by: pay.domovina.ai ADR 0004 (Android verifier mesh), 0005 (Certilia eID)
Supersedes: pay.domovina.ai ADR 0004 (mesh se degradira iz "temelj" u "Faza 2, opcionalno")
Superseded-by: —

## Context

Blockchain ne može zvati Certilia OIDC → treba most eID → onchain. Ranija vizija (pay ADR 0004)
stavljala je **M-of-N Android verifier mesh** kao temelj. Dva kruga prior-art istraživanja pokazala su:

1. **Nitko** ne most-uje živi eID-OIDC onchain preko decentralizirane mreže → to je genuino novo,
   ali i neprovjereno; ne treba to biti *prvi* korak.
2. **World ID** radi personhood samo s nullifier-registrom + Semaphore zk, **bez ikakvog mesha** →
   mesh nije nužan za samu personhood funkciju.
3. Dokument/sesija se mogu **sami kriptografski dokazati** (Rarimo NFC putovnica preko ICAO PKI;
   Certilia OIDC preko zkTLS) → Sybil-otpornost bez oraklske mreže.
4. Android Key Attestation korijeni u **Googleu** → mesh je trust-minimized, ne trustless.
5. Ako mesh ipak treba, **Acurast** (250k+ telefona, HW atestacija, EVM potpisivanje) je mogući
   substrat — M-of-N je custom logika na njemu, ne gradnja od nule.

## Decision

`IdentityRegistry._verify()` je **apstrakcija s više implementacija**, biranih po fazi:

| Verifier | Mehanizam | Decentralizacija | Faza |
|---|---|---|---|
| **A. zkTLS/Certilia** | zk dokaz da je Certilia potpisao id_token s OIB-om | Certilia PKI | **MVP** |
| **B. NFC eOI** | pasivna autentikacija eOsobne (tip Rarimo) | državna PKI | **MVP alt.** |
| **C. EIP-712 orakl** | jedan off-chain verifier potpiše atestaciju | centralno | prijelazno |
| **D. Android mesh** | M nezavisnih HW-attested potpisnika | visoka (trust-min.) | **Faza 2** |

- **MVP = A ili B** (nullifier iz [0001](0001-nullifier-registry.md), bez mreže).
- **D = Faza 2**, opcionalno, po mogućnosti **na Acurast substratu**; koristi **M zasebnih EIP-712
  potpisnika (ne pravi threshold ECDSA/MPC)** — jednostavnije *i* ruta oko nChain threshold-ECDSA patenata.

## Consequences

- **+** MVP je jeftin i brz (nema hardvera/mreže). Mesh se dodaje samo ako A/B ne zadovolje.
- **+** Interface se ne mijenja pri prelasku A/B → D; registar ostaje isti.
- **−** Verifier A ovisi o zrelosti zkTLS-a nad Certilia endpointom (custom flow); provjeriti rano.
- **−** Priznati Google root-of-trust caveat za D u svakoj komunikaciji.
