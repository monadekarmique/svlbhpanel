// SVLBHPanel — Views/ChronoClockView.swift
// Horloge circulaire 六腑 — arcs colorés + aiguille temps réel

import SwiftUI

struct ChronoClockView: View {
    let organs: [FuOrgan]
    let activeCode: String?
    let selectedCode: String
    let currentHour: Double  // fractional hour (e.g. 14.5)
    let onSelect: (String) -> Void

    private let size: CGFloat = 220
    private let outerR: CGFloat = 90
    private let innerR: CGFloat = 68

    var body: some View {
        Canvas { context, canvasSize in
            let cx = canvasSize.width / 2
            let cy = canvasSize.height / 2

            // Outer circle
            let outerCircle = Path(ellipseIn: CGRect(
                x: cx - outerR - 9, y: cy - outerR - 9,
                width: (outerR + 9) * 2, height: (outerR + 9) * 2))
            context.stroke(outerCircle, with: .color(.black.opacity(0.1)), lineWidth: 0.5)

            // Tick marks (24h)
            for i in 0..<24 {
                let angle = hourAngle(Double(i))
                let ro = outerR + 7
                let ri = outerR + 2
                var tickPath = Path()
                tickPath.move(to: CGPoint(x: cx + ro * cos(angle), y: cy + ro * sin(angle)))
                tickPath.addLine(to: CGPoint(x: cx + ri * cos(angle), y: cy + ri * sin(angle)))
                context.stroke(tickPath, with: .color(.black.opacity(0.15)), lineWidth: 0.5)
            }

            // Organ arcs
            for organ in organs {
                let startH = Double(organ.startHour)
                let endH = organ.startHour == 23 ? 25.0 : startH + 2.0
                let a1 = hourAngle(startH)
                let a2 = hourAngle(endH)
                let isAct = organ.id == activeCode
                let isSel = organ.id == selectedCode

                var arcPath = Path()
                arcPath.move(to: CGPoint(x: cx + innerR * cos(a1), y: cy + innerR * sin(a1)))
                arcPath.addLine(to: CGPoint(x: cx + outerR * cos(a1), y: cy + outerR * sin(a1)))
                arcPath.addArc(center: CGPoint(x: cx, y: cy), radius: outerR,
                               startAngle: .radians(a1), endAngle: .radians(a2), clockwise: false)
                arcPath.addLine(to: CGPoint(x: cx + innerR * cos(a2), y: cy + innerR * sin(a2)))
                arcPath.addArc(center: CGPoint(x: cx, y: cy), radius: innerR,
                               startAngle: .radians(a2), endAngle: .radians(a1), clockwise: true)
                arcPath.closeSubpath()

                let fillColor: Color = isAct ? organ.swiftColor : organ.swiftBg
                let opacity: Double = isSel ? 1.0 : 0.65
                context.opacity = opacity
                context.fill(arcPath, with: .color(fillColor))
                context.opacity = 1.0
                context.stroke(arcPath, with: .color(.white), lineWidth: 2.5)

                // Label
                let midA = (a1 + a2) / 2
                let lr = (outerR + innerR) / 2
                let lx = cx + lr * cos(midA)
                let ly = cy + lr * sin(midA)
                let textColor: Color = isAct ? .white : organ.swiftTx
                context.draw(
                    Text(organ.id).font(.system(size: 8.5, weight: .medium)).foregroundColor(textColor),
                    at: CGPoint(x: lx, y: ly))
            }

            // Inner circle
            let innerCircle = Path(ellipseIn: CGRect(
                x: cx - innerR + 2, y: cy - innerR + 2,
                width: (innerR - 2) * 2, height: (innerR - 2) * 2))
            context.fill(innerCircle, with: .color(Color(hex: "#f8f8f8")))

            // Clock hand
            let handAngle = hourAngle(currentHour)
            let handColor: Color = activeCode.flatMap { code in
                organs.first(where: { $0.id == code })?.swiftColor
            } ?? .gray
            var handPath = Path()
            handPath.move(to: CGPoint(x: cx, y: cy))
            handPath.addLine(to: CGPoint(
                x: cx + (outerR - 6) * cos(handAngle),
                y: cy + (outerR - 6) * sin(handAngle)))
            context.stroke(handPath, with: .color(handColor),
                           style: StrokeStyle(lineWidth: 2, lineCap: .round))

            // Center dot
            let dotR: CGFloat = 3
            let dotCircle = Path(ellipseIn: CGRect(x: cx - dotR, y: cy - dotR, width: dotR * 2, height: dotR * 2))
            context.fill(dotCircle, with: .color(.black))
        }
        .frame(width: size, height: size)
        .overlay {
            // Center text
            VStack(spacing: 0) {
                let h = Int(currentHour)
                let m = Int((currentHour - Double(h)) * 60)
                Text(String(format: "%02d:%02d", h >= 24 ? h - 24 : h, m))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.primary)
                Text("六腑")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .overlay {
            // Invisible tap targets for each organ arc
            ForEach(organs) { organ in
                let startH = Double(organ.startHour)
                let endH = organ.startHour == 23 ? 25.0 : startH + 2.0
                let midA = (hourAngle(startH) + hourAngle(endH)) / 2
                let lr = (outerR + innerR) / 2
                let cx = size / 2
                let cy = size / 2
                Circle()
                    .fill(Color.clear)
                    .frame(width: 30, height: 30)
                    .contentShape(Circle())
                    .position(x: cx + lr * cos(midA), y: cy + lr * sin(midA))
                    .onTapGesture { onSelect(organ.id) }
            }
        }
    }

    private func hourAngle(_ hour: Double) -> Double {
        (hour / 24.0) * 2 * .pi - .pi / 2
    }
}
