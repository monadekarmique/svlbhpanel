#!/usr/bin/env swift
// Scripts/sync_agents.swift
//
// Synchronise les définitions locales `agents/*.json` avec les Managed Agents
// côté Anthropic. Met à jour `agents/.lockfile.json` avec l'ID et le hash.
//
// Usage:
//   export ANTHROPIC_API_KEY=sk-ant-...
//   swift Scripts/sync_agents.swift            # sync tous les agents
//   swift Scripts/sync_agents.swift hdom-session-agent   # sync un seul
//   swift Scripts/sync_agents.swift --dry-run   # simulation
//
// Dépendances : Foundation uniquement. Pas de SPM.
//
// ⚠️  ATTENTION : le schéma exact du payload `/v1/agents` d'Anthropic n'est pas
// figé dans ce script au moment de l'écriture (cutoff du rédacteur: mai 2025,
// feature releasée le 8/04/2026). Le mapping `agentJSONToAPIPayload()`
// ci-dessous est une HYPOTHÈSE RAISONNABLE à valider contre la doc officielle
// avant le premier run en production. En cas de 4xx, lire le body d'erreur
// et ajuster `agentJSONToAPIPayload()`.

import Foundation
#if canImport(CommonCrypto)
import CommonCrypto
#endif

// MARK: - Constants

let anthropicBaseURL = "https://api.anthropic.com"
let anthropicVersion = "2023-06-01"
let anthropicBeta = "managed-agents-2026-04-01"

let repoRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()   // Scripts/
    .deletingLastPathComponent()   // repo root
let agentsDir = repoRoot.appendingPathComponent("agents")
let lockfileURL = agentsDir.appendingPathComponent(".lockfile.json")

// MARK: - Models

struct AgentDefinition: Codable {
    let slug: String
    let name: String
    let description: String
    let model: String
    let systemPrompt: String
    let skills: [String]
    let tools: [AnyCodable]
    let mcpServers: [AnyCodable]
    let betaHeader: String
    let caller: String
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case slug, name, description, model
        case systemPrompt = "system_prompt"
        case skills, tools
        case mcpServers = "mcp_servers"
        case betaHeader = "beta_header"
        case caller, notes
    }
}

struct LockfileEntry: Codable {
    var id: String
    var lastSync: String
    var contentHash: String

    enum CodingKeys: String, CodingKey {
        case id
        case lastSync = "last_sync"
        case contentHash = "content_hash"
    }
}

struct Lockfile: Codable {
    let version: Int
    var agents: [String: LockfileEntry]
}

/// Codable wrapper pour JSON hétérogènes (tools, mcp_servers).
struct AnyCodable: Codable {
    let value: Any

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { value = NSNull(); return }
        if let b = try? c.decode(Bool.self) { value = b; return }
        if let i = try? c.decode(Int.self) { value = i; return }
        if let d = try? c.decode(Double.self) { value = d; return }
        if let s = try? c.decode(String.self) { value = s; return }
        if let a = try? c.decode([AnyCodable].self) { value = a.map(\.value); return }
        if let o = try? c.decode([String: AnyCodable].self) { value = o.mapValues(\.value); return }
        throw DecodingError.dataCorruptedError(
            in: c, debugDescription: "AnyCodable: unsupported type"
        )
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch value {
        case is NSNull: try c.encodeNil()
        case let b as Bool: try c.encode(b)
        case let i as Int: try c.encode(i)
        case let d as Double: try c.encode(d)
        case let s as String: try c.encode(s)
        case let a as [Any]: try c.encode(a.map { AnyCodable(boxing: $0) })
        case let o as [String: Any]: try c.encode(o.mapValues { AnyCodable(boxing: $0) })
        default:
            throw EncodingError.invalidValue(
                value,
                .init(codingPath: c.codingPath, debugDescription: "AnyCodable: unsupported type")
            )
        }
    }

    private init(boxing v: Any) { self.value = v }
}

// MARK: - Hash

func sha256Hex(_ data: Data) -> String {
    // Implémentation SHA-256 Foundation-only via CommonCrypto.
    // Évite d'ajouter CryptoKit pour rester Foundation-pur et permettre
    // un exec via `swift Scripts/sync_agents.swift` sans package manifest.
    var hash = [UInt8](repeating: 0, count: 32)
    data.withUnsafeBytes { buf in
        _ = CC_SHA256(buf.baseAddress, CC_LONG(data.count), &hash)
    }
    return hash.map { String(format: "%02x", $0) }.joined()
}

// MARK: - IO helpers

func loadAgentDefinitions() throws -> [(url: URL, def: AgentDefinition, rawData: Data)] {
    let fm = FileManager.default
    let contents = try fm.contentsOfDirectory(at: agentsDir, includingPropertiesForKeys: nil)
    let jsonFiles = contents.filter {
        $0.pathExtension == "json" && $0.lastPathComponent != ".lockfile.json"
    }
    let decoder = JSONDecoder()
    return try jsonFiles.map { url in
        let data = try Data(contentsOf: url)
        let def = try decoder.decode(AgentDefinition.self, from: data)
        return (url, def, data)
    }
}

func loadLockfile() throws -> Lockfile {
    guard FileManager.default.fileExists(atPath: lockfileURL.path) else {
        return Lockfile(version: 1, agents: [:])
    }
    let data = try Data(contentsOf: lockfileURL)
    return try JSONDecoder().decode(Lockfile.self, from: data)
}

func saveLockfile(_ lockfile: Lockfile) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    let data = try encoder.encode(lockfile)
    try data.write(to: lockfileURL, options: .atomic)
}

// MARK: - Anthropic API

enum SyncError: Error, CustomStringConvertible {
    case missingAPIKey
    case tbdUrlInTool(slug: String, toolName: String)
    case apiError(status: Int, body: String)
    case unexpectedResponse(String)

    var description: String {
        switch self {
        case .missingAPIKey:
            return "ANTHROPIC_API_KEY non défini dans l'environnement."
        case .tbdUrlInTool(let slug, let name):
            return "Agent \(slug) a un tool `\(name)` avec URL TBD — à renseigner avant sync."
        case .apiError(let status, let body):
            return "Anthropic API error HTTP \(status): \(body)"
        case .unexpectedResponse(let msg):
            return "Réponse Anthropic inattendue: \(msg)"
        }
    }
}

func apiKey() throws -> String {
    guard let key = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"], !key.isEmpty else {
        throw SyncError.missingAPIKey
    }
    return key
}

/// Hypothèse de mapping local → payload API Anthropic Managed Agents.
/// ⚠️ À valider contre la doc officielle. Voir note en tête de fichier.
func agentJSONToAPIPayload(_ def: AgentDefinition) -> [String: Any] {
    var body: [String: Any] = [
        "name": def.name,
        "description": def.description,
        "model": def.model,
        "system_prompt": def.systemPrompt,
    ]
    if !def.skills.isEmpty {
        body["skills"] = def.skills
    }
    if !def.tools.isEmpty {
        body["tools"] = def.tools.map(\.value)
    }
    if !def.mcpServers.isEmpty {
        body["mcp_servers"] = def.mcpServers.map(\.value)
    }
    return body
}

/// Vérifie qu'aucun tool n'a une URL TBD_* (safeguard).
func validateTools(_ def: AgentDefinition) throws {
    for tool in def.tools {
        guard let dict = tool.value as? [String: Any] else { continue }
        if let url = dict["url"] as? String, url.hasPrefix("TBD_") {
            let name = (dict["name"] as? String) ?? "<anonymous>"
            throw SyncError.tbdUrlInTool(slug: def.slug, toolName: name)
        }
    }
}

func makeRequest(method: String, path: String, body: Data?) throws -> URLRequest {
    let url = URL(string: "\(anthropicBaseURL)\(path)")!
    var req = URLRequest(url: url)
    req.httpMethod = method
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.setValue(try apiKey(), forHTTPHeaderField: "x-api-key")
    req.setValue(anthropicVersion, forHTTPHeaderField: "anthropic-version")
    req.setValue(anthropicBeta, forHTTPHeaderField: "anthropic-beta")
    req.httpBody = body
    req.timeoutInterval = 30
    return req
}

func syncHTTP(_ req: URLRequest) throws -> (Int, Data) {
    let sem = DispatchSemaphore(value: 0)
    var result: (Int, Data)?
    var error: Error?
    URLSession.shared.dataTask(with: req) { data, resp, err in
        if let err = err { error = err }
        else {
            let status = (resp as? HTTPURLResponse)?.statusCode ?? 0
            result = (status, data ?? Data())
        }
        sem.signal()
    }.resume()
    sem.wait()
    if let error = error { throw error }
    return result!
}

func createAgent(_ def: AgentDefinition) throws -> String {
    let payload = agentJSONToAPIPayload(def)
    let body = try JSONSerialization.data(withJSONObject: payload)
    let req = try makeRequest(method: "POST", path: "/v1/agents", body: body)
    let (status, data) = try syncHTTP(req)
    guard (200...299).contains(status) else {
        throw SyncError.apiError(status: status, body: String(data: data, encoding: .utf8) ?? "")
    }
    guard
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
        let id = json["id"] as? String
    else {
        throw SyncError.unexpectedResponse(String(data: data, encoding: .utf8) ?? "")
    }
    return id
}

func patchAgent(id: String, def: AgentDefinition) throws {
    let payload = agentJSONToAPIPayload(def)
    let body = try JSONSerialization.data(withJSONObject: payload)
    let req = try makeRequest(method: "PATCH", path: "/v1/agents/\(id)", body: body)
    let (status, data) = try syncHTTP(req)
    guard (200...299).contains(status) else {
        throw SyncError.apiError(status: status, body: String(data: data, encoding: .utf8) ?? "")
    }
}

// MARK: - Main

func main() {
    let args = CommandLine.arguments.dropFirst()
    let dryRun = args.contains("--dry-run")
    let only = args.first { !$0.hasPrefix("--") }

    do {
        let definitions = try loadAgentDefinitions()
        var lockfile = try loadLockfile()

        let iso = ISO8601DateFormatter()

        for (_, def, raw) in definitions {
            if let only = only, def.slug != only { continue }

            print("→ \(def.slug)")

            do {
                try validateTools(def)
            } catch {
                print("  ❌ \(error)")
                continue
            }

            let hash = sha256Hex(raw)
            let existing = lockfile.agents[def.slug]

            if let existing = existing, existing.contentHash == hash {
                print("  ✓ up-to-date (hash \(hash.prefix(12))...)")
                continue
            }

            if dryRun {
                if existing == nil {
                    print("  [dry-run] would CREATE agent")
                } else {
                    print("  [dry-run] would PATCH agent \(existing!.id)")
                }
                continue
            }

            if let existing = existing {
                try patchAgent(id: existing.id, def: def)
                lockfile.agents[def.slug] = LockfileEntry(
                    id: existing.id,
                    lastSync: iso.string(from: Date()),
                    contentHash: hash
                )
                print("  ✓ PATCHED \(existing.id)")
            } else {
                let id = try createAgent(def)
                lockfile.agents[def.slug] = LockfileEntry(
                    id: id,
                    lastSync: iso.string(from: Date()),
                    contentHash: hash
                )
                print("  ✓ CREATED \(id)")
            }
        }

        if !dryRun {
            try saveLockfile(lockfile)
            print("\nLockfile mis à jour : \(lockfileURL.path)")
        } else {
            print("\n[dry-run] lockfile NON modifié")
        }
    } catch {
        print("❌ \(error)")
        exit(1)
    }
}

main()
