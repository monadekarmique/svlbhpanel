//
//  PDLDiagnosticView.swift
//  SVLBH Panel — importé de Palette de Lumière
//

import SwiftUI

struct PDLDiagnosticView: View {
    @EnvironmentObject var elementManager: FiveElementsManager
    @State private var currentBilan: BilanEnergetique?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let bilan = currentBilan ?? elementManager.bilans.last {
                    PDLEnergyRadarChart(bilan: bilan).frame(height: 300).padding()
                } else {
                    emptyStateView
                }
                if currentBilan != nil { elementSlidersSection }
                if !elementManager.bilans.isEmpty { recommendationsSection }
                historySection
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { withAnimation { currentBilan = elementManager.creerNouveauBilan() } } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.path.ecg").font(.system(size: 60)).foregroundStyle(.secondary)
            Text("Aucun bilan énergétique").font(.title3).fontWeight(.semibold)
            Text("Créez votre premier bilan pour analyser l'équilibre de vos 5 éléments")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button { withAnimation { currentBilan = elementManager.creerNouveauBilan() } } label: {
                Label("Nouveau bilan", systemImage: "plus")
                    .padding().background(Color.accentColor).foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(40)
    }

    private var elementSlidersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Évaluation énergétique").font(.headline)
            ForEach(TCMElement.allCases) { element in
                PDLElementSlider(element: element, bilan: $currentBilan)
            }
            HStack(spacing: 16) {
                Button("Annuler") { withAnimation { currentBilan = nil } }.foregroundStyle(.secondary)
                Spacer()
                Button {
                    if currentBilan != nil { elementManager.sauvegarderBilan(notes: ""); currentBilan = nil }
                } label: {
                    Label("Enregistrer", systemImage: "checkmark.circle.fill")
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(Color.green).foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.top)
        }
        .padding().background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16)).shadow(radius: 5)
    }

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommandations").font(.headline)
            let recommandations = elementManager.recommandationsCouleurs()
            if recommandations.isEmpty {
                Text("Vos éléments sont équilibrés").foregroundStyle(.secondary).padding()
            } else {
                ForEach(recommandations.prefix(3)) { reco in
                    PDLRecommendationCard(recommandation: reco)
                }
            }
        }
        .padding().background(Color(.systemBackground)).clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Historique").font(.headline)
            if elementManager.bilans.isEmpty {
                Text("Aucun historique").foregroundStyle(.secondary)
            } else {
                ForEach(elementManager.bilans.suffix(5).reversed()) { bilan in
                    PDLBilanHistoryRow(bilan: bilan)
                }
            }
        }
        .padding().background(Color(.systemBackground)).clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct PDLElementSlider: View {
    let element: TCMElement
    @Binding var bilan: BilanEnergetique?
    private var niveau: Double { bilan?.niveaux[element]?.niveau ?? 0.5 }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(element.symbol); Text(element.rawValue).fontWeight(.medium)
                Spacer()
                Text(niveauText).font(.caption).foregroundStyle(.secondary)
            }
            HStack {
                Text("Vide").font(.caption2).foregroundStyle(.secondary)
                Slider(value: Binding(get: { niveau }, set: { bilan?.niveaux[element]?.niveau = $0 }), in: 0...1).tint(element.color)
                Text("Plénitude").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var niveauText: String {
        switch niveau {
        case 0..<0.3: return "Vide"
        case 0.3..<0.45: return "Faible"
        case 0.45..<0.55: return "Équilibré"
        case 0.55..<0.7: return "Fort"
        default: return "Plénitude"
        }
    }
}

struct PDLEnergyRadarChart: View {
    let bilan: BilanEnergetique

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius: CGFloat = min(geometry.size.width, geometry.size.height) / 2.5
            ZStack {
                referenceCircles(radius: radius)
                filledArea(center: center, radius: radius)
                strokeArea(center: center, radius: radius)
                labels(center: center, radius: radius)
            }
        }
    }

    private func referenceCircles(radius: CGFloat) -> some View {
        ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { level in
            Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1)
                .frame(width: radius * 2 * level, height: radius * 2 * level)
        }
    }

    private func radarPath(center: CGPoint, radius: CGFloat) -> Path {
        Path { path in
            for (index, element) in TCMElement.allCases.enumerated() {
                let angle = angleFor(index: index)
                let niveau = bilan.niveaux[element]?.niveau ?? 0.5
                let dist: CGFloat = radius * CGFloat(niveau)
                let x = center.x + dist * CoreGraphics.cos(angle)
                let y = center.y + dist * CoreGraphics.sin(angle)
                let point = CGPoint(x: x, y: y)
                if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.closeSubpath()
        }
    }

    private func filledArea(center: CGPoint, radius: CGFloat) -> some View {
        let gradientColors: [Color] = TCMElement.allCases.map { $0.color.opacity(0.3) }
        return radarPath(center: center, radius: radius)
            .fill(LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
    }

    private func strokeArea(center: CGPoint, radius: CGFloat) -> some View {
        radarPath(center: center, radius: radius)
            .stroke(Color.accentColor, lineWidth: 2)
    }

    private func labels(center: CGPoint, radius: CGFloat) -> some View {
        let labelRadius = radius + 30
        return ForEach(Array(TCMElement.allCases.enumerated()), id: \.element.id) { index, element in
            let angle = angleFor(index: index)
            VStack(spacing: 2) {
                Text(element.symbol)
                Text(element.rawValue).font(.caption2)
            }
            .position(x: center.x + labelRadius * CoreGraphics.cos(angle), y: center.y + labelRadius * CoreGraphics.sin(angle))
        }
    }

    private func angleFor(index: Int) -> CGFloat {
        -CGFloat.pi / 2 + (CGFloat(index) * 2 * .pi / 5)
    }
}

struct PDLRecommendationCard: View {
    let recommandation: RecommandationCouleur

    var body: some View {
        HStack(spacing: 12) {
            Circle().fill(recommandation.couleur).frame(width: 40, height: 40)
                .shadow(color: recommandation.couleur.opacity(0.5), radius: 4)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(recommandation.action.rawValue) \(recommandation.element.rawValue)").font(.subheadline).fontWeight(.medium)
                Text("\(recommandation.dureeRecommandee) min recommandées").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(recommandation.priorite == .haute ? "Urgent" : "Normal")
                .font(.caption2).fontWeight(.semibold).padding(.horizontal, 8).padding(.vertical, 4)
                .background(recommandation.priorite == .haute ? Color.red : Color.gray)
                .foregroundStyle(.white).clipShape(Capsule())
        }
        .padding().background(recommandation.couleur.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct PDLBilanHistoryRow: View {
    let bilan: BilanEnergetique
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(bilan.date, style: .date).font(.subheadline).fontWeight(.medium)
                Text(bilan.date, style: .time).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 4) {
                ForEach(TCMElement.allCases) { element in
                    Circle().fill(element.color).frame(width: 12, height: 12)
                        .opacity(bilan.niveaux[element]?.niveau ?? 0.5)
                }
            }
        }
        .padding(.vertical, 8)
    }
}
