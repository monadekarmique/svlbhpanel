import SwiftUI

// MARK: - Ratio 4D Detail View (sheet)

struct Ratio4DDetailView: View {
    @ObservedObject var passeport: Passeport4DData
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPays: String = ""
    @State private var anneeTrauma: String = ""
    @State private var sltda4DInput: String = ""

    // Table 21S embarquée
    static let ref21S: [(pays: String, slsaCh: Int, sltdaOrig: Int, sltdaCh: Int)] = [
        ("Iran",            9176, 1,  78),
        ("Ukraine",         1922, 3,  49),
        ("Pologne",         1118, 2,  19),
        ("USA",              857, 7,  45),
        ("Kosovo",           465, 45, 178),
        ("C\u{00f4}te d'Ivoire", 424, 5,  18),
        ("Cambodge",         314, 48, 128),
        ("England",          216, 43, 79),
        ("France",           196, 15, 25),
        ("Serbie",           180, 19, 29),
        ("Suisse",           136, 85, 98),
        ("Espagne",          133, 15, 17),
        ("Su\u{00e8}de",     128, 89, 97),
        ("Alg\u{00e9}rie",   96,  48, 39),
        ("UK",                86,  74, 54),
        ("Allemagne",         55,  75, 35),
        ("Italie",            50,  28, 12),
        ("Turquie",           50,  45, 19),
        ("S\u{00e9}n\u{00e9}gal", 42, 39, 14),
        ("Portugal",          37,  45, 14),
        ("Tibet",             18,  94, 14),
    ]

    private var selectedEntry: (pays: String, slsaCh: Int, sltdaOrig: Int, sltdaCh: Int)? {
        Self.ref21S.first { $0.pays == selectedPays }
    }

    private var baseline: Int? { selectedEntry?.slsaCh }

    private var sltda4D: Double? { Double(sltda4DInput) }

    private var ratio4D: Double? {
        guard let b = baseline, b > 0, let s = sltda4D else { return nil }
        return s / Double(b)
    }

    private func clusterLabel(_ slsaCh: Int) -> String {
        if slsaCh > 800 { return "Hypersensibilit\u{00e9} extr\u{00ea}me" }
        if slsaCh >= 128 { return "Sensibilit\u{00e9} active" }
        return "Compression"
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
                    inputSection
                    if selectedEntry != nil {
                        baselineCard
                    }
                    referenceTable
                    explanationCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Passeport SVLBH")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
            .onAppear { restoreFromPasseport() }
        }
    }

    // MARK: - Restore existing data

    private func restoreFromPasseport() {
        if let p = passeport.paysOrigine, !p.isEmpty { selectedPays = p }
        if let t = passeport.dateTrauma, !t.isEmpty { anneeTrauma = t }
        if let h = passeport.slsaHistorique { sltda4DInput = "\(h)" }
    }

    // MARK: - Save to passeport

    private func saveToPasseport() {
        guard let entry = selectedEntry, let r = ratio4D, let s = sltda4D else { return }
        passeport.paysOrigine = selectedPays
        passeport.dateTrauma = anneeTrauma
        passeport.slsaHistorique = Int(s)
        passeport.slsaChBaseline = entry.slsaCh
        passeport.sltdaOrigine = entry.sltdaOrig
        passeport.sltdaCh = entry.sltdaCh
        passeport.ratio4D = r
        passeport.cluster = clusterLabel(entry.slsaCh)
    }

    // MARK: - Ratio Header

    private var ratioHeader: some View {
        VStack(spacing: 6) {
            if let entry = selectedEntry {
                Text(clusterLabel(entry.slsaCh))
                    .font(.caption).fontWeight(.semibold).textCase(.uppercase)
                    .foregroundStyle(ratioColor(ratio4D))
            }

            Text(ratio4D.map { String(format: "%.2f\u{00d7}", $0) } ?? "\u{2014}")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(ratioColor(ratio4D))

            Text("Ratio 4D")
                .font(.subheadline).foregroundColor(Color(hex: "#1A2A4A"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Mesure")

            // Pays picker
            HStack {
                Text("Pays d'origine").font(.subheadline).foregroundColor(Color(hex: "#1A2A4A"))
                Spacer()
                Picker("", selection: $selectedPays) {
                    Text("\u{2014} S\u{00e9}lectionner \u{2014}").tag("")
                    ForEach(Self.ref21S.sorted(by: { $0.pays < $1.pays }), id: \.pays) { entry in
                        Text(entry.pays).tag(entry.pays)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color(hex: "#8B3A62"))
            }
            .padding(.horizontal).padding(.vertical, 8)

            Divider().padding(.leading)

            // Année trauma
            HStack {
                Text("Ann\u{00e9}e du trauma").font(.subheadline).foregroundColor(Color(hex: "#1A2A4A"))
                Spacer()
                TextField("ex. 1515", text: $anneeTrauma)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .font(.subheadline.bold())
                    .frame(width: 100)
            }
            .padding(.horizontal).padding(.vertical, 8)

            Divider().padding(.leading)

            // SLTdA 4D
            HStack {
                Text("SLTdA 4D %").font(.subheadline).foregroundColor(Color(hex: "#1A2A4A"))
                Text("(mesure)").font(.caption2).foregroundStyle(Color(hex: "#BD3482"))
                Spacer()
                TextField("ex. 45880", text: $sltda4DInput)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .font(.subheadline.bold())
                    .frame(width: 100)
                    .onChange(of: sltda4DInput) { _ in saveToPasseport() }
            }
            .padding(.horizontal).padding(.vertical, 8)
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        .onChange(of: selectedPays) { _ in saveToPasseport() }
    }

    // MARK: - Baseline Card (auto after country selection)

    private var baselineCard: some View {
        let entry = selectedEntry!
        return VStack(spacing: 0) {
            sectionHeader("Baseline 21S \u{2014} \(entry.pays)")

            row("SLTdA-CH\u{2192}\(entry.pays) Baseline", "\(entry.slsaCh)%",
                valueColor: ratioColor(ratio4D))
            Divider().padding(.leading)
            row("SLTdA origine", "\(entry.sltdaOrig)%", valueColor: Color(hex: "#2B5EA7"))
            Divider().padding(.leading)
            row("SLTdA combin\u{00e9} CH", "\(entry.sltdaCh)%", valueColor: Color(hex: "#C28D43"))
            Divider().padding(.leading)
            row("Cluster", clusterLabel(entry.slsaCh), valueColor: ratioColor(ratio4D))

            if let r = ratio4D {
                Divider().padding(.leading)
                HStack {
                    Text("Formule").font(.subheadline).foregroundColor(Color(hex: "#1A2A4A"))
                    Spacer()
                    Text("\(sltda4DInput)% \u{00f7} \(entry.slsaCh)% = ")
                        .font(.caption).foregroundColor(Color(hex: "#1A2A4A"))
                    Text(String(format: "%.2f\u{00d7}", r))
                        .font(.subheadline.bold()).foregroundStyle(ratioColor(r))
                }
                .padding(.horizontal).padding(.vertical, 8)
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 21S Reference Table

    private var referenceTable: some View {
        VStack(spacing: 0) {
            sectionHeader("Table de r\u{00e9}f\u{00e9}rence 21\u{1d49}")

            HStack {
                Text("Pays").font(.caption2).fontWeight(.semibold).frame(maxWidth: .infinity, alignment: .leading)
                Text("SLSA_CH").font(.caption2).fontWeight(.semibold).frame(width: 75, alignment: .trailing)
                Text("SLTdA orig.").font(.caption2).fontWeight(.semibold).frame(width: 75, alignment: .trailing)
                Text("SLTdA CH").font(.caption2).fontWeight(.semibold).frame(width: 75, alignment: .trailing)
            }
            .padding(.horizontal).padding(.vertical, 6)
            .background(Color(.tertiarySystemGroupedBackground))

            ForEach(Self.ref21S.sorted(by: { $0.sltdaCh > $1.sltdaCh }), id: \.pays) { entry in
                let isSelected = entry.pays == selectedPays
                HStack {
                    Text(entry.pays)
                        .font(.caption).frame(maxWidth: .infinity, alignment: .leading)
                        .fontWeight(isSelected ? .bold : .regular)
                    Text("\(entry.slsaCh)%")
                        .font(.caption).frame(width: 75, alignment: .trailing)
                    Text("\(entry.sltdaOrig)%")
                        .font(.caption).frame(width: 75, alignment: .trailing)
                    Text("\(entry.sltdaCh)%")
                        .font(.caption).frame(width: 75, alignment: .trailing)
                }
                .padding(.horizontal).padding(.vertical, 4)
                .background(isSelected ? ratioColor(ratio4D).opacity(0.12) : Color.clear)
                .onTapGesture { selectedPays = entry.pays }

                if entry.pays != Self.ref21S.last?.pays {
                    Divider().padding(.leading)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Explanation

    private var explanationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Qu'est-ce que le Ratio 4D ?")

            Text("""
            Le Ratio 4D mesure le poids \u{00e9}nerg\u{00e9}tique port\u{00e9} par le patient \
            par rapport au baseline de son pays d'origine au 21\u{00e8}me si\u{00e8}cle.

            \u{2022} **Formule** : SLTdA 4D \u{00f7} SLTdA-CH Baseline 21S
            \u{2022} **1\u{00d7}** = le patient porte exactement le poids de r\u{00e9}f\u{00e9}rence
            \u{2022} **> 10\u{00d7}** = surcharge \u{00e9}nerg\u{00e9}tique majeure

            **Clusters :**
            \u{2022} **Compression** (SLSA_CH < 128%) \u{2014} \u{00e9}nergie contenue
            \u{2022} **Sensibilit\u{00e9} active** (128\u{2013}800%) \u{2014} r\u{00e9}activit\u{00e9} \u{00e9}lev\u{00e9}e
            \u{2022} **Hypersensibilit\u{00e9} extr\u{00ea}me** (> 800%) \u{2014} terrain tr\u{00e8}s charg\u{00e9}
            """)
            .font(.caption)
            .foregroundColor(Color(hex: "#1A2A4A"))
            .padding(.horizontal)
            .padding(.bottom, 12)
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
