# 0003 — Pepper custody

Status: Proposed
Informed-by: 0001 (nullifier-registry)
Supersedes: —
Superseded-by: —

## Context

Nullifier = `HMAC-SHA256(OIB, PEPPER)` ([0001](0001-nullifier-registry.md)). Sigurnost cijele
Sybil-otpornosti i privatnosti oslanja se na tajnost `PEPPER`-a. **Kritičan rizik:** prostor
validnih OIB-ova je malen (~10¹¹, i uz kontrolne znamenke još manji efektivno). Ako `PEPPER`
procuri, napadač može **brute-force izračunati nullifier za svaki OIB** i time:
- deanonimizirati onchain nullifiere (mapirati nullifier → OIB),
- unaprijed rezervirati/kovati identitete za tuđe OIB-ove ako verifier to dopušta.

Dakle pepper nije obična tajna — kompromitacija ruši i privatnost i integritet.

## Decision (prijedlog — otvoreno za raspravu)

1. **Pepper nikad na aplikacijskom serveru u plaintextu.** Kandidati:
   - **HSM / threshold custody** — HMAC se računa unutar HSM-a ili preko threshold-PRF-a (npr.
     distribuirani među istim potpisnicima kao verifier mesh), tako da nijedan pojedinačni host
     nema cijeli pepper.
   - Minimalno: pepper u KMS-u (Cloudflare/cloud KMS), HMAC iza tvrde granice, rotacija ključa.
2. **Per-epoch rotacija + verzija u registru.** `nullifier` nosi `pepperVersion`; rotacija ne
   invalidira postojeće identitete (stari nullifieri ostaju valjani pod svojom verzijom), ali
   ograničava štetu curenja na jednu epohu.
3. **Odvojen pepper po namjeni** (personhood vs phone-SBT) da curenje jednog ne kompromitira drugi.
4. **(Dopuna 2026-11-03) Klijentski verifieri trebaju OPRF.** zkTLS (A) i čip (B) dokaz rade kod
   korisnika, a korisnik ne smije imati pepper. Nullifier zato dobiva od čuvara peppera preko
   **(threshold) OPRF-a** (npr. RFC 9497 VOPRF): čuvar ne vidi OIB, a korisnik ne vidi pepper. ZK dokaz zatim
   veže taj izlaz uz OIB iz dokumenta. Bez toga se A/B svode na C (verifier vidi OIB).
   Verifier E ([0004](0004-eoi-kartica-web-eid-verifier.md)) ionako radi provjeru van lanca, pa koristi isti HMAC iza granice.

## Consequences

- **+** Curenje app-servera ne otkriva pepper; brute-force OIB→nullifier je blokiran.
- **+** Rotacija ograničava prozor štete.
- **−** Threshold/HSM HMAC dodaje složenost i latenciju u `claim` tok.
- **−** Rotacija traži `pepperVersion` u registru i migracijsku logiku — dizajnirati prije mainneta.
- **?** Otvoreno: je li threshold-PRF nad verifier meshom (Faza 2) prava dugoročna custody, ili HSM dovoljan za MVP?
