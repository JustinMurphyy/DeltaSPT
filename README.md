# SPT 4.1.6 Fika native-AI client pack

This private distribution repo contains only the files a friend needs to match
the host's client-side SPT/Fika mod set. It intentionally excludes Escape from
Tarkov, SPT server files, user profiles, certificates, logs, disabled mods, and
the host's real connection address.

## Current release

`SPT-Fika-CLIENT-Pack-4.1.6-native-ai-client.4.zip`

- SPT 4.1.6 / EFT 0.16.9.40743
- Fika client 2.4.4; host server 2.4.2
- Native SPT/EFT PvE AI: SAIN and QuestingBots are not included
- PitFireTeam teammates retained; BigBrain and Waypoints remain only because
  PitFireTeam requires them
- Host provides eight lightweight named traders (Vektor, Brass, Mule, Sparks,
  Vita, Rook, Ledger, and Cipher), 1,164 offers, and 64 data-only story quests
- All original SPT/EFT traders remain intact; the host currently registers 23
  unique trader/service definitions with no ID collisions
- Includes a locally rebuilt SPT 4.1.6 Adjustable Trader Rows client fix,
  configured for eight cards per row so large rosters remain clickable
- Includes the matching client pieces for custom content, UI fixes, maps,
  TraderGen, trader/weapon-builder search, Bright Lasers, and other active QOL
- SHA-256 manifest verification is included inside the pack

## Friend installation

1. Download the release ZIP through Git LFS.
2. Verify it with the adjacent `.sha256.txt` file if desired.
3. Extract the whole ZIP to a normal folder.
4. Run `INSTALL-FRIEND-PACK.cmd` and select a clean SPT 4.1.6 installation.
5. Enter the host address supplied privately in SPT Launcher. Never publish it
   in this repository.

Only the host runs `SPT.Server`. Server-side traders, quests, loot additions,
and configuration are delivered by the host and are intentionally absent here.

## Maintainer workflow

Run `Multiplayer Setup/Pack Builder/BUILD-FRIEND-PACK.ps1` from the host install
after changing active client plugins. The builder creates a new expanded pack,
hashes every payload file, and writes a privacy-safe connection placeholder.
Update the versioned allowlist in `.gitignore`, verify the pack, create the ZIP,
then update its SHA-256 sidecar.

This repo is prepared locally with no commit and no remote. Create a private
GitHub repository under the owner's account, do not add collaborators with write
access, push `main`, and enable branch protection/rulesets after the first push.

