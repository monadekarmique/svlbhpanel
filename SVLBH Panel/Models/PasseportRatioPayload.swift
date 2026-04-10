// SVLBHPanel — Models/PasseportRatioPayload.swift
// Phase 2 Managed Agents — DTOs échangés avec `passeport-ratio-agent`.
//
// Le calcul Ratio 4D reste local (Ratio4DDetailView + table ref21S).
// L'agent reçoit les valeurs déjà calculées et se concentre sur la
// rédaction du passeport en markdown.

import Foundation

// MARK: - Input (iOS → agent)

struct PasseportRatioInput: Codable {
    let patientId: String
    let sessionNum: String

    // Mesures saisies dans Ratio4DDetailView
    let pays: String
    let anneeTrauma: String?
    let sltda4D: Double?

    // Baseline 21S (venant de la table embarquée côté iOS)
    let baselineSlsaCh: Int
    let baselineSltdaOrig: Int
    let baselineSltdaCh: Int

    // Ratio + cluster — pré-calculés côté iOS
    let ratio4D: Double?
    let cluster: String

    // Contexte de la séance courante (optionnel, aide à contextualiser
    // la narrative)
    let scoresSession: ScoresSnapshot?

    let generatedAt: String
    let schemaVersion: Int

    struct ScoresSnapshot: Codable {
        let sla: Int?
        let slsa: Int?
    }

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case sessionNum = "session_num"
        case pays
        case anneeTrauma = "annee_trauma"
        case sltda4D = "sltda_4d"
        case baselineSlsaCh = "baseline_slsa_ch"
        case baselineSltdaOrig = "baseline_sltda_orig"
        case baselineSltdaCh = "baseline_sltda_ch"
        case ratio4D = "ratio_4d"
        case cluster
        case scoresSession = "scores_session"
        case generatedAt = "generated_at"
        case schemaVersion = "schema_version"
    }
}

// MARK: - Output (agent → iOS)

/// Passeport 4D rédigé par l'agent.
/// JSON strict attendu côté agent (voir system prompt).
struct PasseportRatioResult: Codable, Equatable {
    /// Passeport complet en markdown (prêt à être affiché / partagé).
    let passeportMarkdown: String
    /// Narrative interprétative courte (1–2 paragraphes).
    let narrative: String
    /// Liste de recommandations actionnables.
    let recommendations: [String]
    /// Métadonnées optionnelles (cluster confirmé, références utilisées, ...).
    let metadata: [String: String]?

    enum CodingKeys: String, CodingKey {
        case passeportMarkdown = "passeport_markdown"
        case narrative
        case recommendations
        case metadata
    }
}

// MARK: - Parser helper

enum PasseportParseError: LocalizedError {
    case emptyResponse
    case jsonNotFound(raw: String)
    case decodingFailed(String, raw: String)

    var errorDescription: String? {
        switch self {
        case .emptyResponse:
            return "Réponse agent vide."
        case .jsonNotFound(let raw):
            return "Aucun JSON trouvé dans la réponse. Extrait: \(raw.prefix(200))"
        case .decodingFailed(let msg, let raw):
            return "Décodage échoué: \(msg). Extrait: \(raw.prefix(200))"
        }
    }
}

extension PasseportRatioResult {
    /// Parser résilient identique à HDOMPreparationResult.parse :
    /// 1. Texte brut JSON
    /// 2. Bloc ```json ... ```
    /// 3. Premier { → dernier }
    static func parse(from text: String) throws -> PasseportRatioResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw PasseportParseError.emptyResponse }

        let candidates: [String] = [
            trimmed,
            extractFencedJSON(from: trimmed),
            extractBracedJSON(from: trimmed)
        ].compactMap { $0 }

        let decoder = JSONDecoder()
        for candidate in candidates {
            guard let data = candidate.data(using: .utf8) else { continue }
            if let result = try? decoder.decode(PasseportRatioResult.self, from: data) {
                return result
            }
        }
        throw PasseportParseError.jsonNotFound(raw: trimmed)
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
