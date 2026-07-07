# 15 — Prior-art i patentabilnost (Android verifier mesh + onchain personhood)

> Analiza: postoji li već ovakvo rješenje i je li patentabilno u Europi.
> Istraženo 2026-07-07 (6 ciljanih web-pretraga + domensko znanje; puni
> adversarijalni deep-research workflow pao je na session limitu — vrijedi ga
> ponoviti nakon reseta za rigorozan patentni zapis). **Nije pravni savjet.**

## Koncept koji provjeravamo

Mreža consumer **Android telefona kao SIGNER-ONLY mesh** (bez execution layera;
read-only na Gnosis RPC; hardverski ključ StrongBox/TEE + Key Attestation),
**offline supotpisnici Safe multisiga** (M-of-N), gdje relayer plaća gas ili zadnji
potpisnik u krugu ima xDAI i sam izvrši tx. Svrha: **decentralizirani attestation
orakl** koji most eID (Certilia/EUDI) → **onchain soulbound personhood** (Sybil-otporno
glasanje). Plus: **geolokalizirani nodeovi na karti**, anti-GPS-spoof preko stakinga/
slashinga, DAO (Safe multisig) onboarding s statusima (active/offline/pending/ejected).

## Verdikt u jednoj rečenici

**Točan puni stack kao jedan proizvod ne postoji** — ali **svaka pojedina komponenta
ima jak, dobro financiran prior-art.** Ovo je "nova kombinacija poznatih dijelova", ne
"nitko se nije sjetio". Za patente je to najteža kategorija; za proizvod je i dalje
vrijedno i diferencirano.

## Najbliži susjedi po komponenti

| Komponenta tvog dizajna | Najbliži postojeći projekt | Preklapanje | Razlika (tvoja diferencijacija) |
|---|---|---|---|
| Consumer telefoni kao HW-attested nodeovi | **Acurast** (250k+ telefona, TEE, dokazuje da kod radi na genuine HW; $11M, XI.2025.) | Vrlo visoko na *substratu* | Acurast = general compute marketplace, NIJE identity/personhood, nije Safe co-signing, nije geo-na-karti. **Mogao bi ti biti substrat, ne konkurent.** |
| Decentralizirana HW-attested potpisna mreža | **Lit Protocol** (MPC TSS + TEE, "svaki potpis je hardverski atestiran zapis", upgradi whitelistani multisigom na Baseu) | Vrlo visoko na *potpisivanju* | Lit koristi cloud TEE (SGX/SEV), ne consumer Android StrongBox; nije geo; nije personhood. Konceptualno već postoji "decentralizirana attested potpisna mreža". |
| Per-user MPC s device-share na mobitelu | **Web3Auth** (2-of-3, device share + biometrija) | Srednje | To je upravljanje ključem po korisniku, ne dijeljena validatorska mreža. |
| eID/dokument → onchain nullifier SBT | **Rarimo / zkPassport** (NFC putovnica 130+ zemalja, verify izdavačev potpis, ZK proof, per-scope stabilan nullifier, onchain EVM, Proof-of-Citizenship) | **Vrlo visoko na identitetskoj polovici** | Rarimo se rootira u **NFC čipu putovnice koji se sam kriptografski dokazuje** (ICAO PKI) → **ne treba orakl mrežu**. Ti hoćeš *live Certilia OIDC* root. ⚠️ Vidi "Ključni izazov". |
| Biometrijski personhood | **World ID** (iris orb, nullifier, SBT-like) | Srednje | Drugi root (biometrija, ne eID). |
| Geolokalizirani nodeovi + anti-spoof staking | **GEODNET** (20k+ nodeova/153 zemlje, PoS+BLS+Proof-of-Location+Proof-of-Accuracy, eksplicitno protiv GPS spoofa), **XYO** (wallet potpisuje proof-of-location, staking), **FOAM** | **Visoko** | "Geo DePIN sa anti-spoof stakingom" je **zrela, čak prenapučena kategorija**. Geolokacija potpisnika NIJE novost sama po sebi. |
| Web2/OIDC login → onchain | **Reclaim / zkTLS / TLSNotary**, Chainlink Functions/DECO | Visoko na *bridgeu* | zkTLS može dokazati Certilia OIDC claim onchain **bez potpisne mreže** — vidi "Ključni izazov". |
| EU eID/VC onchain | **EBSI** (EU permissioned chain; DID/Trusted Issuers/Schemas registri kao smart ugovori; integrira EUDI) | Srednje | EBSI je *permissioned*, nije public-chain, nije DeFi-composable SBT, nije Gnosis. Tvoj public composable personhood SBT je diferenciran. |

## ⚠️ Ključni izazov (najvrjedniji nalaz)

Najjači prior-art (**Rarimo/zkPassport** + **zkTLS/Reclaim**) sugerira da za *core*
personhood funkciju **možda uopće ne trebaš Android signer mesh.** Dokument ili OIDC
sesija se mogu **sami kriptografski dokazati** (putovnica: ICAO potpis; Certilia:
zkTLS nad id_tokenom), pa nullifier izvedeš klijentski bez oraklske mreže.

Mesh se opravdava tek u dva scenarija:
1. **Živi Certilia OIDC root** (ne NFC putovnica): OIDC verifikacija traži server-side
   provjeru JWKS/aud → treba *netko* atestirati taj rezultat onchain. Tu mesh ima smisla.
2. **Politička/decentralizacijska priča**: "nijedan pojedinačni entitet (ni AKD, ni ITalk)
   ne može sam kovati identitete". To je legitimna vrijednost, ali je *narativna/upravljačka*,
   ne nužno *tehnički nužna*.

**Preporuka:** ne gradi skupi mesh prije nego dokažeš da zkTLS-nad-Certilijom ili
NFC-eOI pristup ne daje 90% vrijednosti jeftinije. Mesh je Faza 2+, ne MVP.

## Europska patentabilnost (EPO) — kratko

- **Dvije prepreke.** (1) *Eligibility* (čl. 52 EPC): softver "kao takav" i poslovne
  metode su isključeni; lako se preskoči uključivanjem tehničkih (računalnih) značajki.
  (2) *Novost + inventivni korak* — ovdje je teško.
- **Dobra vijest:** kriptografija, integritet/sigurnost podataka, HW atestacija i
  konkretni tehnički protokoli **jesu tehnički po prirodi** → tehnički karakter se može
  zadovoljiti. Konkretan anti-spoof mehanizam ili specifičan attestation-gated threshold
  protokol mogli bi proći prvu prepreku.
- **Loša vijest:** *poslovni/administrativni* aspekti (jedan-čovjek-jedan-glas, DAO
  onboarding, KYC) su **ne-tehnički** i NE broje se u inventivni korak. A s obzirom na
  gornji prior-art (Acurast + Lit + Rarimo + GEODNET + zkTLS), ispitivač bi kombinaciju
  lako proglasio očitom agregacijom osim ako ne pokažeš **ne-očitu tehničku sinergiju**.
- **Strateška napetost:** "100% open source javno dobro" + "EU grantovi za javno dobro"
  vs. **patent** su u sukobu. Patent košta (desetci tisuća €, godine), a slabo brani
  ovakav projekt. **Jači moat = biti kanonska open implementacija + mreža + brand +
  hrvatski first-mover + Certilia integracija**, ne patent. Ako patent, onda *defenzivni*
  (spriječiti da te netko drugi zaključa), uz open licencu.
- **Nije pravni savjet** — za ozbiljnu procjenu treba europski patentni zastupnik i
  formalni novelty search (EPO/Espacenet).

## Zaključak i preporuka

1. **Nisi zakasnio, ali nisi ni sam** — polje je aktivno i dobro financirano. Tvoja
   prava diferencijacija: **Certilia/EUDI (hrvatski/EU eID) root + Gnosis-native
   composable personhood SBT + first-mover u HR + integracija s tvojim postojećim
   stackom** (pay/sms/karta). To je proizvod-moat, ne patent-moat.
2. **Preispitaj nužnost mesha za MVP** (vidi Ključni izazov). zkTLS/NFC put može biti
   jeftiniji put do iste Sybil-otpornosti.
3. **Za patent:** ne oslanjaj se na njega kao strategiju; ako ga radiš, defenzivno i uz
   patentnog zastupnika. Otvoreno-izvorni javni dobro + EU grantovi su vjerojatno bolji put.
4. **Sljedeći korak za rigorozan zapis:** ponovi puni adversarijalni deep-research
   workflow nakon reset limita (10:40 Zagreb) za citirane, verificirane tvrdnje +
   Espacenet pretragu patenata.

## v2 — Verificirani nalazi (dorađeni deep-research, 105 agenata, 24/25 tvrdnji potvrđeno 3-0)

*Drugi krug s izoštrenim pitanjima. Finalni synthesizer je vratio stub (bug), ali verify
faza je uspjela — nalazi izvučeni ručno iz journala. Sve dolje = verificirane tvrdnje.*

### A. Live-OIDC most — POTVRĐENO: prazan prostor ✅
**Nijedan projekt ne most-uje ŽIVU eID OIDC prijavu onchain preko decentralizirane verifier mreže.** Najbliži:
- **Anima** — biometrijski face-scan (ne eID), **centralizirani** KYC provider (Synaps/FaceTec), izdaje SBT za one-member-one-vote. Nije eID-OIDC, nije decentraliziran.
- **interID** — SSI/EBSI/EUDI verifikacija, ali **centralizirani SaaS** (Keycloak), bez onchain SBT-a, bez HW atestacije, bez nullifiera.
- **Privado ID** (Iden3) — zk-VC framework, ugovorno/klijentski, nije signer mesh, nije live-OIDC.
→ **"Živi eID OIDC → onchain SBT preko decentralizirane verifier mreže" je genuino nezauzeto.** To je tvoja jezgra novosti (ali i neprovjereno tržište).

### B. Acurast kao SUBSTRAT — POTVRĐENO: izvedivo ✅ (možda ne gradiš mrežu od nule)
Verificirano iz Acurast dokumentacije:
- Svaki procesor ima **vlastitu EVM adresu**, može potpisati i submitati EVM tx (kad je fundiran gasom).
- **Code-bound hardverski ključ** u secure elementu; samo taj deployment može potpisati; promjena koda uništi pristup.
- **Hardverska atestacija** ukorijenjena u proizvođača uređaja (Titan M2/QSEE); general-purpose runtime (Node/JS/Python) → **možeš deployati vlastiti verifier orakl na postojećih 250k+ telefona**.
- Podržava **pull-orakl** (korisnik plaća gas) i settlement signed outputa onchain.
- **ALI:** nema threshold/multisig/Safe co-signing out-of-the-box → **M-of-N logika je custom nadogradnja**; Acurast sam ne radi eID→SBT.
→ **Ozbiljno razmotri Acurast kao substrat umjesto vlastite mreže** — Faza 2 postaje "custom deployment na Acurastu", ne "kupi/pokreni telefone".

### C. ⚠️ KRITIČAN CAVEAT: Android Key Attestation korijeni u Googleu
Verificirano: attestation lanac (OID 1.3.6.1.4.1.11129.2.1.17) potpisuje **Google-certificirani ključ**. Dakle svaka "decentralizirana" mreža na Android Key Attestationu ima **Google kao točku centralizacije / root of trust.** Poštena formulacija: **"trust-minimized, ne trustless."** Mitigacija: miješaj vendore (Samsung Knox + Titan + Qualcomm), ili to eksplicitno priznaj.

### D. Nullifier state-of-the-art — POTVRĐENO: tvoj dizajn je standard ✅
- **World ID:** nullifier = deterministički hash(identity privkey, app/action) + **Semaphore zk-dokaz protiv onchain Merkle stabla** identity commitmenta + **smart-contract nullifier registar** (mapping, revert ako viđen). **Wallet-agnostičan.** → **Točno moj preporučeni dizajn.**
- **Proof of Humanity v2:** `humanityId` (bytes20), soulbound, ali uniqueness preko **socijalnog challenge-dispute** (ne kriptografski nullifier).
- **Human Passport:** per-wallet score agregator (ne binarni nullifier).
→ **Nullifier-registar + Semaphore zk = dokazana najbolja praksa (World ID). Nitko ne koristi signer mesh za personhood — svi koriste ugovor/zk.** Tvoja diferencijacija je **eID korijen**, ne nullifier mehanizam. (Još jedan dokaz da mesh nije nužan za samu personhood funkciju.)

### E. Patenti / Freedom-to-Operate — KONKRETNI RIZICI ⚠️
- **nChain US 11,347,838 B2** (Craig Wright/nChain, 2022): claim pokriva *"distribuciju identity tokena fiksnom skupu glasača, brojanje onchain signala kroz prozor, otpuštanje pre-lockanih sredstava kad broj prijeđe prag"* → **izravno preklapa identity-token-za-glasanje personhood koncept.** **NAJVEĆI FTO RIZIK** (nChain je parničarski agresivan).
- **nChain US 11,348,095 B2 / 12,003,616:** threshold ECDSA nad bonded validator setom. ALI verificirana distinkcija: **airKUNA koristi M nezavisnih zasebnih ECDSA potpisa kao Safe ownera, NE pravi threshold ECDSA (jedan kolektivni potpis)** → **izbor "M zasebnih potpisnika, ne MPC" ruta OKO ovog patenta.** (Dvostruka korist te odluke.)
- **Cloudflare US 12,206,789 B2** (2025): uređaj generira HW-backed attestation prisutnosti + zk proof bez otkrivanja pubkeya. Djelomično preklapa; ali dokazuje *momentalnu prisutnost* (anti-bot), ne perzistentni personhood.
- **Space Telecom US 12,335,739 B2:** proof-of-location + velocity, ali RF ping-pong fizika (ne GPS/staking) → tehnički različito, nizak rizik.
→ **Realan FTO rizik postoji (osobito nChain glasačko-identitetski patent). Za komercijalizaciju treba FTO mišljenje patentnog zastupnika. Nije blocker za open-source R&D.**

### F. Europska patentabilnost (COMVIK, izoštreno)
- **COMVIK (T641/00):** samo tehničke značajke broje za inventivni korak; ne-tehnički cilj (Sybil-otpornost za glasanje) ide u *formulaciju problema* danu stručnjaku (ne ignorira se, ali ne broji).
- **Pozitivno:** EPO priznaje **"činjenje sustava sigurnijim/pouzdanijim" kao tehnički učinak** koji nosi inventivni korak; kriptografske metode su tehničke (T1326/06); "prilagodba specifičnoj tehničkoj implementaciji" je put; G1/19 "potencijalni tehnički učinak".
- **Loše:** financijski/administrativni koncepti (T641/00 — raspodjela troškova, analogno glasanju/governanceu) ne broje; claim koji pokriva ne-tehničke uporabe pada.
→ **Plausibilan locus patenta = specifičan HW-atestacijom-gated protokol supotpisivanja (sigurnosni učinak), NE "personhood glasački sustav".** USPTO je već tretirao HW-atestaciju+potpisivanje kao patentabilno (Cloudflare). Uzak patent moguć; širok ne.

### G. Financiranje — KONKRETNI PROGRAMI I IZNOSI
- **NGI Pilots (Horizon/NGI) — REALAN ULAZ:** cascade funding, **≥15% se prosljeđuje trećima preko open callova, kapa €60.000 po primatelju.** Ovo je mehanizam kojim mali open-source projekt uđe **bez konzorcija.** (Oprez: jedan NGI Pilots call nije naveo identity/blockchain kao fokus — provjeri aktualni WP.)
- **Digital Europe `DIGITAL-2025-BESTUSE-TECH-09-WALLET`:** ~**€129,6M** za EUDI Wallet dev/certifikaciju (rok 9.12.2025. — prošao; traži 2026-2027 WP nasljednika). `...-09-MDL`: ~**€77M** mobilna vozačka.
- **EUDI large-scale piloti** (POTENTIAL/EWC/NOBID/DC4EU, lansirani IV.2023., 350+ entiteta, 26 zemalja): ulaz preko **konzorcija**; grantovi grade na njihovim spec/reference implementacijama.
- **Horizon "Pilots for NGI (IA)":** max €5M/projekt, €14M call (rok 2023. zatvoren — čekaj novi).
→ **Realan put za airKUNA sada: NGI cascade grant (~€60k), bez konzorcija.** EUDI/Digital Europe = veći novac ali traži konzorcij i kasnije callove. Gnosis/Optimism/Gitcoin kao crypto-native dopuna.

### Finalni verdikt v2
1. **Točan puni stack ne postoji** — potvrđeno. **Live-eID-OIDC → onchain SBT preko decentralizirane mreže je genuino prazan prostor.**
2. **Mesh NIJE nužan za MVP** — potvrđeno dvostruko: (a) World ID dokazuje da nullifier-registar+zk radi personhood BEZ mreže; (b) live-OIDC se može klijentski dokazati (zkTLS). Mesh = decentralizacija povjerenja (Faza 2), i po mogućnosti **na Acurastu, ne od nule.**
3. **Patentabilnost:** uzak tehnički patent (HW-attestation signing) moguć u EU; ali FTO rizik (nChain) realan i patent u sukobu s open-source/grant strategijom → **moat je open impl + eID + first-mover, ne patent.**

## Izvori (glavni)

- Acurast: https://docs.acurast.com/ · https://tech.eu/2025/11/13/acurast-raises-11m-...
- Lit Protocol (TEE + attested signing): https://developer.litprotocol.com/security/introduction
- Web3Auth MPC: https://web3auth.io/docs/product/mpc-core-kit
- Rarimo zkPassport / Proof-of-Citizenship: https://docs.rarimo.com/zk-passport/ · https://rarimo.medium.com/proof-of-citizenship-passport-zkps-and-incognito-identity-28476d4b9451
- GEODNET / XYO proof-of-location: https://geodnet.com/ · https://docs.xyo.network/about-xyo/proprietary-technologies-and-solutions/proof-of-location
- EBSI Verifiable Credentials: https://ec.europa.eu/digital-building-blocks/sites/spaces/EBSI/pages/600343491/EBSI+Verifiable+Credentials
- EPO CII/blockchain patentability: https://www.iam-media.com/review/the-patent-prosecution-review/2026/... · https://gevers.eu/blog/blockchain-eu-patent-protection-importance/
