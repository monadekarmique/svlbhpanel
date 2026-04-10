// SVLBHPanel — Services/AnthropicClient.swift
// Phase 0 Managed Agents — wrapper HTTP générique pour appeler les agents
// managés depuis l'iPad.
//
// ⚠️  SCHÉMA API NON VALIDÉ. Les endpoints `/v1/sessions`, le format de
// message input/output et les headers exacts pour Managed Agents sont
// basés sur les notes CLAUDE.md + ce qui est annoncé publiquement au
// 8/04/2026. Si un appel retourne 4xx inattendu, lire le body d'erreur
// et ajuster `SessionRequestBody` / `SessionResponse`.

import Foundation

enum AnthropicError: LocalizedError {
    case notConfigured
    case invalidURL
    case httpError(status: Int, body: String)
    case decoding(String)
    case noContent

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "AnthropicConfig manquant : vérifier Config.xcconfig / secrets.xcconfig."
        case .invalidURL:
            return "URL Anthropic invalide."
        case .httpError(let s, let b):
            return "Anthropic HTTP \(s): \(b)"
        case .decoding(let m):
            return "Décodage réponse Anthropic : \(m)"
        case .noContent:
            return "Réponse Anthropic vide."
        }
    }
}

// MARK: - Payloads

/// Corps envoyé à `POST /v1/sessions` pour démarrer une session agent.
/// Le format exact n'est pas figé au moment de l'écriture — voir note en tête.
struct SessionRequestBody: Encodable {
    let agentId: String
    let messages: [Message]

    struct Message: Encodable {
        let role: String   // "user"
        let content: String
    }

    enum CodingKeys: String, CodingKey {
        case agentId = "agent_id"
        case messages
    }
}

/// Réponse simplifiée — on extrait seulement le contenu texte final.
struct SessionResponse: Decodable {
    let id: String
    let content: [ContentBlock]

    struct ContentBlock: Decodable {
        let type: String
        let text: String?
    }

    /// Concatène tous les blocs texte en un seul string.
    var textOutput: String {
        content.compactMap { $0.type == "text" ? $0.text : nil }.joined(separator: "\n")
    }
}

// MARK: - Client

final class AnthropicClient: ObservableObject {

    @Published var isCalling: Bool = false
    @Published var lastError: String?

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Public API

    /// Démarre une session managée et envoie un message utilisateur initial.
    /// Retourne le texte final produit par l'agent.
    func runAgent(agentId: String, userMessage: String) async throws -> SessionResponse {
        guard AnthropicConfig.isConfigured, let apiKey = AnthropicConfig.apiKey else {
            throw AnthropicError.notConfigured
        }

        let body = SessionRequestBody(
            agentId: agentId,
            messages: [.init(role: "user", content: userMessage)]
        )
        let req = try makeRequest(
            method: "POST",
            path: "/v1/sessions",
            body: body,
            apiKey: apiKey
        )

        await MainActor.run { self.isCalling = true; self.lastError = nil }
        defer { Task { @MainActor in self.isCalling = false } }

        let (data, response) = try await session.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200...299).contains(status) else {
            let bodyText = String(data: data, encoding: .utf8) ?? ""
            await MainActor.run { self.lastError = "HTTP \(status)" }
            throw AnthropicError.httpError(status: status, body: bodyText)
        }

        do {
            return try JSONDecoder().decode(SessionResponse.self, from: data)
        } catch {
            let bodyText = String(data: data, encoding: .utf8) ?? ""
            throw AnthropicError.decoding("\(error) — body: \(bodyText.prefix(300))")
        }
    }

    /// Ferme explicitement une session pour arrêter la facturation session-heure.
    /// À appeler dès que le flux iOS qui a initié la session est terminé.
    func closeSession(sessionId: String) async {
        guard AnthropicConfig.isConfigured, let apiKey = AnthropicConfig.apiKey else { return }
        guard let req = try? makeRequest(
            method: "DELETE",
            path: "/v1/sessions/\(sessionId)",
            body: Optional<SessionRequestBody>.none,
            apiKey: apiKey
        ) else { return }
        _ = try? await session.data(for: req)
    }

    // MARK: - Request builder

    private func makeRequest<T: Encodable>(
        method: String,
        path: String,
        body: T?,
        apiKey: String
    ) throws -> URLRequest {
        guard let url = URL(string: path, relativeTo: AnthropicConfig.baseURL) else {
            throw AnthropicError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        req.setValue(AnthropicConfig.apiVersion, forHTTPHeaderField: "anthropic-version")
        req.setValue(AnthropicConfig.managedAgentsBeta, forHTTPHeaderField: "anthropic-beta")
        req.timeoutInterval = 60
        if let body {
            req.httpBody = try JSONEncoder().encode(body)
        }
        return req
    }
}
