# airKUNA — Proof of Croatian Personhood — ugovori (reference)

**Reference / startna implementacija.** NIJE audited, NIJE za produkciju bez audita.
Prati whitepaper `../docs/16-whitepaper-proof-of-croatian-personhood.md` i ADR-ove
`../docs/decisions/` (0001 nullifier-registry, 0002 pluggable-verifier, 0003 pepper-custody).

## Datoteke

| Datoteka | Uloga |
|---|---|
| `src/interfaces/IVerifier.sol` | Pluggable verifier interface (ADR 0002): A zkTLS / B NFC / C orakl / D mesh |
| `src/interfaces/IPersonhoodSBT.sol` | Interface za SBT koji registar kuje/spaljuje |
| `src/PersonhoodSBT.sol` | EIP-5484 soulbound token (non-transferable), samo registar kuje |
| `src/IdentityRegistry.sol` | Srce: nullifier→Identity, `claim`/`migrateAnchor`/`reverify`, governance = Safe |
| `src/verifiers/EIP712Verifier.sol` | Verifier C (referenca): M-of-N EIP-712 potpisnika (prijelazno / temelj za mesh D) |

## Model (kratko)

- Jedinstvenost na razini **`nullifier = HMAC(OIB, pepper)`**, ne walleta (ADR 0001). Jedan OIB →
  jedan identitet. Više Safeova iste osobe → isti nullifier → drugi `claim` revertira.
- `IdentityRegistry` je **verifier-agnostičan**: zove `IVerifier.verify(...)` koji vrati
  `(nullifier, loa)` ili revertira. MVP koristi verifier A/B (klijentski dokaz); `EIP712Verifier`
  je prijelazni/mesh temelj.
- **Oporavak = eID:** `migrateAnchor` s novom atestacijom istog OIB-a → premjesti SBT na novi Safe.
- **Governance = Safe multisig** (airKUNA DAO): mijenja odobreni verifier i parametre.

## Pretpostavljeni toolchain

Foundry (`forge`). OpenZeppelin se koristi konceptualno; ovdje su ugovori namjerno self-contained
i minimalni radi čitljivosti — u produkciji koristi OZ ERC-721 + soulbound override, OZ AccessControl,
i ozbiljan test/audit. Pepper i off-chain verifikacija (JWKS/zkTLS) su IZVAN ugovora (vidi ADR 0003 i
`../docs/18-android-verifier-node-i-mvp-verifier-a.md`).

## Solidity

`^0.8.24`. Ciljni chain: Gnosis (chainId 100).
