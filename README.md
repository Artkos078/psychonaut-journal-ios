# PsychonautWiki Journal — sideload build

Signing-ready build of the final archived GPL-3.0 iOS source edition (version 11.11).

## Enhancements

- Enables the complete built-in catalogue of 289 PsychonautWiki substances on first run.
- Imports native Journal exports and Dose Diary JSON backups.
- Normalizes common brand names, aliases, capitalization, misspellings, routes, and units.
- Groups Dose Diary records into timeline sessions using a 12-hour activity gap.
- Preserves unknown records by creating custom substances instead of dropping data.
- Keeps Journal timelines, statistics, interaction checks, tolerance charts, Face ID, offline data, and Live Activities.

The workflow checks out the archived upstream source at a pinned commit, applies `Patches/journal-enhancements.patch`, assigns the sideload bundle identifier, and produces an unsigned arm64 IPA.

Journal data remains stored locally on the device. This project is not the later proprietary/premium release and is not affiliated with or endorsed by PsychonautWiki or the original developer.
