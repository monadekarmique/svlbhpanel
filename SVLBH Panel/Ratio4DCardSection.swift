import SwiftUI

// MARK: - Ratio 4D Card Section (to embed in SVLBHTab session card)
//
// Usage in SVLBHTab.swift:
//   Replace the static ratio text with:
//     Ratio4DCardSection(passeport: session.passeport)
//
// The session card layout becomes:
//   [Patient | Ratio4DCardSection | Tier | Niveau]

// MARK: - Ratio Planète Card Section (même apparence que Ratio 4D)

struct RatioPlaneteCardSection: View {
    @ObservedObject var passeport: Passeport4DData
    @State private var showDetail = false

    var body: some View {
        Button { showDetail = true } label: {
            VStack(spacing: 2) {
                if let p = passeport.planete {
                    Text("\(p.symbol) \(p.rawValue)")
                        .font(.system(size: 8, weight: .semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(p.color.opacity(0.8))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if let computed = passeport.computedRatioPlanete {
                        Text(String(format: "%.2f\u{00d7}", computed))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(p.color)
                    } else {
                        Text(String(format: "%.0f\u{00d7}", p.multiplicateur))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(p.color)
                    }
                } else {
                    Text("\u{2014}")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Text("Plan\u{00e8}te")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            RatioPlaneteDetailView(passeport: passeport)
        }
    }
}

// MARK: - Opérateur énergétique

enum OperateurEnergetique: String, CaseIterable {
    case multiplication = "Multiplication"
    case exponentielle = "Exponentielle"
    case division = "Division"
    case logarithme = "Logarithme"

    var symbol: String {
        switch self {
        case .multiplication: "\u{00d7}"
        case .exponentielle: "e\u{02e3}"
        case .division: "\u{00f7}"
        case .logarithme: "log"
        }
    }

    func apply(base: Double, value: Double) -> Double {
        switch self {
        case .multiplication: return base * value
        case .exponentielle: return pow(base, value)
        case .division: return value != 0 ? base / value : 0
        case .logarithme: return value > 0 ? log(value) * base : 0
        }
    }
}

// MARK: - Phase lunaire (calcul astronomique simplifié)

private struct MoonPhaseInfo {
    let phase: Double        // 0.0–1.0
    let ageDays: Double
    let phaseName: String
    let illumination: Int    // %

    static func current(for date: Date = Date()) -> MoonPhaseInfo {
        // Référence : nouvelle lune connue le 6 janvier 2000 18:14 UTC
        let refNew = Date(timeIntervalSince1970: 947182440)
        let synodicMonth = 29.53058770576
        let daysSinceRef = date.timeIntervalSince(refNew) / 86400.0
        let cycles = daysSinceRef / synodicMonth
        let phase = cycles - floor(cycles)
        let ageDays = phase * synodicMonth
        let illumination = Int(round((1.0 - cos(phase * 2.0 * .pi)) / 2.0 * 100.0))

        let name: String
        switch phase {
        case 0..<0.0625:      name = "Nouvelle lune"
        case 0.0625..<0.1875: name = "Premier croissant"
        case 0.1875..<0.3125: name = "Premier quartier"
        case 0.3125..<0.4375: name = "Gibbeuse croissante"
        case 0.4375..<0.5625: name = "Pleine lune"
        case 0.5625..<0.6875: name = "Gibbeuse d\u{00e9}croissante"
        case 0.6875..<0.8125: name = "Dernier quartier"
        case 0.8125..<0.9375: name = "Dernier croissant"
        default:              name = "Nouvelle lune"
        }

        return MoonPhaseInfo(phase: phase, ageDays: ageDays, phaseName: name, illumination: illumination)
    }

    /// Prochaine pleine lune
    var nextFullMoon: (date: Date, daysUntil: Int) {
        let synodicMonth = 29.53058770576
        let refNew = Date(timeIntervalSince1970: 947182440)
        let now = Date()
        let daysSinceRef = now.timeIntervalSince(refNew) / 86400.0
        let cycles = daysSinceRef / synodicMonth
        let currentPhase = cycles - floor(cycles)
        // Pleine lune = phase 0.5
        var daysToFull = (0.5 - currentPhase) * synodicMonth
        if daysToFull < 0 { daysToFull += synodicMonth }
        let fullDate = now.addingTimeInterval(daysToFull * 86400)
        return (fullDate, Int(ceil(daysToFull)))
    }

    /// Emoji de la phase lunaire
    var emoji: String {
        switch phase {
        case 0..<0.0625:      return "\u{1F311}"  // 🌑
        case 0.0625..<0.1875: return "\u{1F312}"  // 🌒
        case 0.1875..<0.3125: return "\u{1F313}"  // 🌓
        case 0.3125..<0.4375: return "\u{1F314}"  // 🌔
        case 0.4375..<0.5625: return "\u{1F315}"  // 🌕
        case 0.5625..<0.6875: return "\u{1F316}"  // 🌖
        case 0.6875..<0.8125: return "\u{1F317}"  // 🌗
        case 0.8125..<0.9375: return "\u{1F318}"  // 🌘
        default:              return "\u{1F311}"  // 🌑
        }
    }
}

// MARK: - Ratio Planète Detail View

struct RatioPlaneteDetailView: View {
    @ObservedObject var passeport: Passeport4DData
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPlanete: PlaneteType = .lune
    @State private var operateur: OperateurEnergetique = .multiplication
    @State private var sldta9DInput: String = ""
    @State private var moonPhase = MoonPhaseInfo.current()

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    // Table de référence
    static let refPlanetes: [(planete: PlaneteType, periode: String, sldtaOrigine: Int, sldtaCh: Int)] = [
        (.lune, "900 000 ans", 155, 12),
        // Saturne et Mercure : à compléter
    ]

    private var selectedEntry: (planete: PlaneteType, periode: String, sldtaOrigine: Int, sldtaCh: Int)? {
        Self.refPlanetes.first { $0.planete == selectedPlanete }
    }

    private var sldta9D: Double? { Double(sldta9DInput) }

    private var ratioPlanete: Double? {
        guard let entry = selectedEntry, let s = sldta9D, entry.sldtaCh > 0 else { return nil }
        return operateur.apply(base: s, value: Double(entry.sldtaCh))
    }

    private func ratioColor(_ r: Double?) -> Color {
        guard let r else { return .gray }
        if r <= 3 { return .green }
        if r <= 10 { return .orange }
        return .pink
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ratioHeader
                    moonCard
                    inputSection
                    if selectedEntry != nil {
                        baselineCard
                    }
                    referenceTable
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Ratio Plan\u{00e8}te")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
            .onAppear { restoreFromPasseport() }
            .onReceive(timer) { _ in moonPhase = MoonPhaseInfo.current() }
        }
    }

    private func restoreFromPasseport() {
        if let p = passeport.planete { selectedPlanete = p }
        if let r = passeport.ratioPlanete { sldta9DInput = String(format: "%.0f", r) }
    }

    private func saveToPasseport() {
        passeport.planete = selectedPlanete
        if let r = ratioPlanete {
            passeport.ratioPlanete = r
        }
    }

    // MARK: - Ratio Header

    private var ratioHeader: some View {
        VStack(spacing: 6) {
            Text("\(selectedPlanete.symbol) \(selectedPlanete.rawValue)")
                .font(.caption).fontWeight(.semibold).textCase(.uppercase)
                .foregroundStyle(selectedPlanete.color)

            Text(ratioPlanete.map { String(format: "%.2f\u{00d7}", $0) } ?? "\u{2014}")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(ratioColor(ratioPlanete))

            Text("Ratio Plan\u{00e8}te")
                .font(.subheadline).foregroundColor(Color(hex: "#1A2A4A"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Moon Phase Card

    private var fullMoonDateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "d MMMM yyyy"
        df.locale = Locale(identifier: "fr_CH")
        return df
    }

    private var moonCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 16) {
                Text(moonPhase.emoji)
                    .font(.system(size: 44))

                VStack(alignment: .leading, spacing: 4) {
                    Text(moonPhase.phaseName)
                        .font(.subheadline.bold())
                        .foregroundColor(Color(hex: "#798EF6"))
                    Text("Illumination : \(moonPhase.illumination)%")
                        .font(.caption).foregroundColor(.secondary)
                    Text(String(format: "\u{00c2}ge : %.1f jours", moonPhase.ageDays))
                        .font(.caption).foregroundColor(.secondary)
                }

                Spacer()
            }

            // Prochaine pleine lune
            let fullMoon = moonPhase.nextFullMoon
            HStack(spacing: 8) {
                Text("\u{1F315}").font(.title3)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Prochaine pleine lune 100%")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "#798EF6"))
                    Text("\(fullMoonDateFormatter.string(from: fullMoon.date)) \u{2014} dans \(fullMoon.daysUntil) jour\(fullMoon.daysUntil > 1 ? "s" : "")")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(8)
            .background(Color(hex: "#798EF6").opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Mesure")

            // Planète picker
            HStack {
                Text("Plan\u{00e8}te").font(.subheadline).foregroundColor(Color(hex: "#1A2A4A"))
                Spacer()
                Picker("", selection: $selectedPlanete) {
                    ForEach(PlaneteType.allCases, id: \.self) { p in
                        Text("\(p.symbol) \(p.rawValue)").tag(p)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color(hex: "#798EF6"))
            }
            .padding(.horizontal).padding(.vertical, 8)

            Divider().padding(.leading)

            // Opérateur énergétique
            HStack {
                Text("Op\u{00e9}rateur \u{00e9}nerg\u{00e9}tique").font(.subheadline).foregroundColor(Color(hex: "#1A2A4A"))
                Spacer()
                Picker("", selection: $operateur) {
                    ForEach(OperateurEnergetique.allCases, id: \.self) { op in
                        Text("\(op.symbol) \(op.rawValue)").tag(op)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color(hex: "#798EF6"))
            }
            .padding(.horizontal).padding(.vertical, 8)

            Divider().padding(.leading)

            // SLdTA 9D
            HStack {
                Text("SLdTA 9D %").font(.subheadline).foregroundColor(Color(hex: "#1A2A4A"))
                Text("(mesure)").font(.caption2).foregroundStyle(Color(hex: "#798EF6"))
                Spacer()
                TextField("ex. 155", text: $sldta9DInput)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .font(.subheadline.bold())
                    .frame(width: 100)
                    .onChange(of: sldta9DInput) { _ in saveToPasseport() }
            }
            .padding(.horizontal).padding(.vertical, 8)
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        .onChange(of: selectedPlanete) { _ in saveToPasseport() }
        .onChange(of: operateur) { _ in saveToPasseport() }
    }

    // MARK: - Baseline Card

    private var baselineCard: some View {
        let entry = selectedEntry!
        return VStack(spacing: 0) {
            sectionHeader("\(entry.planete.symbol) \(entry.planete.rawValue) \u{2014} \(entry.periode)")

            row("SLdTA origine", "\(entry.sldtaOrigine)%", valueColor: Color(hex: "#2B5EA7"))
            Divider().padding(.leading)
            row("SLdTA CH", "\(entry.sldtaCh)%", valueColor: Color(hex: "#C28D43"))
            Divider().padding(.leading)
            row("P\u{00e9}riode", entry.periode, valueColor: .secondary)

            if let r = ratioPlanete, let s = sldta9D {
                Divider().padding(.leading)
                HStack {
                    Text("Formule").font(.subheadline).foregroundColor(Color(hex: "#1A2A4A"))
                    Spacer()
                    Text("\(String(format: "%.0f", s))% \(operateur.symbol) \(entry.sldtaCh)% = ")
                        .font(.caption).foregroundColor(Color(hex: "#1A2A4A"))
                    Text(String(format: "%.2f\u{00d7}", r))
                        .font(.subheadline.bold()).foregroundStyle(ratioColor(r))
                }
                .padding(.horizontal).padding(.vertical, 8)
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Reference Table

    private var referenceTable: some View {
        VStack(spacing: 0) {
            sectionHeader("Table de r\u{00e9}f\u{00e9}rence")

            HStack {
                Text("Plan\u{00e8}te").font(.caption2).fontWeight(.semibold).frame(maxWidth: .infinity, alignment: .leading)
                Text("P\u{00e9}riode").font(.caption2).fontWeight(.semibold).frame(width: 90, alignment: .trailing)
                Text("SLdTA orig.").font(.caption2).fontWeight(.semibold).frame(width: 70, alignment: .trailing)
                Text("SLdTA CH").font(.caption2).fontWeight(.semibold).frame(width: 65, alignment: .trailing)
            }
            .padding(.horizontal).padding(.vertical, 6)
            .background(Color(.tertiarySystemGroupedBackground))

            ForEach(Self.refPlanetes, id: \.planete) { entry in
                let isSelected = entry.planete == selectedPlanete
                HStack {
                    HStack(spacing: 4) {
                        Text(entry.planete.symbol).font(.caption)
                        Text(entry.planete.rawValue).font(.caption)
                            .fontWeight(isSelected ? .bold : .regular)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text(entry.periode)
                        .font(.caption).frame(width: 90, alignment: .trailing)
                    Text("\(entry.sldtaOrigine)%")
                        .font(.caption).frame(width: 70, alignment: .trailing)
                    Text("\(entry.sldtaCh)%")
                        .font(.caption).frame(width: 65, alignment: .trailing)
                }
                .padding(.horizontal).padding(.vertical, 6)
                .background(isSelected ? selectedPlanete.color.opacity(0.12) : Color.clear)
                .onTapGesture { selectedPlanete = entry.planete }
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.footnote).fontWeight(.semibold).foregroundColor(Color(hex: "#1A2A4A"))
            .textCase(.uppercase)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal).padding(.top, 12).padding(.bottom, 4)
    }

    private func row(_ label: String, _ value: String, valueColor: Color = .primary) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundColor(Color(hex: "#1A2A4A"))
            Spacer()
            Text(value).font(.subheadline).fontWeight(.medium).foregroundStyle(valueColor)
        }
        .padding(.horizontal).padding(.vertical, 8)
    }
}

struct Ratio4DCardSection: View {
    @ObservedObject var passeport: Passeport4DData
    @State private var showDetail = false

    var body: some View {
        Button { showDetail = true } label: {
            VStack(spacing: 2) {
                // Cluster label above
                if let cluster = passeport.cluster, !cluster.isEmpty {
                    Text(passeport.clusterDisplay)
                        .font(.system(size: 8, weight: .semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(passeport.ratioColor.opacity(0.8))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                // Ratio value
                if let ratio = passeport.ratio4D {
                    Text(String(format: "%.2f\u{00d7}", ratio))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(passeport.ratioColor)
                } else {
                    Text("—")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                // Label
                Text("Ratio 4D")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            Ratio4DDetailView(passeport: passeport)
        }
    }
}
