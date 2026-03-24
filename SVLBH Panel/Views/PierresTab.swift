// SVLBHPanel — Views/PierresTab.swift
// v4.0.3 — Fix layout volume 3+ chiffres + grille 8 pierres

import SwiftUI

struct PierresTab: View {
    @EnvironmentObject var session: SessionState

    var chargeText: String {
        let n = session.validatedCount
        if n >= 10 { return "⚠️ Charge critique — protection maximale" }
        if n >= 6  { return "⚡️ Charge sévère — sélectionner 3+ pierres" }
        return "Charge modérée"
    }
    var chargeColor: Color {
        let n = session.validatedCount
        if n >= 10 { return Color(hex: "#E24B4A") }
        if n >= 6  { return Color(hex: "#BA7517") }
        return Color(hex: "#1D9E75")
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    chargeHeader
                    pierresGrid
                    if session.selectedPierresCount > 0 { validationSection }
                    Spacer().frame(height: 80)
                }
            }
            .navigationTitle("Pierres")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }

    private var chargeHeader: some View {
        HStack {
            Text(chargeText).font(.caption.bold()).foregroundColor(chargeColor)
            Spacer()
            Text("\(session.selectedPierresCount) sélectionnée(s)")
                .font(.caption2).foregroundColor(.secondary)
        }
        .padding(.horizontal, 16).padding(.top, 12)
    }

    private var pierresGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(session.pierres) { p in PierreCard(p: p) }
        }
        .padding(.horizontal, 12)
    }

    private var validationSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Validation post-séance")
                .font(.subheadline.bold())
                .padding(.horizontal, 16)
            ForEach(session.pierres.filter(\.selected)) { p in
                ValidationRow(p: p)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 8)
        .background(Color(hex: "#8B3A62").opacity(0.05))
        .cornerRadius(10)
        .padding(.horizontal, 12)
    }
}

struct ValidationRow: View {
    @ObservedObject var p: PierreState
    var body: some View {
        HStack {
            Button { p.validated.toggle() } label: {
                Image(systemName: p.validated ? "checkmark.square.fill" : "square")
                    .foregroundColor(p.validated ? Color(hex: "#1D9E75") : .secondary)
            }
            .buttonStyle(.plain)
            Text(p.spec.icon + " " + p.spec.nom).font(.caption)
            Spacer()
            Text(p.spec.purification).font(.caption2).foregroundColor(.secondary)
        }
    }
}

struct PierreCard: View {
    @ObservedObject var p: PierreState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(p.spec.icon + " " + p.spec.nom)
                    .font(.caption.bold())
                    .foregroundColor(p.selected ? Color(hex: "#8B3A62") : .primary)
                    .lineLimit(2)
                Spacer()
                Button {
                    withAnimation { p.selected.toggle() }
                } label: {
                    Image(systemName: p.selected ? "checkmark.circle.fill" : "plus.circle")
                        .font(.title3)
                        .foregroundColor(p.selected ? Color(hex: "#1D9E75") : Color(hex: "#C27894"))
                }
                .buttonStyle(.plain)
            }

            Text(p.spec.role)
                .font(.caption2).foregroundColor(.secondary).lineLimit(3)

            if p.selected {
                Divider()
                PierreDetail(p: p)
            }

            // 🔬 Suggestion: Patrick propose cette pierre (non sélectionnée localement)
            if p.sugSelected && !p.selected {
                Divider()
                Button {
                    p.selected = true
                    if let v = p.sugVolume { p.volume = v }
                    if let u = p.sugUnit { p.unit = u }
                    if let m = p.sugDurationMin { p.durationMin = m }
                    if let d = p.sugDurationDays { p.durationDays = d }
                    p.clearSuggestions()
                } label: {
                    HStack(spacing: 4) {
                        Text("🔬").font(.system(size: 10))
                        Text("Proposée · \(p.sugVolume ?? 1)\(p.sugUnit ?? "kg")")
                            .font(.caption2.bold()).foregroundColor(Color(hex: "#185FA5"))
                        Spacer()
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 12)).foregroundColor(Color(hex: "#185FA5"))
                    }
                    .padding(6)
                    .background(Color(hex: "#185FA5").opacity(0.08))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }

            // 🔬 Suggestion: pierre déjà sélectionnée, Patrick propose d'autres valeurs
            if p.selected && (p.sugVolume != nil || p.sugDurationMin != nil) {
                Divider()
                Button {
                    if let v = p.sugVolume { p.volume = v }
                    if let u = p.sugUnit { p.unit = u }
                    if let m = p.sugDurationMin { p.durationMin = m }
                    if let d = p.sugDurationDays { p.durationDays = d }
                    p.clearSuggestions()
                } label: {
                    HStack(spacing: 4) {
                        Text("🔬").font(.system(size: 10))
                        if let v = p.sugVolume, let u = p.sugUnit {
                            Text("\(v) \(u)").font(.caption2.bold()).foregroundColor(Color(hex: "#185FA5"))
                        }
                        if let m = p.sugDurationMin {
                            Text("· \(m) min").font(.caption2.bold()).foregroundColor(Color(hex: "#185FA5"))
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 12)).foregroundColor(Color(hex: "#185FA5"))
                    }
                    .padding(6)
                    .background(Color(hex: "#185FA5").opacity(0.08))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(p.selected
            ? Color(hex: "#8B3A62").opacity(0.08)
            : p.sugSelected
                ? Color(hex: "#185FA5").opacity(0.06)
                : Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(p.selected ? Color(hex: "#8B3A62")
                        : p.sugSelected ? Color(hex: "#185FA5")
                        : Color.clear,
                        style: p.sugSelected && !p.selected
                            ? StrokeStyle(lineWidth: 1.5, dash: [5, 3])
                            : StrokeStyle(lineWidth: 1.5))
        )
    }
}

struct PierreDetail: View {
    @ObservedObject var p: PierreState
    var body: some View {
        VStack(spacing: 8) {
            // Volume — valeur + unité sur une ligne, stepper en dessous
            VStack(spacing: 4) {
                HStack {
                    Text("Volume").font(.caption2).foregroundColor(.secondary)
                    Spacer()
                    Picker("", selection: $p.unit) {
                        Text("kg").tag("kg"); Text("t").tag("t")
                    }.pickerStyle(.segmented).frame(maxWidth: 80)
                }
                HStack {
                    Text("\(p.volume)")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: "#8B3A62"))
                        .frame(minWidth: 50, alignment: .leading)
                    Text(p.unit)
                        .font(.caption.bold())
                        .foregroundColor(Color(hex: "#8B3A62"))
                    Spacer()
                    Stepper("", value: $p.volume, in: 1...9999)
                        .labelsHidden()
                        .fixedSize()
                }
            }
            Divider()
            // Durée minutes
            HStack {
                Text("\(p.durationMin)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#BA7517"))
                Text("min")
                    .font(.caption.bold())
                    .foregroundColor(Color(hex: "#BA7517"))
                Spacer()
                Stepper("", value: $p.durationMin, in: 5...120, step: 5)
                    .labelsHidden()
                    .fixedSize()
            }
            // Durée jours
            HStack {
                Text("+ \(p.durationDays)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#BA7517").opacity(0.7))
                Text("j")
                    .font(.caption.bold())
                    .foregroundColor(Color(hex: "#BA7517").opacity(0.7))
                Spacer()
                Stepper("", value: $p.durationDays, in: 1...30)
                    .labelsHidden()
                    .fixedSize()
            }
        }
    }
}
