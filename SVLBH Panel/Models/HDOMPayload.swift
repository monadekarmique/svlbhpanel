// SVLBHPanel — Models/HDOMPayload.swift
// Phase 1 Managed Agents — DTOs envoyés à / reçus de `hdom-session-agent`.

import Foundation

// MARK: - Input (iOS → agent)

/// Payload envoyé à `hdom-session-agent` pour préparer une séance.
/// Construit depuis `SessionState.toHDOMAgentInput(tracker:)`.
struct HDOMAgentInput: Codable {
    let patientId: String
    let sessionNum: String
    let sessionProgramCode: String

    /// SLA thérapeute (source de vérité pour le décodage).
    let sla: Int?
    /// SLSA effectif (SA1 seul si pas de détail, sinon somme SA1–SA5).
    let slsa: Int?
    let slsaS1: Int?
    let slsaS2: Int?
    let slsaS3: Int?
    let slsaS4: Int?
    let slsaS5: Int?

    /// Heure de réveil de la patiente (ISO8601). Nil si non renseignée.
    let heureReveil: String?
    /// HH:mm local — extrait de heureReveil pour confort de lecture côté agent.
    let heureReveilLocal: String?

    /// Événements "Rose des Vents" loggés dans le tracker de session.
    let roseDesVents: [RoseEvent]

    /// Horodatage de construction du payload (ISO8601).
    let generatedAt: String

    /// Version du schéma pour permettre une évolution côté agent.
    let schemaVersion: Int

    struct RoseEvent: Codable {
        let timestamp: String   // ISO8601
        let timeLocal: String   // HH:mm
        let label: String
        let detail: String?
        let niveau: String?
    }

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case sessionNum = "session_num"
        case sessionProgramCode = "session_program_code"
        case sla
        case slsa
        case slsaS1 = "slsa_s1"
        case slsaS2 = "slsa_s2"
        case slsaS3 = "slsa_s3"
        case slsaS4 = "slsa_s4"
        case slsaS5 = "slsa_s5"
        case heureReveil = "heure_reveil"
        case heureReveilLocal = "heure_reveil_local"
        case roseDesVents = "rose_des_vents"
        case generatedAt = "generated_at"
        case schemaVersion = "schema_version"
    }
}

// MARK: - Output (agent → iOS)

/// Résultat structuré retourné par `hdom-session-agent`.
/// L'agent s'engage à produire du JSON strict avec ces 3 clés
/// (voir `docs/skills-templates/hdom-decoder.SKILL.md`).
struct HDOMPreparationResult: Codable, Equatable {
    /// Bloc markdown : décodage hDOM du jour.
    let decodage: String
    /// Bloc markdown : protocole de séance recommandé.
    let protocole: String
    /// Bloc markdown : chromothérapie.
    let chromotherapie: String
    /// Métadonnées optionnelles (méridien actif, cluster détecté, etc.).
    let metadata: [String: String]?

    enum CodingKeys: String, CodingKey {
        case decodage, protocole, chromotherapie, metadata
    }
}

// MARK: - Parser helper

enum HDOMParseError: LocalizedError {
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

extension HDOMPreparationResult {
    /// Tente de parser la sortie texte de l'agent en `HDOMPreparationResult`.
    ///
    /// Ordre de tentatives :
    /// 1. Texte brut parseable en JSON
    /// 2. Bloc ```json ... ``` extrait du texte
    /// 3. Premier `{` → dernier `}` du texte
    ///
    /// Si rien ne marche → `HDOMParseError.jsonNotFound`.
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
                return result
            }
        }
        throw HDOMParseError.jsonNotFound(raw: trimmed)
    }

    private static func extractFencedJSON(from text: String) -> String? {
        // Cherche ```json ... ``` ou ``` ... ``` contenant du JSON
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
