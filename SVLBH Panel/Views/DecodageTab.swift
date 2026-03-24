// SVLBHPanel — Views/DecodageTab.swift
// v4.0.0 — Tableau 15 générations + Fork galactique conditionnel au tier

import SwiftUI

struct DecodageTab: View {
    @EnvironmentObject var session: SessionState

    var currentTier: PractitionerTier {
        switch session.role {
        case .patrick: return .superviseur
        case .shamane(let p): return p.tier
        }
    }

    var dominantMeridian: (Meridian, Int)? {
        var c: [Meridian: Int] = [:]
        for g in session.visibleGenerations where g.validated {
            for m in g.meridiens { c[m, default: 0] += 1 }
        }
        return c.max(by: { $0.value < $1.value }).map { ($0.key, $0.value) }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Résumé
                    HStack(spacing: 16) {
                        VStack(spacing: 2) {
                            Text("\(session.validatedCount)")
                                .font(.title2.bold()).foregroundColor(Color(hex: "#1D9E75"))
                            Text("validées / 15").font(.caption2).foregroundColor(.secondary)
                        }
                        if let (m, n) = dominantMeridian {
                            VStack(spacing: 2) {
                                Text(m.rawValue + " ×\(n)")
                                    .font(.title2.bold()).foregroundColor(Color(hex: m.color))
                                Text("méridien dominant").font(.caption2).foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    Divider()

                    // F25 — Fork galactique conditionnel au tier
                    ForkGalactiqueSection(tier: currentTier)
                        .environmentObject(session)

                    ForEach(session.visibleGenerations) { g in
                        GenerationRow(g: g)
                        Divider().padding(.leading, 16)
                    }
                    // ── Footer ORCID ──
                    VStack(spacing: 4) {
                        Divider().padding(.horizontal, 40)
                        Text("Digital Shaman Lab · vlbh.energy")
                            .font(.caption2).foregroundColor(.secondary)
                        Link(destination: URL(string: "https://orcid.org/0009-0007-9183-8018")!) {
                            HStack(spacing: 4) {
                                Image(systemName: "person.text.rectangle")
                                    .font(.system(size: 10))
                                Text("ORCID 0009-0007-9183-8018")
                                    .font(.system(size: 10, design: .monospaced))
                            }
                            .foregroundColor(Color(hex: "#1D9E75"))
                        }
                    }
                    .padding(.top, 20).padding(.bottom, 80)
                }
            }
            .navigationTitle("Décodage G.")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - GenerationRow
struct GenerationRow: View {
    @ObservedObject var g: Generation
    @State private var expanded = false
    @Environment(\.colorScheme) var colorScheme

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    var body: some View {
        VStack(spacing: 0) {
            // En-tête ligne
            Button {
                withAnimation(.easeInOut(duration: 0.18)) { expanded.toggle() }
            } label: {
                HStack(spacing: 8) {
                    // Numéro + statut validé
                    ZStack {
                        Circle()
                            .fill(g.validated ? Color(hex: "#1D9E75") : Color(hex: "#8B3A62").opacity(0.12))
                            .frame(width: 30, height: 30)
                        Text("G\(g.id)")
                            .font(.caption2.bold())
                            .foregroundColor(g.validated ? .white : Color(hex: "#8B3A62"))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        if g.abLabel.isEmpty && g.viLabel.isEmpty {
                            Text("—").font(.caption).foregroundColor(.secondary)
                        } else {
                            HStack(spacing: 4) {
                                if !g.abLabel.isEmpty {
                                    Text("Ab: \(g.abLabel)").font(.caption2)
                                        .foregroundColor(Color(hex: "#E24B4A"))
                                        .textSelection(.enabled)
                                }
                                if !g.viLabel.isEmpty {
                                    Text("Vi: \(g.viLabel)").font(.caption2)
                                        .foregroundColor(Color(hex: "#185FA5"))
                                        .textSelection(.enabled)
                                }
                            }
                        }
                        // Pills méridiens
                        if !g.meridiens.isEmpty {
                            HStack(spacing: 3) {
                                ForEach(Array(g.meridiens), id: \.self) { m in
                                    Text(m.rawValue)
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 4).padding(.vertical, 1)
                                        .background(Color(hex: m.color))
                                        .cornerRadius(3)
                                }
                            }
                        }
                    }
                    Spacer()
                    // Badges Gu
                    if !g.gu.isEmpty {
                        Text("Gu ×\(g.gu.count)")
                            .font(.caption2.bold())
                            .foregroundColor(Color(hex: "#D4537E"))
                    }
                    // 🔬 Suggestion indicator
                    if g.hasSuggestions {
                        Text("🔬").font(.caption)
                    }
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption2).foregroundColor(.secondary)
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            // Détail expandé
            if expanded {
                VStack(spacing: 10) {
                    // Besoins Abuseur / Victime
                    HStack(spacing: 8) {
                        BesoinsMenu(label: "Abuseur", selection: $g.abuseur, color: Color(hex: "#E24B4A"))
                        BesoinsMenu(label: "Victime", selection: $g.victime, color: Color(hex: "#185FA5"))
                    }
                    .padding(.horizontal, 12)
                    // 🔬 Suggestions Besoins
                    if !g.sugAbuseur.isEmpty || !g.sugVictime.isEmpty {
                        HStack(spacing: 8) {
                            if !g.sugAbuseur.isEmpty {
                                SuggestionAdopt(label: "Ab: \(g.sugAbuseur.split(separator: "|").last.map(String.init) ?? "?")") {
                                    g.abuseur = g.sugAbuseur; g.sugAbuseur = ""
                                }
                            }
                            if !g.sugVictime.isEmpty {
                                SuggestionAdopt(label: "Vi: \(g.sugVictime.split(separator: "|").last.map(String.init) ?? "?")") {
                                    g.victime = g.sugVictime; g.sugVictime = ""
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                    }

                    // Phases
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Phases").font(.caption2.bold()).foregroundColor(.secondary)
                        HStack(spacing: 6) {
                            ForEach(Phase.allCases) { ph in
                                TogglePill(label: ph.label, color: Color(hex: ph.color),
                                           active: g.phases.contains(ph)) {
                                    if g.phases.contains(ph) { g.phases.remove(ph) }
                                    else { g.phases.insert(ph) }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    // 🔬 Suggestion Phases
                    if !g.sugPhases.isEmpty {
                        SuggestionSetAdopt(label: "Phases", items: g.sugPhases.map(\.label)) {
                            g.phases = g.sugPhases; g.sugPhases = []
                        }.padding(.horizontal, 12)
                    }

                    // Gui 鬼
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Gui 鬼").font(.caption2.bold()).foregroundColor(.secondary)
                        FlowLayout(items: GuType.allCases, id: \.id) { gu in
                            TogglePill(label: gu.rawValue, color: Color(hex: "#D4537E"),
                                       active: g.gu.contains(gu)) {
                                if g.gu.contains(gu) { g.gu.remove(gu) }
                                else { g.gu.insert(gu) }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    // 🔬 Suggestion Gu
                    if !g.sugGu.isEmpty {
                        SuggestionSetAdopt(label: "Gui 鬼", items: g.sugGu.map(\.rawValue)) {
                            g.gu = g.sugGu; g.sugGu = []
                        }.padding(.horizontal, 12)
                    }

                    // Méridiens
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Méridiens").font(.caption2.bold()).foregroundColor(.secondary)
                        HStack(spacing: 5) {
                            ForEach(Meridian.observed) { m in
                                TogglePill(label: m.rawValue, color: Color(hex: m.color),
                                           active: g.meridiens.contains(m)) {
                                    if g.meridiens.contains(m) { g.meridiens.remove(m) }
                                    else { g.meridiens.insert(m) }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    // 🔬 Suggestion Méridiens
                    if !g.sugMeridiens.isEmpty {
                        SuggestionSetAdopt(label: "Méridiens", items: g.sugMeridiens.map(\.rawValue)) {
                            g.meridiens = g.sugMeridiens; g.sugMeridiens = []
                        }.padding(.horizontal, 12)
                    }

                    // Statut OART + Validé
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Statut").font(.caption2.bold()).foregroundColor(.secondary)
                            HStack(spacing: 5) {
                                ForEach(Statut.allCases, id: \.rawValue) { s in
                                    TogglePill(label: s.rawValue, color: Color(hex: "#BA7517"),
                                               active: g.statuts.contains(s)) {
                                        if g.statuts.contains(s) { g.statuts.remove(s) }
                                        else { g.statuts.insert(s) }
                                    }
                                }
                            }
                        }
                        Spacer()
                        Toggle(isOn: $g.validated) {
                            Text("Validée ✓")
                                .font(.caption.bold())
                                .foregroundColor(g.validated ? Color(hex: "#1D9E75") : .secondary)
                        }
                        .toggleStyle(.switch)
                        .tint(Color(hex: "#1D9E75"))
                        .onChange(of: g.validated) { _ in haptic(.medium) }
                    }
                    .padding(.horizontal, 12).padding(.bottom, 4)
                    // 🔬 Suggestion Statuts
                    if !g.sugStatuts.isEmpty {
                        SuggestionSetAdopt(label: "Statut", items: g.sugStatuts.map(\.rawValue)) {
                            g.statuts = g.sugStatuts; g.sugStatuts = []
                        }.padding(.horizontal, 12).padding(.bottom, 10)
                    }
                }
                .background(Color(hex: "#8B3A62").opacity(colorScheme == .dark ? 0.18 : 0.04))
            }
        }
    }
}

// MARK: - BesoinsMenu (Picker par catégorie)
struct BesoinsMenu: View {
    let label: String
    @Binding var selection: String
    let color: Color

    var displayLabel: String {
        selection.split(separator: "|").last.map(String.init) ?? "—"
    }

    var body: some View {
        Menu {
            Button("— Effacer") { selection = "" }
            ForEach(roueDesBesoins) { cat in
                Menu(cat.label) {
                    ForEach(cat.items, id: \.self) { item in
                        Button(item) { selection = "\(cat.id)|\(item)" }
                    }
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption2).foregroundColor(.secondary)
                HStack(spacing: 3) {
                    Text(displayLabel)
                        .font(.caption.bold())
                        .foregroundColor(selection.isEmpty ? .secondary : color)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8)).foregroundColor(.secondary)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color.opacity(0.08))
            .cornerRadius(8)
        }
    }
}

// MARK: - TogglePill
struct TogglePill: View {
    let label: String
    let color: Color
    let active: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(active ? .white : color)
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(active ? color : color.opacity(colorScheme == .dark ? 0.22 : 0.1))
                .cornerRadius(5)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - FlowLayout (grid adaptatif 3 colonnes)
struct FlowLayout<T: Identifiable, Content: View>: View {
    let items: [T]
    let id: KeyPath<T, String>
    @ViewBuilder let content: (T) -> Content

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())
        ], spacing: 4) {
            ForEach(items) { item in content(item) }
        }
    }
}

// MARK: - 🔬 Suggestion Adopt (single field)
struct SuggestionAdopt: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text("🔬").font(.system(size: 10))
                Text(label)
                    .font(.caption2.bold())
                    .foregroundColor(Color(hex: "#185FA5"))
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#185FA5"))
            }
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Color(hex: "#185FA5").opacity(0.10))
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6)
                .stroke(Color(hex: "#185FA5").opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 🔬 Suggestion Set Adopt (set of values)
struct SuggestionSetAdopt: View {
    let label: String
    let items: [String]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text("🔬").font(.system(size: 10))
                Text("\(label): \(items.joined(separator: ", "))")
                    .font(.caption2.bold())
                    .foregroundColor(Color(hex: "#185FA5"))
                    .lineLimit(2)
                Spacer()
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#185FA5"))
            }
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Color(hex: "#185FA5").opacity(0.10))
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6)
                .stroke(Color(hex: "#185FA5").opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - F25 — Fork galactique conditionnel au tier
struct ForkGalactiqueSection: View {
    let tier: PractitionerTier
    @EnvironmentObject var session: SessionState
    @State private var sephPrincipal = ""
    @State private var sephSecondaires: [String] = ["", "", "", "", ""]
    @State private var forkExpanded = false

    var body: some View {
        switch tier {
        case .superviseur:
            EmptyView()  // Tout visible sans filtre — pas de section fork

        case .certifiee:
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(Color(hex: "#1D9E75"))
                Text("Fork résolu par la certification")
                    .font(.caption.bold())
                    .foregroundColor(Color(hex: "#1D9E75"))
                Spacer()
            }
            .padding(12)
            .background(Color(hex: "#1D9E75").opacity(0.08))
            .cornerRadius(10)
            .padding(.horizontal, 16).padding(.vertical, 6)

        case .formation, .lead:
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(Color(hex: "#B8965A"))
                    Text("Fork galactique")
                        .font(.headline.bold())
                        .foregroundColor(Color(hex: "#8B3A62"))
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Code séphirothique principal")
                        .font(.caption2.bold()).foregroundColor(.secondary)
                    TextField("Ex: TIF-3-KET", text: $sephPrincipal)
                        .font(.body)
                        .padding(8)
                        .background(Color.white)
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(hex: "#B8965A").opacity(0.5), lineWidth: 1))
                }

                DisclosureGroup("5 codes secondaires", isExpanded: $forkExpanded) {
                    VStack(spacing: 6) {
                        ForEach(0..<5, id: \.self) { i in
                            TextField("Code \(i + 1)", text: $sephSecondaires[i])
                                .font(.caption)
                                .padding(6)
                                .background(Color.white)
                                .cornerRadius(4)
                                .overlay(RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color(hex: "#B8965A").opacity(0.3), lineWidth: 1))
                        }
                    }
                    .padding(.top, 6)
                }
                .font(.caption.bold())
                .foregroundColor(Color(hex: "#B8965A"))
            }
            .padding(14)
            .background(Color(hex: "#F5EDE4"))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "#B8965A"), lineWidth: 1.5))
            .padding(.horizontal, 16).padding(.vertical, 6)
        }
    }
}
