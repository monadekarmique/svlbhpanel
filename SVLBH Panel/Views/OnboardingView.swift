// SVLBHPanel — Views/OnboardingView.swift
// v4.2.10 — Identification praticien au premier lancement

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var identity: PractitionerIdentity
    @EnvironmentObject var session: SessionState
    @State private var codeDraft = ""
    @State private var nameDraft = ""
    @State private var error = ""

    private var codeInt: Int? { Int(codeDraft) }
    private var isValid: Bool {
        guard let n = codeInt else { return false }
        return (1...30000).contains(n) || n == 455000
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
                    identity.identify(code: codeDraft, name: nameDraft.trimmingCharacters(in: .whitespaces))
                    identity.applyTo(session)
                } label: {
                    Text("Entrer")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isValid && !nameDraft.isEmpty ? Color(hex: "#8B3A62") : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!isValid || nameDraft.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(24)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
            .padding(.horizontal, 32)

            Spacer()

            Text("Digital Shaman Lab · vlbh.energy")
                .font(.caption2).foregroundColor(.secondary)
                .padding(.bottom, 20)
        }
        .background(
            LinearGradient(colors: [Color(hex: "#F5EDE4"), Color(hex: "#C27894").opacity(0.3)],
                          startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        )
    }
}
