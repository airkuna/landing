# airKUNA ADR — Indeks

Aktualne arhitektonske odluke airKUNA projekta. Politika i format: `README.md`.

| ADR | Naslov | Status |
|---|---|---|
| [0001](0001-nullifier-registry.md) | Jedinstvenost na razini nullifiera, ne walleta | Accepted |
| [0002](0002-pluggable-verifier.md) | Pluggable verifier (zkTLS / NFC / orakl / mesh); MVP bez mesha | Accepted |
| [0003](0003-pepper-custody.md) | Pepper custody (threshold/HSM, rotacija, OPRF za klijentske verifiere) | Proposed |
| [0004](0004-eoi-kartica-web-eid-verifier.md) | eOsobna kartica preko Web eID-a (CAdES) kao verifier E | Proposed |
| [0005](0005-seq-anti-replay-i-rotacija-potpisnika.md) | `seq` po nullifieru protiv replaya; promjenu skupa potpisnika odobrava kvorum | Proposed |

## Povezano
- Whitepaper: `../16-whitepaper-proof-of-croatian-personhood.md`
- Prior-art & patentabilnost: `../15-prior-art-i-patentabilnost.md`
- EUDI Wallet knowledge: `../14-eudi-wallet-eidas2.md`
- Origin ADR-ovi (povijesni): `pay.domovina.ai/docs/decisions/` (0003–0006)
