// SVLBHPanel — Models/ParasiteEnergyData.swift
// v4.8.0 — Classification des énergies parasitaires (Provocation)

import SwiftUI

enum EnergyType: String, Codable {
    case permanent, temporary

    var color: Color {
        switch self {
        case .permanent: return Color(hex: "#8B5CF6")
        case .temporary: return Color(hex: "#10B981")
        }
    }

    var label: String {
        switch self {
        case .permanent: return "PERMANENT"
        case .temporary: return "TEMPORAIRE"
        }
    }
}

struct ParasiteEnergy: Identifiable {
    let id = UUID()
    let numero: Int
    let nom: String
    let description: String
    let niveau: String
    let liberation: String
    let type: EnergyType
}

// MARK: - Données statiques

enum ParasiteEnergyData {

    static let permanentes: [ParasiteEnergy] = [
        ParasiteEnergy(numero: 1, nom: "Anchors, Chains, and Hooks", description: "Liens karmiques ou ancestraux profonds", niveau: "D7-D11", liberation: "Travail transgénérationnel, libération des vœux ancestraux", type: .permanent),
        ParasiteEnergy(numero: 2, nom: "Black Magick", description: "Travail magique intentionnel ancré", niveau: "D7-D11", liberation: "Dégagement profond, praticien qualifié", type: .permanent),
        ParasiteEnergy(numero: 3, nom: "Blackmail", description: "Emprise par la peur ou la honte ancestrale", niveau: "D7-D11", liberation: "Libération des secrets de famille, pardon transgénérationnel", type: .permanent),
        ParasiteEnergy(numero: 4, nom: "Core Wound", description: "Blessure fondamentale de l'âme/incarnation", niveau: "D7-D11", liberation: "Travail T3 profond, réconciliation avec l'origine", type: .permanent),
        ParasiteEnergy(numero: 5, nom: "Dark Energy", description: "Énergie sombre ancrée dans l'aura", niveau: "D7-D11", liberation: "Nettoyage profond de l'arbre hermétique", type: .permanent),
        ParasiteEnergy(numero: 6, nom: "Dark Force Energy", description: "Connexion à des forces obscures transgénérationnelles", niveau: "D7-D11", liberation: "Fermeture des portes dimensionnelles, rupture des pactes", type: .permanent),
        ParasiteEnergy(numero: 7, nom: "Dark Magician Energy", description: "Héritage de pratiques magiques dans la lignée", niveau: "D7-D11", liberation: "Renonciation aux pactes ancestraux", type: .permanent),
        ParasiteEnergy(numero: 8, nom: "Dark Overlord Energy", description: "Domination par entité de haut niveau (D10-D11)", niveau: "D10-D11", liberation: "Dégagement expert, fermeture de GV20", type: .permanent),
        ParasiteEnergy(numero: 9, nom: "Death Wish", description: "Programmation de mort héritée ou auto-créée", niveau: "D7-D11", liberation: "Reprogrammation cellulaire, choix conscient de vie", type: .permanent),
        ParasiteEnergy(numero: 10, nom: "Demon Consciousness", description: "Fragment de conscience démoniaque hérité", niveau: "D7-D11", liberation: "Exorcisme énergétique, fermeture des portes", type: .permanent),
        ParasiteEnergy(numero: 11, nom: "Demonic Energy", description: "Énergie démoniaque transgénérationnelle", niveau: "D3-D4", liberation: "Travail D3-D4, expulsion", type: .permanent),
        ParasiteEnergy(numero: 12, nom: "Desperation Energy", description: "Désespoir profond hérité des ancêtres", niveau: "D7-D11", liberation: "Guérison de la lignée, restauration de l'espoir", type: .permanent),
        ParasiteEnergy(numero: 13, nom: "Domination Energy", description: "Pattern domination/soumission transgénérationnel", niveau: "D7-D11", liberation: "Libération des rôles familiaux, reprise du pouvoir", type: .permanent),
        ParasiteEnergy(numero: 14, nom: "Evil Eye", description: "Mauvais œil profondément ancré", niveau: "D6-D4", liberation: "Protocole VB37 + F3 + Yintang, miroir permanent", type: .permanent),
        ParasiteEnergy(numero: 15, nom: "Healer's Curse", description: "Malédiction liée à un don de guérison", niveau: "D7-D11", liberation: "Réconciliation du don, purification de l'héritage", type: .permanent),
        ParasiteEnergy(numero: 16, nom: "Hex", description: "Malédiction rituelle ancienne", niveau: "D7-D11", liberation: "Identification de l'origine, annulation par praticien", type: .permanent),
        ParasiteEnergy(numero: 17, nom: "Impersonation Energy", description: "Entité usurpant l'identité (possession partielle)", niveau: "D7-D11", liberation: "Affirmation d'identité, expulsion de l'intrus", type: .permanent),
        ParasiteEnergy(numero: 18, nom: "Infinity Curse", description: "Malédiction à répétition infinie dans la lignée", niveau: "D7-D11", liberation: "Rupture du cycle, travail sur la source originelle", type: .permanent),
        ParasiteEnergy(numero: 19, nom: "Insanity Energy", description: "Folie héritée transgénérationnellement", niveau: "D7-D11", liberation: "Ancrage de la raison, différenciation d'avec les ancêtres", type: .permanent),
        ParasiteEnergy(numero: 20, nom: "Mark", description: "Marque énergétique permanente (sceau, tatouage astral)", niveau: "D7-D11", liberation: "Effacement du sceau, travail sur l'arbre hermétique", type: .permanent),
        ParasiteEnergy(numero: 21, nom: "Mind Control Energy", description: "Contrôle mental profond (MK, programmation)", niveau: "D7-D11", liberation: "Déprogrammation profonde, reconstruction de l'identité", type: .permanent),
        ParasiteEnergy(numero: 22, nom: "Mutation Curse", description: "Malédiction affectant le code génétique/énergétique", niveau: "D7-D11", liberation: "Guérison du code, restoration de la matrice originelle", type: .permanent),
        ParasiteEnergy(numero: 23, nom: "Narcissism Energy", description: "Pattern narcissique hérité de la lignée", niveau: "D7-D11", liberation: "Travail sur l'inversion de l'amour, retour à l'unité", type: .permanent),
        ParasiteEnergy(numero: 24, nom: "Occult", description: "Liens occultes transgénérationnels", niveau: "D7-D11", liberation: "Renonciation aux pactes, fermeture des portes", type: .permanent),
        ParasiteEnergy(numero: 25, nom: "Satanic Energy", description: "Énergie satanique ancrée dans la lignée", niveau: "D10-D11", liberation: "Travail expert, fermeture des portes D10-D11", type: .permanent),
        ParasiteEnergy(numero: 26, nom: "Seed", description: "Graine de programme destructeur dans l'inconscient", niveau: "D7-D11", liberation: "Extraction de la graine, guérison du terrain", type: .permanent),
        ParasiteEnergy(numero: 27, nom: "Self-Abuse Energy", description: "Pattern d'auto-abus transgénérationnel", niveau: "D7-D11", liberation: "Libération de la culpabilité héritée, auto-amour", type: .permanent),
        ParasiteEnergy(numero: 28, nom: "Self-Cord", description: "Cordon avec une partie dissociée de soi", niveau: "D7-D11", liberation: "Réintégration du fragment, guérison du trauma", type: .permanent),
        ParasiteEnergy(numero: 29, nom: "Self-Criticism Energy", description: "Auto-critique profonde héritée", niveau: "D7-D11", liberation: "Travail sur le juge intérieur ancestral", type: .permanent),
        ParasiteEnergy(numero: 30, nom: "Self-Deception Energy", description: "Auto-illusion structurelle", niveau: "D7-D11", liberation: "Confrontation avec la vérité, acceptation du réel", type: .permanent),
        ParasiteEnergy(numero: 31, nom: "Self-Destruct Switch", description: "Programmation d'auto-destruction", niveau: "D7-D11", liberation: "Désactivation du programme, choix de vie", type: .permanent),
        ParasiteEnergy(numero: 32, nom: "Self-Harm", description: "Pattern d'auto-mutilation transgénérationnel", niveau: "D7-D11", liberation: "Travail sur la culpabilité ancestrale", type: .permanent),
        ParasiteEnergy(numero: 33, nom: "Self-Hatred", description: "Haine de soi profonde héritée", niveau: "D7-D11", liberation: "Réconciliation avec la lignée, auto-acceptation", type: .permanent),
        ParasiteEnergy(numero: 34, nom: "Self-Punishment", description: "Auto-punition structurelle héritée", niveau: "D7-D11", liberation: "Libération de la dette karmique perçue", type: .permanent),
        ParasiteEnergy(numero: 35, nom: "Self-Recrimination", description: "Auto-accusation permanente", niveau: "D7-D11", liberation: "Pardon de soi, libération de la culpabilité", type: .permanent),
        ParasiteEnergy(numero: 36, nom: "Self-Sabotage Energy", description: "Pattern de sabotage transgénérationnel", niveau: "D7-D11", liberation: "Identification des loyautés invisibles, libération", type: .permanent),
        ParasiteEnergy(numero: 37, nom: "Sorcery", description: "Sorcellerie ancestrale active", niveau: "D7-D11", liberation: "Rupture des liens, fermeture des portes", type: .permanent),
        ParasiteEnergy(numero: 38, nom: "Spell", description: "Sort ancien actif dans la lignée", niveau: "D7-D11", liberation: "Annulation du sort, travail sur l'origine", type: .permanent),
        ParasiteEnergy(numero: 39, nom: "Spitting Curse", description: "Malédiction transmise par crachat (ancestral)", niveau: "D7-D11", liberation: "Purification de la bouche ancestrale", type: .permanent),
        ParasiteEnergy(numero: 40, nom: "Stain", description: "Tache énergétique permanente (honte, déshonneur)", niveau: "D7-D11", liberation: "Purification de la mémoire familiale", type: .permanent),
        ParasiteEnergy(numero: 41, nom: "Stamp", description: "Tampon karmique de la lignée", niveau: "D7-D11", liberation: "Effacement du sceau karmique", type: .permanent),
        ParasiteEnergy(numero: 42, nom: "Subliminal Entity", description: "Entité subliminale installée", niveau: "D6-D4", liberation: "Identification et expulsion", type: .permanent),
        ParasiteEnergy(numero: 43, nom: "Voodoo", description: "Travail vaudou ancestral ou actif", niveau: "D7-D11", liberation: "Dégagement par praticien qualifié", type: .permanent),
        ParasiteEnergy(numero: 44, nom: "Warlock Energy", description: "Énergie de sorcier masculin dans la lignée", niveau: "D7-D11", liberation: "Renonciation aux pactes, libération du masculin", type: .permanent),
        ParasiteEnergy(numero: 45, nom: "Witch Energy", description: "Énergie de sorcière dans la lignée féminine", niveau: "D7-D11", liberation: "Réconciliation du féminin sacré", type: .permanent),
        ParasiteEnergy(numero: 46, nom: "Witchcraft", description: "Sorcellerie héritée ou active", niveau: "D7-D11", liberation: "Travail sur l'arbre hermétique, fermeture des portes", type: .permanent),
        ParasiteEnergy(numero: 47, nom: "Wizard Energy", description: "Énergie de magicien dans la lignée", niveau: "D7-D11", liberation: "Transformation de l'héritage en sagesse", type: .permanent),
        ParasiteEnergy(numero: 48, nom: "Written Curse", description: "Malédiction écrite (testament, contrat)", niveau: "D7-D11", liberation: "Annulation par l'écrit, contre-déclaration", type: .permanent),
    ]

    static let temporaires: [ParasiteEnergy] = [
        ParasiteEnergy(numero: 1, nom: "Addiction Energy", description: "Attachement temporaire à des substances ou comportements", niveau: "D1-D6", liberation: "Identification du besoin non satisfait, substitution consciente", type: .temporary),
        ParasiteEnergy(numero: 2, nom: "Baiting Energy", description: "Provocation ponctuelle pour déclencher une réaction", niveau: "D1-D6", liberation: "Non-réaction, retrait émotionnel conscient", type: .temporary),
        ParasiteEnergy(numero: 3, nom: "Brainwashing Energy", description: "Conditionnement mental récent", niveau: "D1-D6", liberation: "Déprogrammation par la conscience, reconditionnement positif", type: .temporary),
        ParasiteEnergy(numero: 4, nom: "Distortion Energy", description: "Perception déformée temporaire de la réalité", niveau: "D1-D6", liberation: "Ancrage, retour au corps physique", type: .temporary),
        ParasiteEnergy(numero: 5, nom: "Emotional Starvation", description: "Manque émotionnel situationnel", niveau: "D1-D6", liberation: "Reconnexion aux sources d'amour, auto-nourriture", type: .temporary),
        ParasiteEnergy(numero: 6, nom: "Eye-Rolling Energy", description: "Mépris ou dédain reçu récemment", niveau: "D1-D6", liberation: "Bouclier énergétique, non-attachement", type: .temporary),
        ParasiteEnergy(numero: 7, nom: "Gaslighting Energy", description: "Manipulation cognitive récente", niveau: "D1-D6", liberation: "Validation de sa propre réalité, ancrage dans les faits", type: .temporary),
        ParasiteEnergy(numero: 8, nom: "Jinx", description: "Malchance temporaire, mauvais sort léger", niveau: "D1-D6", liberation: "Purification par le sel, rupture de la chaîne", type: .temporary),
        ParasiteEnergy(numero: 9, nom: "Negative Self-Talk", description: "Dialogue intérieur négatif actif", niveau: "D1-D6", liberation: "Remplacement conscient, affirmations positives", type: .temporary),
        ParasiteEnergy(numero: 10, nom: "Negative Thought Form", description: "Forme-pensée négative récemment créée", niveau: "D6-D4", liberation: "Dissolution par la lumière, transformation alchimique", type: .temporary),
        ParasiteEnergy(numero: 11, nom: "Passive-Aggressive Energy", description: "Réception d'agressivité passive récente", niveau: "D1-D6", liberation: "Communication directe, clarification des intentions", type: .temporary),
        ParasiteEnergy(numero: 12, nom: "Poison", description: "Contamination énergétique aiguë", niveau: "D1-D6", liberation: "Purification immédiate, drainage énergétique", type: .temporary),
        ParasiteEnergy(numero: 13, nom: "Psychic Attack", description: "Attaque psychique ponctuelle", niveau: "D1-D6", liberation: "Bouclier, renvoi à l'expéditeur, coupure des liens", type: .temporary),
        ParasiteEnergy(numero: 14, nom: "Sarcasm Energy", description: "Énergie de sarcasme reçue", niveau: "D1-D6", liberation: "Non-absorption, miroir protecteur", type: .temporary),
        ParasiteEnergy(numero: 15, nom: "Self-Doubt", description: "Doute de soi situationnel", niveau: "D1-D6", liberation: "Reconnexion à ses succès, validation externe/interne", type: .temporary),
        ParasiteEnergy(numero: 16, nom: "Suppression Energy", description: "Énergie de suppression active", niveau: "D1-D6", liberation: "Expression authentique, libération de la voix", type: .temporary),
        ParasiteEnergy(numero: 17, nom: "Vampire Energy", description: "Vampirisme énergétique relationnel actif", niveau: "D1-D6", liberation: "Coupure des cordons, scellement des fuites", type: .temporary),
        ParasiteEnergy(numero: 18, nom: "Vex Energy", description: "Irritation ou contrariété reçue", niveau: "D1-D6", liberation: "Centrage, retour au calme intérieur", type: .temporary),
        ParasiteEnergy(numero: 19, nom: "Verbal Curse", description: "Malédiction verbale récente", niveau: "D1-D6", liberation: "Annulation par la parole, contre-déclaration", type: .temporary),
    ]
}
