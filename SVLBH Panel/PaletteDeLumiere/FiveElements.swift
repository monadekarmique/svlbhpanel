//
//  FiveElements.swift
//  SVLBH Panel — importé de Palette de Lumière
//

import SwiftUI

// MARK: - Élément TCM
enum TCMElement: String, CaseIterable, Identifiable, Codable {
    case bois = "Bois"
    case feu = "Feu"
    case terre = "Terre"
    case metal = "Métal"
    case eau = "Eau"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .bois: return Color(hex: "#4CAF50")
        case .feu: return Color(hex: "#F44336")
        case .terre: return Color(hex: "#FFC107")
        case .metal: return Color(hex: "#FFFFFF")
        case .eau: return Color(hex: "#2196F3")
        }
    }

    var secondaryColor: Color {
        switch self {
        case .bois: return Color(hex: "#81C784")
        case .feu: return Color(hex: "#FF8A80")
        case .terre: return Color(hex: "#FFE082")
        case .metal: return Color(hex: "#E0E0E0")
        case .eau: return Color(hex: "#64B5F6")
        }
    }

    var organYin: String {
        switch self {
        case .bois: return "Foie"
        case .feu: return "Cœur"
        case .terre: return "Rate"
        case .metal: return "Poumon"
        case .eau: return "Rein"
        }
    }

    var organYang: String {
        switch self {
        case .bois: return "Vésicule Biliaire"
        case .feu: return "Intestin Grêle"
        case .terre: return "Estomac"
        case .metal: return "Gros Intestin"
        case .eau: return "Vessie"
        }
    }

    var emotion: String {
        switch self {
        case .bois: return "Colère"
        case .feu: return "Joie"
        case .terre: return "Rumination"
        case .metal: return "Tristesse"
        case .eau: return "Peur"
        }
    }

    var emotionPositive: String {
        switch self {
        case .bois: return "Créativité"
        case .feu: return "Amour"
        case .terre: return "Réflexion"
        case .metal: return "Lâcher-prise"
        case .eau: return "Sagesse"
        }
    }

    var saison: String {
        switch self {
        case .bois: return "Printemps"
        case .feu: return "Été"
        case .terre: return "Intersaisons"
        case .metal: return "Automne"
        case .eau: return "Hiver"
        }
    }

    var sens: String {
        switch self {
        case .bois: return "Vue"
        case .feu: return "Parole"
        case .terre: return "Goût"
        case .metal: return "Odorat"
        case .eau: return "Ouïe"
        }
    }

    var tissu: String {
        switch self {
        case .bois: return "Tendons & Ligaments"
        case .feu: return "Vaisseaux sanguins"
        case .terre: return "Chair & Muscles"
        case .metal: return "Peau & Poils"
        case .eau: return "Os & Moelle"
        }
    }

    var engendre: TCMElement {
        switch self {
        case .bois: return .feu
        case .feu: return .terre
        case .terre: return .metal
        case .metal: return .eau
        case .eau: return .bois
        }
    }

    var controle: TCMElement {
        switch self {
        case .bois: return .terre
        case .feu: return .metal
        case .terre: return .eau
        case .metal: return .bois
        case .eau: return .feu
        }
    }

    var symbol: String {
        switch self {
        case .bois: return "🌳"
        case .feu: return "🔥"
        case .terre: return "🏔️"
        case .metal: return "⚪"
        case .eau: return "💧"
        }
    }

    var pointsCles: [String] {
        switch self {
        case .bois: return ["F3 Taichong", "F14 Qimen", "VB34 Yanglingquan"]
        case .feu: return ["C7 Shenmen", "MC6 Neiguan", "IG3 Houxi"]
        case .terre: return ["Rt6 Sanyinjiao", "E36 Zusanli", "Rt4 Gongsun"]
        case .metal: return ["P7 Lieque", "P9 Taiyuan", "GI4 Hegu"]
        case .eau: return ["Rn3 Taixi", "Rn1 Yongquan", "V23 Shenshu"]
        }
    }
}

// MARK: - Bilan Énergétique
struct BilanEnergetique: Identifiable, Codable {
    let id: UUID
    let date: Date
    var niveaux: [TCMElement: NiveauEnergetique]
    var notes: String

    init(id: UUID = UUID(), date: Date = Date(), notes: String = "") {
        self.id = id
        self.date = date
        self.niveaux = Dictionary(uniqueKeysWithValues: TCMElement.allCases.map { ($0, NiveauEnergetique()) })
        self.notes = notes
    }
}

struct NiveauEnergetique: Codable {
    var niveau: Double = 0.5
    var qualite: QualiteEnergie = .equilibre

    enum QualiteEnergie: String, Codable, CaseIterable {
        case vide = "Vide"
        case equilibre = "Équilibre"
        case plenitude = "Plénitude"
        case stagnation = "Stagnation"
        case chaleur = "Chaleur"
        case froid = "Froid"
    }
}
