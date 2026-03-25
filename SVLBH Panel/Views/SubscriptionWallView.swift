// SVLBHPanel — Views/SubscriptionWallView.swift
// v4.8.0 — Écran de verrouillage abonnement expiré

import SwiftUI

struct SubscriptionWallView: View {
    let status: SubscriptionStatus
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "#8B3A62"))

            Text("Abonnement requis")
                .font(.title2.bold())
                .foregroundColor(Color(hex: "#8B3A62"))

            VStack(spacing: 8) {
                if status.status == "expired" {
                    Text("Votre abonnement a expiré le \(status.paidUntil)")
                        .font(.callout)
                        .foregroundColor(.secondary)
                } else {
                    Text("Accès non autorisé")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }

                Text("CHF 29 / mois")
                    .font(.title3.bold())
                    .foregroundColor(Color(hex: "#B8965A"))
            }

            VStack(spacing: 12) {
                Text("Pour renouveler votre abonnement :")
                    .font(.caption.bold()).foregroundColor(.secondary)

                // Twint
                HStack(spacing: 8) {
                    Image(systemName: "banknote")
                        .foregroundColor(Color(hex: "#1D9E75"))
                    Text("Twint : +41 79 813 19 26")
                        .font(.callout.monospaced())
                        .textSelection(.enabled)
                }

                // WhatsApp
                Link(destination: URL(string: "https://wa.me/41792168200?text=Bonjour%20Patrick%2C%20je%20souhaite%20renouveler%20mon%20abonnement%20SVLBH%20Panel.")!) {
                    HStack(spacing: 8) {
                        Image(systemName: "message.fill")
                            .foregroundColor(.white)
                        Text("Contacter Patrick sur WhatsApp")
                            .font(.callout.bold())
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "#25D366"))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            }

            Spacer()

            Button(action: onRetry) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text("Vérifier à nouveau")
                }
                .font(.caption.bold())
                .foregroundColor(Color(hex: "#8B3A62"))
            }
            .padding(.bottom, 8)

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
