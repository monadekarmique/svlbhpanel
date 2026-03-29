// SVLBHPanel — Views/ProvocationView.swift
// v4.8.0 — Classification des énergies parasitaires — 3 permanentes + 5 temporaires

import SwiftUI

struct ProvocationView: View {
    @EnvironmentObject var session: SessionState
    /// 5 sélections permanentes (gauche)
    @State private var permanentSelections: [Int?] = [nil, nil, nil, nil, nil]
    /// 14 sélections temporaires (droite)
    @State private var temporarySelections: [Int?] = Array(repeating: nil, count: 14)

    var body: some View {
        VStack(spacing: 12) {
            // Header + compteur validées
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Énergies Parasitaires")
                        .font(.title3.bold())
                        .foregroundColor(Color(hex: "#8B3A62"))
                    Text("\(ParasiteEnergyData.permanentes.count) permanentes · \(ParasiteEnergyData.temporaires.count) temporaires")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                // Compteur validées / affichées (côté droit)
                VStack(spacing: 2) {
                    Text("\(session.validatedCount)/\(session.visibleGenerations.count)")
                        .font(.title2.bold())
                        .foregroundColor(Color(hex: "#1D9E75"))
                    Text("validées")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            HStack(alignment: .top, spacing: 10) {
                // ── Colonne gauche : 3 × Permanentes ──
                VStack(spacing: 8) {
                    HStack {
                        Text("PERMANENTES (48)")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(EnergyType.permanent.color)
                            .cornerRadius(5)
                        Spacer()
                    }

                    ForEach(0..<5, id: \.self) { idx in
                        EnergyPickerSlot(
                            slotIndex: idx,
                            selection: $permanentSelections[idx],
                            energies: ParasiteEnergyData.permanentes,
                            type: .permanent
                        )
                    }
                }
                .frame(maxWidth: .infinity)

                // ── Colonne droite : 5 × Temporaires ──
                VStack(spacing: 8) {
                    HStack {
                        Text("TEMPORAIRES (19)")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(EnergyType.temporary.color)
                            .cornerRadius(5)
                        Spacer()
                    }

                    ForEach(0..<14, id: \.self) { idx in
                        EnergyPickerSlot(
                            slotIndex: idx,
                            selection: $temporarySelections[idx],
                            energies: ParasiteEnergyData.temporaires,
                            type: .temporary
                        )
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 12)
        }
    }
}

// MARK: - Slot picker individuel

struct EnergyPickerSlot: View {
    let slotIndex: Int
    @Binding var selection: Int?
    let energies: [ParasiteEnergy]
    let type: EnergyType
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var tracker: SessionTracker

    private var selectedEnergy: ParasiteEnergy? {
        guard let idx = selection else { return nil }
        return energies.first { $0.numero == idx }
    }

    private var bgColor: Color {
        Color(UIColor.secondarySystemBackground)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── Menu déroulant ──
            Menu {
                Button("— Aucune —") { selection = nil }
                ForEach(energies) { energy in
                    Button {
                        selection = energy.numero
                        tracker.logProvocation(energy)
                    } label: {
                        Text("\(energy.numero). \(energy.description)")
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text("\(selectedEnergy?.numero ?? (slotIndex + 1))")
                        .font(.caption.bold().monospaced())
                        .foregroundColor(type.color)
                        .frame(width: 24)
                    if let energy = selectedEnergy {
                        Text(energy.description)
                            .font(.caption.bold())
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    } else {
                        Text("Sélectionner…")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11))
                        .foregroundColor(type.color.opacity(0.6))
                }
                .padding(.horizontal, 8).padding(.vertical, 8)
                .background(bgColor)
                .cornerRadius(8)
            }

            // ── Détails si sélectionné ──
            if let energy = selectedEnergy {
                VStack(alignment: .leading, spacing: 4) {
                    // Nom en couleur (violet/vert)
                    Text(energy.nom)
                        .font(.caption.bold())
                        .foregroundColor(type.color)

                    // Dimensions à vérifier
                    HStack(spacing: 4) {
                        Text(type == .temporary ? "D2" : energy.niveau)
                            .font(.caption.bold())
                            .foregroundColor(type.color)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(type.color.opacity(0.15))
                            .cornerRadius(5)
                        Text("à vérifier")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Recommandation
                    Text(energy.liberation)
                        .font(.caption)
                        .foregroundColor(.primary.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 8).padding(.vertical, 6)
                .background(type.color.opacity(0.05))
                .overlay(
                    Rectangle()
                        .fill(type.color)
                        .frame(width: 2),
                    alignment: .leading
                )
                .cornerRadius(6)
                .padding(.top, 2)
            }
        }
    }
}
