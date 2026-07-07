# airKUNA — Architecture Decision Records (ADR)

Ovo je **vlastita ADR baza airKUNA projekta** (Proof of Croatian Personhood protokol i
srodne odluke). Namjerno odvojena od `pay.domovina.ai/docs/decisions/` da onboarding na
airKUNA bude čist — samo aktualne, relevantne odluke, bez zastarjelih ADR-ova iz drugog
projekta.

## Princip: Single Source of Truth ≠ jedna mapa

SSOT znači **svaka odluka ima točno jedan mjerodavan dom, bez duplikata** — a ne "sve u
jednoj mapi". Zato:

- **ADR živi u repou koji je vlasnik odluke.** Payment-rail odluke → `pay.domovina.ai`.
  Personhood-protokol odluke → **airKUNA (ovdje)**.
- **Nikad ne kopiramo ADR** u dva repoa — **referenciramo** ga.

## Format

Nygard-stil, po ADR-u: `Status · Context · Decision · Consequences`, plus cross-ref polja:

```
# NNNN — Naslov
Status: Proposed | Accepted | Superseded
Informed-by: pay.domovina.ai ADR 000X (naslov)     # ideja potekla odande
Supersedes: —                                       # zamjenjuje raniju odluku
Superseded-by: —                                    # zamijenjen kasnijom
```

## Cross-repo politika (airKUNA ⇄ pay.domovina.ai)

- Origin ADR-ovi u payu (0003 PhoneSBT, 0004 mesh, 0005 Certilia, 0006 zkProof) **ostaju
  kao povijesni zapis** — nastali su u tom kontekstu.
- airKUNA ADR-ovi ih **referenciraju** (`Informed-by`) i gdje mijenjaju odluku, dodaju
  `Supersedes: pay ADR 000X`.
- Kad airKUNA ADR nadjača payev, u **payev** ADR dopiši jedan red
  `Superseded-by: airkuna ADR 000X` → nitko ga ne čita kao aktualan.

## Numeracija

airKUNA kreće od **0001** (svježe, ne nastavlja payevu sekvencu). Vidi `0000-index.md`.

## Budućnost

Kad personhood ugovori dobiju vlastiti repo, ADR-ovi se sele s kodom (ovaj folder je
privremeni dom dok je airkuna-web dokumentacijski hub).
