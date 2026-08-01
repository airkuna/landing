# Handoff #05 — Doc-stranice i Mermaid: skaliranje, timeline, zamke

> Napisano 01.08.2026. pri izradi `org/licenciranje/` + `org/en/licensing/`.
> Ovo NIJE brief za jedan zadatak nego **ponovljiv pattern** — pročitaj prije nego
> dodaš novu doc-stranicu s dijagramima na `com/` ili `org/`.
> Nadopunjuje [#03 Vizualizacija problema](03-viz-mermaid-problems.md) i memoriju
> `reference-airkuna-landing-design.md`.

---

## 1. Najveća zamka: Mermaid stišće SVG, font postane nečitljiv

Mermaid renderira SVG s `viewBox="0 0 <naturalW> <naturalH>"` i `style="max-width:<naturalW>px"`.
Ako je kontejner uži od `naturalW`, **cijeli SVG se skalira dolje** — uključujući font.
Na doc-stranici je tekstualni stupac `.doc{max-width:900px}` → sadržajna širina **852 px**,
pa je LR dijagram od 1800 px prirodne širine skaliran na **0,45** i 15 px font renderira
kao **~7 px**. Izgleda uredno na screenshotu punog page-a, a nečitljivo je u praksi.

**Dijagnostika (uvijek pokreni prije nego kažeš „gotovo"):**

```js
[...document.querySelectorAll('.figure svg')].map((s,i)=>{
  const nat = parseFloat(s.getAttribute('viewBox').split(/\s+/)[2]);
  const w   = s.getBoundingClientRect().width;
  return {i, nat: Math.round(nat), rendered: Math.round(w), scale: +(w/nat).toFixed(2)};
})
```

Cilj: **scale ≥ 0,8** na desktopu. Ispod 0,7 je nečitljivo.

### Tri poluge, ovim redom

**a) `.bleed` — dijagram izlazi iz tekstualnog stupca na punu širinu.**
Najjeftiniji dobitak (852 → 1092 px, tj. +28 %). Radi i za široke tablice.

```css
.bleed{width:min(1140px,calc(100vw - 40px));margin-left:50%;transform:translateX(-50%)}
```

Primijeni na `.figure` **i** `.tblwrap`. `overflow-x:auto` na `.figure` i dalje radi
unutar transformiranog elementa.

**b) TD umjesto LR.** Desktop ima beskonačno vertikale i ograničenu horizontalu.
Lanac od 6 čvorova u LR-u je ~1800 px širok; isti lanac u TD-u je ~500 px širok.
Ako dijagram nije prirodno horizontalan (tok novca jest, ljestvica/lanac nije) — TD.

**c) Kratke labele u romboidima.** Mermaid rombu (`{"..."}`) daje ogromnu visinu po
retku teksta. Pitanje u 3 retka → dijagram od 3000 px visine; isto pitanje u 2 kratka
retka → 1400 px. Duži tekst premjesti u prozu ili caption, ne u čvor.

### Pod skaliranja (JS, nakon renderiranja)

Kad ni to nije dovoljno — osobito na mobitelu, gdje je kontejner 350 px — bolje je da
dijagram **horizontalno scrolla** nego da se stisne. Postavi pod od 78 %:

```html
<script type="module">
import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';
mermaid.initialize({startOnLoad:false, /* … */});
await mermaid.run();                       // ⚠ startOnLoad MORA biti false, inače dupli render
document.querySelectorAll('.figure .mermaid svg').forEach(function(svg){
  var natural = parseFloat((svg.getAttribute('viewBox')||'').split(/\s+/)[2]);
  if (natural > 0) svg.style.minWidth = Math.round(natural * 0.78) + 'px';
});
</script>
```

`min-width` je pod, `max-width` (koji mermaid sam postavi) je strop → na širokom
ekranu se ništa ne mijenja, na uskom dijagram scrolla unutar `.figure`.
**Ovo zamjenjuje** stari fiksni `@media(max-width:640px){.figure .mermaid svg{min-width:520px}}`
pattern, koji je za široke dijagrame davao scale 0,3.

Uz to na uskim ekranima treba `justify-content:flex-start` (inače je centrirani
dijagram odsječen s obje strane):

```css
@media(max-width:900px){.figure{padding:20px 12px}.figure .mermaid{justify-content:flex-start}}
```

---

## 2. Mermaid `timeline` — radi, ali ima dvije zamke

`timeline` je dobar za regulatorne rokove. Sintaksa:

```
timeline
  30.12.2024. : Prvi događaj : drugi redak istog razdoblja
  10.06.2025. : …
```

- **Naslov (`title …`) se renderira kao `<text>` BEZ klase, s bijelim `fill`** →
  nevidljiv je na bijeloj `.figure` kartici. Nema ga kako pouzdano ciljati CSS-om
  a da ne pogodiš ostale tekstove. **Rješenje: ne koristi `title`** — naslov ide
  u `<h2>` iznad ili u `.cap` ispod.
- **Boje razdoblja idu preko `cScale*` / `cScaleLabel*` theme varijabli**, ne preko
  `classDef`. Bez njih dobiješ mermaid default paletu (pastelno, izvan brenda):

```js
themeVariables:{
  cScale0:'#002F6C',cScaleLabel0:'#ffffff', cScale1:'#C8912A',cScaleLabel1:'#ffffff',
  cScale2:'#0A3B82',cScaleLabel2:'#ffffff', cScale3:'#1A7A3C',cScaleLabel3:'#ffffff',
  cScale4:'#C0181C',cScaleLabel4:'#ffffff', cScale5:'#5B6B82',cScaleLabel5:'#ffffff'}
```

- Svaki stupac (razdoblje) dodaje ~230 px prirodne širine. **6 stupaca ≈ 1390 px**
  (scale 0,79 u `.bleed` kontejneru), 7 stupaca ≈ 1590 px (scale 0,69 — premalo).
  Ako ne stane, izbaci najmanje važan događaj i spomeni ga u captionu.

---

## 3. Ostale zamke potvrđene u ovoj sesiji

- **`white-space:nowrap` na pill/chip elementima širi grid stupac.** EN prijevod
  („technical service provider (PSD2 art. 3(j))") bio je ~50 px duži od hrvatskog
  i gurnuo karticu na 396 px pri viewportu od 390. Fiks:
  `@media(max-width:640px){.chip{white-space:normal}}` + `min-width:0` na SVIM
  grid/flex djecom (`.row>*,.grid>*,.lvl>*,.scnhead>*{min-width:0}`).
  **HR verzija prolazi, EN pada** — provjeri obje.
- **Sticky header prekriva naslov na koji se skoči preko `#anchor`.**
  `.prose h2[id],.prose p[id]{scroll-margin-top:86px}`.
- **Kontrast-audit skripta ima lažno pozitivne rezultate.** Elementi s
  `background: linear-gradient(...)` imaju `background-color: transparent`, pa
  skripta koja traži prvog roditelja s bojom pronađe bijelu karticu ispod i prijavi
  „bijeli tekst na bijelom". Za `.dochero`, `.goldbox`, `.lvl .n` i sl. potvrdi
  screenshotom prije nego popravljaš.
- **`perl -i -pe 's/\x{ad}//g'` uništi UTF-8 fajl.** Bez `-CSD` perl radi po
  bajtovima i obriše bajt `0xAD` koji je dio višebajtnog niza (`U+00AD` = `C2 AD`),
  ostavljajući siroti `C2`. Za bilo kakvu zamjenu u HTML-u s dijakriticima
  **koristi python s `encoding='utf-8'`**, ne perl/sed.

---

## 4. Checklist za novu doc-stranicu

1. Kopiraj strukturu iz `org/licenciranje/index.html` (najnoviji pattern):
   sticky header + hamburger **drawer** (doc-stranice bez drawera nemaju navigaciju
   na mobitelu), `.langsw` u navigaciji **i** u draweru, `.dochero`, `<article class="prose">`.
2. `rel=canonical` + 3 × `rel=alternate hreflang` (hr / en / x-default→hr).
   HR na korijenu, EN pod `/en/` s engleskim slugom.
3. `coin.svg` kopiraj u folder stranice (folderi su samodostatni).
4. Linkaj stranicu iz **navigacije i podnožja** obiju naslovnica (HR i EN).
5. Verifikacija prije deploya, na `python3 -m http.server`:
   - skripta iz §1 → svi dijagrami `scale ≥ 0,8` na 1280 px
   - `[...document.querySelectorAll('.mermaid')].filter(m=>!m.querySelector('svg')).length === 0`
   - `document.documentElement.scrollWidth === clientWidth` na **1265 px i 390 px**,
     za **obje** jezične verzije (EN nav i EN chipovi su širi)
   - konzola bez grešaka; kontrast provjeren okom na tamnim sekcijama
   - HR: nula ASCII navodnika u prozi (regexom, uz preskakanje `<script>`, `<style>`,
     `<div class="mermaid">` i atributa) — samo `„…"`
6. Deploy: wrangler **iz direktorija bez `.env`**, apsolutna putanja na `org/` ili `com/`
   (vidi memoriju `reference-airkuna-web-deploy.md`). Nakon deploya provjeri live URL
   s `?cb=<rand>` — edge cache zna servirati staru verziju ~1 min.
