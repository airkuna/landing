# HANFA i HNB licence za airKUNA / ITalk / MPT model — verificirana pravna baza

**Svrha:** činjenična podloga za javnu, transparentnu web-stranicu o tome koje licence
(ne)trebaju ITalk d.o.o. i airKUNA za MPT (Monerium Payment Toolkit) poslovni model
s EURe stablecoinom. Istraženo 01.08.2026. primarno na **HANFA, HNB, Narodne novine,
EBA, ESMA, Monerium** izvorima; odvjetnički prikazi (Bird & Bird, DLA Piper, CMS…)
korišteni samo kao sekundarna potvrda.

> **Pravilo za autore:** ovo NIJE pravni savjet i na stranici mora stajati disclaimer.
> Prije pokretanja bilo kojeg scenarija koji nije "čisti softver" obavezna konzultacija
> s odvjetnikom i/ili upit HANFA-i (fintech kontakt) odnosno HNB-u. Regulativa je u
> tranziciji (PSD3/PSR u zakonodavnom postupku) — fiksiraj datum provjere uz svaku tvrdnju.

---

## A. Ključna pravna kvalifikacija: što je EURe?

Lanac kvalifikacije o kojem ovisi SVE ostalo:

| Korak | Tvrdnja | Izvor | Pouzdanost |
|---|---|---|---|
| 1 | EURe je **token elektroničkog novca (EMT)** u smislu MiCA-e (glava IV. Uredbe (EU) 2023/1114) | [Monerium](https://monerium.com/eure/) | HIGH |
| 2 | Izdavatelj je **Monerium EMI hf.**, institucija za elektronički novac (EMI) licencirana kod **Središnje banke Islanda**, s EEA passportingom | [Monerium](https://monerium.com/eure/), [MiCA Crypto Alliance](https://www.micacryptoalliance.com/news/mica-crypto-alliance-welcomes-regulated-electronic-money-institution-monerium-as-a-member) | HIGH |
| 3 | EMT se **pravno smatra elektroničkim novcem** (EMD2), a time i **"novčanim sredstvima" (funds) po PSD2** | [EBA mišljenje EBA/Op/2025/08, 10.6.2025.](https://www.eba.europa.eu/publications-and-media/press-releases/eba-publishes-no-action-letter-interplay-between-payment-services-directive-psd23-and-markets-crypto) | HIGH |
| 4 | Posljedica: usluge nad EURe mogu istovremeno biti **kripto-usluga (MiCA → CASP)** i **platna usluga (PSD2 → PI/EMI)** — tzv. **dvostruka autorizacija** | EBA No-Action Letter; [DLA Piper](https://www.dlapiper.com/en-us/insights/publications/2025/07/interplay-between-mica-and-psd2-for-transfers-of-electronic-money-tokens-eba-no-action-letter) | HIGH |
| 5 | Prijelazni rok iz EBA No-Action Lettera istekao je **2.3.2026.** — od tada NCA-ovi (u RH: HNB za platne usluge) trebaju tražiti PSD2 autorizaciju od CASP-ova koji prenose/čuvaju EMT-ove za klijente | [EBA press](https://eba.europa.eu/publications-and-media/press-releases/eba-advises-national-authorities-actions-take-end-transition-period-under-its-no-action-letter) | HIGH |
| 6 | Trajno rješenje očekuje se kroz **PSD3/PSR** (EBA preferira: platni zahtjevi ugrađeni u MiCA-u, bez dvostruke licence) — u zakonodavnom postupku | EBA No-Action Letter | HIGH (smjer), MEDIUM (ishod/rok) |

**Zašto je ovo bitno:** "zero-exchange-fee" NIJE relevantan kriterij. I MiCA i PSD2
hvataju usluge koje se pružaju **trećima na profesionalnoj/poslovnoj osnovi** —
naknada može biti neizravna (marketing, rast platforme, marža drugdje) ili je uopće
ne mora biti. Besplatnost ne oslobađa od licence; oslobađa jedino **nepružanje
regulirane usluge** (novac/tokeni nikad ne prolaze kroz tebe i ne kontroliraš ih).

---

## B. Podjela nadležnosti u RH (Zakon o provedbi Uredbe (EU) 2023/1114, NN 85/2024)

| Tijelo | Nadležnost po MiCA-i | Ostale relevantne nadležnosti |
|---|---|---|
| **HANFA** | Glave II., V., VI. — izdaje **odobrenja CASP-ovima** (čl. 59. MiCA-e), nadzire ponuditelje "ostale" kriptoimovine (ne-ART/EMT); kontaktna točka za ESMA-u | ECSP (crowdfunding), tržište kapitala, fondovi (UCITS/AIF), osiguranje, leasing, faktoring |
| **HNB** | Glave III., IV. — odobrenja **izdavateljima ART-a** (koji nisu kreditne institucije), nadzor **izdavatelja EMT-a** (kreditne institucije i institucije za e-novac); kontaktna točka za EBA-u | Kreditne institucije, **institucije za platni promet (PI)**, **institucije za e-novac (EMI)**, platni sustavi, mjenjači |

Izvori: [NN 85/2024](https://narodne-novine.nn.hr/clanci/sluzbeni/2024_07_85_1473.html) ·
[HANFA o zakonu](https://www.hanfa.hr/vijesti/donesen-zakon-o-provedbi-uredbe-o-trzistima-kriptoimovine-mica/)

**Kazne za rad bez odobrenja (NN 85/2024):** pravna osoba do **5.000.000 € ili 3 %
ukupnog prihoda**; fizička osoba do 500.000 €; odgovorne osobe u upravi do 1.000.000 €.

**Rokovi koji su već prošli (stanje 01.08.2026.):**
- CASP odobrenja HANFA izdaje od **30.12.2024.** (početak primjene MiCA-e na CASP-ove).
- **Grandfathering za postojeće VASP-ove istekao je 1.7.2026.** — tko danas u RH pruža
  kripto-usluge, mora imati MiCA odobrenje ([ESMA/HANFA poziv na uredan izlazak](https://hanfa.hr/vijesti/esma-poziva-pruzatelje-usluga-povezanih-s-kriptoimovinom-koji-nemaju-odobrenje-za-rad-na-uredan-prestanak-pruzanja-usluga-uz-istodobnu-zastitu-interesa-klijenata-po-isteku-prijelaznog-razdoblja-u-okviru-mica-e)).
- Prvo hrvatsko MiCA odobrenje: **Electrocoin d.o.o., travanj 2026.**; do srpnja 2026.
  izdana su tri ([HANFA](https://www.hanfa.hr/vijesti/sjednica-upravnog-vijeca-hanfe-electrocoin-doo-prvo-drustvo-koje-je-ishodilo-hanfino-odobrenje-za-rad-u-skladu-s-uredbom-mica/), [HANFA — treće odobrenje](https://hanfa.hr/vijesti/sjednica-upravnog-vijeca-hanfe-izdano-trece-odobrenje-za-rad-u-skladu-s-uredbom-mica), [Financije.hr](https://financije.hr/hanfa-izdala-prvu-mica-licencu-u-hrvatskoj-electrocoin-pod-punim-regulatornim-nadzorom/)).
- EBA-in prijelazni rok za **PSD2 sloj nad EMT uslugama istekao 2.3.2026.** — CASP koji
  prenosi/čuva EMT-ove za klijente, a nije barem predao PSD2 zahtjev, mora prestati
  s tim uslugama i off-boardati klijente.

---

## C. Deset MiCA kripto-usluga (CASP katalog, čl. 3(1)(16) MiCA-e)

Odobrenje se traži **po uslugama** — CASP licenca nije "sve ili ništa".

| # | Usluga (MiCA) | Relevantno za MPT/airKUNA model? |
|---|---|---|
| a | **Skrb i administriranje kriptoimovine za račun klijenata** (custody — čuvanje/kontrola privatnih ključeva) | **DA** — ako ITalk ikad kontrolira ključeve korisničkih walleta |
| b | Upravljanje platformom za trgovanje | Ne (nema order booka) |
| c | **Zamjena kriptoimovine za novčana sredstva** (crypto↔fiat) | **DA** — ako ITalk iz vlastite pozicije prodaje/otkupljuje EURe |
| d | **Zamjena kriptoimovine za drugu kriptoimovinu** (npr. EURe↔USDC) | **DA** — ako ITalk nudi swap iz vlastite pozicije |
| e | Izvršavanje naloga za račun klijenata | Uvjetno — ako ITalk izvršava kupnje/prodaje za korisnike |
| f | Plasman kriptoimovine | Ne |
| g | Zaprimanje i prijenos naloga (RTO) | Uvjetno — ako ITalk "prosljeđuje" korisničke naloge trećima (npr. burzi) |
| h | Savjetovanje o kriptoimovini | Uvjetno — pazi na sadržaj weba/aplikacije (personalizirane preporuke = savjetovanje) |
| i | Upravljanje portfeljem kriptoimovine | Uvjetno — "mi ti optimiziramo prinos" s diskrecijom = upravljanje portfeljem |
| j | **Usluge prijenosa kriptoimovine za račun klijenata** (transfer s jedne DLT adrese na drugu) | **DA — središnje pitanje.** Ako ITalk šalje EURe s adrese koju kontrolira po nalogu korisnika → CASP (j) **+ PSD2 sloj** (EMT = novčana sredstva) |

Izvori: [MiCA čl. 3](https://www.mica.wtf/mica/title-i-subject-matter-scope-and-definitions-art.-1-3/article-3) ·
[ESMA MiCA](https://www.esma.europa.eu/esmas-activities/digital-finance-and-innovation/markets-crypto-assets-regulation-mica) ·
[Norton Rose Fulbright vodič](https://www.nortonrosefulbright.com/en/knowledge/publications/2cec201e/regulating-crypto-assets-in-europe-practical-guide-to-mica)

**Što NIJE CASP usluga (izvan MiCA-e):**
- **Nekustodijalni (self-custody) softver i hardver** — pružatelji softvera/hardvera za
  novčanike kod kojih korisnik sam drži ključeve nisu u dosegu MiCA-e (recital 83).
  Granica je "substance over form": čim postoji recovery/admin ključ ili kontrola
  pristupa kod pružatelja, custody analiza se otvara ([ESMA/EBA pristup](https://blog.bcas.io/is-defi-really-excluded-from-micas-scope)).
- "Potpuno decentralizirane" usluge bez posrednika (recital 22) — usko, procjena od
  slučaja do slučaja; ne osloniti se na to.

---

## D. Kompletan katalog HANFA odobrenja (provjereno — sve kategorije)

Izvor: [HANFA — Odobrenja za društva iz nadležnosti Hanfe](https://www.hanfa.hr/licenciranje/odobrenja-za-drustva-iz-nadleznosti-hanfe/)

| # | Licenca / odobrenje | Propis | Relevantnost za airKUNA/ITalk |
|---|---|---|---|
| 1 | Društvo za osiguranje / reosiguranje | Zakon o osiguranju | — |
| 2 | Mirovinsko osiguravajuće društvo | ZMOD | — |
| 3 | Društvo za upravljanje UCITS fondovima | ZOIFJP | — |
| 4 | **Društvo za upravljanje alternativnim investicijskim fondovima (UAIF)** | Zakon o AIF-ovima | ⚠️ **Latentni rizik**: pooling tuđeg novca radi ulaganja (npr. "mi za tebe ulažemo u DeFi uz prinos") = AIF teritorij. Flywheel model NE smije primati tuđa sredstva u zajednički pool bez ove analize |
| 5 | Mirovinsko društvo — obvezni fondovi | ZOMF | — |
| 6 | Mirovinsko društvo — dobrovoljni fondovi | ZDMF | — |
| 7 | **Investicijsko društvo** (MiFID usluge) | Zakon o tržištu kapitala | ⚠️ Uvjetno: ako bi se ikad nudili **security tokeni** (financijski instrumenti u DLT obliku) ili investicijsko savjetovanje — ZTK, ne MiCA |
| 8 | Tržišni posrednik | ZTK | — |
| 9 | Burza | ZTK | — |
| 10 | Središnji depozitorij (CSD) | ZTK + Uredba 909/2014 | — |
| 11 | Središnja druga ugovorna strana (CCP) | ZTK + EMIR | — |
| 12 | Operater sustava poravnanja | ZTK | — |
| 13 | Leasing društvo | Zakon o leasingu | — |
| 14 | Faktoring društvo | Zakon o faktoringu | — |
| 15 | **Pružatelj usluga skupnog financiranja (ECSP)** | Uredba (EU) 2020/1503 + [NN 144/21](https://narodne-novine.nn.hr/clanci/sluzbeni/2021_12_144_2458.html) | ⚠️ Uvjetno: SAMO ako airKUNA vodi **platformu** koja spaja ulagatelje i nositelje projekata (krediti ili prenosivi vrijednosni papiri). Vidi F.9 |
| 16 | **Pružatelj usluga povezanih s kriptoimovinom (CASP)** | Uredba (EU) 2023/1114 + NN 85/24 + Pravilnik NN 95/25 | ✅ **Središnja licenca** za sve scenarije u kojima ITalk dira tuđe tokene (vidi matricu F) |

Uz to HANFA vodi registre distributera osiguranja (zastupnici/posrednici) — nije relevantno.

**ECSP detalji (za F.9):** HANFA odlučuje o odobrenju u roku 3 mjeseca od urednog
zahtjeva (čl. 12. st. 8. Uredbe 2020/1503). ECSP pokriva **kredite i prenosive
vrijednosne papire** — ne pokriva prikupljanje u kriptoimovini ni od potrošača za
potrošačke kredite. Ako bi se "flywheel" ikad otvorio javnosti kao ulaganje,
analiza ide: ECSP (platforma) vs. prospekt (vlastita emisija) vs. AIF (pooling).
Izvori: [HANFA — skupno financiranje](https://www.hanfa.hr/podrucja-nadzora/trziste-kapitala/skupno-financiranje-crowdfunding/) ·
[Pravilnik NN 150/22](https://narodne-novine.nn.hr/clanci/sluzbeni/2022_12_150_2315.html)

---

## E. Kompletan katalog HNB odobrenja (provjereno — sve kategorije)

Izvori: [HNB — licenciranje platnog prometa](https://www.hnb.hr/core-functions/payment-system/licensing) ·
[HNB — institucija za e-novac](https://www.hnb.hr/en/-/electronic-money-institution) ·
[Zakon o kreditnim institucijama](https://www.zakon.hr/z/195/zakon-o-kreditnim-institucijama)

| # | Licenca / odobrenje | Propis | Relevantnost za airKUNA/ITalk |
|---|---|---|---|
| 1 | Banka | Zakon o kreditnim institucijama | — |
| 2 | Štedna banka | ZOKI | — |
| 3 | Stambena štedionica | ZOKI | — |
| 4 | Kreditna unija | Zakon o kreditnim unijama | — |
| 5 | **Institucija za platni promet (PI)** | Zakon o platnom prometu (PSD2) | ✅ Ključna u scenarijima gdje ITalk **drži ili prenosi tuđa novčana sredstva** (uklj. EURe — EMT = "funds") ili **inicira plaćanja** s tuđih računa (PIS) |
| 6 | **Mala institucija za platni promet** | ZPP | ✅ Jeftinija ulazna varijanta PI-ja: samo RH (bez passportinga), limit volumena (prosjek platnih transakcija ≤ 3 mil €/mj.) |
| 7 | Registrirani pružatelj usluge informiranja o računu (AISP) | ZPP | Uvjetno — samo ako bi se čitali tuđi bančini računi radi agregacije (nije MPT slučaj) |
| 8 | **Institucija za elektronički novac (EMI)** | Zakon o elektroničkom novcu (EMD2) | ⚠️ Potrebna SAMO ako ITalk **izdaje vlastiti** e-novac / vlastiti EMT stablecoin. Za korištenje tuđeg (Monerium EURe) nije potrebna |
| 9 | Mala institucija za elektronički novac | ZEN | Isto kao 8, RH-only varijanta |
| 10 | Odobrenje za rad platnog sustava | Zakon o platnim sustavima | — |
| 11 | Ovlašteni mjenjač | Zakon o deviznom poslovanju | — (fizička gotovina/valute, ne kripto) |
| 12 | **Izdavatelj tokena vezanih uz imovinu (ART)** — odobrenje | MiCA glava III. + NN 85/24 | — (nema ART planova) |
| 13 | **Nadzor izdavatelja EMT-a** (mora biti kreditna institucija ili EMI + MiCA glava IV. bijela knjiga) | MiCA glava IV. + NN 85/24 | ⚠️ Relevantno tek u scenariju "vlastiti stablecoin" (F.10) |

**Statusi koji NISU licenca, a bitni su za model:**

| Status | Što znači | Za koga |
|---|---|---|
| **Tehnički pružatelj usluga** (PSD2 čl. 3(j) iznimka) | Podržava pružanje platnih usluga (IT, mreže, obrada podataka, autentifikacija) **bez da ikad dođe u posjed novčanih sredstava** | ✅ **Ciljani status ITalka u MPT modelu.** Iznimka otpada čim se dotaknu sredstva ILI se inicira plaćanje s tuđeg računa ([EBA Q&A](https://www.eba.europa.eu/single-rule-book-qa/qna/view/publicId/2022_6360)) |
| **Distributer e-novca** (EMD2) | Distribuira i/ili otkupljuje e-novac **u ime i za račun izdavatelja** (Moneriuma) po ugovoru; ne treba vlastitu licencu ni registraciju kod NCA | ⚠️ Moguć okvir za dublju suradnju s Moneriumom, ali granice su uske: distributer ne smije sam pružati platne usluge ni izdavati e-novac; a on-chain "predaja" tokena iz vlastite zalihe lako sklizne u CASP (c)/(j). Koristiti samo uz ugovor s Moneriumom i pravno mišljenje ([EC e-money FAQ](https://finance.ec.europa.eu/document/download/3a9f865b-4b16-4fbd-b25c-3c37d24d80ed_en?filename=e-money-faq-22122016_en.pdf), [thebanks.eu](https://thebanks.eu/articles/e-money-institutions-agents-and-distributors)) |
| **Zastupnik (agent) PI/EMI-ja** | Pruža platne usluge u ime licencirane institucije; upisuje se u registar te institucije/NCA | Alternativa vlastitoj licenci: ITalk kao registrirani agent neke PI/EMI (npr. Moneriuma) — tada usluge idu pod licencom principala |
| **Obveznik SPNFT-a (AML)** | Svaki CASP i PI/EMI je obveznik Zakona o sprječavanju pranja novca; čisti softverski pružatelj nije | Prati status: čim se uzme bilo koja licenca, dolazi puni AML program (SPNFT, Ured za sprječavanje pranja novca) |

---

## F. Kombinatorna matrica: scenarij → potrebna licenca

Osi kombinatorike: (1) tko prolazi KYC/KYB kod Moneriuma, (2) na čiji IBAN sjeda SEPA
uplata, (3) na čiji wallet se minta EURe, (4) tko i po čijem nalogu šalje EURe dalje,
(5) postoji li zamjena EURe↔druga kriptoimovina, (6) čijim se novcem radi.
Naknada (fee) NIJE os — besplatnost ne mijenja ništa (vidi A).

| # | Scenarij | MiCA/CASP (HANFA) | PSD2/ZPP (HNB) | Ostalo | Verdikt |
|---|---|---|---|---|---|
| **1** | **Čisti softver (MPT ciljani model):** korisnik radi KYC izravno kod Moneriuma (OAuth/co-branded), SEPA ide na **korisnikov** Monerium IBAN, EURe se minta na **korisnikov self-custody wallet**, ITalk servis samo prima webhooke i prikazuje stanje. Novac/tokeni nikad ne prolaze kroz ITalk, ITalk ne drži ključeve, ne inicira transfere | ✖ nije CASP (recital 83 — nekustodijalni softver; nema usluge iz čl. 3(1)(16)) | ✖ tehnički pružatelj (čl. 3(j)); ne dolazi u posjed sredstava, ne inicira plaćanja | AML: nije obveznik; Monerium je obveznik za KYC/transakcije | ✅ **Bez licence** |
| **2** | Kao 1, ali ITalk-ov backend **sam inicira** transfer s korisnikovog Monerium računa (drži API token korisnika i "puca" naloge po webhooku/pravilima) | ⚠️ ovisno o izvedbi: može biti (j) prijenos za račun klijenta iako ne drži ključeve/sredstva | ⚠️ **usluga iniciranja plaćanja (PIS)** — traži PI licencu čak i bez posjeda sredstava | — | ⚠️ **Siva zona — izbjegavati.** Nalog mora eksplicitno dati korisnik u svojoj sesiji (potpis/consent po transakciji), ne ITalk-ov server autonomno |
| **3** | **Prolazni model (danas opisan za pay.domovina.ai):** SEPA uplata trećih ide na **ITalk-ov** Monerium IBAN (KYB), Monerium minta EURe na **ITalk-ov wallet**, ITalk šalje EURe krajnjem primatelju po nalogu platitelja | ✔ CASP (j) prijenos za račun klijenata; dok tokeni stoje kod ITalka i (a) skrb | ✔ **novčana doznaka / izvršenje platnih transakcija** → PI licenca; EMT = funds (EBA/Op/2025/08); od 2.3.2026. dvostruka obveza se primjenjuje | AML obveznik; safeguarding sredstava | ❌ **Bez licenci NEDOPUŠTENO. Treba: HANFA CASP (a, j) + HNB PI** — ili restrukturirati u scenarij 1 |
| **4** | ITalk prima EURe **kao trgovac za vlastite usluge** (naplata vlastitih faktura u EURe, tokeni na vlastiti wallet) | ✖ nema usluge trećima | ✖ primatelj plaćanja nije PSP | računovodstvo/porezi | ✅ **Bez licence** |
| **5** | ITalk **iz vlastite riznice** šalje EURe (plaća dobavljače, suradnike; vlastita likvidnost, vlastiti ključevi) | ✖ nije "za račun klijenata" | ✖ vlastita plaćanja nisu platna usluga trećima | — | ✅ **Bez licence** |
| **6** | ITalk nudi korisnicima **zamjenu EURe↔USDC** (ili EURe↔fiat) iz vlastite pozicije, pa makar uz 0 naknade | ✔ CASP (d) odnosno (c) | ⚠️ + PSD2 sloj ako u lancu drži EMT/fiat za klijente | AML obveznik | ❌ **Treba HANFA CASP (c/d)**; bez licence zabranjeno od 1.7.2026. |
| **7** | ITalk drži **ključeve korisničkih walleta** (embedded/custodial wallet u aplikaciji, recovery pod kontrolom ITalka) | ✔ CASP (a) skrb | ✔ custody EMT-a = **vođenje računa za plaćanje** (EBA) → PI/EMI sloj | AML obveznik | ❌ **CASP (a) + PSD2** — najskuplja kombinacija; self-custody dizajn ovo izbjegava |
| **8** | ITalk kao **registrirani agent/distributer** licencirane institucije (npr. Monerium): onboarding, marketing, redemption support po ugovoru | ✖ vlastita CASP licenca nije nužna ako se ne pružaju CASP usluge u svoje ime | ✖ radi pod licencom principala (agent u registru; distributer bez registracije) | ugovor s principalom definira opseg | ⚠️ **Moguće bez vlastite licence**, ali opseg striktno ograničen ugovorom; on-chain izvedba pažljivo |
| **9** | **Javno prikupljanje sredstava za flywheel** (treći ulažu očekujući prinos) | (kriptoimovina kao instrument prikupljanja → MiCA ponuda javnosti, bijela knjiga) | — | **ECSP** (platforma, HANFA) ili **prospekt/ZTK** (vlastita emisija) ili **AIF/UAIF** (pooling s diskrecijskim upravljanjem) | ❌ **Nikad bez prethodne pravne analize**; najmanje jedna od tri HANFA rute |
| **10** | ITalk izdaje **vlastiti EUR stablecoin** | ✔ MiCA glava IV.: izdavatelj EMT-a mora biti **kreditna institucija ili EMI** + bijela knjiga | ✔ **EMI licenca (HNB)** preduvjet | safeguarding 1:1, redemption at par | ❌ **HNB EMI + MiCA glava IV.** — višegodišnji, kapitalno zahtjevan pothvat |
| **11** | Web/aplikacija daje **personalizirane preporuke** ("za tebe je najbolje da…") ili diskrecijski optimizira tuđe pozicije | ✔ CASP (h) savjetovanje / (i) upravljanje portfeljem | — | pazi na copy landing stranica! | ⚠️ Edukativni/generički sadržaj OK; personalizacija = licenca |

**Zlatno pravilo iz matrice:** postoje točno **tri sigurne zone bez ijedne licence** —
(1) čisti softver s korisnikovim vlastitim Monerium računom i self-custody walletom,
(4) primanje EURe za vlastite usluge, (5) plaćanje vlastitim EURe iz vlastite riznice.
Sve ostalo znači licencu ili ugovor pod tuđom licencom.

---

## F-bis. Trenutno implementirani flow (pay.domovina.ai) — mapiranje na matricu ⚠️ INTERNO

> **Osjetljivo — ne prenositi doslovno na javnu stranicu.** Detalji dolaze iz koda i
> internih dokumenata (`pay.domovina.ai/docs/compliance/INTERNO-monerium-tos-analiza.md`,
> označen "NE OBJAVLJIVATI"). Dodatno: Monerium API ToS §4 traži **pisanu suglasnost
> Moneriuma za javno opisivanje integracije** — prije objave web-stranice o licencama
> koja spominje Monerium flow, provjeriti tu klauzulu.

Provjera koda (01.08.2026.) pokazuje da danas u produkciji radi **scenarij 3
(prolazni / hold-and-forward model)**, a ne scenarij 1:

| Činjenica iz koda | Dokaz | Posljedica |
|---|---|---|
| SEPA uplate trećih idu na **ITalk-ov IBAN** (LHV Estonija), hardkodirano s beneficiary "ITalk d.o.o." | `backend/src/intents/api.ts:30-35`, checkout `page.ts:272` | ITalk dolazi u posjed tuđih novčanih sredstava → otpada PSD2 čl. 3(j) iznimka |
| Monerium odnos ima **samo ITalk (KYB)**; korisnici nemaju Monerium profile | `docs/monerium-private.md:8,19,343`; `docs/plans/gnosis-pay-cards/04-backend-webhooks-iban.md:119-125` | korisnik nije Moneriumov klijent → sredstva se ne mogu tretirati kao "korisnikova kod Moneriuma" |
| EURe se minta na **MPT main-rail Safe (2/3 multisig)** čiji su potpisnici ITalk-ovi ljudi; postoji i backend EOA (`ROUTER_PRIVATE_KEY`) koji **sam** pomiče EURe kroz Zodiac Roles bez korisničkog potpisa | `backend/wrangler.toml`, `safe-tx/README.md:35-52`, `router/safe.ts:131-208` | kontrola nad tuđom vrijednošću → CASP (a) skrb + (j) prijenos za račun klijenata |
| **Webhook pokreće stvarni prijenos** (`order.processed` → `maybeForward` → `EURe.transfer` prema adresi iz SEPA reference) — nije samo notifikacija | `backend/src/index.ts:226-233,518-537` | automatizirani hold-and-forward = money remittance profil (PSD2 Prilog I. t. 6) |
| Ako referenca nema adresu → EURe **ostaju parkirani na ITalk-ovom Safeu** | `index.ts:477-490` | de facto custody tuđe vrijednosti neograničeno dugo |
| Naknada = 0 €, nema konverzije (EURe ostaje EURe 1:1) | grep cijeli backend | **ne mijenja ništa** (vidi A) — besplatnost nije obrana |
| Interna analiza već zaključila: topologija je **radni primjer onoga što Monerium Business ToS §16 zabranjuje** bez odobrenja/statusa distributera; rizik kvalifikacije kao money remittance | `INTERNO-monerium-tos-analiza.md:11-34` | nalaz ovog researcha se poklapa s internim |
| Odluka (11.6.2026.): **cilj = per-user Monerium profili** (mint direktno u korisnikov Safe, ITalk izlazi iz toka novca) = scenarij 1; prijelazno tražiti pisano odobrenje po §16(9) | `INTERNO:99-111` | migracijski put već definiran — ovaj research mu daje regulatornu potvrdu |

**Zaključak F-bis:** korisnikova pretpostavka iz uvodnog pitanja je točna, ali nepotpuna:
za današnji flow ne bi trebala samo **CASP licenca (HANFA — usluge a i j)** nego, zbog
EMT = e-novac = funds, i **PSD2 sloj (HNB — institucija za platni promet, usluga novčane
doznake)**. Obje prijelazne olakšice su istekle (MiCA grandfathering 1.7.2026.; EBA NAL
2.3.2026.). Alternativa licenciranju je migracija na scenarij 1 (per-user Monerium
profili + self-custody mint + korisnik inicira svaki transfer) i/ili formalni status
distributera/partnera kod Moneriuma (scenarij 8), što je interno već postavljeno kao cilj.

---

## G. Uvjeti da scenarij 1 ("bez licence") ostane bez licence — checklist za MPT

1. **KYC/KYB odnos je korisnik ↔ Monerium** (OAuth ili co-branded onboarding;
   [Monerium partner modeli](https://monerium.com/partners/), [docs](https://docs.monerium.com/)).
   ITalk ne smije biti "vlasnik" korisnikovih sredstava ni računa.
2. **SEPA uplate sjedaju isključivo na IBAN samog korisnika** (Monerium izdaje IBAN
   po korisniku). Nikad zbirni/omnibus IBAN ITalka za tuđi novac.
3. **EURe se minta na wallet čije ključeve drži samo korisnik.** ITalk nema ključeve,
   nema recovery, nema multisig udjel koji omogućuje samostalno raspolaganje.
4. **Svaki prijenos inicira korisnik** vlastitim potpisom/consentom u svojoj sesiji.
   Webhook smije *notificirati* i *pripremiti* transakciju, ali ne i *izvršiti* je
   bez korisnikove radnje (inače PIS/CASP-j rizik — scenarij 2).
5. **Nema zamjene iz vlastite pozicije** (ni "gratis"). Swap linkovi vode na
   licencirane treće strane (DEX ≠ automatski sigurno; agregacija s naplatom = RTO rizik).
6. **Copy na webu bez personaliziranih investicijskih preporuka** i bez obećanja prinosa.
7. **Ne primati tuđa sredstva ni privremeno** — ni sekundu na ITalk IBAN-u/walletu.
   "Prolaznost" ne postoji kao pravna obrana (scenarij 3).

---

## H. Otvorena pitanja / što fiksirati prije objave web-stranice

- [x] Potvrđeno iz koda (01.08.2026.): danas je implementiran **scenarij 3** (vidi F-bis).
- [ ] Odluka: migracija na scenarij 1 (per-user Monerium profili — interno već cilj)
      ili licenciranje (CASP kod HANFA-e + PI kod HNB-a) — **prije** javne objave
      transparentne dokumentacije. Javna stranica ne smije opisivati flow koji je
      u koliziji s vlastitim zaključcima.
- [ ] Upit Moneriumu: status "distributera" / partnera + odobrenje po Business ToS
      §16(9) + suglasnost za javno opisivanje integracije (API ToS §4).
- [ ] Pratiti PSD3/PSR — očekuje se ukidanje dvostruke autorizacije (EBA preferira
      ugradnju platnih zahtjeva u MiCA-u); do tada vrijedi dvostruki režim.
- [ ] Disclaimer na stranici: "informativno, nije pravni savjet, stanje na dan X".

---

## I. Svi izvori (poveznice)

**Zakoni i regulatori:**
[NN 85/2024 — Zakon o provedbi MiCA-e](https://narodne-novine.nn.hr/clanci/sluzbeni/2024_07_85_1473.html) ·
[Zakon.hr pročišćeni tekst](https://www.zakon.hr/z/3808/zakon-o-provedbi-uredbe-%28eu%29-2023-1114-o-trzistima-kriptoimovine) ·
[HANFA — donesen zakon](https://www.hanfa.hr/vijesti/donesen-zakon-o-provedbi-uredbe-o-trzistima-kriptoimovine-mica/) ·
[HANFA — smjernice o organizacijskim zahtjevima CASP-a (PDF)](https://www.hanfa.hr/media/dpdb44yc/smjernice-o-organizacijskim-zahtjevima-casp-a.pdf) ·
[HANFA — što je MiCA (PDF)](https://www.hanfa.hr/media/zj2a2rxc/%C5%A1to-je-uredba-mica-3.pdf) ·
[HANFA — katalog odobrenja](https://www.hanfa.hr/licenciranje/odobrenja-za-drustva-iz-nadleznosti-hanfe/) ·
[HANFA — ESMA poziv neovlaštenima](https://hanfa.hr/vijesti/esma-poziva-pruzatelje-usluga-povezanih-s-kriptoimovinom-koji-nemaju-odobrenje-za-rad-na-uredan-prestanak-pruzanja-usluga-uz-istodobnu-zastitu-interesa-klijenata-po-isteku-prijelaznog-razdoblja-u-okviru-mica-e) ·
[HANFA — prvo MiCA odobrenje (Electrocoin)](https://www.hanfa.hr/vijesti/sjednica-upravnog-vijeca-hanfe-electrocoin-doo-prvo-drustvo-koje-je-ishodilo-hanfino-odobrenje-za-rad-u-skladu-s-uredbom-mica/) ·
[HANFA — treće MiCA odobrenje](https://hanfa.hr/vijesti/sjednica-upravnog-vijeca-hanfe-izdano-trece-odobrenje-za-rad-u-skladu-s-uredbom-mica) ·
[HANFA — skupno financiranje](https://www.hanfa.hr/podrucja-nadzora/trziste-kapitala/skupno-financiranje-crowdfunding/) ·
[NN 144/21 — Zakon o provedbi ECSP uredbe](https://narodne-novine.nn.hr/clanci/sluzbeni/2021_12_144_2458.html) ·
[NN 150/22 — ECSP pravilnik](https://narodne-novine.nn.hr/clanci/sluzbeni/2022_12_150_2315.html) ·
[HNB — licenciranje (platni promet)](https://www.hnb.hr/core-functions/payment-system/licensing) ·
[HNB — institucija za e-novac](https://www.hnb.hr/en/-/electronic-money-institution) ·
[HNB — male institucije za e-novac](https://www.hnb.hr/en/core-functions/payment-system/licensing/small-electronic-money-institutions) ·
[HNB — institucije za platni promet](https://www.hnb.hr/en/core-functions/payment-system/licensing/payment-institutions) ·
[HNB — male institucije za platni promet](https://www.hnb.hr/en/core-functions/payment-system/licensing/small-payment-institutions) ·
[Zakon o kreditnim institucijama](https://www.zakon.hr/z/195/zakon-o-kreditnim-institucijama)

**EBA / ESMA / EU:**
[EBA No-Action Letter (press, 10.6.2025.)](https://www.eba.europa.eu/publications-and-media/press-releases/eba-publishes-no-action-letter-interplay-between-payment-services-directive-psd23-and-markets-crypto) ·
[EBA — kraj prijelaznog razdoblja](https://eba.europa.eu/publications-and-media/press-releases/eba-advises-national-authorities-actions-take-end-transition-period-under-its-no-action-letter) ·
[ESMA — MiCA](https://www.esma.europa.eu/esmas-activities/digital-finance-and-innovation/markets-crypto-assets-regulation-mica) ·
[MiCA čl. 3 (tekst)](https://www.mica.wtf/mica/title-i-subject-matter-scope-and-definitions-art.-1-3/article-3) ·
[EC e-money FAQ (distributeri)](https://finance.ec.europa.eu/document/download/3a9f865b-4b16-4fbd-b25c-3c37d24d80ed_en?filename=e-money-faq-22122016_en.pdf) ·
[EBA Q&A 2022_6360 (čl. 3(j))](https://www.eba.europa.eu/single-rule-book-qa/qna/view/publicId/2022_6360)

**Monerium:**
[EURe](https://monerium.com/eure/) · [Partneri](https://monerium.com/partners/) ·
[Docs](https://docs.monerium.com/) · [MiCA blog](https://monerium.com/blog/2025/mica-explained-how-to-choose-a-compliant-euro-stablecoin-in-europe/)

**Sekundarni (odvjetnički) prikazi:**
[Morgan Lewis](https://www.morganlewis.com/pubs/2025/06/e-money-tokens-european-banking-authority-clarifies-psd2-mica-interplay-implications-for-casps) ·
[DLA Piper](https://www.dlapiper.com/en-us/insights/publications/2025/07/interplay-between-mica-and-psd2-for-transfers-of-electronic-money-tokens-eba-no-action-letter) ·
[Hogan Lovells](https://www.hoganlovells.com/en/publications/interplay-between-micar-and-psd2-eba-on-the-end-of-the-no-action-letter-transition-period) ·
[Loyens & Loeff](https://www.loyensloeff.com/insights/news--events/news/psd2-and-micar-overlap-the-transition-period-in-the-ebas-no-action-letter-comes-to-an-end/) ·
[CMS](https://cms.law/en/bel/legal-updates/eba-issues-no-action-letter-on-dual-licensing-of-emt-services-under-mica-and-psd2) ·
[Norton Rose Fulbright](https://www.nortonrosefulbright.com/en/knowledge/publications/2cec201e/regulating-crypto-assets-in-europe-practical-guide-to-mica) ·
[Financije.hr — Electrocoin](https://financije.hr/hanfa-izdala-prvu-mica-licencu-u-hrvatskoj-electrocoin-pod-punim-regulatornim-nadzorom/) ·
[Glas Istre](https://www.glasistre.hr/gospodarstvo/2026/04/09/hanfa-izdala-prvu-kriptolicencu-dobio-ju-je-zagrebacki-electrocoin-1061911)
