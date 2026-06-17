# airKUNA — Plan sadržaja landing stranica + dokumentacijska struktura

> **Status:** plan (ništa nije implementirano). Ovaj dokument je rezultat side-by-side analize 4 izvorna dokumenta, oba postojeća landing pagea (airkuna.com + airkuna.org) i nezavisnog fact-checka prema vanjskim izvorima (ECB, HNB, EBA, HANFA, Monerium, World Bank, Visa…).
> **Cilj:** jasno, jednostavnim rječnikom, komunicirati **činjenični problem** hrvatske ekonomije i **rješenje** koje airKUNA daje — bez filozofiranja, sa svakim brojem potkrijepljenim izvorom.
> **Datum:** 2026-06-17

---

## 0. Sažetak u jednoj rečenici

Hrvatska je platila ~5,5 mlrd $ da sanira banke, prodala ih za ~1–1,5 mlrd €, a strani vlasnici od tada izvlače 10+ mlrd € dobiti (samo dividende > 3 mlrd € u 2022.–2024., ~98% van zemlje) — airKUNA je regulirani euro stablecoin (MiCA e-money token, 1:1 euro, otkup po nominali) koji vraća kontrolu nad novčanom infrastrukturom i platnim maržama u domaću ekonomiju.

---

## 1. Četiri izvorna dokumenta — što svaki donosi

| # | Datoteka | Tema | Glavni "ubojiti" podaci | Najjači format |
|---|----------|------|--------------------------|----------------|
| **A** | `remixed-dbf530d8.md` | **Creator economy plaćanja** | Kreatori gube 15–40% (>50% na mikro <€3) na naknade; Patreon 10% + processing; Solana ~€0,00025/tx; MoR + MiCA model | Fee-waterfall tablica, usporedba €1 plaćanja kroz kanale |
| **B** | `remixed-bf4ed9d9.md` | **Vlasništvo banaka i lanac ekstrakcije** | >3 mlrd € dividendi 2022.–2024., ~98% van; krajnji vlasnici: BlackRock, Vanguard, Norges, talijanske zaklade iz 1563./1823. | Stablo vlasništva (drill-down do Wall Streeta) |
| **C** | `remixed-69d41156.md` | **Povijest rasprodaje banaka 1992.–2025.** | Sanacija ~5,5 mlrd $; prodano za ~1–1,5 mlrd €; 60→20 banaka; oportunitetni trošak S&P 500 ≈ €8,2 mlrd; rekordna dobit 1,53 mlrd € (2024.) | Vremenska crta, "što da je uloženo u S&P 500" |
| **D** | `remixed-64b3afd6.tsx` | **Simulacija kredita / kako nastaje novac** | Banka stvara novac "iz ničega"; kredit 10.000 € → ~2.950 € kamate trajno odlazi stranom vlasniku; ~97% novca nastaje kreditom | Interaktivna step-by-step simulacija (cigla) |

**Ključni uvid kombinatorike:** od ova 4 problema, **landing pageovi trenutno pokrivaju samo ~1,5** (dio B + dio D). Dokumenti **A (creator economy) i C (povijest rasprodaje) gotovo uopće nisu na stranicama** — a to su najjači, najkonkretniji, najmanje "filozofski" argumenti.

---

## 2. SIDE-BY-SIDE: što je već uključeno vs. što nedostaje

Legenda: ✅ pokriveno · 🟡 djelomično / slabo · ❌ nedostaje

### 2.1 Po temi (izvor → landing)

| Tema (izvor) | airkuna.com | airkuna.org | Procjena | Što konkretno nedostaje |
|---|---|---|---|---|
| **Što je stablecoin / EMT** (research) | ✅ Hero + "Što je" | ✅ "Stablecoin u minuti" | ✅ | OK; dodati 1 rečenicu "nije kripto špekulacija" je već tu |
| **Mint/burn mehanika** | ✅ Mermaid #1 | 🟡 (u kuharici) | ✅ | OK |
| **Dokazani model Monerium** | ✅ fact box | ✅ fact box | 🟡 | Godina osnivanja (2016, ne 2019); 6 lanaca; bez linka na monerium.com |
| **Kako nastaje novac (endogeni)** (D) | ❌ | ✅ Mermaid #2 | 🟡 | Samo na .org; nedostaje izvor (Bank of England 2014); typo u dijagramu |
| **Simulacija kredita / kamata kao odljev** (D) | ❌ | ❌ | ❌ | Cijeli "cigla" primjer (10.000 € → 2.950 € kamate van) nije nigdje — a najlakše ga je razumjeti |
| **Ekstrakcija: dividende van** (B) | ❌ | ✅ Mermaid #3 + tablica | 🟡 | Lanac staje na "strana matica"; **ne ide dublje do krajnjih vlasnika** |
| **Tko su KRAJNJI vlasnici** (B) | ❌ | ❌ | ❌ | BlackRock/Vanguard/Norges + talijanske zaklade (1563., 1823.) — potpuno odsutno; najjači "wow" podatak |
| **Povijest rasprodaje banaka** (C) | ❌ | ❌ | ❌ | Sanacija 5,5 mlrd $ → prodaja 1–1,5 mlrd € → 10 mlrd € izvučeno; 60→20 banaka |
| **Oportunitetni trošak (S&P 500)** (C) | ❌ | ❌ | ❌ | €8,2 mlrd "da je uloženo" — dramatičan, konkretan broj |
| **Rekordne dobiti / ECB facility** (C) | ❌ | 🟡 (samo dividende) | 🟡 | 1,53 mlrd € (2024.); HNB platio bankama 532 mil € (2024.) |
| **Creator economy problem** (A) | ❌ | ❌ | ❌ | **Cijela vertikala odsutna** — a to je konkretan "kome ovo pomaže sutra" |
| **Naknade građanima/trgovcima** (research) | ❌ | ❌ | ❌ | Kartične naknade iznad EU prosjeka (AZTN); interchange |
| **Tržište / prilika** | ✅ #trziste | 🟡 stat band | ✅ | OK, treba ispraviti brojke (v. §5) |
| **Poslovni model (treasury yield)** | ✅ #poslovni | ❌ | ✅ | OK na .com |
| **Već radi (live)** | ✅ #live | ❌ | ✅ | OK na .com |
| **Kuharica (kako izdati)** | ❌ | ✅ Mermaid #4 | ✅ | OK na .org |
| **Povijest kune (krzno→kod)** | ❌ | ✅ | ✅ | OK na .org |

### 2.2 Što nedostaje na razini stranice (strukturno)

**airkuna.com (investitori) — rupe:**
- ❌ **Nijedan broj nema citat izvora** (najveća slabost za VC publiku).
- ❌ Nema **tim / osnivač / advisori** (samo mail).
- ❌ Nema **roadmap / licencni status / jurisdikcija** za airKUNA-inu vlastitu EMI.
- ❌ Nema **specifike aska** (veličina runde, valuacija, upotreba sredstava).
- ❌ Nema **vlastitih traction metrika** (svi volumeni su tržišni ili Monerium).
- 🟡 Miješa "$33 bilijuna (2025.)" volumen i "$312 mlrd (2026.)" market cap bez razlikovanja.

**airkuna.org (pokret) — rupe:**
- ❌ Nema **community akcije** (newsletter, pridruži se, peticija) unatoč "pokret" framingu — oba CTA-a samo guraju na .com.
- 🟡 Tvrdnja "97% novca" bez izvora; typo "odlucuje sto" u Mermaid dijagramu.
- 🟡 Nesklad: zbroj tržišnih udjela ~91,8% vs "88,9% strano"; HPB 9,4% domaći implicira ~90,6% strano.
- ❌ Nema dubokog lanca vlasništva ni povijesti rasprodaje (najjača građa odsutna).

---

## 3. KORIGIRANE ČINJENICE (fact-check — obavezno prije objave)

Nezavisni research je potvrdio većinu, ali ovo treba ispraviti/precizirati:

| Tvrdnja na stranici | Status | Točna verzija + izvor |
|---|---|---|
| "~$33 bilijuna godišnji volumen stablecoina 2025." | 🔴 ispraviti | **~$27,6 bilijuna namireno u 2024.**, premašilo Visa+Mastercard zajedno. (CryptoSlate / Visual Capitalist, 2025) |
| "$312 mlrd market cap (2026.)" | 🟡 uskladiti | **> $280 mlrd (ECB, stu 2025.)**, ~8% kripto tržišta; projekcija $2 bilijuna do 2028. (ECB FSR 11/2025) |
| "EURC ~$0,4 mlrd" | ✅ | Euro segment ukupno ~€395 mil; EURC vodi ~41%. (ECB FSR; CoinGecko) |
| "Monerium — prva EMI licenca (2019.)" | 🟡 dopuniti | **Osnovan 2016.** u Reykjavíku; prvi EMI ovlašten za e-novac na blockchainu. Danas **6 lanaca**: Ethereum, Polygon, Gnosis, Arbitrum, Base, Linea. (monerium.com) |
| "88,9% strano vlasništvo" | ✅ | **≈89–90%** (N1: 88,9%; Telegram: ~89%). Za egzaktno: HNB *Bilten o bankama*. |
| "~2 mlrd € dividendi / 18 mj." | ✅ proširiti | **> 3,1 mlrd € u 2022.–2024.**; ~98% van (egzaktno 97,8% za ZABA+PBZ = 802 mil €). (Telegram.hr / HNB platna bilanca) |
| "~97% novca nastaje kreditom" | ✅ dodati izvor | Bank of England, *Money creation in the modern economy* (2014). |
| Stripe "2,9% + €0,30" (u dokumentu A) | 🟡 EU kontekst | Za EEA **1,5% + €0,25** (ne US 2,9%+$0,30). (stripe.com/pricing) |
| Creator economy "$250 mlrd 2025." | 🟡 godina | $250 mlrd = **2023.** (Goldman Sachs) → ~$480 mlrd 2027.; **EU ~€28–33 mlrd (2025.)**. |
| Dobit banaka | ✅ dodati | **1,36 mlrd € (2023.)**, **1,53 mlrd € rekord (2024.)**. (HNB preko tportal/fondovi.hr) |
| HNB platio bankama za prekonoćne depozite | ✅ novi podatak | **532,2 mil € (2024.)**, 478,9 mil € (2023.). **Plaća HNB** (ne izravno ECB). (HNB fin. izvještaj 2024.) |

> **Pravilo:** svaki broj na .com i .org mora imati vidljiv izvor (footnote/superscript ili "Izvori" blok kao što .org već ima za tablicu banaka).

---

## 4. JEDINSTVENI IZVOR ISTINE (SSOT) — predložena struktura dokumenata

Ulazni formati (whitepaper s citation-noiseom, .tsx komponenta) nisu pogodni za landing. Prijedlog: **`docs/` mapa s 12 markdown dokumenata**, svaki s vlastitim MermaidJS dijagramom. Landing pageovi se onda "hrane" iz ovih dokumenata (jedan broj → jedno mjesto istine).

```
docs/
├── 00-ssot-index.md              ← master indeks, mapiranje sekcija → dokumenata
├── 01-problem-ekstrakcija.md     ← ekstrakcijska ekonomija (B) + Mermaid lanac
├── 02-vlasnistvo-stablo.md       ← tko su KRAJNJI vlasnici (B) + Mermaid stablo
├── 03-povijest-rasprodaje.md     ← 1992.–2025. (C) + Mermaid timeline + S&P
├── 04-kako-nastaje-novac.md      ← endogeni novac + kredit/kamata (D) + Mermaid
├── 05-creator-economy.md         ← naknade kreatorima (A) + Mermaid fee-waterfall
├── 06-rjesenje-stablecoin.md     ← EMT/MiCA + mint/burn (research) + Mermaid
├── 07-dokazani-model-monerium.md ← Monerium EURe proof
├── 08-kuharica-kako-izdati.md    ← 5 koraka + Mermaid
├── 09-poslovni-model.md          ← treasury yield ekonomika
├── 10-trziste-prilika.md         ← sizing (ECB brojke)
├── 11-izvori.md                  ← svi izvori, grupirani po temi (single bibliography)
└── 12-pojmovnik.md               ← plain-language glossary (EMT, mint, burn, SEPA, MoR…)
```

### 4.1 Predloženi Mermaid dijagrami po dokumentu

| Doc | Dijagram | Tip | Što prikazuje |
|---|---|---|---|
| 01 | Lanac ekstrakcije | `flowchart TB` | Štediša → banka HR → dobit → matica → inozemstvo (postoji, zadržati) |
| 02 | **Stablo vlasništva** (NOVO) | `flowchart TD` | ZABA→UniCredit→{BlackRock 7,38%, Norges, Fondazione CRT (1991/19.st.), Del Vecchio, C.B. Libya}; PBZ→Intesa→{Compagnia di San Paolo (1563.), Cariplo (1823.)} |
| 03 | **Vremenska crta + bilanca** (NOVO) | `timeline` ili `flowchart LR` | 1991. sanacija 5,5 mlrd $ → 1999.–2002. prodaja 1–1,5 mlrd € → 2024. dobit 1,53 mlrd €; grana "da je uloženo u S&P 500 → €8,2 mlrd" |
| 04 | Kreacija novca + odljev kamate (NOVO/spoj) | `flowchart LR` | Banka stvara depozit → kredit 10.000 € → 10 rata → 2.950 € kamate odlazi van |
| 05 | **Fee-waterfall** (NOVO) | `flowchart LR` ili `sankey` | €1 plaćanje → -10% platforma → -processing → kreatoru 0,75 €; vs Solana ~0,00025 € |
| 06 | Mint/burn lifecycle | `flowchart LR` | (postoji na .com, zadržati kao SSOT) |
| 08 | 5 koraka kuharice | `flowchart LR` | (postoji na .org, zadržati) |

---

## 5. PLAN SADRŽAJA PO STRANICI (što dodati, kojim redom, kojim rječnikom)

Načelo komunikacije: **problem → broj → posljedica za tebe → kako airKUNA mijenja**. Kratke rečenice. Bez žargona bez objašnjenja (svaki pojam linka na `12-pojmovnik.md`).

### 5.1 airkuna.org (pokret/edukacija) — proširiti narativ

Trenutni redoslijed je dobar; **umetnuti 4 nove sekcije** (podebljano) i ojačati izvore:

1. Hero — "Kuna se vraća. Ovaj put kao euro." *(zadržati)*
2. Tri života kune *(zadržati)*
3. Stablecoin u minuti *(zadržati, ispraviti $33→$27,6 bilijuna 2024.)*
4. Kako nastaje novac *(zadržati, dodati izvor BoE 2014, ispraviti typo)*
5. **🆕 Simulacija kredita "Cigla"** — iz dokumenta D. Najjednostavniji mogući prikaz: kredit 10.000 € od susjeda do susjeda, ali 2.950 € kamate trajno odlazi stranom vlasniku. Statična verzija (3–4 koraka + brojke) ili interaktivna (port .tsx-a). *Most između "kako nastaje novac" i "problem".*
6. Problem: ekstrakcijska ekonomija *(zadržati, brojke → >3,1 mlrd €)*
7. **🆕 Tko zapravo zarađuje (stablo vlasništva)** — drill-down: ZABA→UniCredit→BlackRock/Norges/talijanske zaklade iz 1563. Poanta jednostavno: "novac s tvog računa na kraju putuje fondu na Wall Streetu i zakladi staroj 460 godina."
8. **🆕 Kako smo došli dovde (povijest rasprodaje)** — iz dokumenta C. "Platili smo 5,5 mlrd $ da sredimo banke, prodali ih za 1–1,5 mlrd €, a od tad je izvučeno 10+ mlrd €." + "da je uloženo u S&P 500 → 8,2 mlrd €."
9. Usporedba banaka (tablica) *(zadržati, uskladiti zbroj udjela)*
10. Dva modela, jedna razlika *(zadržati)*
11. **🆕 Kome ovo pomaže: kreator iz Hrvatske** — iz dokumenta A. Konkretno lice: kreator gubi 15–40% na naknade; on-chain euro = naknada djelić centa.
12. Kuharica *(zadržati)*
13. Monerium proof *(zadržati, 2016./6 lanaca)*
14. **🆕 Community CTA** — newsletter / "pridruži se" (trenutno nedostaje za "pokret").
15. Vizija + CTA *(zadržati)*

### 5.2 airkuna.com (investitori) — dodati kredibilitet i ask

Trenutni funnel je dobar; **dodati**:

- **Izvori/footnotes uz svaki broj** (najvažnije).
- **🆕 "Problem koji rješavamo"** — kratka verzija ekstrakcije + creator economy (TAM argument): €3+ mlrd/god odljeva + creator economy EU ~€28–33 mlrd.
- **🆕 Tim & advisori**.
- **🆕 Roadmap & licencni status** (jurisdikcija EMI, faze, datumi).
- **🆕 Ask** (runda, upotreba sredstava) — makar high-level.
- **🆕 Traction** (čak i rani: domovina.ai wallet/pay/mpt — broj transakcija/korisnika ako postoji).
- Ispraviti tržišne brojke (§3) i razdvojiti "godišnji volumen" od "market cap".

---

## 6. KLJUČNE PORUKE (plain-language, za copy)

Rezerva fraza koje prolaze test "razumije baka i tinejdžer":

- "Najstarije hrvatsko sredstvo plaćanja postaje najnovije."
- "1 KUNA = 1 euro. Uvijek. U svakom trenutku možeš vratiti euro."
- "Banka kad ti da kredit, ne posuđuje tuđu štednju — stvara novi novac. Tko stvara novac, odlučuje što se gradi."
- "Za svakih 10.000 € kredita, ~2.950 € kamate trajno odlazi vlasniku banke — u inozemstvo."
- "U 3 godine banke su isplatile preko 3 milijarde € dividendi. 98% je otišlo van Hrvatske."
- "Platili smo 5,5 milijardi $ da sredimo banke. Prodali ih za 1–1,5 milijardi €. Od tada je izvučeno više od 10 milijardi €."
- "Da je taj novac uložen u S&P 500, danas bismo imali ~8 milijardi € — dovoljno za godinu dana zdravstva."
- "Kreator u Hrvatskoj gubi 15–40% na naknade. On-chain euro: naknada je djelić centa."
- "Ne izmišljamo model. Monerium ovo radi od 2019. pod EU licencom."

---

## 7. SLJEDEĆI KORACI (redoslijed izvedbe — kad se krene implementirati)

1. **Potvrditi SSOT strukturu** (§4) i nazive dokumenata.
2. Napisati 12 markdown dokumenata + Mermaid dijagrame (sadržaj već ekstrahiran; treba ga složiti i ozvučiti izvorima).
3. Uskladiti/ispraviti brojke prema §3 na obje stranice.
4. Dodati nove sekcije na .org (§5.1) i .com (§5.2).
5. Dodati "Izvori" blok / footnotes na obje stranice.
6. (Opcionalno) port .tsx simulacije kredita u statičnu/lightweight verziju za .org.

---

## 8. Izvori (sažeto — puna bibliografija ide u `11-izvori.md`)

**Banke / ekstrakcija:** HNB *Bilten o bankama*; HNB fin. izvještaj 2024. (532,2 mil €); tportal/fondovi.hr (dobit 1,36/1,53 mlrd €); Telegram.hr (dividende >3,1 mlrd, 98%); N1 (88,9% strano); udrugafranak.hr (kumulativna dobit); AZTN (kartične naknade iznad EU).
**Vlasništvo:** UniCredit/Intesa/Erste/RBI/OTP IR stranice; simplywall.st; Wikipedia (Compagnia di San Paolo 1563., Cariplo 1823., Fondazione CRT); libyaherald.com.
**Stablecoin / regulativa:** ECB FSR 11/2025 (>$280 mlrd, ~€395M euro, $2T do 2028.); EBA/ESMA MiCA; HANFA/HNB (nadzor EMT/CASP); Monerium.com (EURe, 2016., 6 lanaca); CryptoSlate/Visual Capitalist ($27,6T 2024.).
**Solana:** solana.com (5.000 lampora, ~400ms); Helius.
**Creator economy:** Patreon Help Center (10%, kol 2025.); Goldman Sachs ($250 mlrd 2023.→$480 mlrd 2027.); BNP Paribas (EU €135 mlrd do 2032.); Stripe pricing (EEA 1,5%+€0,25).
**Eurozona:** HNB/ECB (1.1.2023., 1 € = 7,53450 kn).
**Novac:** Bank of England, *Money creation in the modern economy* (2014).
**Remitance/naknade:** Reg (EU) 2015/751 (interchange caps); World Bank RPW (6,36% global); Reg (EC) 924/2009 (SEPA).
