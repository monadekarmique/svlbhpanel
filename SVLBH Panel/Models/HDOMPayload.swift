// SVLBHPanel — Models/HDOMPayload.swift
// Phase 1 Managed Agents — DTOs envoyés à / reçus de `hdom-session-agent`.
//
// Schema v0.1 aligné sur le system prompt hdom-session-agent v0.1 produit
// par Claude.ai (protocole radiesthésique : propositions Type A chromatiques
// + Type B lymphatiques monadiques, avec confidence + rationale).

import Foundation

// MARK: - Input (iOS → agent)

/// Payload envoyé à `hdom-session-agent` pour préparer une séance.
/// Construit depuis `SessionState.toHDOMAgentInput(tracker:)`.
///
/// Schema aligné sur la section "Entrées Attendues" du system prompt v0.1.
struct HDOMAgentInput: Codable {
    let patienteId: String
    let sla: Int?
    let slsa: Int?
    /// Pas encore présent dans `ScoresLumiere` — toujours nil en v0.1.
    /// TODO: câbler quand le modèle iOS exposera SLPMO.
    let slpmo: Int?
    let slm: Int?
    /// Format "HH:MM" (pas ISO, pour matcher le system prompt).
    let heureReveil: String?
    /// Directions cardinales extraites des events tracker.roseDesVentsEvents.
    /// Toujours présent (empty array si aucun event).
    let roseDesVents: [String]
    /// Notes libres de la séance précédente — non câblé en v0.1.
    let notesSeancePrecedente: String?
    /// Flags profil patient — non câblés en v0.1 (restent nil).
    let profilEndometriose: Bool?
    let profilFerritineBasse: Bool?

    enum CodingKeys: String, CodingKey {
        case patienteId = "patiente_id"
        case sla, slsa, slpmo, slm
        case heureReveil = "heure_reveil"
        case roseDesVents = "rose_des_vents"
        case notesSeancePrecedente = "notes_seance_precedente"
        case profilEndometriose = "profil_endometriose"
        case profilFerritineBasse = "profil_ferritine_basse"
    }
}

// MARK: - Output (agent → iOS)

/// Résultat structuré retourné par `hdom-session-agent`.
/// L'agent s'engage à produire du JSON strict avec ces clés
/// (voir system prompt v0.1 — section "Format de sortie JSON strict").
struct HDOMPreparationResult: Codable, Equatable {
    /// Bloc markdown : décodage hDOM + signature diagnostique.
    let decodage: String
    /// Bloc markdown : protocole proposé phase par phase.
    let protocole: String
    /// Bloc markdown : chromothérapie suggérée.
    let chromotherapie: String
    /// Propositions à valider par radiesthésie — Types A et B.
    /// Vide = pas de propositions (peut arriver si l'agent bloque sur sécurité praticienne).
    let propositions: [Proposition]
    /// Métadonnées libres (meridien du jour, skills actifs, etc.).
    let metadata: [String: String]?

    init(
        decodage: String,
        protocole: String,
        chromotherapie: String,
        propositions: [Proposition] = [],
        metadata: [String: String]? = nil
    ) {
        self.decodage = decodage
        self.protocole = protocole
        self.chromotherapie = chromotherapie
        self.propositions = propositions
        self.metadata = metadata
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        decodage = try c.decode(String.self, forKey: .decodage)
        protocole = try c.decode(String.self, forKey: .protocole)
        chromotherapie = try c.decode(String.self, forKey: .chromotherapie)
        propositions = try c.decodeIfPresent([Proposition].self, forKey: .propositions) ?? []
        metadata = try c.decodeIfPresent([String: String].self, forKey: .metadata)
    }

    enum CodingKeys: String, CodingKey {
        case decodage, protocole, chromotherapie, propositions, metadata
    }

    // MARK: - Proposition à valider par radiesthésie

    struct Proposition: Codable, Equatable, Identifiable {
        let type: PropositionType
        let label: String
        /// Score 0.0 — 1.0. Si < 0.95, `rationale` est obligatoire.
        let confidence: Double
        /// Raison explicite de la confiance réduite (requise si confidence < 0.95).
        let rationale: String?
        /// Champs spécifiques au type de proposition (dict string libre).
        let details: [String: String]?

        /// Identifiant stable pour SwiftUI (pas de collision UI).
        var id: String { "\(type.rawValue)::\(label)" }

        /// true si la proposition est au-dessus du seuil de confiance VLBH.
        var isHighConfidence: Bool { confidence >= 0.95 }

        /// true si la proposition devrait afficher son rationale.
        var requiresRationale: Bool { !isHighConfidence }

        /// Confiance en pourcentage entier (0–100).
        var confidencePercent: Int { Int((confidence * 100).rounded()) }
    }

    enum PropositionType: String, Codable, CaseIterable {
        case pathologieChromatique = "pathologie_chromatique"
        case lymphatiqueMonadique = "lymphatique_monadique"

        var displayName: String {
            switch self {
            case .pathologieChromatique: return "Pathologie chromatique"
            case .lymphatiqueMonadique: return "Guérissabilité lymphatique monadique"
            }
        }

        var iconName: String {
            switch self {
            case .pathologieChromatique: return "paintpalette.fill"
            case .lymphatiqueMonadique: return "drop.circle.fill"
            }
        }
    }
}

// MARK: - Parser helper

enum HDOMParseError: LocalizedError {
    case emptyResponse
    case jsonNotFound(raw: String)
    case decodingFailed(String, raw: String)
    case rationaleRequired(label: String)

    var errorDescription: String? {
        switch self {
        case .emptyResponse:
            return "Réponse agent vide."
        case .jsonNotFound(let raw):
            return "Aucun JSON trouvé dans la réponse. Extrait: \(raw.prefix(200))"
        case .decodingFailed(let msg, let raw):
            return "Décodage échoué: \(msg). Extrait: \(raw.prefix(200))"
        case .rationaleRequired(let label):
            return "Proposition « \(label) » avec confidence < 95 % mais aucun rationale fourni — rejet côté iOS."
        }
    }
}

extension HDOMPreparationResult {
    /// Tente de parser la sortie texte de l'agent en `HDOMPreparationResult`.
    ///
    /// Ordre de tentatives :
    /// 1. Texte brut parseable en JSON
    /// 2. Bloc ```json ... ``` extrait du texte
    /// 3. Premier `{` → dernier `}` du texte
    ///
    /// Après décodage réussi : valide la règle « confidence < 95 % ⇒ rationale requis ».
    /// Toute proposition qui viole cette règle → `HDOMParseError.rationaleRequired`.
    static func parse(from text: String) throws -> HDOMPreparationResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw HDOMParseError.emptyResponse }

        let candidates: [String] = [
            trimmed,
            extractFencedJSON(from: trimmed),
            extractBracedJSON(from: trimmed)
        ].compactMap { $0 }

        let decoder = JSONDecoder()
        for candidate in candidates {
            guard let data = candidate.data(using: .utf8) else { continue }
            if let result = try? decoder.decode(HDOMPreparationResult.self, from: data) {
                try validateRationales(result.propositions)
                return result
            }
        }
        throw HDOMParseError.jsonNotFound(raw: trimmed)
    }

    /// Vérifie que chaque proposition < 95 % a bien un rationale non-vide.
    private static func validateRationales(_ propositions: [Proposition]) throws {
        for p in propositions where p.confidence < 0.95 {
            guard let rat = p.rationale, !rat.trimmingCharacters(in: .whitespaces).isEmpty else {
                throw HDOMParseError.rationaleRequired(label: p.label)
            }
        }
    }

    private static func extractFencedJSON(from text: String) -> String? {
        let patterns = ["```json\\s*([\\s\\S]*?)```", "```\\s*([\\s\\S]*?)```"]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            if let match = regex.firstMatch(in: text, range: range),
               match.numberOfRanges >= 2,
               let r = Range(match.range(at: 1), in: text) {
                let inside = String(text[r]).trimmingCharacters(in: .whitespacesAndNewlines)
                if inside.hasPrefix("{") { return inside }
            }
        }
        return nil
    }

    private static func extractBracedJSON(from text: String) -> String? {
        guard let first = text.firstIndex(of: "{"),
              let last = text.lastIndex(of: "}"),
              first < last else { return nil }
        return String(text[first...last])
    }
}
