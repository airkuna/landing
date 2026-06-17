# airKUNA — landing stranice

Dvije premium, samostojeće (self-contained) landing stranice za airKUNA brand. Bez build koraka: čisti HTML + CSS, fontovi (Fraunces + Inter) i MermaidJS preko CDN-a.

| Folder | Domena | Svrha | Ton |
|---|---|---|---|
| [`com/`](com) | **airkuna.com** | Komercijalni projekt za investitore/partnere (kao Monerium) | Fintech, samouvjeren, VC-facing |
| [`org/`](org) | **airkuna.org** | Pokret/edukacija: zašto stablecoin, kako nastaje novac, ekstrakcijska ekonomija, kuharica | Edukativan, narativan, argumentiran |

## Sadržaj

- **com** — hero, tržišne brojke, kako radi (mint/burn Mermaid flow), dokazani Monerium model, tržište/prilika, treasury yield, live (domovina.ai), CTA.
- **org** — priča kune (od krzna do koda), stablecoin 101, endogeni novac (Mermaid), ekstrakcijska ekonomija (Mermaid odljev kapitala), usporedna tablica HR banaka (ZABA/UniCredit, PBZ/Intesa, Erste, OTP, RBA, HPB), dva modela side-by-side, kuharica (5 koraka + Mermaid), Monerium dokaz, vizija.

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
