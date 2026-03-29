// SVLBHPanel — Views/SLMTab.swift
// v4.0.4 — Fix SA1 : champ propre slsaS1, plus d'isAutoCalc, SA1 éditable indépendamment

import SwiftUI

struct SLMTab: View {
    @EnvironmentObject var session: SessionState
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var isEditing: Bool

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {

                    // ── En-tête ──
                    VStack(spacing: 3) {
                        Text("◈ Scores de Lumière")
                            .font(.title2.bold()).foregroundColor(Color(hex: "#8B3A62"))
                        Text("SLA · SLSA · SLM · Tot SLM")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    .padding(.top, 14)

                    if session.role.isSuperviseur {
                        // ── Patrick actif : scores shamane (read-only) + scores Patrick (éditable) ──
                        ScoreBlock(
                            title: session.pullSource?.displayName ?? "Th\u{00e9}rapeute MyShamanFamily",
                            color: Color(hex: "#8B3A62"),
                            scores: $session.scoresTherapist,
                            readOnly: true
                        )
                        .padding(.horizontal, 16)

                        ScoreBlock(
                            title: "🔬 Patrick",
                            color: Color(hex: "#185FA5"),
                            scores: $session.scoresPatrick,
                            readOnly: false
                        )
                        .padding(.horizontal, 16)
                    } else {
                        // ── Shamane active : ses scores (éditable) + scores Patrick (read-only) ──
                        ScoreBlock(
                            title: session.role.displayName,
                            color: Color(hex: "#8B3A62"),
                            scores: $session.scoresTherapist,
                            readOnly: false
                        )
                        .padding(.horizontal, 16)

                        ScoreBlock(
                            title: "🔬 Patrick",
                            color: Color(hex: "#185FA5"),
                            scores: $session.scoresPatrick,
                            readOnly: true
                        )
                        .padding(.horizontal, 16)
                    }

                    // ── Définitions des scores ──
                    ScoreDefinitions()
                        .padding(.horizontal, 16)

                    Spacer().frame(height: 80)
                }
            }
            .navigationTitle("SLM")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("OK") { isEditing = false; hideKeyboard() }
                }
            }
            .onTapGesture { hideKeyboard() }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Bloc de saisie d'un praticien
struct ScoreBlock: View {
    let title: String
    let color: Color
    @Binding var scores: ScoresLumiere
    let readOnly: Bool
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(color)

            VStack(spacing: 10) {
                ScoreField(
                    label: "SLA",
                    sublabel: "Score de Lumière de l'Âme",
                    unit: "%",
                    max: ScoresLumiere.slaMax,
                    value: Binding(
                        get: { scores.sla },
                        set: { scores.sla = $0 }
                    ),
                    color: color,
                    readOnly: readOnly
                )
                ScoreField(
                    label: "SLSA",
                    sublabel: scores.hasDetailedSLSA
                        ? "Auto : SA1+SA2+SA3+SA4+SA5"
                        : "Score de Lumière de la Sur-Âme",
                    unit: "%",
                    max: ScoresLumiere.slsaMax,
                    value: Binding(
                        get: { scores.slsaEffective },
                        set: { scores.slsa = $0 }
                    ),
                    color: color,
                    readOnly: readOnly || scores.hasDetailedSLSA
                )

                // ── Tabelle SLSA : SA5 → SA4 → SA3 → SA2 → SA1 ──
                SLSATableRow(scores: $scores, color: color, readOnly: readOnly)
                ScoreField(
                    label: "SLM",
                    sublabel: "Score de Lumière de la Monade",
                    unit: "%",
                    max: ScoresLumiere.slmMax,
                    value: Binding(
                        get: { scores.slm },
                        set: { scores.slm = $0 }
                    ),
                    color: color,
                    readOnly: readOnly
                )
                ScoreField(
                    label: "Tot SLM",
                    sublabel: "Total SLM",
                    unit: "%",
                    max: ScoresLumiere.totSlmMax,
                    value: Binding(
                        get: { scores.totSlm },
                        set: { scores.totSlm = $0 }
                    ),
                    color: color,
                    readOnly: readOnly
                )
            }
        }
        .padding(14)
        .background(color.opacity(colorScheme == .dark ? 0.15 : 0.06))
        .cornerRadius(12)
    }
}

// MARK: - Champ individuel
struct ScoreField: View {
    let label: String
    let sublabel: String
    let unit: String
    let max: Int
    @Binding var value: Int?
    let color: Color
    let readOnly: Bool

    @State private var draft: String = ""

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.caption.bold()).foregroundColor(color)
                Text(sublabel).font(.system(size: 9)).foregroundColor(.secondary)
                Text("0 – \(max.formatted()) %")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.7))
            }
            .frame(minWidth: 100, alignment: .leading)

            Spacer()

            if readOnly {
                // Affichage seul
                Text(value.map { "\($0) %" } ?? "—")
                    .font(.body.bold())
                    .foregroundColor(value != nil ? color : .secondary)
                    .frame(width: 90, alignment: .trailing)
            } else {
                // Saisie
                HStack(spacing: 2) {
                    TextField("—", text: $draft)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 70)
                        .padding(.horizontal, 8).padding(.vertical, 5)
                        .background(color.opacity(0.10))
                        .cornerRadius(7)
                        .font(.body.bold())
                        .foregroundColor(color)
                        .onChange(of: draft) { v in
                            if let n = Int(v), n >= 0, n <= max {
                                value = n
                            } else if v.isEmpty {
                                value = nil
                            }
                        }
                        .onAppear { draft = value.map(String.init) ?? "" }
                        .onChange(of: value) { v in
                            let newDraft = v.map(String.init) ?? ""
                            if newDraft != draft { draft = newDraft }
                        }
                    Text("%").font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Tabelle SLSA : SA5 | SA4 | SA3 | SA2 | SA1
struct SLSATableRow: View {
    @Binding var scores: ScoresLumiere
    let color: Color
    let readOnly: Bool

    private let cells: [(label: String, keyPath: WritableKeyPath<ScoresLumiere, Int?>)] = [
        ("SA5", \ScoresLumiere.slsaS5),
        ("SA4", \ScoresLumiere.slsaS4),
        ("SA3", \ScoresLumiere.slsaS3),
        ("SA2", \ScoresLumiere.slsaS2),
        ("SA1", \ScoresLumiere.slsaS1),
    ]

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 0) {
                ForEach(Array(cells.enumerated()), id: \.offset) { idx, cell in
                    let isSA1 = cell.label == "SA1"
                    // SA1 affiche sa propre valeur (slsaS1), jamais le total
                    let val = scores[keyPath: cell.keyPath]
                    VStack(spacing: 2) {
                        Text(cell.label)
                            .font(.system(size: 9, weight: isSA1 ? .bold : .medium))
                            .foregroundColor(isSA1 ? .white : color)
                        if readOnly {
                            Text(val.map { "\($0)%" } ?? "—")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(isSA1 ? .white : (val != nil ? color : .secondary))
                        } else {
                            SLSACellField(
                                value: Binding(
                                    get: { scores[keyPath: cell.keyPath] },
                                    set: {
                                        scores[keyPath: cell.keyPath] = $0
                                        scores.recalcSLSA()
                                    }
                                ),
                                color: isSA1 ? .white : color,
                                bgColor: isSA1 ? color.opacity(0.15) : color.opacity(0.06)
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(isSA1 ? color : Color.clear)
                    .cornerRadius(isSA1 ? 6 : 0)
                    if idx < cells.count - 1 {
                        Divider().frame(height: 30)
                    }
                }
            }
            .padding(4)
            .background(color.opacity(0.06))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.2), lineWidth: 1))

            Text("SA1 = SLSA si seul, sinon SLSA = SA1+SA2+SA3+SA4+SA5")
                .font(.system(size: 9)).foregroundColor(.secondary)
        }
    }
}

// MARK: - Cellule saisie compacte SLSA
struct SLSACellField: View {
    @Binding var value: Int?
    let color: Color
    let bgColor: Color
    @State private var draft: String = ""

    var body: some View {
        HStack(spacing: 2) {
            TextField("—", text: $draft)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 44)
                .padding(.horizontal, 2).padding(.vertical, 3)
                .background(bgColor)
                .cornerRadius(4)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .onChange(of: draft) { v in
                    if let n = Int(v), n >= 0, n <= ScoresLumiere.slsaMax {
                        value = n
                    } else if v.isEmpty {
                        value = nil
                    }
                }
                .onAppear { draft = value.map(String.init) ?? "" }
                .onChange(of: value) { v in
                    let newDraft = v.map(String.init) ?? ""
                    if newDraft != draft { draft = newDraft }
                }
            Text("%")
                .font(.system(size: 9))
                .foregroundColor(color.opacity(0.7))
        }
    }
}

// MARK: - Définitions des scores
struct ScoreDefinitions: View {
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Définitions").font(.subheadline.bold()).foregroundColor(.secondary)

            ScoreDefRow(
                label: "SLA",
                range: "0 – 350 %",
                definition: "Score de Lumière de l'Âme — mesure la luminosité de l'âme individuelle (S0). Indique le niveau de fragmentation ou d'intégrité de la conscience incarnée.",
                color: Color(hex: "#8B3A62")
            )
            ScoreDefRow(
                label: "SLSA",
                range: "0 – 50 000 %",
                definition: "Score de Lumière de la Sur-Âme — mesure la luminosité de la Sur-Âme (S1). SLSA = SA1 + SA2 + SA3 + SA4 + SA5 (somme directe, max < 50 000 %). SA1 seul si les autres ne sont pas renseignés. Reflète les charges transgénérationnelles et karmiques portées par la lignée.",
                color: Color(hex: "#8B3A62")
            )
            ScoreDefRow(
                label: "SLM",
                range: "0 – 100 000 %",
                definition: "Score de Lumière de la Monade — mesure la luminosité de la Monade (S2–S8). Indique la connexion au Soi supérieur et le niveau d'ascension vibratoire.",
                color: Color(hex: "#8B3A62")
            )
            ScoreDefRow(
                label: "Tot SLM",
                range: "0 – 1 000 %",
                definition: "Total SLM — score composite intégrant les 9 dimensions, les voyelles sacrées déséquilibrées et les 46 Chakras. Indicateur global de cohérence du Corps de Lumière.",
                color: Color(hex: "#8B3A62")
            )
        }
        .padding(14)
        .background(Color.secondary.opacity(colorScheme == .dark ? 0.12 : 0.05))
        .cornerRadius(12)
    }
}

struct ScoreDefRow: View {
    let label: String
    let range: String
    let definition: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label).font(.caption.bold()).foregroundColor(color)
                Spacer()
                Text(range).font(.system(size: 10, design: .monospaced)).foregroundColor(.secondary)
            }
            Text(definition)
                .font(.system(size: 13))
                .foregroundColor(.primary.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
    }
}

// MARK: - Dismiss keyboard helper
private func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}
