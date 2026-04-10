// SVLBHPanel — Services/PasseportRatioAgentService.swift
// Phase 2 Managed Agents — orchestre l'appel à `passeport-ratio-agent`.
//
// Le calcul Ratio 4D reste local. Cet agent se concentre sur la
// rédaction du passeport markdown à partir des valeurs déjà calculées.

import Foundation
import Combine

@MainActor
final class PasseportRatioAgentService: ObservableObject {

    enum State: Equatable {
        case idle
        case loading
        case success(PasseportRatioResult)
        case error(String)
    }

    @Published private(set) var state: State = .idle

    var isPreparing: Bool {
        if case .loading = state { return true }
        return false
    }

    private let client: AnthropicClient

    init(client: AnthropicClient = AnthropicClient()) {
        self.client = client
    }

    // MARK: - Public API

    /// Lance la rédaction du passeport pour le ratio courant.
    ///
    /// `localCalcul` contient les valeurs déjà calculées par
    /// `Ratio4DDetailView` — on les passe telles quelles à l'agent
    /// pour qu'il ne refasse pas le calcul.
    func generatePasseport(
        session: SessionState,
        localCalcul: Ratio4DLocalCalcul
    ) async {
        self.state = .loading

        guard AnthropicConfig.isConfigured else {
            self.state = .error("Clé API Anthropic manquante — voir Config.xcconfig.")
            return
        }
        guard let agentId = AnthropicConfig.passeportRatioAgentId else {
            self.state = .error("ID agent passeport-ratio manquant — lancer Scripts/sync_agents.swift puis renseigner ANTHROPIC_AGENT_PASSEPORT_RATIO.")
            return
        }
        guard localCalcul.isReady else {
            self.state = .error("Calcul local incomplet : sélectionner un pays et saisir le SLTdA 4D avant de générer le passeport.")
            return
        }

        let input = PasseportRatioInput(
            patientId: session.patientId,
            sessionNum: session.sessionNum,
            pays: localCalcul.pays,
            anneeTrauma: localCalcul.anneeTrauma.isEmpty ? nil : localCalcul.anneeTrauma,
            sltda4D: localCalcul.sltda4D,
            baselineSlsaCh: localCalcul.baselineSlsaCh,
            baselineSltdaOrig: localCalcul.baselineSltdaOrig,
            baselineSltdaCh: localCalcul.baselineSltdaCh,
            ratio4D: localCalcul.ratio4D,
            cluster: localCalcul.cluster,
            scoresSession: PasseportRatioInput.ScoresSnapshot(
                sla: session.scoresTherapist.sla,
                slsa: session.scoresTherapist.slsaEffective
            ),
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            schemaVersion: 1
        )

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
        Rédige le passeport 4D pour la patiente suivante.

        Le calcul Ratio 4D, le cluster et les baselines 21S sont déjà fournis
        — n'effectue PAS de re-calcul, n'appelle PAS l'outil fetch_svlbh_ref_21s
        sauf si les valeurs du payload sont manifestement incohérentes.

        Payload JSON :
        ```json
        \(payloadJSON)
        ```

        Produis ta réponse en JSON strict avec les clés :
        - `passeport_markdown` : le passeport complet en markdown (prêt à partager)
        - `narrative` : interprétation clinique courte (1–2 paragraphes)
        - `recommendations` : liste de recommandations actionnables
        - `metadata` : métadonnées optionnelles (références utilisées, etc.)
        """

        do {
            let response = try await client.runAgent(agentId: agentId, userMessage: userMessage)
            let text = response.textOutput
            guard !text.isEmpty else {
                self.state = .error("Réponse agent vide.")
                return
            }
            do {
                let result = try PasseportRatioResult.parse(from: text)
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

    func reset() {
        state = .idle
    }
}

// MARK: - Snapshot du calcul local

/// Valeurs produites par Ratio4DDetailView (calcul local) et passées
/// au service pour éviter que l'agent ne refasse le calcul.
struct Ratio4DLocalCalcul: Equatable {
    let pays: String
    let anneeTrauma: String
    let sltda4D: Double?
    let baselineSlsaCh: Int
    let baselineSltdaOrig: Int
    let baselineSltdaCh: Int
    let ratio4D: Double?
    let cluster: String

    /// Minimum requis pour lancer la génération : pays + sltda4D + ratio.
    var isReady: Bool {
        !pays.isEmpty && sltda4D != nil && ratio4D != nil
    }
}
