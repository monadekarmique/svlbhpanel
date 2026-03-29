// SVLBHPanel — Views/ConditionsPortesView.swift
// v4.8.0 — Conditions d'ouverture des portes énergétiques d'entrées

import SwiftUI

struct ConditionsPortesView: View {
    // Stockage des sélections : [chakraId: numero porte sélectionnée]
    @State private var tempSelections: [Int: Int] = [:]
    @State private var permSelections: [Int: Int] = [:]

    var body: some View {
        VStack(spacing: 8) {
            Text("Conditions d'ouverture des portes énergétiques d'entrées")
                .font(.caption2.bold())
                .foregroundColor(Color(hex: "#8B3A62"))
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            ForEach(PorteEnergetiqueData.chakras) { chakra in
                ChakraPorteSelector(
                    chakra: chakra,
                    tempSelection: Binding(
                        get: { tempSelections[chakra.id] },
                        set: { tempSelections[chakra.id] = $0 }
                    ),
                    permSelection: Binding(
                        get: { permSelections[chakra.id] },
                        set: { permSelections[chakra.id] = $0 }
                    )
                )
            }
        }
    }
}

// MARK: - Sélecteur par chakra (réutilisable)

struct ChakraPorteSelector: View {
    let chakra: PorteChakraInfo
    @Binding var tempSelection: Int?
    @Binding var permSelection: Int?
    @Environment(\.colorScheme) var colorScheme
    @State private var showTempPicker = false
    @State private var showPermPicker = false

    private var selectedTemp: PorteEnergetique? {
        guard let n = tempSelection else { return nil }
        return PorteEnergetiqueData.temporaires.first { $0.numero == n }
    }

    private var selectedPerm: PorteEnergetique? {
        guard let n = permSelection else { return nil }
        return PorteEnergetiqueData.permanentes.first { $0.numero == n }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header chakra + reset
            HStack {
                Text("CHAKRA \(chakra.id)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: "#8B3A62"))
                Text("— \(chakra.nom) (\(chakra.sanskrit))")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                if tempSelection != nil || permSelection != nil {
                    Button {
                        tempSelection = nil
                        permSelection = nil
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Réinitialiser chakra \(chakra.id)")
                }
            }

            // Ouvertures Temporaires
            porteButton(
                label: "Ouvertures Temporaires",
                color: Color(hex: "#10B981"),
                selected: selectedTemp,
                showPicker: $showTempPicker
            )
            .sheet(isPresented: $showTempPicker) {
                PortePickerSheet(
                    selection: $tempSelection,
                    portes: PorteEnergetiqueData.temporaires,
                    title: "Temporaires — \(chakra.nom)",
                    color: Color(hex: "#10B981")
                )
            }

            // Ouvertures Permanentes
            porteButton(
                label: "Ouvertures Permanentes",
                color: Color(hex: "#E24B4A"),
                selected: selectedPerm,
                showPicker: $showPermPicker
            )
            .sheet(isPresented: $showPermPicker) {
                PortePickerSheet(
                    selection: $permSelection,
                    portes: PorteEnergetiqueData.permanentes,
                    title: "Permanentes — \(chakra.nom)",
                    color: Color(hex: "#E24B4A")
                )
            }
        }
        .padding(10)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal, 12)
    }

    @ViewBuilder
    private func porteButton(label: String, color: Color,
                             selected: PorteEnergetique?, showPicker: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Button { showPicker.wrappedValue = true } label: {
                HStack(spacing: 4) {
                    Text(label)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(color)
                    Spacer()
                    if let porte = selected {
                        Text(porte.nom)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    } else {
                        Text("— Sélectionner —")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 8))
                        .foregroundColor(color.opacity(0.6))
                }
                .padding(.horizontal, 8).padding(.vertical, 6)
                .background(color.opacity(0.06))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(label) pour chakra \(chakra.nom)")

            // Détail si sélectionné
            if let porte = selected {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(porte.isPermanent ? "🔴" : "🟢")
                            .font(.system(size: 8))
                        let pointStr = porte.point.isEmpty ? "" : " (\(porte.point))"
                        Text("\(porte.nom)\(pointStr)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(color)
                    }
                    Text(porte.condition)
                        .font(.system(size: 9).italic())
                        .foregroundColor(.secondary)
                    Text(porte.statut)
                        .font(.system(size: 9))
                        .foregroundColor(color.opacity(0.8))
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(color.opacity(0.04))
                .cornerRadius(5)
            }
        }
    }
}

// MARK: - Sheet scrollable pour portes énergétiques

struct PortePickerSheet: View {
    @Binding var selection: Int?
    let portes: [PorteEnergetique]
    let title: String
    let color: Color
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                List {
                    Button {
                        selection = nil
                        dismiss()
                    } label: {
                        Text("— Aucune —")
                            .foregroundColor(.secondary)
                    }

                    ForEach(portes) { porte in
                        Button {
                            selection = porte.numero
                            dismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Text("\(porte.numero)")
                                    .font(.caption.bold().monospaced())
                                    .foregroundColor(color)
                                    .frame(width: 28, alignment: .trailing)
                                VStack(alignment: .leading, spacing: 2) {
                                    let pointStr = porte.point.isEmpty ? "" : " (\(porte.point))"
                                    Text("\(porte.nom)\(pointStr)")
                                        .foregroundColor(.primary)
                                    Text(porte.condition)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if selection == porte.numero {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(color)
                                }
                            }
                        }
                        .id(porte.numero)
                    }
                }
                .listStyle(.plain)
                .onAppear {
                    if let sel = selection {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation { proxy.scrollTo(sel, anchor: .center) }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}
