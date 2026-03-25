// SVLBHPanel — Views/ProvocationView.swift
// v4.8.0 — Classification des énergies parasitaires — DisclosureGroup 2 colonnes

import SwiftUI

struct ProvocationView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var selectedSegment = 0 // iPhone: 0=permanent, 1=temporaire

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 4) {
                Text("Classification des Énergies Parasitaires")
                    .font(.subheadline.bold())
                    .foregroundColor(Color(hex: "#8B3A62"))
                Text("\(ParasiteEnergyData.permanentes.count) permanentes · \(ParasiteEnergyData.temporaires.count) temporaires")
                    .font(.caption2).foregroundColor(.secondary)
            }
            .padding(.vertical, 10)

            if sizeClass == .regular {
                // iPad : deux colonnes côte à côte
                twoColumnLayout
            } else {
                // iPhone : segment picker + une colonne
                phoneLayout
            }
        }
    }

    // MARK: - iPad : 2 colonnes

    private var twoColumnLayout: some View {
        HStack(alignment: .top, spacing: 12) {
            EnergyColumnView(
                energies: ParasiteEnergyData.permanentes,
                type: .permanent
            )
            EnergyColumnView(
                energies: ParasiteEnergyData.temporaires,
                type: .temporary
            )
        }
        .padding(.horizontal, 12)
    }

    // MARK: - iPhone : picker + colonne unique

    private var phoneLayout: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedSegment) {
                Text("Permanent (\(ParasiteEnergyData.permanentes.count))").tag(0)
                Text("Temporaire (\(ParasiteEnergyData.temporaires.count))").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            if selectedSegment == 0 {
                EnergyColumnView(
                    energies: ParasiteEnergyData.permanentes,
                    type: .permanent
                )
                .padding(.horizontal, 12)
            } else {
                EnergyColumnView(
                    energies: ParasiteEnergyData.temporaires,
                    type: .temporary
                )
                .padding(.horizontal, 12)
            }
        }
    }
}

// MARK: - Colonne d'énergies (ScrollView + DisclosureGroups accordion)

struct EnergyColumnView: View {
    let energies: [ParasiteEnergy]
    let type: EnergyType
    @State private var expandedId: UUID?

    var body: some View {
        VStack(spacing: 0) {
            // Badge type
            HStack {
                Text(type.label)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(type.color)
                    .cornerRadius(6)
                Spacer()
                Text("\(energies.count)")
                    .font(.caption.bold().monospaced())
                    .foregroundColor(type.color)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)

            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(energies) { energy in
                        EnergyDisclosureRow(
                            energy: energy,
                            isExpanded: expandedId == energy.id,
                            onToggle: {
                                withAnimation(.spring(response: 0.3)) {
                                    expandedId = expandedId == energy.id ? nil : energy.id
                                }
                            }
                        )
                    }
                }
                .padding(.bottom, 80)
            }
        }
    }
}

// MARK: - Row individuelle (simule DisclosureGroup avec accordion)

struct EnergyDisclosureRow: View {
    let energy: ParasiteEnergy
    let isExpanded: Bool
    let onToggle: () -> Void
    @Environment(\.colorScheme) var colorScheme

    private var bgColor: Color {
        colorScheme == .dark
            ? Color(hex: "#1A1A2E")
            : Color(UIColor.secondarySystemBackground)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row (toujours visible)
            Button(action: onToggle) {
                HStack(spacing: 8) {
                    Text("\(energy.numero)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(energy.type.color)
                        .frame(width: 24)
                    Text(energy.nom)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(isExpanded ? nil : 1)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(energy.type.color.opacity(0.6))
                }
                .padding(.horizontal, 10).padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Énergie \(energy.nom), \(energy.type.label), niveau \(energy.niveau)")

            // Contenu déplié
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider().padding(.horizontal, 8)

                    // Description
                    Text(energy.description)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    // Énergie
                    Text(energy.nom)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(energy.type.color)

                    // Badge niveau
                    Text(energy.niveau)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(energy.type.color)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(energy.type.color.opacity(0.15))
                        .cornerRadius(8)

                    // Libération
                    Text(energy.liberation)
                        .font(.system(size: 13).italic())
                        .foregroundColor(.primary.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 12).padding(.bottom, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(bgColor)
        .overlay(
            isExpanded
                ? Rectangle()
                    .fill(energy.type.color)
                    .frame(width: 3)
                    .padding(.vertical, 1)
                : nil,
            alignment: .leading
        )
        .cornerRadius(12)
    }
}
