import SwiftUI
import FamilyControls
import UserNotifications

struct OnboardingView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(ScreenTimeAuthorizer.self) private var screenTime
    @Environment(BlockListStore.self) private var blockLists

    @State private var step = 0
    @State private var selection = FamilyActivitySelection()
    @State private var showPicker = false

    private var pickedCount: Int {
        selection.applicationTokens.count + selection.categoryTokens.count + selection.webDomainTokens.count
    }

    var body: some View {
        VStack(spacing: 24) {
            ProgressView(value: Double(step + 1), total: 4)
                .tint(.omoLapis)
                .padding(.top, 12)

            Spacer()

            switch step {
            case 0:
                page(icon: "building.columns.fill",
                     title: "OMO",
                     text: "thoughts of many\n\nBlock distractions, pause before you give in, and study alongside friends.")
            case 1:
                page(icon: "hourglass",
                     title: "Allow Screen Time access",
                     text: "OMO uses Apple's Screen Time to block apps. Your app list never leaves your phone; Apple doesn't even show us which apps you pick.")
            case 2:
                page(icon: "square.stack.3d.up.fill",
                     title: "What distracts you?",
                     text: pickedCount == 0
                        ? "Pick the apps, categories and websites you want blocked during focus sessions. You can make more lists later."
                        : "\(pickedCount) picked. Nice. You can change these any time in Block Lists.")
            default:
                page(icon: "bell.badge.fill",
                     title: "Stay in the loop",
                     text: "Notifications tell you when a session or break ends, and when a friend unlocks your phone or asks you for a break.")
            }

            Spacer()

            VStack(spacing: 12) {
                switch step {
                case 0:
                    Button("Begin") { step = 1 }
                        .buttonStyle(PrimaryButtonStyle())
                case 1:
                    Button(screenTime.isApproved ? "Access granted ✓" : "Allow Screen Time") {
                        if screenTime.isApproved {
                            step = 2
                        } else {
                            Task {
                                await screenTime.request()
                                if screenTime.isApproved { step = 2 }
                            }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    if let error = screenTime.errorMessage {
                        Text(error).font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                case 2:
                    Button(pickedCount == 0 ? "Choose apps" : "Change apps") { showPicker = true }
                        .buttonStyle(SecondaryButtonStyle())
                    Button("Continue") { step = 3 }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(pickedCount == 0)
                        .opacity(pickedCount == 0 ? 0.5 : 1)
                default:
                    Button("Turn on notifications") {
                        Task {
                            _ = try? await UNUserNotificationCenter.current()
                                .requestAuthorization(options: [.alert, .sound, .badge])
                            finish()
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    Button("Not now") { finish() }
                        .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
        .padding(24)
        .background(OmoBackground())
        .familyActivityPicker(isPresented: $showPicker, selection: $selection)
        .animation(.easeInOut, value: step)
    }

    private func page(icon: String, title: String, text: String) -> some View {
        VStack(spacing: 18) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(Color.omoLapis.gradient)
            Text(title)
                .font(.omoSerif(.largeTitle, weight: .bold))
                .multilineTextAlignment(.center)
            Text(text)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .transition(.opacity)
    }

    private func finish() {
        if pickedCount > 0 {
            blockLists.save(BlockList(name: "Distractions", emoji: "📱", selection: selection))
            if !settings.tracksAnything { settings.trackedSelection = selection }
        }
        settings.settings.hasCompletedOnboarding = true
    }
}
