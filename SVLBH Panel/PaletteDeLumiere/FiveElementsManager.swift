//
//  FiveElementsManager.swift
//  SVLBH Panel — importé de Palette de Lumière
//

import SwiftUI
import Combine

@MainActor
class FiveElementsManager: ObservableObject {

    @Published var bilans: [BilanEnergetique] = []
    @Published var currentBilan: BilanEnergetique?
    @Published var selectedElement: TCMElement = .terre

    init() { loadBilans() }

    func creerNouveauBilan() -> BilanEnergetique {
        let bilan = BilanEnergetique()
        currentBilan = bilan
        return bilan
    }

    func updateNiveau(element: TCMElement, niveau: Double, qualite: NiveauEnergetique.QualiteEnergie) {
        guard var bilan = currentBilan else { return }
        bilan.niveaux[element] = NiveauEnergetique(niveau: niveau, qualite: qualite)
        currentBilan = bilan
    }

    func sauvegarderBilan(notes: String) {
        guard var bilan = currentBilan else { return }
        bilan.notes = notes
        bilans.append(bilan)
        saveBilans()
        currentBilan = nil
    }

    func analyserCycleGeneration() -> [DesequilibreEnergetique] {
        guard let bilan = currentBilan ?? bilans.last else { return [] }
        var desequilibres: [DesequilibreEnergetique] = []
        for element in TCMElement.allCases {
            guard let niveauSource = bilan.niveaux[element],
                  let niveauCible = bilan.niveaux[element.engendre] else { continue }
            if niveauSource.niveau < 0.3 && niveauCible.niveau < 0.4 {
                desequilibres.append(DesequilibreEnergetique(
                    type: .insuffisanceGeneration, elementSource: element, elementCible: element.engendre,
                    description: "\(element.rawValue) en vide ne peut pas nourrir \(element.engendre.rawValue)",
                    recommandation: "Tonifier \(element.rawValue) avec la couleur \(element.color.description)"))
            }
        }
        return desequilibres
    }

    func analyserCycleControle() -> [DesequilibreEnergetique] {
        guard let bilan = currentBilan ?? bilans.last else { return [] }
        var desequilibres: [DesequilibreEnergetique] = []
        for element in TCMElement.allCases {
            guard let niveauSource = bilan.niveaux[element],
                  let niveauCible = bilan.niveaux[element.controle] else { continue }
            if niveauSource.niveau > 0.7 && niveauCible.niveau < 0.3 {
                desequilibres.append(DesequilibreEnergetique(
                    type: .excesControle, elementSource: element, elementCible: element.controle,
                    description: "\(element.rawValue) en excès opprime \(element.controle.rawValue)",
                    recommandation: "Disperser \(element.rawValue) et tonifier \(element.controle.rawValue)"))
            }
            if niveauSource.niveau < 0.3 && niveauCible.niveau > 0.7 {
                desequilibres.append(DesequilibreEnergetique(
                    type: .controleInverse, elementSource: element, elementCible: element.controle,
                    description: "\(element.controle.rawValue) contre-domine \(element.rawValue)",
                    recommandation: "Rétablir l'équilibre entre ces deux éléments"))
            }
        }
        return desequilibres
    }

    func recommandationsCouleurs() -> [RecommandationCouleur] {
        guard let bilan = currentBilan ?? bilans.last else { return [] }
        var recommandations: [RecommandationCouleur] = []
        for (element, niveau) in bilan.niveaux {
            if niveau.niveau < 0.3 {
                recommandations.append(RecommandationCouleur(
                    couleur: element.color, element: element, action: .tonifier, dureeRecommandee: 15, priorite: .haute))
            } else if niveau.niveau > 0.7 {
                recommandations.append(RecommandationCouleur(
                    couleur: element.controle.color, element: element, action: .disperser, dureeRecommandee: 10, priorite: .moyenne))
            }
            switch niveau.qualite {
            case .stagnation:
                recommandations.append(RecommandationCouleur(
                    couleur: Color(hex: "#4CAF50"), element: element, action: .fairCirculer, dureeRecommandee: 12, priorite: .haute))
            case .chaleur:
                recommandations.append(RecommandationCouleur(
                    couleur: Color(hex: "#2196F3"), element: element, action: .rafraichir, dureeRecommandee: 10, priorite: .haute))
            case .froid:
                recommandations.append(RecommandationCouleur(
                    couleur: Color(hex: "#F44336"), element: element, action: .rechauffer, dureeRecommandee: 10, priorite: .moyenne))
            default: break
            }
        }
        return recommandations.sorted { $0.priorite.rawValue > $1.priorite.rawValue }
    }

    private func saveBilans() {
        if let encoded = try? JSONEncoder().encode(bilans) {
            UserDefaults.standard.set(encoded, forKey: "energy_bilans")
        }
    }

    private func loadBilans() {
        if let data = UserDefaults.standard.data(forKey: "energy_bilans"),
           let decoded = try? JSONDecoder().decode([BilanEnergetique].self, from: data) {
            bilans = decoded
        }
    }
}

struct DesequilibreEnergetique: Identifiable {
    let id = UUID()
    let type: TypeDesequilibre
    let elementSource: TCMElement
    let elementCible: TCMElement
    let description: String
    let recommandation: String

    enum TypeDesequilibre: String {
        case insuffisanceGeneration = "Insuffisance de génération"
        case excesControle = "Excès de contrôle"
        case controleInverse = "Contrôle inversé"
    }
}

struct RecommandationCouleur: Identifiable {
    let id = UUID()
    let couleur: Color
    let element: TCMElement
    let action: ActionTherapeutique
    let dureeRecommandee: Int
    let priorite: Priorite

    enum ActionTherapeutique: String {
        case tonifier = "Tonifier"
        case disperser = "Disperser"
        case fairCirculer = "Faire circuler"
        case rafraichir = "Rafraîchir"
        case rechauffer = "Réchauffer"
    }

    enum Priorite: Int {
        case basse = 0
        case moyenne = 1
        case haute = 2
    }
}
