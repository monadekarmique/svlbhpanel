//
//  PDLPaletteView.swift
//  SVLBH Panel — importé de Palette de Lumière
//

import SwiftUI

struct PDLPaletteView: View {
    @EnvironmentObject var chromoManager: ChromotherapyManager
    @EnvironmentObject var elementManager: FiveElementsManager
    @State private var selectedElement: TCMElement?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Les 5 Éléments")
                        .font(.title2).fontWeight(.semibold)
                    Text("Touchez un élément pour explorer ses correspondances")
                        .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }

                fiveElementsCircle.padding(.vertical, 20)

                if let element = selectedElement {
                    PDLElementDetailCard(element: element)
                        .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                }

                WuXingPanel()
                Spacer(minLength: 100)
            }
            .padding()
        }
        .background(backgroundGradient)
    }

    private var fiveElementsCircle: some View {
        ZStack {
            Circle().stroke(Color.gray.opacity(0.2), lineWidth: 2).frame(width: 280, height: 280)
            cycleConnections
            ForEach(Array(TCMElement.allCases.enumerated()), id: \.element.id) { index, element in
                PDLElementButton(element: element, isSelected: selectedElement == element) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        selectedElement = selectedElement == element ? nil : element
                        chromoManager.setCurrentElement(element)
                    }
                }
                .offset(elementOffset(for: index))
            }
            Image(systemName: "circle.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(LinearGradient(colors: [.black, .white], startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        .frame(width: 320, height: 320)
    }

    private var cycleConnections: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius: CGFloat = 110
            var shengPath = Path()
            for i in 0..<5 {
                let angle = angleFor(index: i)
                let point = CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
                if i == 0 { shengPath.move(to: point) } else { shengPath.addLine(to: point) }
            }
            shengPath.closeSubpath()
            context.stroke(shengPath, with: .color(.green.opacity(0.3)), lineWidth: 2)
            var kePath = Path()
            let keOrder = [0, 2, 4, 1, 3]
            for (i, idx) in keOrder.enumerated() {
                let angle = angleFor(index: idx)
                let point = CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
                if i == 0 { kePath.move(to: point) } else { kePath.addLine(to: point) }
            }
            kePath.closeSubpath()
            context.stroke(kePath, with: .color(.red.opacity(0.2)), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
        }
        .frame(width: 280, height: 280)
    }

    private var quickColorPalette: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Palette rapide").font(.headline).padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CouleurTherapeutique.palette) { couleur in
                        VStack(spacing: 6) {
                            Circle().fill(couleur.color).frame(width: 50, height: 50)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .shadow(color: couleur.color.opacity(0.5), radius: 5)
                            Text(couleur.nom).font(.caption).foregroundStyle(.secondary)
                        }
                        .onTapGesture { withAnimation { chromoManager.currentColor = couleur.color } }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground).opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var backgroundGradient: some View {
        LinearGradient(colors: [chromoManager.currentColor.opacity(0.1), Color(.systemBackground)], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: chromoManager.currentColor)
    }

    private func elementOffset(for index: Int) -> CGSize {
        let angle = angleFor(index: index)
        let radius: CGFloat = 110
        return CGSize(width: radius * cos(angle), height: radius * sin(angle))
    }

    private func angleFor(index: Int) -> CGFloat {
        let startAngle = -CGFloat.pi / 2
        return startAngle + (CGFloat(index) * 2 * .pi / 5)
    }
}

struct PDLElementButton: View {
    let element: TCMElement
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle().fill(element.color)
                        .frame(width: isSelected ? 70 : 60, height: isSelected ? 70 : 60)
                        .shadow(color: element.color.opacity(0.6), radius: isSelected ? 12 : 6)
                    Text(element.symbol).font(.system(size: isSelected ? 28 : 24))
                }
                Text(element.rawValue).font(.caption).fontWeight(isSelected ? .bold : .medium)
                    .foregroundStyle(isSelected ? element.color : .primary)
            }
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

struct PDLElementDetailCard: View {
    let element: TCMElement

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(element.symbol).font(.largeTitle)
                VStack(alignment: .leading) {
                    Text(element.rawValue).font(.title2).fontWeight(.bold)
                    Text(element.saison).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Circle().fill(element.color).frame(width: 40, height: 40)
            }
            Divider()
            VStack(alignment: .leading, spacing: 12) {
                PDLDetailRow(label: "Organe Yin", value: element.organYin)
                PDLDetailRow(label: "Organe Yang", value: element.organYang)
                PDLDetailRow(label: "Émotion", value: "\(element.emotion) → \(element.emotionPositive)")
                PDLDetailRow(label: "Sens", value: element.sens)
                PDLDetailRow(label: "Tissu", value: element.tissu)
            }
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                Text("Points d'acupuncture clés").font(.subheadline).fontWeight(.semibold)
                ForEach(element.pointsCles, id: \.self) { point in
                    HStack {
                        Image(systemName: "circle.fill").font(.system(size: 6)).foregroundStyle(element.color)
                        Text(point).font(.caption)
                    }
                }
            }
            HStack(spacing: 20) {
                PDLCycleInfo(title: "Engendre", element: element.engendre, icon: "arrow.right.circle")
                PDLCycleInfo(title: "Contrôle", element: element.controle, icon: "arrow.down.circle")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: element.color.opacity(0.2), radius: 10)
    }
}

struct PDLDetailRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.subheadline).fontWeight(.medium)
        }
    }
}

struct PDLCycleInfo: View {
    let title: String
    let element: TCMElement
    let icon: String
    var body: some View {
        VStack(spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 4) {
                Image(systemName: icon).foregroundStyle(element.color)
                Text(element.rawValue).fontWeight(.medium)
            }
            .font(.subheadline)
        }
        .padding(8)
        .background(element.color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
