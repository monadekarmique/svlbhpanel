// SVLBHPanel — Services/SubscriptionService.swift
// v4.8.0 — Vérification abonnement CHF 29/mois via Make.com datastore

import Foundation

struct SubscriptionStatus: Codable {
    let code: String
    let status: String         // "active", "expired", "trial"
    let paidUntil: String      // "2026-04-25"
    let trialDaysLeft: Int?

    var isActive: Bool { status == "active" || status == "trial" }

    var paidUntilDate: Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: paidUntil)
    }

    var daysLeft: Int {
        guard let date = paidUntilDate else { return 0 }
        return max(0, Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0)
    }
}

final class SubscriptionService {
    static let shared = SubscriptionService()

    private static let checkURL = URL(string: "https://hook.eu2.make.com/svlbh-subscription-check")!

    private static let cacheKey = "svlbh_subscription_cache"
    private static let cacheTimestampKey = "svlbh_subscription_cache_ts"
    private static let cacheDuration: TimeInterval = 3600 // 1h

    private init() {}

    /// Vérifie l'abonnement — cache 1h pour éviter les appels réseau excessifs
    func check(code: String) async -> SubscriptionStatus {
        // Vérifier le cache
        if let cached = loadCache(), cached.code == code {
            return cached
        }

        // Appel Make.com
        let body: [String: String] = ["code": code]
        do {
            var req = URLRequest(url: Self.checkURL)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            req.timeoutInterval = 10
            let (data, response) = try await URLSession.shared.data(for: req)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0

            if status == 200 {
                let result = try JSONDecoder().decode(SubscriptionStatus.self, from: data)
                saveCache(result)
                print("[Subscription] check \(code) → \(result.status), until \(result.paidUntil)")
                return result
            }
        } catch {
            print("[Subscription] check failed: \(error.localizedDescription)")
        }

        // Fallback : si réseau down, accorder un accès gracieux de 7 jours depuis le dernier cache
        if let cached = loadCache() { return cached }

        // Aucun cache, aucun réseau → trial par défaut
        return SubscriptionStatus(code: code, status: "trial",
                                  paidUntil: fallbackTrialDate(), trialDaysLeft: 7)
    }

    // MARK: - Cache

    private func saveCache(_ status: SubscriptionStatus) {
        if let data = try? JSONEncoder().encode(status) {
            UserDefaults.standard.set(data, forKey: Self.cacheKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Self.cacheTimestampKey)
        }
    }

    private func loadCache() -> SubscriptionStatus? {
        let ts = UserDefaults.standard.double(forKey: Self.cacheTimestampKey)
        guard ts > 0, Date().timeIntervalSince1970 - ts < Self.cacheDuration else { return nil }
        guard let data = UserDefaults.standard.data(forKey: Self.cacheKey) else { return nil }
        return try? JSONDecoder().decode(SubscriptionStatus.self, from: data)
    }

    func clearCache() {
        UserDefaults.standard.removeObject(forKey: Self.cacheKey)
        UserDefaults.standard.removeObject(forKey: Self.cacheTimestampKey)
    }

    private func fallbackTrialDate() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Calendar.current.date(byAdding: .day, value: 7, to: Date())!)
    }
}
