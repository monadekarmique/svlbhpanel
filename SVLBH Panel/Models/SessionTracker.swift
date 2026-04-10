// SVLBHPanel — Models/SessionTracker.swift
// v4.8.0 — Session Tracker : événements, timeline, résumé, clôture

import Foundation

// MARK: - Catégories d'événements

enum EventCategory: String, Codable, CaseIterable {
    case provocationTemporaire = "Provocation Temporaire"
    case provocationPermanente = "Provocation Permanente"
    case entite = "Entité"
    case porte = "Porte"
    case sephiroth = "Sephiroth"
    case roseDesVents = "Rose des Vents"
    case hdom = "hDOM"
    case scoreLight = "Score de Lumière"
    case custom = "Action Custom"

    var icon: String {
        switch self {
        case .provocationPermanente: return "🟣"
        case .provocationTemporaire: return "🟢"
        case .entite: return "🔴"
        case .porte: return "🔒"
        case .sephiroth: return "🟠"
        case .roseDesVents: return "🧭"
        case .hdom: return "🔵"
        case .scoreLight: return "✨"
        case .custom: return "⚪"
        }
    }

    var colorHex: String {
        switch self {
        case .provocationPermanente: return "#8B5CF6"
        case .provocationTemporaire: return "#10B981"
        case .entite: return "#E24B4A"
        case .porte: return "#B8965A"
        case .sephiroth: return "#BA7517"
        case .roseDesVents: return "#185FA5"
        case .hdom: return "#185FA5"
        case .scoreLight: return "#C27894"
        case .custom: return "#8B3A62"
        }
    }
}

// MARK: - Événement de séance

struct SessionEvent: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let category: EventCategory
    let label: String
    let detail: String?
    let niveau: String?
    let energyType: String?   // "permanent" ou "temporary"
    let liberation: String?
    let porte: String?
    var isLiberated: Bool

    init(category: EventCategory, label: String, detail: String? = nil,
         niveau: String? = nil, energyType: String? = nil,
         liberation: String? = nil, porte: String? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.category = category
        self.label = label
        self.detail = detail
        self.niveau = niveau
        self.energyType = energyType
        self.liberation = liberation
        self.porte = porte
        self.isLiberated = false
    }
}

// MARK: - Résumé de séance

struct SessionSummary {
    let date: Date
    let duration: TimeInterval
    let permanentEnergies: [SessionEvent]
    let temporaryEnergies: [SessionEvent]
    let entities: [SessionEvent]
    let portes: [SessionEvent]
    let niveaux: Set<String>
    let categories: Set<EventCategory>

    var totalLiberations: Int {
        permanentEnergies.count + temporaryEnergies.count + entities.count
    }
}

// MARK: - Porte de scellement

struct SealingPorte: Identifiable {
    let id = UUID()
    let nom: String
    let point: String
    let delay: TimeInterval
    var wasWorked: Bool
    var isSealed: Bool = false
}

// MARK: - Session Tracker

class SessionTracker: ObservableObject {
    @Published var events: [SessionEvent] = []
    @Published var sessionStart: Date = Date()
    @Published var isActive: Bool = false

    /// Événements Rose des Vents de la séance en cours.
    /// Consommé par `hdom-session-agent` pour le décodage hDOM.
    var roseDesVentsEvents: [SessionEvent] {
        events.filter { $0.category == .roseDesVents }
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    func startSession() {
        events = []
        sessionStart = Date()
        isActive = true
    }

    func logEvent(_ event: SessionEvent) {
        guard isActive else { return }
        events.append(event)
    }

    func logProvocation(_ energy: ParasiteEnergy) {
        let cat: EventCategory = energy.type == .permanent
            ? .provocationPermanente : .provocationTemporaire
        let evt = SessionEvent(
            category: cat,
            label: energy.nom,
            detail: energy.description,
            niveau: energy.type == .temporary ? "D2" : energy.niveau,
            energyType: energy.type.rawValue,
            liberation: energy.liberation
        )
        logEvent(evt)
    }

    func markLiberated(_ eventId: UUID) {
        guard let idx = events.firstIndex(where: { $0.id == eventId }) else { return }
        events[idx].isLiberated = true
    }

    func endSession() -> SessionSummary {
        isActive = false
        let duration = Date().timeIntervalSince(sessionStart)
        let liberated = events.filter(\.isLiberated)

        let permanents = liberated.filter { $0.category == .provocationPermanente }
        let temporaries = liberated.filter { $0.category == .provocationTemporaire }
        let entities = liberated.filter { $0.category == .entite }
        let portes = events.filter { $0.category == .porte }

        var niveaux = Set<String>()
        for e in liberated {
            if let n = e.niveau {
                // Parse "D7-D11" into individual dimensions
                let parts = n.replacingOccurrences(of: "D", with: "").split(separator: "-")
                if let lo = Int(parts.first ?? ""), let hi = Int(parts.last ?? "") {
                    for d in lo...hi { niveaux.insert("D\(d)") }
                } else {
                    niveaux.insert(n)
                }
            }
        }

        let cats = Set(events.map(\.category))

        return SessionSummary(
            date: sessionStart,
            duration: duration,
            permanentEnergies: permanents,
            temporaryEnergies: temporaries,
            entities: entities,
            portes: portes,
            niveaux: niveaux,
            categories: cats
        )
    }

    // MARK: - Texte de gratitude

    func generateGratitudeText(from summary: SessionSummary) -> String {
        var text = """
        Je remercie tous les aspects de ma conscience \
        qui ont permis de libérer \
        tous les aspects non bénéficiels \
        des lignes de temps parasites.
        """

        if !summary.permanentEnergies.isEmpty {
            let names = summary.permanentEnergies.map(\.label).joined(separator: ", ")
            let niveaux = Set(summary.permanentEnergies.compactMap(\.niveau)).sorted().joined(separator: ", ")
            text += """

            \n— les \(summary.permanentEnergies.count) énergies permanentes de la lignée
              [\(names)]
              ancrées aux niveaux [\(niveaux)]
            """
        }

        if !summary.temporaryEnergies.isEmpty {
            let names = summary.temporaryEnergies.map(\.label).joined(separator: ", ")
            text += """

            \n— les \(summary.temporaryEnergies.count) énergies temporaires
              [\(names)]
              attachées au niveau [D2]
            """
        }

        if !summary.entities.isEmpty {
            for e in summary.entities {
                text += "\n\n— l'entité [\(e.label)] libérée du niveau [\(e.niveau ?? "?")]"
            }
        }

        if !summary.portes.isEmpty {
            let porteNames = summary.portes.compactMap(\.porte).joined(separator: ", ")
            text += """

            \n— les portes [\(porteNames)] qui ont permis l'accès
              et qui sont maintenant refermées.
            """
        }

        text += """

        \nTous ces aspects sont libérés,
        retournés à la Source de Lumière,
        avec amour et gratitude.
        """

        return text
    }

    // MARK: - Portes de scellement

    func sealingPortes(from summary: SessionSummary) -> [SealingPorte] {
        let workedPortes = Set(summary.portes.compactMap(\.porte))
        return [
            SealingPorte(nom: "Porte du Sommet", point: "GV20 Baihui", delay: 0,
                         wasWorked: workedPortes.contains("GV20")),
            SealingPorte(nom: "Porte de la Nuque", point: "GV16 Fengfu", delay: 2,
                         wasWorked: workedPortes.contains("GV16")),
            SealingPorte(nom: "Porte du Cœur", point: "CV17 Danzhong", delay: 4,
                         wasWorked: workedPortes.contains("CV17")),
            SealingPorte(nom: "Porte du Plexus", point: "CV12 Zhongwan", delay: 6,
                         wasWorked: workedPortes.contains("CV12")),
            SealingPorte(nom: "Porte du Sacrum", point: "GV4 Mingmen", delay: 8,
                         wasWorked: workedPortes.contains("GV4")),
        ]
    }

    func timeString(_ date: Date) -> String {
        Self.timeFormatter.string(from: date)
    }
}
