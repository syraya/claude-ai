# OMO: where things stand (handoff for a new session)

Read this first, then `docs/APP_STORE_LISTING.md`.

## The app
- OMO, an iPhone focus app (SwiftUI, iOS 17+, XcodeGen `project.yml`, Firebase). Screen Time blocking through
  FamilyControls / ManagedSettings / DeviceActivity, with monitor, shield and Live Activity (OmoWidgets) extensions.
- Work happens on the branch `claude/busy-noether-s4gads`. The real checkout is on Hamza's Mac at
  `~/Claude Code/omo`; pull there with `git fetch origin claude/busy-noether-s4gads && git merge --ff-only FETCH_HEAD`,
  then run xcodegen (`~/Claude Code/tools/xcodegen/bin/xcodegen`) before building.
- Simulator demo screens: launch with `-OMODemo <screen> -OMODemoOMO <omo>` (focus, session, break, ended, scheduled,
  schedules, lifetime, omos, omos-preview, omos-swipe, omo-index, live, demo-mode, start-anim, end-anim).
  `-OMODemoPreview <omo>` picks which OMO the picker previews. If a notification alert covers the simulator, restart
  the simulator: it's a stuck system alert, not the app.

## App Store
- Version 1.0. **Build 7 is uploaded** (the next upload must be build 8; `project.yml` is already set to 8).
- Next step: submit build 7 in App Store Connect, following "Submitting build 7: step by step" in
  `docs/APP_STORE_LISTING.md`. Swap the attached build to 7, paste the promotional text, description and review
  notes from that doc, and upload the eight screenshots in `~/Claude Code/OMO App Store/App Store 6.3 inch/`.
- Hamza wants Claude to do the App Store Connect clicking with computer use (Claude desktop app, Settings → Computer
  use, with the Mac picked under + → Devices).
- The developer code for App Review is only in App Store Connect's review notes. Never write it into the repo.
- Still on Hamza: publish the Firestore rules (`firebase/firestore.rules`) if not done; check the `reports`
  collection daily.

## OMOs (33)
- Figures are vector SVGs in `Shared/Figures.xcassets`. Landscapes are figure-free paintings in
  `Omo/Resources/Breathing.xcassets`; the figure is drawn on top using the frames in
  `Omo/Components/BreathingScene.swift` (`placements`). A figure whose canvas changes needs its frame there updated.
- Hamza supplied his own art for Phoenix, Turtle Island, Nyx and Asteria; those are traced from it. Hestia is one
  solid shape. Holiday OMOs: Family Day (Hestia), Truth and Reconciliation (Turtle Island, spoken about quietly),
  Remembrance Day (Mnemosyne), Canadian Thanksgiving (Demeter).
- `docs/brand/OMO-Reference.pdf` is a reference sheet of every OMO (regenerate it after art changes).

## Preferences Hamza has given
- Wants the app as smooth as possible; no snapping transitions.
- Doesn't want videos of the simulator; screenshots are fine.
- Figures: solid colours, one flat style, nothing cropped or glitchy.
