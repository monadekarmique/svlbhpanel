// SVLBHPanel — Services/HDOMSessionAgentService.swift
// Phase 1 Managed Agents — orchestre l'appel à `hdom-session-agent`.
//
// Responsabilités :
//   1. Sérialiser le SessionState + SessionTracker en HDOMAgentInput (JSON)
//   2. Appeler AnthropicClient.runAgent avec l'ID d'agent hdom-session
//   3. Parser la réponse texte en HDOMPreparationResult (JSON strict)
//   4. Publier l'état (idle / loading / success / error) pour la sheet SwiftUI

import Foundation
import Combine

@MainActor
final class HDOMSessionAgentService: ObservableObject {

    enum State: Equatable {
        case idle
        case loading
        case success(HDOMPreparationResult)
        case error(String)
    }

    @Published private(set) var state: State = .idle

    /// True tant qu'une préparation est en cours (pour désactiver le bouton UI).
    var isPreparing: Bool {
        if case .loading = state { return true }
        return false
    }

    private let client: AnthropicClient

    init(client: AnthropicClient = AnthropicClient()) {
        self.client = client
    }

    // MARK: - Public API

    /// Lance la préparation de séance.
    /// Publie `loading` → `success(result)` ou `error(message)`.
    func prepareSession(session: SessionState, tracker: SessionTracker) async {
        self.state = .loading

        // 1. Guard config
        guard AnthropicConfig.isConfigured else {
            self.state = .error("Clé API Anthropic manquante — voir Config.xcconfig.")
            return
        }
        guard let agentId = AnthropicConfig.hdomSessionAgentId else {
            self.state = .error("ID agent hdom-session manquant — lancer Scripts/sync_agents.swift puis renseigner ANTHROPIC_AGENT_HDOM_SESSION.")
            return
        }

        // 2. Guard payload complet
        guard session.isHDOMPayloadReady() else {
            self.state = .error("Payload incomplet : renseigner SLA ou SLSA et l'heure de réveil avant de préparer la séance.")
            return
        }

        // 3. Construire le payload JSON
        let input = session.toHDOMAgentInput(tracker: tracker)
        let payloadJSON: String
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
            let data = try encoder.encode(input)
            payloadJSON = String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            self.state = .error("Sérialisation du payload échouée : \(error.localizedDescription)")
            return
        }

        let userMessage = """
        Prépare la séance pour la patiente suivante.

        Payload JSON :
        ```json
        \(payloadJSON)
        ```

        Produis ta réponse en JSON strict avec les clés `decodage`, `protocole`, `chromotherapie`, `metadata`.
        """

        // 4. Appel agent
        do {
            let response = try await client.runAgent(agentId: agentId, userMessage: userMessage)
            let text = response.textOutput
            guard !text.isEmpty else {
                self.state = .error("Réponse agent vide.")
                return
            }
            do {
                let result = try HDOMPreparationResult.parse(from: text)
                self.state = .success(result)
            } catch {
                self.state = .error("Parse JSON échoué : \(error.localizedDescription)")
            }
        } catch let err as AnthropicError {
            self.state = .error(err.errorDescription ?? "Erreur Anthropic inconnue.")
        } catch {
            self.state = .error("Erreur : \(error.localizedDescription)")
        }
    }

    /// Reset l'état (appelé à la fermeture de la sheet).
    func reset() {
        state = .idle
    }
}
