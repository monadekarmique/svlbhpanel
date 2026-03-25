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
            porteMenu(
                label: "Ouvertures Temporaires",
                placeholder: "— Sélectionner —",
                color: Color(hex: "#10B981"),
                portes: PorteEnergetiqueData.temporaires,
                selection: $tempSelection,
                selected: selectedTemp
            )
            porteMenu(
                label: "Ouvertures Permanentes",
                placeholder: "— Sélectionner —",
                color: Color(hex: "#E24B4A"),
                portes: PorteEnergetiqueData.permanentes,
                selection: $permSelection,
                selected: selectedPerm
            )
            if tempSelection != nil || permSelection != nil {
                Button {
                    tempSelection = nil
                    permSelection = nil
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.counterclockwise").font(.caption)
                        Text("Réinitialiser").font(.caption)
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
                        .font(.caption.bold())
                        .foregroundColor(color)
                    Spacer()
                    if let porte = selected {
                        let pt = porte.point.isEmpty ? "" : " (\(porte.point))"
                        Text("\(porte.nom)\(pt)")
                            .font(.caption)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    } else {
                        Text(placeholder)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundColor(color.opacity(0.5))
                }
                .padding(.horizontal, 8).padding(.vertical, 5)
                .background(color.opacity(0.06))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.15), lineWidth: 1))
            }
            .accessibilityLabel("\(label) G\(generationId)")

            if let porte = selected {
                HStack(spacing: 4) {
                    Text(porte.isPermanent ? "🔴" : "🟢").font(.caption)
                    let pt = porte.point.isEmpty ? "" : " (\(porte.point))"
                    Text("\(porte.nom)\(pt)")
                        .font(.caption.bold())
                        .foregroundColor(color)
                    Text("·").font(.caption).foregroundColor(.secondary)
                    Text(porte.condition)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
            }
        }
    }
}
