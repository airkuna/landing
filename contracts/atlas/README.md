# sol-atlas

Vizualizacijski alat za Solidity projekte: prikazuje deployane sustave ugovora onako kako
DBML/dbdiagram.io prikazuje relacijske baze — **storage kao tablice, međusobne reference ugovora
kao strane ključeve (foreign keys)** — plus eksplicitni **prikaz tokova novca kao state machine**,
sve na interaktivnom 2D canvasu.

## Struktura

```
atlas/
├── atlas.config.json      # deklarativni registar projekata/ugovora/deploymenta + popis machina
├── machines/
│   ├── pinka-crowdfund.json          # ručno napisan state machine PinkaCrowdfund kampanje
│   ├── identity-registry.json        # ručno napisan state machine IdentityRegistry (bez novca)
│   ├── kuna-token.json               # KunaToken money machine (mint/redeem/pauza s iznimkom) + governance lane
│   └── verifier-node-registry.json   # lifecycle Android verifier nodea (pending→active→offline→ejected) sa stake/slash
├── generate.mjs           # generator (Node, bez npm ovisnosti)
├── smoke.mjs              # validacija generiranih artefakata
├── viewer.html            # interaktivni 2D canvas preglednik
└── out/                   # generirano (ne uređivati ručno)
    ├── atlas.dbml             # zalijepiti u https://dbdiagram.io/d
    ├── atlas-data.json        # spojeni model (schema + machines)
    └── atlas-standalone.html  # viewer s inline podacima (radi preko file://)
```

## Kako regenerirati

Preduvjet: instaliran Foundry (`forge`). Zatim iz `contracts/` direktorija:

```bash
node atlas/generate.mjs   # forge build + forge inspect za sve ugovore, emitira out/
node atlas/smoke.mjs      # validira artefakte (broj ugovora, ABI provjere fn-ova, refovi, DBML)
```

Generator za svaki projekt iz configa pokrene `forge build`, pa po ugovoru
`forge inspect <Ime> storage-layout --json` i `forge inspect <Ime> abi --json`,
te iz toga složi DBML, JSON model i standalone HTML.

## Kako otvoriti viewer

- **Najjednostavnije:** otvoriti `atlas/out/atlas-standalone.html` dvoklikom (podaci su inline,
  radi i preko `file://`).
- Alternativno: servirati `atlas/` direktorij (npr. `python3 -m http.server` u `atlas/`) i otvoriti
  `viewer.html` — on onda fetcha `out/atlas-data.json`.

### Što viewer zna

- **Schema view** — ugovori kao DB tablice (redovi = storage varijable sa slotom/offsetom;
  immutable adrese ugovora prikazane kao pseudo-redovi da bi refovi imali sidrište). Bridovi su
  tipizirani: `holds-address` (plavo), `calls` (sivo), `mints` (zeleno), `burns` (crveno);
  cross-project bridovi su isprekidani.
- **State machine view** — po machineu: stanja obojana po vrsti (initial/active/terminal),
  prijelazi kao strelice s imenom funkcije i guardovima; **prijelazi koji nose novac su jantarne
  boje s oznakama tokena**; vremenski prijelazi (`startTime`, `deadline`) su isprekidani.
  Machine bez novca (identity) se renderira bez money legende.
- **Klik** na tablicu/stanje/labelu brida otvara bočni panel s punim detaljima
  (storage + ABI, odnosno guardovi + money + side effects).
- **Live mode** (schema view): upiši RPC URL i adrese deployanih ugovora (prefill iz
  `deployments` u configu ako postoje) pa klikni **Read** — viewer preko čistog
  `fetch` JSON-RPC `eth_call`-a pročita *sve view gettere bez parametara* (izvedeno iz ABI-ja)
  i upiše trenutne vrijednosti u retke tablica. Greške se prikazuju po pozivu, ne ruše ostalo.
- Pan (drag), zoom (kotačić), drag čvorova; svijetla/tamna tema prati `prefers-color-scheme`.

## Kako napisati machine JSON

State machineovi su **ručno pisani** (vidi Ograničenja). Shema:

```jsonc
{
  "id": "moj-machine",                  // jedinstveni id
  "title": "Naslov u UI-ju",
  "project": "pinka",                   // id projekta iz atlas.config.json
  "contract": "PinkaCrowdfund",         // ugovor čiji ABI validira fn-ove (smoke test!)
  "stateSource": "derived" | "stored",  // derived = view fn računa stanje; stored = stanje u storageu
  "stateGetter": "status",              // (derived) view fn koja vraća stanje — mora postojati u ABI-ju
  "stateExpr": "...",                   // (stored) izraz koji objašnjava kako se stanje čita
  "scope": "po čemu se instancira (po kampanji, po nullifieru...)",
  "tokens": {                           // legenda tokena za money bridove
    "EURe":  { "external": true, "note": "Monerium EURe" },
    "ITALK": { "contract": "PinkaToken", "project": "pinka" }  // mapira token na ugovor iz atlasa
  },
  "states": [
    { "id": "ACTIVE", "label": "Active", "kind": "initial|active|terminal",
      "guard": "uvjet pod kojim status()/storage daje ovo stanje" }
  ],
  "transitions": [
    {
      "from": "ACTIVE", "to": "ACTIVE",
      "fn": "invest",                   // ime funkcije iz ABI-ja ILI literal "time" za vremenski prijelaz
      "path": "DIRECT_APPROVE",         // (opcionalno) oznaka investicijskog puta
      "caller": "tko smije zvati",
      "guards": ["require uvjeti, modifieri..."],
      "money": [                        // [] ako se novac ne miče — obavezno navesti eksplicitno!
        { "token": "EURe",  "from": "investor", "to": "PinkaCrowdfund", "note": "..." },
        { "token": "ITALK", "from": "mint",     "to": "investor" }       // "mint"/"burn" su specijalne vrijednosti
      ],
      "sideEffects": [                  // pozivi u druge ugovore (validira se protiv njihovog ABI-ja)
        { "contract": "PersonhoodSBT", "fn": "mint", "note": "..." }
      ],
      "note": "posebnosti (npr. quirkovi u kodu)"
    }
  ],
  "overlays": [                         // ortogonalna stanja (npr. Pausable)
    { "id": "PAUSED", "enterFn": "pause", "exitFn": "unpause",
      "appliesTo": ["ACTIVE"], "blocks": ["invest"], "note": "..." }
  ],
  "notes": ["slobodne napomene, prikazuju se u panelu"]
}
```

Konvencije za `money.from`/`money.to`: ime ugovora iz atlasa, uloga aktera (`investor`,
`fundReceiver`...), ili specijalne vrijednosti `"mint"` (token nastaje) i `"burn"` (token nestaje).
Iz `mint`/`burn`/`sideEffects` generator izvodi dodatne bridove (`mints`/`burns`/`calls`) za
schema view. Novi machine registrira se dodavanjem putanje u `machines` polje configa;
`node atlas/smoke.mjs` zatim provjerava da svaki `fn` postoji u ABI-ju ugovora.

## Kako dodati projekt/ugovor

U `atlas.config.json` dodaj projekt (`root` je relativan na config ili apsolutan) i ugovore
(`name` = ime ugovora za `forge inspect`, `source` = putanja radi provjere postojanja).
`"optional": true` znači da se ugovor preskače dok ne postoji (tako je `KunaToken` bio registriran
prije nego što je stigao u src — čim se pojavio, generator ga je pokupio bez izmjene configa).
`deployments` (opcionalno): `[{ "contract": "PinkaCrowdfund", "chainId": 100, "address": "0x…", "label": "Gnosis" }]`
— prefilla adrese u live modeu. `refs` (opcionalno) su eksplicitne veze koje heuristika ne može
vidjeti (npr. adrese unutar structova poput `PinkaFactory.campaigns`).

## Poštena ograničenja

- **State machineovi su ručno pisani.** Automatska ekstrakcija state machinea i tokova novca iz
  bytecodea/ABI-ja nije izvediva ovim alatom (stanje je često *derived* iz više varijabli i
  `block.timestamp`, a semantika "novca" je domenska). Smoke test zato barem strojno provjerava da
  svaka referencirana funkcija (transition `fn`, overlay, side effect) stvarno postoji u ABI-ju.
- **Refovi su djelomično heuristički.** Sigurni su bridovi iz tipiziranih storage varijabli
  (`contract X`), a za `address` varijable pogađa se po imenu (npr. `registry` →
  `IdentityRegistry`). Adrese unutar mappinga/structova heuristika ne vidi — za njih služe
  eksplicitni `refs` u configu. Vanjski ugovori (npr. Monerium EURe / `IERC20 currency`) nisu u
  atlasu pa nemaju brid — spomenuti su u Note bloku tablice.
- **Live mode čita samo view/pure funkcije bez parametara.** Mappinzi, nizovi i getteri s
  argumentima ne mogu se pročitati bez ulaznih vrijednosti. Dekodiraju se samo jednostavni
  povratni tipovi (uint/int/address/bool/bytesN/string/bytes); ostalo se prikazuje kao sirovi hex.
- **Immutables/konstante nisu u storage layoutu** — prikazuju se iz ABI-ja kao getteri; kao
  pseudo-redovi u tablici završe samo oni s tipom `contract X` (da refovi imaju sidrište).
- Konstante poput `name`/`symbol` ne razlikuju se od izvedenih view funkcija (ABI ih ne razlikuje);
  sve su navedene zajedno u Note bloku tablice.
- DBML ne poznaje tipizirane/isprekidane bridove pa `calls`/`mints`/`burns` bridovi postoje samo u
  vieweru; u DBML idu samo bridovi usidreni na kolonu.
