// SVLBHPanel — Services/BuildGateService.swift
// Force update — bloque l'app si le build n'est pas dans les 5 derniers

import Foundation

actor BuildGateService {
    static let shared = BuildGateService()

    /// Webhook Make retournant {"latestBuild": N}
    private static let checkURL = URL(string: "https://hook.eu2.make.com/3hwa9zqb8gxgyrwxb1ljmaoxkfjko6di")!

    /// Nombre de builds tolérés en retard
    private static let tolerance = 4

    struct BuildStatus {
        let currentBuild: Int
        let latestBuild: Int
        var isAllowed: Bool { currentBuild >= latestBuild - BuildGateService.tolerance }
    }

    func check() async -> BuildStatus {
        let current = currentBuildNumber()

        do {
            var url = Self.checkURL
            url.append(queryItems: [URLQueryItem(name: "currentBuild", value: "\(current)")])
            var req = URLRequest(url: url)
            req.timeoutInterval = 10
            let (data, _) = try await URLSession.shared.data(for: req)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let latest = json["latestBuild"] as? Int {
                return BuildStatus(currentBuild: current, latestBuild: latest)
            }
        } catch {
            // En cas d'erreur réseau, on laisse passer
        }

        return BuildStatus(currentBuild: current, latestBuild: current)
    }

    private func currentBuildNumber() -> Int {
        let buildStr = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return Int(buildStr) ?? 0
    }
}
