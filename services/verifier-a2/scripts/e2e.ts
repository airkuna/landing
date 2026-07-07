// End-to-end MVP demonstration (docs/18 "A2 mock harness"):
//   mock issuer  →  verifier A2 (EIP-712 attestation)  →  IdentityRegistry.claim  →  SBT mint
//   + same OIB twice reverts (AlreadyClaimed)  + migrateAnchor moves the SBT.
//
// Chain-agnostic: defaults to a local anvil (chainId 31337), but point it at Gnosis
// Chiado by setting RPC_URL + PRIVATE_KEY (a funded EOA):
//   RPC_URL=https://rpc.chiadochain.net PRIVATE_KEY=0x... bun run scripts/e2e.ts
//
// Requires the verifier server running (bun run dev) at VERIFIER_URL.
import {
  createPublicClient,
  createWalletClient,
  defineChain,
  http,
  getAddress,
  type Abi,
  type Address,
  type Hex,
} from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";
import { DEV_SIGNER_ADDRESS } from "../src/config.ts";

const HERE = dirname(fileURLToPath(import.meta.url));
const OUT = resolve(HERE, "../../../contracts/out");

const RPC = process.env.RPC_URL ?? "http://localhost:8545";
const VERIFIER_URL = process.env.VERIFIER_URL ?? "http://localhost:8787";
// anvil default account 0 (well-known dev key). Override for Chiado.
const DEPLOYER_PK = (process.env.PRIVATE_KEY ??
  "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80") as Hex;
const MIN_LOA = 2;
const OIB = process.env.TEST_OIB ?? "12345678901";

const A1 = getAddress("0x1111111111111111111111111111111111111111");
const A2 = getAddress("0x2222222222222222222222222222222222222222");
const A3 = getAddress("0x3333333333333333333333333333333333333333");

function artifact(name: string): { abi: Abi; bytecode: Hex } {
  const j = JSON.parse(readFileSync(`${OUT}/${name}.sol/${name}.json`, "utf8"));
  return { abi: j.abi as Abi, bytecode: j.bytecode.object as Hex };
}

function ok(cond: boolean, msg: string) {
  if (!cond) throw new Error(`ASSERT FAILED: ${msg}`);
  console.log(`  ✓ ${msg}`);
}

async function main() {
  const account = privateKeyToAccount(DEPLOYER_PK);
  const probe = createPublicClient({ transport: http(RPC) });
  const chainId = await probe.getChainId();
  const chain = defineChain({
    id: chainId,
    name: `chain-${chainId}`,
    nativeCurrency: { name: "xDAI", symbol: "xDAI", decimals: 18 },
    rpcUrls: { default: { http: [RPC] } },
  });
  const pub = createPublicClient({ chain, transport: http(RPC) });
  const wallet = createWalletClient({ account, chain, transport: http(RPC) });

  console.log(`\nRPC ${RPC}  chainId ${chainId}  deployer ${account.address}`);
  const bal = await pub.getBalance({ address: account.address });
  console.log(`deployer balance: ${bal} wei`);
  if (bal === 0n) throw new Error("deployer has no funds — fund it (Chiado faucet) or start anvil");

  async function deploy(name: string, args: readonly unknown[]): Promise<Address> {
    const { abi, bytecode } = artifact(name);
    const hash = await wallet.deployContract({ abi, bytecode, args, account, chain });
    const rcpt = await pub.waitForTransactionReceipt({ hash });
    if (!rcpt.contractAddress) throw new Error(`${name} deploy: no address`);
    console.log(`  deployed ${name} @ ${rcpt.contractAddress}`);
    return getAddress(rcpt.contractAddress);
  }

  async function send(address: Address, abi: Abi, fn: string, args: readonly unknown[]) {
    const { request } = await pub.simulateContract({ address, abi, functionName: fn, args, account, chain });
    const hash = await wallet.writeContract(request);
    await pub.waitForTransactionReceipt({ hash });
  }

  async function expectRevert(
    address: Address,
    abi: Abi,
    fn: string,
    args: readonly unknown[],
    label: string,
  ) {
    try {
      await pub.simulateContract({ address, abi, functionName: fn, args, account, chain });
      throw new Error(`expected revert but ${label} succeeded`);
    } catch (e) {
      const msg = String((e as Error).message);
      if (msg.includes("expected revert but")) throw e;
      console.log(`  ✓ ${label} reverted (${msg.split("\n")[0].slice(0, 60)})`);
    }
  }

  // --- 1. deploy the MVP stack (order per DeployMVP.s.sol) ---
  console.log("\n[1] deploy contracts");
  const verifier = await deploy("EIP712Verifier", [account.address, 1n]);
  const sbt = await deploy("PersonhoodSBT", []);
  const registry = await deploy("IdentityRegistry", [account.address, verifier, sbt, MIN_LOA]);

  const vAbi = artifact("EIP712Verifier").abi;
  const sAbi = artifact("PersonhoodSBT").abi;
  const rAbi = artifact("IdentityRegistry").abi;

  await send(sbt, sAbi, "setRegistry", [registry]);
  await send(verifier, vAbi, "addSigner", [getAddress(DEV_SIGNER_ADDRESS)]);
  console.log(`  wired sbt.registry + addSigner(${DEV_SIGNER_ADDRESS})`);

  // --- helper: mock issuer → verifier A2 → {attestation, proof} for `anchor` ---
  async function attestFor(anchor: Address) {
    const { idToken } = await fetch(`${VERIFIER_URL}/issue`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ oib: OIB, ime: "Ivan", prezime: "Horvat" }),
    }).then((r) => r.json());

    const res = await fetch(`${VERIFIER_URL}/verify`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ idToken, anchor, chainId, verifyingContract: verifier }),
    }).then((r) => r.json());
    if (res.error) throw new Error(`verifier error: ${JSON.stringify(res)}`);
    return res as { attestation: Hex; proof: Hex; nullifier: Hex; loa: number };
  }

  const ownerOfNull = (nullifier: Hex) =>
    pub.readContract({ address: sbt, abi: sAbi, functionName: "ownerOfNullifier", args: [nullifier] }) as Promise<Address>;

  // --- 2. claim mints an SBT ---
  console.log("\n[2] claim (anchor A1)");
  const att1 = await attestFor(A1);
  await send(registry, rAbi, "claim", [A1, att1.attestation, att1.proof]);
  ok((await ownerOfNull(att1.nullifier)) === A1, "SBT minted to anchor A1");
  ok(
    (await pub.readContract({ address: registry, abi: rAbi, functionName: "isPerson", args: [A1] })) === true,
    "isPerson(A1) == true",
  );
  console.log(`  nullifier: ${att1.nullifier}  loa: ${att1.loa}`);

  // --- 3. same OIB again → AlreadyClaimed ---
  console.log("\n[3] duplicate claim, same OIB (anchor A2)");
  const att2 = await attestFor(A2);
  ok(att2.nullifier === att1.nullifier, "same OIB → same nullifier");
  await expectRevert(registry, rAbi, "claim", [A2, att2.attestation, att2.proof], "duplicate claim");

  // --- 4. migrateAnchor moves the SBT (eID recovery) ---
  console.log("\n[4] migrateAnchor to A3 (eID recovery)");
  const att3 = await attestFor(A3);
  await send(registry, rAbi, "migrateAnchor", [A3, att3.attestation, att3.proof]);
  ok((await ownerOfNull(att1.nullifier)) === A3, "SBT moved to anchor A3");
  ok(
    (await pub.readContract({ address: registry, abi: rAbi, functionName: "isPerson", args: [A1] })) === false,
    "old anchor A1 freed (isPerson == false)",
  );

  console.log("\n✅ e2e OK — mock issuer → verifier A2 → claim → SBT; dup reverts; migrate works.");
  console.log("\nDeployed addresses:");
  console.log(JSON.stringify({ chainId, verifier, sbt, registry, signer: DEV_SIGNER_ADDRESS }, null, 2));
}

main().catch((e) => {
  console.error("\n❌ e2e FAILED:", e.message);
  process.exit(1);
});
