//
//  PDLSessionView.swift
//  SVLBH Panel — importé de Palette de Lumière
//

import SwiftUI

struct PDLSessionView: View {
    @EnvironmentObject var chromoManager: ChromotherapyManager
    @State private var selectedProtocole: ProtocoleChromotherapie?
    @State private var isSessionRunning = false
    @State private var currentColorIndex = 0
    @State private var sessionTimer: Timer?
    @State private var elapsedSeconds = 0
    @State private var showingPreSession = false
    @State private var showingPostSession = false
    @State private var ressentiAvant = SessionChromotherapie.RessentieEmotionnel(
        niveauEnergie: 5, niveauCalme: 5, emotionPrincipale: "", sensationsCorporelles: "")

    var body: some View {
        ZStack {
            if isSessionRunning, let protocole = selectedProtocole {
                currentSessionColor(for: protocole).ignoresSafeArea()
                    .animation(.easeInOut(duration: 2), value: currentColorIndex)
            } else {
                Color(.systemBackground).ignoresSafeArea()
            }
            ScrollView {
                VStack(spacing: 24) {
                    if isSessionRunning { activeSessionView } else { protocolSelectionView }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingPreSession) {
            PDLPreSessionSheet(ressenti: $ressentiAvant, onStart: startSession)
        }
        .sheet(isPresented: $showingPostSession) {
            PDLPostSessionSheet(onComplete: endSession)
        }
    }

    private var protocolSelectionView: some View {
        VStack(spacing: 20) {
            statsCard
            VStack(alignment: .leading, spacing: 16) {
                Text("Protocoles").font(.headline)
                ForEach(chromoManager.protocolesDefaut) { protocole in
                    PDLProtocoleCard(protocole: protocole, isSelected: selectedProtocole?.id == protocole.id) {
                        withAnimation { selectedProtocole = protocole }
                    }
                }
            }
            if selectedProtocole != nil {
                Button { showingPreSession = true } label: {
                    Label("Commencer la séance", systemImage: "play.fill")
                        .font(.headline).frame(maxWidth: .infinity).padding()
                        .background(Color.accentColor).foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.top)
            }
        }
    }

    private var activeSessionView: some View {
        VStack(spacing: 40) {
            Spacer()
            ZStack {
                Circle().stroke(Color.white.opacity(0.3), lineWidth: 8).frame(width: 200, height: 200)
                Circle().trim(from: 0, to: progress)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 200, height: 200).rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
                VStack(spacing: 8) {
                    Text(timeString).font(.system(size: 48, weight: .light, design: .rounded)).foregroundStyle(.white)
                    if let protocole = selectedProtocole {
                        Text(protocole.nom).font(.subheadline).foregroundStyle(.white.opacity(0.8))
                    }
                }
            }
            VStack(spacing: 12) {
                Text("Respirez profondément").font(.title2).fontWeight(.medium).foregroundStyle(.white)
                Text("Laissez la lumière pénétrer chaque cellule de votre corps")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.8)).multilineTextAlignment(.center)
            }
            .padding()
            Spacer()
            Button { stopSession() } label: {
                Label("Terminer", systemImage: "stop.fill")
                    .font(.headline).padding().background(Color.white.opacity(0.2))
                    .foregroundStyle(.white).clipShape(Capsule())
            }
            .padding(.bottom, 40)
        }
    }

    private var statsCard: some View {
        HStack(spacing: 20) {
            PDLStatItem(value: "\(chromoManager.totalSessionsCount())", label: "Séances", icon: "rays")
            Divider().frame(height: 40)
            PDLStatItem(value: "\(chromoManager.totalDurationMinutes())", label: "Minutes", icon: "clock")
            Divider().frame(height: 40)
            if let element = chromoManager.elementLePlusTravaille() {
                PDLStatItem(value: element.symbol, label: "Favori", icon: "star")
            }
        }
        .padding().background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16)).shadow(radius: 5)
    }

    private var progress: Double {
        guard let protocole = selectedProtocole else { return 0 }
        return Double(elapsedSeconds) / Double(protocole.dureeMinutes * 60)
    }

    private var timeString: String {
        String(format: "%02d:%02d", elapsedSeconds / 60, elapsedSeconds % 60)
    }

    private func currentSessionColor(for protocole: ProtocoleChromotherapie) -> Color {
        guard !protocole.couleurs.isEmpty else { return .blue }
        return Color(hex: protocole.couleurs[currentColorIndex % protocole.couleurs.count].couleurHex)
    }

    private func startSession() {
        guard let protocole = selectedProtocole else { return }
        chromoManager.startSession(protocole: protocole, ressenti: ressentiAvant)
        isSessionRunning = true; elapsedSeconds = 0; currentColorIndex = 0
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedSeconds += 1
            updateColorIndex()
            if elapsedSeconds >= protocole.dureeMinutes * 60 { stopSession() }
        }
    }

    private func updateColorIndex() {
        guard let protocole = selectedProtocole else { return }
        var accumulatedTime = 0
        for (index, couleur) in protocole.couleurs.enumerated() {
            accumulatedTime += couleur.dureeSecondes
            if elapsedSeconds < accumulatedTime {
                if currentColorIndex != index { withAnimation(.easeInOut(duration: 2)) { currentColorIndex = index } }
                break
            }
        }
    }

    private func stopSession() {
        sessionTimer?.invalidate(); sessionTimer = nil; showingPostSession = true
    }

    private func endSession(ressenti: SessionChromotherapie.RessentieEmotionnel, notes: String) {
        chromoManager.endSession(ressenti: ressenti, notes: notes, memoires: [])
        isSessionRunning = false; selectedProtocole = nil; showingPostSession = false
    }
}

struct PDLProtocoleCard: View {
    let protocole: ProtocoleChromotherapie
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    // Logo Cercle de Lumière AVANT le nom — pour Cycle 5 Éléments + Libération Colère.
                    if protocole.nom.contains("5 Éléments") || protocole.nom.contains("Colère") {
                        Image("cercle_de_lumiere")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28, height: 28)
                            .clipShape(Circle())
                    }
                    Text(protocole.nom).font(.headline)
                    Spacer()
                    Text("\(protocole.dureeMinutes) min").font(.caption)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.2)).clipShape(Capsule())
                }
                Text(protocole.description).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                HStack(spacing: 4) {
                    ForEach(protocole.couleurs.prefix(6).indices, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: protocole.couleurs[index].couleurHex)).frame(height: 8)
                    }
                }
                HStack {
                    ForEach(protocole.elementsCibles) { element in Text(element.symbol).font(.caption) }
                    Spacer()
                    Text(protocole.objectif.rawValue).font(.caption2).foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemBackground))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2))
            .clipShape(RoundedRectangle(cornerRadius: 16)).shadow(radius: isSelected ? 5 : 2)
        }
        .buttonStyle(.plain)
    }
}

struct PDLStatItem: View {
    let value: String
    let label: String
    let icon: String
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.title3).foregroundStyle(.secondary)
            Text(value).font(.title2).fontWeight(.bold)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PDLPreSessionSheet: View {
    @Binding var ressenti: SessionChromotherapie.RessentieEmotionnel
    let onStart: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Niveau d'énergie") {
                    Slider(value: $ressenti.niveauEnergie, in: 0...10, step: 1)
                    Text("Niveau: \(Int(ressenti.niveauEnergie))/10").font(.caption).foregroundStyle(.secondary)
                }
                Section("Niveau de calme") {
                    Slider(value: $ressenti.niveauCalme, in: 0...10, step: 1)
                    Text("Niveau: \(Int(ressenti.niveauCalme))/10").font(.caption).foregroundStyle(.secondary)
                }
                Section("Émotion principale") {
                    TextField("Ex: Anxiété, fatigue...", text: $ressenti.emotionPrincipale)
                }
                Section("Sensations corporelles") {
                    TextField("Ex: Tension dans les épaules...", text: $ressenti.sensationsCorporelles)
                }
            }
            .navigationTitle("Avant la séance").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Commencer") { dismiss(); onStart() } }
            }
        }
    }
}

struct PDLPostSessionSheet: View {
    let onComplete: (SessionChromotherapie.RessentieEmotionnel, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var ressenti = SessionChromotherapie.RessentieEmotionnel(
        niveauEnergie: 5, niveauCalme: 5, emotionPrincipale: "", sensationsCorporelles: "")
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Niveau d'énergie après") {
                    Slider(value: $ressenti.niveauEnergie, in: 0...10, step: 1)
                    Text("Niveau: \(Int(ressenti.niveauEnergie))/10").font(.caption).foregroundStyle(.secondary)
                }
                Section("Niveau de calme après") {
                    Slider(value: $ressenti.niveauCalme, in: 0...10, step: 1)
                    Text("Niveau: \(Int(ressenti.niveauCalme))/10").font(.caption).foregroundStyle(.secondary)
                }
                Section("Émotion ressentie") {
                    TextField("Ex: Apaisement, clarté...", text: $ressenti.emotionPrincipale)
                }
                Section("Notes de séance") {
                    TextEditor(text: $notes).frame(minHeight: 100)
                }
            }
            .navigationTitle("Fin de séance").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Enregistrer") { onComplete(ressenti, notes) } }
            }
        }
    }
}
