# OMO: App Store listing

Everything to paste into App Store Connect. The screenshots are made from the app itself in
the simulator; see "Screenshots" at the end.

## App information

| Field | Value |
|---|---|
| Name (30) | OMO: Focus Together |
| Subtitle (30) | Block distractions, together |
| Bundle ID | com.hserieh.omo |
| SKU | omo-ios-001 |
| Primary category | Productivity |
| Secondary category | Education |
| Age rating | 4+ (answer "None" to every content question) |
| Price | Free |

If "OMO: Focus Together" is taken, try "OMO: Focus with Friends" or "OMO – Thoughts of Many".

## Promotional text (170, can change any time without review)

New: scheduled blocking. Lock your apps 9 to 5 on weekdays or every night at bedtime, and OMO turns the block on by itself, even when it's closed.

## Description (4000)

OMO blocks the apps that pull you away, and asks you to pause before you give in.

Pick the apps, categories and websites that distract you, choose how long to focus, and they stay locked until time's up. Write down what the session is for, and your intention shows on the timer and on the screen you see when you try to open a blocked app.

PAUSE BEFORE EVERY BREAK
Need a break? First you sit through a short reflection: a breathing circle and a question like "Will this make the next hour better or worse?" Often that's enough to change your mind. If not, pick a break length and your apps lock again on their own when it's over.

BLOCKS THAT RUN THEMSELVES
Set schedules like weekdays 9 to 5, school hours, or bedtime every night. OMO turns them on and off at the right time, even when the app is closed. Make a schedule strict and it can't be turned off until it ends.

STUDY TOGETHER
Start a Study Circle with friends and every phone locks. Each person's key is held by a friend, and only your keyholder can unlock you. Ask them for a break and they can allow it, deny it, or unlock you for good. If their phone dies, an emergency exit lets you out after a 60-second wait, and your keyholder is told.

FRIENDS WHO KEEP YOU HONEST
Add friends with a 6-character code. See each other's focus time and roughly how long you spent on distracting apps, with a daily leaderboard and a weekly chart.

WATCH YOUR FOCUS GROW
OMO keeps a running total of every hour you've focused since you started, with a chart over time, streaks, your longest session, and titles to earn on the way to 10,000 hours: Apprentice, Scholar, Master, Sage, Polymath.

EARN YOUR OMOs
29 companions from myths around the world: Athena's owl, the phoenix, Odin's ravens, the Salmon of Knowledge, the Simurgh and more. Each one brings its own color theme. Earn them with focus hours, streaks, friends and Study Circles, and some only on holidays.

PRIVATE BY DESIGN
OMO uses Apple's Screen Time framework. Apple never tells OMO which apps you picked; it only gets anonymous tokens. Your block lists and schedules stay on your phone. No ads, and no selling your data.

OMO: thoughts of many.

## Keywords (100)

study,screen time,app blocker,productivity,pomodoro,timer,detox,habit,school,limit,lock,phone

## URLs

| Field | Value |
|---|---|
| Support URL | https://syraya.github.io/claude-ai/ (docs/index.html, once GitHub Pages is on) |
| Privacy Policy URL | https://syraya.github.io/claude-ai/privacy.html (docs/privacy.html) |
| Marketing URL | Optional. |

Support email: omoikaneapp@gmail.com

## Copyright

2026 Hamza Serieh

## App Privacy (the "nutrition label")

OMO doesn't track users. Answer "No" to tracking. Data collected, all **linked to the user** and used only for **App Functionality**, and only if they sign in:

- **Contact Info › Name** (display name from Sign in with Apple)
- **Identifiers › User ID** (Firebase account ID)
- **Identifiers › Device ID** (push notification token)
- **Usage Data › Product Interaction** (daily focus minutes, sessions, breaks)
- **Usage Data › Other Usage Data** (approximate minutes in the apps a user chooses to share with friends)

Block lists, schedules and the apps people pick never leave the phone.

## Notes for App Review

> OMO blocks apps the user chooses, using the Screen Time API with individual authorization (Family Controls). To try it alone: allow Screen Time access, choose a few apps, start a 15-minute session, then open a blocked app to see the block screen. Tap "Take a break" in OMO to see the reflection countdown before a break. Block Lists › + › New schedule creates a block that turns on at set times.
>
> Study Circles and Friends need two devices signed in with Apple. In a Study Circle a friend holds your unlock key; anyone can leave with the 60-second emergency exit, which notifies their friend.
>
> Settings › Developer code unlocks every OMO theme for review: OMO-PX5T-QZN6. The themes are free; normally they unlock with focus time.

## Screenshots

Six screenshots for the "iPhone with Dynamic Island (medium display)" slot, 1206 × 2622 (6.3-inch), in this order:

1. Think before you scroll (Focus tab, Glaux)
2. Focus with intention (a session with its intention, Daphne)
3. Every break starts with a pause (the reflection wait, Nyx)
4. Blocks that run themselves (schedules, Noor)
5. Watch your focus grow (lifetime tracker)
6. Earn mythic companions (the OMO collection, Selene)

To make them again after the app changes, in the simulator, launch OMO with `-OMODemo <screen>` and `-OMODemoOMO <omo>` (screens: focus, session, break, schedules, lifetime, omos). The demo data exists only in simulator builds (`Omo/App/ScreenshotDemo.swift`). Save the captures as `raw/1-focus.png` … `raw/6-omos.png`, then run `swift make-frames.swift` (from `docs/app-store/`) in the folder that holds `raw/` to add the captions.
