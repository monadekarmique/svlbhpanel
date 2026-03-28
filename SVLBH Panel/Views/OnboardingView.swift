// SVLBHPanel — Views/OnboardingView.swift
// v4.8.0 — Identification praticien + Sign in with Apple (Patrick)

import SwiftUI
import AuthenticationServices

struct OnboardingView: View {
    @EnvironmentObject var identity: PractitionerIdentity
    @EnvironmentObject var session: SessionState
    @State private var codeDraft = ""
    @State private var nameDraft = ""
    @State private var error = ""
    @State private var isCheckingPresence = false
    @State private var presenceBlocked = false
    @State private var pendingAppleUserID: String?
    @State private var showAppleLinkAlert = false

    private var codeInt: Int? { Int(codeDraft) }
    private var isValid: Bool {
        guard let n = codeInt else { return false }
        return (1...30000).contains(n) || n >= 455000
    }
    private var tierPreview: PractitionerTier? {
        guard let n = codeInt else { return nil }
        return PractitionerTier.from(code: n)
    }

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
                Text("Identification")
                    .font(.headline).foregroundColor(Color(hex: "#8B3A62"))

                VStack(alignment: .leading, spacing: 6) {
                    Text("Code praticien").font(.caption.bold()).foregroundColor(.secondary)
                    TextField("Ex: 300", text: $codeDraft)
                        .keyboardType(.numberPad)
                        .font(.title2.bold().monospaced())
                        .foregroundColor(isValid ? Color(hex: "#8B3A62") : .primary)
                        .padding(12)
                        .background(Color(hex: "#8B3A62").opacity(0.08))
                        .cornerRadius(10)
                }

                if let tier = tierPreview {
                    HStack {
                        Text(tier.label)
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color(hex: tier.badgeColor))
                            .cornerRadius(5)
                        Spacer()
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Prénom").font(.caption.bold()).foregroundColor(.secondary)
                    TextField("Votre prénom", text: $nameDraft)
                        .font(.body)
                        .padding(12)
                        .background(Color(hex: "#8B3A62").opacity(0.08))
                        .cornerRadius(10)
                }

                if !error.isEmpty {
                    Text(error)
                        .font(.caption.bold()).foregroundColor(.red)
                }

                Button {
                    guard isValid else {
                        error = "Code invalide (1–30000 ou 455000)"
                        return
                    }
                    guard !nameDraft.trimmingCharacters(in: .whitespaces).isEmpty else {
                        error = "Prénom requis"
                        return
                    }
                    let name = nameDraft.trimmingCharacters(in: .whitespaces)
                    let isLead = tierPreview == .lead
                    if isLead {
                        // Vérifier la capacité avant d'autoriser la connexion
                        isCheckingPresence = true
                        Task {
                            let status = await PresenceService.shared.check()
                            await MainActor.run { isCheckingPresence = false }
                            if status.maxReached {
                                await MainActor.run {
                                    presenceBlocked = true
                                    error = "Capacité maximale atteinte (\(status.activeCount)/\(status.maxAllowed) leads connectés)"
                                }
                            } else {
                                let leadId = PresenceService.shared.leadId
                                await PresenceService.shared.register(leadId: leadId, tier: "lead")
                                await MainActor.run {
                                    identity.identify(code: codeDraft, name: name)
                                    identity.applyTo(session)
                                }
                            }
                        }
                    } else {
                        identity.identify(code: codeDraft, name: name)
                        identity.applyTo(session)
                    }
                } label: {
                    HStack(spacing: 6) {
                        if isCheckingPresence { ProgressView().scaleEffect(0.7).tint(.white) }
                        Text(isCheckingPresence ? "Vérification…" : "Entrer")
                    }
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(isValid && !nameDraft.isEmpty && !presenceBlocked ? Color(hex: "#8B3A62") : Color.gray)
                    .cornerRadius(12)
                }
                .disabled(!isValid || nameDraft.trimmingCharacters(in: .whitespaces).isEmpty || isCheckingPresence || presenceBlocked)

                Text("Entrez votre code praticien et prénom, puis appuyez Entrer.\nOu utilisez la connexion rapide ci-dessous.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)

                // ── Sign in with Apple ──
                appleSignInSection
            }
            .padding(24)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
            .padding(.horizontal, 32)

            if identity.isAutoIdentifying {
                HStack(spacing: 8) {
                    ProgressView().tint(Color(hex: "#8B3A62"))
                    Text("Identification automatique…")
                        .font(.caption).foregroundColor(.secondary)
                }
            }

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
        .task {
            // Tenter l'auto-identification via vendorID au lancement
            await identity.autoIdentify()
            if identity.isIdentified { identity.applyTo(session) }
        }
        .alert("Lier votre compte Apple", isPresented: $showAppleLinkAlert) {
            TextField("Code praticien", text: $codeDraft).keyboardType(.numberPad)
            TextField("Prénom", text: $nameDraft)
            Button("Lier") {
                guard let userID = pendingAppleUserID,
                      let code = Int(codeDraft), (1...30000).contains(code) || code == 455000,
                      !nameDraft.trimmingCharacters(in: .whitespaces).isEmpty else {
                    error = "Code invalide"
                    return
                }
                let name = nameDraft.trimmingCharacters(in: .whitespaces)
                // Sauvegarder l'association Apple userID → code/nom
                UserDefaults.standard.set(userID, forKey: "svlbh_apple_user_id")
                UserDefaults.standard.set(codeDraft, forKey: "svlbh_apple_mapped_code")
                UserDefaults.standard.set(name, forKey: "svlbh_apple_mapped_name")
                identity.identify(code: codeDraft, name: name)
                identity.applyTo(session)
                pendingAppleUserID = nil
            }
            Button("Annuler", role: .cancel) { pendingAppleUserID = nil }
        } message: {
            Text("Votre compte Apple n'est pas encore lié. Entrez votre code praticien pour activer la connexion automatique.")
        }
    }

    // MARK: - Sign in with Apple
    private var appleSignInSection: some View {
        VStack(spacing: 8) {
            Divider().padding(.vertical, 4)
            Text("Connexion rapide")
                .font(.caption.bold()).foregroundColor(.secondary)

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                switch result {
                case .success(let auth):
                    guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else { return }
                    identity.identifyWithApple(
                        userID: credential.user,
                        email: credential.email,
                        fullName: credential.fullName
                    )
                    if identity.isIdentified { identity.applyTo(session) }
                    if !identity.isIdentified {
                        // Tenter l'auto-identification vendorID avant de demander code/prénom
                        let userID = credential.user
                        Task {
                            await identity.autoIdentify()
                            await MainActor.run {
                                if identity.isIdentified {
                                    // Lier le userID Apple pour les prochains lancements
                                    UserDefaults.standard.set(userID, forKey: "svlbh_apple_user_id")
                                    UserDefaults.standard.set(identity.code, forKey: "svlbh_apple_mapped_code")
                                    UserDefaults.standard.set(identity.displayName, forKey: "svlbh_apple_mapped_name")
                                    identity.applyTo(session)
                                } else {
                                    pendingAppleUserID = userID
                                    showAppleLinkAlert = true
                                }
                            }
                        }
                    }
                case .failure(let err):
                    error = err.localizedDescription
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 44)
            .cornerRadius(10)
        }
    }
}
