import SwiftUI
import AuthenticationServices

/// Shown on the Friends and Circle tabs until you sign in.
struct SignInCard: View {
    @Environment(AuthService.self) private var auth
    var reason: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.omoPrimary.gradient)
            Text("Many minds, one focus")
                .font(.omoSerif(.title2, weight: .bold))
            Text(reason)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if auth.isAvailable {
                SignInWithAppleButton(.signIn) { request in
                    auth.prepare(request)
                } onCompletion: { result in
                    Task { await auth.completeSignIn(result) }
                }
                .signInWithAppleButtonStyle(OmoTheme.current.isDark ? .white : .black)
                .frame(height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .disabled(auth.isWorking)

                Text("We only use your first name, which you can change. Solo sessions work without an account.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Friends aren't set up in this build yet. Add GoogleService-Info.plist (see README) to turn them on.")
                    .font(.footnote)
                    .foregroundStyle(Color.omoGold)
                    .multilineTextAlignment(.center)
            }
        }
        .card()
    }
}
