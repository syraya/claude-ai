# Lockstep

A Screen Time blocker for iPhone that you can use with friends.

- **Block lists.** Pick the apps, categories and websites to block, and save as many named lists as you want ("Social", "Games", …).
- **Focus sessions.** Choose a list and a length, and those apps are locked until time's up. Strict mode means no ending early.
- **Breaks with a reflection wait.** Before a break starts you sit through a short countdown (5–60 seconds, your choice) with a breathing circle and a question like *"Will this make the next hour better or worse?"*. Then you pick a break length and the apps re-lock on their own when it's over.
- **Friends.** Add each other with a 6-character friend code. See each other's focus time and roughly how long you spent on distracting apps, plus a daily leaderboard and a 7-day chart.
- **Study together.** Everyone joins a session with a 6-digit code (or an invite), the host starts it, and every phone locks. Each person's key is held by a friend, so with two people you hold each other's. **Only your keyholder can unlock you.** You can ask them for a break, and they can allow it, deny it, or unlock you for good.
- **Emergency exit.** If your keyholder's phone dies or they leave, you can unlock yourself after a 60-second wait. Your keyholder gets notified and everyone in the session sees it. iOS always leaves you some way out, so it's better to have an honest one.

---

## What's in this repo

```
project.yml                      Xcode project definition (XcodeGen)
Lockstep/                        The iPhone app (SwiftUI, iOS 17+)
  App/                           Entry point, push notifications, tab bar
  Features/                      Focus, Block Lists, Together, Friends, Settings, Onboarding
  Services/                      Firebase sign-in, friends, study sessions, stats sync
  Components/                    Shared UI: reflection screen, buttons, cards
Shared/                          Code used by both the app and its extensions
  FocusEngine.swift              The rules: start, break, end, friend locks
  ShieldManager.swift            Turns blocking on/off (ManagedSettings)
  ActivityScheduler.swift        Background timers (DeviceActivity)
Extensions/
  LockstepMonitor/               Ends sessions/breaks on time even when the app is closed
  LockstepShieldConfiguration/   The custom "this app is blocked" screen
  LockstepShieldAction/          The buttons on that screen
firebase/
  firestore.rules                Security rules (who can unlock whom)
  functions/                     Push notifications (Cloud Functions, TypeScript)
  rules-tests/                   Tests for the security rules
docs/APP_STORE.md                Checklist for getting it on the App Store
```

---

## Setup (on a Mac)

You need a Mac with **Xcode 16 or newer**, an **iPhone** (Screen Time blocking does not work in the simulator), and a free Apple ID to start. Publishing needs the paid Apple Developer Program ($99/year).

### 1. Generate the Xcode project

```bash
brew install xcodegen          # install Homebrew first if you don't have it: https://brew.sh
git clone <this repo>
cd claude-ai
```

Open `project.yml` and change the three lines under `settings > base`:

```yaml
DEVELOPMENT_TEAM: "ABCDE12345"              # Xcode › Settings › Accounts › your team › Team ID
APP_BUNDLE_ID: com.yourname.lockstep        # anything unique, reverse-domain style
APP_GROUP_ID: group.com.yourname.lockstep   # "group." + the bundle ID
```

Then:

```bash
xcodegen generate
open Lockstep.xcodeproj
```

Run `xcodegen generate` again whenever you add or remove files.

### 2. Try it without friends features first

Plug in your iPhone, pick it as the run destination, and press ▶︎. Solo sessions, block lists and breaks all work without Firebase. The Friends and Together tabs will say they're not set up yet.

> On first run, enable **Developer Mode** on the iPhone (Settings › Privacy & Security) and trust your developer certificate (Settings › General › VPN & Device Management).

### 3. Set up Firebase (friends + study sessions)

1. Go to [console.firebase.google.com](https://console.firebase.google.com), create a project, and **add an iOS app** with your `APP_BUNDLE_ID`.
2. Download **`GoogleService-Info.plist`**, put it in the `Lockstep/` folder, and run `xcodegen generate` again.
3. In the Firebase console:
   - **Authentication › Sign-in method:** enable **Apple**.
   - **Firestore Database:** create a database (production mode).
   - **Project settings › Cloud Messaging:** upload an **APNs Authentication Key**. Create the key at [developer.apple.com › Keys](https://developer.apple.com/account/resources/authkeys/list) with "Apple Push Notifications service" ticked.
4. Deploy the rules, indexes and push functions:

   ```bash
   npm install -g firebase-tools
   firebase login
   cd firebase
   firebase use --add                  # pick your project
   (cd functions && npm install)
   firebase deploy --only firestore    # rules + indexes
   firebase deploy --only functions    # push notifications
   ```

   Cloud Functions need the **Blaze (pay-as-you-go)** plan. Its free allowance easily covers a small app. Without functions everything still works while the app is open; you just don't get pushes, like "Sam unlocked your phone", when it's closed.

5. Optional: run the security-rule tests (needs Java):

   ```bash
   cd firebase/rules-tests && npm install && npm test
   ```

### 4. Test a study session

You need **two iPhones and two Apple IDs**. Sign in on both, add each other with friend codes, create a session on one, join with the code on the other, and tap **Lock everyone in**.

---

## How the locking works (and its limits)

- Blocking uses Apple's official Screen Time frameworks: **FamilyControls** for permission and the app picker, **ManagedSettings** to block, and **DeviceActivity** to wake up in the background when a timer ends. Apple never tells the app which apps you picked; it gets anonymous tokens.
- Each phone blocks its *own* chosen list. Your friend can lock and unlock your phone, but never sees or chooses which apps.
- When your keyholder taps **Unlock**, Firestore updates, a Cloud Function sends a push, and your phone lifts the block. If Lockstep is open this takes about a second; if it's closed, the push wakes it up.
- **The honest limit:** with individual Screen Time authorization, iOS always lets you turn off Lockstep's Screen Time access in Settings. No App Store app can fully prevent that, including Opus. To make it harder, Lockstep can stop apps from being deleted while a friend holds your key (Settings › Study sessions), and offers the emergency exit as the "honest" way out, which notifies your friend.
- **Screen time numbers for friends** are approximate (15-minute steps). Apple doesn't let apps read or upload exact Screen Time data, so Lockstep counts usage thresholds on the apps you choose to share.
- Short timers (under 15 minutes, like most breaks) use a workaround, because iOS won't schedule anything shorter. They can land up to about a minute late when the app is closed.
- One block list can include up to 50 individual apps (Apple's limit); use categories for more.

---

## Before the App Store

See **[docs/APP_STORE.md](docs/APP_STORE.md)**. The big one: you must request the **Family Controls (Distribution)** entitlement from Apple for the app *and* all three extensions. Do this early, because approval can take a while.
