# 19 — MVP deploy & e2e (verifier A2, Gnosis Chiado)

> Zatvara Roadmap Fazu 0 (whitepaper `16` §10): `IdentityRegistry` + `PersonhoodSBT`
> + **verifier A2** (thin EIP-712 oracle, ADR 0002 / `docs/18`), mock issuer → claim → SBT.
> Prati ADR 0001 (nullifier), 0002 (pluggable verifier), 0003 (pepper).

## Što je isporučeno

| Dio | Lokacija | Status |
|---|---|---|
| Foundry testovi (55, sve revert grane) | `contracts/test/` | ✅ `forge test` zeleno |
| Deploy skripta | `contracts/script/DeployMVP.s.sol` | ✅ |
| Off-chain verifier A2 (Bun/CF Worker) | `services/verifier-a2/` | ✅ |
| Mock issuer (test PID) | `services/verifier-a2/src/mock-issuer.ts` | ✅ |
| E2e harness (deploy→claim→dup→migrate) | `services/verifier-a2/scripts/e2e.ts` | ✅ |

`forge test`: **55 passed, 0 failed**; coverage 100% linija/funkcija, sve dostižne revert grane
pokrivene (preostale nepokrivene grane su nedostižne: mrtvi `valid < threshold` u verifieru,
kratkospojene OR-podgrane u zero-address/`supportsInterface` provjerama).

## E2e dokaz (lokalni EVM = isti kao Chiado)

Pokrenuto protiv `anvil` (chainId 31337; identičan EVM kao Chiado, razlika je samo mreža):

```
[1] deploy contracts
  deployed EIP712Verifier @ 0x5FbDB2315678afecb367f032d93F642f64180aa3
  deployed PersonhoodSBT @ 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
  deployed IdentityRegistry @ 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
  wired sbt.registry + addSigner(0xd4739c08DF98C20C7861373c6aE0A44D604061D5)
[2] claim (anchor A1)      → ✓ SBT minted; isPerson(A1)==true; loa=3
[3] duplicate, same OIB    → ✓ same nullifier; claim reverted (AlreadyClaimed)
[4] migrateAnchor to A3    → ✓ SBT moved to A3; old anchor A1 freed
✅ e2e OK
```

(Adrese gore su deterministički CREATE iz anvil računa #0 — iste na svakom lokalnom pokretanju.)

## Deploy na Chiado (runbook)

**Preduvjeti:** funded EOA na Chiadu (xDAI); Foundry (`~/.foundry/bin`). RPC/chainId u
`contracts/foundry.toml` (`chiado`, chainId **10200**).

### Fundiranje (faucet) — nema čistog programskog puta

Provjereno (2026-07): Chiado faucet-i su **namjerno anti-bot** — nema javnog HTTP API-ja
koji bi zaobišao zaštitu. Podjela posla: **captcha je ljudska (30 s), sve poslije je skriptabilno.**

| Faucet | Unos adrese? | Zaštita | Napomena |
|---|---|---|---|
| [gnosisfaucet.com](https://gnosisfaucet.com) | ✅ proizvoljna adresa | CAPTCHA | odaberi **Chiado**; najmanje trenja |
| [faucet.chiadochain.net](https://faucet.chiadochain.net) | ✅ proizvoljna adresa | CAPTCHA | službeni |
| [faucets.chain.link/gnosis-chiado-testnet](https://faucets.chain.link/gnosis-chiado-testnet) | wallet-connect | wallet + CAPTCHA (+ povijesno mainnet ETH anti-sybil) | traži uvoz ključa u wallet |
| [ETHGlobal](https://ethglobal.com/faucet/gnosis-chiado-10200) | wallet-connect | login | 0.05 xDAI/dan |

**Preporuka:** zalijepi deployer adresu u gnosisfaucet.com/faucet.chiadochain.net, riješi captcha.
Ne moraš uvoziti ključ u MetaMask jer ovi faucet-i šalju na proizvoljnu adresu.

> **Gotcha (LINK ≠ gas):** Chainlink faucet po defaultu dispenzira **25 test LINK** (ERC-20),
> što NE plaća gas. Za deploy treba **native xDAI**. Ili odaberi native/gas opciju na
> Chainlink faucetu, ili uzmi native s faucet.chiadochain.net / gnosisfaucet.com.
> (Provjera: `cast balance $ADDR` = native; ERC-20 stanje ne pomaže deployu.)

Programski dio koji JEST moguć — poll balansa dok ne stigne (pa auto-deploy):

```bash
export PATH="$HOME/.foundry/bin:$PATH"
ADDR=$(cast wallet address --private-key $(grep -oP 'PRIVATE_KEY=\K.*' contracts/.env))
until [ "$(cast balance "$ADDR" --rpc-url chiado)" != "0" ]; do sleep 15; done
echo "funded: $(cast balance "$ADDR" --rpc-url chiado --ether) xDAI"
```

```bash
# 1. deploy ugovora (gov/admin/oracleSigner default = deployer)
cd contracts
export PRIVATE_KEY=0x<funded-eoa>
# opcionalno: GOVERNANCE=0x<Safe> ADMIN=0x<Safe> ORACLE_SIGNER=0x<verifier-signer> MIN_LOA=2
forge script script/DeployMVP.s.sol:DeployMVP --rpc-url chiado --broadcast

# → zabilježi ispisane adrese (EIP712Verifier / PersonhoodSBT / IdentityRegistry)
```

```bash
# 2. pokreni verifier A2 s adresom deployanog EIP712Verifiera
cd services/verifier-a2
#   .dev.vars: MODE=mock  CHAIN_ID=10200  VERIFYING_CONTRACT=0x<verifier>
#              PEPPER=...  SIGNER_KEY=0x<oracle key čija je adresa addSigner-ana>
bun run dev
```

```bash
# 3. e2e protiv Chiada (deploya svjež set + odvrti claim/dup/migrate)
RPC_URL=https://rpc.chiadochain.net PRIVATE_KEY=0x<funded-eoa> \
  VERIFIER_URL=http://localhost:8787 bun run e2e
```

> Napomena: `DeployMVP` radi `addSigner(oracleSigner)` samo ako je `ADMIN == deployer`
> (broadcaster mora biti verifier admin). Ako je admin poseban Safe, pozovi
> `verifier.addSigner(oracleSigner)` iz Safea nakon deploya.

## Chiado adrese (popuniti nakon deploya)

| Ugovor | Adresa | Tx |
|---|---|---|
| EIP712Verifier | `TODO` | |
| PersonhoodSBT | `TODO` | |
| IdentityRegistry | `TODO` | |
| Oracle signer (addSigner) | `TODO` | |
| Deployer/governance | `TODO` | |

> **Blokira:** treba funded Chiado EOA (privatni ključ + xDAI). Kad je dostupan,
> pokreni runbook iznad i upiši adrese ovdje. Lokalni e2e (gore) već dokazuje cijeli tok.

## Sljedeće (Faza 1+)

- A2 na **pravoj Certiliji** (`MODE=prod`, posudi JWKS/iss/aud iz `domovina-api`); pepper → KMS/HSM.
- Drugi izvor (phone-SBT preko `sms.domovina.ai`) + credibility score.
- Verifier D (mesh): `addSigner` + `setThreshold` — ugovori se NE mijenjaju.
