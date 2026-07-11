# airKUNA — Proof of Croatian Personhood — ugovori (reference)

**Reference / startna implementacija.** NIJE audited, NIJE za produkciju bez audita.
Prati whitepaper `../docs/16-whitepaper-proof-of-croatian-personhood.md` i ADR-ove
`../docs/decisions/` (0001 nullifier-registry, 0002 pluggable-verifier, 0003 pepper-custody).

## Datoteke

| Datoteka | Uloga |
|---|---|
| `src/interfaces/IVerifier.sol` | Pluggable verifier interface (ADR 0002): A zkTLS / B NFC / C orakl / D mesh |
| `src/interfaces/IPersonhoodSBT.sol` | Interface za SBT koji registar kuje/spaljuje |
| `src/interfaces/IIdentityRegistry.sol` | Minimalni view interface (`isPerson`) za potrošače registra (npr. token) |
| `src/interfaces/IERC677Receiver.sol` | Callback interface za ERC-677 `transferAndCall` primatelje |
| `src/PersonhoodSBT.sol` | EIP-5484 soulbound token (non-transferable), samo registar kuje |
| `src/IdentityRegistry.sol` | Srce: nullifier→Identity, `claim`/`migrateAnchor`/`reverify`/`revoke`, governance = Safe |
| `src/verifiers/EIP712Verifier.sol` | Verifier C (referenca): M-of-N EIP-712 potpisnika (prijelazno / temelj za mesh D) |
| `src/KunaToken.sol` | airKUNA e-money token (EMT po MiCA modelu): "1 KUNA = 1 EUR", ERC-20 + EIP-2612 permit + ERC-677 |

## Model (kratko)

- Jedinstvenost na razini **`nullifier = HMAC(OIB, pepper)`**, ne walleta (ADR 0001). Jedan OIB →
  jedan identitet. Više Safeova iste osobe → isti nullifier → drugi `claim` revertira.
- `IdentityRegistry` je **verifier-agnostičan**: zove `IVerifier.verify(...)` koji vrati
  `(nullifier, loa)` ili revertira. MVP koristi verifier A/B (klijentski dokaz); `EIP712Verifier`
  je prijelazni/mesh temelj.
- **Oporavak = eID:** `migrateAnchor` s novom atestacijom istog OIB-a → premjesti SBT na novi Safe.
- **Opoziv:** governance može identitet opozvati (`revoke`) — briše oba mapiranja i spali SBT
  (prijevara, smrt, sudski nalog). Osoba se kasnije može ponovno `claim`-ati svježom atestacijom
  (isti nullifier).
- **Governance = Safe multisig** (airKUNA DAO): mijenja odobreni verifier i parametre.

## airKUNA token (KunaToken)

- **EMT po MiCA modelu, Monerium stil:** KYC i SEPA rails žive OFF-chain kod izdavatelja;
  on-chain `issuer` kuje (`mint`) na SEPA uplatu i spaljuje (`burnFrom`) na otkup po paritetu
  "1 KUNA = 1 EUR". Otkupni burn je issuer-only (controller model) — korisnik ne daje allowance,
  a spaljeni iznos uvijek odgovara stvarno isplaćenom fiatu.
- **Standardi:** ERC-20 (18 decimala) + EIP-2612 `permit` (gasless odobrenja) + ERC-677
  `transferAndCall` (plati-i-obavijesti u jednoj transakciji; kompatibilno s PinkaCrowdfund
  Path A i Monerium-EURe integracijama).
- **Pauza NE blokira otkup:** `pause()` zamrzava transfere i mint, ali `burnFrom` (otkup) radi
  i pod pauzom — pravo na otkup po paritetu je MiCA pravo, izlaz se ne smije zamrznuti.
- **Personhood politika izdavanja (opcionalno):** kad je `identityRegistry` postavljen,
  `mint` primatelj mora zadovoljiti `isPerson(to)`. KYC je na fiat rampi; on-chain provjera
  osobnosti je DODATNA politika izdavanja (jedna osoba = jedan identitet). Transferi ostaju
  slobodni — samo je izdavanje ograničeno.
- **Governance = Safe multisig** s dvostupanjskim prijenosom (`transferGovernance` +
  `acceptGovernance`) — tipfeler ne može zaključati token.

## Pretpostavljeni toolchain

Foundry (`forge`). OpenZeppelin se koristi konceptualno; ovdje su ugovori namjerno self-contained
i minimalni radi čitljivosti — u produkciji koristi OZ ERC-721 + soulbound override, OZ AccessControl,
i ozbiljan test/audit. Pepper i off-chain verifikacija (JWKS/zkTLS) su IZVAN ugovora (vidi ADR 0003 i
`../docs/18-android-verifier-node-i-mvp-verifier-a.md`).

## Solidity

`^0.8.24`. Ciljni chain: Gnosis (chainId 100).
