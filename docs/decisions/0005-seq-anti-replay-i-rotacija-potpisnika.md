# 0005 — `seq` po nullifieru protiv replaya; promjenu skupa potpisnika odobrava kvorum

Status: Proposed
Informed-by: eidchain (rotacija authority ključeva: kvorum trenutnih ključeva, `seq`, finalnost), analiza 2026-11-03
Supersedes: —
Superseded-by: —

## Context

**Replay atestacije.** EIP-712 struktura je `Attestation(anchor, nullifier, loa, expiry)` i
nema ni nonce ni redni broj. `IdentityRegistry.migrateAnchor()` ne provjerava `msg.sender`, a
atestacija je javna u calldata od `claim`/`migrateAnchor`. Dok `expiry` vrijedi (verifier-a2:
`ATTESTATION_TTL_SEC`, zadano 600 s), bilo tko može ponovno poslati staru atestaciju.

Scenarij: korisnik napravi `claim` na X, pa zbog kompromitacije X-a `migrateAnchor` na Y. Napadač
uzme atestaciju za X iz `claim` transakcije i pošalje `migrateAnchor(X, att)`. X je u tom trenutku slobodan
(`delete anchorToNullifier[oldAnchor]`), pa se identitet vraća na kompromitirani wallet. Kratki TTL
smanjuje prozor, ali ne uklanja problem.

eidchain isti problem kod rotacija rješava pravilom „`seq` mora biti jednak broju dosad
primijenjenih rotacija”. Svaka odobrena promjena vrijedi točno jednom i točno ondje gdje je predviđena.

**Upravljanje skupom potpisnika.** `EIP712Verifier.addSigner/removeSigner/setThreshold` su
`onlyAdmin`. M-of-N tako vrijedi samo za atestacije, a jedan admin ključ i dalje može zamijeniti cijeli skup
potpisnika. eidchain promjenu authority ključa dopušta samo uz odobrenje **kvoruma ključeva
koji vrijede u tom trenutku**. Promjena se primjenjuje od sljedećeg bloka, a stari zapisi ostaju
valjani pod ključevima koji su tada vrijedili.

## Decision

1. **`seq` po nullifieru.** `Identity` dobiva `uint64 seq`. Atestacija nosi `seq`
   (EIP-712: `Attestation(anchor, nullifier, loa, expiry, seq, action)`). Registar traži
   `att.seq == identities[nullifier].seq` (0 za `claim`), pa nakon uspjeha radi `seq++`.
   `action` (claim | migrate | reverify) sprječava da se atestacija za jednu akciju iskoristi za drugu.
   Verifier čita trenutni `seq` s lanca prije potpisivanja. Za eOsobnu (E, [0004](0004-eoi-kartica-web-eid-verifier.md))
   isti `seq` ulazi u izjavu koju potpisuje kartica.
2. **Promjene skupa potpisnika odobrava kvorum trenutnih potpisnika** (EIP-712 poruka
   `SignerSetChange{op, signer, threshold, setSeq}` s M potpisa trenutnog skupa), a ne admin. Admin
   ostaje samo za bootstrap na testnetu i odriče se uloge (renounce) prije mainneta.
3. Do Faze 2 (D) ovo se primjenjuje i na N=1 (C). Kod N=1 kvorum je jedan ključ, ali
   format i `setSeq` su već na mjestu, pa prelazak na mesh ne mijenja ugovor.

## Consequences

- **+** Zatvara replay za `migrateAnchor`/`reverify` bez oslanjanja na kratki TTL.
- **+** M-of-N postaje stvaran i za upravljanje skupom potpisnika, ne samo za atestacije.
- **−** Promjena EIP-712 tipa: treba prilagoditi `verifier-a2`, `EIP712Verifier`, testove i
  `DeployMVP`. Na Chiadu još nema deploya, pa je ovo trenutak za tu promjenu.
- **−** Verifier mora čitati stanje lanca (`seq`) prije potpisivanja. Dvije paralelne
  atestacije za istu osobu propadaju, ali kod ove akcije to je poželjno.
- **Test koji treba dodati:** replay atestacije iz `claim` nakon `migrateAnchor` mora revertati.
