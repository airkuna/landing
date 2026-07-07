# Proof of Croatian Personhood — Whitepaper (v0.2, nacrt)

> **Otvoreni protokol za onchain dokaz osobnosti ukorijenjen u hrvatskom/EU eID-u.**
> Projekt: airKUNA (ITalk d.o.o.). Chain: Gnosis. Licenca (namjera): open-source (Apache-2.0 / MIT).
> Status: **NACRT v0.2** (2026-07-07). Dorađeno nakon dva kruga prior-art istraživanja
> (vidi `docs/15-prior-art-i-patentabilnost.md`).
>
> Ovo je *whitepaper* (cjelina + motivacija + mehanizam, za community/grantove). Ključne
> odluke izvedene su kao zasebni **ADR-ovi** u `docs/decisions/` (airKUNA vlastita ADR baza).
>
> **Što je novo u v0.2 (iz istraživanja):** (1) potvrđeno da je "živi eID-OIDC → onchain SBT
> preko decentralizirane mreže" genuino prazan prostor; (2) nullifier-registar+zk = dokazani
> standard (World ID) — mesh nije nužan za personhood; (3) **Acurast** kao mogući substrat za
> mrežu umjesto gradnje od nule; (4) caveat: Android Key Attestation korijeni u Googleu →
> "trust-minimized, ne trustless"; (5) konkretni patentni/FTO rizici (nChain) i grant iznosi.

---

## 0. Sažetak (Abstract)

**Problem:** Hrvati imaju vrhunski digitalni identitet — **Certilia MobileID** (AKD, preko MUP-a,
eIDAS **razina High**) — ali je centraliziran. Onchain svijet nema pouzdan, Sybil-otporan dokaz
"ovo je jedinstvena stvarna osoba", što blokira legitimno **onchain glasanje**, demokratsko
upravljanje i pravedno raspoređivanje resursa.

**Rješenje:** Otvoreni protokol koji verificiranu eID prijavu pretvara u **soulbound token (SBT)
osobnosti** na Gnosisu. Jedinstvenost se ne veže za novčanik nego za **nullifier izveden iz OIB-a**
(`nullifier = HMAC-SHA256(OIB, pepper)`), pa jedna osoba može imati **više Safe novčanika, ali samo
jedan identitet**. Sirovi OIB nikad ne napušta backend (GDPR-first). Dizajn je **source-agnostičan**:
Certilia danas, **EU EUDI Wallet** sutra — isti onchain sloj radi za svih 27 zemalja EU.

**Ključni uvid (iz prior-art analize):** za MVP **ne treba** skupa hardverska infrastruktura ni
vlastita mreža potpisnika. Sybil-otpornost se postiže **klijentskim dokazom** (zkTLS nad Certilia
OIDC-om, ili NFC čitanje eOI čipa) + onchain nullifier registrom. **Decentralizirana Android
verifier mreža je Faza 2** — poboljšava *decentralizaciju povjerenja*, nije preduvjet za rad.

---

## 1. Problem

1. **Centralizirano povjerenje.** Certilia/AKD je jedina točka istine. Za onchain demokraciju
   trebamo dokaz osobnosti koji ne ovisi o jednom entitetu koji sve može sam kovati.
2. **Sybil napadi.** Bez dokaza osobnosti, jedna osoba otvori 1000 novčanika i preglasa poštene.
3. **Vezanost za novčanik.** Naivni "KYC po novčaniku" ne radi: ljudi imaju više novčanika (hladni,
   topli, Safe za udrugu, Safe za tvrtku), a identitet mora biti *iznad* njih.
4. **Privatnost & GDPR.** OIB je osjetljiv PII. Ne smije završiti onchain ni u plaintext bazi.
5. **Nasljeđe/oporavak.** Izgubljeni novčanik ne smije značiti izgubljeni identitet.

## 2. Temeljni primitiv: nullifier, ne novčanik

```
nullifier = HMAC-SHA256(OIB, TAJNI_PEPPER)
```

- **Deterministički** (isti OIB → uvijek isti nullifier) i **nepovratan** (HMAC jednosmjeran, pepper tajan).
- **Jedinstvenost na razini osobe, ne novčanika.** 100 Safeova iste osobe → isti OIB → isti nullifier
  → ugovor odbija drugi mint. **Ovo je Sybil-otpornost.**
- Već dokazano u produkciji: `domovina-api` radi `oib_hash = HMAC-SHA256(oib, key)` s `unique`
  ograničenjem → jedan OIB = jedan račun.

## 3. Onchain arhitektura

Tri open-source ugovora na Gnosisu:

### 3.1 `IdentityRegistry`
```solidity
mapping(bytes32 nullifier => Identity) registry;
struct Identity { address anchor; uint64 loa; uint64 verifiedAt; uint64 reverifiedAt; }

function claim(Attestation calldata a, bytes calldata proof) external {
    require(registry[a.nullifier].anchor == address(0), "one person, one identity");
    require(_verify(a, proof), "invalid attestation");        // vidi 4. — pluggable verifier
    registry[a.nullifier] = Identity(a.anchor, a.loa, _now(), _now());
    sbt.mint(a.anchor, a.nullifier);
}
```

### 3.2 `PersonhoodSBT` (EIP-5484)
Non-transferable bedž vezan uz *anchor* Safe. Nosi LoA i vremenske oznake; čita se iz glasačkih ugovora.

### 3.3 Razrješavanje više novčanika
- SBT živi u **jednom anchor Safeu**.
- Ostali novčanici se razrješavaju u nullifier: (a) potpisom iz anchor Safea (ERC-1271 `LinkedWallets`),
  ili (b) **zk članstvom** (glasaju bez otkrivanja koji su — vidi §6).
- **Oporavak = eID.** Izgubiš anchor? Ponovni Certilia login → isti nullifier → `migrateAnchor()` na novi
  Safe. Tvoj eID je tvoj recovery.

## 4. Most eID → onchain (pluggable verifier) — i zašto mesh nije MVP

`_verify()` je **apstrakcija s više implementacija**, biramo po fazi:

| Verifier | Kako | Decentralizacija | Faza |
|---|---|---|---|
| **A. zkTLS nad Certilia OIDC** | Klijent dokaže (Reclaim/zkTLS) da je Certilia JWKS potpisao id_token s njegovim OIB-om; ugovor verificira zk proof | Nema oraklske mreže; oslanja se na Certilia PKI | **MVP** |
| **B. NFC eOI (eOsobna) čip** | Klijent pasivno autenticira potpis izdavača čipa (tip Rarimo/zkPassport), izvede nullifier lokalno | Nema oraklske mreže; oslanja se na državnu PKI | **MVP alt.** |
| **C. EIP-712 attestation orakl** | Off-chain verifier validira id_token (JWKS/iss/aud), potpiše `{nullifier,anchor,loa}`; ugovor provjeri potpisnika | Jedan potpisnik = centralno | Prijelazno |
| **D. M-of-N Android verifier mesh** | Kao C, ali M nezavisnih Android nodeova (StrongBox + Key Attestation) supotpisuje | **Visoka** — nitko sam ne kuje | **Faza 2** |

**Ključni uvid iz prior-arta (potvrđeno u 2 kruga):** verifieri A i B daju Sybil-otpornost **bez ikakve
mreže potpisnika**, jer se dokument/sesija *sama kriptografski dokazuje*. Dodatna potvrda: **World ID**
radi personhood samo s nullifier-registrom + Semaphore zk, bez ikakvog signer-mesha — to je dokazani
industrijski standard. Mesh (D) opravdavaju samo: (1) živi-OIDC root koji se ne može klijentski dokazati,
i (2) politička priča "ni AKD ni ITalk ne mogu sami kovati". Zato: **gradi A/B za MVP; mesh je Faza 2,
ne preduvjet.**

**Ako ipak gradiš mesh (Faza 2): razmotri Acurast kao SUBSTRAT, ne gradi od nule.** Verificirano: Acurast
procesori (250k+ telefona) imaju vlastitu EVM adresu, code-bound hardverski ključ, hardversku atestaciju,
general-purpose runtime i mogu potpisati/settlati onchain. M-of-N Safe co-signing je custom logika *na*
Acurastu (nema je out-of-the-box). To pretvara "kupi i pokreni telefone" u "deploy custom verifier na
postojeću mrežu".

**⚠️ Caveat za sve HW-atestacijske pristupe:** Android Key Attestation lanac korijeni u **Googleu**
(Google potpisuje attestation ključ). Dakle mesh na Android atestaciji je **trust-minimized, ne trustless**
— Google je root of trust. Pošteno to reci; mitigacija = miješanje vendora (Samsung Knox + Titan +
Qualcomm) da nijedan proizvođač nije jedina točka.

## 5. Verifier mreža (Faza 2): geolokalizirani Android signer-mesh

*Dizajn zadržan jer daje jaku decentralizaciju povjerenja; nije MVP.*

- **Signer-only, bez execution layera.** Telefoni se spajaju **read-only na Gnosis RPC**; ne drže
  chain state → nema skupog hardvera/SSD-a. Uloga = **offline M-of-N supotpisnici Safe multisiga**.
- **Izvršenje.** Relayer plaća gas i submitta pre-potpisani `execTransaction`, **ili** svaki telefon
  drži malo xDAI-a pa je "zadnji potpisnik u krugu" nezavisni executor. Relayer nikad nije vlasnik →
  ne može krivotvoriti (potpis se veže na to/value/data/nonce).
- **Hardverski korijen.** StrongBox/TEE ključ + **Android Key Attestation** (certifikatski lanac dokazuje
  da ključ nikad nije napustio certificirani secure element) — *ovo* je prava vrijednost telefona.
- **DAO upravljanje.** airKUNA DAO (Safe multisig) odobrava nove nodeove; **statusi**: `pending →
  active → offline → ejected`. **Poznat ljudski operater po nodeu.**
- **Geolokacija & anti-spoof.** Nodeovi se prikazuju **na karti** (`karta-web`, MapLibre — integracija
  je par sati: novi layer sa status→boja markerima). GPS lažiranje se kažnjava **staking/slashing**
  ekonomijom (tip GEODNET/XYO proof-of-location).
- **Prior-art oprez:** ovaj sloj je *nova kombinacija poznatih dijelova* (Acurast = telefoni+TEE;
  Lit = attested potpisna mreža; GEODNET = geo anti-spoof). Razmotriti **Acurast kao substrat** umjesto
  gradnje mreže od nule.

## 6. Privatnost i glasanje

- **Transparentno glasanje** (udruge, javni identiteti): obični SBT + nullifier dovoljni.
- **Anonimno glasanje**: **MACI / Semaphore** — zk dokaz članstva u skupu verificiranih građana + per-poll
  nullifier `H(secret, pollId)` sprječava dvostruko glasanje **bez povezivanja novčanika**; MACI dodaje
  **receipt-freeness** (otpornost na kupovinu glasova). Chain nikad ne nauči "ovaj Safe = taj građanin".

## 7. GDPR / compliance

- **Sirovi OIB nikad onchain ni u plaintext bazi.** Onchain ide samo `nullifier` (nepovratan).
- Ako backend privremeno vidi OIB (verifier C/D), odmah ga hashira i odbaci; šifriranje at-rest (pgcrypto).
- Poklapa se s eIDAS načelima **data minimisation / selective disclosure** → prednost pred regulatorom i
  u grant prijavama.
- ITalk = **non-custodial software provider** (usklađeno s postojećom compliance tezom); regulirane
  funkcije (eID izdavanje, KYC) rade licencirani (AKD/Certilia, kasnije EUDI).

## 8. Pozicioniranje vs prior-art (zašto ovo ipak vrijedi)

Puni stack ne postoji kao jedan proizvod, ali komponente imaju jak prior-art (Acurast, Lit, Rarimo/
zkPassport, GEODNET, Reclaim/zkTLS, EBSI). **Potvrđeno u istraživanju: "živi eID-OIDC → onchain SBT
preko decentralizirane verifier mreže" je genuino nezauzet prostor** (Anima=biometrija+centralizirano,
interID=SSI SaaS bez onchaina, Privado=zk-VC framework). **Naša diferencijacija nije patent nego:**
- **Certilia/EUDI (hrvatski/EU eID) root** — ne putovnica, ne biometrija; eIDAS High LoA. **Ovo je jezgra novosti.**
- **Gnosis-native composable personhood SBT** — javni chain, DeFi/DAO-composable (za razliku od permissioned EBSI).
- **Nullifier-registar + zk = ista obitelj kao World ID** (dokazan pattern); razlika je izvor, ne mehanizam.
- **First-mover u Hrvatskoj** + integracija s postojećim airKUNA/domovina stackom (pay/sms/karta).
- **Kanonska open implementacija + mreža + brand** = jači moat od patenta (detalji: `docs/15-prior-art-i-patentabilnost.md`).

**Patent / Freedom-to-Operate (konkretno):** ⚠️ **nChain US 11,347,838 B2** pokriva "identity tokeni
→ fiksni skup glasača → brojanje onchain signala → otpuštanje sredstava na prag" = izravno preklapa
personhood-za-glasanje; nChain je parničarski agresivan → treba FTO mišljenje prije komercijalizacije.
Dobra vijest: izbor **M zasebnih EIP-712 potpisnika (ne pravi threshold ECDSA/MPC)** ruta *oko* nChain
threshold-ECDSA patenata (11,348,095 / 12,003,616). Patentiranje samo defenzivno, uz zastupnika.

## 9. Open-source & financiranje

- **Open-source** ugovori + verifier node + dokumentacija; ITalk vodi razvoj koji svi koriste.
- **Financiranje (konkretno, iz istraživanja):**
  - **EU NGI Pilots (cascade) — realan prvi ulaz:** ≥15% se prosljeđuje trećima preko open callova, **kapa
    ~€60.000 po primatelju, BEZ konzorcija.** Provjeri aktualni WP (identity/blockchain fokus varira po callu).
  - **Digital Europe** `DIGITAL-2025-...-WALLET` (~€129,6M) / `...-MDL` (~€77M) za EUDI — veći novac, ali
    preko **konzorcija** i LSP-ova (POTENTIAL/EWC/NOBID/DC4EU); prati 2026-2027 Work Programme callove.
  - **Crypto-native dopuna:** Gnosis/GnosisDAO ecosystem grants, Optimism RetroPGF / Octant / Gitcoin.

## 10. Roadmap

| Faza | Isporuka |
|---|---|
| **0 — MVP** | `IdentityRegistry` + `PersonhoodSBT` + **verifier A (zkTLS/Certilia)** ili **B (NFC eOI)**; mock issuer/verifier lokalno |
| **1** | Drugi neovisni izvor (phone-SBT preko `sms.domovina.ai` reverse-OTP) + credibility score; karta nodeova |
| **2** | **M-of-N Android verifier mesh** (M zasebnih EIP-712 potpisnika, ne MPC) + DAO onboarding + statusi + slashing |
| **3** | Socijalna atestacija (web-of-trust score) |
| **4** | zk anonimno glasanje (MACI/Semaphore) |
| **5** | EUDI Wallet izvor (SD-JWT VC/mDoc preko OpenID4VP) — pan-EU |

## 11. Otvorena pitanja / rizici

- **Nužnost mesha** — istraživanje jako sugerira da A/B daju ~90% vrijednosti bez mesha; dokazati na MVP-u prije gradnje D.
- **zkTLS zrelost** za Certilia OIDC endpoint (custom flow preko `certilia.domovina.ai` proxyja).
- **Pepper governance** — tko drži `pepper`? (Ako curi, nullifieri se mogu brute-force korelirati s OIB-om
  jer je prostor OIB-ova malen ~10^11 → pepper mora biti u threshold/HSM custody, ili per-epoch rotacija.) → ADR 0003.
- **Google root-of-trust** — Android Key Attestation korijeni u Googleu → mesh je trust-minimized, ne trustless;
  mitigacija miješanjem vendora. Priznati u svakom pitchu.
- **eOI kao NFC** — podržava li hrvatska eOsobna pasivnu autentikaciju čipa kao putovnica? (Provjeriti.)
- **Anti-spoof ekonomija** za mesh — dizajn stakinga/slashinga (Faza 2); razmotri Acurast substrat.
- **FTO rizik (nChain US 11,347,838 B2)** — glasačko-identitetski patent; FTO mišljenje prije komercijalizacije.
- **Patent vs open-source napetost** — ako patent, samo defenzivno, uz zastupnika.

---

### Dodatak: ADR baza
airKUNA ima **vlastitu ADR bazu** (`docs/decisions/`, kreće od 0001) — čist, aktualan skup bez
zastarjelih odluka. Origin ADR-ovi u `pay.domovina.ai/docs/decisions/` (0003 PhoneSBT, 0004 mesh,
0005 Certilia, 0006 zkProof) ostaju kao povijesni zapis; airKUNA ADR-ovi ih referenciraju (`Informed-by`)
i gdje mijenjaju odluku, supersede-aju (`Superseded-by`).

airKUNA ADR-ovi (v1):
- **0001** — nullifier-registar vs per-wallet SBT (jedinstvenost na razini osobe).
- **0002** — pluggable verifier (A zkTLS / B NFC eOI / C EIP-712 orakl / D Android mesh); MVP = A/B, mesh = Faza 2.
- **0003** — pepper custody (threshold/HSM, rotacija).
