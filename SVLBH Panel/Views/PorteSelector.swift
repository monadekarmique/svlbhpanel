// SVLBHPanel — Views/PorteSelector.swift
// v4.8.0 — Sélecteur de portes énergétiques par génération

import SwiftUI

struct PorteSelector: View {
    let generationId: Int
    @Binding var tempSelection: Int?
    @Binding var permSelection: Int?

    private var selectedTemp: PorteEnergetique? {
        guard let n = tempSelection else { return nil }
        return PorteEnergetiqueData.temporaires.first { $0.numero == n }
    }

    private var selectedPerm: PorteEnergetique? {
        guard let n = permSelection else { return nil }
        return PorteEnergetiqueData.permanentes.first { $0.numero == n }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Temporaires
            porteMenu(
                label: "Ouvertures Temporaires",
                placeholder: "— Sélectionner une porte temporaire —",
                color: Color(hex: "#10B981"),
                portes: PorteEnergetiqueData.temporaires,
                selection: $tempSelection,
                selected: selectedTemp
            )

            // Permanentes
            porteMenu(
                label: "Ouvertures Permanentes",
                placeholder: "— Sélectionner une porte permanente —",
                color: Color(hex: "#E24B4A"),
                portes: PorteEnergetiqueData.permanentes,
                selection: $permSelection,
                selected: selectedPerm
            )

            // Reset
            if tempSelection != nil || permSelection != nil {
                Button {
                    tempSelection = nil
                    permSelection = nil
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.counterclockwise").font(.system(size: 9))
                        Text("Réinitialiser").font(.system(size: 9))
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func porteMenu(label: String, placeholder: String, color: Color,
                           portes: [PorteEnergetique], selection: Binding<Int?>,
                           selected: PorteEnergetique?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Menu {
                Button("— Aucune —") { selection.wrappedValue = nil }
                ForEach(portes) { porte in
                    Button {
                        selection.wrappedValue = porte.numero
                    } label: {
                        let pt = porte.point.isEmpty ? "" : " (\(porte.point))"
                        Text("\(porte.numero). \(porte.nom)\(pt) — \(porte.condition)")
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(label)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(color)
                    Spacer()
                    if let porte = selected {
                        let pt = porte.point.isEmpty ? "" : " (\(porte.point))"
                        Text("\(porte.nom)\(pt)")
                            .font(.system(size: 9))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    } else {
                        Text(placeholder)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 7))
                        .foregroundColor(color.opacity(0.5))
                }
                .padding(.horizontal, 8).padding(.vertical, 5)
                .background(color.opacity(0.06))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.15), lineWidth: 1))
            }
            .accessibilityLabel("\(label) G\(generationId)")

            // Détail sélection
            if let porte = selected {
                HStack(spacing: 4) {
                    Text(porte.isPermanent ? "🔴" : "🟢").font(.system(size: 8))
                    let pt = porte.point.isEmpty ? "" : " (\(porte.point))"
                    Text("\(porte.nom)\(pt)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(color)
                    Text("·").foregroundColor(.secondary)
                    Text(porte.condition)
                        .font(.system(size: 9).italic())
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
            }
        }
    }
}
