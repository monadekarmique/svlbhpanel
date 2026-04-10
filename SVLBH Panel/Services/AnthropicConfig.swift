// SVLBHPanel — Services/AnthropicConfig.swift
// Phase 0 Managed Agents — configuration statique + lookup clé API.
//
// La clé API est lue depuis Info.plist via Config.xcconfig (non versionné).
// Voir secrets.xcconfig.example pour le format attendu.

import Foundation

enum AnthropicConfig {

    // MARK: - API

    static let baseURL = URL(string: "https://api.anthropic.com")!
    static let apiVersion = "2023-06-01"
    static let managedAgentsBeta = "managed-agents-2026-04-01"

    // MARK: - Agent IDs
    //
    // Les IDs Anthropic sont produits par `Scripts/sync_agents.swift` et
    // stockés dans `agents/.lockfile.json`. Ils sont injectés dans le bundle
    // iOS via Config.xcconfig (clés INFOPLIST_KEY_*) pour éviter qu'un dev
    // parse le lockfile au runtime.
    //
    // Si une de ces clés est absente d'Info.plist, l'accesseur renvoie nil
    // et le service appelant doit refuser de démarrer.

    static var hdomSessionAgentId: String? {
        bundleString("ANTHROPIC_AGENT_HDOM_SESSION")
    }

    static var passeportRatioAgentId: String? {
        bundleString("ANTHROPIC_AGENT_PASSEPORT_RATIO")
    }

    /// Note : `whatsapp-vlbh-agent` n'est pas appelé depuis l'iPad (il est
    /// invoqué par un scénario Make). Cet ID n'est donc jamais lu côté iOS.
    /// Exposé ici uniquement pour symétrie / debug.
    static var whatsappVlbhAgentId: String? {
        bundleString("ANTHROPIC_AGENT_WHATSAPP_VLBH")
    }

    // MARK: - API Key

    /// Clé API Anthropic lue depuis Info.plist.
    ///
    /// Format attendu dans Config.xcconfig :
    ///     INFOPLIST_KEY_ANTHROPIC_API_KEY = $(ANTHROPIC_API_KEY)
    ///
    /// Où `ANTHROPIC_API_KEY` est défini dans `secrets.xcconfig` (gitignore).
    ///
    /// ⚠️ Cette clé est présente en clair dans le bundle iOS installé sur
    /// l'iPad. Risque accepté explicitement pour une app interne mono-opérateur
    /// (Patrick). Rotation à envisager si le device est perdu / l'app
    /// distribuée au-delà du cabinet.
    static var apiKey: String? {
        bundleString("ANTHROPIC_API_KEY")
    }

    // MARK: - Helpers

    static var isConfigured: Bool {
        apiKey?.isEmpty == false
    }

    private static func bundleString(_ key: String) -> String? {
        let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String
        guard let raw, !raw.isEmpty, raw != "$(\(key))" else { return nil }
        return raw
    }
}
