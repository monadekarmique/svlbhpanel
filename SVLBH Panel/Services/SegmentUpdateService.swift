// SVLBHPanel — Services/SegmentUpdateService.swift
// v1.0.0 — PUSH segment update vers Make → svlbh-v2 data store
// Déclenché depuis la Planche Tactique (assignProgramme / drag-drop)

import Foundation

// MARK: - Segment CRM (mapping depuis PractitionerTier)

enum SVLBHSegment: String, CaseIterable, Sendable {
    case lead = "lead"
    case patientActif = "patient_actif"
    case prospect = "prospect"
    case praticien = "praticien"
    case alumni = "alumni"

    var displayName: String {
        switch self {
        case .lead:        return "Lead"
        case .patientActif: return "Patient actif"
        case .prospect:    return "Prospect"
        case .praticien:   return "Praticien"
        case .alumni:      return "Alumni"
        }
    }

    /// Mapping PractitionerTier → SVLBHSegment
    static func from(tier: PractitionerTier) -> SVLBHSegment {
        switch tier {
        case .lead:        return .lead
        case .formation:   return .prospect
        case .certifiee:   return .praticien
        case .superviseur: return .praticien
        }
    }
}

// MARK: - Service

class SegmentUpdateService: ObservableObject {

    /// Singleton pour accès global (état connectivité)
    static let shared = SegmentUpdateService()

    /// Webhook Make — SEGMENT UPDATE scenario #8944575
    static let webhookURL = URL(string: "https://hook.eu2.make.com/jl32rcoregoc34xeekj3cldngj9rkhh9")!

    /// Webhook Make — WhatsApp auto-reply router
    static let whatsappRouterURL = URL(string: "https://hook.eu2.make.com/lllo1g6btuv4e3qjt4qvpj8fjwyd663s")!

    /// true si le dernier check webhook a réussi
    @Published var isWhatsAppConnected = false

    /// Vérifie si le webhook WhatsApp router est actif (HEAD request)
    func checkWhatsAppConnectivity() async {
        do {
            var req = URLRequest(url: Self.whatsappRouterURL)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.timeoutInterval = 5
            req.httpBody = try JSONSerialization.data(withJSONObject: ["ping": true])

            let (_, response) = try await URLSession.shared.data(for: req)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let ok = (200...299).contains(status)
            await MainActor.run { isWhatsAppConnected = ok }
            print("[WhatsApp] Connectivity check: \(ok ? "OK" : "FAIL") (HTTP \(status))")
        } catch {
            await MainActor.run { isWhatsAppConnected = false }
            print("[WhatsApp] Connectivity check: FAIL (\(error.localizedDescription))")
        }
    }

    /// Envoie le segment d'un ShamaneProfile vers Make → svlbh-v2
    /// Clé contact : CT-{telephone} (convention data store)
    @discardableResult
    static func pushSegment(for profile: ShamaneProfile, autoReply: Bool = false) async -> Bool {
        // Construire la clé contact : CT-{téléphone nettoyé} ou CT-{code} si pas de téléphone
        let phone = profile.whatsapp.isEmpty ? profile.code : cleanPhone(profile.whatsapp)
        let contactKey = "CT-\(phone)"
        let segment = SVLBHSegment.from(tier: profile.tier)

        let body: [String: Any] = [
            "session_id": contactKey,
            "segment": segment.rawValue,
            "auto_reply": autoReply,
            "prenom": profile.prenom,
            "nom": profile.nom,
            "email": profile.email,
            "telephone": profile.whatsapp
        ]

        do {
            var req = URLRequest(url: webhookURL)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.timeoutInterval = 10
            req.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (_, response) = try await URLSession.shared.data(for: req)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let ok = (200...299).contains(status)
            print("[SegmentUpdate] \(contactKey) → \(segment.rawValue) → HTTP \(status)")
            return ok
        } catch {
            print("[SegmentUpdate] FAILED \(contactKey): \(error.localizedDescription)")
            return false
        }
    }

    /// Batch push pour plusieurs profils (Planche Tactique)
    static func pushBatch(_ profiles: [ShamaneProfile], autoReply: Bool = false) async -> (success: Int, fail: Int) {
        var ok = 0, fail = 0
        await withTaskGroup(of: Bool.self) { group in
            for profile in profiles {
                group.addTask {
                    await pushSegment(for: profile, autoReply: autoReply)
                }
            }
            for await result in group {
                if result { ok += 1 } else { fail += 1 }
            }
        }
        print("[SegmentUpdate] Batch: \(ok) ok, \(fail) fail")
        return (ok, fail)
    }

    // MARK: - Helpers

    /// Nettoie un numéro de téléphone (garde chiffres + préfixe +)
    private static func cleanPhone(_ raw: String) -> String {
        let digits = raw.filter { $0.isNumber || $0 == "+" }
        // Retirer le + initial pour la clé CT
        return digits.hasPrefix("+") ? String(digits.dropFirst()) : digits
    }
}
