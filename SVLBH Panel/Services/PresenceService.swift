// SVLBHPanel — Services/PresenceService.swift
// v4.8.0 — Présence leads via Make.com datastore

import Foundation

struct PresenceStatus: Decodable {
    let activeCount: Int
    let maxAllowed: Int
    let maxReached: Bool
}

final class PresenceService {
    static let shared = PresenceService()

    private static let registerURL = URL(string: "https://hook.eu2.make.com/nhfc4x35fithec3d7ywbwce1upy79oo0")!
    private static let disconnectURL = URL(string: "https://hook.eu2.make.com/s8k1h98g7dsgbjbhomurg7bhi76uofgy")!
    private static let checkURL = URL(string: "https://hook.eu2.make.com/m4m54erw01fwqk5jpyjov1ak32ekoi68")!

    private static let leadIdKey = "svlbh_lead_id"

    private init() {}

    // MARK: - Lead ID (persisté localement)

    var leadId: String {
        if let existing = UserDefaults.standard.string(forKey: Self.leadIdKey) {
            return existing
        }
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: Self.leadIdKey)
        return new
    }

    func clearLeadId() {
        UserDefaults.standard.removeObject(forKey: Self.leadIdKey)
    }

    // MARK: - Register

    func register(leadId: String, tier: String) async {
        let body: [String: String] = ["lead_id": leadId, "tier": tier]
        do {
            var req = URLRequest(url: Self.registerURL)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            req.timeoutInterval = 10
            let (_, response) = try await URLSession.shared.data(for: req)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("[Presence] register \(leadId) → \(status)")
        } catch {
            print("[Presence] register failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Disconnect

    func disconnect(leadId: String) async {
        let body: [String: String] = ["lead_id": leadId]
        do {
            var req = URLRequest(url: Self.disconnectURL)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            req.timeoutInterval = 10
            let (_, response) = try await URLSession.shared.data(for: req)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("[Presence] disconnect \(leadId) → \(status)")
        } catch {
            print("[Presence] disconnect failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Check

    func check() async -> PresenceStatus {
        do {
            var req = URLRequest(url: Self.checkURL)
            req.httpMethod = "GET"
            req.timeoutInterval = 8
            let (data, response) = try await URLSession.shared.data(for: req)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard status == 200 else {
                print("[Presence] check → \(status)")
                return PresenceStatus(activeCount: 0, maxAllowed: 5, maxReached: false)
            }
            let result = try JSONDecoder().decode(PresenceStatus.self, from: data)
            print("[Presence] check → active:\(result.activeCount)/\(result.maxAllowed) maxReached:\(result.maxReached)")
            return result
        } catch {
            print("[Presence] check failed: \(error.localizedDescription)")
            return PresenceStatus(activeCount: 0, maxAllowed: 5, maxReached: false)
        }
    }
}
