// SVLBHPanel — Models/DimensionsData.swift
// v0.1.3-P8 — 9+1 dimensions × 45 chakras + D2 = 46 total

import Foundation
import SwiftUI

// MARK: - Color hex extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8)*17, (int >> 4 & 0xF)*17, (int & 0xF)*17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 180, 180, 180)
        }
        self.init(.sRGB,
                  red: Double(r)/255,
                  green: Double(g)/255,
                  blue: Double(b)/255,
                  opacity: Double(a)/255)
    }
}

func slaColor(_ sla: Int) -> Color {
    if sla >= 87 { return Color(hex: "#1D9E75") }
    if sla >= 74 { return Color(hex: "#BA7517") }
    return Color(hex: "#E24B4A")
}

struct ChakraIssue {
    let label: String
    let sla: Int
}

struct ChakraInfo: Identifiable {
    let num: Int?
    let icon: String
    let nom: String
    let issues: [ChakraIssue]
    let hasCIM: Bool
    let cimCodes: [(code: String, label: String)]
    var id: String { "\(num ?? 0)_\(nom)" }
    func key(forDim dimId: String) -> String { "\(dimId)_\(num.map(String.init) ?? "x")" }
}

struct DimensionInfo: Identifiable {
    let id: String
    let num: Int
    let label: String
    let description: String
    let defaultCollapsed: Bool
    let chakras: [ChakraInfo]
    func chakraKey(_ c: ChakraInfo) -> String { c.key(forDim: id) }
    var allKeys: [String] { chakras.map { chakraKey($0) } }
}

// MARK: - allDimensions
let allDimensions: [DimensionInfo] = [

    DimensionInfo(id: "d9", num: 9,
        label: "D9 — Source créatrice · Temps",
        description: "Corps Kéthérique",
        defaultCollapsed: false,
        chakras: [
            ChakraInfo(num: 33, icon: "◈", nom: "Intention, Symptômes et signes",
                issues: [ChakraIssue(label: "Diabète T2 — symptôme fork", sla: 89)], hasCIM: false, cimCodes: []),
            ChakraInfo(num: 32, icon: "⇄", nom: "Symptômes et signes relatifs",
                issues: [ChakraIssue(label: "Polyurie, polydipsie, fatigue", sla: 89)], hasCIM: true,
                cimCodes: [
                    ("R35.89", "Polyurie"),
                    ("R63.1",  "Polydipsie"),
                    ("R53.83", "Fatigue — autre")
                ]),
            ChakraInfo(num: 31, icon: "▶", nom: "Classification CIM-10/11",
                issues: [ChakraIssue(label: "5A11.0 T2DM", sla: 89)], hasCIM: true,
                cimCodes: [
                    ("E11.9",  "T2DM sans complications"),
                    ("E11.65", "T2DM avec hyperglycémie"),
                    ("E11.22", "T2DM — néphropathie chronique")
                ]),
            ChakraInfo(num: 30, icon: "♥", nom: "Oversoul", issues: [], hasCIM: false, cimCodes: []),
        ]),

    DimensionInfo(id: "d8", num: 8,
        label: "D8 — Lumière du Tout-Connaissant",
        description: "Corps Céleste",
        defaultCollapsed: true,
        chakras: [
            ChakraInfo(num: 29, icon: "◉", nom: "Sacred Soul", issues: [], hasCIM: false, cimCodes: []),
            ChakraInfo(num: 28, icon: "♥", nom: "Electronic Higherself", issues: [], hasCIM: false, cimCodes: []),
        ]),

    DimensionInfo(id: "d7", num: 7,
        label: "D7 — Résonance vibratoire",
        description: "Corps Émotionnel Supérieur",
        defaultCollapsed: false,
        chakras: [
            ChakraInfo(num: 27, icon: "◎", nom: "Higher Purpose",
                issues: [ChakraIssue(label: "Impersonation Energy", sla: 63)], hasCIM: false, cimCodes: []),
        ]),

    DimensionInfo(id: "d6", num: 6,
        label: "D6 — Formes géométriques",
        description: "5–7 mois avant manifestation",
        defaultCollapsed: false,
        chakras: [
            ChakraInfo(num: 26, icon: "✚", nom: "Geometric Universal Tree",
                issues: [ChakraIssue(label: "Stain G-5", sla: 77)], hasCIM: false, cimCodes: []),
            ChakraInfo(num: 25, icon: "◎", nom: "Vibrat. Geometric Forms",
                issues: [ChakraIssue(label: "Motif géométrique diabète", sla: 76)], hasCIM: true,
                cimCodes: [
                    ("E11.51", "T2DM — angiopathie périphérique"),
                    ("E11.8",  "T2DM — complications non spécifiées")
                ]),
            ChakraInfo(num: 24, icon: "◌", nom: "Dimensions of the World Tree",
                issues: [], hasCIM: false, cimCodes: []),
        ]),

    DimensionInfo(id: "d5", num: 5,
        label: "D5 — Amour · Sensualité · Pléiades",
        description: "Corps Astral",
        defaultCollapsed: false,
        chakras: [
            ChakraInfo(num: 23, icon: "♥", nom: "Love — Immunodéficience",
                issues: [ChakraIssue(label: "Abuse Energy", sla: 70)], hasCIM: false, cimCodes: []),
            ChakraInfo(num: 22, icon: "▽", nom: "Sensuality — Trouble sommeil",
                issues: [ChakraIssue(label: "Incubus/Succubus G-1", sla: 67)], hasCIM: false, cimCodes: []),
            ChakraInfo(num: 21, icon: "✦", nom: "Light from the Pleiades", issues: [], hasCIM: false, cimCodes: []),
            ChakraInfo(num: 20, icon: "合", nom: "Channel for love 3D", issues: [], hasCIM: false, cimCodes: []),
            ChakraInfo(num: 19, icon: "◉", nom: "Universal Higher Bridge", issues: [], hasCIM: false, cimCodes: []),
            ChakraInfo(num: 18, icon: "✤", nom: "Nirodhah Star", issues: [], hasCIM: false, cimCodes: []),
            ChakraInfo(num: 17, icon: "◎", nom: "Life Tree — Génito-Urinaire",
                issues: [ChakraIssue(label: "Tuyau Jing 3.5 Ga", sla: 83)], hasCIM: false, cimCodes: []),
        ]),

    DimensionInfo(id: "d4", num: 4,
        label: "D4 — Couche autour de la Terre",
        description: "Corps Mental — Mythes · Archétypes",
        defaultCollapsed: false,
        chakras: [
            ChakraInfo(num: 16, icon: "☉", nom: "Universal Father — Égrégores",
                issues: [ChakraIssue(label: "Archétype Père abuseur 15 G", sla: 74)], hasCIM: false, cimCodes: []),
            ChakraInfo(num: 15, icon: "▽", nom: "Universal Mother — Mythes",
                issues: [ChakraIssue(label: "Mythe \"femme = proie\" — Ph.1", sla: 89)], hasCIM: false, cimCodes: []),
            ChakraInfo(num: 14, icon: "◈", nom: "Universal Core — Implants",
                issues: [ChakraIssue(label: "Implant Archon/Reptilian G-10", sla: 66)], hasCIM: false, cimCodes: []),
            ChakraInfo(num: 13, icon: "⬛", nom: "Earth Star — Maladie rénale",
                issues: [ChakraIssue(label: "KI×4 — risque néphropathie", sla: 83)], hasCIM: false, cimCodes: []),
            ChakraInfo(num: 12, icon: "◉", nom: "Galactic — Lésion vaisseaux",
                issues: [ChakraIssue(label: "Fork galactiques 3.5 Ga — Ph.2", sla: 89)], hasCIM: false, cimCodes: []),
            ChakraInfo(num: 11, icon: "☀", nom: "Solar Star", issues: [], hasCIM: false, cimCodes: []),
            ChakraInfo(num: 10, icon: "⊛", nom: "Atomic Doorway", issues: [], hasCIM: false, cimCodes: []),
            ChakraInfo(num: 9, icon: "♻", nom: "Higher Heart — Cœur Supérieur",
                issues: [ChakraIssue(label: "Phase 3 séance", sla: 89)], hasCIM: false, cimCodes: []),
        ]),

    DimensionInfo(id: "d3", num: 3,
        label: "D3 — Réalité incarnée 3D",
        description: "7 chakras classiques",
        defaultCollapsed: false,
        chakras: [
            ChakraInfo(num: 8, icon: "♛", nom: "Crown / Sahasrāra",
                issues: [], hasCIM: false, cimCodes: []),
            ChakraInfo(num: 7, icon: "—", nom: "Brow / Ājñā",
                issues: [], hasCIM: false, cimCodes: []),
            ChakraInfo(num: 6, icon: "⊞", nom: "Throat / Viśuddha",
                issues: [ChakraIssue(label: "LU×1 — expression bloquée G-7", sla: 83)], hasCIM: false, cimCodes: []),
            ChakraInfo(num: 5, icon: "♥", nom: "Heart / Anāhata — CV17",
                issues: [ChakraIssue(label: "Phase 4 — Porte du Cœur", sla: 89)], hasCIM: false, cimCodes: []),
            ChakraInfo(num: 4, icon: "◉", nom: "Naval / Manipūra — Plexus",
                issues: [ChakraIssue(label: "SP×6 — Yi saturé", sla: 80)], hasCIM: false, cimCodes: []),
            ChakraInfo(num: 3, icon: "⊗", nom: "Sacral / Svādhisthāna",
                issues: [ChakraIssue(label: "Honte ancestrale 15 G", sla: 85)], hasCIM: false, cimCodes: []),
            ChakraInfo(num: 2, icon: "◑", nom: "Base / Mūlādhāra",
                issues: [ChakraIssue(label: "KI racine — Jing pollué", sla: 85)], hasCIM: false, cimCodes: []),
        ]),

    DimensionInfo(id: "d2", num: 2,
        label: "D2 — Espace tellurique",
        description: "Entre centre Terre et surface",
        defaultCollapsed: true,
        chakras: [
            ChakraInfo(num: nil, icon: "◌", nom: "Royaume tellurique",
                issues: [], hasCIM: false, cimCodes: []),
        ]),

    DimensionInfo(id: "d1", num: 1,
        label: "D1 — Cristal de fer · Centre Terre",
        description: "7.8 Hz Schumann",
        defaultCollapsed: false,
        chakras: [
            ChakraInfo(num: 1, icon: "◈", nom: "Earth Chakra",
                issues: [ChakraIssue(label: "Ancrage défaillant — KI1 Nuummite", sla: 83)], hasCIM: false, cimCodes: []),
        ]),

    DimensionInfo(id: "d0", num: 99,
        label: "D99 — Architecture Galactique",
        description: "Méta-dimensionnel · Patient / Système",
        defaultCollapsed: true,
        chakras: [
            ChakraInfo(num: 45, icon: "◈", nom: "Monade — Unité source",
                issues: [], hasCIM: false, cimCodes: []),
            ChakraInfo(num: 44, icon: "⧫", nom: "Interface biophotonique — ADN lumière",
                issues: [], hasCIM: false, cimCodes: []),
            ChakraInfo(num: 43, icon: "⬟", nom: "Dodécaèdre — Éther universel",
                issues: [], hasCIM: false, cimCodes: []),
            ChakraInfo(num: 42, icon: "◎", nom: "Anneau Tor — Flux toroïdal vital",
                issues: [], hasCIM: false, cimCodes: []),
            ChakraInfo(num: 41, icon: "⌖", nom: "Point zéro — Vide quantique",
                issues: [], hasCIM: false, cimCodes: []),
            ChakraInfo(num: 40, icon: "☯", nom: "Équilibre Yin/Yang — Polarité systémique",
                issues: [], hasCIM: false, cimCodes: []),
            ChakraInfo(num: 39, icon: "◬", nom: "Portail ascension — Transit S0↔S8",
                issues: [], hasCIM: false, cimCodes: []),
            ChakraInfo(num: 38, icon: "⬡", nom: "Matrice Métatronique — Géométrie sacrée",
                issues: [], hasCIM: false, cimCodes: []),
            ChakraInfo(num: 37, icon: "✦", nom: "Système nerveux subtil — Nadis",
                issues: [], hasCIM: false, cimCodes: []),
            ChakraInfo(num: 36, icon: "⊛", nom: "Plans transverses — Champs morphiques",
                issues: [], hasCIM: false, cimCodes: []),
            ChakraInfo(num: 35, icon: "⊗", nom: "Réseau Akashique — Mémoire collective",
                issues: [], hasCIM: false, cimCodes: []),
            ChakraInfo(num: 34, icon: "⊕", nom: "Système Source — Origine primordiale",
                issues: [], hasCIM: false, cimCodes: []),
        ]),
]

// MARK: - Lookup helpers
func chakraName(forKey key: String) -> String? {
    for dim in allDimensions {
        for c in dim.chakras where dim.chakraKey(c) == key { return c.nom }
    }
    return nil
}

func initialChakraStates() -> [String: Bool] {
    var s: [String: Bool] = [:]
    for dim in allDimensions {
        for c in dim.chakras { s[dim.chakraKey(c)] = false }
    }
    return s
}
