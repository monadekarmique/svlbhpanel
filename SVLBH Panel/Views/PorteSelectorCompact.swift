// SVLBHPanel — Views/PorteSelectorCompact.swift
// v4.8.0 — Sélecteur portes énergétiques par chakra (compact, côte à côte iPad)

import SwiftUI

struct PorteSelectorCompact: View {
    @EnvironmentObject var session: SessionState
    let chakraKey: String
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var tempSelection: Binding<Int?> {
        Binding(
            get: { session.porteSelections[chakraKey + "_temp"] },
            set: { session.porteSelections[chakraKey + "_temp"] = $0 }
        )
    }

    private var permSelection: Binding<Int?> {
        Binding(
            get: { session.porteSelections[chakraKey + "_perm"] },
            set: { session.porteSelections[chakraKey + "_perm"] = $0 }
        )
    }

    private var selectedTemp: PorteEnergetique? {
        guard let n = tempSelection.wrappedValue else { return nil }
        return PorteEnergetiqueData.temporaires.first { $0.numero == n }
    }

    private var selectedPerm: PorteEnergetique? {
        guard let n = permSelection.wrappedValue else { return nil }
        return PorteEnergetiqueData.permanentes.first { $0.numero == n }
    }

    var body: some View {
        let content = Group {
            porteMenu(
                label: "Temporaire",
                color: Color(hex: "#10B981"),
                portes: PorteEnergetiqueData.temporaires,
                selection: tempSelection,
                selected: selectedTemp
            )
            porteMenu(
                label: "Permanent",
                color: Color(hex: "#E24B4A"),
                portes: PorteEnergetiqueData.permanentes,
                selection: permSelection,
                selected: selectedPerm
            )
        }

        if sizeClass == .regular {
            HStack(alignment: .top, spacing: 6) { content }
        } else {
            VStack(alignment: .leading, spacing: 3) { content }
        }
    }

    @ViewBuilder
    private func porteMenu(label: String, color: Color, portes: [PorteEnergetique],
                           selection: Binding<Int?>, selected: PorteEnergetique?) -> some View {
        VStack(alignment: .leading, spacing: 1) {
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
                HStack(spacing: 3) {
                    Text(label)
                        .font(.caption)
                        .foregroundColor(color)
                    Spacer()
                    if let p = selected {
                        Text(p.nom)
                            .font(.caption2)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    } else {
                        Text("—")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 7))
                        .foregroundColor(color.opacity(0.5))
                }
                .padding(.horizontal, 6).padding(.vertical, 4)
                .background(color.opacity(0.06))
                .cornerRadius(5)
            }

            if let p = selected {
                HStack(spacing: 3) {
                    Text(p.isPermanent ? "🔴" : "🟢").font(.system(size: 7))
                    Text(p.condition)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(.leading, 4)
            }
        }
    }
}
