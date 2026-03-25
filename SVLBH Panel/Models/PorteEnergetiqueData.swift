// SVLBHPanel — Models/PorteEnergetiqueData.swift
// v4.8.0 — Données portes énergétiques d'entrées (temporaires + permanentes)

import Foundation

struct PorteEnergetique: Identifiable {
    let id = UUID()
    let numero: Int
    let nom: String
    let point: String
    let condition: String
    let statut: String
    let isPermanent: Bool
}

struct PorteChakraInfo: Identifiable {
    let id: Int       // 7 à 1
    let nom: String
    let sanskrit: String
}

enum PorteEnergetiqueData {

    static let chakras: [PorteChakraInfo] = [
        PorteChakraInfo(id: 7, nom: "Couronne", sanskrit: "Sahasrara"),
        PorteChakraInfo(id: 6, nom: "Troisième Œil", sanskrit: "Ajna"),
        PorteChakraInfo(id: 5, nom: "Gorge", sanskrit: "Vishuddha"),
        PorteChakraInfo(id: 4, nom: "Cœur", sanskrit: "Anahata"),
        PorteChakraInfo(id: 3, nom: "Plexus Solaire", sanskrit: "Manipura"),
        PorteChakraInfo(id: 2, nom: "Sacré", sanskrit: "Svadhisthana"),
        PorteChakraInfo(id: 1, nom: "Racine", sanskrit: "Muladhara"),
    ]

    static let temporaires: [PorteEnergetique] = [
        PorteEnergetique(numero: 1, nom: "Porte du Plexus", point: "CV12",
                         condition: "Émotions fortes, empathie excessive",
                         statut: "Temporaire si refermée rapidement", isPermanent: false),
        PorteEnergetique(numero: 2, nom: "Porte du Cœur", point: "CV17",
                         condition: "Chagrin, trahison récente",
                         statut: "Temporaire si travaillée", isPermanent: false),
        PorteEnergetique(numero: 3, nom: "Porte de la Nuque", point: "GV16",
                         condition: "Froid, peur soudaine",
                         statut: "Temporaire si scellée", isPermanent: false),
    ]

    static let permanentes: [PorteEnergetique] = [
        PorteEnergetique(numero: 1, nom: "Porte du Sacrum", point: "GV4",
                         condition: "Épuisement du Jing, abus ancestraux",
                         statut: "Permanent si non traité (transmission transgénérationnelle)", isPermanent: true),
        PorteEnergetique(numero: 2, nom: "Porte du Sommet", point: "GV20",
                         condition: "Pratiques non protégées, substances",
                         statut: "Permanent si connexion établie avec D10-D11", isPermanent: true),
        PorteEnergetique(numero: 3, nom: "Multiples portes", point: "",
                         condition: "Trauma majeur, possession",
                         statut: "Permanent si système de portes compromis", isPermanent: true),
    ]
}
