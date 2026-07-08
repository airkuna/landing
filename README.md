# airKUNA — landing stranice

Samostojeće (self-contained) landing stranice za airKUNA brand. Bez build koraka: čisti HTML + CSS, fontovi (Fraunces + Inter) i MermaidJS preko CDN-a.

| Folder | Domena | Svrha | Ton |
|---|---|---|---|
| [`com/`](com) | **airkuna.com** | **Proof of Croatian Personhood** — protokol dokaza osobnosti onchain + prikupljanje sredstava (ITalk d.o.o.) | Tehnički, javno dobro, grant/partner-facing |
| [`org/`](org) | **airkuna.org** | **Stablecoin** — edukacija + investitorski sadržaj; airKUNA DAO / javno dobro zajednice | Edukativan, narativan + investitorski |

> **Napomena (raspored):** `.com` = **ITalk d.o.o.** (firma koja razvija personhood protokol i traži funding). `.org` = **airKUNA DAO** (upravlja stablecoinom kao javnim dobrom). Stranice su cross-linkane: com „Stablecoin" ⇄ org „Digitalni identitet".

## Sadržaj

- **com** (personhood) — hero, problem (Sybil + centraliziran eID), rješenje (eID→SBT, nullifier, GDPR, source-agnostično), kako radi (Mermaid eID→onchain flow), pluggable verifier tablica (A/B=MVP, D=Faza 2), zašto javno dobro/ITalk, roadmap (Faza 0→5), status (izgrađeno vs u planu), financiranje (NGI ~€60k, Gnosis, RetroPGF) + CTA. Pod-stranice (HR primarne, linkane): [`com/whitepaper/`](com/whitepaper) (HR whitepaper), [`com/sazetak/`](com/sazetak) (HR funding one-pager), [`com/zamasnjak/`](com/zamasnjak) (HR treasury-flywheel investitorski explainer). **Engleske varijante skrivene** (`noindex`, van navigacije) do finalizacije HR sadržaja: [`com/funding/`](com/funding), [`com/flywheel/`](com/flywheel). Vidi [`docs/handoffs/04-jezik-hrvatski-primarni.md`](docs/handoffs/04-jezik-hrvatski-primarni.md).
- **org** (stablecoin) — priča kune (od krzna do koda), stablecoin 101, endogeni novac (Mermaid), ekstrakcijska ekonomija, usporedna tablica HR banaka, dva modela side-by-side, kuharica (5 koraka + Mermaid), Monerium dokaz, razmjer/Gnosis, **tržište/prilika**, **treasury yield**, **live stack (domovina.ai)**, DAO/partner CTA.

## Brand

- Navy `#002F6C` (airKUNA / povjerenje), zlato `#C8912A` / `#E3AF35` (novčić, vrijednost, treasury), crvena `#C0181C` (samo .org — stari centralizirani/ekstrakcijski sustav).
- Tipografija: **Fraunces** (display serif) + **Inter** (tekst).
- `coin.svg` — novčić: navy + zlatni rub + bijela silueta kune (iz airKUNA media-kita).
- Bez emojija (vidi pravilo u pitch-deck repou).

## Lokalni pregled

```bash
python3 -m http.server 8755
# → http://localhost:8755/com/   i   http://localhost:8755/org/
```

## Deploy

Svaki folder je neovisno deployabilan na svoju domenu (statički hosting — Cloudflare Pages, GitHub Pages, Netlify). `coin.svg` je kopiran u svaki folder pa su folderi samodostatni.

## Izvori podataka

Brojke su potkrijepljene javnim izvorima (HNB/HUB, N1, Bloomberg Adria, Telegram, NHS za bankarski sektor; Monerium, CoinGecko/DefiLlama, EBA/MiCA za stablecoine; ECB/HNB za kunu). Sve zaokruženo i timestampirano (2025./2026.).
