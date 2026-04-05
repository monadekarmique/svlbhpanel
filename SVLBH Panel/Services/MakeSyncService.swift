// SVLBHPanel — Services/MakeSyncService.swift
// v4.0.4 — debounce queue-drain post-update + guard pullKey vide + max() patientId

import Foundation
import UserNotifications
import UIKit

class MakeSyncService: ObservableObject {
    static let pushURL = URL(string: "https://hook.eu2.make.com/1xhfk4o1l5pu4h23m0x26zql6oe8c3ns")!
    static let pullURL = URL(string: "https://hook.eu2.make.com/n00qt5bxbemy49l3woix0xaopltg8sas")!

    // Anti queue-drain : timestamp du dernier pull accepté
    private var lastPullTimestamp: Date = .distantPast
    private static let minPullIntervalSeconds: TimeInterval = 3.0

    @Published var isSending = false
    @Published var isReceiving = false
    @Published var isScanning = false
    @Published var lastError: String?
    @Published var lastPin: String?
    /// Historique PINs par shamane (code shamane → [(pin, date)])
    @Published var pinsByShamane: [String: [(pin: String, date: Date)]] = [:]
    @Published var pushSuccess: Bool = false
    @Published var diffLog: [String] = []
    @Published var diffs: TabDiffs = TabDiffs()
    @Published var pendingSources: [ShamaneProfile] = []

    struct TabDiffs {
        var decode: Int = 0
        var pierres: Int = 0
        var chakras: Int = 0
        var total: Int { decode + pierres + chakras }
    }

    // MARK: - Delete READ key before relay (permet de refaire un cycle)
    /// Écrase une clé READ avec payload vide pour la rendre invisible au PULL suivant
    func deleteReadKey(_ key: String) async {
        let body: [String: String] = ["session_id": key, "payload": ""]
        guard !key.isEmpty, !key.contains("--") else { return }
        do {
            var req = URLRequest(url: Self.pushURL)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            req.timeoutInterval = 8
            let (_, response) = try await URLSession.shared.data(for: req)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("[MakeSyncService] deleteReadKey \(key) → \(status)")
        } catch {
            print("[MakeSyncService] deleteReadKey failed: \(error.localizedDescription)")
        }
    }

    /// Efface toutes les clés READ connues pour un patient+session donnés (toutes praticiens)
    /// Puis remet sessionNum à la valeur correcte pour le prochain relay
    func prepareRelayRepeat(session: SessionState, profiles: [ShamaneProfile]) async {
        let sNum = session.sessionNum
        let pId  = session.patientId
        let prog = session.sessionProgramCode
        // Clé Patrick
        let keyPatrick = "\(prog)-\(pId)-\(sNum)-\(ActiveRole.patrickCode)"
        await deleteReadKey(keyPatrick)
        // Clés de chaque shamane
        for s in profiles {
            let key = "\(prog)-\(pId)-\(sNum)-\(s.codeFormatted)"
            await deleteReadKey(key)
        }
        print("[MakeSyncService] prepareRelayRepeat — clés nettoyées pour P\(pId) S\(sNum)")
    }

    // MARK: - PUSH
    func push(session: SessionState, forShamaneCode: String? = nil) async -> Bool {
        // Guard: patientId must be set before building any key
        guard session.isPatientIdValid else {
            print("[MakeSyncService] PUSH aborted: patientId '\(session.patientId)' invalid (min \(SessionState.minPatientId))")
            return false
        }

        await MainActor.run { isSending = true; lastError = nil }

        var pin = ""
        var payload = serializeSession(session)
        // PIN pour Patrick ou Patrick simulant une shamane
        if session.role.isPatrick || session.isPatrickSimulating {
            pin = String(format: "%04d", Int.random(in: 1000...9999))
            payload = "PIN:\(pin)\n" + payload
        }
        let cleanKey = session.pushKey
        print("[MakeSyncService] PUSH key='\(cleanKey)' role.code='\(session.role.code)' prog='\(session.sessionProgramCode)' patient='\(session.patientId)' session='\(session.sessionNum)' isPatrick=\(session.role.isPatrick)")
        let body: [String: String] = ["session_id": cleanKey, "payload": payload]
        do {
            var req = URLRequest(url: Self.pushURL)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (_, response) = try await URLSession.shared.data(for: req)
            let ok = (response as? HTTPURLResponse)?.statusCode == 200
            let finalPin = pin  // capture before MainActor hop
            let shamaneCode = forShamaneCode
            let now = Date()
            await MainActor.run {
                isSending = false
                if ok && !finalPin.isEmpty {
                    lastPin = finalPin
                    if let code = shamaneCode {
                        var history = pinsByShamane[code] ?? []
                        history.append((pin: finalPin, date: now))
                        pinsByShamane[code] = history
                    }
                }
                if ok { pushSuccess = true }
            }
            guard ok else { return false }

            // Record in session history
            let headerLine = payload.split(separator: "\n").first.map(String.init) ?? ""
            SessionHistory.record(
                key: cleanKey,
                programCode: session.sessionProgramCode,
                patientId: session.patientId,
                sessionNum: session.sessionNum,
                practitionerCode: session.role.code,
                headerLine: headerLine
            )

            // Auto-dismiss toast après 3s
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                pushSuccess = false
            }

            return true
        } catch {
            await MainActor.run { isSending = false; lastError = error.localizedDescription }
            return false
        }
    }

    // MARK: - Post-PUSH PULL (hookId 3982917)
    private func triggerPostPushPull(sessionId: String) async {
        // Guard: reject empty or malformed keys
        guard !sessionId.isEmpty, !sessionId.contains("--") else {
            await MainActor.run { lastError = "PULL aborted: invalid key \(sessionId)" }
            print("[MakeSyncService] PULL aborted: invalid key '\(sessionId)'")
            return
        }

        // Wait 2s for Make.com to finish writing the PUSH record to datastore
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        let body: [String: String] = ["session_id": sessionId]
        do {
            var req = URLRequest(url: Self.pullURL)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            req.timeoutInterval = 10
            let (_, response) = try await URLSession.shared.data(for: req)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if status != 200 {
                await MainActor.run { lastError = "Post-PUSH PULL failed (\(status))" }
            }
        } catch {
            await MainActor.run { lastError = "Post-PUSH PULL: \(error.localizedDescription)" }
        }
    }

    // MARK: - PULL (single key)
    func pullSingleKey(_ key: String) async throws -> String? {
        let body: [String: String] = ["session_id": key]
        var req = URLRequest(url: Self.pullURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        req.timeoutInterval = 10
        let (data, _) = try await URLSession.shared.data(for: req)
        let text = String(data: data, encoding: .utf8) ?? ""
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != "Accepted", trimmed != "READ" else { return nil }
        return text
    }

    // MARK: - PULL
    func pull(session: SessionState, manual: Bool = true) async -> String? {
        guard session.isPatientIdValid else {
            // Ne pas bloquer visuellement — juste loguer
            print("[MakeSyncService] PULL skipped: patientId '\(session.patientId)' invalid (min \(SessionState.minPatientId))")
            return nil
        }
        let key = session.pullKey
        print("[MakeSyncService] PULL key='\(key)' role.code='\(session.role.code)' pullSource='\(session.pullSource?.code ?? "nil")' pullSource.codeFormatted='\(session.pullSource?.codeFormatted ?? "nil")' isPatrick=\(session.role.isPatrick)")
        guard !key.isEmpty, !key.hasPrefix("00--"), !key.contains("--") else {
            await MainActor.run { lastError = "PULL aborted: pullKey invalide '\(key)'" }
            print("[MakeSyncService] PULL aborted: pullKey invalide '\(key)'")
            return nil
        }
        // Debounce anti queue-drain : rejeter si < minPullIntervalSeconds depuis le dernier pull
        let now = Date()
        guard now.timeIntervalSince(lastPullTimestamp) >= Self.minPullIntervalSeconds || manual else {
            print("[MakeSyncService] PULL debounced (queue-drain guard) — \(String(format: "%.1f", now.timeIntervalSince(lastPullTimestamp)))s < \(Self.minPullIntervalSeconds)s")
            return nil
        }
        lastPullTimestamp = now
        await MainActor.run { isReceiving = true; lastError = nil }
        do {
            // Try primary key first
            var text = try await pullSingleKey(key)

            // If primary key returned nothing useful, try alternate program codes (00→01→02)
            // This handles the case where the supervisor changed the program code during correction
            if text == nil {
                let parts = key.split(separator: "-", maxSplits: 1)
                if parts.count == 2, let currentCode = Int(parts[0]) {
                    let suffix = String(parts[1])
                    for altCode in (currentCode + 1)...min(currentCode + 5, 99) {
                        let altKey = String(format: "%02d-%@", altCode, suffix)
                        if let altText = try await pullSingleKey(altKey) {
                            print("[MakeSyncService] PULL fallback: found data at \(altKey) (original: \(key))")
                            text = altText
                            // Update session program code to match
                            await MainActor.run { session.sessionProgramCode = String(format: "%02d", altCode) }
                            break
                        }
                    }
                }
            }

            await MainActor.run { isReceiving = false }
            guard let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            var lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
            var detectedPin: String?
            if let first = lines.first, first.hasPrefix("PIN:") {
                detectedPin = String(first.dropFirst(4)).trimmingCharacters(in: .whitespaces)
                lines.removeFirst()
            }
            // Patrick ne doit jamais valider ses propres PINs
            let isSelfPull = session.role.isPatrick && key.hasSuffix("-\(ActiveRole.patrickCode)")
            if detectedPin != nil && !manual && !isSelfPull {
                // Auto-scan avec PIN d'un tiers → NE PAS marquer READ (la shamane doit encore le lire)
                return "PIN_PENDING"
            }
            if let pin = detectedPin, manual, !isSelfPull {
                // Pull manuel avec PIN (shamane) → la clé sera marquée READ après validation du PIN
                return "PIN:\(pin)\n" + lines.joined(separator: "\n")
            }
            // Self-pull ou pas de PIN → marquer READ immédiatement
            if isSelfPull || detectedPin == nil {
                Task { await self.markAsRead(sessionId: key) }
            }
            return lines.joined(separator: "\n")
        } catch {
            await MainActor.run { isReceiving = false; lastError = error.localizedDescription }
            return nil
        }
    }

    // MARK: - Mark as READ (overwrite with empty marker after successful PULL)
    func markAsRead(sessionId: String) async {
        let body: [String: String] = ["session_id": sessionId, "payload": "READ"]
        do {
            var req = URLRequest(url: Self.pushURL)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            req.timeoutInterval = 10
            let (_, response) = try await URLSession.shared.data(for: req)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("[MakeSyncService] markAsRead \(sessionId) → \(status)")
        } catch {
            print("[MakeSyncService] markAsRead failed: \(error.localizedDescription)")
        }
    }

    // MARK: - SCAN all shamane sources (Patrick only)
    func scanSources(session: SessionState) async {
        guard session.role.isSuperviseur else { return }
        guard session.isPatientIdValid else {
            print("[MakeSyncService] Scan skipped: patientId '\(session.patientId)' invalid (min \(SessionState.minPatientId))")
            return
        }
        let profiles = session.shamaneProfiles
        guard !profiles.isEmpty else {
            await MainActor.run { isScanning = false; pendingSources = [] }
            return
        }
        await MainActor.run { isScanning = true }
        var found: [ShamaneProfile] = []
        await withTaskGroup(of: (ShamaneProfile, Bool).self) { group in
            for shamane in profiles {
                group.addTask {
                    let key = "\(session.sessionProgramCode)-\(session.patientId)-\(session.sessionNum)-\(shamane.codeFormatted)"
                    // Guard race condition : ne pas envoyer une clé malformée
                    guard !key.isEmpty, !key.contains("--"), Int(session.patientId) ?? 0 >= SessionState.minPatientId else {
                        return (shamane, false)
                    }
                    let body: [String: String] = ["session_id": key]
                    do {
                        var req = URLRequest(url: Self.pullURL)
                        req.httpMethod = "POST"
                        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        req.httpBody = try JSONSerialization.data(withJSONObject: body)
                        req.timeoutInterval = 8
                        let (data, _) = try await URLSession.shared.data(for: req)
                        let text = String(data: data, encoding: .utf8) ?? ""
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        let hasData = !trimmed.isEmpty && trimmed != "READ" && trimmed != "Accepted"
                        return (shamane, hasData)
                    } catch {
                        return (shamane, false)
                    }
                }
            }
            for await (shamane, hasData) in group {
                if hasData { found.append(shamane) }
            }
        }
        await MainActor.run {
            let previousCount = pendingSources.count
            pendingSources = found.sorted(by: { $0.code < $1.code })
            isScanning = false
            // Badge app
            UIApplication.shared.applicationIconBadgeNumber = pendingSources.count
            // Notification locale si nouveaux soins détectés
            if pendingSources.count > previousCount && !pendingSources.isEmpty {
                sendLocalNotification(count: pendingSources.count, names: pendingSources.map(\.displayName))
            }
        }
    }

    // MARK: - Sérialisation
    func serializeSession(_ s: SessionState) -> String {
        var lines: [String] = []
        let df = DateFormatter(); df.dateFormat = "dd.MM.yyyy HH:mm:ss"
        lines.append("SVLBH·hDOM·P\(s.patientId)·S\(s.sessionNum)·\(s.role.displayName)·\(df.string(from: Date()))")
        // P1 — ScoresLumiere complets (SLA / SLSA / SLM / TotSLM)
        lines.append(serializeScores(s.scoresTherapist, suffix: "T"))
        lines.append(serializeScores(s.scoresPatrick,   suffix: "P"))
        // Ratio 4D (Passeport SVLBH)
        if let r = s.passeport.ratio4D {
            let cluster = s.passeport.cluster ?? ""
            let pays = s.passeport.paysOrigine ?? ""
            let baseline = s.passeport.slsaChBaseline ?? 0
            let sltdaO = s.passeport.sltdaOrigine ?? 0
            let sltdaC = s.passeport.sltdaCh ?? 0
            let hist = s.passeport.slsaHistorique ?? 0
            let trauma = s.passeport.dateTrauma ?? ""
            lines.append("R4D:\(String(format: "%.2f", r))|\(cluster)|\(pays)|\(baseline)|\(sltdaO)|\(sltdaC)|\(hist)|\(trauma)")
        }
        // Sérialiser uniquement les générations avec contenu
        let activeGens = s.visibleGenerations.filter {
            $0.validated || !$0.abLabel.isEmpty || !$0.viLabel.isEmpty
            || !$0.phases.isEmpty || !$0.gu.isEmpty || !$0.meridiens.isEmpty
        }
        for g in activeGens {
            let v = g.validated ? "✓" : "○"
            let ph = g.phases.sorted(by: { $0.rawValue < $1.rawValue }).map(\.label).joined(separator: "+")
            let gu = g.gu.map(\.rawValue).joined(separator: ",")
            let mt = g.meridiens.map(\.rawValue).joined(separator: " ")
            let st = g.statuts.map(\.rawValue).joined(separator: "+")
            lines.append("G\(g.id)|\(v)|ab:\(g.abLabel)|vi:\(g.viLabel)|ph:\(ph)|gu:\(gu)|mt:\(mt)|st:\(st)")
        }
        for p in s.pierres where p.selected {
            let v = p.validated ? "✓" : "○"
            let dur = "\(p.durationMin) min + \(p.durationDays) j"
            lines.append("P|\(v)|\(p.spec.nom)|\(p.volume)\(p.unit)|\(dur)")
        }
        for (key, done) in s.chakraStates.sorted(by: { $0.key < $1.key }) where done {
            let parts = key.split(separator: "_")
            if parts.count == 2 {
                let dNum = parts[0].replacingOccurrences(of: "d", with: "")
                let cNum = String(parts[1])
                let nm = chakraName(forKey: key) ?? "?"
                lines.append("C|D\(dNum)|C\(cNum)|\(nm)")
            }
        }
        // F16 — CIM-11 sélectionnés
        for (key, codes) in s.selectedCIM where !codes.isEmpty {
            let parts = key.split(separator: "_")
            let dim = parts.count > 0 ? String(parts[0]).uppercased() : "?"
            let chk = parts.count > 1 ? "C\(parts[1])" : "?"
            lines.append("CIM|\(dim)|\(chk)|\(codes.sorted().joined(separator: ","))")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Apply received payload (MERGE mode)
    func applyPayload(_ text: String, to session: SessionState) {
        var log: [String] = []
        let sender = session.role.isSuperviseur ? (session.pullSource?.displayName ?? "?") : "🔬 Patrick"
        let df = DateFormatter(); df.dateFormat = "HH:mm:ss"
        log.append("📥 Réception de \(sender) · \(df.string(from: Date()))")
        log.append("🔑 Pull key: \(session.pullKey)")

        // Clear previous suggestions
        session.generations.forEach { $0.clearSuggestions() }
        session.pierres.forEach { $0.clearSuggestions() }
        session.sugChakraStates = [:]

        var sugCount = 0
        var mergeCount = 0

        for line in text.split(separator: "\n").map(String.init) {
            if line.hasPrefix("SVLBH") { log.append("⏱ \(line)"); continue }
            if parseScoresLine(line, session: session) { continue }
            // Ratio 4D (Passeport SVLBH)
            if line.hasPrefix("R4D:") {
                let parts = String(line.dropFirst(4)).split(separator: "|", omittingEmptySubsequences: false).map(String.init)
                if let val = Double(parts[0]) {
                    session.ratio4D = val
                    let p = session.passeport
                    p.ratio4D = val
                    if parts.count > 1 { p.cluster = parts[1] }
                    if parts.count > 2 { p.paysOrigine = parts[2] }
                    if parts.count > 3 { p.slsaChBaseline = Int(parts[3]) }
                    if parts.count > 4 { p.sltdaOrigine = Int(parts[4]) }
                    if parts.count > 5 { p.sltdaCh = Int(parts[5]) }
                    if parts.count > 6 { p.slsaHistorique = Int(parts[6]) }
                    if parts.count > 7 { p.dateTrauma = parts[7] }
                    log.append("📐 Ratio 4D: \(String(format: "%.2f", val))× [\(p.clusterDisplay)]")
                }
                continue
            }
            let gResult = mergeGeneration(line, session: session)
            sugCount += gResult.suggestions; mergeCount += gResult.merged
            let pResult = mergePierre(line, session: session)
            sugCount += pResult.suggestions; mergeCount += pResult.merged
            let cResult = mergeChakra(line, session: session)
            sugCount += cResult.suggestions; mergeCount += cResult.merged
        }

        // Calc tab diffs for badges
        var d = TabDiffs()
        d.decode = session.generations.filter { $0.hasSuggestions }.count
        d.pierres = session.pierres.filter { $0.hasSuggestions }.count
        d.chakras = session.sugChakraStates.values.filter { $0 }.count

        log.append("─── \(mergeCount) fusionnés · \(sugCount) suggestions 🔬 ───")
        if sugCount > 0 {
            log.append("🔬 \(sugCount) proposition(s) à réviser")
        }
        DispatchQueue.main.async { self.diffs = d; self.diffLog = log }
    }


    // MARK: - Broadcast ciblé (Patrick → certifiées / programme / groupe)
    func broadcastPush(session: SessionState, target: BroadcastTarget = .allCertifiees) async -> Bool {
        let keys = session.broadcastKeys(target: target)
        guard !keys.isEmpty else { return false }
        await MainActor.run { isSending = true; lastError = nil }
        let payload = serializeSession(session)
        var allOk = true
        for key in keys {
            let body: [String: String] = ["session_id": key, "payload": payload]
            do {
                var req = URLRequest(url: Self.pushURL)
                req.httpMethod = "POST"
                req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                req.httpBody = try JSONSerialization.data(withJSONObject: body)
                let (_, response) = try await URLSession.shared.data(for: req)
                if (response as? HTTPURLResponse)?.statusCode != 200 { allOk = false }
            } catch { allOk = false }
        }
        await MainActor.run { isSending = false }
        return allOk
    }

    // MARK: - SLM Helpers
    private func serializeScores(_ sc: ScoresLumiere, suffix: String) -> String {
        let f: (Int?) -> String = { $0.map { "\($0)" } ?? "—" }
        return "SLA_\(suffix):\(f(sc.sla)) SLSA_\(suffix):\(f(sc.slsaEffective ?? sc.slsa)) SLM_\(suffix):\(f(sc.slm)) TotSLM_\(suffix):\(f(sc.totSlm))"
    }

    private func parseScoresLine(_ line: String, session: SessionState) -> Bool {
        guard line.hasPrefix("SLA_T:") || line.hasPrefix("SLA_P:") else { return false }
        let isT = line.hasPrefix("SLA_T:")
        var sc = ScoresLumiere()
        for part in line.split(separator: " ").map(String.init) {
            let kv = part.split(separator: ":", maxSplits: 1).map(String.init)
            guard kv.count == 2 else { continue }
            let val = Int(kv[1])  // nil if "—"
            let key = kv[0]
            if key.hasPrefix("SLA_")    { sc.sla = val }
            if key.hasPrefix("SLSA_")   { sc.slsa = val }
            if key.hasPrefix("SLM_")    { sc.slm = val }
            if key.hasPrefix("TotSLM_") { sc.totSlm = val }
        }
        if isT {
            session.scoresTherapist = sc
            session.slaTherapist = sc.sla
        } else {
            session.scoresPatrick = sc
            session.slaPatrick = sc.sla
        }
        return true
    }

    // MARK: - Merge Parsers
    private struct MergeResult { var merged: Int = 0; var suggestions: Int = 0 }

    private func mergeGeneration(_ line: String, session: SessionState) -> MergeResult {
        var r = MergeResult()
        guard line.hasPrefix("G") else { return r }
        let parts = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        guard parts.count >= 8 else { return r }
        let nStr = parts[0].replacingOccurrences(of: "G", with: "")
        guard let n = Int(nStr), let g = session.generations.first(where: { $0.id == n }) else { return r }

        // Parse incoming values
        let incValidated = parts[1] == "✓"
        let abRaw = parts[2].replacingOccurrences(of: "ab:", with: "")
        var incAb = ""
        if !abRaw.isEmpty { for cat in roueDesBesoins where cat.items.contains(abRaw) { incAb = "\(cat.id)|\(abRaw)"; break } }
        let viRaw = parts[3].replacingOccurrences(of: "vi:", with: "")
        var incVi = ""
        if !viRaw.isEmpty { for cat in roueDesBesoins where cat.items.contains(viRaw) { incVi = "\(cat.id)|\(viRaw)"; break } }
        let phStr = parts[4].replacingOccurrences(of: "ph:", with: "")
        let incPh = Set(phStr.split(separator: "+").compactMap { p in Phase.allCases.first { $0.label == String(p) } })
        let guStr = parts[5].replacingOccurrences(of: "gu:", with: "")
        let incGu = Set(guStr.split(separator: ",").compactMap { GuType(rawValue: String($0).trimmingCharacters(in: .whitespaces)) })
        let mtStr = parts[6].replacingOccurrences(of: "mt:", with: "")
        let incMer = Set(mtStr.split(separator: " ").compactMap { Meridian(rawValue: String($0)) })
        let stStr = parts[7].replacingOccurrences(of: "st:", with: "")
        let incSt = Set(stStr.split(separator: "+").compactMap { Statut(rawValue: String($0)) })

        // Merge: validated — always accept if incoming is true
        if incValidated && !g.validated { g.validated = true; r.merged += 1 }

        // Merge per field: empty local → suggest, same → silent, different → suggest
        r = mergeField(local: g.abuseur, incoming: incAb, set: { g.abuseur = $0 }, suggest: { g.sugAbuseur = $0 }, result: r)
        r = mergeField(local: g.victime, incoming: incVi, set: { g.victime = $0 }, suggest: { g.sugVictime = $0 }, result: r)
        r = mergeSetField(local: g.phases, incoming: incPh, set: { g.phases = $0 }, suggest: { g.sugPhases = $0 }, result: r)
        r = mergeSetField(local: g.gu, incoming: incGu, set: { g.gu = $0 }, suggest: { g.sugGu = $0 }, result: r)
        r = mergeSetField(local: g.meridiens, incoming: incMer, set: { g.meridiens = $0 }, suggest: { g.sugMeridiens = $0 }, result: r)
        r = mergeSetField(local: g.statuts, incoming: incSt, set: { g.statuts = $0 }, suggest: { g.sugStatuts = $0 }, result: r)
        return r
    }

    /// String field merge: empty local → fill silently, same → skip, different → suggest
    private func mergeField(local: String, incoming: String, set: (String) -> Void, suggest: (String) -> Void, result: MergeResult) -> MergeResult {
        var r = result
        guard !incoming.isEmpty else { return r }
        if local.isEmpty { set(incoming); r.merged += 1 }
        else if local != incoming { suggest(incoming); r.suggestions += 1 }
        return r
    }

    /// Set field merge: empty local → fill silently, same → skip, different → suggest
    private func mergeSetField<T: Hashable>(local: Set<T>, incoming: Set<T>, set: (Set<T>) -> Void, suggest: (Set<T>) -> Void, result: MergeResult) -> MergeResult {
        var r = result
        guard !incoming.isEmpty else { return r }
        if local.isEmpty { set(incoming); r.merged += 1 }
        else if local != incoming { suggest(incoming); r.suggestions += 1 }
        return r
    }

    private func mergePierre(_ line: String, session: SessionState) -> MergeResult {
        var r = MergeResult()
        guard line.hasPrefix("P|") else { return r }
        let parts = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        guard parts.count >= 5, let p = session.pierres.first(where: { $0.spec.nom == parts[2] }) else { return r }
        let incVol: Int
        let incUnit: String
        let volStr = parts[3]
        if volStr.hasSuffix("t") { incUnit = "t"; incVol = Int(volStr.dropLast()) ?? 1 }
        else { incUnit = "kg"; incVol = Int(volStr.replacingOccurrences(of: "kg", with: "")) ?? 1 }

        if !p.selected {
            // Pierre pas sélectionnée localement → suggestion
            p.sugSelected = true
            p.sugVolume = incVol; p.sugUnit = incUnit
            r.suggestions += 1
        } else {
            // Pierre déjà sélectionnée → comparer volume/unité
            if p.volume != incVol || p.unit != incUnit {
                p.sugVolume = incVol; p.sugUnit = incUnit
                r.suggestions += 1
            } else { r.merged += 1 }
        }
        return r
    }

    private func mergeChakra(_ line: String, session: SessionState) -> MergeResult {
        var r = MergeResult()
        guard line.hasPrefix("C|") else { return r }
        let parts = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        guard parts.count >= 4 else { return r }
        let dNum = parts[1].replacingOccurrences(of: "D", with: "")
        let cNum = parts[2].replacingOccurrences(of: "C", with: "")
        let key = "d\(dNum)_\(cNum)"
        if session.chakraStates[key] == true {
            r.merged += 1  // déjà coché localement
        } else {
            session.sugChakraStates[key] = true  // suggestion
            r.suggestions += 1
        }
        return r
    }

    // MARK: - Notifications locales

    static func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            print("[Notifications] Permission: \(granted)")
        }
    }

    private func sendLocalNotification(count: Int, names: [String]) {
        let content = UNMutableNotificationContent()
        content.title = "Soin reçu"
        content.body = count == 1
            ? "\(names.first ?? "Une shamane") a envoyé un soin"
            : "\(count) soins en attente de \(names.joined(separator: ", "))"
        content.sound = .default
        content.badge = NSNumber(value: count)
        let request = UNNotificationRequest(identifier: "soin-\(UUID().uuidString)",
                                            content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
