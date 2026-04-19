//
//  PDLHotlineSidebarView.swift
//  SVLBH Panel — Sidebar Hotline (droite→gauche)
//  Intègre: Scores de Lumière, Johrei_25, Sephiroth, Protocole de Séance
//

import SwiftUI

// MARK: - Sidebar Container
struct PDLHotlineSidebarView: View {
    @Binding var isOpen: Bool
    @StateObject private var vm = HotlineSidebarVM()

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .trailing) {
                // Dimmed background
                if isOpen {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture { withAnimation(.easeInOut(duration: 0.3)) { isOpen = false } }
                }
                // Sidebar panel
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("⚡ Hotline DSL").font(.headline).foregroundStyle(Color(hex: "#8B3A62"))
                        Spacer()
                        Button { withAnimation(.easeInOut(duration: 0.3)) { isOpen = false } } label: {
                            Image(systemName: "xmark.circle.fill").font(.title2).foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(hex: "#F5EDE4"))

                    // Scrollable content
                    ScrollView {
                        VStack(spacing: 20) {
                            scoresSection
                            johreiSection
                            wuShenSection
                            sephirothSection
                            protocoleSection
                        }
                        .padding()
                    }
                }
                .frame(width: min(geo.size.width * 0.85, 420))
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.2), radius: 20)
                .offset(x: isOpen ? 0 : min(geo.size.width * 0.85, 420) + 20)
                .animation(.easeInOut(duration: 0.3), value: isOpen)
            }
        }
    }

    // MARK: - 1. Scores de Lumière
    private var scoresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Scores de Lumière", systemImage: "lightbulb.fill")
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(Color(hex: "#8B3A62"))

            HStack(spacing: 8) {
                ForEach(ScoreDeLumiere.allCases, id: \.self) { score in
                    VStack(spacing: 6) {
                        Text(score.label).font(.caption2).fontWeight(.bold)
                        TextField("%", text: vm.bindingForScore(score))
                            .font(.title3).fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .frame(width: 60, height: 44)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(vm.scoreColor(score), lineWidth: 2))
                            .keyboardType(.numberPad)
                        Text("Seuil: \(score.seuil)%")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }

            // Dynamic total
            let total = vm.scoreTotal
            HStack {
                Spacer()
                Text("Total: \(total)").font(.caption).fontWeight(.bold)
                    .foregroundStyle(total >= 235 ? .green : Color(hex: "#8B3A62"))
                Spacer()
            }
        }
        .padding().background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color(hex: "#8B3A62").opacity(0.1), radius: 5)
    }

    // MARK: - 2. Johrei_25 Compass
    private var johreiSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Johrei_25 — Screening", systemImage: "scope")
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(Color(hex: "#8B3A62"))

            // Compass circle
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Color.purple.opacity(0.2), Color.purple.opacity(0.5)],
                                         center: .center, startRadius: 0, endRadius: 80))
                    .frame(width: 160, height: 160)
                    .overlay(Circle().stroke(Color(hex: "#8B3A62"), lineWidth: 2))

                // Quadrant buttons
                ForEach(JohreiQuadrant.allCases, id: \.self) { q in
                    Button { vm.selectedQuadrant = (vm.selectedQuadrant == q) ? nil : q } label: {
                        quadrantWedge(q)
                    }
                }

                Circle().fill(Color(hex: "#8B3A62")).frame(width: 10, height: 10)

                // Labels N/S/E/O
                Text("N").font(.caption2).fontWeight(.bold).foregroundStyle(Color(hex: "#8B3A62")).offset(y: -75)
                Text("S").font(.caption2).fontWeight(.bold).foregroundStyle(Color(hex: "#8B3A62")).offset(y: 75)
                Text("E").font(.caption2).fontWeight(.bold).foregroundStyle(Color(hex: "#8B3A62")).offset(x: 75)
                Text("O").font(.caption2).fontWeight(.bold).foregroundStyle(Color(hex: "#8B3A62")).offset(x: -75)
            }
            .frame(maxWidth: .infinity)

            if let q = vm.selectedQuadrant {
                Text(q.description)
                    .font(.caption).foregroundStyle(.secondary)
                    .padding(8).background(Color(hex: "#F5EDE4")).clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Johrei options
            VStack(alignment: .leading, spacing: 8) {
                Text("Image").font(.caption).fontWeight(.semibold)
                HStack(spacing: 8) {
                    JohreiPill(label: "Unique ✓", selected: !vm.johreiDedoublee) { vm.johreiDedoublee = false }
                    JohreiPill(label: "Dédoublée ✗", selected: vm.johreiDedoublee) { vm.johreiDedoublee = true }
                }

                Text("Intensité").font(.caption).fontWeight(.semibold)
                HStack(spacing: 6) {
                    ForEach(JohreiIntensity.allCases, id: \.self) { i in
                        JohreiPill(label: i.label, selected: vm.johreiIntensity == i) { vm.johreiIntensity = i }
                    }
                }

                Text("Profondeur (lot)").font(.caption).fontWeight(.semibold)
                HStack(spacing: 6) {
                    ForEach(JohreiDepth.allCases, id: \.self) { d in
                        JohreiPill(label: d.label, selected: vm.johreiDepth == d) { vm.johreiDepth = d }
                    }
                }
            }
        }
        .padding().background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color(hex: "#8B3A62").opacity(0.1), radius: 5)
    }

    // MARK: - 3. Wu Shen (五神)
    private var wuShenSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("5 Parties de l'Âme — Wu Shen (五神)", systemImage: "sparkles")
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(Color(hex: "#8B3A62"))

            Text("Cliquer = fragment détecté").font(.caption2).foregroundStyle(.secondary)

            HStack(spacing: 6) {
                ForEach(WuShenPart.allCases, id: \.self) { part in
                    Button { vm.toggleWuShen(part) } label: {
                        VStack(spacing: 4) {
                            Text(part.icon).font(.title3)
                            Text(part.hanzi).font(.title3).foregroundStyle(part.color)
                            Text("(\(part.number)) \(part.name)").font(.caption2).fontWeight(.bold)
                            Text(part.organ).font(.caption2).foregroundStyle(.secondary)
                            Text(part.element).font(.caption2).foregroundStyle(part.color)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(vm.wuShenFragmented.contains(part) ? part.color.opacity(0.15) : Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(vm.wuShenFragmented.contains(part) ? part.color : Color.clear, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding().background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color(hex: "#8B3A62").opacity(0.1), radius: 5)
    }

    // MARK: - 4. Sephiroth — Code 3 Chiffres
    private var sephirothSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Sephiroth — Code 3 Chiffres", systemImage: "leaf.fill")
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(Color(hex: "#6B7B3A"))

            // Code 3 chiffres inputs
            HStack(spacing: 16) {
                SephCodeInput(label: "♀ Gauche\n(féminin)", value: $vm.sephCodeGauche, color: Color(hex: "#C27894"))
                SephCodeInput(label: "◎ Centre\n(conflit)", value: $vm.sephCodeCentre, color: Color(hex: "#6B7B3A"))
                SephCodeInput(label: "♂ Droite\n(masculin)", value: $vm.sephCodeDroite, color: Color(hex: "#4A6FA5"))
            }

            // Compact Sephiroth tree
            VStack(spacing: 4) {
                sephRow([(.center, "1", "Kether", Color(hex: "#B8965A"))])
                sephRow([(.left, "2", "Chokmah", .blue.opacity(0.6)), (.right, "3", "Binah", Color(hex: "#C27894").opacity(0.7))])
                sephRow([(.left, "4", "Chesed", .blue.opacity(0.6)), (.right, "5", "Geburah", Color(hex: "#C27894"))])
                sephRow([(.center, "6", "Tiphareth", Color(hex: "#B8965A"))])
                sephRow([(.left, "7", "Netzach", .blue.opacity(0.6)), (.right, "8", "Hod", Color(hex: "#C27894"))])
                sephRow([(.center, "9", "Yesod", Color(hex: "#6B7B3A"))])
                sephRow([(.center, "10", "Malkuth", Color(hex: "#B8965A"))])
            }
            .padding(8)
            .background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding().background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color(hex: "#6B7B3A").opacity(0.1), radius: 5)
    }

    // MARK: - 5. Protocole de Séance
    private var protocoleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Protocole de Séance", systemImage: "bolt.fill")
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(Color(hex: "#8B3A62"))

            ForEach(ProtocolePhase.allPhases) { phase in
                HStack(alignment: .top, spacing: 12) {
                    // Timeline dot + line
                    VStack(spacing: 0) {
                        Circle()
                            .fill(vm.completedPhases.contains(phase.id) ? Color(hex: "#8B3A62") : Color(.systemGray4))
                            .frame(width: 20, height: 20)
                            .overlay(
                                vm.completedPhases.contains(phase.id)
                                ? Image(systemName: "checkmark").font(.caption2).foregroundStyle(.white)
                                : nil
                            )
                        if phase.id != ProtocolePhase.allPhases.last?.id {
                            Rectangle().fill(Color(.systemGray4)).frame(width: 2, height: 30)
                        }
                    }

                    // Phase content
                    VStack(alignment: .leading, spacing: 2) {
                        Text(phase.titre).font(.caption).fontWeight(.bold)
                        Text(phase.description).font(.caption2).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    .onTapGesture { vm.togglePhase(phase.id) }
                }
            }
        }
        .padding().background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color(hex: "#8B3A62").opacity(0.1), radius: 5)
    }

    // MARK: - Helpers
    private func quadrantWedge(_ q: JohreiQuadrant) -> some View {
        Circle().trim(from: q.trimFrom, to: q.trimTo)
            .fill(vm.selectedQuadrant == q ? Color(hex: "#8B3A62").opacity(0.35) : Color.clear)
            .frame(width: 160, height: 160)
    }

    enum SephPosition { case left, center, right }

    private func sephRow(_ nodes: [(SephPosition, String, String, Color)]) -> some View {
        HStack {
            if nodes.count == 1 && nodes[0].0 == .center {
                Spacer()
            }
            ForEach(nodes, id: \.1) { pos, num, name, color in
                if pos == .right { Spacer() }
                Button { vm.selectedSephirah = num } label: {
                    VStack(spacing: 1) {
                        Text(num).font(.caption).fontWeight(.bold)
                        Text(name).font(.caption2)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(vm.selectedSephirah == num ? color.opacity(0.3) : Color.clear)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(color, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
                if pos == .left { Spacer() }
            }
            if nodes.count == 1 && nodes[0].0 == .center {
                Spacer()
            }
        }
    }
}

// MARK: - Reusable Components
struct JohreiPill: View {
    let label: String; let selected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label).font(.caption2).fontWeight(selected ? .bold : .regular)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(selected ? Color(hex: "#8B3A62") : Color(.systemGray6))
                .foregroundStyle(selected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct SephCodeInput: View {
    let label: String; @Binding var value: String; let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Text(label).font(.caption2).multilineTextAlignment(.center).foregroundStyle(.secondary)
            TextField("—", text: $value)
                .font(.title3).fontWeight(.bold).multilineTextAlignment(.center)
                .frame(width: 70, height: 44)
                .background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(color, lineWidth: 1.5))
                .keyboardType(.numberPad)
        }
    }
}

// MARK: - ViewModel
class HotlineSidebarVM: ObservableObject {
    @Published var sla = ""; @Published var slsa = ""; @Published var slpmo = ""; @Published var slm = ""
    @Published var selectedQuadrant: JohreiQuadrant?
    @Published var johreiDedoublee = false
    @Published var johreiIntensity: JohreiIntensity = .leger
    @Published var johreiDepth: JohreiDepth = .l1
    @Published var wuShenFragmented: Set<WuShenPart> = []
    @Published var sephCodeGauche = ""; @Published var sephCodeCentre = ""; @Published var sephCodeDroite = ""
    @Published var selectedSephirah: String?
    @Published var completedPhases: Set<String> = []

    var scoreTotal: Int {
        (Int(sla) ?? 0) + (Int(slsa) ?? 0) + (Int(slpmo) ?? 0) + (Int(slm) ?? 0)
    }

    func bindingForScore(_ score: ScoreDeLumiere) -> Binding<String> {
        switch score {
        case .sla:   return Binding(get: { self.sla },   set: { self.sla = $0 })
        case .slsa:  return Binding(get: { self.slsa },  set: { self.slsa = $0 })
        case .slpmo: return Binding(get: { self.slpmo }, set: { self.slpmo = $0 })
        case .slm:   return Binding(get: { self.slm },   set: { self.slm = $0 })
        }
    }

    func scoreColor(_ score: ScoreDeLumiere) -> Color {
        let val = Int(bindingForScore(score).wrappedValue) ?? 0
        return val >= score.seuilInt ? .green : Color(hex: "#C27894")
    }

    func toggleWuShen(_ part: WuShenPart) {
        if wuShenFragmented.contains(part) { wuShenFragmented.remove(part) }
        else { wuShenFragmented.insert(part) }
    }

    func togglePhase(_ id: String) {
        if completedPhases.contains(id) { completedPhases.remove(id) }
        else { completedPhases.insert(id) }
    }
}

// MARK: - Models
enum ScoreDeLumiere: String, CaseIterable {
    case sla, slsa, slpmo, slm
    var label: String { rawValue.uppercased() }
    var seuil: Int { switch self { case .sla: 78; case .slsa: 32; case .slpmo: 25; case .slm: 100 } }
    var seuilInt: Int { seuil }
}

enum JohreiQuadrant: String, CaseIterable {
    case ne, se, so, no
    var trimFrom: CGFloat { switch self { case .ne: 0.75; case .se: 0.0; case .so: 0.25; case .no: 0.5 } }
    var trimTo: CGFloat { trimFrom + 0.25 }
    var description: String {
        switch self {
        case .ne: "Q I — NE — Abus / Monde ext."
        case .se: "Q II — SE — Abus / Famille"
        case .so: "Q III — SO — Meurtre / Famille"
        case .no: "Q IV — NO — Meurtre / Monde ext."
        }
    }
}

enum JohreiIntensity: String, CaseIterable {
    case leger, marque, extreme
    var label: String { switch self { case .leger: "Léger (Sag.)"; case .marque: "Marqué (Cor.)"; case .extreme: "Extrême (Tr.)" } }
}

enum JohreiDepth: String, CaseIterable {
    case l1, l2, l3, l4, l5
    var label: String { switch self { case .l1: "L1"; case .l2: "L2"; case .l3: "L3"; case .l4: "L4"; case .l5: "L5" } }
}

enum WuShenPart: String, CaseIterable {
    case hun, shen, po, yi, zhi
    var number: Int { switch self { case .hun: 1; case .shen: 2; case .po: 3; case .yi: 4; case .zhi: 5 } }
    var name: String { rawValue.capitalized }
    var hanzi: String { switch self { case .hun: "魂"; case .shen: "神"; case .po: "魄"; case .yi: "意"; case .zhi: "志" } }
    var organ: String { switch self { case .hun: "Foie (LR)"; case .shen: "Cœur (HT)"; case .po: "Poumon (LU)"; case .yi: "Rate (SP)"; case .zhi: "Rein (KI)" } }
    var element: String { switch self { case .hun: "Bois"; case .shen: "Feu"; case .po: "Métal"; case .yi: "Terre"; case .zhi: "Eau" } }
    var icon: String { switch self { case .hun: "🌿"; case .shen: "🔥"; case .po: "🤍"; case .yi: "🌍"; case .zhi: "💧" } }
    var color: Color {
        switch self {
        case .hun: Color.green; case .shen: Color.red
        case .po: Color.gray; case .yi: Color(hex: "#B8965A")
        case .zhi: Color.blue
        }
    }
}

struct ProtocolePhase: Identifiable {
    let id: String; let titre: String; let description: String

    static let allPhases: [ProtocolePhase] = [
        .init(id: "m1", titre: "Phase -1 : Apaiser la Monade", description: "TOUJOURS en premier. SLM = 100% requis. Vérifier cordage."),
        .init(id: "p0", titre: "Phase 0 : Secondary Gain", description: "Lever le bénéfice secondaire."),
        .init(id: "p0b", titre: "Phase 0b : Screening Johrei_25", description: "Test visuel rapide. Profondeur, direction, intensité, couches."),
        .init(id: "p1", titre: "Phase 1 : Chakra 15 — Réécrire le Mythe (D4)", description: "Mère Universelle, égrégores. Corps Mental 4D."),
        .init(id: "p2", titre: "Phase 2 : Chakra 12 — Router Galactique", description: "Réparer le routeur galactique."),
        .init(id: "p2b", titre: "Phase 2b : Conflit Yin/Yang", description: "Résoudre le conflit de polarité."),
        .init(id: "p3", titre: "Phase 3 : Chakra 9 — Pont Cœur Supérieur", description: "Restaurer la connexion cœur supérieur."),
        .init(id: "p4", titre: "Phase 4 : Chakra 5 — Porte du Cœur (CV17)", description: "Fermer la porte du cœur."),
        .init(id: "p5a", titre: "Phase 5a : CUBE — Patient Zéro", description: "Ego actif. Meurtres/Abus/Vols. Plans transverses."),
        .init(id: "p5b", titre: "Phase 5b : ICOSAÈDRE × n — Victimes", description: "Lots de 20 victimes. Eau. S0→S3."),
        .init(id: "p5c", titre: "Phase 5c : ICOSAÈDRE — Débris Kessler", description: "Nettoyage résiduel."),
        .init(id: "p5d", titre: "Phase 5d : DODÉCAÈDRE — Monade S8", description: "Consciences perpétuelles. Éther. S1→S8."),
        .init(id: "p5bis", titre: "Phase 5bis : Johrei Modifié — Lots de 5", description: "Scanner éons. Batch par lot. Vérifier H3 → 0."),
        .init(id: "p6", titre: "Phase 6 : Libération Physique Résiduelle", description: "Somatisation restante, douleurs résiduelles."),
        .init(id: "seal", titre: "Scellement : Mudra + Om Nama Shivaya", description: "SLA = 100%. Séance terminée."),
    ]
}
