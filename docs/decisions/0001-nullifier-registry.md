# 0001 — Jedinstvenost na razini nullifiera, ne walleta

Status: Accepted
Informed-by: pay.domovina.ai ADR 0003 (PhoneSBT / EIP-5484), 0005 (Certilia eID KYC)
Supersedes: —
Superseded-by: —

## Context

Cilj: jedna stvarna osoba = jedan onchain identitet, ali osoba ima **više Safe novčanika**
(hladni, topli, udruga, tvrtka). Naivni "SBT po walletu" ne radi — koji wallet nosi SBT, i
kako identitet vrijedi preko svih? Trebamo Sybil-otpornost koja je *iznad* novčanika.

OIB je stabilan jedinstveni identifikator osobe, ali je osjetljiv PII i ne smije onchain.
`domovina-api` već u produkciji koristi `oib_hash = HMAC-SHA256(oib, key)` s `unique`
ograničenjem (jedan OIB = jedan račun). World ID (istraženo) koristi isti obrazac:
deterministički nullifier + smart-contract registar + Semaphore zk, wallet-agnostično.

## Decision

Jedinstvenost enforcamo **na razini nullifiera, ne walleta**:

```
nullifier = HMAC-SHA256(OIB, PEPPER)     // deterministički, nepovratan
```

- `IdentityRegistry.claim()` traži `registry[nullifier].anchor == 0` → jedan OIB = jedan
  identitet, zauvijek.
- SBT (EIP-5484) živi u **jednom anchor Safeu**. Ostali novčanici se razrješavaju u nullifier
  preko ERC-1271 linka iz anchora, ili preko zk članstva (za glasanje).
- **Oporavak = eID:** ponovni Certilia login → isti nullifier → `migrateAnchor()` na novi Safe.
- Sirovi OIB nikad onchain ni u plaintext bazi (vidi [0003](0003-pepper-custody.md)).

## Consequences

- **+** Neograničeno novčanika, jedan identitet. Sybil-otpornost. eID kao recovery.
- **+** Isti dokazani obrazac kao World ID → nizak tehnički rizik; diferencijacija je eID izvor.
- **−** Pepper postaje kritična tajna (prostor OIB-ova ~10¹¹ je brute-force-abilan ako pepper curi)
  → rješava [0003](0003-pepper-custody.md).
- **−** `migrateAnchor` mora biti atomičan i zaštićen od zloupotrebe (svježa eID atestacija po migraciji).
  Svježina sama nije dovoljna: atestaciju se može ponovno poslati dok vrijedi → `seq` po nullifieru,
  [0005](0005-seq-anti-replay-i-rotacija-potpisnika.md).

## Dopuna 2026-11-03 (iz analize eidchaina, vidi [0004](0004-eoi-kartica-web-eid-verifier.md))

- **Normalizacija OIB-a prije HMAC-a, ista za sve izvore.** Ulaz u HMAC je točno 11 znamenki.
  Certilia daje OIB u `sub` (ili `pin`), eOsobna u certifikatu `subject.serialNumber = "PNOHR-<OIB>"`.
  Prefiks se skida, a kontrolna znamenka (ISO 7064 MOD 11,10) se provjerava. Bez toga ista osoba
  preko dva izvora dobiva dva nullifiera, a to je Sybil rupa.
- **Što nikad ne ide onchain:** OIB, ime, certifikat, potpis izdavača (CAdES/JWS) i OCSP odgovor.
  eidchain pokazuje što se događa ako se to ne poštuje: certifikat s OIB-om ostaje u svakom bloku
  zauvijek, a explorer ga može samo sakriti, ne i obrisati.
- **Rok valjanosti identiteta je ograničen dokumentom.** Svaka atestacija ima `expiry ≤ notAfter`
  certifikata ili dokumenta. Za glasanje se traži `reverifiedAt` unutar politike, jer onchain
  nema signala o opozivu (izgubljena kartica, smrt).
