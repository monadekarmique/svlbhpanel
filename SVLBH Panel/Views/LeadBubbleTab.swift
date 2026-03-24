// SVLBHPanel — Views/LeadBubbleTab.swift
// v0.1.0 — Séquence 3 bulles lead : Pierres → Chakras/Dimensions → WhatsApp
// Déclenchement : 15 s après apparition onglet
// Neutralisation : tap sur la bulle active

import SwiftUI

// ═══════════════════════════════════════════════════════════
// MARK: - Onglet principal
// ═══════════════════════════════════════════════════════════

struct LeadBubbleTab: View {
    @EnvironmentObject var session: SessionState

    // 0 = rien, 1 = Pierres, 2 = Chakras, 3 = WhatsApp
    @State private var bubbleStep: Int = 0
    @State private var timerFired  = false
    @State private var showBubble  = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#F5EDE4"), Color(hex: "#8B3A62").opacity(0.12)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                Spacer()
                corpsHumain
                Spacer()
            }

            if showBubble && bubbleStep > 0 {
                bubbleOverlay
            }
        }
        .onAppear { startTimer() }
        .onDisappear { resetSequence() }
    }

    private func startTimer() {
        bubbleStep = 0; showBubble = false; timerFired = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            guard !timerFired else { return }
            timerFired = true
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                bubbleStep = 1; showBubble = true
            }
        }
    }

    private func resetSequence() {
        bubbleStep = 0; showBubble = false; timerFired = false
    }

    private func neutraliser() {
        withAnimation(.easeInOut(duration: 0.25)) { showBubble = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if bubbleStep < 3 {
                bubbleStep += 1
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { showBubble = true }
            } else {
                bubbleStep = 0
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - Header
// ═══════════════════════════════════════════════════════════

extension LeadBubbleTab {
    var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Décodage Vibratoire")
                    .font(.headline).foregroundColor(Color(hex: "#8B3A62"))
                Text("Vibrational Light Body Healing")
                    .font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
            Text("S\(session.sessionNum)")
                .font(.caption.bold())
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color(hex: "#8B3A62").opacity(0.12))
                .cornerRadius(8)
                .foregroundColor(Color(hex: "#8B3A62"))
        }
        .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 8)
    }

    var corpsHumain: some View {
        ZStack {
            SilhouetteShape()
                .fill(Color(hex: "#8B3A62").opacity(0.06))
                .overlay(SilhouetteShape().stroke(Color(hex: "#C27894").opacity(0.3), lineWidth: 1.5))
                .frame(width: 160, height: 340)
            ForEach(chakraPositions, id: \.name) { cp in
                ChakraDot(cp: cp, highlighted: bubbleStep == 2)
            }
        }
        .frame(height: 360)
    }

    var chakraPositions: [ChakraPosition] {[
        ChakraPosition(name: "Couronne",  color: "#9B59B6", yRatio: 0.03),
        ChakraPosition(name: "3ème œil", color: "#8B3A62", yRatio: 0.12),
        ChakraPosition(name: "Gorge",    color: "#2980B9", yRatio: 0.21),
        ChakraPosition(name: "Cœur",    color: "#27AE60", yRatio: 0.32),
        ChakraPosition(name: "Plexus",   color: "#F39C12", yRatio: 0.43),
        ChakraPosition(name: "Sacré",    color: "#E67E22", yRatio: 0.54),
        ChakraPosition(name: "Racine",   color: "#E24B4A", yRatio: 0.65),
    ]}

    @ViewBuilder
    var bubbleOverlay: some View {
        Color.black.opacity(0.18).ignoresSafeArea().onTapGesture { neutraliser() }
        VStack {
            Spacer()
            switch bubbleStep {
            case 1: BullePierres(pierres: session.pierres.filter(\.selected), onNeutralise: neutraliser)
            case 2: BulleChakras(cleaned: session.cleanedChakrasCount, total: session.totalChakras, onNeutralise: neutraliser)
            case 3: BulleWhatsApp(onNeutralise: neutraliser)
            default: EmptyView()
            }
            Spacer().frame(height: 60)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - Modèles chakras + silhouette
// ═══════════════════════════════════════════════════════════

struct ChakraPosition { let name: String; let color: String; let yRatio: Double }

struct ChakraDot: View {
    let cp: ChakraPosition; let highlighted: Bool
    @State private var pulse = false
    var body: some View {
        ZStack {
            if highlighted {
                Circle().fill(Color(hex: cp.color).opacity(0.25)).frame(width: 28, height: 28)
                    .scaleEffect(pulse ? 1.4 : 1.0)
                    .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: pulse)
                    .onAppear { pulse = true }.onDisappear { pulse = false }
            }
            Circle().fill(Color(hex: cp.color).opacity(highlighted ? 1.0 : 0.45))
                .frame(width: 14, height: 14)
                .shadow(color: Color(hex: cp.color).opacity(0.5), radius: highlighted ? 6 : 2)
        }
        .offset(y: CGFloat(cp.yRatio) * 340 - 170)
    }
}

struct SilhouetteShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path(); let w = rect.width, h = rect.height
        p.addEllipse(in: CGRect(x: w*0.3, y: 0, width: w*0.4, height: h*0.12))
        p.move(to: CGPoint(x: w*0.42, y: h*0.12)); p.addLine(to: CGPoint(x: w*0.42, y: h*0.16))
        p.addLine(to: CGPoint(x: w*0.58, y: h*0.16)); p.addLine(to: CGPoint(x: w*0.58, y: h*0.12))
        p.move(to: CGPoint(x: w*0.25, y: h*0.16)); p.addLine(to: CGPoint(x: w*0.75, y: h*0.16))
        p.addLine(to: CGPoint(x: w*0.72, y: h*0.55)); p.addLine(to: CGPoint(x: w*0.28, y: h*0.55))
        p.closeSubpath()
        p.move(to: CGPoint(x: w*0.25, y: h*0.16)); p.addLine(to: CGPoint(x: w*0.05, y: h*0.42))
        p.addLine(to: CGPoint(x: w*0.10, y: h*0.42)); p.addLine(to: CGPoint(x: w*0.30, y: h*0.18))
        p.move(to: CGPoint(x: w*0.75, y: h*0.16)); p.addLine(to: CGPoint(x: w*0.95, y: h*0.42))
        p.addLine(to: CGPoint(x: w*0.90, y: h*0.42)); p.addLine(to: CGPoint(x: w*0.70, y: h*0.18))
        p.move(to: CGPoint(x: w*0.28, y: h*0.55)); p.addLine(to: CGPoint(x: w*0.72, y: h*0.55))
        p.addLine(to: CGPoint(x: w*0.78, y: h*0.65)); p.addLine(to: CGPoint(x: w*0.22, y: h*0.65))
        p.closeSubpath()
        p.move(to: CGPoint(x: w*0.22, y: h*0.65)); p.addLine(to: CGPoint(x: w*0.28, y: h*0.65))
        p.addLine(to: CGPoint(x: w*0.30, y: h*1.0)); p.addLine(to: CGPoint(x: w*0.24, y: h*1.0))
        p.move(to: CGPoint(x: w*0.72, y: h*0.65)); p.addLine(to: CGPoint(x: w*0.78, y: h*0.65))
        p.addLine(to: CGPoint(x: w*0.76, y: h*1.0)); p.addLine(to: CGPoint(x: w*0.70, y: h*1.0))
        return p
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - Bulle 1 : Pierres
// ═══════════════════════════════════════════════════════════

struct BullePierres: View {
    let pierres: [PierreState]; let onNeutralise: () -> Void
    var body: some View {
        BulleCard(icon: "diamond.fill", iconColor: Color(hex: "#B8965A"),
                  titre: "Vos Pierres de Protection", tag: "1 / 3") {
            if pierres.isEmpty {
                Text("Aucune pierre sélectionnée pour cette séance.")
                    .font(.caption).foregroundColor(.secondary).padding(.horizontal, 4)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(pierres.prefix(6)) { p in
                        HStack(spacing: 6) {
                            Text(p.spec.icon).font(.title3)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(p.spec.nom).font(.caption.bold()).lineLimit(1)
                                Text("\(p.volume) \(p.unit) · \(p.durationMin) min")
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                        }
                        .padding(8).background(Color(hex: "#B8965A").opacity(0.08)).cornerRadius(8)
                    }
                }
            }
            Text("Ces pierres créent un champ vibratoire de protection\nautour de votre corps de lumière.")
                .font(.caption2).foregroundColor(.secondary)
                .multilineTextAlignment(.center).padding(.top, 4)
        } onNeutralise: { onNeutralise() }
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - Bulle 2 : Chakras + Dimensions
// ═══════════════════════════════════════════════════════════

struct BulleChakras: View {
    let cleaned: Int; let total: Int; let onNeutralise: () -> Void
    var pct: Double { total > 0 ? Double(cleaned) / Double(total) : 0 }
    var pctText: String { "\(Int(pct * 100))%" }
    var scoreLabel: String {
        if pct >= 0.85 { return "Corps de lumière aligné ✦" }
        if pct >= 0.60 { return "Nettoyage en cours…" }
        return "Décodage initial requis"
    }
    func statCell(label: String, value: String, color: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.caption.bold()).foregroundColor(Color(hex: color))
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(Color(hex: color).opacity(0.08)).cornerRadius(8)
    }
    var body: some View {
        BulleCard(icon: "circle.hexagongrid.fill", iconColor: Color(hex: "#8B3A62"),
                  titre: "Chakras & Dimensions Actifs", tag: "2 / 3") {
            VStack(spacing: 12) {
                ZStack {
                    Circle().stroke(Color(hex: "#8B3A62").opacity(0.15), lineWidth: 10)
                    Circle().trim(from: 0, to: pct)
                        .stroke(AngularGradient(colors: [Color(hex: "#C27894"), Color(hex: "#8B3A62")],
                                                center: .center),
                                style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text(pctText).font(.title2.bold()).foregroundColor(Color(hex: "#8B3A62"))
                        Text("nettoyé").font(.caption2).foregroundColor(.secondary)
                    }
                }.frame(width: 90, height: 90)
                Text(scoreLabel).font(.caption.bold()).foregroundColor(Color(hex: "#8B3A62"))
                HStack(spacing: 20) {
                    statCell(label: "Chakras", value: "\(cleaned)/\(total)", color: "#8B3A62")
                    statCell(label: "9 Dimensions", value: "actives", color: "#C27894")
                }
                Text("Le VLBH travaille sur 9 dimensions × 33 chakras\npour restaurer votre Score de Lumière.")
                    .font(.caption2).foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        } onNeutralise: { onNeutralise() }
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - Bulle 3 : WhatsApp
// ═══════════════════════════════════════════════════════════

struct BulleWhatsApp: View {
    let onNeutralise: () -> Void
    private let waURL = URL(string: "whatsapp://send?phone=41792168200&text=Bonjour%20Digital%20Shaman%20Lab%20%E2%80%94%20je%20voudrais%20en%20savoir%20plus%20sur%20le%20VLBH.")!
    var body: some View {
        BulleCard(icon: "message.fill", iconColor: Color(hex: "#25D366"),
                  titre: "Commencer votre Décodage", tag: "3 / 3") {
            VStack(spacing: 16) {
                Text("Chaque parcours de guérison est unique.\nPatrick et Cornelia vous accompagnent\nvers votre corps de lumière.")
                    .font(.callout).foregroundColor(.primary)
                    .multilineTextAlignment(.center).lineSpacing(4)
                Button {
                    UIApplication.shared.open(waURL)
                    onNeutralise()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "message.fill").font(.title3).foregroundColor(.white)
                        Text("Prendre contact sur WhatsApp").font(.callout.bold()).foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Color(hex: "#25D366")).cornerRadius(14)
                }
                .buttonStyle(.plain)
                Text("Digital Shaman Lab · Avenches, Suisse\nvlbh.energy")
                    .font(.caption2).foregroundColor(.secondary).multilineTextAlignment(.center)
            }
        } onNeutralise: { onNeutralise() }
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - Card bulle générique
// ═══════════════════════════════════════════════════════════

struct BulleCard<Content: View>: View {
    let icon: String; let iconColor: Color
    let titre: String; let tag: String
    @ViewBuilder let content: Content
    let onNeutralise: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(iconColor.opacity(0.15)).frame(width: 36, height: 36)
                    Image(systemName: icon).font(.system(size: 16)).foregroundColor(iconColor)
                }
                Text(titre).font(.headline).foregroundColor(.primary)
                Spacer()
                Text(tag).font(.caption2.bold())
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color(hex: "#8B3A62").opacity(0.1)).cornerRadius(6)
                    .foregroundColor(Color(hex: "#8B3A62"))
            }
            .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 14)
            Divider().padding(.horizontal, 20)
            content.padding(.horizontal, 20).padding(.vertical, 16)
            Divider().padding(.horizontal, 20)
            Button(action: onNeutralise) {
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle").font(.system(size: 14))
                    Text("Neutraliser").font(.subheadline.bold())
                }
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .foregroundColor(Color(hex: "#8B3A62"))
            }
            .buttonStyle(.plain)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color(hex: "#8B3A62").opacity(0.18), radius: 24, x: 0, y: -8)
        )
        .padding(.horizontal, 16)
    }
}
