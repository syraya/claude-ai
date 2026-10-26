import SwiftUI
import AuthenticationServices
import FamilyControls

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(AuthService.self) private var auth
    @Environment(ScreenTimeAuthorizer.self) private var screenTime

    @State private var showTrackedPicker = false
    @State private var editingName = ""
    @State private var showDeleteAccount = false

    var body: some View {
        @Bindable var settings = settings
        @Bindable var auth = auth

        NavigationStack {
            Form {
                Section {
                    Picker("Reflection wait", selection: $settings.settings.reflectionSeconds) {
                        ForEach(AppSettings.reflectionOptions, id: \.self) { seconds in
                            Text("\(seconds) seconds").tag(seconds)
                        }
                    }
                    Picker("Default break", selection: $settings.settings.defaultBreakMinutes) {
                        ForEach(AppSettings.breakOptions, id: \.self) { minutes in
                            Text("\(minutes) min").tag(minutes)
                        }
                    }
                    Stepper {
                        Text("Breaks per session: \(settings.settings.hasUnlimitedBreaks ? "Unlimited" : "\(settings.settings.maxBreaksPerSession)")")
                    } onIncrement: {
                        let count = settings.settings.maxBreaksPerSession
                        guard count != FocusSession.unlimitedBreaks else { return }
                        settings.settings.maxBreaksPerSession = count >= AppSettings.maxBreakSteps
                            ? FocusSession.unlimitedBreaks : count + 1
                    } onDecrement: {
                        let count = settings.settings.maxBreaksPerSession
                        settings.settings.maxBreaksPerSession = count == FocusSession.unlimitedBreaks
                            ? AppSettings.maxBreakSteps : max(1, count - 1)
                    }
                } header: {
                    Text("Breaks")
                } footer: {
                    Text("Before any break starts you'll sit through the reflection wait. Long enough to ask yourself if you really want it. Unlimited still makes you wait every time.")
                }

                Section {
                    Toggle("Block deleting apps while locked", isOn: $settings.settings.preventAppDeletionWhenLocked)
                } header: {
                    Text("Study sessions")
                } footer: {
                    Text("While a friend holds your key, iOS won't let you delete apps, including OMO. Makes it much harder to cheat your way out.")
                }

                Section {
                    Toggle("Share screen time with friends", isOn: $settings.settings.shareScreenTimeWithFriends)
                        .onChange(of: settings.settings.shareScreenTimeWithFriends) { _, _ in
                            Task { await StatsSyncService.upload() }
                        }
                    Button {
                        showTrackedPicker = true
                    } label: {
                        HStack {
                            Text("Apps to count")
                            Spacer()
                            Text(trackedSummary).foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Screen time")
                } footer: {
                    Text("Friends see roughly how long you spent in these apps today (in 15-minute steps). Your focus time is always shared with friends.")
                }

                Section("Account") {
                    if auth.isSignedIn {
                        HStack {
                            TextField("Your name", text: $editingName)
                                .onSubmit { Task { await auth.updateDisplayName(editingName) } }
                            if editingName != auth.displayName {
                                Button("Save") { Task { await auth.updateDisplayName(editingName) } }
                            }
                        }
                        if let code = auth.profile?.friendCode {
                            LabeledContent("Friend code", value: code)
                        }
                        Button("Sign out") { auth.signOut() }
                        Button("Delete account", role: .destructive) { showDeleteAccount = true }
                    } else {
                        Text("Sign in from the Friends tab to add friends and study together.")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Permissions") {
                    LabeledContent("Screen Time", value: screenTime.isApproved ? "Allowed" : "Not allowed")
                    if !screenTime.isApproved {
                        Button("Allow Screen Time access") { Task { await screenTime.request() } }
                    }
                    Button("Notification settings") {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }

                Section {
                    Link("Privacy policy", destination: URL(string: "https://example.com/omo/privacy")!)
                    LabeledContent("Version",
                                   value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                } footer: {
                    Text("OMO never sees which apps you block. Apple hands us anonymous tokens instead of app names.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(OmoBackground())
            .navigationTitle("Settings")
            .familyActivityPicker(isPresented: $showTrackedPicker, selection: $settings.trackedSelection)
            .onAppear { editingName = auth.displayName }
            .onChange(of: auth.profile?.displayName) { _, name in editingName = name ?? "" }
            .sheet(isPresented: $showDeleteAccount) { DeleteAccountView() }
            .errorAlert($auth.errorMessage)
        }
    }

    private var trackedSummary: String {
        let selection = settings.trackedSelection
        let count = selection.applicationTokens.count + selection.categoryTokens.count + selection.webDomainTokens.count
        return count == 0 ? "None" : "\(count) selected"
    }
}

private struct DeleteAccountView: View {
    @Environment(AuthService.self) private var auth
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.xmark")
                .font(.system(size: 56))
                .foregroundStyle(.red)
            Text("Delete your account?")
                .font(.omoSerif(.title2, weight: .bold))
            Text("This removes your profile, friends and shared stats for good. Your block lists and solo sessions stay on this phone. Confirm with Apple to continue.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            SignInWithAppleButton(.continue) { request in
                auth.prepare(request)
            } onCompletion: { result in
                Task {
                    if await auth.deleteAccount(result) { dismiss() }
                }
            }
            .signInWithAppleButtonStyle(OmoCompanion.current.isDark ? .white : .black)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .disabled(auth.isWorking)

            if let error = auth.errorMessage {
                Text(error).font(.footnote).foregroundStyle(.red).multilineTextAlignment(.center)
            }

            Button("Cancel") { dismiss() }
        }
        .padding(28)
        .presentationDetents([.medium])
    }
}
