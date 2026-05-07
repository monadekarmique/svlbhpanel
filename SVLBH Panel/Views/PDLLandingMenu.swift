// SVLBHPanel — Views/PDLLandingMenu.swift
// 2026-05-04 — Menu de premier niveau Palette/Séance/Décodage
// Affiché en haut de RoutineMatinTab et DecodageTab (demande Patrick).

import SwiftUI

struct PDLLandingMenu: View {
    @State private var pendingTab: PaletteDeLumiereView.PDLTab?

    var body: some View {
        VStack(spacing: 10) {
            menuButton(
                title: "Palette 5 éléments",
                subtitle: "Cercle Bois · Feu · Terre · Métal · Eau",
                icon: "paintpalette.fill",
                color: Color(hex: "#8B3A62"),
                tab: .palette
            )
            menuButton(
                title: "Séance",
                subtitle: "Conduire une séance énergétique",
                icon: "rays",
                color: Color(hex: "#BA7517"),
                tab: .seance
            )
            menuButton(
                title: "Décodage",
                subtitle: "Décoder l'arbre de transformation",
                icon: "tree.fill",
                color: Color(hex: "#1D9E75"),
                tab: .decodage
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .sheet(item: $pendingTab) { tab in
            PaletteDeLumiereView(initialTab: tab)
        }
    }

    @ViewBuilder
    private func menuButton(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        tab: PaletteDeLumiereView.PDLTab
    ) -> some View {
        Button { pendingTab = tab } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(color)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}

extension PaletteDeLumiereView.PDLTab: Identifiable {
    public var id: String { rawValue }
}
