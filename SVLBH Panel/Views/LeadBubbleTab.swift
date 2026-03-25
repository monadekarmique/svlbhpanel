// SVLBHPanel — Views/LeadBubbleTab.swift
// v4.8.0 — Carrousel patchwork 2×2 avec fond hDOM 3D + dots navigation

import SwiftUI

// ═══════════════════════════════════════════════════════════
// MARK: - Onglet principal — Carrousel patchwork
// ═══════════════════════════════════════════════════════════

struct LeadBubbleTab: View {
    @EnvironmentObject var session: SessionState

    /// Page courante du carrousel (0 = patchwork, 1 = pierres, 2 = chakras)
    @State private var currentPage = 0
    private let totalPages = 3

    /// Quadrants visibles (animation séquentielle 2s)
    @State private var visibleQuadrants: Set<Int> = []
    @State private var animationTimer: Timer?

    var body: some View {
        ZStack {
            // ── Fond hDOM 3D ──
            Image("hdom_background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.25).ignoresSafeArea())

            VStack(spacing: 0) {
                headerBar
                Spacer()

                // ── Contenu paginé ──
                TabView(selection: $currentPage) {
                    patchworkPage.tag(0)
                    pierresPage.tag(1)
                    chakrasPage.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                Spacer()

                // ── Dots navigation ──
                dotsIndicator
                    .padding(.bottom, 24)
            }
        }
        .onAppear { startPatchworkAnimation() }
        .onDisappear { stopAnimation() }
        .onChange(of: currentPage) { page in
            if page == 0 { restartPatchworkAnimation() }
        }
    }

    // MARK: - Animation séquentielle

    private func startPatchworkAnimation() {
        visibleQuadrants = []
        var step = 0
        animationTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            if step < 4 {
                withAnimation(.easeInOut(duration: 0.6)) {
                    visibleQuadrants.insert(step)
                }
                step += 1
            } else {
                timer.invalidate()
            }
        }
        // Quadrant 0 apparaît immédiatement
        withAnimation(.easeInOut(duration: 0.6)) {
            visibleQuadrants.insert(0)
        }
        // step 0 déjà fait, commencer à 1
        var stepCount = 1
        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            if stepCount < 4 {
                withAnimation(.easeInOut(duration: 0.6)) {
                    visibleQuadrants.insert(stepCount)
                }
                stepCount += 1
            } else {
                timer.invalidate()
            }
        }
    }

    private func restartPatchworkAnimation() {
        stopAnimation()
        startPatchworkAnimation()
    }

    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - Header
// ═══════════════════════════════════════════════════════════

extension LeadBubbleTab {
    var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Comment faire ?")
                    .font(.headline).foregroundColor(.white)
                Text("Vibrational Light Body Healing")
                    .font(.caption2).foregroundColor(.white.opacity(0.7))
            }
            Spacer()
            Text("S\(session.sessionNum)")
                .font(.caption.bold())
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.white.opacity(0.2))
                .cornerRadius(8)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 8)
    }

    // MARK: - Dots

    var dotsIndicator: some View {
        HStack(spacing: 10) {
            ForEach(0..<totalPages, id: \.self) { idx in
                Circle()
                    .fill(idx == currentPage ? Color.white : Color.white.opacity(0.4))
                    .frame(width: idx == currentPage ? 10 : 7,
                           height: idx == currentPage ? 10 : 7)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - Page 1 : Patchwork 2×2
// ═══════════════════════════════════════════════════════════

extension LeadBubbleTab {
    var patchworkPage: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 10
            let padH: CGFloat = 16
            let available = geo.size.width - padH * 2 - spacing
            let cellW = available / 2
            let cellH = cellW * 0.85

            VStack(spacing: spacing) {
                // Rangée haute : ① ②
                HStack(spacing: spacing) {
                    patchworkCell(
                        index: 0,
                        title: "Décodage Vibratoire",
                        text: "Le VLBH décode les charges transgénérationnelles inscrites dans votre Corps de Lumière à travers 9 dimensions.",
                        color: Color(hex: "#8B3A62")
                    )
                    .frame(width: cellW, height: cellH)

                    patchworkCell(
                        index: 1,
                        title: "Méridiens & Chakras",
                        text: "46 chakras et 12 méridiens sont analysés pour identifier les blocages énergétiques et restaurer la circulation.",
                        color: Color(hex: "#185FA5")
                    )
                    .frame(width: cellW, height: cellH)
                }

                // Rangée basse : ④ ③
                HStack(spacing: spacing) {
                    // ④ Logo SVLBH
                    logoCell
                        .frame(width: cellW, height: cellH)

                    patchworkCell(
                        index: 2,
                        title: "Pierres de Protection",
                        text: "Des pierres vibratoires spécifiques créent un champ de protection autour de votre Sur-Âme pendant le soin.",
                        color: Color(hex: "#B8965A")
                    )
                    .frame(width: cellW, height: cellH)
                }
            }
            .padding(.horizontal, padH)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    func patchworkCell(index: Int, title: String, text: String, color: Color) -> some View {
        let isVisible = visibleQuadrants.contains(index)
        ZStack {
            if isVisible {
                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(color)
                        .multilineTextAlignment(.center)
                    Text(text)
                        .font(.system(size: 11))
                        .foregroundColor(.primary.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
                .cornerRadius(14)
                .shadow(color: color.opacity(0.2), radius: 8, y: 4)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    var logoCell: some View {
        let isVisible = visibleQuadrants.contains(3)
        return ZStack {
            if isVisible {
                VStack(spacing: 6) {
                    Image("logo_svlbh")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
                .cornerRadius(14)
                .shadow(color: Color(hex: "#8B3A62").opacity(0.2), radius: 8, y: 4)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - Page 2 : Pierres
// ═══════════════════════════════════════════════════════════

extension LeadBubbleTab {
    var pierresPage: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Image(systemName: "diamond.fill")
                    .font(.title).foregroundColor(Color(hex: "#B8965A"))
                Text("Vos Pierres de Protection")
                    .font(.headline).foregroundColor(.white)
            }

            let selected = session.pierres.filter(\.selected)
            if selected.isEmpty {
                Text("Aucune pierre sélectionnée\npour cette séance.")
                    .font(.callout).foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(selected.prefix(6)) { p in
                        HStack(spacing: 6) {
                            Text(p.spec.icon).font(.title3)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(p.spec.nom).font(.caption.bold()).foregroundColor(.white).lineLimit(1)
                                Text("\(p.volume) \(p.unit) · \(p.durationMin) min")
                                    .font(.caption2).foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 20)
            }

            Text("Ces pierres créent un champ vibratoire\nde protection autour de votre corps de lumière.")
                .font(.caption).foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - Page 3 : Chakras
// ═══════════════════════════════════════════════════════════

extension LeadBubbleTab {
    var chakrasPage: some View {
        let cleaned = session.cleanedChakrasCount
        let total = session.totalChakras
        let pct = total > 0 ? Double(cleaned) / Double(total) : 0

        return VStack(spacing: 20) {
            VStack(spacing: 6) {
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.title).foregroundColor(Color(hex: "#C27894"))
                Text("Chakras & Dimensions")
                    .font(.headline).foregroundColor(.white)
            }

            ZStack {
                Circle().stroke(Color.white.opacity(0.2), lineWidth: 10)
                Circle().trim(from: 0, to: pct)
                    .stroke(
                        AngularGradient(colors: [Color(hex: "#C27894"), Color(hex: "#8B3A62")], center: .center),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(Int(pct * 100))%")
                        .font(.title.bold()).foregroundColor(.white)
                    Text("nettoyé")
                        .font(.caption2).foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(width: 110, height: 110)

            HStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text("\(cleaned)/\(total)")
                        .font(.headline.bold()).foregroundColor(.white)
                    Text("Chakras").font(.caption2).foregroundColor(.white.opacity(0.7))
                }
                .padding(12).background(.ultraThinMaterial).cornerRadius(10)

                VStack(spacing: 2) {
                    Text("9")
                        .font(.headline.bold()).foregroundColor(.white)
                    Text("Dimensions").font(.caption2).foregroundColor(.white.opacity(0.7))
                }
                .padding(12).background(.ultraThinMaterial).cornerRadius(10)
            }

            Text("Le VLBH travaille sur 9 dimensions × 46 chakras\npour restaurer votre Score de Lumière.")
                .font(.caption).foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
