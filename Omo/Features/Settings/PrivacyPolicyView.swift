import SwiftUI

/// OMO's privacy policy, shown in the app so it works without a website.
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("OMO helps you block distracting apps and study with friends. Here's what it keeps, where, and why.")
                    .font(.system(.body, design: .serif).italic())
                    .foregroundStyle(.secondary)

                section("On your phone only",
                        "Your block lists, schedules, focus sessions, settings, OMOs and lifetime totals stay on this phone. "
                        + "Apple gives OMO anonymous tokens for the apps you pick, so not even OMO can see their names.")

                section("In the cloud, only if you sign in",
                        "To make friends and Study Circles work, OMO stores these in Google Firebase: your first name "
                        + "(from Sign in with Apple, and you can change it), a random friend code, your friends list, "
                        + "the study sessions you join, and daily totals: focus minutes, sessions, breaks, and roughly "
                        + "how long you spent in the apps you choose to share. Only you and the friends you've accepted "
                        + "can see your stats.")

                section("Notifications",
                        "If you sign in, OMO stores a device token so it can tell you when a friend unlocks you or "
                        + "asks you for a break.")

                section("What OMO never does",
                        "No ads, no selling data, and no tracking you across other apps or websites.")

                section("Deleting your data",
                        "Settings › Delete account removes everything stored in the cloud. Deleting the app removes "
                        + "everything on your phone.")
            }
            .padding()
        }
        .background(OmoBackground())
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.omoSerif(.headline))
            Text(text).foregroundStyle(.secondary)
        }
        .card()
    }
}
