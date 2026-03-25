// SVLBHPanel — Services/SessionExporter.swift
// v4.0.0 — Export WhatsApp texte — ordre SVLBH · Décodage · SLM · Pierres · Séquence séance

import Foundation

struct SessionExporter {

    // MARK: - Point d'entrée principal
    static func export(_ session: SessionState) -> String {
        var lines: [String] = []

        // ── Header ──
        let sla = session.scoresTherapist.sla ?? session.slaTherapist ?? 89
        lines += [
            "=== SVLBH · hDOM · \(session.isSysteme ? "Système" : "Consultant.e") · SLA \(sla)% ===",
            "Exporté le \(formatDate())",
        ]

        // F30 — Ligne programme si ≠ 00
        if session.sessionProgramCode != "00" {
            let label = session.sessionProgramCode == "01" ? "Recherche" : session.sessionProgramCode
            lines += ["Programme : \(session.sessionProgramCode) · \(label)"]
        }

        lines += [""]

        // ── SVLBH ──
        lines += svlbhSection(session)

        // ── DÉCODAGE G. ──
        lines += decodageSection(session)

        // ── SLM ──
        lines += slmSection(session)

        // ── PIERRES ──
        lines += pierresSection(session)

        // ── SÉQUENCE SÉANCE ──
        lines += seanceSection(session)

        // ── F16 — CIM-11 sélectionnés ──
        lines += cimSection(session)

        return lines.joined(separator: "\n")
    }

    // MARK: - Section SVLBH
    private static func svlbhSection(_ session: SessionState) -> [String] {
        var lines = ["── SVLBH ──"]
        let merCount = meridianCount(session)
        let domMer = merCount.max(by: { $0.value < $1.value })
        let merStr = domMer.map { "\($0.key.rawValue)×\($0.value)" } ?? "—"
        let hasFork = session.generations.filter {
            $0.meridiens.contains(.KI) || $0.meridiens.contains(.GB)
        }.count > 3
        let forkStr = hasFork ? "3.5 Ga · C12 D4 · Méridien dominant : \(merStr)" : "— · Méridien dominant : \(merStr)"
        lines += ["Fork galactique : \(forkStr)"]
        lines += ["\(session.validatedCount) générations · Yi \(session.validatedCount > 0 ? "épuisé" : "normal")"]
        lines += [""]
        return lines
    }

    // MARK: - Section Décodage (uniquement les générations avec contenu)
    private static func decodageSection(_ session: SessionState) -> [String] {
        var lines = ["── DÉCODAGE G. ──"]
        let active = session.visibleGenerations.filter {
            $0.validated || !$0.abLabel.isEmpty || !$0.viLabel.isEmpty
            || !$0.phases.isEmpty || !$0.gu.isEmpty || !$0.meridiens.isEmpty
        }
        for gen in active {
            let prefix = gen.validated ? "✓" : "○"
            let ab = gen.abLabel.isEmpty ? "—" : gen.abLabel
            let vi = gen.viLabel.isEmpty ? "—" : gen.viLabel
            let ph = gen.phases.sorted(by: { $0.rawValue < $1.rawValue }).map(\.label).joined(separator: "+")
            let gu = gen.gu.map(\.rawValue).sorted().joined(separator: ", ")
            let mer = gen.meridiens.map(\.rawValue).sorted().joined(separator: " ")
            let st = gen.statuts.map(\.label).sorted().joined(separator: "+")
            lines += ["\(prefix) G-\(gen.id) | Abuseur: \(ab) | Victime: \(vi) | Phase: \(ph) | Gu: \(gu) | Méridiens: \(mer) | Statut: \(st)"]
        }
        if active.isEmpty { lines += ["— Aucune génération décodée —"] }
        let merCount = meridianCount(session)
        if !merCount.isEmpty {
            let summary = merCount.sorted(by: { $0.key.rawValue < $1.key.rawValue })
                .map { "\($0.key.rawValue)×\($0.value)" }.joined(separator: " · ")
            lines += ["", "Méridiens validés : \(summary)"]
        }
        lines += [""]
        return lines
    }

    // MARK: - Section SLM
    private static func slmSection(_ session: SessionState) -> [String] {
        let t = session.scoresTherapist
        return [
            "── SLM ──",
            "Thérapeute : SLA \(fmt(t.sla))% · SLSA \(fmt(t.slsa))% · SLM \(fmt(t.slm))% · TotSLM \(fmt(t.totSlm))%",
            ""
        ]
    }

    // MARK: - Section Pierres
    private static func pierresSection(_ session: SessionState) -> [String] {
        var lines = ["── PIERRES DE PROTECTION ──"]
        let sel = session.selectedPierres
        if sel.isEmpty {
            lines += ["— Aucune pierre sélectionnée —"]
        } else {
            for ps in sel {
                lines += ["✓ \(ps.spec.icon) \(ps.spec.nom) | \(ps.volume) \(ps.unit) · \(ps.durationMin) min + \(ps.durationDays) j | \(ps.spec.role) | Placement: \(ps.spec.placement)"]
            }
        }
        lines += [""]
        return lines
    }

    // MARK: - Section Séquence séance (dérivée de l'état session)
    private static func seanceSection(_ session: SessionState) -> [String] {
        var lines = ["── SÉQUENCE SÉANCE ──"]
        let hasNuummite = session.pierres.first(where: { $0.spec.id == "nuum" })?.selected ?? false
        let slmLabel = hasNuummite ? "SLM Monade + Nuummite GV4 (3.5 Ga)" : "SLM Monade"
        lines += ["Ph -1 · \(slmLabel)"]
        lines += ["Ph 0 · Secondary Gain"]
        if session.chakraStates["C15"] == true {
            lines += ["Ph 1 · C15 D4 Mère Universelle"]
        }
        if session.chakraStates["C12"] == true {
            let hasFork = session.generations.filter {
                $0.meridiens.contains(.KI) || $0.meridiens.contains(.GB)
            }.count > 3
            lines += ["Ph 2 · C12 D4 Galactique\(hasFork ? " — fork 3.5 Ga" : "")"]
        }
        if session.chakraStates["C9"] == true {
            lines += ["Ph 3 · C9 Higher Heart"]
        }
        if session.chakraStates["C5"] == true {
            lines += ["Ph 4 · C5 Cœur — Porte du Cœur"]
        }
        let hasAbuseurs = session.generations.filter { $0.validated && !$0.abLabel.isEmpty }.count > 0
        if hasAbuseurs { lines += ["Ph 5a · CUBE × abuseurs patients zéro"] }
        let hasVictimes = session.generations.filter { $0.validated && !$0.viLabel.isEmpty }.count > 0
        if hasVictimes { lines += ["Ph 5b · ICOSAÈDRE × lots victimes féminines"] }
        lines += ["Ph 5d · DODÉCAÈDRE Monade S8"]
        lines += ["Scellement · SP3+SP6+KI3+GV4+PC7 · Om Nama Shivaya"]
        return lines
    }

    // MARK: - Helpers
    private static func meridianCount(_ session: SessionState) -> [Meridian: Int] {
        var c: [Meridian: Int] = [:]
        for g in session.generations where g.validated { for m in g.meridiens { c[m, default: 0] += 1 } }
        return c
    }
    // MARK: - Section CIM-11
    private static func cimSection(_ session: SessionState) -> [String] {
        let entries = session.selectedCIM.filter { !$0.value.isEmpty }
        guard !entries.isEmpty else { return [] }
        var lines = ["", "── CIM-11 ──"]
        for (key, codes) in entries.sorted(by: { $0.key < $1.key }) {
            let parts = key.split(separator: "_")
            let dim = parts.count > 0 ? String(parts[0]).uppercased() : "?"
            let chk = parts.count > 1 ? "C\(parts[1])" : "?"
            lines.append("CIM|\(dim)|\(chk)|\(codes.sorted().joined(separator: ","))")
        }
        return lines
    }

    private static func fmt(_ v: Int?) -> String { v.map { "\($0)" } ?? "—" }
    private static func formatDate() -> String {
        let f = DateFormatter(); f.dateFormat = "dd.MM.yyyy HH:mm:ss"; return f.string(from: Date())
    }
}
