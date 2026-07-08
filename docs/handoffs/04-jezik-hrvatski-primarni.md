# Handoff / odluka #4 — Jezična politika: hrvatski primaran, engleski skriven do finalizacije

> Trajni zapis odluke korisnika (matija) o jeziku landing stranica u repou `airkuna-web`.

## Odluka

**Hrvatski je primarni, kanonski jezik svih landing stranica.** Prvo se finalizira i itererira
**hrvatska verzija sadržaja** (copy, brojke, ton). Engleske stranice ostaju u codebaseu, ali
**skrivene** (`<meta name="robots" content="noindex, nofollow">` + **ne** linkane iz javne navigacije).

**Tek kad smo zadovoljni hrvatskim sadržajem svega**, radi se **1:1 prijevod na engleski za sve
stranice** (uključujući `com/index.html` i `org/index.html`). Do tada se engleski NE itererira —
on je zamrznut izvor koji će se regenerirati iz finalnog hrvatskog.

Razlog: glavne stranice (`com/index.html`, `org/index.html`, `com/whitepaper/`) su već hrvatske;
dvije novije pod-stranice bile su engleske → miješanje jezika. Hrvatski je publika broj jedan.

## Trenutno stanje (nakon ove promjene)

| Sadržaj | Hrvatski (primaran, linkan) | Engleski (skriven: noindex, van navigacije) |
|---|---|---|
| Funding one-pager | `com/sazetak/` | `com/funding/` |
| Treasury flywheel (investitorski explainer) | `com/zamasnjak/` | `com/flywheel/` |
| Personhood landing | `com/index.html` (HR) | — (engleska verzija tek u fazi 1:1 prijevoda) |
| Whitepaper | `com/whitepaper/` (HR) | — |
| Stablecoin landing | `org/index.html` (HR) | — |

- HR i EN varijante su **zasebni fajlovi** (isti dizajn-sustav, prevodi se samo tekst; CSS/JS/Mermaid
  ostaju identični). Kalkulator/Mermaid logika se NE mijenja pri prijevodu.
- Folderi su samodostatni (svoj `coin.svg`).

## Pravila za buduće izmjene

1. **Uređuj hrvatski, ne engleski.** Sve nove izmjene sadržaja idu u HR verziju.
2. Engleske pod-stranice (`com/funding/`, `com/flywheel/`) drži `noindex` i **izostavi ih iz
   navigacije/footera** dok ne dođe faza 1:1 prijevoda.
3. Kad je HR finaliziran → generiraj EN 1:1 iz HR (ne obrnuto), pa makni `noindex` i uvrsti u navigaciju.
4. Terminološka dosljednost (glosar korišten pri prvom prijevodu): riznica, zamašnjak, kolateral (zalog),
   vlastito skrbništvo, prinos, posudba/kamata, dug, LTV (omjer zajma i vrijednosti), likvidacija,
   faktor zdravlja, LST (token likvidnog stakinga), isplata u eure (off-ramp), stablecoin, gubitak
   pariteta (de-peg), (vlasnički) udio, glavnica. Vlastita imena i tickeri (Solflare, Squads, Hobba,
   Jupiter, Circle, EURC, USDC, Monerium, Gnosis, JitoSOL, SOL, MiCA, SEPA) ostaju u originalu.

## Povezano
- `README.md` (tablica com/org), `docs/handoffs/02-landing-airkuna.md` (com↔org raspored)
- Memorija: `project-flywheel-funding-page`, `reference-airkuna-landing-design`
