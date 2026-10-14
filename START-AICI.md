# Bounty Escrow — ce este gata

Pachetul conține contractul Rust AVM, receptorul de test, codul sursă, artefactele
WASM/ABI/descriptor și dovezile verificărilor locale.

- 35 teste ale proiectului și 13 teste ale SDK-ului au trecut.
- Ambele contracte sunt construite de compilatorul oficial AVM, cu verificarea
  reproductibilității.
- Testul AVM local verifică plăți și rambursări refuzate, reîncercări, operații
  neautorizate, operații repetate și protejarea etapelor aprobate după termen.
- La final: 1.000 unități locale depuse = 700 plătite + 300 rambursate.
- Replay-ul produce aceleași rădăcini și costuri.

Acestea sunt fonduri simulate local. Proiectul este un exemplu pentru SDK, cu
maximum 8 etape și 64 încercări de transfer. Nu este auditat pentru fonduri reale.

Pentru Codex pe Windows: extrage arhiva într-un proiect separat și folosește WSL2
(Linux x86-64). Instrucțiunile exacte sunt în `README.md`. Comanda de verificare
este `bash scripts/check.sh` după instalarea mediului descris acolo.

Următorul pas pentru participarea la oferta din postare este publicarea codului
într-un repository GitHub și trimiterea linkului. Descrierea pentru dezvoltatori
este pregătită în `docs/SDK-INTEGRATION.md`. Pachetul nu a fost publicat și nu a
fost trimis nimănui.

Compatibilitatea a fost verificată cu SDK 0.2.0 și guest SDK 0.1.1, într-un stand local nou.
