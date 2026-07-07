# 14 — EUDI Wallet & eIDAS 2.0 (europski identitetski sloj)

> Knowledge dokument za **Proof of Croatian Personhood** protokol (airKUNA).
> Cilj: razumjeti EU Digital Identity Wallet kao *source-agnostičan* drugi izvor
> atestacije uz Certiliju, i uskladiti dizajn našeg onchain SBT-a s eIDAS 2.0.
>
> Istraženo 2026-07-07 dubinskim istraživanjem (23 izvora, 25 verificiranih tvrdnji,
> jednoglasno 3-0). Vremenski osjetljivo — status ZKP-a i implementacijskih akata
> se aktivno mijenja; provjeri prije oslanjanja. Primarni izvori navedeni na dnu.

---

## TL;DR

**Da — EUDI Wallet je u biti "europska Certilia".** Točnije: to je **standardizirani,
pan-europski interoperabilni sloj IZNAD nacionalnih eID shema, a ne njihova zamjena.**
Hrvatska (preko AKD/Certilia) i dalje izdaje temeljni digitalni identitet; građanin se
u wallet onboarda svojim nacionalnim eID-om; svaka članica mora ponuditi barem jedan
wallet; i zajamčeno je **prekogranično uzajamno priznavanje** (Hrvat se može verificirati
kod njemačkog relying partyja i obrnuto).

Za nas presudno: wallet vraća **pseudonim jedinstven po relying-partyju** (ne globalni
identifikator), gradi se na **selective disclosure + anti-linkability**, a **ZKP je
predviđen ali još nije odabran/isporučen**. To je gotovo idealno poravnanje s našim
nullifier + zk-glasanje dizajnom.

---

## 1. Što je EUDI Wallet i odnos prema Certiliji

- eIDAS 2.0 = **Regulation (EU) 2024/1183**, usvojena 11.4.2024., objavljena u Službenom
  listu 30.4.2024., **stupila na snagu 20.5.2024.**, mijenja Reg. (EU) 910/2014. Uvodi
  **pravo na digitalni identitet pod isključivom kontrolom korisnika** (Recital 9).
- **Wallet gradi NA nacionalnim eID shemama, ne zamjenjuje ih.** EC doslovno: *"digital
  identities will continue to be provided by Member States"* i wallet *"builds on this
  basis... ensuring mutual recognition of national wallets"*. Onboarding koristi
  nacionalni eID na razini LoA **substantial → nadopunjeno na high**.
- **Prekogranično uzajamno priznavanje** je zajamčeno harmoniziranim sigurnosnim pristupom.
- **Zaključak za nas:** Certilia (AKD) postaje *jedan od izvora* PID-a (Person
  Identification Data) unutar EUDI ekosustava. Naš protokol treba biti **source-agnostičan**:
  Certilia OIDC danas, EUDI Wallet (SD-JWT VC / mDoc) sutra — isti nullifier-orakl dizajn.

## 2. Timeline i obavezni rokovi

Dvije tvrde prekretnice (izvedene iz stupanja na snagu implementacijskih akata ~24.12.2024.):

| Rok | Obaveza | Osnova |
|---|---|---|
| **~kraj 2026.** (24 mj) | Svaka članica mora ponuditi **barem jedan wallet** svim građanima/rezidentima/tvrtkama | Art. 5a(1) |
| **~kraj 2027.** (36 mj) | **Privatni relying partyji** u sektorima jake autentikacije (banke, financije, transport, zdravstvo, telekom, energetika, socijalno, obrazovanje, digitalna infrastruktura...) **moraju prihvaćati wallet** — na *dobrovoljni zahtjev korisnika* | Art. 5f(2) |

- Mikro/mala poduzeća izuzeta od obaveze prihvaćanja.
- Komisija je do travnja 2026. usvojila **30+ implementacijskih akata** (prvi krug na snazi
  ~24.12.2024.; drugi krug od 4 uredbe objavljen u OJ **7.5.2025.**). Pokrivaju integritet
  walleta, protokole/sučelja, PID i atestacije, trust framework, **registraciju relying
  partyja** (CIR 2025/848), certifikaciju, prekogranično usklađivanje identiteta.
- Napomena: Komisija komunicira "2026", ali puni rollout faza se proteže u 2027.

## 3. ARF — tehnički standardi (Architecture Reference Framework)

Kanonski izvor: **GitHub `eu-digital-identity-wallet/eudi-doc-architecture-and-reference-framework`**
(trenutno ~v2.9.0). ARF **mandira dva formata atestacije**:

- **ISO/IEC 18013-5 mdoc** (prošireno ISO/IEC 23220-2 za opće atestacije) — isti standard
  kao mobilna vozačka (mDL).
- **IETF SD-JWT VC** (Selectively Disclosable JWT Verifiable Credential), uz **HAIP** profil.

Protokoli/sučelja:
- **Izdavanje:** OpenID4VCI (PID Issuance + Attestation Issuance Interface).
- **Udaljena prezentacija:** OpenID4VP.
- **Proximity/offline:** ISO/IEC 18013-5 device-retrieval.
- W3C VCDM 2.0 se pojavljuje u usporednim tablicama ali **nije** mandirani wallet format.

Oba formata podržavaju **selective disclosure**. Ovo su isti gradivni blokovi (OIDC obitelj)
koje već koristimo s Certilijom → integracija je evolucija, ne rewrite.

## 4. Privatnost: selective disclosure, unlinkability, ZKP

- **Selective disclosure** je *obavezujuća* operativna značajka (data minimisation) — korisnik
  otkriva samo tražene atribute (npr. "stariji od 18" bez datuma rođenja).
- **Anti-linkability:** mjere protiv praćenja od strane relying partyja, PID providera i
  atestacijskih providera; **re-izdavanje** atestacija koristi se za ograničavanje povezivosti.
- **ZKP status (KLJUČNO, vremenski osjetljivo):** **nijedna ZKP shema još nije odabrana.**
  ARF doslovno: *"No specific ZKP has been selected to be supported by components"*, a podrška
  se *"expected to be introduced following the launch of the EUDI Wallet"*. Rad teče pod
  **Discussion Topic G** (Discussion #408; natječu se BBS+/BBS# vs zk-SNARK), 9 zahtjeva
  (ZKP_01–ZKP_09) predviđeno za Annex 2, follow-on **TS13** (siječanj 2026.). Zahtjev
  **ZKP_06**: ZKP bi trebao generirati dokaze nad **već izdanim** mdoc/SD-JWT VC atestacijama
  (backward-compatible dizajn).
- ETSI TR 119 476: mdoc i SD-JWT (hash-salted atributi) *već zadovoljavaju* regulatorne
  zahtjeve selective disclosure/unlinkability — **ZKP strogo gledano nije nužan** da se
  zadovolji regulativa (ali daje jaču nepovezljivost).
- Recital 14: članice *"should integrate"* privacy-preserving tehnologije *"such as zero
  knowledge proof"* — **neobvezujući** jezik recitala (za razliku od obavezujućeg selective
  disclosure).

**Za nas:** ne oslanjaj se na EUDI-native ZKP kratkoročno. Naš MACI/Semaphore zk-glasanje
sloj (ADR 0006) ostaje *naša* odgovornost; EUDI daje verificirani PID kao ulaz, mi radimo
onchain nullifier + zk iznad toga.

## 5. Integracija relying partyja / dApp-a — koji identifikator dobivamo?

- **Registracija obavezna:** relying party se mora upisati u **nacionalni registar**
  (CIR 2025/848), deklarirati namjenu i **točno koje atribute traži**; dobiva **Relying
  Party Access Certificate (RPAC)** i **Registration Certificate (RPRC)**. Tj. nije
  permissionless — RP je poznat i ograničen na deklarirane atribute.
- **Identifikator koji se vraća:** **pseudonim jedinstven PO relying-partyju**, generiran
  lokalno u walletu; **NE globalni jedinstveni subject ID.** Tehnička osnova = **W3C WebAuthn**
  po CIR 2024/2979 (per-RP jedinstveni ključevi/passkeys), s prekograničnom nepovezljivošću.
  Po Art. 5f RP ne smije odbiti pseudonim gdje zakon ne traži identifikaciju.
- **Caveat:** otvoreni ARF issue #572 tvrdi da WebAuthn pseudonimi možda ne jamče *potpunu*
  nepovezljivost.
- **Implikacija za "jedan čovjek = jedan SBT":** per-RP pseudonim znači da *sam wallet* neće
  dati stabilan globalni identifikator preko RP-ova. Naš Sybil-primitiv mora ostati
  **nullifier izveden iz stabilnog atributa PID-a (OIB)** unutar našeg registriranog RP
  konteksta — točno kao s Certilijom danas. EUDI ne rješava Sybil sam po sebi; on je
  *verificirani izvor*, a jedinstvenost i dalje enforcamo mi na razini nullifiera.

**Open-source reference implementacije** (GitHub org `eu-digital-identity-wallet`, službeni
EC repo):
- `eudi-srv-verifier-endpoint` — **verifier/RP backend (OpenID4VP)** — točno ono što bismo
  gradili za našu stranu.
- `eudi-lib-*` biblioteke (npr. `eudi-lib-jvm-openid4vci-kt` Kotlin) — korisno za Android
  verifier node (ADR 0004).
- PID/mDL issuer, wallet provider, verifier endpoints kao reference.

## 6. Hrvatska: status (djelomično — vidi caveat)

- **Certilia (izgradio AKD)** već podržava eID onboarding i eIDAS je notificirana shema;
  prirodni kandidat da postane hrvatski EUDI wallet / PID provider.
- Nacionalni projekt: **eid.hr / DTC** (Digital Travel Credential / mobilni identitet).
- Hrvatski čelnik digitalizacije javno je izražavao zabrinutost oko **certifikacije** EUDI
  walleta (Biometric Update, listopad 2025.) — signal da rollout ima otvorena pitanja.
- **Caveat:** dubinsko istraživanje NIJE čvrsto verificiralo detalje uloge AKD/FINA/Certilia
  u konkretnim large-scale pilotima (**POTENTIAL, EWC, NOBID, DC4EU**) — ovo treba zasebno
  istražiti prije oslanjanja. (POTENTIAL je najveći pilot i Hrvatska vjerojatno sudjeluje,
  ali to ovdje NIJE potvrđeno primarnim izvorom.)

## 7. Strateške / financijske implikacije za airKUNA

- **Poravnanje priče:** "otvoreni, samosuvereni onchain sloj IZNAD obaveznog EU eID-a" je
  jaka, fundabilna naracija baš dok EU gura EUDI 2024–2027.
- **Ne kladi se samo na današnji Certilia OIDC** — dizajniraj source-agnostičan attestation
  sloj (Certilia → EUDI SD-JWT VC/mDoc). To je i tehnički bolje i bolji pitch za grantove.
- **GDPR prednost:** naš "nullifier-only, sirovi OIB nikad ne napušta backend" dizajn se
  poklapa s eIDAS načelima data minimisation / selective disclosure — istaknuti u svakom
  pitchu i prema regulatoru.
- **Regulatorni oprez:** RP registracija (CIR 2025/848) znači da ćemo, kad koristimo pravi
  EUDI wallet, morati biti registriran RP s deklariranim atributima. Naš onchain sloj mora
  jasno stajati kao *ne-custodial software* (usklađeno s postojećom compliance tezom ITalka).

---

## Sažetak poravnanja s našim dizajnom

| Naš element | EUDI ekvivalent / status | Implikacija |
|---|---|---|
| Certilia OIDC izvor | EUDI PID provider (nacionalni eID iznad) | Certilia = prvi izvor, EUDI = drugi; isti orakl |
| `nullifier = HMAC(OIB)` | EUDI daje per-RP pseudonim, NE globalni ID | Sybil-jedinstvenost ostaje NAŠA odgovornost |
| EIP-712 attestation orakl | OpenID4VP verifier (`eudi-srv-verifier-endpoint`) | Reference implementacija postoji |
| zk-glasanje (MACI, ADR 0006) | EUDI ZKP još neodabran (Topic G/TS13) | Radimo sami; EUDI daje verificiran ulaz |
| Selective disclosure | Obavezujuće u ARF-u | Prirodno poravnanje, marketinška prednost |
| Android verifier node (ADR 0004) | `eudi-lib-*` (npr. Kotlin OpenID4VCI) | Iskoristivo za node |

## Primarni izvori

- eIDAS 2.0 tekst: https://eur-lex.europa.eu/eli/reg/2024/1183/oj/eng
- EC EUDI regulativa: https://digital-strategy.ec.europa.eu/en/policies/eudi-regulation
- EC digital-building-blocks (wallet): https://ec.europa.eu/digital-building-blocks/sites/spaces/EUDIGITALIDENTITYWALLET/
- ARF repo: https://github.com/eu-digital-identity-wallet/eudi-doc-architecture-and-reference-framework
- ARF (renderano): https://eu-digital-identity-wallet.github.io/eudi-doc-architecture-and-reference-framework/
- GitHub org (sve reference impl.): https://github.com/eu-digital-identity-wallet
- Verifier endpoint (RP backend): https://github.com/eu-digital-identity-wallet/eudi-srv-verifier-endpoint
- ZKP Topic G: https://github.com/eu-digital-identity-wallet/eudi-doc-architecture-and-reference-framework/discussions/408
- ETSI TR 119 476 (selective disclosure/ZKP analiza): https://www.etsi.org/deliver/etsi_tr/119400_119499/119476/01.01.01_60/tr_119476v010101p.pdf
- Council press (usvajanje): https://www.consilium.europa.eu/en/press/press-releases/2024/03/26/
- Hrvatska DTC/eID: https://www.eid.hr/en
- Hrvatska zabrinutost oko certifikacije: https://www.biometricupdate.com/202510/croatian-digitalization-head-shares-concerns-about-eudi-wallet-certification
