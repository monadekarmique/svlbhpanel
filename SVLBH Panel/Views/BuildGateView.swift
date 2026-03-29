// SVLBHPanel — Views/BuildGateView.swift
// Écran bloquant si le build est trop ancien (> 5 builds de retard)

import SwiftUI

struct BuildGateView: View {
    let status: BuildGateService.BuildStatus

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "arrow.down.app.fill")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "#E24B4A"))

            Text("Mise à jour requise")
                .font(.title.bold())
                .foregroundColor(.primary)

            Text("Votre version (build \(status.currentBuild)) est trop ancienne.\nLe dernier build est le \(status.latestBuild).")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)

            Text("Veuillez mettre à jour via TestFlight.")
                .font(.callout.bold())
                .foregroundColor(Color(hex: "#8B3A62"))

            // Lien direct TestFlight
            Link(destination: URL(string: "itms-beta://")!) {
                HStack {
                    Image(systemName: "airplane")
                    Text("Ouvrir TestFlight")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(Color(hex: "#007AFF"))
                .cornerRadius(12)
            }

            Spacer()

            Text("Build \(status.currentBuild) · Minimum requis : \(status.latestBuild - 4)")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
        }
    }
}
