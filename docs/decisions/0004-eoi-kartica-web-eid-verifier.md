# 0004 — eOsobna kartica preko Web eID-a (CAdES) kao verifier E

Status: Proposed
Informed-by: eidchain (open-source PoC, GPLv3; fork `github.com/stepanic/eidchain`), analiza 2026-11-03
Supersedes: —
Superseded-by: —

## Context

[0002](0002-pluggable-verifier.md) predviđa verifier **B. NFC eOI**: pasivnu autentikaciju čipa
eOsobne po uzoru na Rarimo/ICAO putovnice. U whitepaperu je to i dalje otvoreno pitanje
(„podržava li hrvatska eOsobna pasivnu autentikaciju čipa kao putovnica? (Provjeriti.)”).

eidchain je PoC lanac u Go-u u kojem **svaki zapis potpisuje eID kartica** i nema walleta ni
orakla. Koristi drugačiji, već isproban put prema istoj kartici:

- Browser preko **Web eID** ekstenzije (čitač kartice + middleware) traži od kartice potpis.
  Iz toga nastaje odvojeni **CAdES-B-B** potpis nad točnim bajtovima JSON zapisa.
- Svaki čvor sam provjerava potpis i lanac certifikata prema **CA-ovima zaključanim u
  genesisu** (AKDCA Root, HRIDCA za kartice prije svibnja 2025., HRIDCA 2025 za eOI 2.0).
  Valjanost se procjenjuje **u trenutku bloka** (RFC 3161 vremenski žig), pa je
  provjera deterministička i radi offline.
- `requireNonRepudiation` traži certifikat za potpisivanje (PIN2), a autentikacijski odbija.
- OCSP se provjerava jednom, pri predaji. Odgovor se sprema uz zapis, a ostali ga čvorovi
  provjeravaju offline.
- Identitet zapisa je `hash(payload, hash(certifikat))`, a ne bajtovi potpisa, jer treća
  strana može mijenjati potpis bez ključa (malleability).
- JSON se parsira strogo: duplicirani ključevi, ključevi koji se razlikuju samo u velikim i malim slovima
  i nepoznata polja se odbijaju.
- **Provjereno sa stvarnom karticom** (HRIDCA 2025): potpis u browseru, CAdES, lanac
  certifikata, OCSP od AKD-a i ponovna provjera iz genesisa. Starije HRIDCA kartice, opozvana
  kartica i kartice drugih zemalja još nisu isprobane.

Glavno ograničenje eidchaina autori sami navode: **osobni podaci su trajni**. CAdES potpis
nosi certifikat s imenom i u `subject.serialNumber` (`PNOHR-<OIB>`, ETSI EN 319 412-1) OIB, a
blok je javan i nepromjenjiv. Explorer skriva `serialNumber`, ali sirovi blok ga i dalje sadrži.
Upravo to [0001](0001-nullifier-registry.md) rješava nullifierom.

Ne preuzimamo eidchain kao lanac. Vlastiti PoA lanac znači vlastite validatore, slabu finalnost
i odvojenost od Gnosis/Safe ekosustava. Preuzimamo **izvor dokaza** i nekoliko pravila
provjere.

## Decision

Uvodimo **verifier E: eOsobna preko Web eID-a**, kao peti red tablice u
[0002](0002-pluggable-verifier.md). Postaje primarna MVP alternativa B-u dok se pasivna
autentikacija čipa ne potvrdi.

1. **Što građanin potpisuje.** Kartica potpisuje izjavu o vezivanju koja sadrži sve što bi
   inače bilo u EIP-712 domeni:
   `{type:"airkuna/personhood-claim/v1", chainId, registry, anchor, action: claim|migrate|reverify, seq, nonce, expiry}`.
   Bez `chainId`/`registry` potpis vrijedi na drugom lancu. eidchain svoje `chain` polje
   provjerava samo pri predaji, i to sam navodi kao slabost. Kod nas je to dio potpisanog sadržaja i
   provjerava se uvijek. `seq` dolazi iz [0005](0005-seq-anti-replay-i-rotacija-potpisnika.md).
2. **Gdje se provjerava.** CAdES, lanac i OCSP provjerava verifier van lanca (C sada, D kasnije).
   Onchain idu samo `nullifier`, `anchor`, `loa`, `expiry`, `seq`.
   **Certifikat, CAdES potpis i OCSP odgovor nikad ne idu onchain, ni u calldata.**
   Onchain provjera CAdES-a ionako nije praktična: HRIDCA 2025 je ECDSA **P-384**, a EVM
   prekompajlirani ugovori pokrivaju samo P-256 (RIP-7212 / EIP-7951). Uz to bi OIB završio u
   calldata.
3. **Nullifier iz certifikata.** OIB se uzima iz `subject.serialNumber` bez prefiksa `PNOHR-`
   i normalizira na isti oblik kao Certilia `sub`. **Ista osoba preko izvora A, C i E daje isti
   nullifier** (vidi normalizaciju u [0001](0001-nullifier-registry.md)).
4. **Pravila provjere preuzeta iz eidchaina:** zaključani skup AKD CA-ova (intermediate
   certifikati ugrađeni u potpis se ignoriraju); valjanost se procjenjuje u trenutku atestacije;
   OCSP mora biti „good” u tom trenutku; strogi JSON; podržani algoritmi RSA PKCS#1 v1.5
   i ECDSA sa SHA-2 (RSA-PSS ne).
5. **`expiry` atestacije ≤ `notAfter` certifikata** kartice.
6. **Koji certifikat (otvoreno, prijedlog):** certifikat za potpisivanje (PIN2,
   non-repudiation) je put koji je eidchain dokazao i daje izjavu pravne težine. To je ujedno
   i rizik: korisnik daje kvalificirani potpis, a to treba jasno reći u sučelju. Alternativa je
   autentikacijski certifikat (PIN1, Web eID `authenticate`) kod kojeg je `nonce` =
   `hash(izjave iz točke 1)`. Taj put još nitko nije isprobao. Odluka nakon testa obaju puteva na stvarnoj kartici.

## Consequences

- **+** Isti fizički dokument kao B, ali s **aktivnim potpisom** (posjed kartice + PIN). Ne oslanjamo se na
  pasivnu autentikaciju, koja ne štiti od kloniranog čipa. Dokazan end-to-end na HRIDCA 2025.
- **+** Dokaz se **sam provjerava**: svaki od M potpisnika u D može nezavisno provjeriti isti
  CAdES paket i ne mora vjerovati čvoru koji je vidio sesiju. Za Certilia OIDC to vrijedi slabije
  (bearer `id_token` s `aud` jednog klijenta). Time je mesh smisleniji, ne manje potreban.
- **+** Izvor neovisan o Certiliji (druga AKD usluga, drugi kanal). Druge EU kartice dolaze
  dodavanjem njihovih kvalificiranih CA-ova, bez promjene ugovora.
- **−** Korisniku trebaju čitač kartice, Web eID i middleware, a stranica mora biti na HTTPS-u.
  To je veliko trenje u odnosu na Certilia MobileID, pa je E alternativa, ne zamjena.
- **−** Verifier dok radi vidi OIB i ime iz certifikata. Vrijede ista pravila kao za `id_token`
  (odbaci nakon izračuna nullifiera, ne logiraj, vidi [0003](0003-pepper-custody.md)). Ako se
  CAdES paket čuva za reviziju, to je osobni podatak: treba mu rok čuvanja i pravna osnova.
- **−** Licenca: eidchain je GPLv3. Ako preuzmemo kod (`cades.js`, `der.js`, Go CAdES provjeru),
  na taj dio se primjenjuje GPLv3. Ideje i pravila se mogu preuzeti slobodno.
- **?** Treba provjeriti starije HRIDCA (RSA) kartice, opozvanu karticu i ponašanje OCSP-a za
  karticu kojoj je istekao rok.
