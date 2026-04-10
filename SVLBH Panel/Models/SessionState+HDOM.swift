// SVLBHPanel — Models/SessionState+HDOM.swift
// Phase 1 Managed Agents — conversion SessionState → HDOMAgentInput.
//
// Schema aligné sur hdom-session-agent v0.1.
// Les événements Rose des Vents vivent dans `SessionTracker` (pas dans
// `SessionState`), d'où le paramètre `tracker`.

import Foundation

extension SessionState {

    /// Construit le payload envoyé à `hdom-session-agent`.
    /// Utilise les scores du thérapeute (`scoresTherapist`) par défaut.
    func toHDOMAgentInput(tracker: SessionTracker) -> HDOMAgentInput {
        let hmFormatter = DateFormatter()
        hmFormatter.dateFormat = "HH:mm"
        hmFormatter.locale = Locale(identifier: "fr_FR")

        let heureReveilStr = heureReveil.map { hmFormatter.string(from: $0) }

        // Extraire les directions cardinales uniques depuis les events tracker
        let directions = tracker.roseDesVentsEvents
            .compactMap(extractCardinalDirection(from:))
        // Dédoublonnage en préservant l'ordre d'apparition
        var seen = Set<String>()
        let uniqueDirections = directions.filter { seen.insert($0).inserted }

        let scores = scoresTherapist
        return HDOMAgentInput(
            patienteId: patientId,
            sla: scores.sla,
            slsa: scores.slsaEffective,
            slpmo: nil,                         // TODO: pas encore dans ScoresLumiere
            slm: scores.slm,
            heureReveil: heureReveilStr,
            roseDesVents: uniqueDirections,
            notesSeancePrecedente: nil,         // TODO: à brancher depuis SessionHistory
            profilEndometriose: nil,            // TODO: à brancher depuis profil patient
            profilFerritineBasse: nil           // TODO: idem
        )
    }

    /// Indique si le payload hDOM est assez complet pour invoquer l'agent.
    /// Minimum : SLA OU SLSA renseigné, et heure de réveil présente.
    func isHDOMPayloadReady() -> Bool {
        let scores = scoresTherapist
        let hasScore = scores.sla != nil || scores.slsaEffective != nil
        let hasHeure = heureReveil != nil
        return hasScore && hasHeure
    }
}

// MARK: - Extraction direction cardinale

/// Cherche une direction cardinale (N / NNE / NE / ENE / E / ESE / SE / SSE / S / SSO / SO / OSO / O / ONO / NO / NNO)
/// dans le label + detail d'un event Rose des Vents. Retourne la première trouvée,
/// ou nil si aucune.
///
/// Les directions multi-caractères (NNE, NNO, etc.) sont testées AVANT les simples
/// pour éviter un faux positif sur "N" dans "NNE".
fileprivate func extractCardinalDirection(from event: SessionEvent) -> String? {
    let haystack = [event.label, event.detail ?? ""].joined(separator: " ")
    // Ordre : plus long d'abord.
    let candidates = [
        "NNE", "NNO", "ENE", "ESE", "SSE", "SSO", "OSO", "ONO",
        "NE", "NO", "SE", "SO",
        "N", "E", "S", "O"
    ]
    for dir in candidates {
        let pattern = "\\b\(dir)\\b"
        if haystack.range(of: pattern, options: .regularExpression) != nil {
            return dir
        }
    }
    return nil
}
