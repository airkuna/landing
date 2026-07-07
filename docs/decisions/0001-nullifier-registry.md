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
