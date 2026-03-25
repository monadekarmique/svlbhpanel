// SVLBHPanel — Views/ProvocationView.swift
// v4.8.0 — Classification des énergies parasitaires — 3 permanentes + 5 temporaires

import SwiftUI

struct ProvocationView: View {
    /// 3 sélections permanentes (gauche)
    @State private var permanentSelections: [Int?] = [nil, nil, nil]
    /// 5 sélections temporaires (droite)
    @State private var temporarySelections: [Int?] = [nil, nil, nil, nil, nil]

    var body: some View {
        VStack(spacing: 12) {
            // Header
            VStack(spacing: 4) {
                Text("Énergies Parasitaires")
                    .font(.subheadline.bold())
                    .foregroundColor(Color(hex: "#8B3A62"))
                Text("\(ParasiteEnergyData.permanentes.count) permanentes · \(ParasiteEnergyData.temporaires.count) temporaires")
                    .font(.caption2).foregroundColor(.secondary)
            }
            .padding(.top, 8)

            HStack(alignment: .top, spacing: 10) {
                // ── Colonne gauche : 3 × Permanentes ──
                VStack(spacing: 8) {
                    HStack {
                        Text("PERMANENT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(EnergyType.permanent.color)
                            .cornerRadius(5)
                        Spacer()
                    }

                    ForEach(0..<3, id: \.self) { idx in
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
                        Text("TEMPORAIRE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(EnergyType.temporary.color)
                            .cornerRadius(5)
                        Spacer()
                    }

                    ForEach(0..<5, id: \.self) { idx in
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
    @State private var isExpanded = false

    private var selectedEnergy: ParasiteEnergy? {
        guard let idx = selection else { return nil }
        return energies.first { $0.numero == idx }
    }

    private var bgColor: Color {
        colorScheme == .dark
            ? Color(UIColor.secondarySystemBackground)
            : Color(UIColor.secondarySystemBackground)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── Menu déroulant ──
            Menu {
                Button("— Aucune —") { selection = nil }
                ForEach(energies) { energy in
                    Button {
                        selection = energy.numero
                    } label: {
                        Text("\(energy.numero). \(energy.description)")
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text("\(slotIndex + 1)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(type.color)
                        .frame(width: 18)
                    if let energy = selectedEnergy {
                        Text(energy.description)
                            .font(.system(size: 11))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    } else {
                        Text("Sélectionner…")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 9))
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
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(type.color)

                    // Dimensions à vérifier
                    HStack(spacing: 4) {
                        Text(type == .temporary ? "D2" : energy.niveau)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(type.color)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(type.color.opacity(0.15))
                            .cornerRadius(5)
                        Text("à vérifier")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }

                    // Recommandation
                    Text(energy.liberation)
                        .font(.system(size: 11))
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
