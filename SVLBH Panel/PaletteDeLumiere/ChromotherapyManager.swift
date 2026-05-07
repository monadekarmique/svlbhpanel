//
//  ChromotherapyManager.swift
//  SVLBH Panel — importé de Palette de Lumière
//

import SwiftUI
import Combine

@MainActor
class ChromotherapyManager: ObservableObject {

    @Published var currentElement: TCMElement = .terre
    @Published var currentColor: Color = Color(hex: "#FFC107")
    @Published var sessions: [SessionChromotherapie] = []
    @Published var activeSession: SessionChromotherapie?
    @Published var isSessionActive: Bool = false
    @Published var sessionProgress: Double = 0.0

    let protocolesDefaut: [ProtocoleChromotherapie] = [
        ProtocoleChromotherapie(
            id: UUID(), nom: "Cycle des 5 Éléments",
            description: "Parcours complet des 5 éléments à 3 thérapeutes MyShaman PRO + Patrick — rééquilibrage global",
            dureeMinutes: 15,
            couleurs: [
                .init(couleurHex: "#4CAF50", dureeSecondes: 180, intensite: 0.8, transition: .fondu),
                .init(couleurHex: "#F44336", dureeSecondes: 180, intensite: 0.8, transition: .fondu),
                .init(couleurHex: "#FFC107", dureeSecondes: 180, intensite: 0.8, transition: .fondu),
                .init(couleurHex: "#FFFFFF", dureeSecondes: 180, intensite: 0.6, transition: .fondu),
                .init(couleurHex: "#2196F3", dureeSecondes: 180, intensite: 0.8, transition: .fondu)
            ],
            elementsCibles: TCMElement.allCases, objectif: .equilibrage),
        ProtocoleChromotherapie(
            id: UUID(), nom: "Libération de la Colère",
            description: "Protocole Bois — libérer la colère et favoriser la créativité · 1 thérapeute PRO + Patrick",
            dureeMinutes: 65,
            couleurs: [
                .init(couleurHex: "#4CAF50", dureeSecondes: 780, intensite: 0.5, transition: .fondu),
                .init(couleurHex: "#81C784", dureeSecondes: 1040, intensite: 0.7, transition: .pulsation),
                .init(couleurHex: "#4CAF50", dureeSecondes: 780, intensite: 0.8, transition: .fondu),
                .init(couleurHex: "#2E7D32", dureeSecondes: 1300, intensite: 0.6, transition: .fondu)
            ],
            elementsCibles: [.bois], objectif: .liberation),
        ProtocoleChromotherapie(
            id: UUID(), nom: "Ancrage & Sagesse",
            description: "Protocole Eau pour transmuter la peur en sagesse",
            dureeMinutes: 20,
            couleurs: [
                .init(couleurHex: "#2196F3", dureeSecondes: 300, intensite: 0.6, transition: .fondu),
                .init(couleurHex: "#1565C0", dureeSecondes: 300, intensite: 0.7, transition: .fondu),
                .init(couleurHex: "#0D47A1", dureeSecondes: 300, intensite: 0.5, transition: .fondu),
                .init(couleurHex: "#2196F3", dureeSecondes: 300, intensite: 0.8, transition: .fondu)
            ],
            elementsCibles: [.eau], objectif: .ancrage),
        ProtocoleChromotherapie(
            id: UUID(), nom: "Mémoires Ancestrales",
            description: "Protocole spécial pour le décodage des mémoires transgénérationnelles",
            dureeMinutes: 30,
            couleurs: [
                .init(couleurHex: "#8B00FF", dureeSecondes: 300, intensite: 0.5, transition: .fondu),
                .init(couleurHex: "#4B0082", dureeSecondes: 360, intensite: 0.6, transition: .fondu),
                .init(couleurHex: "#2196F3", dureeSecondes: 300, intensite: 0.7, transition: .fondu),
                .init(couleurHex: "#4CAF50", dureeSecondes: 300, intensite: 0.8, transition: .fondu),
                .init(couleurHex: "#FFFFFF", dureeSecondes: 240, intensite: 0.6, transition: .fondu),
                .init(couleurHex: "#FFC107", dureeSecondes: 300, intensite: 0.7, transition: .fondu)
            ],
            elementsCibles: [.eau, .bois, .metal, .terre], objectif: .decodage)
    ]

    init() { loadSessions() }

    func setCurrentElement(_ element: TCMElement) {
        currentElement = element
        currentColor = element.color
    }

    func startSession(protocole: ProtocoleChromotherapie, ressenti: SessionChromotherapie.RessentieEmotionnel) {
        let session = SessionChromotherapie(
            id: UUID(), date: Date(), protocole: protocole,
            ressentiAvant: ressenti, ressentiApres: nil, notes: "",
            elementsTravailles: protocole.elementsCibles, memoiresLiberees: [])
        activeSession = session
        isSessionActive = true
        sessionProgress = 0.0
    }

    func endSession(ressenti: SessionChromotherapie.RessentieEmotionnel, notes: String, memoires: [MemoireTransgenerationnelle]) {
        guard var session = activeSession else { return }
        session.ressentiApres = ressenti
        session.notes = notes
        session.memoiresLiberees = memoires
        sessions.append(session)
        saveSessions()
        activeSession = nil
        isSessionActive = false
        sessionProgress = 0.0
    }

    func updateProgress(_ progress: Double) {
        sessionProgress = min(1.0, max(0.0, progress))
    }

    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: "chromotherapy_sessions")
        }
    }

    private func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: "chromotherapy_sessions"),
           let decoded = try? JSONDecoder().decode([SessionChromotherapie].self, from: data) {
            sessions = decoded
        }
    }

    func totalSessionsCount() -> Int { sessions.count }
    func totalDurationMinutes() -> Int { sessions.reduce(0) { $0 + $1.protocole.dureeMinutes } }
    func elementLePlusTravaille() -> TCMElement? {
        let counts = sessions.flatMap { $0.elementsTravailles }
            .reduce(into: [:]) { counts, element in counts[element, default: 0] += 1 }
        return counts.max(by: { $0.value < $1.value })?.key
    }
}
