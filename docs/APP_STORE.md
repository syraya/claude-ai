# Getting OMO on the App Store

Work through this list top to bottom. Items marked ⏳ take Apple days or weeks, so start them first.

## 1. Accounts and IDs

- [ ] Join the [Apple Developer Program](https://developer.apple.com/programs/) ($99/year). ⏳ Takes up to 48 hours.
- [ ] Check the App Store for other apps already called "OMO". Short names are often taken. App Store names must be unique, so you may need something like "OMO: Study & Focus" (the home screen can still say OMO).
- [ ] Set your real `DEVELOPMENT_TEAM`, `APP_BUNDLE_ID` and `APP_GROUP_ID` in `project.yml` and run `xcodegen generate`.
- [ ] In Xcode, let automatic signing register the 4 bundle IDs (app + `.monitor`, `.shieldconfiguration`, `.shieldaction`) and the App Group.

## 2. Family Controls entitlement ⏳

Screen Time apps need special permission to be distributed. Development builds on your own phone work without it.

- [ ] Request it at <https://developer.apple.com/contact/request/family-controls-distribution>.
- [ ] Submit a request for **each** of the 4 bundle IDs.
- [ ] Explain the app plainly: *"OMO is a self-control and study app. Users choose apps to block during focus sessions, and can join study sessions with friends where a friend must approve unlocking. We use individual authorization only."*
- [ ] Once approved, the "Family Controls" capability shows up as available for distribution in your provisioning profiles.

## 3. Push notifications

- [ ] Change `aps-environment: development` to `production` in `project.yml` for release builds. Xcode usually handles this when you archive, but double-check.
- [ ] Upload an APNs **Authentication Key** (.p8) in Firebase › Project settings › Cloud Messaging. One key covers both development and production.

## 4. Things App Review checks for this kind of app

- [x] **Sign in with Apple** is the only login, and it's optional (solo mode works without an account).
- [x] **Account deletion** is in the app (Settings › Delete account), and it revokes the Apple token, as Apple requires.
- [x] **Emergency exit.** Reviewers dislike apps that can trap users. Mention it in the review notes.
- [x] The app works without friends, so a reviewer can test it alone.
- [ ] **Privacy policy URL.** Host one (a free GitHub Pages or Notion page is fine) and replace `https://example.com/omo/privacy` in `SettingsView.swift`. A starting point is below.
- [ ] **Review notes.** Give the reviewer a demo flow. Suggested text:

  > OMO blocks apps the user chooses using the Screen Time API (individual authorization). To test solo: allow Screen Time access, choose apps, start a 15-minute session, try opening a blocked app, then tap "Take a break" to see the reflection countdown. Study sessions with friends need two devices signed in with Apple; a friend holds the key to unlock. Users can always leave with the 60-second "Emergency unlock", which notifies their friend.

## 5. App Store Connect listing

- [ ] Screenshots on a 6.9" iPhone (Focus session, reflection screen, Study Circle session, Friends leaderboard).
- [ ] Category: **Productivity** (secondary: Education).
- [ ] Age rating questionnaire: no objectionable content. User-generated content is limited to display names.
- [ ] **App Privacy ("nutrition label"):**
  - *Contact info › Name.* Linked to user, used for app functionality (display name).
  - *Identifiers › User ID.* Linked to user, app functionality.
  - *Usage data › Product interaction.* Linked to user, app functionality (focus minutes, breaks, approximate time in chosen apps, shared with friends).
  - No tracking, no ads, no data sold.
- [ ] Price: free, or set up in-app purchases later.

## 6. Ship it

- [ ] In Xcode: Product › Archive, then Distribute App › App Store Connect.
- [ ] Test with friends through **TestFlight** first, especially study sessions with the app closed on one phone.
- [ ] Submit for review.

---

## Privacy policy starter

> **OMO Privacy Policy**
>
> OMO helps you block distracting apps. Here's what we store and why.
>
> **On your phone only:** which apps you block. Apple gives OMO anonymous tokens, so even we can't see app names.
>
> **In our cloud database (Google Firebase), only if you sign in:** your first name (from Sign in with Apple, editable), a random friend code, your friends list, study sessions you join, and daily totals (focus minutes, sessions, breaks, and approximate minutes in apps you choose to share). Only you and your accepted friends can see your stats.
>
> **Push notifications:** we store a device token to tell you when a friend unlocks you or sends a request.
>
> We don't sell data, show ads, or track you across apps. Delete your account any time in Settings › Delete account, which removes everything above.
>
> Contact: *your email*
