// SVLBHPanel — Views/ChronoFuTab.swift
// Chrono 六腑 — Horloge acupression temps réel (Zi Wu Liu Zhu 子午流注)

import SwiftUI

struct ChronoFuTab: View {
    @EnvironmentObject var session: SessionState
    @State private var organs = ChronoFuData.allOrgans()
    @State private var selectedCode: String? = nil
    @State private var now = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: - Computed

    private var calendar: Calendar { Calendar.current }
    private var hour: Int { calendar.component(.hour, from: now) }
    private var minute: Int { calendar.component(.minute, from: now) }
    private var second: Int { calendar.component(.second, from: now) }
    private var fractionalHour: Double {
        Double(hour) + Double(minute) / 60.0 + Double(second) / 3600.0
    }

    private var activeCode: String? {
        ChronoFuData.activeOrganCode(at: hour)
    }

    private var displayCode: String {
        selectedCode ?? activeCode ?? organs[0].id
    }

    private var displayOrgan: FuOrgan {
        organs.first(where: { $0.id == displayCode }) ?? organs[0]
    }

    private var timeString: String {
        String(format: "%02d:%02d:%02d", hour, minute, second)
    }

    // MARK: - Countdown

    private var countdownInfo: (value: String, label: String) {
        let totalSec = hour * 3600 + minute * 60 + second

        if let sel = selectedCode, sel != activeCode {
            // Countdown to selected organ's window
            let organ = organs.first(where: { $0.id == sel })!
            var secsUntil = organ.startHour * 3600 - totalSec
            if secsUntil < 0 { secsUntil += 86400 }
            return (formatCountdown(secsUntil), "prochaine fenêtre : \(organ.label)")
        } else if let actCode = activeCode {
            // Countdown to end of current window
            let organ = organs.first(where: { $0.id == actCode })!
            let endH = organ.startHour == 23 ? 25 : organ.startHour + 2
            var secsLeft = endH * 3600 - totalSec
            if secsLeft < 0 { secsLeft += 86400 }
            return (formatCountdown(secsLeft), "fin de fenêtre \(organ.label)")
        } else {
            // Countdown to next window
            let next = ChronoFuData.nextWindow(after: hour)
            var secsUntil = next.startHour * 3600 - totalSec
            if secsUntil < 0 { secsUntil += 86400 }
            return (formatCountdown(secsUntil), "prochain : \(next.name) \(next.label)")
        }
    }

    // MARK: - Badge

    private var badgeInfo: (text: String, bg: Color, tx: Color)? {
        if activeCode == displayCode, activeCode != nil {
            return ("Organe actif maintenant", displayOrgan.swiftBg, displayOrgan.swiftTx)
        }
        if activeCode == nil && selectedCode == nil {
            return ("Fenêtre inactive — récupération", Color(hex: "#f0f0f0"), .secondary)
        }
        if selectedCode != nil && selectedCode != activeCode {
            return ("Vue manuelle", displayOrgan.swiftBg, displayOrgan.swiftTx)
        }
        return nil
    }

    // MARK: - SLA filtering

    private var slaValue: Int? {
        session.scoresTherapist.sla ?? session.scoresPatrick.sla
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    headerSection
                    clockSection
                    cardsGrid
                    organChips
                    Spacer().frame(height: 80)
                }
                .padding(.horizontal, 16)
            }
            .navigationTitle("Chrono 六腑")
            .navigationBarTitleDisplayMode(.inline)
            .onReceive(timer) { now = $0 }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        LingguiBafaView()
                    } label: {
                        Text("灵龟八法")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "#185FA5"))
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 2) {
            Text(timeString)
                .font(.system(size: 38, weight: .medium, design: .default))
                .tracking(-1)
                .monospacedDigit()

            Text("\(displayOrgan.zh) · \(displayOrgan.name) · \(displayOrgan.pinyin)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let badge = badgeInfo {
                Text(badge.text)
                    .font(.caption2)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 3)
                    .background(badge.bg)
                    .foregroundColor(badge.tx)
                    .clipShape(Capsule())
                    .padding(.top, 6)
            }
        }
        .padding(.top, 14)
    }

    // MARK: - Clock

    private var clockSection: some View {
        ChronoClockView(
            organs: organs,
            activeCode: activeCode,
            selectedCode: displayCode,
            currentHour: fractionalHour,
            onSelect: { code in
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedCode = selectedCode == code ? nil : code
                }
            }
        )
    }

    // MARK: - Cards grid

    private var cardsGrid: some View {
        HStack(alignment: .top, spacing: 12) {
            pointsCard
            chromoCard
        }
    }

    // MARK: - Points card

    private var pointsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("POINTS D'ACUPRESSION")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.secondary)
                .tracking(0.7)

            let organIndex = organs.firstIndex(where: { $0.id == displayCode }) ?? 0

            ForEach(Array(organs[organIndex].points.enumerated()), id: \.element.id) { idx, pt in
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(pt.code)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(displayOrgan.swiftColor)
                            Text(pt.name)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .italic()
                        }
                        .frame(minWidth: 56, alignment: .leading)

                        Text(pt.action)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }

                    // Stimulated toggle
                    Button {
                        organs[organIndex].points[idx].isStimulated.toggle()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: pt.isStimulated ? "circle.fill" : "circle")
                                .font(.system(size: 8))
                            Text(pt.isStimulated ? "Stimulé" : "Stimuler")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(pt.isStimulated ? displayOrgan.swiftColor : .secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 4)

                if idx < organs[organIndex].points.count - 1 {
                    Divider()
                }
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.12), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Chromo card

    private var chromoCard: some View {
        VStack(spacing: 10) {
            Text("CHROMOTHÉRAPIE VLBH")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.secondary)
                .tracking(0.7)

            // Color swatch
            RoundedRectangle(cornerRadius: 8)
                .fill(displayOrgan.swiftBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(displayOrgan.swiftColor.opacity(0.2), lineWidth: 1)
                )
                .frame(height: 52)
                .overlay(
                    Text("● \(displayOrgan.chromoName)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(displayOrgan.swiftTx)
                )

            Text("Élément \(displayOrgan.element) · code méridien \(displayOrgan.id)")
                .font(.system(size: 12))
                .foregroundColor(.gray)

            // Countdown
            VStack(spacing: 4) {
                let isEndOfWindow = activeCode == displayCode && activeCode != nil
                Text(isEndOfWindow ? "FIN DE FENÊTRE" : "PROCHAINE FENÊTRE")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.secondary)
                    .tracking(0.7)

                Text(countdownInfo.value)
                    .font(.system(size: 26, weight: .medium))
                    .monospacedDigit()

                Text(countdownInfo.label)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 6)
        }
        .padding(14)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.12), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Organ chips

    private var organChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ZI WU LIU ZHU 子午流注 — CLIQUER POUR EXPLORER")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.secondary)
                .tracking(0.7)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 6), spacing: 6) {
                ForEach(organs) { organ in
                    let isSel = organ.id == displayCode
                    let isAct = organ.id == activeCode
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCode = selectedCode == organ.id ? nil : organ.id
                        }
                    } label: {
                        VStack(spacing: 2) {
                            Text(organ.zh)
                                .font(.system(size: 13))
                            Text(organ.id)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(organ.swiftColor)
                            Text(organ.label)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            if isAct {
                                Circle()
                                    .fill(organ.swiftColor)
                                    .frame(width: 5, height: 5)
                                    .padding(.top, 1)
                            }
                        }
                        .padding(.vertical, 7)
                        .padding(.horizontal, 4)
                        .frame(maxWidth: .infinity)
                        .background(isSel ? organ.swiftBg : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSel ? organ.swiftColor : Color.black.opacity(0.12),
                                        lineWidth: isSel ? 1.5 : 0.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Helpers

    private func formatCountdown(_ totalSeconds: Int) -> String {
        let h = totalSeconds / 3600
        let m = (totalSeconds % 3600) / 60
        let s = totalSeconds % 60
        if h > 0 {
            return String(format: "%02d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}
