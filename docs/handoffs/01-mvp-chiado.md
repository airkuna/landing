# Handoff prompt #1 — Izgradi MVP na Gnosis Chiado testnetu

> Zalijepi sve ispod u NOVU Claude Code sesiju (u repou `airkuna-web`).

---

Radiš na **airKUNA Proof of Croatian Personhood** protokolu. Prvo pročitaj, tim redom:
`docs/PERSONHOOD-HANDOFF.md`, `docs/16-whitepaper-proof-of-croatian-personhood.md`,
`docs/decisions/0001-nullifier-registry.md`, `docs/decisions/0002-pluggable-verifier.md`,
`docs/18-android-verifier-node-i-mvp-verifier-a.md`, te sve u `contracts/src/`.

**Cilj:** dovesti MVP (verifier A2 put — thin oracle, BEZ Android mreže) do žive demonstracije
end-to-end na **Gnosis Chiado testnetu**. Foundry je već instaliran (`~/.foundry/bin`); ugovori
kompajliraju (`forge build`, solc 0.8.24).

**Zadaci:**

1. **Foundry testovi** (`contracts/test/`) — pokrij:
   - `claim` uspije i mintira SBT; drugi `claim` s ISTIM nullifierom revertira (`AlreadyClaimed`).
   - `claim` na već-korišten anchor revertira (`AnchorInUse`); `loa < minLoA` revertira.
   - `migrateAnchor` premjesti SBT na novi Safe (isti nullifier); stari anchor oslobođen.
   - `reverify` osvježi `reverifiedAt`; `NullifierMismatch` ako se ne slaže.
   - `PersonhoodSBT`: transfer/approve revertiraju (`Soulbound`); samo registry kuje; `setRegistry` samo jednom.
   - `EIP712Verifier`: M-of-N potpisi prolaze; ispod praga revertira (`NotEnoughSigners`);
     nesortirani/duplirani potpisnici (`SignersNotSorted`); neovlašten potpisnik (`UnauthorizedSigner`); istekli (`Expired`).
   - Cilj: `forge test` zeleno, coverage na sve revert grane.

2. **Deploy skripta** (`contracts/script/DeployMVP.s.sol`) — redoslijed (kružnost je riješena):
   `EIP712Verifier(admin, threshold=1)` → `PersonhoodSBT()` → `IdentityRegistry(gov, verifier, sbt, minLoA)`
   → `sbt.setRegistry(registry)` → `verifier.addSigner(oracleSigner)`. `gov`/`admin` = tvoj Safe/EOA za test.

3. **Off-chain verifier A2** (`services/verifier-a2/`, Cloudflare Worker/Bun) — posudi Certilia
   verifikaciju iz `/Users/ms/git/domovinatv/domovina-api/supabase/functions/certilia/index.ts`
   (JWKS/iss/aud). Za MVP koristi **mock issuer** (test ključ umjesto prave Certilije):
   - Mock issuer izda testni PID `{ime, prezime, OIB}` (OpenID4VCI ili obični OIDC).
   - Verifier validira, izračuna `nullifier = HMAC(oib, TEST_PEPPER)`, potpiše EIP-712
     `{anchor, nullifier, loa, expiry}` (domain "airKUNA PersonhoodVerifier", v1, chainId=10200,
     verifyingContract=EIP712Verifier), vrati `{attestation: abi(nullifier,loa,expiry), proof: abi([sig])}`.

4. **Claim skripta / e2e** — pozovi `IdentityRegistry.claim(anchor, attestation, proof)` na Chiado i
   provjeri da je SBT mintan; pa testiraj isti OIB dvaput (revert) i `migrateAnchor`.

**Gotchas / pravila:**
- Chiado RPC: `https://rpc.chiadochain.net` (chainId **10200**); xDAI s Chiado faucet-a. RPC-i su u `contracts/foundry.toml`.
- Sirovi OIB NIKAD onchain ni u logovima; pepper iza granice (za MVP env var, produkcija KMS/HSM — ADR 0003).
- `EIP712Verifier` traži potpisnike **sortirane strogo uzlazno** po recovered adresi (dedupe).
- NE mijenjaj `IVerifier` interface — A2 je samo N=1 slučaj; kasnije dodaš potpisnike (→ mesh) bez promjene ugovora.
- Commitaj semantički na feature branchu; ne pushaj bez pitanja.

**Done kad:** `forge test` zeleno; ugovori deployani na Chiado; mock-issuer→verifier→`claim` mintira
SBT; dupli OIB revertira; `migrateAnchor` radi. Zabilježi deployane adrese u `docs/18` ili novi `docs/19-mvp-chiado-deploy.md`.
