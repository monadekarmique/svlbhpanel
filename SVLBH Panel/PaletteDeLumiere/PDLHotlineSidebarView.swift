//
//  PDLHotlineSidebarView.swift
//  SVLBH Panel — Sidebar Hotline (droite→gauche)
//  Intègre: Scores de Lumière, Johrei_25, Sephiroth, Protocole de Séance
//

import SwiftUI

// MARK: - Sidebar Container
struct PDLHotlineSidebarView: View {
    @Binding var isOpen: Bool
    /// Si true, rend en pleine page (utilisé par l'onglet Hotline en niveau 1).
    var embedded: Bool = false
    @StateObject private var vm = HotlineSidebarVM()

    var body: some View {
        if embedded {
            // Rendu pleine page pour l'onglet top-level Hotline (Patrick 2026-05-04).
            ScrollView {
                VStack(spacing: 20) {
                    Text("\u{26a1} En cas d\u{2019}\u{00c9}nergies Sombres identifi\u{00e9}es")
                        .font(.title3.bold())
                        .foregroundStyle(Color(hex: "#8B3A62"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    securiteSection
                    corpsEMSection
                    transfertsSection
                    scoresSection
                    johreiSection
                    wuShenSection
                    matriceDesordreSection
                    mandalaSection
                    fiveElementsSection
                    glandesSection
                    mandelbrotSection
                    sephirothSection
                    protocoleSection
                }
                .padding()
            }
        } else {
            sidebarOverlay
        }
    }

    private var sidebarOverlay: some View {
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
                        Text("\u{26a1} En cas d\u{2019}\u{00c9}nergies Sombres identifi\u{00e9}es").font(.subheadline.bold()).foregroundStyle(Color(hex: "#8B3A62"))
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
                            securiteSection
                            corpsEMSection
                            transfertsSection
                            scoresSection
                            johreiSection
                            wuShenSection
                            matriceDesordreSection
                            mandalaSection
                            fiveElementsSection
                            glandesSection
                            mandelbrotSection
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

    // MARK: - 0a. Sécurité 10⁸
    private var securiteSection: some View {
        VStack(spacing: 8) {
            Text(vm.securiteValidee
                 ? "\u{2705} S\u{00e9}curit\u{00e9} 10\u{2078} valid\u{00e9}e \u{2014} Protocole d\u{00e9}verrouill\u{00e9}"
                 : "\u{1f512} S\u{00e9}curit\u{00e9} 10\u{2078} non valid\u{00e9}e \u{2014} Protocole verrouill\u{00e9}")
                .font(.caption.weight(.semibold))
                .foregroundStyle(vm.securiteValidee ? .green : Color(hex: "#8B3A62"))
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(vm.securiteValidee ? Color.green.opacity(0.08) : Color(hex: "#FFF0F0"))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - 0b. Corps électromagnétiques
    private var corpsEMSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Corps \u{00e9}lectromagn\u{00e9}tiques d\u{00e9}s\u{00e9}quilibr\u{00e9}s par des conflits")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(LinearGradient(colors: [Color(hex: "#4A6741"), Color(hex: "#6B8F62")], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            HStack(spacing: 8) {
                ForEach([
                    ("Corps Mental", $vm.corpsMental),
                    ("Corps \u{00c9}motionnel", $vm.corpsEmotionnel),
                    ("Corps Bouddhique", $vm.corpsBouddhique)
                ], id: \.0) { label, binding in
                    Toggle(isOn: binding) {
                        Text(label).font(.caption2.weight(.medium))
                    }
                    .toggleStyle(.button)
                    .tint(Color(hex: "#4A6741"))
                }
            }
        }
        .padding().background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color(hex: "#4A6741").opacity(0.1), radius: 5)
    }

    // MARK: - 0c. Libération des Transferts
    private var transfertsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\u{1f319} Lib\u{00e9}ration des Transferts")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(LinearGradient(colors: [Color(hex: "#6B2D50"), Color(hex: "#8B3A62")], startPoint: .leading, endPoint: .trailing))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            HStack(spacing: 16) {
                // EGO — Puissance de Fragmentation
                VStack(spacing: 4) {
                    Text("EGO \u{2014} PUISSANCE DE FRAGMENTATION")
                        .font(.system(size: 7, weight: .medium)).foregroundStyle(.secondary)
                        .textCase(.uppercase).tracking(1)
                    HStack(spacing: 4) {
                        Text("5").font(.title2.weight(.bold)).foregroundStyle(Color(hex: "#B8965A"))
                        TextField("n", text: $vm.egoN)
                            .font(.system(size: 12, weight: .bold))
                            .frame(width: 28, height: 22)
                            .multilineTextAlignment(.center)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .keyboardType(.numberPad)
                            .overlay(Text("n").font(.system(size: 8)).foregroundStyle(.secondary).opacity(vm.egoN.isEmpty ? 1 : 0))
                        Text("=").foregroundStyle(.secondary)
                        Text(vm.egoPuissance.map { formatLargeNumber($0) } ?? "\u{2014}")
                            .font(.title3.weight(.bold)).foregroundStyle(Color(hex: "#8B3A62"))
                    }
                    Text("Saisir n dans la Matrice")
                        .font(.system(size: 8)).foregroundStyle(Color(hex: "#B8965A"))
                }
                .frame(maxWidth: .infinity)

                // Dilution des comportements
                VStack(spacing: 4) {
                    Text("DILUTION DES COMPORTEMENTS")
                        .font(.system(size: 7, weight: .medium)).foregroundStyle(.secondary)
                        .textCase(.uppercase).tracking(1)
                    HStack(spacing: 4) {
                        Text("1 / 5").font(.caption.weight(.bold)).foregroundStyle(Color(hex: "#8B3A62"))
                        Text("n").font(.system(size: 9, weight: .bold)).foregroundStyle(Color(hex: "#8B3A62")).baselineOffset(6)
                        Text("=").foregroundStyle(.secondary)
                        Text(vm.egoDilution.map { String(format: "%.2e", $0) } ?? "\u{2014}")
                            .font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundStyle(Color(hex: "#8B3A62"))
                            .lineLimit(1).minimumScaleFactor(0.6)
                    }
                    Text(vm.dilutionLabel.isEmpty ? "Intensit\u{00e9} r\u{00e9}siduelle par fragment" : vm.dilutionLabel)
                        .font(.system(size: 8)).foregroundStyle(Color(hex: "#B8965A"))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(12)
            .background(Color(hex: "#B8965A").opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#B8965A").opacity(0.3), lineWidth: 1))
        }
        .padding().background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color(hex: "#8B3A62").opacity(0.1), radius: 5)
    }

    // MARK: - Helper
    private func formatLargeNumber(_ n: Double) -> String {
        if n >= 1_000_000 { return String(format: "%.1e", n) }
        if n >= 1_000 { return String(format: "%.0f", n) }
        return String(format: "%.0f", n)
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

    // MARK: - 2. Johrei_25 — Référence
    private var johreiSection: some View {
        VStack(spacing: 10) {
            // Pattern concentrique avec directions
            ZStack {
                // Fond violet clair
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.purple.opacity(0.15))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#C27894"), lineWidth: 2))

                // Carrés concentriques
                ForEach(0..<8, id: \.self) { i in
                    let size = CGFloat(180 - i * 20)
                    let strokeColor = i % 2 == 0 ? Color(hex: "#4A1528") : Color(hex: "#8B3A62")
                    RoundedRectangle(cornerRadius: CGFloat(2 + i))
                        .stroke(strokeColor, lineWidth: CGFloat(3 - Double(i) * 0.2))
                        .frame(width: size, height: size)
                }

                // Centre
                Circle().fill(Color(hex: "#8B3A62").opacity(0.3)).frame(width: 16, height: 16)
                Circle().fill(Color(hex: "#8B3A62")).frame(width: 6, height: 6)

                // Directions
                Text("NO").font(.system(size: 9, weight: .bold)).foregroundStyle(Color(hex: "#8B3A62"))
                    .position(x: 20, y: 16)
                Text("NE").font(.system(size: 9, weight: .bold)).foregroundStyle(Color(hex: "#8B3A62"))
                    .position(x: 185, y: 16)
                Text("SO").font(.system(size: 9, weight: .bold)).foregroundStyle(Color(hex: "#8B3A62"))
                    .position(x: 20, y: 190)
                Text("SE").font(.system(size: 9, weight: .bold)).foregroundStyle(Color(hex: "#8B3A62"))
                    .position(x: 185, y: 190)
            }
            .frame(width: 205, height: 205)
            .frame(maxWidth: .infinity)

            Text("Johrei_25 \u{2014} R\u{00e9}f\u{00e9}rence")
                .font(.caption).foregroundStyle(.secondary)

            // Options compactes
            VStack(alignment: .leading, spacing: 8) {
                Text("Image").font(.caption).fontWeight(.semibold)
                HStack(spacing: 8) {
                    JohreiPill(label: "Unique \u{2713}", selected: !vm.johreiDedoublee) { vm.johreiDedoublee = false }
                    JohreiPill(label: "D\u{00e9}doubl\u{00e9}e \u{2717}", selected: vm.johreiDedoublee) { vm.johreiDedoublee = true }
                }

                Text("Intensit\u{00e9}").font(.caption).fontWeight(.semibold)
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

    // MARK: - 3b. Matrice de Désordre n × m
    private var matriceDesordreSection: some View {
        let eons = ["5D", "4D", "3D"]
        let lots = [
            ("L1", "1-5"), ("L2", "6-10"), ("L3", "11-15"),
            ("L4", "16-20"), ("L5", "21-25")
        ]

        return VStack(alignment: .leading, spacing: 10) {
            Label("Matrice de D\u{00e9}sordre n \u{00d7} m", systemImage: "chart.bar.fill")
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(LinearGradient(colors: [Color(hex: "#6B2D50"), Color(hex: "#8B3A62")], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Text("Cliquer sur les cellules o\u{00f9} H3 \u{2260} 0 (charge active mesurable).")
                .font(.system(size: 10)).foregroundStyle(.secondary)

            // Header row
            HStack(spacing: 0) {
                Text("").frame(width: 30)
                ForEach(lots, id: \.0) { lot in
                    VStack(spacing: 1) {
                        Text(lot.0).font(.system(size: 10, weight: .bold))
                        Text(lot.1).font(.system(size: 8)).foregroundStyle(.secondary).italic()
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // Grid rows
            ForEach(eons, id: \.self) { eon in
                HStack(spacing: 4) {
                    Text(eon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: "#8B3A62"))
                        .frame(width: 30)

                    ForEach(lots, id: \.0) { lot in
                        let key = "\(eon)-\(lot.0)"
                        let isActive = vm.matriceCells.contains(key)
                        Button { vm.toggleMatriceCell(key) } label: {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isActive ? Color(hex: "#4A1528") : Color(.systemGray6))
                                .frame(height: 50)
                                .overlay(
                                    Text(isActive ? "\u{25a0}" : "\u{00b7}")
                                        .font(isActive ? .caption : .title3)
                                        .foregroundStyle(isActive ? .white : .secondary)
                                )
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                    }
                }
            }

            // Summary
            Text("Matrice : n = \(vm.matriceEons) \u{00e9}ons \u{00d7} m = \(vm.matriceLots) lots")
                .font(.system(size: 11)).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding().background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color(hex: "#8B3A62").opacity(0.1), radius: 5)
    }

    // MARK: - 3c. Mandala énergétique
    private var mandalaSection: some View {
        VStack(spacing: 8) {
            mandalaDrawing
            Text("Mandala \u{00e9}nerg\u{00e9}tique \u{2014} R\u{00e9}f\u{00e9}rence")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding().background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color(hex: "#8B3A62").opacity(0.1), radius: 5)
    }

    private var mandalaDrawing: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#1E1A2E"))
            ForEach(0..<6, id: \.self) { i in
                Circle()
                    .stroke(Color(hex: "#C27894").opacity(0.5), lineWidth: 2)
                    .frame(width: CGFloat(160 - i * 24), height: CGFloat(160 - i * 24))
            }
            ForEach(0..<4, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color(hex: "#B8965A").opacity(0.3), lineWidth: 1.5)
                    .frame(width: CGFloat(120 - i * 28), height: CGFloat(120 - i * 28))
                    .rotationEffect(.degrees(Double(i) * 22.5))
            }
            Circle().fill(Color.white.opacity(0.4)).frame(width: 20, height: 20)
        }
        .frame(height: 200)
    }

    // MARK: - 3d. Cinq Éléments / Méridiens
    private var fiveElementsSection: some View {
        VStack(spacing: 8) {
            Text("5 \u{00c9}l\u{00e9}ments \u{2014} M\u{00e9}ridiens").font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(hex: "#8B3A62"))

            fiveElementsDiagram

            Text("Engendrement \u{2192} / Contr\u{00f4}le \u{2192}")
                .font(.system(size: 9)).foregroundStyle(.secondary)
        }
        .padding().background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color(hex: "#8B3A62").opacity(0.1), radius: 5)
    }

    private var fiveElementsDiagram: some View {
        let data: [(String, String, String, Double)] = [
            ("Feu", "C\u{0153}ur", "#C53030", -90),
            ("Terre", "Rate", "#B8965A", -18),
            ("M\u{00e9}tal", "Poumon", "#AAAAAA", 54),
            ("Eau", "Rein", "#2F6FB5", 126),
            ("Bois", "Foie", "#66B032", 198)
        ]
        return ZStack {
            ForEach(0..<5, id: \.self) { i in
                let a: Double = data[i].3 * .pi / 180
                let c: Color = Color(hex: data[i].2)
                VStack(spacing: 1) {
                    Text(data[i].0).font(.system(size: 9, weight: .bold)).foregroundStyle(.white)
                    Text(data[i].1).font(.system(size: 7)).foregroundStyle(.white.opacity(0.8))
                }
                .frame(width: 44, height: 44)
                .background(Circle().fill(c))
                .offset(x: cos(a) * 60, y: sin(a) * 60)
            }
        }
        .frame(width: 180, height: 180)
        .frame(maxWidth: .infinity)
    }

    // MARK: - 3e. Glandes cérébrales
    private var glandesSection: some View {
        VStack(spacing: 10) {
            Text("Glandes c\u{00e9}r\u{00e9}brales").font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(hex: "#8B3A62"))

            let glandes: [(name: String, icon: String)] = [
                ("Hypothalamus", "brain"),
                ("Pituitaire", "brain.head.profile"),
                ("Pin\u{00e9}ale", "moon.stars"),
                ("Amygdale", "bolt.heart"),
                ("Thalamus", "circle.hexagongrid")
            ]

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(Array(glandes.enumerated()), id: \.offset) { i, g in
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#F5C6D0").opacity(0.5))
                                .frame(width: 56, height: 56)
                            Image(systemName: g.icon)
                                .font(.system(size: 22))
                                .foregroundStyle(Color(hex: "#798EF6"))
                        }
                        Text(g.name)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color(hex: "#4A1528"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            Text("Axe hypophysaire \u{2194} pin\u{00e9}al \u{2014} R\u{00e9}sonance hDOM")
                .font(.system(size: 9)).foregroundStyle(.secondary)
        }
        .padding().background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color(hex: "#8B3A62").opacity(0.1), radius: 5)
    }

    // MARK: - 3f. Fractale Mandelbrot (approximation SwiftUI)
    private var mandelbrotSection: some View {
        VStack(spacing: 8) {
            ZStack {
                // Fond noir
                RoundedRectangle(cornerRadius: 12).fill(Color.black)

                // Approximation fractale avec cercles
                ForEach(0..<12, id: \.self) { i in
                    let angle = Double(i) * 30.0
                    let radius = 20.0 + Double(i) * 5.0
                    let size = CGFloat(40 - i * 2)
                    Circle()
                        .fill(RadialGradient(
                            colors: [
                                Color(hex: "#FF4500").opacity(0.9 - Double(i) * 0.06),
                                Color(hex: "#8B0000").opacity(0.6)
                            ],
                            center: .center, startRadius: 0, endRadius: size / 2
                        ))
                        .frame(width: size, height: size)
                        .offset(
                            x: cos(angle * .pi / 180) * radius,
                            y: sin(angle * .pi / 180) * radius
                        )
                }

                // Spirales
                ForEach(0..<20, id: \.self) { i in
                    let t = Double(i) * 0.5
                    let x = cos(t * 1.5) * t * 8
                    let y = sin(t * 1.5) * t * 8
                    Circle()
                        .fill(Color(hex: "#FF6B00").opacity(0.7 - Double(i) * 0.03))
                        .frame(width: CGFloat(8 - Double(i) * 0.3), height: CGFloat(8 - Double(i) * 0.3))
                        .offset(x: x, y: y)
                }

                // Grand cercle central
                Circle()
                    .fill(Color.black)
                    .frame(width: 50, height: 50)
                    .offset(x: -20, y: 20)

                Circle()
                    .fill(Color.black)
                    .frame(width: 30, height: 30)
                    .offset(x: 25, y: -10)
            }
            .frame(height: 200)

            Text("Fractale de Mandelbrot \u{2014} Auto-similarit\u{00e9} transg\u{00e9}n\u{00e9}rationnelle")
                .font(.caption).foregroundStyle(.secondary)
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
    // Energies Sombres
    @Published var corpsMental = false
    @Published var corpsEmotionnel = false
    @Published var corpsBouddhique = false
    @Published var egoN: String = ""

    var securiteValidee: Bool { corpsMental || corpsEmotionnel || corpsBouddhique }

    var egoPuissance: Double? {
        guard let n = Double(egoN), n > 0 else { return nil }
        return pow(5.0, n)
    }

    var egoDilution: Double? {
        guard let p = egoPuissance, p > 0 else { return nil }
        return 1.0 / p
    }

    // Matrice de Desordre
    @Published var matriceCells: Set<String> = []  // ex: "5D-L1"

    var matriceEons: Int { Set(matriceCells.map { $0.split(separator: "-").first.map(String.init) ?? "" }).count }
    var matriceLots: Int { Set(matriceCells.map { $0.split(separator: "-").last.map(String.init) ?? "" }).count }

    func toggleMatriceCell(_ key: String) {
        if matriceCells.contains(key) { matriceCells.remove(key) }
        else { matriceCells.insert(key) }
    }

    var dilutionLabel: String {
        guard let n = Double(egoN) else { return "" }
        if n <= 3 { return "Dilution faible \u{2014} comportement encore perceptible" }
        if n <= 7 { return "Dilution moyenne \u{2014} influence r\u{00e9}siduelle" }
        if n <= 12 { return "Dilution forte \u{2014} quasi imperceptible" }
        return "Dilution extr\u{00ea}me \u{2014} trace infinit\u{00e9}simale"
    }

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
