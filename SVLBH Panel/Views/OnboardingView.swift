// SVLBHPanel — Views/OnboardingView.swift
// Refonte 2026-05-06 : Apple Sign-In + Google placeholder uniquement.
// Aucune saisie texte. Pas d'auto-sign-in : l'utilisateur doit cliquer.

import SwiftUI
import AuthenticationServices

struct OnboardingView: View {
    @EnvironmentObject var identity: PractitionerIdentity
    @EnvironmentObject var session: SessionState

    @State private var error = ""

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Text("◈ SVLBH Panel")
                    .font(.title.bold()).foregroundColor(Color(hex: "#8B3A62"))
                Text("hDOM · Corps de Lumière")
                    .font(.subheadline).foregroundColor(.secondary)
            }

            VStack(spacing: 16) {
                Text("Connexion")
                    .font(.headline).foregroundColor(Color(hex: "#8B3A62"))

                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    switch result {
                    case .success(let auth):
                        guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else { return }
                        let userID = credential.user
                        let email = credential.email
                        let fullName = credential.fullName
                        Task {
                            await identity.identifyWithApple(
                                userID: userID,
                                email: email,
                                fullName: fullName
                            )
                            await MainActor.run {
                                if identity.isIdentified {
                                    identity.applyTo(session)
                                } else {
                                    error = "Compte Apple non reconnu. Contactez Patrick pour activer votre accès."
                                }
                            }
                        }
                    case .failure(let err):
                        error = err.localizedDescription
                    }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 48)
                .cornerRadius(10)

                // Google Sign-In : placeholder désactivé tant que l'OAuth iOS client ID
                // n'est pas configuré dans Google Cloud Console.
                Button {
                    error = "Sign in with Google : configuration en cours."
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "g.circle.fill")
                            .font(.title3)
                        Text("Sign in with Google")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.gray.opacity(0.5))
                    .cornerRadius(10)
                }
                .disabled(true)

                if !error.isEmpty {
                    Text(error)
                        .font(.caption.bold()).foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 4) {
                Text("Digital Shaman Lab · vlbh.energy")
                    .font(.caption2).foregroundColor(.secondary)
                Link(destination: URL(string: "https://orcid.org/0009-0007-9183-8018")!) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.text.rectangle")
                            .font(.system(size: 10))
                        Text("ORCID 0009-0007-9183-8018")
                            .font(.system(size: 10, design: .monospaced))
                    }
                    .foregroundColor(Color(hex: "#1D9E75"))
                }
            }
            .padding(.bottom, 20)
        }
        .background(
            LinearGradient(colors: [Color(hex: "#F5EDE4"), Color(hex: "#C27894").opacity(0.3)],
                          startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        )
    }
}
