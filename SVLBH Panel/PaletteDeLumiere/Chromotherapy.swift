//
//  Chromotherapy.swift
//  SVLBH Panel — importé de Palette de Lumière
//

import SwiftUI

// MARK: - Couleur Thérapeutique
struct CouleurTherapeutique: Identifiable, Codable {
    let id: UUID
    let nom: String
    let hexColor: String
    let frequenceNm: Int
    let frequenceThz: Double
    let element: TCMElement
    let proprietes: [String]
    let indications: [String]
    let contreIndications: [String]

    var color: Color {
        Color(hex: hexColor)
    }

    static let palette: [CouleurTherapeutique] = [
        CouleurTherapeutique(id: UUID(), nom: "Rouge", hexColor: "#FF0000", frequenceNm: 700, frequenceThz: 428, element: .feu,
            proprietes: ["Stimulant", "Énergisant", "Réchauffant"],
            indications: ["Fatigue", "Hypotension", "Anémie", "Dépression"],
            contreIndications: ["Hypertension", "Fièvre", "Inflammation aiguë"]),
        CouleurTherapeutique(id: UUID(), nom: "Orange", hexColor: "#FF8000", frequenceNm: 620, frequenceThz: 484, element: .feu,
            proprietes: ["Tonifiant", "Antispasmodique", "Joie"],
            indications: ["Troubles digestifs", "Crampes", "Pessimisme"],
            contreIndications: ["Anxiété excessive", "Agitation"]),
        CouleurTherapeutique(id: UUID(), nom: "Jaune", hexColor: "#FFFF00", frequenceNm: 580, frequenceThz: 517, element: .terre,
            proprietes: ["Digestif", "Mental", "Clarté"],
            indications: ["Troubles digestifs", "Concentration", "Rate"],
            contreIndications: ["Diarrhée", "Surexcitation mentale"]),
        CouleurTherapeutique(id: UUID(), nom: "Vert", hexColor: "#00FF00", frequenceNm: 530, frequenceThz: 566, element: .bois,
            proprietes: ["Équilibrant", "Régénérant", "Apaisant"],
            indications: ["Stress", "Problèmes hépatiques", "Colère"],
            contreIndications: ["États dépressifs profonds"]),
        CouleurTherapeutique(id: UUID(), nom: "Turquoise", hexColor: "#00CED1", frequenceNm: 500, frequenceThz: 600, element: .metal,
            proprietes: ["Rafraîchissant", "Immunité", "Communication"],
            indications: ["Gorge", "Thyroïde", "Expression"],
            contreIndications: ["Frilosité extrême"]),
        CouleurTherapeutique(id: UUID(), nom: "Bleu", hexColor: "#0000FF", frequenceNm: 470, frequenceThz: 638, element: .eau,
            proprietes: ["Calmant", "Anti-inflammatoire", "Rafraîchissant"],
            indications: ["Insomnie", "Hypertension", "Inflammation", "Peur"],
            contreIndications: ["Dépression", "Frilosité", "Hypotension"]),
        CouleurTherapeutique(id: UUID(), nom: "Indigo", hexColor: "#4B0082", frequenceNm: 445, frequenceThz: 674, element: .eau,
            proprietes: ["Intuitif", "Purificateur", "Profondeur"],
            indications: ["Troubles ORL", "Intuition", "Troisième œil"],
            contreIndications: ["États dissociatifs"]),
        CouleurTherapeutique(id: UUID(), nom: "Violet", hexColor: "#8B00FF", frequenceNm: 400, frequenceThz: 750, element: .metal,
            proprietes: ["Spirituel", "Transmutation", "Élévation"],
            indications: ["Deuil", "Transformation", "Lâcher-prise"],
            contreIndications: ["Déconnexion de la réalité"]),
        CouleurTherapeutique(id: UUID(), nom: "Blanc", hexColor: "#FFFFFF", frequenceNm: 0, frequenceThz: 0, element: .metal,
            proprietes: ["Purifiant", "Globalisant", "Clarté"],
            indications: ["Purification", "Nouveau départ", "Poumon"],
            contreIndications: [])
    ]
}

// MARK: - Protocole de Séance
struct ProtocoleChromotherapie: Identifiable, Codable {
    let id: UUID
    let nom: String
    let description: String
    let dureeMinutes: Int
    let couleurs: [CouleurSequence]
    let elementsCibles: [TCMElement]
    let objectif: ObjectifTherapeutique

    struct CouleurSequence: Codable {
        let couleurHex: String
        let dureeSecondes: Int
        let intensite: Double
        let transition: TypeTransition
    }

    enum TypeTransition: String, Codable {
        case instant = "Instantané"
        case fondu = "Fondu"
        case pulsation = "Pulsation"
    }

    enum ObjectifTherapeutique: String, Codable, CaseIterable {
        case equilibrage = "Équilibrage énergétique"
        case relaxation = "Relaxation profonde"
        case energisation = "Énergisation"
        case liberation = "Libération émotionnelle"
        case ancrage = "Ancrage terrestre"
        case elevation = "Élévation spirituelle"
        case decodage = "Décodage transgénérationnel"
    }
}

// MARK: - Session de Chromothérapie
struct SessionChromotherapie: Identifiable, Codable {
    let id: UUID
    let date: Date
    let protocole: ProtocoleChromotherapie
    var ressentiAvant: RessentieEmotionnel
    var ressentiApres: RessentieEmotionnel?
    var notes: String
    var elementsTravailles: [TCMElement]
    var memoiresLiberees: [MemoireTransgenerationnelle]

    struct RessentieEmotionnel: Codable {
        var niveauEnergie: Double
        var niveauCalme: Double
        var emotionPrincipale: String
        var sensationsCorporelles: String
    }
}

// MARK: - Mémoire Transgénérationnelle
struct MemoireTransgenerationnelle: Identifiable, Codable {
    let id: UUID
    var description: String
    var generation: Int
    var lignee: Lignee
    var elementAssocie: TCMElement
    var couleurLiberatrice: String
    var dateIdentification: Date
    var estLiberee: Bool
    var dateLiberarion: Date?

    enum Lignee: String, Codable, CaseIterable {
        case paternelle = "Paternelle"
        case maternelle = "Maternelle"
        case mixte = "Mixte"
    }
}
