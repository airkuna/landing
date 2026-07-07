# Proof of Croatian Personhood — HANDOFF (cat za /clear)

> **Svrha:** `cat` ovaj fajl nakon `/clear` da vratiš puni kontekst u jednom potezu.
> Memorija (`~/.claude/.../memory/MEMORY.md`) se i tako auto-učitava, ali ovo je brzi pregled.
> Zadnje ažurirano: 2026-07-07.

## Što gradimo (1 odlomak)

airKUNA (ITalk d.o.o.) gradi **100% open-source protokol** koji verificiranu hrvatsku/EU eID
prijavu (**Certilia MobileID**, eIDAS High; kasnije **EUDI Wallet**) pretvara u **soulbound token
(SBT) osobnosti** na **Gnosis Chainu**. Jedinstvenost je na razini **`nullifier = HMAC(OIB, pepper)`**,
ne walleta → jedna osoba, više Safeova, **jedan identitet** → Sybil-otporno onchain glasanje +
implicitni KYC. Sirovi OIB nikad onchain (GDPR). Cilj: prikupiti EU grantove; ITalk = non-custodial
software provider.

## Ključne odluke (usvojeno)

1. **Nullifier, ne wallet** enforcea jedinstvenost (ADR 0001). Oporavak = ponovni eID login.
2. **Pluggable verifier** (ADR 0002): A zkTLS/Certilia · B NFC eOI · C EIP-712 orakl · D Android mesh.
   **MVP = A/B BEZ mreže** (potvrđeno da radi; World ID dokazuje nullifier+zk bez mesha). **Mesh = Faza 2.**
3. **airKUNA ima VLASTITU ADR bazu** (`docs/decisions/`, kreće 0001), odvojeno od `pay.domovina.ai`
   (payevi ADR 0003-0006 ostaju povijesni; cross-ref Informed-by/Superseded-by).
4. **Pepper je kritičan** (ADR 0003): OIB prostor ~10¹¹ brute-force-abilan ako pepper curi → threshold/HSM + rotacija.
5. **Mesh (ako se gradi):** M zasebnih EIP-712 potpisnika (NE threshold ECDSA/MPC) → jednostavno + ruta oko nChain patenata; razmotri **Acurast kao substrat**.

## Ključni nalazi istraživanja (verificirano, 2 kruga)

- **"Živi eID-OIDC → onchain SBT preko decentralizirane mreže" = GENUINO PRAZAN prostor** (jezgra novosti). Anima=biometrija+centralno, interID=SSI SaaS, Privado=zk-VC framework, Rarimo=NFC putovnica (ne živi OIDC).
- **World ID** = nullifier-registar + Semaphore zk + smart-contract nullifier mapping, wallet-agnostično = dokazani standard (isto kao naš dizajn; razlika = eID izvor).
- **Android Key Attestation korijeni u Googleu** → mesh je trust-minimized, NE trustless. Mitigacija: miješaj vendore.
- **FTO/patenti:** ⚠️ **nChain US 11,347,838 B2** (identity-tokeni→glasači→prag) izravno preklapa personhood-glasanje = najveći rizik. M-zasebnih-potpisnika ruta oko nChain 11,348,095/12,003,616. Cloudflare US 12,206,789 (HW-attest+zk, djelomično). EPO COMVIK: uzak tehnički patent (HW-attest signing) moguć, širok ne.
- **Financiranje:** **NGI Pilots cascade ~€60k/primatelj BEZ konzorcija = realan prvi ulaz.** Digital Europe WALLET ~€129,6M / MDL ~€77M preko LSP konzorcija (POTENTIAL/EWC/NOBID/DC4EU). Gnosis/Optimism/Gitcoin dopuna.
- **EUDI Wallet** = "europska Certilia" (sloj IZNAD nacionalnih eID; obavezno ~kraj 2026./2027.); vraća per-RP pseudonim (NE globalni ID) → EUDI ne rješava Sybil sam, nullifier ostaje naš.

## Mapa datoteka (sve u ovom repou, `airkuna-web/`)

- `docs/14-eudi-wallet-eidas2.md` — EUDI/eIDAS 2.0 knowledge
- `docs/15-prior-art-i-patentabilnost.md` — prior-art + patenti (v2, verificirano)
- `docs/16-whitepaper-proof-of-croatian-personhood.md` — **whitepaper v0.2**
- `docs/17-funding-one-pager.md` — funding one-pager (EN, cilja NGI €60k)
- `docs/18-android-verifier-node-i-mvp-verifier-a.md` — Android node + MVP verifier-A PoC plan
- `docs/decisions/` — ADR baza: README (cross-repo politika), 0000-index, 0001 nullifier, 0002 verifier, 0003 pepper
- `contracts/` — Solidity reference: `IdentityRegistry.sol`, `PersonhoodSBT.sol` (EIP-5484), `EIP712Verifier.sol`, interfaces

## Povezani repozitoriji (drugdje na disku)

- `/Users/ms/git/domovinatv/domovina-api` — **Certilia OIDC verifikacija U PRODUKCIJI** (JWKS/iss/aud, `oib_hash`). Posudi ovaj kod za verifier A2.
- `/Users/ms/git/domovinatv/pay.domovina.ai` — EURe/Safe/relayer rail + origin ADR 0003-0006; Gnosis stack.
- `/Users/ms/git/domovinatv/sms.domovina.ai` — reverse-OTP SMS gateway (neovisan phone-ownership dokaz, drugi izvor).
- `/Users/ms/git/domovinatv/karta-hrvatske/apps/karta-web` — MapLibre karta; dodavanje verifier-node layera = par sati (kloniraj `usePinkaLayer`).
- `/Users/ms/git/domovinatv/domovina-blockchain` — DRUGAČIJI koncept (suvereni L1 klon Gnosisa); mesh NIJE tamo.

## Sljedeći koraci (na Matijin odabir)

- Izgradi **A2 mock harness** (mock issuer + verifier servis + `claim` na Chiado) — počni ovdje za MVP.
- **A2 na pravoj Certiliji** (posudi domovina-api).
- Dopiši `Superseded-by: airkuna 0002` u payev ADR 0004 (zatvori cross-ref petlju).
- Solidity testovi (Foundry) + deploy na Chiado.
- NGI Pilots prijava (iskoristi `docs/17`).
- (paralelno) zkTLS istraživanje; EUDI verifier track.

## Status isporuka A/B/C/D

- (A) Whitepaper v0.2 ✅ + ADR baza ✅
- (B) Funding one-pager ✅ (`docs/17`)
- (C) Solidity reference ugovori ✅ (`contracts/`)
- (D) Android node dizajn + MVP verifier-A plan ✅ (`docs/18`)
