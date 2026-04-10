// SVLBHPanel — Models/SessionState+HDOM.swift
// Phase 1 Managed Agents — conversion SessionState → HDOMAgentInput.
//
// Note : la méthode prend `tracker` en paramètre car les événements
// Rose des Vents vivent dans `SessionTracker`, pas dans `SessionState`.

import Foundation

extension SessionState {

    /// Construit le payload envoyé à `hdom-session-agent`.
    /// Utilise les scores du thérapeute (`scoresTherapist`) par défaut.
    func toHDOMAgentInput(tracker: SessionTracker) -> HDOMAgentInput {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let hmFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "HH:mm"
            f.locale = Locale(identifier: "fr_FR")
            return f
        }()

        let scores = scoresTherapist

        let heureReveilISO = heureReveil.map { iso.string(from: $0) }
        let heureReveilLocal = heureReveil.map { hmFormatter.string(from: $0) }

        let rose = tracker.roseDesVentsEvents.map { event in
            HDOMAgentInput.RoseEvent(
                timestamp: iso.string(from: event.timestamp),
                timeLocal: hmFormatter.string(from: event.timestamp),
                label: event.label,
                detail: event.detail,
                niveau: event.niveau
            )
        }

        return HDOMAgentInput(
            patientId: patientId,
            sessionNum: sessionNum,
            sessionProgramCode: sessionProgramCode,
            sla: scores.sla,
            slsa: scores.slsaEffective,
            slsaS1: scores.slsaS1,
            slsaS2: scores.slsaS2,
            slsaS3: scores.slsaS3,
            slsaS4: scores.slsaS4,
            slsaS5: scores.slsaS5,
            heureReveil: heureReveilISO,
            heureReveilLocal: heureReveilLocal,
            roseDesVents: rose,
            generatedAt: iso.string(from: Date()),
            schemaVersion: 1
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
