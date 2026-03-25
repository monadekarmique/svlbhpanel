// SVLBHPanel — Views/SessionClosureView.swift
// v4.8.0 — Protocole de clôture de séance : récap, gratitude, scellement

import SwiftUI
import UIKit

struct SessionClosureView: View {
    @EnvironmentObject var tracker: SessionTracker
    @Binding var isPresented: Bool
    @State private var phase: ClosurePhase = .recap
    @State private var summary: SessionSummary?

    enum ClosurePhase {
        case recap, gratitude, sealing, done
    }

    var body: some View {
        ZStack {
            // Fond sombre
            LinearGradient(
                colors: [Color(hex: "#0D0D1A"), Color(hex: "#1A0D2E")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                // Close button
                HStack {
                    Spacer()
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2).foregroundColor(.white.opacity(0.4))
                    }
                    .padding()
                }

                switch phase {
                case .recap:
                    recapPhase
                case .gratitude:
                    gratitudePhase
                case .sealing:
                    sealingPhase
                case .done:
                    donePhase
                }
            }
        }
        .onAppear {
            summary = tracker.endSession()
        }
    }

    // MARK: - Phase 1 : Récapitulatif

    private var recapPhase: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("RÉCAPITULATIF DE SÉANCE")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: "#B8965A"))

                if let s = summary {
                    // Date + durée
                    VStack(spacing: 4) {
                        Text(dateString(s.date))
                            .font(.caption).foregroundColor(.white.opacity(0.6))
                        Text("Durée : \(durationString(s.duration))")
                            .font(.caption.bold()).foregroundColor(.white.opacity(0.8))
                    }

                    Divider().background(Color.white.opacity(0.2))

                    // Permanentes
                    if !s.permanentEnergies.isEmpty {
                        sectionHeader("🟣 Permanentes (\(s.permanentEnergies.count))")
                        ForEach(s.permanentEnergies) { e in
                            eventRow(e, color: "#8B5CF6")
                        }
                    }

                    // Temporaires
                    if !s.temporaryEnergies.isEmpty {
                        sectionHeader("🟢 Temporaires (\(s.temporaryEnergies.count))")
                        ForEach(s.temporaryEnergies) { e in
                            eventRow(e, color: "#10B981")
                        }
                    }

                    // Entités
                    if !s.entities.isEmpty {
                        sectionHeader("🔴 Entités dégagées")
                        ForEach(s.entities) { e in
                            eventRow(e, color: "#E24B4A")
                        }
                    }

                    // Portes
                    if !s.portes.isEmpty {
                        sectionHeader("🔒 Portes travaillées")
                        ForEach(s.portes) { e in
                            Text("• \(e.porte ?? e.label)")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "#B8965A"))
                                .padding(.leading, 16)
                        }
                    }

                    // Niveaux
                    if !s.niveaux.isEmpty {
                        sectionHeader("Niveaux dimensionnels touchés")
                        Text(s.niveaux.sorted().joined(separator: " · "))
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(hex: "#C27894"))
                            .padding(.leading, 16)
                    }

                    if s.totalLiberations == 0 {
                        Text("Aucune libération enregistrée")
                            .font(.caption).foregroundColor(.white.opacity(0.4))
                            .padding(.top, 20)
                    }
                }

                Spacer().frame(height: 20)

                Button {
                    withAnimation { phase = .gratitude }
                } label: {
                    Text("Continuer →")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "#B8965A"))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Phase 2 : Gratitude

    @State private var gratitudeText = ""
    @State private var displayedText = ""
    @State private var typewriterTimer: Timer?

    private var gratitudePhase: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("GRATITUDE")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: "#B8965A"))

                Text(displayedText)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(6)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                Spacer().frame(height: 20)

                if displayedText.count >= gratitudeText.count {
                    Button {
                        withAnimation { phase = .sealing }
                    } label: {
                        Text("Sceller les portes →")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "#B8965A"))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 32)
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            if let s = summary {
                gratitudeText = tracker.generateGratitudeText(from: s)
                startTypewriter()
            }
        }
        .onDisappear { typewriterTimer?.invalidate() }
    }

    private func startTypewriter() {
        displayedText = ""
        var idx = gratitudeText.startIndex
        typewriterTimer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { timer in
            if idx < gratitudeText.endIndex {
                displayedText.append(gratitudeText[idx])
                idx = gratitudeText.index(after: idx)
            } else {
                timer.invalidate()
            }
        }
    }

    // MARK: - Phase 3 : Scellement

    @State private var portes: [SealingPorte] = []
    @State private var sealingIndex = -1
    @State private var allSealed = false

    private var sealingPhase: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("SCELLEMENT DES PORTES")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: "#B8965A"))

                Text("GV20 → GV16 → CV17 → CV12 → GV4")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))

                ForEach(Array(portes.enumerated()), id: \.element.id) { idx, porte in
                    HStack(spacing: 12) {
                        // Icône verrou
                        ZStack {
                            Circle()
                                .fill(porte.isSealed
                                      ? (porte.wasWorked ? Color(hex: "#B8965A") : Color.gray)
                                      : Color.white.opacity(0.1))
                                .frame(width: 36, height: 36)
                            Image(systemName: porte.isSealed ? "lock.fill" : "lock.open")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(porte.isSealed ? .white : .white.opacity(0.3))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(porte.point)
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(porte.isSealed
                                    ? (porte.wasWorked ? Color(hex: "#B8965A") : .gray)
                                    : .white.opacity(0.3))
                            Text(porte.nom)
                                .font(.system(size: 11))
                                .foregroundColor(porte.isSealed ? .white.opacity(0.7) : .white.opacity(0.2))
                        }

                        Spacer()

                        if porte.isSealed {
                            Text("scellée")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(porte.wasWorked ? Color(hex: "#B8965A") : .gray)
                        }
                    }
                    .padding(.horizontal, 20)
                    .animation(.spring(response: 0.4), value: porte.isSealed)

                    if idx < portes.count - 1 && porte.isSealed {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#B8965A").opacity(0.5))
                    }
                }

                if allSealed {
                    VStack(spacing: 16) {
                        Text("✅ Toutes les portes sont scellées.")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: "#1D9E75"))

                        Divider().background(Color.white.opacity(0.2)).padding(.horizontal, 40)

                        // Affirmation
                        Text("\"Je suis le seul habitant de mon corps.\nMon espace est sacré et protégé.\"")
                            .font(.system(size: 17, weight: .medium).italic())
                            .foregroundColor(Color(hex: "#B8965A"))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 20)

                        // Renforcement Wei Qi
                        Text("Renforcement Wei Qi : E36 + GV14 + VB20")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))

                        Button {
                            withAnimation { phase = .done }
                        } label: {
                            Text("Terminer la séance")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(hex: "#1D9E75"))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 32)
                    }
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            if let s = summary {
                portes = tracker.sealingPortes(from: s)
                startSealingSequence()
            }
        }
    }

    private func startSealingSequence() {
        for (idx, _) in portes.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(idx) * 2.0) {
                withAnimation(.spring(response: 0.4)) {
                    portes[idx].isSealed = true
                }
                // Haptic
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()

                if idx == portes.count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation { allSealed = true }
                    }
                }
            }
        }
    }

    // MARK: - Phase Done

    private var donePhase: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "#B8965A"))

            Text("Séance clôturée")
                .font(.title2.bold())
                .foregroundColor(.white)

            if let s = summary {
                Text("\(s.totalLiberations) libérations · \(durationString(s.duration))")
                    .font(.caption).foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            Button {
                isPresented = false
            } label: {
                Text("Fermer")
                    .font(.headline.bold())
                    .foregroundColor(Color(hex: "#0D0D1A"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "#B8965A"))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(.white.opacity(0.8))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
    }

    private func eventRow(_ e: SessionEvent, color: String) -> some View {
        HStack(spacing: 8) {
            Text("•").foregroundColor(Color(hex: color))
            Text(e.label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: color))
            Text("—").foregroundColor(.white.opacity(0.3))
            Text(e.niveau ?? "")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.leading, 16)
    }

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "dd MMMM yyyy · HH:mm"; f.locale = Locale(identifier: "fr_FR")
        return f.string(from: date)
    }

    private func durationString(_ duration: TimeInterval) -> String {
        let min = Int(duration) / 60
        return "\(min) min"
    }
}
