// SVLBHPanel — Models/SessionData.swift
// v4.0.2 — Fix SLSA bug : slsaS1 séparé de slsa (total), recalcSLSA non-circulaire

import Foundation
import Combine
import UIKit

// ═══════════════════════════════════════════════════════════════════
// MARK: - Rôle actif (dynamique)
// ═══════════════════════════════════════════════════════════════════

enum ActiveRole: Equatable {
    case unidentified
    case shamane(ShamaneProfile)

    var code: String {
        switch self {
        case .unidentified: return ""
        case .shamane(let s): return s.codeFormatted
        }
    }

    var displayName: String {
        switch self {
        case .unidentified: return "Non identifié"
        case .shamane(let s): return s.displayName
        }
    }

    var isIdentified: Bool {
        if case .unidentified = self { return false }
        return true
    }

    var isSuperviseur: Bool {
        if case .shamane(let s) = self { return s.tier == .superviseur }
        return false
    }

    /// Owner = Patrick (455000). Seul l'owner voit la mécanique technique
    /// (scan sources, broadcast, dropdown shamane, PIN generation, INBOX write).
    /// Tous les autres rôles — y compris superviseur — ont une expérience transparente.
    var isOwner: Bool {
        if case .shamane(let s) = self { return Int(s.code) == 455000 }
        return false
    }
}

// ═══════════════════════════════════════════════════════════════════
// MARK: - Tier praticien (dérivé du code)
// ═══════════════════════════════════════════════════════════════════

enum PractitionerTier: String, Codable, CaseIterable {
    case lead        // 01-99
    case formation   // 100-299
    case certifiee   // 300-30000
    case superviseur // 455000+

    var label: String {
        switch self {
        case .lead:        return "INVITÉ"
        case .formation:   return "EN FORMATION"
        case .certifiee:   return "CERTIFIÉE"
        case .superviseur: return "SUPERVISEUR"
        }
    }

    var badgeColor: String {
        switch self {
        case .lead:        return "#E24B4A"
        case .formation:   return "#BA7517"
        case .certifiee:   return "#3B6D11"
        case .superviseur: return "#8B3A62"
        }
    }

    var forkResolu: Bool { self == .certifiee || self == .superviseur }

    var maxGenerations: Int {
        switch self {
        case .lead:        return 5
        case .formation:   return 25
        case .certifiee:   return 100
        case .superviseur: return 100
        }
    }

    var whatsappURL: URL? {
        switch self {
        case .lead:        return URL(string: "https://wa.me/41798131926")
        case .formation:   return URL(string: "https://wa.me/41792168200")
        case .certifiee:   return URL(string: "https://wa.me/41799302800")
        case .superviseur: return nil
        }
    }

    var whatsappLabel: String {
        switch self {
        case .lead:        return "Contacte Cornelia et Patrick"
        case .formation:   return "WhatsApp Formation"
        case .certifiee:   return "WhatsApp Certifiées"
        case .superviseur: return ""
        }
    }

    static func from(code: Int) -> PractitionerTier {
        switch code {
        case 1...99:       return .lead
        case 100...299:    return .formation
        case 300...30000:  return .certifiee
        case 30001...:     return .superviseur
        default:           return .lead
        }
    }
}

// ═══════════════════════════════════════════════════════════════════
// MARK: - Programmes shamane (Planche Tactique)
// ═══════════════════════════════════════════════════════════════════

enum ShamaneProgramme: String, Codable, CaseIterable, Sendable {
    case aucun      = "aucun"
    case leadChaud  = "leadChaud"
    case protection = "protection"
    case mySha      = "mySha"
    case formee     = "formee"
    case myShaFa    = "myShaFa"

    var label: String {
        switch self {
        case .aucun:      return "Aucun"
        case .leadChaud:  return "Lead chaud avec RDV"
        case .protection: return "Programme de Protection de la Sur-Âme"
        case .mySha:      return "mySha"
        case .formee:     return "Formé.e.s"
        case .myShaFa:    return "MyShaFa"
        }
    }

    var badgeColor: String {
        switch self {
        case .aucun:      return "#999999"
        case .leadChaud:  return "#D4451A"
        case .protection: return "#5B2C8E"
        case .mySha:      return "#2E6CB5"
        case .formee:     return "#7B8D4E"
        case .myShaFa:    return "#1A8A6E"
        }
    }
}

// ═══════════════════════════════════════════════════════════════════
// MARK: - Module Shamane minimum
// ═══════════════════════════════════════════════════════════════════

struct ShamaneProfile: Codable, Identifiable, Equatable, Hashable, Sendable {
    var id: String { code }
    var code: String
    var prenom: String
    var nom: String
    var whatsapp: String
    var email: String
    var abonnement: String
    var prochainFacturation: Date?
    var patientId: Int = 12              // min 12, choisi par la shamane
    var zones: [String] = []             // max 5 zones texte libre
    var photoSetId: String? = nil       // lien vers ReferenceImageSet.id
    var sephirothCodes: [String] = []   // max 5 codes séphirothiques
    var programmes: [ShamaneProgramme] = []

    var tier: PractitionerTier { PractitionerTier.from(code: Int(code) ?? 0) }

    var displayName: String { nom.isEmpty ? prenom : "\(prenom) \(nom)" }

    var codeFormatted: String {
        guard let n = Int(code) else { return code }
        switch tier {
        case .lead:        return String(format: "%02d", n)
        case .formation:   return String(format: "%03d", n)
        case .certifiee:   return String(format: "%04d", n)
        case .superviseur: return String(n)
        }
    }

    static func nextCode(tier: PractitionerTier, existing: [ShamaneProfile]) -> String {
        let usedNumbers = existing.compactMap { Int($0.code) }
        let range: ClosedRange<Int>
        switch tier {
        case .lead:        range = 1...99
        case .formation:   range = 100...299
        case .certifiee:   range = 300...30000
        case .superviseur: range = 455000...455999
        }
        var next = range.lowerBound
        while usedNumbers.contains(next) { next += 1 }
        guard range.contains(next) else { return String(range.upperBound) }
        return String(next)
    }
}

// ═══════════════════════════════════════════════════════════════════
// MARK: - Programmes de recherche
// ═══════════════════════════════════════════════════════════════════

struct ResearchProgram: Codable, Identifiable, Equatable, Hashable {
    var id: String
    var nom: String
    var programCode: String  // "01", "03", "05"
    var actif: Bool = true
    var shamaneCodes: [String] = []

    static let defaults: [ResearchProgram] = [
        ResearchProgram(id: "SCT", nom: "Scleroses chromatiques transgenerationnelles multiples", programCode: "01"),
        ResearchProgram(id: "AME", nom: "Accumulations masculines sur l'endometre", programCode: "03"),
        ResearchProgram(id: "GLY", nom: "Glycemies I, II et III", programCode: "05"),
    ]
}

// ═══════════════════════════════════════════════════════════════════
// MARK: - Groupes thématiques (manuels, par pathologie)
// ═══════════════════════════════════════════════════════════════════

struct ThematicGroup: Codable, Identifiable, Equatable {
    let id: String
    var nom: String
    var shamaneCodes: [String] = []
}

// ═══════════════════════════════════════════════════════════════════
// MARK: - Systèmes de référence (groupes d'images)
// ═══════════════════════════════════════════════════════════════════

struct ReferenceImageSet: Codable, Identifiable, Equatable, Hashable {
    let id: String
    var nom: String
    var description: String = ""
    var imageFileNames: [String] = []
    var createdAt: Date = Date()

    /// Chemin de base des images (Drive local)
    static let basePath = "/Users/patricktest/Library/CloudStorage/GoogleDrive-monade.karmique@gmail.com/Mon Drive/palettemulticouleur/mft-2022-04-11-magnetic-field-light"

    func imagePaths() -> [String] {
        imageFileNames.map { "\(Self.basePath)/\($0)" }
    }
}

// ═══════════════════════════════════════════════════════════════════
// MARK: - F01 — Leads : cap + liste d'attente
// ═══════════════════════════════════════════════════════════════════

enum LeadStatus: String, Codable { case active, waiting, completed }

struct LeadSlot: Codable, Identifiable, Equatable {
    var id: String { shamaneCode }
    var shamaneCode: String
    var status: LeadStatus
    var createdAt: Date = Date()
}

// ═══════════════════════════════════════════════════════════════════
// MARK: - Cible de broadcast
// ═══════════════════════════════════════════════════════════════════

enum BroadcastTarget: Equatable {
    case allCertifiees
    case program(ResearchProgram)
    case group(ThematicGroup)
}

// ═══════════════════════════════════════════════════════════════════
// MARK: - Shamane enum (dropdown "Décoder et Envoyer")
// ═══════════════════════════════════════════════════════════════════

// enum Shamane supprimé — la source de vérité est shamaneProfiles (Planche Tactique)

// Migration ancien format CertifiedTherapist → ShamaneProfile
private struct LegacyCertifiedTherapist: Codable {
    let name: String
    let code: String
}

// ═══════════════════════════════════════════════════════════════════
// MARK: - Phase transgénérationnelle
// ═══════════════════════════════════════════════════════════════════

enum Phase: Int, Codable, CaseIterable, Identifiable {
    case survie = 0, pouvoir, expression, deconnexion
    var id: Int { rawValue }
    var label: String { ["Survie","Pouvoir","Expression","Déconnexion"][rawValue] }
    var color: String { ["#185FA5","#BA7517","#D4537E","#5F5E5A"][rawValue] }
}

enum Statut: String, Codable, CaseIterable {
    case O, A, R, T
    var label: String { ["Origine","Accumulation","Réduction","Transmission"][["O","A","R","T"].firstIndex(of: rawValue)!] }
}

enum GuType: String, Codable, CaseIterable, Identifiable {
    case coreWound = "Core Wound"
    case inLimbo = "In Limbo"
    case energeticRope = "Energetic Rope"
    case abuseEnergy = "Abuse Energy"
    case sabotageEnergy = "Sabotage Energy"
    case archonReptilian = "Archon/Reptilian"
    case spell = "Spell"
    case blackMagick = "Black Magick"
    case stain = "Stain"
    case bitchEnergy = "Bitch Energy"
    case incubusSuccubus = "Incubus/Succubus"
    case entityOnHeart = "Entity on Heart"
    case biblicalDarkEntity = "Biblical Dark Entity"
    case anchorsChains = "Anchors/Chains"
    case impersonationEnergy = "Impersonation Energy"
    var id: String { rawValue }
}

enum Meridian: String, Codable, CaseIterable, Identifiable {
    case SP, KI, LR, HT, PC, LU, GB, ST, LI, GV, CV, TE, BL
    var id: String { rawValue }
    var color: String {
        switch self {
        case .SP: return "#BA7517"; case .KI: return "#185FA5"; case .LR: return "#3B6D11"
        case .HT: return "#E24B4A"; case .PC: return "#D4537E"; case .LU: return "#888780"
        case .GB: return "#7F77DD"; case .ST: return "#639922"; case .LI: return "#1D9E75"
        case .GV: return "#BA7517"; case .CV: return "#185FA5"; case .TE: return "#D4537E"
        case .BL: return "#3B6D11"
        }
    }
    static let observed: [Meridian] = [.SP, .KI, .LR, .HT, .PC, .LU, .GB]
}

// ═══════════════════════════════════════════════════════════════════
// MARK: - Roue des besoins
// ═══════════════════════════════════════════════════════════════════

struct RoueCategory: Identifiable {
    let id: String
    let label: String
    let items: [String]
}

let roueDesBesoins: [RoueCategory] = [
    RoueCategory(id: "s", label: "Sécurité / Paix", items: ["Câlins","Calme","Amour","Soutien","Intimité","Empathie","Écoute","Sécurité","Paix intérieure"]),
    RoueCategory(id: "a", label: "Autonomie", items: ["Choix de mes rêves","Choix de mes actions","Temps libre","Faire moi-même","Apprendre","Découvrir","Comprendre","Besoin de clarté","Besoin de justice"]),
    RoueCategory(id: "e", label: "Expression", items: ["Dire ce que je pense","Exprimer mes émotions","Créativité","Être entendu(e)","Authenticité"]),
    RoueCategory(id: "r", label: "Respect", items: ["Respect pour mon corps","Respect pour mes idées","Respect pour mes efforts","Dignité"]),
    RoueCategory(id: "k", label: "Acceptation / Groupe", items: ["Acceptation tel que je suis","Appartenance","Amitié","Partage","Aide et aider","Honnêteté","Fêter / célébrer","Attention"]),
    RoueCategory(id: "j", label: "Jeu / Créa", items: ["Amuser","Créer quelque chose","Rire","Me détendre","Jouer","Légèreté"]),
    RoueCategory(id: "c", label: "Corps", items: ["Manger","Dormir","Respirer","Bouger","Boire","Toucher sain"])
]

// ═══════════════════════════════════════════════════════════════════
// MARK: - Génération
// ═══════════════════════════════════════════════════════════════════

class Generation: ObservableObject, Identifiable {
    let id: Int
    @Published var abuseur: String = ""
    @Published var victime: String = ""
    @Published var phases: Set<Phase> = []
    @Published var gu: Set<GuType> = []
    @Published var meridiens: Set<Meridian> = []
    @Published var statuts: Set<Statut> = []
    @Published var validated: Bool = false

    @Published var porteTemp: Int? = nil
    @Published var portePerm: Int? = nil

    @Published var sugAbuseur: String = ""
    @Published var sugVictime: String = ""
    @Published var sugPhases: Set<Phase> = []
    @Published var sugGu: Set<GuType> = []
    @Published var sugMeridiens: Set<Meridian> = []
    @Published var sugStatuts: Set<Statut> = []

    var hasSuggestions: Bool {
        !sugAbuseur.isEmpty || !sugVictime.isEmpty || !sugPhases.isEmpty
        || !sugGu.isEmpty || !sugMeridiens.isEmpty || !sugStatuts.isEmpty
    }

    func clearSuggestions() {
        sugAbuseur = ""; sugVictime = ""
        sugPhases = []; sugGu = []; sugMeridiens = []; sugStatuts = []
    }

    init(n: Int) { self.id = n }

    var abLabel: String { abuseur.split(separator: "|").last.map(String.init) ?? "" }
    var viLabel: String { victime.split(separator: "|").last.map(String.init) ?? "" }
}

// ═══════════════════════════════════════════════════════════════════
// MARK: - Pierre de protection
// ═══════════════════════════════════════════════════════════════════

struct PierreSpec: Identifiable {
    let id: String; let nom: String; let latin: String; let tags: [String]
    let role: String; let placement: String; let purification: String; let icon: String
    var defaultDays: Int { id == "obsid" ? 5 : 7 }
}

let pierresReference: [PierreSpec] = [
    PierreSpec(id:"tourm", nom:"Tourmaline noire", latin:"Schorl", tags:["ent","abus","cord"], role:"Bouclier n°1 · Gui 鬼 et Abuse Energy · 15 générations.", placement:"Périmètre cabinet + sous la table", purification:"Eau salée 12 h · Soleil 4 h", icon:"\u{1FACC}"),
    PierreSpec(id:"obsid", nom:"Obsidienne noire", latin:"SiO₂", tags:["cord","abus","anc"], role:"Cordages Abuseur→Consultant.e · Black Magick.", placement:"Mains du consultant.e ou CV1", purification:"Eau froide 1 h · Pleine lune", icon:"\u{1FACC}"),
    PierreSpec(id:"nuum", nom:"Nuummite (3.5 Ga)", latin:"Amphibolite", tags:["anc","jing","cord"], role:"Fork guerres galactiques C12 · Jing pré-biologique.", placement:"GV4 Mingmen ou KI1", purification:"Pleine lune uniquement. Pas d'eau.", icon:"\u{1FACC}"),
    PierreSpec(id:"shung", nom:"Shungite élite I", latin:"C>98%", tags:["ent","prat"], role:"Incubus/Succubus G-1 · Spell G-8 · Protection praticien.", placement:"Poche praticien + coins cabinet", purification:"Eau froide 30 min hebdo", icon:"\u{1FACC}"),
    PierreSpec(id:"aegir", nom:"Aegyrine", latin:"NaFe³⁺Si₂O₆", tags:["ent","abus"], role:"Archon/Reptilian G-10 · CUBE non-hermétique.", placement:"Grille 4 pointes autour de la table", purification:"Salvia 10 min · Pleine lune. Fragile.", icon:"\u{1FACC}"),
    PierreSpec(id:"apache", nom:"Apache Tears", latin:"Perlite volcanique", tags:["anc","cord"], role:"In Limbo ×3 · Psychopompe · Deuil femmes victimes.", placement:"Cercle autour du consultant.e", purification:"Enterrer 48 h dans la terre après usage", icon:"\u{1FACC}"),
    PierreSpec(id:"labra", nom:"Labradorite", latin:"(Ca,Na)(Si,Al)₄O₈", tags:["prat","ent"], role:"Aura praticien · Stern-Tetraeder · Pemphigus 15 G.", placement:"Portée praticien (cou ou poche)", purification:"Pleine lune mensuelle · Eau froide brève", icon:"\u{1FACC}"),
    PierreSpec(id:"kyani", nom:"Kyanite noire", latin:"Al₂SiO₅", tags:["cord","jing"], role:"Tuyau masculin Adam→Consultant.e · Zéro rétention.", placement:"Tuyau Jing GV4↔KI3", purification:"Aucune purification nécessaire.", icon:"\u{1FACC}")
]

class PierreState: ObservableObject, Identifiable {
    let spec: PierreSpec
    var id: String { spec.id }
    @Published var selected: Bool = false
    @Published var validated: Bool = false
    @Published var volume: Int = 1
    @Published var unit: String = "kg"
    @Published var durationMin: Int = 30
    @Published var durationDays: Int = 7

    @Published var sugSelected: Bool = false
    @Published var sugVolume: Int? = nil
    @Published var sugUnit: String? = nil
    @Published var sugDurationMin: Int? = nil
    @Published var sugDurationDays: Int? = nil

    var hasSuggestions: Bool {
        sugSelected || sugVolume != nil || sugUnit != nil
        || sugDurationMin != nil || sugDurationDays != nil
    }

    func clearSuggestions() {
        sugSelected = false; sugVolume = nil; sugUnit = nil
        sugDurationMin = nil; sugDurationDays = nil
    }

    init(spec: PierreSpec) { self.spec = spec; self.durationDays = spec.defaultDays }
}

// ═══════════════════════════════════════════════════════════════════
// MARK: - Dimension & Chakra
// ═══════════════════════════════════════════════════════════════════

struct ChakraSpec: Identifiable {
    let num: Int?; let icon: String; let nom: String
    let issues: [(label: String, sla: Int)]; let hasCIM: Bool
    var id: String { "\(num ?? 0)_\(nom)" }
}

struct DimensionSpec: Identifiable {
    let id: String; let num: Int; let label: String
    let description: String; let cssClass: String; let chakras: [ChakraSpec]
}

// ═══════════════════════════════════════════════════════════════════
// MARK: - Scores de Lumière (SLA / SLSA / SLM / TotSLM)
// ═══════════════════════════════════════════════════════════════════

struct ScoresLumiere {
    var sla: Int? = nil
    var slsa: Int? = nil       // SLSA total (computed ou saisie directe si pas de détail)
    var slsaS1: Int? = nil     // SA1 — champ propre, plus jamais confondu avec slsa
    var slsaS2: Int? = nil
    var slsaS3: Int? = nil
    var slsaS4: Int? = nil
    var slsaS5: Int? = nil
    var slm: Int? = nil
    var totSlm: Int? = nil

    static let slaMax   = 350
    static let slsaMax  = 50_000
    static let slmMax   = 100_000
    static let totSlmMax = 1_000

    /// true si au moins un SA renseigné (SA1–SA5)
    var hasDetailedSLSA: Bool {
        slsaS1 != nil || slsaS2 != nil || slsaS3 != nil || slsaS4 != nil || slsaS5 != nil
    }

    /// SLSA = SA1 + SA2 + SA3 + SA4 + SA5 (somme directe, sans auto-référence)
    var slsaAutoCalc: Int {
        (slsaS1 ?? 0) + (slsaS2 ?? 0) + (slsaS3 ?? 0) + (slsaS4 ?? 0) + (slsaS5 ?? 0)
    }

    /// SA1 seul si pas de détail SA2-SA5, sinon somme SA1-SA5
    var slsaEffective: Int? { hasDetailedSLSA ? slsaAutoCalc : slsa }

    mutating func recalcSLSA() { if hasDetailedSLSA { slsa = slsaAutoCalc } }
}

// ═══════════════════════════════════════════════════════════════════
// MARK: - Patient registry
// ═══════════════════════════════════════════════════════════════════

class PatientRegistry {
    private static let key = "svlbh_nextPatientId"

    static func nextId() -> String {
        let current = UserDefaults.standard.integer(forKey: key)
        // max() garantit qu'on démarre toujours à minPatientId (12)
        // même si UserDefaults contient une valeur résiduelle < 12
        return String(max(current + 1, SessionState.minPatientId))
    }

    static func consume() -> String {
        let id = nextId()
        UserDefaults.standard.set(Int(id) ?? 1, forKey: key)
        return id
    }

    static func seed(with knownId: String) {
        guard let n = Int(knownId) else { return }
        let current = UserDefaults.standard.integer(forKey: key)
        if n > current { UserDefaults.standard.set(n, forKey: key) }
    }
}

// ═══════════════════════════════════════════════════════════════════
// MARK: - Identification praticien (persistante)
// ═══════════════════════════════════════════════════════════════════

class PractitionerIdentity: ObservableObject {
    private static let codeKey = "svlbh_practitioner_code"
    private static let nameKey = "svlbh_practitioner_name"
    private static let appleUserKey = "svlbh_apple_user_id"
    private static let identityURL = URL(string: "https://hook.eu2.make.com/svlbh-identity-lookup")!
    private static let appleIdentityURL = URL(string: "https://hook.eu2.make.com/ril8mrrt2f97rq8r1ztip26th2nhd8zl")!

    // MARK: - Keychain (persiste entre reinstalls)
    private static let keychainService = "com.svlbh.panel.apple-identity"

    static func keychainSave(userID: String, code: String, name: String) {
        let data = "\(code)|\(name)".data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: userID
        ]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = data
        SecItemAdd(add as CFDictionary, nil)
    }

    private static func keychainLoad(userID: String) -> (code: String, name: String)? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: userID,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let str = String(data: data, encoding: .utf8) else { return nil }
        let parts = str.split(separator: "|", maxSplits: 1)
        guard parts.count == 2 else { return nil }
        return (code: String(parts[0]), name: String(parts[1]))
    }

    // appleEmailMap supprimé — la source de vérité est le datastore Make
    // (Planche Tactique → svlbh-apple-identity webhook)

    @Published var isIdentified: Bool = false
    @Published var code: String = ""
    @Published var displayName: String = ""
    @Published var isAutoIdentifying: Bool = false
    /// Mode client (Demandes) — point d'entrée séparé pour les patients
    @Published var isClientMode: Bool = false
    @Published var clientPatientId: String = ""

    private static let clientModeKey = "svlbh_client_mode"
    private static let clientPatientIdKey = "svlbh_client_patient_id"

    init() { load() }

    func load() {
        code = UserDefaults.standard.string(forKey: Self.codeKey) ?? ""
        displayName = UserDefaults.standard.string(forKey: Self.nameKey) ?? ""
        isIdentified = !code.isEmpty
        isClientMode = UserDefaults.standard.bool(forKey: Self.clientModeKey)
        clientPatientId = UserDefaults.standard.string(forKey: Self.clientPatientIdKey) ?? ""
    }

    func identify(code: String, name: String) {
        self.code = code
        self.displayName = name
        UserDefaults.standard.set(code, forKey: Self.codeKey)
        UserDefaults.standard.set(name, forKey: Self.nameKey)
        isIdentified = true
        isClientMode = false
        UserDefaults.standard.set(false, forKey: Self.clientModeKey)
        // Enregistrer le vendorID sur Make pour les prochains lancements
        Task { await registerVendorID(code: code, name: name) }
    }

    /// Identifier en mode client (Demandes)
    func identifyAsClient(patientId: String, name: String) {
        self.clientPatientId = patientId
        self.displayName = name
        self.isClientMode = true
        self.isIdentified = true
        UserDefaults.standard.set(true, forKey: Self.clientModeKey)
        UserDefaults.standard.set(patientId, forKey: Self.clientPatientIdKey)
        UserDefaults.standard.set(name, forKey: Self.nameKey)
    }

    /// Sign in with Apple — identifie via email mappé, cache local, ou webhook Make
    func identifyWithApple(userID: String, email: String?, fullName: PersonNameComponents?) async {
        let appleName = fullName.flatMap {
            [$0.givenName, $0.familyName].compactMap { $0 }.joined(separator: " ")
        }.flatMap { $0.isEmpty ? nil : $0 }

        // 1. Webhook Make — source de vérité (lookup par apple_user_id)
        if let remote = await lookupAppleUserID(userID: userID) {
            let name = appleName ?? remote.name
            UserDefaults.standard.set(userID, forKey: Self.appleUserKey)
            UserDefaults.standard.set(remote.code, forKey: "svlbh_apple_mapped_code")
            UserDefaults.standard.set(name, forKey: "svlbh_apple_mapped_name")
            Self.keychainSave(userID: userID, code: remote.code, name: name)
            identify(code: remote.code, name: name)
            return
        }

        // 2. Fallback offline — UserDefaults (login suivant, email = nil)
        let savedAppleUser = UserDefaults.standard.string(forKey: Self.appleUserKey)
        if savedAppleUser == userID, !userID.isEmpty,
           let savedCode = UserDefaults.standard.string(forKey: "svlbh_apple_mapped_code"), !savedCode.isEmpty {
            let savedName = UserDefaults.standard.string(forKey: "svlbh_apple_mapped_name") ?? "Utilisateur"
            identify(code: savedCode, name: savedName)
            return
        }

        // 3. Fallback offline — Keychain (survit aux reinstalls)
        if let saved = Self.keychainLoad(userID: userID) {
            UserDefaults.standard.set(userID, forKey: Self.appleUserKey)
            UserDefaults.standard.set(saved.code, forKey: "svlbh_apple_mapped_code")
            UserDefaults.standard.set(saved.name, forKey: "svlbh_apple_mapped_name")
            identify(code: saved.code, name: saved.name)
            return
        }

        // 5. UserID inconnu mais user déjà identifié dans cette app → lier automatiquement
        if !code.isEmpty && !displayName.isEmpty {
            UserDefaults.standard.set(userID, forKey: Self.appleUserKey)
            UserDefaults.standard.set(code, forKey: "svlbh_apple_mapped_code")
            UserDefaults.standard.set(displayName, forKey: "svlbh_apple_mapped_name")
            Self.keychainSave(userID: userID, code: code, name: displayName)
            Task { await registerAppleUserID(userID: userID, code: code, name: displayName, email: email) }
            isIdentified = true
            return
        }

        // 6. Nouveau userID, pas de code connu → sauver le userID pour la liaison manuelle
        UserDefaults.standard.set(userID, forKey: Self.appleUserKey)
    }

    // MARK: - Apple Identity ↔ Make.com

    /// Enregistre apple_user_id → code/name/email sur Make pour lookup cross-device (appelé depuis OnboardingView lors de la liaison manuelle)
    func registerAppleUserIDFromLink(userID: String, code: String, name: String, email: String? = nil) async {
        await registerAppleUserID(userID: userID, code: code, name: name, email: email)
    }

    /// Enregistre apple_user_id → code/name/email/categorie sur Make pour lookup cross-device
    private func registerAppleUserID(userID: String, code: String, name: String, email: String? = nil) async {
        var body: [String: String] = [
            "action": "apple_register",
            "apple_user_id": userID,
            "code": code,
            "name": name,
            "categorie": PractitionerTier.from(code: Int(code) ?? 0).rawValue
        ]
        if let email = email { body["email"] = email }
        do {
            var req = URLRequest(url: Self.appleIdentityURL)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            req.timeoutInterval = 10
            let (_, response) = try await URLSession.shared.data(for: req)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("[Identity] apple_register → \(status)")
        } catch {
            print("[Identity] apple_register failed: \(error.localizedDescription)")
        }
    }

    /// Lookup apple_user_id sur Make — retourne code/name ou nil
    private func lookupAppleUserID(userID: String) async -> (code: String, name: String)? {
        let body: [String: String] = [
            "action": "apple_lookup",
            "apple_user_id": userID
        ]
        do {
            var req = URLRequest(url: Self.appleIdentityURL)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            req.timeoutInterval = 8
            let (data, response) = try await URLSession.shared.data(for: req)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard status == 200 else {
                print("[Identity] apple_lookup → \(status), no match")
                return nil
            }
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let code = json["code"] as? String, !code.isEmpty,
               let name = json["name"] as? String, !name.isEmpty {
                print("[Identity] apple_lookup → \(code) (\(name))")
                return (code, name)
            }
        } catch {
            print("[Identity] apple_lookup failed: \(error.localizedDescription)")
        }
        return nil
    }

    func logout() {
        // Disconnect lead presence si c'est un lead
        if tier == .lead {
            let leadId = PresenceService.shared.leadId
            Task { await PresenceService.shared.disconnect(leadId: leadId) }
        }
        code = ""
        displayName = ""
        clientPatientId = ""
        isClientMode = false
        UserDefaults.standard.removeObject(forKey: Self.codeKey)
        UserDefaults.standard.removeObject(forKey: Self.nameKey)
        UserDefaults.standard.removeObject(forKey: Self.clientModeKey)
        UserDefaults.standard.removeObject(forKey: Self.clientPatientIdKey)
        isIdentified = false
    }

    var tier: PractitionerTier {
        PractitionerTier.from(code: Int(code) ?? 0)
    }

    var isSuperviseur: Bool { tier == .superviseur }

    /// Configurer le SessionState avec l'identité
    func applyTo(_ session: SessionState) {
        guard isIdentified, !code.isEmpty else {
            session.role = .unidentified
            return
        }
        let profile = session.shamaneProfiles.first { $0.code == code }
            ?? ShamaneProfile(code: code, prenom: displayName, nom: "",
                              whatsapp: "", email: "", abonnement: "")
        session.role = .shamane(profile)
        // Superviseur : enregistrer son code pour les clés sync
        if profile.tier == .superviseur {
            session.supervisorCode = profile.codeFormatted
        }
    }

    // MARK: - VendorID ↔ Make.com

    private var vendorID: String {
        UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    }

    /// Enregistre vendorID + code + nom sur Make après identification manuelle
    func registerVendorID(code: String, name: String) async {
        let body: [String: String] = [
            "action": "register",
            "vendor_id": vendorID,
            "code": code,
            "name": name
        ]
        do {
            var req = URLRequest(url: Self.identityURL)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            req.timeoutInterval = 10
            let (_, response) = try await URLSession.shared.data(for: req)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("[Identity] register vendorID → \(status)")
        } catch {
            print("[Identity] register vendorID failed: \(error.localizedDescription)")
        }
    }

    /// Tente un auto-login via vendorID au lancement
    func autoIdentify() async {
        guard !isIdentified else { return }
        await MainActor.run { isAutoIdentifying = true }
        defer { Task { @MainActor in isAutoIdentifying = false } }

        let body: [String: String] = [
            "action": "lookup",
            "vendor_id": vendorID
        ]
        do {
            var req = URLRequest(url: Self.identityURL)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            req.timeoutInterval = 8
            let (data, response) = try await URLSession.shared.data(for: req)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard status == 200 else {
                print("[Identity] lookup → \(status), no match")
                return
            }
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let code = json["code"] as? String, !code.isEmpty,
               let name = json["name"] as? String {
                await MainActor.run { identify(code: code, name: name) }
                print("[Identity] autoIdentify → \(code) (\(name))")
            }
        } catch {
            print("[Identity] autoIdentify failed: \(error.localizedDescription)")
        }
    }
}

// ═══════════════════════════════════════════════════════════════════
// MARK: - Session complète
// ═══════════════════════════════════════════════════════════════════

class SessionState: ObservableObject {

    // ── Identifiants session ──
    static let minPatientId = 12

    @Published var patientId: String = "12" { didSet { PatientRegistry.seed(with: patientId) } }
    @Published var sessionNum: String = "001"
    @Published var ratio4D: Double? = nil
    @Published var passeport = Passeport4DData()
    @Published var isSysteme: Bool = false
    @Published var sessionProgramCode: String = "00"  // F30 — "00" = non classifiée, "01" = Recherche
    var sessionId: String { "\(sessionProgramCode)-\(patientId)-\(sessionNum)-\(role.code)" }

    /// PatientId valide : numérique et >= 12
    var isPatientIdValid: Bool {
        guard let n = Int(patientId) else { return false }
        return n >= Self.minPatientId
    }

    // ── Tier actuel ──
    var currentTier: PractitionerTier {
        switch role {
        case .unidentified: return .lead
        case .shamane(let s): return s.tier
        }
    }

    // ── Rôle actif ──
    @Published var role: ActiveRole = .unidentified {
        didSet {
            // F32 — Reset auto quand on switch vers une shamane
            if case .shamane(let p) = role {
                // Reset quand superviseur switch vers un tier inférieur (simulation)
                if oldValue.isSuperviseur && p.tier != .superviseur {
                    resetForShamane()
                }
                patientId = String(max(p.patientId, Self.minPatientId))
            }
            // Adapter le nombre de générations au tier
            rebuildGenerations()
        }
    }
    /// true quand un superviseur simule une shamane (set dans SVLBHTab segment picker)
    var isSuperviseurSimulating: Bool = false
    /// Code du superviseur qui gère cette session (pour les clés shamane pull)
    var supervisorCode: String = "455000"
    @Published var pullSource: ShamaneProfile?

    // ── Scores duaux ──
    @Published var slaTherapist: Int? = nil
    @Published var slaPatrick: Int? = nil
    @Published var scoresTherapist: ScoresLumiere = ScoresLumiere()
    @Published var scoresPatrick: ScoresLumiere = ScoresLumiere()

    // ── Registre shamanes ──
    @Published var shamaneProfiles: [ShamaneProfile] = [] { didSet { saveShamanes() } }
    @Published var researchPrograms: [ResearchProgram] = [] { didSet { savePrograms() } }
    @Published var thematicGroups: [ThematicGroup] = [] { didSet { saveGroups() } }
    @Published var referenceImageSets: [ReferenceImageSet] = [] { didSet { saveImageSets() } }
    @Published var leadSlots: [LeadSlot] = [] { didSet { saveLeadSlots() } }
    @Published var maxActiveLeads: Int = 5 {
        didSet { UserDefaults.standard.set(maxActiveLeads, forKey: "svlbh_max_active_leads") }
    }
    static let defaultMaxActiveLeads = 5

    // ── Données session ──
    @Published var generations: [Generation] = []
    @Published var pierres: [PierreState] = pierresReference.map { PierreState(spec: $0) }
    @Published var chakraStates: [String: Bool] = [:]
    @Published var sugChakraStates: [String: Bool] = [:]
    // F16 — CIM-11 sélectionnés par chakra
    @Published var selectedCIM: [String: Set<String>] = [:]
    @Published var porteSelections: [String: Int] = [:]  // chakraKey_temp / chakraKey_perm → numero porte
    // D22 — Programmes de Protection sélectionnés (id programme → true)
    @Published var programmeProtectionSelections: Set<String> = []
    @Published var syncStatus: String = "🔴 Off"
    @Published var lastPin: String = ""
    private var cancellables = Set<AnyCancellable>()

    // Cache pour visibleGenerations (évite filtre+sort à chaque render)
    @Published private(set) var visibleGenerations: [Generation] = []

    // ── Init ──
    init() {
        // Créer uniquement les générations nécessaires au tier (défaut: superviseur = 100)
        generations = (1...currentTier.maxGenerations).map { Generation(n: $0) }
        visibleGenerations = generations.sorted(by: { $0.id > $1.id })
        chakraStates = initialChakraStates()
        loadShamanes()
        loadPrograms()
        loadGroups()
        loadImageSets()
        loadLeadSlots()
        let savedMax = UserDefaults.standard.integer(forKey: "svlbh_max_active_leads")
        if savedMax > 0 { maxActiveLeads = savedMax }
        subscribeToPierres()
    }

    /// Propager les changements de chaque PierreState vers SessionState
    private func subscribeToPierres() {
        for p in pierres {
            p.objectWillChange
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in self?.objectWillChange.send() }
                .store(in: &cancellables)
        }
    }

    /// Notifier SwiftUI manuellement (appeler après modification d'une Generation/Pierre)
    func notifyChange() { objectWillChange.send() }

    /// Reconstruire les générations après changement de tier
    func rebuildGenerations() {
        let needed = currentTier.maxGenerations
        if generations.count < needed {
            let existing = Set(generations.map(\.id))
            for n in 1...needed where !existing.contains(n) {
                generations.append(Generation(n: n))
            }
        }
        visibleGenerations = generations.filter { $0.id <= needed }.sorted(by: { $0.id > $1.id })
    }

    // ── Clés sync ──
    var pushKey: String {
        // Superviseur simulant une shamane → déposer sous clé superviseur
        // (car la shamane pull toujours avec supervisorCode)
        if isSuperviseurSimulating {
            return "\(sessionProgramCode)-\(patientId)-\(sessionNum)-\(supervisorCode)"
        }
        return sessionId
    }

    var pullKey: String {
        if role.isOwner, let src = pullSource {
            // Owner pull depuis une shamane
            return "\(sessionProgramCode)-\(patientId)-\(sessionNum)-\(src.codeFormatted)"
        } else if role.isOwner {
            // Owner self-pull (pas de pullSource)
            return sessionId
        } else {
            // Tous les autres (shamanes, superviseurs) pullent depuis l'owner
            return "\(sessionProgramCode)-\(patientId)-\(sessionNum)-\(supervisorCode)"
        }
    }

    // ── Compteurs ──
    var validatedCount: Int { visibleGenerations.filter(\.validated).count }
    var selectedPierresCount: Int { pierres.filter(\.selected).count }
    var selectedPierres: [PierreState] { pierres.filter(\.selected) }
    var cleanedChakrasCount: Int { chakraStates.values.filter { $0 }.count }
    var totalChakras: Int { allDimensions.flatMap(\.chakras).count }
    var totalClassicChakras: Int { allDimensions.filter { $0.id != "d0" }.flatMap(\.chakras).count }
    var cleanedClassicCount: Int {
        let classicKeys = allDimensions.filter { $0.id != "d0" }.flatMap { $0.allKeys }
        return classicKeys.filter { chakraStates[$0] == true }.count
    }

    // ── Actions session ──
    func incrementSession() {
        sessionNum = String(format: "%03d", (Int(sessionNum) ?? 0) + 1)
    }

    func createNewPatient() {
        patientId = PatientRegistry.consume()
        sessionNum = "001"
        slaTherapist = nil; slaPatrick = nil
    }

    /// F32 — Reset session pour shamane (sessionNum = 001, données vierges)
    func resetForShamane() {
        sessionNum = "001"
        slaTherapist = nil; slaPatrick = nil
        scoresTherapist = ScoresLumiere(); scoresPatrick = ScoresLumiere()
        for g in generations { g.abuseur = ""; g.victime = ""; g.phases = []; g.gu = []; g.meridiens = []; g.statuts = []; g.validated = false; g.clearSuggestions() }
        for p in pierres { p.selected = false; p.validated = false; p.volume = 1; p.unit = "kg"; p.durationMin = 30; p.durationDays = p.spec.defaultDays; p.clearSuggestions() }
        chakraStates = initialChakraStates(); sugChakraStates = [:]; selectedCIM = [:]; programmeProtectionSelections = []
        rebuildGenerations()
    }

    // ── CRUD Shamanes ──

    func addShamane(prenom: String, nom: String = "", whatsapp: String = "",
                    email: String = "", abonnement: String = "",
                    prochainFacturation: Date? = nil,
                    tier: PractitionerTier = .lead) -> ShamaneProfile {
        let s = ShamaneProfile(
            code: ShamaneProfile.nextCode(tier: tier, existing: shamaneProfiles),
            prenom: prenom, nom: nom, whatsapp: whatsapp, email: email,
            abonnement: abonnement, prochainFacturation: prochainFacturation)
        shamaneProfiles.append(s)
        return s
    }

    func removeShamane(_ s: ShamaneProfile) { shamaneProfiles.removeAll { $0.code == s.code } }

    func updateShamane(_ updated: ShamaneProfile) {
        guard let idx = shamaneProfiles.firstIndex(where: { $0.code == updated.code }) else { return }
        shamaneProfiles[idx] = updated
    }

    var shamanesCertifiees: [ShamaneProfile] { shamaneProfiles.filter { $0.tier == .certifiee } }

    // ── Broadcast ciblé ──

    func broadcastKeys(target: BroadcastTarget = .allCertifiees) -> [String] {
        let recipients = shamanes(for: target)
        guard !recipients.isEmpty else { return [] }
        return [pushKey]
    }

    func shamanes(for target: BroadcastTarget) -> [ShamaneProfile] {
        switch target {
        case .allCertifiees:    return shamanesCertifiees
        case .program(let p):   return shamaneProfiles.filter { p.shamaneCodes.contains($0.code) }
        case .group(let g):     return shamaneProfiles.filter { g.shamaneCodes.contains($0.code) }
        }
    }

    // ── CRUD Programmes ──

    func addProgram(nom: String, programCode: String = "01") -> ResearchProgram {
        let p = ResearchProgram(id: UUID().uuidString, nom: nom, programCode: programCode)
        researchPrograms.append(p); return p
    }

    func removeProgram(_ p: ResearchProgram) { researchPrograms.removeAll { $0.id == p.id } }

    func addShamaneToProgram(shamaneCode: String, programId: String) {
        guard let idx = researchPrograms.firstIndex(where: { $0.id == programId }) else { return }
        if !researchPrograms[idx].shamaneCodes.contains(shamaneCode) {
            researchPrograms[idx].shamaneCodes.append(shamaneCode)
        }
    }

    func removeShamaneFromProgram(shamaneCode: String, programId: String) {
        guard let idx = researchPrograms.firstIndex(where: { $0.id == programId }) else { return }
        researchPrograms[idx].shamaneCodes.removeAll { $0 == shamaneCode }
    }

    // ── CRUD Groupes ──

    func addGroup(nom: String) -> ThematicGroup {
        let g = ThematicGroup(id: UUID().uuidString, nom: nom)
        thematicGroups.append(g); return g
    }

    func removeGroup(_ g: ThematicGroup) { thematicGroups.removeAll { $0.id == g.id } }

    func addShamaneToGroup(shamaneCode: String, groupId: String) {
        guard let idx = thematicGroups.firstIndex(where: { $0.id == groupId }) else { return }
        if !thematicGroups[idx].shamaneCodes.contains(shamaneCode) {
            thematicGroups[idx].shamaneCodes.append(shamaneCode)
        }
    }

    func removeShamaneFromGroup(shamaneCode: String, groupId: String) {
        guard let idx = thematicGroups.firstIndex(where: { $0.id == groupId }) else { return }
        thematicGroups[idx].shamaneCodes.removeAll { $0 == shamaneCode }
    }

    func programs(for shamaneCode: String) -> [ResearchProgram] {
        researchPrograms.filter { $0.shamaneCodes.contains(shamaneCode) }
    }

    func groups(for shamaneCode: String) -> [ThematicGroup] {
        thematicGroups.filter { $0.shamaneCodes.contains(shamaneCode) }
    }

    // ── F01 — Leads cap ──

    var activeLeadCount: Int { leadSlots.filter { $0.status == .active }.count }
    var waitingLeads: [LeadSlot] { leadSlots.filter { $0.status == .waiting } }
    var canAcceptLead: Bool { activeLeadCount < maxActiveLeads }

    func receiveLead(shamaneCode: String) {
        guard !leadSlots.contains(where: { $0.shamaneCode == shamaneCode }) else { return }
        let status: LeadStatus = canAcceptLead ? .active : .waiting
        leadSlots.append(LeadSlot(shamaneCode: shamaneCode, status: status))
    }

    func activateLead(shamaneCode: String) {
        guard canAcceptLead,
              let idx = leadSlots.firstIndex(where: { $0.shamaneCode == shamaneCode && $0.status == .waiting })
        else { return }
        leadSlots[idx].status = .active
    }

    func completeLead(shamaneCode: String) {
        guard let idx = leadSlots.firstIndex(where: { $0.shamaneCode == shamaneCode }) else { return }
        leadSlots[idx].status = .completed
    }

    // ── CRUD Systèmes de référence (images) ──

    func addImageSet(nom: String, description: String = "", fileNames: [String] = []) -> ReferenceImageSet {
        let s = ReferenceImageSet(id: UUID().uuidString, nom: nom, description: description, imageFileNames: fileNames)
        referenceImageSets.append(s); return s
    }

    func removeImageSet(_ s: ReferenceImageSet) { referenceImageSets.removeAll { $0.id == s.id } }

    func updateImageSet(_ updated: ReferenceImageSet) {
        guard let idx = referenceImageSets.firstIndex(where: { $0.id == updated.id }) else { return }
        referenceImageSets[idx] = updated
    }

    func addImageToSet(fileName: String, setId: String) {
        guard let idx = referenceImageSets.firstIndex(where: { $0.id == setId }) else { return }
        if !referenceImageSets[idx].imageFileNames.contains(fileName) {
            referenceImageSets[idx].imageFileNames.append(fileName)
        }
    }

    func removeImageFromSet(fileName: String, setId: String) {
        guard let idx = referenceImageSets.firstIndex(where: { $0.id == setId }) else { return }
        referenceImageSets[idx].imageFileNames.removeAll { $0 == fileName }
    }

    // ── Persistence ──

    private func saveShamanes() {
        if let data = try? JSONEncoder().encode(shamaneProfiles) {
            UserDefaults.standard.set(data, forKey: "svlbh_shamanes")
        }
    }
    // F28 — Migration codes v3 → v4.0.0 (inclut artefacts iPad)
    private static let codesMigration: [String: String] = [
        "25": "300",      // Cornelia v3
        "2501": "300",    // Cornelia artefact iPad
        "0300": "300",    // Cornelia padded
        "27": "301",      // Flavia v3
        "26": "302",      // Anne v3
        "01": "455000",   // Patrick v3
        "2601": "302",    // Anne artefact
        "2701": "301",    // Flavia artefact
        "103": "304",     // Irène formation → certifiée
        "22": "0303",     // Chloé lead → certifiée
        "21": "200",      // Véronique lead → formation
    ]

    private func loadShamanes() {
        if let data = UserDefaults.standard.data(forKey: "svlbh_shamanes"),
           var list = try? JSONDecoder().decode([ShamaneProfile].self, from: data) {
            // F28 — Migration anciens codes au premier lancement 4.0.0
            var migrated = false
            for i in list.indices {
                if let newCode = Self.codesMigration[list[i].code] {
                    print("[F28] Migration code \(list[i].code) → \(newCode)")
                    list[i].code = newCode
                    migrated = true
                }
            }
            shamaneProfiles = list
            if migrated { saveShamanes() }
        } else if let old = UserDefaults.standard.data(forKey: "svlbh_certified"),
                  let oldList = try? JSONDecoder().decode([LegacyCertifiedTherapist].self, from: old) {
            shamaneProfiles = oldList.map {
                let code = Self.codesMigration[$0.code] ?? $0.code
                return ShamaneProfile(code: code, prenom: $0.name, nom: "",
                               whatsapp: "", email: "", abonnement: "",
                               prochainFacturation: nil)
            }
        } else {
            // F28 — Defaults v4.2.11
            shamaneProfiles = [
                ShamaneProfile(code: "300", prenom: "Cornelia", nom: "",
                               whatsapp: "", email: "", abonnement: ""),
                ShamaneProfile(code: "301", prenom: "Flavia", nom: "",
                               whatsapp: "", email: "", abonnement: ""),
                ShamaneProfile(code: "302", prenom: "Anne", nom: "",
                               whatsapp: "", email: "", abonnement: ""),
                ShamaneProfile(code: "303", prenom: "Chloé", nom: "",
                               whatsapp: "", email: "", abonnement: "",
                               programmes: [.mySha, .protection]),
                ShamaneProfile(code: "200", prenom: "Véronique", nom: "",
                               whatsapp: "", email: "", abonnement: "Formation"),
                ShamaneProfile(code: "304", prenom: "Irène", nom: "Bays-Marion",
                               whatsapp: "", email: "", abonnement: "Certifiée",
                               programmes: [.myShaFa]),
                ShamaneProfile(code: "455000", prenom: "Patrick", nom: "Bays",
                               whatsapp: "", email: "", abonnement: "Superviseur"),
                ShamaneProfile(code: "754545", prenom: "Patrick", nom: "Bays",
                               whatsapp: "", email: "bays.patrick@icloud.com", abonnement: "Protection",
                               programmes: [.protection]),
            ]
        }
    }

    private func savePrograms() {
        if let data = try? JSONEncoder().encode(researchPrograms) {
            UserDefaults.standard.set(data, forKey: "svlbh_programs")
        }
    }
    private func loadPrograms() {
        if let data = UserDefaults.standard.data(forKey: "svlbh_programs"),
           let list = try? JSONDecoder().decode([ResearchProgram].self, from: data) {
            researchPrograms = list
        } else {
            researchPrograms = ResearchProgram.defaults
        }
    }

    private func saveGroups() {
        if let data = try? JSONEncoder().encode(thematicGroups) {
            UserDefaults.standard.set(data, forKey: "svlbh_groups")
        }
    }
    private func loadGroups() {
        if let data = UserDefaults.standard.data(forKey: "svlbh_groups"),
           let list = try? JSONDecoder().decode([ThematicGroup].self, from: data) {
            thematicGroups = list
        }
    }

    private func saveImageSets() {
        if let data = try? JSONEncoder().encode(referenceImageSets) {
            UserDefaults.standard.set(data, forKey: "svlbh_imagesets")
        }
    }
    private func loadImageSets() {
        if let data = UserDefaults.standard.data(forKey: "svlbh_imagesets"),
           let list = try? JSONDecoder().decode([ReferenceImageSet].self, from: data) {
            referenceImageSets = list
        }
    }

    private func saveLeadSlots() {
        if let data = try? JSONEncoder().encode(leadSlots) {
            UserDefaults.standard.set(data, forKey: "svlbh_leads")
        }
    }
    private func loadLeadSlots() {
        if let data = UserDefaults.standard.data(forKey: "svlbh_leads"),
           let list = try? JSONDecoder().decode([LeadSlot].self, from: data) {
            leadSlots = list
        }
    }
}
