# Handoff prompt #2 — Javni landing za funding (airkuna.org + airkuna.com)

> Zalijepi sve ispod u NOVU Claude Code sesiju (u repou `airkuna-web`).

---

Radiš na **airKUNA** web prezentaciji. Cilj: **javno predstaviti Proof of Croatian Personhood
protokol i omogućiti prikupljanje sredstava** — jer trenutno nema landinga koji pokazuje ZA ŠTO
treba funding. Prvo pročitaj, tim redom:
`docs/PERSONHOOD-HANDOFF.md`, `docs/16-whitepaper-proof-of-croatian-personhood.md`,
`docs/17-funding-one-pager.md`, pa POSTOJEĆE stranice `com/index.html` i `org/index.html`
(i `docs/00-ssot-index.md` za ton/brand).

**Zatečeno stanje (provjeri sam):**
- `com/index.html` = TRENUTNO airKUNA **stablecoin** landing (regulirani hrvatski euro stablecoin).
- `org/index.html` = TRENUTNO šira misija/vizija stranica.
- Oba su **single-file HTML** s istim dizajn-sustavom (CSS varijable navy `#002F6C` / gold `#C8912A`,
  fontovi Fraunces + Inter, `.wrap/.eyebrow/.title/.lead` klase, `coin.svg`). Deploy je Cloudflare
  (`.wrangler/` postoji, remote `airkuna/landing`) — **prije deploya utvrdi točan mehanizam** (README, `.wrangler`, `wrangler pages`).

**CILJANI RASPORED (odluka korisnika — OBRNUTO od trenutnog):**
- **`com` = Proof of Personhood FUNDING landing.** Razlog: `.com` je **ITalk d.o.o. (firma)** koja traži
  funding da razvije protokol — day-zero transparentno. Ovdje ide personhood priča + funding CTA.
- **`org` = stablecoin.** Razlog: `.org` je **airKUNA DAO** koji upravlja stablecoinom (javno dobro / zajednica).
- **Migracija:** trenutni stablecoin sadržaj je u `com/index.html` → **premjesti ga u `org/index.html`**
  (spoji sa/zamijeni postojeću org misiju po dogovoru), pa **`com/index.html` postane personhood-funding**.

**Zadaci:**

1. **Reorganiziraj com↔org prema ciljanom rasporedu gore.** Pročitaj obje postojeće stranice, predloži
   korisniku konkretan plan migracije (što ide gdje, što s postojećom org misijom) i **potvrdi prije velikih izmjena**.

2. **Napiši personhood funding sekciju/stranicu** — sadržaj destiliraj iz `docs/16` + `docs/17`, na
   hrvatskom za javnost (one-pager `docs/17` je EN za grantove — zadrži i EN verziju za grant link):
   - **Problem** (laički): Sybil napadi + centraliziran eID → onchain demokracija ne radi.
   - **Rješenje:** eID → soulbound token osobnosti; jedna osoba, više novčanika, **jedan identitet**;
     OIB nikad onchain (GDPR). Source-agnostično: Certilia danas → EUDI Wallet sutra (cijela EU).
   - **Zašto javno dobro / zašto ITalk** (non-custodial software provider).
   - **Roadmap** (Faza 0 MVP → … → EUDI), transparentno.
   - **Funding CTA:** za što točno treba novac (MVP, audit, mreža) + kako doprinijeti — Gitcoin/grant
     link, **EURe/xDAI donacijska adresa na Gnosisu** (pitaj korisnika za adresu ili Safe), i
     `ms@airkuna.com`. Iskoristi konkretne iznose iz `docs/17` (npr. NGI ~€60k za MVP).
   - Linkovi na whitepaper i one-pager (razmisli o objavi `docs/16`/`docs/17` kao javnih stranica).

3. **Dizajn:** 100% ponovno iskoristi postojeći dizajn-sustav (iste CSS varijable, fontovi, komponente)
   da izgleda nativno uz stablecoin landing. Single-file HTML, self-contained, responsive, bez vanjskih
   ovisnosti osim već korištenih Google fonts. Provjeri da se ne lomi na mobitelu.

4. **Cross-link .com ⇄ .org** (npr. u navu/footeru: "Stablecoin" ⇄ "Digitalni identitet / Personhood").

5. **Preview lokalno**, pokaži korisniku screenshot/opis. **Deploy na produkciju (airkuna.org/.com) TEK
   nakon izričite potvrde korisnika** — to je javno i teško reverzibilno. Utvrdi deploy komandu prije toga.

**Pravila:**
- Točnost iznad hypea: NE tvrdi da je gotovo ono što nije (mesh je Faza 2; MVP je verifier A). NE obećavaj
  regulatorni status koji nemamo. Zadrži GDPR/non-custodial okvir.
- Ne izmišljaj donacijske adrese — traži ih od korisnika.
- Commitaj semantički; **NE deployaj bez potvrde**.

**Done kad:** personhood funding sadržaj je na **com** i stablecoin na **org** (+ cross-link), izgleda nativno
uz postojeći dizajn, ima jasan "za što treba novac" + CTA, lokalno preview OK, i — nakon potvrde —
deployano na airkuna.org/.com.
