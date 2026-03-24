// SVLBHPanel — Services/PasteParser.swift
// v0.1.1 — Parse export texte VLBH → SessionState

import Foundation

struct PasteParser {

    // MARK: - Point d'entrée principal
    static func apply(_ text: String, to session: SessionState) -> Int {
        var count = 0
        let lines = text.components(separatedBy: "\n")
        var section = ""

        for line in lines {
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.hasPrefix("── DÉCODAGE G.") { section = "decode"; continue }
            if t.hasPrefix("── PIERRES")      { section = "pierres"; continue }
            if t.hasPrefix("── 33 CHAKRAS")   { section = "chakras"; continue }
            if t.hasPrefix("── SVLBH")        { section = "svlbh"; continue }
            if t.hasPrefix("── SÉQUENCE")     { section = ""; continue }

            switch section {
            case "decode":  if parseGeneration(t, session: session) { count += 1 }
            case "pierres": if parsePierre(t, session: session)     { count += 1 }
            case "chakras": if parseChakra(t, session: session)     { count += 1 }
            default: break
            }
        }
        return count
    }

    // MARK: - Parser Génération
    // Format: ✓ G-25 | Abuseur: X | Victime: Y | Phase: A+B | Gu: X, Y | Méridiens: GV LU | Statut: Origine
    private static func parseGeneration(_ line: String, session: SessionState) -> Bool {
        guard line.hasPrefix("✓") || line.hasPrefix("○") else { return false }
        let validated = line.hasPrefix("✓")
        let parts = line.components(separatedBy: " | ")
        guard parts.count >= 7 else { return false }

        // Numéro génération
        let header = parts[0]
        guard let gRange = header.range(of: #"G-(\d+)"#, options: .regularExpression) else { return false }
        let gNum = Int(header[gRange].replacingOccurrences(of: "G-", with: "")) ?? 0
        guard let gen = session.generations.first(where: { $0.id == gNum }) else { return false }

        gen.validated = validated

        // Abuseur
        let abStr = field(parts[1], prefix: "Abuseur:")
        gen.abuseur = abStr == "—" ? "" : matchBesoin(abStr)

        // Victime
        let viStr = field(parts[2], prefix: "Victime:")
        gen.victime = viStr == "—" ? "" : matchBesoin(viStr)

        // Phases
        let phaseStr = field(parts[3], prefix: "Phase:")
        gen.phases = Set(phaseStr.components(separatedBy: "+").compactMap { phaseFrom($0.trimmingCharacters(in: .whitespaces)) })

        // Gu
        let guStr = field(parts[4], prefix: "Gu:")
        gen.gu = Set(guStr.components(separatedBy: ", ").compactMap { GuType(rawValue: $0.trimmingCharacters(in: .whitespaces)) })

        // Méridiens
        let merStr = field(parts[5], prefix: "Méridiens:")
        gen.meridiens = Set(merStr.components(separatedBy: " ").compactMap { Meridian(rawValue: $0.trimmingCharacters(in: .whitespaces)) })

        // Statuts
        let statStr = field(parts[6], prefix: "Statut:")
        gen.statuts = Set(statStr.components(separatedBy: "+").compactMap { statutFrom($0.trimmingCharacters(in: .whitespaces)) })

        return true
    }

    // MARK: - Parser Pierre
    // Format: ✓ ◼ Tourmaline noire | 28 kg · 45 min + 3 j | ...
    private static func parsePierre(_ line: String, session: SessionState) -> Bool {
        guard line.hasPrefix("✓") else { return false }
        let parts = line.components(separatedBy: " | ")
        guard parts.count >= 2 else { return false }

        // Nom pierre (enlève ✓ + icone)
        let header = parts[0]
        let tokens = header.components(separatedBy: " ").filter { !$0.isEmpty }
        guard tokens.count >= 3 else { return false }
        let nom = tokens.dropFirst(2).joined(separator: " ")

        guard let ps = session.pierres.first(where: { $0.spec.nom.lowercased() == nom.lowercased() }) else { return false }
        ps.selected = true
        ps.validated = false

        // Volume + durées depuis "28 kg · 45 min + 3 j"
        let mesure = parts[1]
        if let vol = parseVolume(mesure)  { ps.volume = vol.0; ps.unit = vol.1 }
        if let dur = parseDuration(mesure) { ps.durationMin = dur.0; ps.durationDays = dur.1 }
        return true
    }

    // MARK: - Parser Chakra
    // Format: "  ✓ C33 Intention, Symptômes..." ou "  ✓ C? ..."
    private static func parseChakra(_ line: String, session: SessionState) -> Bool {
        let t = line.trimmingCharacters(in: .whitespaces)
        guard t.hasPrefix("✓") else { return false }
        let tokens = t.components(separatedBy: " ").filter { !$0.isEmpty }
        guard tokens.count >= 2 else { return false }
        let key = tokens[1] // ex: "C33", "C?"
        if key == "C?" { return false }
        session.chakraStates[key] = true
        return true
    }

    // MARK: - Helpers
    private static func field(_ s: String, prefix: String) -> String {
        s.replacingOccurrences(of: prefix, with: "").trimmingCharacters(in: .whitespaces)
    }

    private static func phaseFrom(_ s: String) -> Phase? {
        switch s {
        case "Survie":       return .survie
        case "Pouvoir":      return .pouvoir
        case "Expression":   return .expression
        case "Déconnexion":  return .deconnexion
        default:             return nil
        }
    }

    private static func statutFrom(_ s: String) -> Statut? {
        switch s {
        case "Origine":      return .O
        case "Accumulation": return .A
        case "Réduction":    return .R
        case "Transmission": return .T
        default:             return nil
        }
    }

    /// Cherche le besoin dans roueDesBesoins → retourne "catKey|item"
    private static func matchBesoin(_ label: String) -> String {
        let clean = label.trimmingCharacters(in: .whitespaces)
        for cat in roueDesBesoins {
            if let item = cat.items.first(where: { $0.lowercased() == clean.lowercased() }) {
                return "\(cat.id)|\(item)"
            }
        }
        return ""
    }

    /// Parse "28 kg · 45 min + 3 j" → (28, "kg")
    private static func parseVolume(_ s: String) -> (Int, String)? {
        let pattern = #"(\d+)\s*(kg|g)"#
        guard let match = s.range(of: pattern, options: .regularExpression) else { return nil }
        let sub = String(s[match])
        let parts = sub.components(separatedBy: CharacterSet.whitespaces).filter { !$0.isEmpty }
        guard parts.count >= 2, let n = Int(parts[0]) else { return nil }
        return (n, parts[1])
    }

    /// Parse "28 kg · 45 min + 3 j" → (45 min, 3 days)
    private static func parseDuration(_ s: String) -> (Int, Int)? {
        var mins = 0; var days = 0
        if let m = s.range(of: #"(\d+)\s*min"#, options: .regularExpression) {
            mins = Int(String(s[m]).components(separatedBy: CharacterSet.whitespaces)[0]) ?? 0
        }
        if let d = s.range(of: #"(\d+)\s*j"#, options: .regularExpression) {
            days = Int(String(s[d]).components(separatedBy: CharacterSet.whitespaces)[0]) ?? 0
        }
        return (mins > 0 || days > 0) ? (mins, days) : nil
    }
}
