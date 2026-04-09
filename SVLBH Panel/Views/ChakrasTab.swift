// SVLBHPanel — Views/ChakrasTab.swift
// v0.1.3 — SLA→SLM · CIM-11 codes affichés · 46 chakras

import SwiftUI

struct ChakrasTab: View {
    @EnvironmentObject var session: SessionState
    @State private var collapseToken = UUID()
    @State private var showPierres = false

    /// D0 (C34-C45) visible uniquement pour superviseur et Cornelia, placé au-dessus de D9
    private var filteredDimensions: [DimensionInfo] {
        let canSeeD0 = session.role.isSuperviseur || session.role.code == "0300"
        var dims = allDimensions.filter { $0.id != "d0" }
        if canSeeD0, let d0 = allDimensions.first(where: { $0.id == "d0" }) {
            // Insérer D0 juste avant D9
            if let d9idx = dims.firstIndex(where: { $0.id == "d9" }) {
                dims.insert(d0, at: d9idx)
            } else {
                dims.append(d0)
            }
        }
        return dims
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // ── Bouton Pierres (haut) ──
                    PierresSheetButton(showPierres: $showPierres)
                        .padding(.horizontal, 16).padding(.vertical, 8)

                    VStack(spacing: 4) {
                        HStack {
                            Text("Bloqueurs d\u{2019}ascensions")
                                .font(.caption).foregroundColor(.secondary)
                            Spacer()
                            Text("\(session.cleanedChakrasCount) / \(session.totalChakras)")
                                .font(.caption.bold()).foregroundColor(Color(hex: "#8B3A62"))
                        }
                        ProgressView(value: Double(session.cleanedChakrasCount),
                                     total: Double(max(1, session.totalChakras)))
                            .tint(Color(hex: "#8B3A62"))
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)

                    Divider()

                    ForEach(filteredDimensions) { dim in
                        DimensionSection(dim: dim, collapseToken: collapseToken)
                            .environmentObject(session)
                    }
                    // ── Bouton Pierres (bas) ──
                    PierresSheetButton(showPierres: $showPierres)
                        .padding(.horizontal, 16).padding(.vertical, 8)

                    Spacer().frame(height: 80)
                }
            }
            .navigationTitle("Conditions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        collapseToken = UUID()
                    } label: {
                        Image(systemName: "chevron.up.2")
                            .font(.caption.bold())
                            .foregroundColor(Color(hex: "#8B3A62"))
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showPierres) {
            PierresTab().environmentObject(session)
        }
    }
}

struct DimensionSection: View {
    @EnvironmentObject var session: SessionState
    let dim: DimensionInfo
    let collapseToken: UUID
    @State private var expanded: Bool = false

    var cleanedInDim: Int { dim.allKeys.filter { session.chakraStates[$0] == true }.count }
    var sugInDim: Int { dim.allKeys.filter { session.sugChakraStates[$0] == true && session.chakraStates[$0] != true }.count }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Text(expanded ? "▼" : "▶")
                        .font(.caption2).foregroundColor(Color(hex: "#8B3A62"))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(dim.label).font(.subheadline.bold()).foregroundColor(.primary)
                        Text(dim.description).font(.caption2).foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("\(cleanedInDim)/\(dim.chakras.count)")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(cleanedInDim > 0 ? Color(hex: "#1D9E75") : Color.gray)
                        .cornerRadius(8)
                    if sugInDim > 0 {
                        Text("🔬 \(sugInDim)")
                            .font(.caption2.bold())
                            .foregroundColor(Color(hex: "#185FA5"))
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color(hex: "#185FA5").opacity(0.12))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(Color(hex: "#8B3A62").opacity(0.05))
            }
            .buttonStyle(.plain)

            if expanded {
                ForEach(dim.chakras) { c in
                    ChakraRow(dim: dim, chakra: c)
                        .environmentObject(session)
                }
            }
            Divider()
        }
        .onChange(of: collapseToken) { _ in
            withAnimation(.easeInOut(duration: 0.2)) { expanded = false }
        }
    }
}

struct ChakraRow: View {
    @EnvironmentObject var session: SessionState
    let dim: DimensionInfo
    let chakra: ChakraInfo

    var key: String { dim.chakraKey(chakra) }
    var isDone: Bool { session.chakraStates[key] ?? false }
    var isSuggested: Bool { session.sugChakraStates[key] == true && !isDone }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Checkbox
            Button {
                session.chakraStates[key] = !isDone
                if isDone { session.sugChakraStates.removeValue(forKey: key) }
            } label: {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isDone ? Color(hex: "#1D9E75") : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            // 🔬 Suggestion badge
            if isSuggested {
                Button {
                    session.chakraStates[key] = true
                    session.sugChakraStates.removeValue(forKey: key)
                } label: {
                    HStack(spacing: 2) {
                        Text("🔬").font(.system(size: 9))
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "#185FA5"))
                    }
                    .padding(3)
                    .background(Color(hex: "#185FA5").opacity(0.10))
                    .cornerRadius(5)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 4) {
                // Ligne titre
                HStack(spacing: 4) {
                    Text(chakra.icon).font(.caption)
                    if let n = chakra.num {
                        Text("C\(n)").font(.caption2.bold())
                            .foregroundColor(Color(hex: "#8B3A62"))
                    }
                    Text(chakra.nom).font(.caption)
                    if chakra.hasCIM {
                        Text("CIM-11").font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(Color(hex: "#185FA5"))
                            .cornerRadius(3)
                    }
                }

                // Portes énergétiques
                PorteSelectorCompact(chakraKey: key)
                    .environmentObject(session)

                // Issues — SLM (remplace SLA)
                ForEach(chakra.issues, id: \.label) { issue in
                    HStack(spacing: 4) {
                        Text(issue.label).font(.caption2).foregroundColor(.secondary)
                        Text("SLM \(issue.sla)%").font(.caption2.bold())
                            .foregroundColor(slaColor(issue.sla))
                    }
                }

                // D22 — Programmes de Protection Gui
                if dim.id == "d22" {
                    ProgrammeProtectionGroup()
                        .environmentObject(session)
                }

                // F16/F30 — Codes CIM-11 toggles (clé fixée au chakra)
                if !chakra.cimCodes.isEmpty {
                    CIMToggleGroup(chakraKey: key, codes: chakra.cimCodes)
                        .environmentObject(session)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 6)
        .background(isDone ? Color(hex: "#1D9E75").opacity(0.06)
                    : isSuggested ? Color(hex: "#185FA5").opacity(0.06)
                    : Color.clear)
    }
}

// F30 — CIM toggles isolés dans leur propre View pour éviter le bug d'indexation
struct CIMToggleGroup: View {
    @EnvironmentObject var session: SessionState
    let chakraKey: String
    let codes: [(code: String, label: String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(codes, id: \.code) { entry in
                CIMToggleRow(chakraKey: chakraKey, code: entry.code, label: entry.label)
                    .environmentObject(session)
            }
        }
        .padding(.top, 2)
    }
}

struct CIMToggleRow: View {
    @EnvironmentObject var session: SessionState
    let chakraKey: String
    let code: String
    let label: String

    private var isOn: Bool {
        session.selectedCIM[chakraKey]?.contains(code) ?? false
    }

    var body: some View {
        Button {
            var s = session.selectedCIM[chakraKey] ?? []
            if isOn { s.remove(code) } else { s.insert(code) }
            session.selectedCIM[chakraKey] = s
        } label: {
            HStack(spacing: 5) {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .font(.caption2)
                    .foregroundColor(isOn ? Color(hex: "#185FA5") : .secondary)
                Text(code)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(isOn ? Color(hex: "#185FA5") : Color(hex: "#185FA5").opacity(0.5))
                    .cornerRadius(4)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(isOn ? Color(hex: "#185FA5") : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - D22 Programmes de Protection Gui
struct ProgrammeProtectionGroup: View {
    @EnvironmentObject var session: SessionState

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(programmesProtectionGui) { prog in
                Button {
                    if session.programmeProtectionSelections.contains(prog.id) {
                        session.programmeProtectionSelections.remove(prog.id)
                    } else {
                        session.programmeProtectionSelections.insert(prog.id)
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: session.programmeProtectionSelections.contains(prog.id)
                              ? "checkmark.square.fill" : "square")
                            .font(.caption2)
                            .foregroundColor(session.programmeProtectionSelections.contains(prog.id)
                                             ? Color(hex: "#8B3A62") : .secondary)
                        Text(prog.label)
                            .font(.caption2)
                            .foregroundColor(session.programmeProtectionSelections.contains(prog.id)
                                             ? Color(hex: "#8B3A62") : .secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 2)
    }
}
