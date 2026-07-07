# 18 — Android verifier node & MVP verifier-A (zkTLS/Certilia)

> Dizajn dvaju putova iz ADR 0002: **MVP = verifier A** (zkTLS nad Certilijom, bez mreže) i
> **Faza 2 = verifier D** (M-of-N Android node mesh). Prati whitepaper (`16`) i ADR 0002/0003.

---

## Dio 1 — MVP: verifier A (zkTLS/Certilia), BEZ mreže

Cilj: dokaži da živi Certilia OIDC login proizvede `nullifier = HMAC(OIB, pepper)` i mintaj SBT —
**bez ijednog verifier nodea**. Ovo je najjeftiniji put do Sybil-otpornosti (potvrđeno istraživanjem).

### Tok

```
Korisnik → Certilia OIDC login (flutter_certilia / certilia.domovina.ai proxy) → id_token
        → zkTLS/Reclaim dokaz: "Certilia JWKS je potpisao id_token koji sadrži OIB=X"
        → klijent/servis izračuna nullifier = HMAC(OIB, pepper)   [pepper: ADR 0003]
        → IdentityRegistry.claim(anchor, attestation, proof)
        → PersonhoodSBT mint na anchor Safe
```

### Dvije varijante verifiera A

- **A1 — čisti zkTLS (bez servera):** klijent generira zk dokaz da HTTPS odgovor s Certilia
  userinfo/token endpointa sadrži njegov OIB, i da je nullifier ispravno izveden. Ugovorni
  `verify()` provjerava zk dokaz. Najčišće, ali pepper tada mora biti *javan po epohi* ili
  zamijenjen zk-friendly commitmentom (jer klijent računa HMAC) → vidi napomenu o pepperu.
- **A2 — thin oracle (praktičniji prvi korak):** jedan off-chain servis (Cloudflare Worker)
  radi ono što `domovina-api` VEĆ radi (validira id_token protiv Certilia JWKS/iss/aud),
  izračuna nullifier iza pepper granice, i potpiše **EIP-712 atestaciju** → to je zapravo
  `EIP712Verifier` s N=1, M=1. Kasnije samo dodaš potpisnike (→ mesh) bez promjene ugovora.

> **Preporuka:** kreni s **A2** (ponovno iskoristi provjeren Certilia kod iz `domovina-api`,
> pepper ostaje tajan na serveru), a A1/zkTLS istraži paralelno kao "trustless" nadogradnju.
> A2 → D je kontinuum: isti `EIP712Verifier`, samo raste broj potpisnika.

### Mock harness (za razvoj bez državne infrastrukture)

Po uzoru na EUDI reference stack:
- **Mock Issuer** (Node/Bun): izdaje testni "PID" `{ime, prezime, OIB}` potpisan test ključem
  (simulira Certiliju), preko OpenID4VCI ili običnog OIDC-a.
- **Verifier servis (A2)**: prima id_token/PID, validira potpis, izračuna `nullifier =
  HMAC(oib, TEST_PEPPER)`, vrati EIP-712 atestaciju `{anchor, nullifier, loa, expiry}`.
- **Skripta**: pozove `IdentityRegistry.claim(...)` na Gnosis testnetu (Chiado) i provjeri mint.
- Testni slučajevi: isti OIB dvaput → drugi `claim` revertira (`AlreadyClaimed`); `migrateAnchor`
  na novi Safe → SBT se premjesti.

### Off-chain verifier (A2) — skica

```ts
// Cloudflare Worker (posudi JWKS/verify logiku iz domovina-api/supabase/functions/certilia)
const { payload } = await jwtVerify(idToken, certiliaJWKS, { issuer, audience: CLIENT_ID });
const oib = payload.pin ?? payload.oib ?? payload.sub;           // Certilia prod: OIB u `sub`
const nullifier = hmacSHA256(oib, env.PEPPER);                   // pepper iza KMS/HSM (ADR 0003)
const loa = acrToLoa(payload.acr);                              // eIDAS High → 3
const expiry = nowSec() + 600;
const sig = signEip712(env.SIGNER_KEY, { anchor, nullifier, loa, expiry }, domain);
return { attestation: abiEncode(nullifier, loa, expiry), proof: abiEncode([sig]) };
```

---

## Dio 2 — Faza 2: Android verifier node (verifier D)

Decentralizira **ključ za kovanje** (ne izvor istine). Nadograđuje A2: umjesto 1 servera, M-of-N
nezavisnih Android nodeova, svaki potpisuje istu EIP-712 atestaciju. Ugovor (`EIP712Verifier`) se
NE mijenja — samo `addSigner` + `setThreshold`.

### Node arhitektura

```
[Android node]
  ├─ StrongBox/TEE ključ (secp256k1)  ── Android Key Attestation dokazuje da ključ
  │                                       nikad nije napustio secure element
  ├─ Certilia verifikacija (JWKS/iss/aud)  ── isti kod kao A2
  ├─ nullifier = HMAC(OIB, pepper-share)   ── pepper threshold/HSM (ADR 0003)
  ├─ EIP-712 potpis {anchor, nullifier, loa, expiry}
  ├─ read-only Gnosis RPC (bez execution layera → nema skupog HW/SSD)
  └─ Cloudflare Tunnel (bez javnog IP-a) ── prima zahtjeve, vraća potpis
```

- **Bez execution layera.** Node NE drži chain state; samo čita RPC i potpisuje → jeftin hardver
  (bilo koji Android s hardverskim keystoreom).
- **Izvršenje tx-a.** Relayer plaća gas i submitta agregirani multi-sig `claim`, **ili** zadnji
  node u krugu (ima malo xDAI) sam izvrši. Relayer/executor ne može krivotvoriti (potpisi vežu
  `anchor/nullifier/loa/expiry`).
- **Potpisi.** M zasebnih EIP-712 potpisa (ne MPC) → jednostavno, i ruta oko nChain threshold patenata.

### DAO onboarding & statusi

- **airKUNA DAO = Safe multisig** (isti `admin` u `EIP712Verifier`) odobrava nove nodeove:
  `pending → active`. Deaktivacija/kick: `active → offline → ejected` (`removeSigner`).
- **Poznat ljudski operater po nodeu** (off-chain registar + onchain adresa). Prijava novog
  verifiera ide kroz DAO glasanje.
- **Onchain izvor istine za status** = je li adresa u `isSigner` + off-chain metadata (status,
  operater, lokacija).

### Geolokacija & karta

- Svaki node ima **poznatu fizičku lokaciju**; prikaz na `karta-hrvatske/apps/karta-web`
  (MapLibre) — novi layer `useVerifiersLayer` (kloniraj `usePinkaLayer`), status→boja
  (`active`=zelena, `offline`=siva, `pending`=amber, `ejected`=crvena).
- **Anti-GPS-spoof:** staking + slashing (tip GEODNET/XYO); node koji laže lokaciju gubi stake.
  (Faza 2 detalj — nije nužno za rad, samo za "gdje je mreža" transparentnost.)

### ⚠️ Caveat (iz istraživanja)

Android Key Attestation korijeni u **Googleu** (Google potpisuje attestation ključ) → mesh je
**trust-minimized, ne trustless**. Mitigacija: miješaj vendore (Samsung Knox + Google Titan +
Qualcomm QSEE) da nijedan proizvođač nije jedina točka. Priznaj to u komunikaciji.

### Alternativa: Acurast kao substrat (preporučeno razmotriti)

Umjesto vlastite mreže: deploy verifier kao **Acurast deployment** na postojećih 250k+ telefona.
Verificirano: Acurast procesori imaju EVM adresu, code-bound HW ključ, atestaciju, potpisuju
onchain, general-purpose runtime. **M-of-N Safe co-signing je custom logika na Acurastu** (nema
out-of-box), ali izbjegavaš nabavu/održavanje hardvera. Trade-off: manje kontrole nad lokacijom
nodeova (tvoja "karta" priča slabija), ali brži start.

---

## Redoslijed gradnje

1. **A2 mock harness** (mock issuer + verifier servis + `claim` na Chiado testnetu). ← počni ovdje
2. **A2 na pravoj Certiliji** (posudi `domovina-api` verifikaciju; pepper u KMS).
3. (paralelno) **A1/zkTLS** istraživanje kao trustless nadogradnja.
4. **D**: prvi 3-of-5 Android nodeovi (ili Acurast deployment) + DAO onboarding + karta.
5. **Slashing/geo** ekonomija.
