// ToreGlycemieScleroseView.swift
// SVLBHPanel — Vue SwiftUI du module Tore dans la section Glycémie/Sclérose

import SwiftUI

struct ToreGlycemieScleroseView: View {
    @EnvironmentObject var session: SessionState
    @StateObject private var vm = ToreViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Champ Toroïdal
                    GroupBox(label: Label("Champ Toroïdal", systemImage: "hurricane")) {
                        VStack(spacing: 12) {
                            ToreSliderRow(label: "Intensité", value: $vm.toreIntensite, range: 0...100_000, unit: "")
                            ToreSliderRow(label: "Cohérence", value: $vm.toreCoherence, range: 0...100, unit: "%")
                            HStack {
                                Text("Phase")
                                Spacer()
                                Picker("Phase", selection: $vm.torePhase) {
                                    ForEach(ChampToroidal.Phase.allCases, id: \.self) { phase in
                                        Text(phase.rawValue).tag(phase)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                        .padding(.top, 4)
                    }

                    // MARK: - Glycémie
                    GroupBox(label: Label("Glycémie", systemImage: "drop.fill")) {
                        VStack(spacing: 12) {
                            ToreSliderRow(label: "Index", value: $vm.glycIndex, range: 0...500, unit: "")
                            ToreSliderRow(label: "Balance", value: $vm.glycBalance, range: 0...100, unit: "%")
                            ToreSliderRow(label: "Absorption", value: $vm.glycAbsorption, range: 0...100, unit: "%")
                            ToreSliderRow(label: "Résistance", value: $vm.glycResistance, range: 0...1000, unit: "")
                        }
                        .padding(.top, 4)
                    }

                    // MARK: - Sclérose
                    GroupBox(label: Label("Sclérose", systemImage: "waveform.path.ecg")) {
                        VStack(spacing: 12) {
                            ToreSliderRow(label: "Score", value: $vm.sclScore, range: 0...1000, unit: "")
                            ToreSliderRow(label: "Densité", value: $vm.sclDensite, range: 0...100, unit: "%")
                            ToreSliderRow(label: "Élasticité", value: $vm.sclElasticite, range: 0...100, unit: "%")
                            ToreSliderRow(label: "Perméabilité", value: $vm.sclPermeabilite, range: 0...100, unit: "%")
                        }
                        .padding(.top, 4)
                    }

                    // MARK: - Couplage
                    GroupBox(label: Label("Couplage", systemImage: "link.circle.fill")) {
                        VStack(spacing: 12) {
                            ToreCorrelationRow(label: "Tore \u{2194} Glycémie", value: $vm.corrTG)
                            ToreCorrelationRow(label: "Tore \u{2194} Sclérose", value: $vm.corrTS)
                            ToreCorrelationRow(label: "Glycémie \u{2194} Sclérose", value: $vm.corrGS)

                            if let score = vm.scoreCouplage {
                                HStack {
                                    Text("Score couplage")
                                    Spacer()
                                    Text("\(score)")
                                        .fontWeight(.bold)
                                        .foregroundColor(.orange)
                                }
                            }
                            if let phase = vm.phaseCouplage {
                                HStack {
                                    Text("Phase")
                                    Spacer()
                                    TorePhaseBadge(phase: phase)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }

                    // MARK: - Sclérose Tissulaire
                    GroupBox(label: Label("Sclérose Tissulaire", systemImage: "circle.grid.cross.fill")) {
                        VStack(spacing: 12) {
                            ToreSliderRow(label: "Fibrose", value: $vm.stFibrose, range: 0...1000, unit: "")
                            ToreSliderRow(label: "Zones atteintes", value: $vm.stZones, range: 0...50, unit: "")
                            ToreSliderRow(label: "Profondeur", value: $vm.stProfondeur, range: 0...10, unit: "")
                            ToreSliderRow(label: "Revascularisation", value: $vm.stRevasc, range: 0...100, unit: "%")
                            ToreSliderRow(label: "Décompaction", value: $vm.stDecompaction, range: 0...100, unit: "%")
                        }
                        .padding(.top, 4)
                    }

                    // MARK: - Stockage Global
                    GroupBox(label: Label("Stockage Énergétique", systemImage: "battery.100.bolt")) {
                        VStack(spacing: 12) {
                            ToreSliderRow(label: "Niveau", value: $vm.niveau, range: 0...100_000, unit: "")
                            ToreSliderRow(label: "Capacité", value: $vm.capacite, range: 0...100_000, unit: "")
                            ToreSliderRow(label: "Taux restauration", value: $vm.tauxRest, range: 0...100, unit: "%")

                            if let rendement = vm.rendement {
                                HStack {
                                    Text("Rendement")
                                    Spacer()
                                    Text(String(format: "%.1f%%", rendement))
                                        .fontWeight(.bold)
                                        .foregroundColor(rendement > 70 ? .green : rendement > 40 ? .orange : .red)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }

                    // MARK: - Actions
                    HStack(spacing: 16) {
                        Button(action: { Task { await vm.pull() } }) {
                            Label("Charger", systemImage: "arrow.down.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button(action: { Task { await vm.push() } }) {
                            Label("Sauvegarder", systemImage: "arrow.up.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.top, 8)

                    if let msg = vm.statusMessage {
                        Text(msg)
                            .font(.caption)
                            .foregroundColor(vm.isError ? .red : .green)
                    }

                    Spacer().frame(height: 80)
                }
                .padding()
            }
            .navigationTitle("Tore — Glycémie / Sclérose")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
        .onAppear {
            vm.sessionKey = session.sessionId
            vm.therapistName = session.role.displayName
        }
    }
}

// MARK: - Composants UI (préfixés Tore pour éviter conflits)

struct ToreSliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                Spacer()
                Text("\(Int(value))\(unit)")
                    .monospacedDigit()
                    .foregroundColor(.secondary)
            }
            Slider(value: $value, in: range)
        }
    }
}

struct ToreCorrelationRow: View {
    let label: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                Spacer()
                Text("\(Int(value))")
                    .monospacedDigit()
                    .foregroundColor(value > 0 ? .green : value < 0 ? .red : .secondary)
            }
            Slider(value: $value, in: -100...100)
        }
    }
}

struct TorePhaseBadge: View {
    let phase: String

    var color: Color {
        switch phase {
        case "SYNERGIQUE": return .green
        case "ANTAGONISTE": return .red
        case "NEUTRE": return .gray
        case "TRANSITOIRE": return .orange
        default: return .secondary
        }
    }

    var body: some View {
        Text(phase)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}
