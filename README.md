## Current release

- SPT 4.1.6 / EFT 0.16.9.40743
- Fika client 2.4.4; host server 2.4.2
- Native SPT/EFT PvE AI: SAIN and QuestingBots are not included
- PitFireTeam teammates retained; BigBrain and Waypoints remain only because
  PitFireTeam requires them
- Host provides eight lightweight named traders (Vektor, Brass, Mule, Sparks,
  Vita, Rook, Ledger, and Cipher), 1,164 offers, and 64 data-only story quests
- All original SPT/EFT traders remain intact; the host currently registers 23
  unique trader/service definitions with no ID collisions
- Includes a guarded SPT 4.1.6 port of Kaeno Trader Scrolling, which makes the
  oversized trader header horizontally scrollable and keeps cards clickable
- Includes the matching client pieces for custom content, UI fixes, maps,
  TraderGen, trader/weapon-builder search, Bright Lasers, and other active QOL
- SHA-256 manifest verification is included inside the pack

## Friend installation

1. Download the release ZIP through Git LFS.
2. Verify it with the adjacent `.sha256.txt` file if desired.
3. Extract the whole ZIP to a normal folder.
4. Run `INSTALL-FRIEND-PACK.cmd` and select a clean SPT 4.1.6 installation.
5. Enter the host address supplied privately in SPT Launcher.

## Maintainer workflow

Run `Multiplayer Setup/Pack Builder/BUILD-FRIEND-PACK.ps1` from the host install
after changing active client plugins. The builder creates a new expanded pack,
hashes every payload file, and writes a privacy-safe connection placeholder.
Update the versioned allowlist in `.gitignore`, verify the pack, create the ZIP,
then update its SHA-256 sidecar.

## Credit & Distribution

All of the mod packs are used from other developers. Delta does not take any credit for the development or creation/maintainer of these mods.
We support all creators of all mods and additions we use. 
