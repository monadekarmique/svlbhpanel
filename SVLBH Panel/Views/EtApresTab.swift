// SVLBHPanel — Views/EtApresTab.swift
// v2.7.0 — Landing auto-soin : Rose des Vents, Palette chromo, science, outils, parcours, Cercles de Lumieres, FAQ

import SwiftUI

// MARK: - Data Models

struct RoseDirection: Identifiable {
    let id: Int
    let label: String
    let abbr: String
    let element: String
    let saison: String
    let organe: String
    let theme: String
    let colorId: String
}

struct ChromoColor: Identifiable {
    let id: String
    let hex: String
    let name: String
    let dimension: String
    let usage: String
    let how: String
}

struct ToolItem: Identifiable {
    let id = UUID()
    let status: String
    let statusClass: ToolStatusClass
    let title: String
    let subtitle: String
    let description: String
}

enum ToolStatusClass {
    case live, seance, seanceDeep

    var badgeBg: Color {
        switch self {
        case .live: Color(hex: "#8B3A62")
        case .seance: Color(hex: "#E5D4A8")
        case .seanceDeep: Color(hex: "#E9CFD8")
        }
    }

    var badgeFg: Color {
        switch self {
        case .live: Color(hex: "#FDFAF4")
        case .seance, .seanceDeep: Color(hex: "#4A1528")
        }
    }
}

struct MechanismItem: Identifiable {
    let id: String
    let title: String
    let body: String
    let citation: String?
}

struct TierItem: Identifiable {
    let id: String
    let title: String
    let access: String
    let borderColor: Color
    let features: [String]
    let price: String
    let priceNote: String
}

struct TherapistItem: Identifiable {
    let id = UUID()
    let initials: String
    let name: String
    let specialty: String
    let description: String
    let accent: Color
}

struct FAQItemData: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

struct ProgressIndicator: Identifiable {
    let id: String
    let text: String
    let note: String?
}

// MARK: - Static Data

private let roseDirections: [RoseDirection] = [
    .init(id: 0, label: "Nord", abbr: "N", element: "Eau", saison: "Hiver", organe: "Reins", theme: "Peur, volont\u{00e9} profonde, ce qui se conserve sous la glace", colorId: "bleu"),
    .init(id: 1, label: "Nord-Nord-Est", abbr: "NNE", element: "Eau \u{2192} Bois", saison: "Fin d\u{2019}hiver", organe: "Reins-Foie", theme: "Germination silencieuse, force cach\u{00e9}e qui s\u{2019}appr\u{00ea}te", colorId: "indigo"),
    .init(id: 2, label: "Nord-Est", abbr: "NE", element: "Bois naissant", saison: "D\u{00e9}but printemps", organe: "V\u{00e9}sicule Biliaire", theme: "D\u{00e9}cision, impulsion, le geste qui tranche", colorId: "vert"),
    .init(id: 3, label: "Est", abbr: "E", element: "Bois", saison: "Printemps", organe: "Foie", theme: "Col\u{00e8}re juste, vision, croissance affirm\u{00e9}e", colorId: "vert"),
    .init(id: 4, label: "Est-Sud-Est", abbr: "ESE", element: "Bois \u{2192} Feu", saison: "Fin printemps", organe: "Foie-C\u{0153}ur", theme: "\u{00c9}lan, passage \u{00e0} l\u{2019}action, la s\u{00e8}ve monte", colorId: "orange"),
    .init(id: 5, label: "Sud-Sud-Est", abbr: "SSE", element: "Feu naissant", saison: "D\u{00e9}but \u{00e9}t\u{00e9}", organe: "P\u{00e9}ricarde", theme: "Ouverture du c\u{0153}ur, joie qui s\u{2019}annonce", colorId: "rose"),
    .init(id: 6, label: "Sud", abbr: "S", element: "Feu", saison: "\u{00c9}t\u{00e9}", organe: "C\u{0153}ur", theme: "Joie pleine, expression, rayonnement", colorId: "rouge"),
    .init(id: 7, label: "Sud-Sud-Ouest", abbr: "SSW", element: "Feu \u{2192} Terre", saison: "Fin \u{00e9}t\u{00e9}", organe: "Intestin gr\u{00ea}le", theme: "Discernement, tri des essences, ce qui nourrit", colorId: "orange"),
    .init(id: 8, label: "Sud-Ouest", abbr: "SW", element: "Terre", saison: "Inter-saisons", organe: "Rate-Pancr\u{00e9}as", theme: "Souci, rumination, besoin d\u{2019}ancrage", colorId: "or"),
    .init(id: 9, label: "Ouest", abbr: "W", element: "M\u{00e9}tal", saison: "Automne", organe: "Poumons", theme: "Tristesse, deuil, l\u{00e2}cher-prise, l\u{2019}air devient pr\u{00e9}cieux", colorId: "blanc"),
    .init(id: 10, label: "Ouest-Nord-Ouest", abbr: "WNW", element: "M\u{00e9}tal", saison: "Fin automne", organe: "Gros Intestin", theme: "\u{00c9}vacuation, purification, ce qui doit partir", colorId: "blanc"),
    .init(id: 11, label: "Nord-Nord-Ouest", abbr: "NNW", element: "M\u{00e9}tal \u{2192} Eau", saison: "Pr\u{00e9}-hiver", organe: "Poumons-Reins", theme: "Recueillement, retour sur soi, la bougie int\u{00e9}rieure", colorId: "violet")
]

private let chromoColors: [ChromoColor] = [
    .init(id: "rouge", hex: "#C53030", name: "Rouge", dimension: "Feu \u{2014} C\u{0153}ur", usage: "Vitalit\u{00e9}, ancrage, courage", how: "Portez cette couleur un matin sans \u{00e9}lan. Visualisez-la au centre de la poitrine, trois inspirations."),
    .init(id: "orange", hex: "#FF923D", name: "Orange", dimension: "Feu-Terre \u{2014} Vitalit\u{00e9} matinale", usage: "Stimulation douce, cr\u{00e9}ativit\u{00e9}, optimisme", how: "Activation matinale, redynamisation. Entourez-vous d\u{2019}un objet orange visible depuis votre poste."),
    .init(id: "or", hex: "#B8965A", name: "Or", dimension: "Terre \u{2014} Rate & lign\u{00e9}es", usage: "Confiance, ancrage, sagesse transg\u{00e9}n\u{00e9}rationnelle", how: "Contre la rumination. Visualisez un disque d\u{2019}or \u{00e0} hauteur du plexus solaire pendant cinq minutes."),
    .init(id: "vert", hex: "#66B032", name: "Vert", dimension: "Bois \u{2014} Foie", usage: "R\u{00e9}g\u{00e9}n\u{00e9}ration h\u{00e9}patique, d\u{00e9}toxification, \u{00e9}quilibre", how: "Visualisation de lumi\u{00e8}re verte enveloppant le foie, 15 min matin et soir."),
    .init(id: "turquoise", hex: "#25AD81", name: "Bleu-Vert", dimension: "Bois-Eau \u{2014} Apaisement", usage: "Calme la col\u{00e8}re h\u{00e9}patique, harmonise le syst\u{00e8}me nerveux", how: "Respiration color\u{00e9}e, bains de lumi\u{00e8}re. Visualiser en apaisant la col\u{00e8}re."),
    .init(id: "bleu", hex: "#2F6FB5", name: "Bleu", dimension: "Eau \u{2014} Reins", usage: "Apaisement, profondeur, \u{00e9}coute int\u{00e9}rieure", how: "Pour le sommeil, la peur, l\u{2019}\u{00e9}puisement. Visualisez au niveau du bas du dos, allong\u{00e9}\u{00b7}e."),
    .init(id: "indigo", hex: "#798EF6", name: "Violet-Bleu", dimension: "Transformation spirituelle", usage: "Transmutation des m\u{00e9}moires, \u{00e9}l\u{00e9}vation vibratoire, flamme violette", how: "Rituel de lib\u{00e9}ration. Visualisez une flamme violette consumant ce qui doit partir."),
    .init(id: "violet", hex: "#7B5AB8", name: "Violet", dimension: "Couronne \u{2014} Connexion", usage: "\u{00c9}l\u{00e9}vation, spiritualit\u{00e9}, recueillement", how: "En fin de journ\u{00e9}e, pour laisser retomber. Visualisez une coupole au-dessus de la t\u{00ea}te."),
    .init(id: "rose", hex: "#D4618F", name: "Rose", dimension: "C\u{0153}ur \u{2014} Tendresse", usage: "Amour de soi, douceur, pardon intime", how: "Apr\u{00e8}s une peine. Posez les mains sur la poitrine, rose chaud sous les paumes."),
    .init(id: "blanc", hex: "#F0EBE2", name: "Blanc perl\u{00e9}", dimension: "M\u{00e9}tal \u{2014} Poumons", usage: "Purification, nouveau souffle, l\u{00e2}cher-prise", how: "Ouvrez une fen\u{00ea}tre, portez un v\u{00ea}tement clair, respirez profond\u{00e9}ment sept fois."),
    .init(id: "noir-profond", hex: "#1E2A3D", name: "Bleu nuit", dimension: "Hara \u{2014} Ancrage profond", usage: "Stabilit\u{00e9}, silence fertile, recentrage", how: "Asseyez-vous dans l\u{2019}obscurit\u{00e9} trois minutes. Laissez les pens\u{00e9}es passer sans les suivre."),
    .init(id: "rose-poudre", hex: "#C27894", name: "Rose poudr\u{00e9}", dimension: "Lign\u{00e9}e f\u{00e9}minine \u{2014} Anc\u{00ea}tres", usage: "R\u{00e9}conciliation transg\u{00e9}n\u{00e9}rationnelle", how: "\u{00c9}crivez une lettre \u{00e0} une grand-m\u{00e8}re (m\u{00ea}me inconnue). Rangez-la dans du tissu rose.")
]

private let dirToColorId: [Int: String] = [
    0: "bleu", 1: "indigo", 2: "vert", 3: "vert", 4: "orange",
    5: "rose", 6: "rouge", 7: "orange", 8: "or", 9: "blanc",
    10: "blanc", 11: "violet"
]

private let toolItems: [ToolItem] = [
    .init(status: "D\u{00e9}mo disponible", statusClass: .live, title: "Johrei_25 \u{2014} Rose des Vents", subtitle: "Diagnostic directionnel Hara", description: "Douze directions pour localiser o\u{00f9} se loge aujourd\u{2019}hui la tension, l\u{2019}\u{00e9}motion, la m\u{00e9}moire."),
    .init(status: "D\u{00e9}mo disponible", statusClass: .live, title: "Palette de Lumi\u{00e8}re", subtitle: "Chromoth\u{00e9}rapie interactive", description: "La couleur qui r\u{00e9}harmonise. Usage quotidien, sans mat\u{00e9}riel."),
    .init(status: "S\u{00e9}ance & PWA", statusClass: .seance, title: "Scores de Lumi\u{00e8}re", subtitle: "SLA \u{00b7} SLSA \u{00b7} SLM", description: "Lecture quantifi\u{00e9}e de l\u{2019}\u{00e9}tat \u{00e9}nerg\u{00e9}tique. Suivi de la progression dans le temps."),
    .init(status: "S\u{00e9}ance & PWA", statusClass: .seance, title: "Cartes Wu Shen", subtitle: "Les Cinq Esprits \u{2014} MTC", description: "Lecture de l\u{2019}\u{00e9}motion dominante et de l\u{2019}organe associ\u{00e9}, selon la MTC."),
    .init(status: "S\u{00e9}ance & PWA", statusClass: .seance, title: "Sephiroth \u{2014} Code 3 Chiffres", subtitle: "Lecture kabbalistique", description: "Trois chiffres qui ouvrent une lecture sur l\u{2019}Arbre de Vie."),
    .init(status: "R\u{00e9}serv\u{00e9} s\u{00e9}ance", statusClass: .seanceDeep, title: "Protocole de S\u{00e9}ance", subtitle: "Trame adapt\u{00e9}e au quotidien", description: "Le squelette de nos consultations, transmis pour devenir votre pratique personnelle.")
]

private let mechanisms: [MechanismItem] = [
    .init(id: "01", title: "D\u{00e9}sactivation de l\u{2019}amygdale", body: "Les recherches en imagerie c\u{00e9}r\u{00e9}brale (IRMf, TEP) men\u{00e9}es \u{00e0} Harvard Medical School ont montr\u{00e9} que la stimulation de points d\u{2019}acupuncture produit une d\u{00e9}sactivation \u{00e9}tendue de l\u{2019}amygdale et du syst\u{00e8}me limbique.", citation: nil),
    .init(id: "02", title: "Ondes delta et d\u{00e9}potentialisation", body: "Le tapotement r\u{00e9}p\u{00e9}t\u{00e9} g\u{00e9}n\u{00e8}re des ondes delta de grande amplitude dans les zones qui h\u{00e9}bergent les souvenirs de peur \u{2014} le syst\u{00e8}me naturel d\u{2019}\u{00e9}dition de la m\u{00e9}moire actif pendant le sommeil profond.", citation: "\u{00ab} Les r\u{00e9}cepteurs du glutamate sur les synapses qui m\u{00e9}dient une m\u{00e9}moire de peur sont d\u{00e9}potentialis\u{00e9}s par ces puissantes vagues de d\u{00e9}charge neuronale. \u{00bb} \u{2014} Feinstein, 2012"),
    .init(id: "03", title: "Fen\u{00ea}tre de reconsolidation", body: "Apr\u{00e8}s qu\u{2019}une m\u{00e9}moire \u{00e9}motionnelle est rappel\u{00e9}e, elle peut \u{00ea}tre reconsolid\u{00e9}e autrement pendant plusieurs heures. L\u{2019}auto-soin outill\u{00e9} utilise cette fen\u{00ea}tre \u{2014} le souvenir est \u{00e9}voqu\u{00e9} en m\u{00ea}me temps que le syst\u{00e8}me nerveux est apais\u{00e9}.", citation: nil)
]

private let tierItems: [TierItem] = [
    .init(id: "I", title: "Essentiel", access: "Gratuit", borderColor: Color(hex: "#C0DD97"),
          features: ["Johrei_25 \u{2014} d\u{00e9}mo compl\u{00e8}te", "Palette de Lumi\u{00e8}re \u{2014} d\u{00e9}mo compl\u{00e8}te", "Newsletter mensuelle", "Articles piliers"],
          price: "Libre", priceNote: "Aucune inscription requise"),
    .init(id: "II", title: "Praticien autonome", access: "PWA \u{2014} Abonnement", borderColor: Color(hex: "#B8965A"),
          features: ["Acc\u{00e8}s aux six outils", "Scores de Lumi\u{00e8}re avec historique", "Cartes Wu Shen & Sephiroth", "Sauvegarde et suivi dans le temps"],
          price: "Tarif mensuel", priceNote: "Sur la PWA vlbh.energy"),
    .init(id: "III", title: "Accompagnement", access: "S\u{00e9}ance \u{2014} payante", borderColor: Color(hex: "#8B3A62"),
          features: ["D\u{00e9}couverte \u{2014} 1h15", "Individuelle \u{2014} 2h", "Constellation \u{2014} 3h30", "Transmission du Protocole"],
          price: "Sur demande", priceNote: "Tarifs \u{00e0} la r\u{00e9}servation"),
    .init(id: "IV", title: "Formation praticien", access: "Sur invitation", borderColor: Color(hex: "#4A1528"),
          features: ["Application SVLBHPanel iOS", "Formation compl\u{00e8}te au cadre hDOM", "Supervision et communaut\u{00e9}", "Outils de travail Gui \u{9b3c}"],
          price: "Cursus d\u{00e9}di\u{00e9}", priceNote: "Entretien pr\u{00e9}alable")
]

private let therapists: [TherapistItem] = [
    .init(initials: "CA", name: "Cornelia Althaus", specialty: "Yoga de l\u{2019}\u{00e9}nergie \u{00b7} R\u{00e9}flexo radiesth-\u{00e9}sique", description: "Co-fondatrice du cabinet d\u{2019}Avenches. Pratique corporelle et \u{00e9}nerg\u{00e9}tique \u{2014} Chi Nei Tsang, Zero Balancing.", accent: Color(hex: "#C27894")),
    .init(initials: "FB", name: "Flavia", specialty: "M\u{00e9}moires abdominales", description: "Th\u{00e9}rapeute certifi\u{00e9}e Cercles de Lumi\u{00e8}res, bas\u{00e9}e en Italie. Vibration solaire, chaleur m\u{00e9}diterran\u{00e9}enne.", accent: Color(hex: "#B8965A")),
    .init(initials: "AN", name: "Anne", specialty: "Lign\u{00e9}e f\u{00e9}minine", description: "Th\u{00e9}rapeute certifi\u{00e9}e Cercles de Lumi\u{00e8}res. Travaux de lign\u{00e9}e f\u{00e9}minine et transformation personnelle.", accent: Color(hex: "#25AD81"))
]

private let faqItems: [FAQItemData] = [
    .init(question: "Ai-je besoin de croire \u{00e0} ce cadre pour que les outils fonctionnent ?",
          answer: "Non. Les outils reposent sur des correspondances h\u{00e9}rit\u{00e9}es de traditions mill\u{00e9}naires \u{2014} MTC, Kabbale \u{2014} et produisent leurs effets par la r\u{00e9}gularit\u{00e9} de la pratique. Une curiosit\u{00e9} ouverte suffit."),
    .init(question: "La psychologie \u{00e9}nerg\u{00e9}tique est-elle reconnue scientifiquement ?",
          answer: "Oui, de plus en plus. Une revue de 51 articles \u{00e0} comit\u{00e9} de lecture a montr\u{00e9} des r\u{00e9}sultats positifs dans 100 % des cas. Les scores de TSPT sont pass\u{00e9}s sous les seuils cliniques apr\u{00e8}s une seule s\u{00e9}ance."),
    .init(question: "Est-ce compatible avec un suivi m\u{00e9}dical ?",
          answer: "Enti\u{00e8}rement. Nos outils sont un compl\u{00e9}ment, jamais un substitut. Si vous suivez une th\u{00e9}rapie ou un traitement m\u{00e9}dical, continuez-le."),
    .init(question: "Pourquoi les s\u{00e9}ances ne sont-elles jamais gratuites ?",
          answer: "L\u{2019}\u{00e9}change \u{00e9}nerg\u{00e9}tique est au c\u{0153}ur de notre cadre. Le paiement \u{00e9}tablit le cadre qui permet au travail d\u{2019}avoir lieu. Les outils gratuits du Tier I \u{00e9}chappent \u{00e0} ce principe parce qu\u{2019}ils vous mettent en position d\u{2019}acteur."),
    .init(question: "Qu\u{2019}est-ce qui diff\u{00e9}rencie l\u{2019}approche hDOM ?",
          answer: "L\u{2019}int\u{00e9}gration (MTC, Kabbale, g\u{00e9}om\u{00e9}trie sacr\u{00e9}e, radiesthesie, chromoth\u{00e9}rapie), l\u{2019}outillage (dispositifs concrets, reproductibles), et la pr\u{00e9}cision (9 dimensions \u{00d7} 33 chakras, 12 directions Hara)."),
    .init(question: "Combien de temps avant de percevoir un changement ?",
          answer: "Variable. Certaines personnes notent un apaisement d\u{00e8}s la premi\u{00e8}re utilisation. La r\u{00e9}gularit\u{00e9} compte davantage que l\u{2019}intensit\u{00e9}\u{00a0}: deux minutes chaque matin donnent plus qu\u{2019}une heure occasionnelle.")
]

private let progressIndicators: [ProgressIndicator] = [
    .init(id: "01", text: "Am\u{00e9}lioration du sommeil", note: "Premier effet constat\u{00e9}"),
    .init(id: "02", text: "Diminution des c\u{00e9}phal\u{00e9}es et tensions", note: nil),
    .init(id: "03", text: "\u{00c9}quilibre \u{00e9}motionnel restaur\u{00e9}", note: nil),
    .init(id: "04", text: "Sentiment de l\u{00e9}g\u{00e8}ret\u{00e9} et paix int\u{00e9}rieure", note: nil),
    .init(id: "05", text: "Clart\u{00e9} mentale accrue", note: nil),
    .init(id: "06", text: "Vitalit\u{00e9} et joie de vivre retrouv\u{00e9}es", note: nil)
]

// MARK: - Design Tokens

private enum Tok {
    static let plum = Color(hex: "#8B3A62")
    static let plumDark = Color(hex: "#4A1528")
    static let rose = Color(hex: "#C27894")
    static let rosePale = Color(hex: "#E9CFD8")
    static let sable = Color(hex: "#F5EDE4")
    static let sableDark = Color(hex: "#EADFC9")
    static let or = Color(hex: "#B8965A")
    static let orPale = Color(hex: "#E5D4A8")
    static let blancChaud = Color(hex: "#FDFAF4")
    static let ivoire = Color(hex: "#F9F3E8")
    static let textPrimary = Color(hex: "#2C1F2A")
    static let textSecondary = Color(hex: "#5A4550")
    static let textMuted = Color(hex: "#8A7A83")
}

// MARK: - Tab principal

struct EtApresTab: View {
    @EnvironmentObject var session: SessionState
    @State private var activeDir: Int?
    @State private var activeColor: Int?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    heroSection
                    manifestoSection
                    mechanismsSection
                    instrumentariumSection
                    roseDesVentsSection
                    paletteSection
                    tiersSection
                    cerclesDeLumieresSection
                    constellationSection
                    progressSection
                    faqSection
                    signatureSection
                    footerSection
                }
            }
            .background(Tok.blancChaud)
            .navigationTitle("Et apr\u{00e8}s ?")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 16) {
            Link(destination: URL(string: "https://wa.me/41798131926?text=Bonjour%2C%20je%20souhaite%20lib%C3%A9rer%20mes%20m%C3%A9moires%20transg%C3%A9n%C3%A9rationnelles")!) {
                Text("Lib\u{00e8}re tes m\u{00e9}moires transg\u{00e9}n\u{00e9}rationnelles")
                    .font(.callout.weight(.semibold))
                    .foregroundColor(Tok.blancChaud)
                    .padding(.horizontal, 24).padding(.vertical, 12)
                    .background(Tok.plum)
                    .cornerRadius(24)
            }
            .padding(.top, 32)

            Text("Lib\u{00e9}rer les m\u{00e9}moires ne se d\u{00e9}cr\u{00e8}te pas.\nCela se ")
            + Text("pratique").italic().foregroundColor(Tok.plum)
            + Text(", avec les bons outils.")
        }
        .font(.title2.weight(.medium))
        .foregroundColor(Tok.plumDark)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        // Subtitle
        .overlay(alignment: .bottom) {
            VStack(spacing: 10) {
                Text("Digital Shaman Lab con\u{00e7}oit et transmet des outils de pr\u{00e9}cision pour l\u{2019}auto-soin \u{00e9}nerg\u{00e9}tique. Une pratique quotidienne, reproductible, praticable chez soi.")
                    .font(.callout).foregroundColor(Tok.textSecondary)
                    .multilineTextAlignment(.center)

                Text("Tradition mill\u{00e9}naire \u{00b7} Recherche IRMf de Harvard \u{00b7} Ondes delta")
                    .font(.caption).foregroundColor(Tok.textMuted)
            }
            .padding(.horizontal, 24)
            .offset(y: 90)
        }
        .padding(.bottom, 110)
    }

    // MARK: - Manifesto

    private var manifestoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\u{00ab} Le subtil ne se travaille pas \u{00e0} mains nues. La MTC a ses aiguilles, la Kabbale ses lettres, la radiesthesie ses pendules. L\u{2019}hDOM a ses outils. \u{00bb}")
                .font(.title3.italic())
                .foregroundColor(Tok.plumDark)
                .padding(.leading, 16)
                .overlay(alignment: .leading) {
                    Rectangle().fill(Tok.or).frame(width: 3)
                }

            SectionTagView("Pourquoi les outils")

            Text("Apr\u{00e8}s sept ans de recherche et d\u{2019}int\u{00e9}gration \u{2014} M\u{00e9}decine Traditionnelle Chinoise, Kabbale, g\u{00e9}om\u{00e9}trie sacr\u{00e9}e, d\u{00e9}codage transg\u{00e9}n\u{00e9}rationnel \u{2014} une \u{00e9}vidence s\u{2019}est impos\u{00e9}e\u{00a0}: ce qui rel\u{00e8}ve d\u{2019}une tradition orale doit pouvoir devenir reproductible, partageable, praticable chez soi.")
                .font(.callout).foregroundColor(Tok.textSecondary)
        }
        .padding(24)
        .background(Tok.sable)
    }

    // MARK: - Mechanisms (Science)

    private var mechanismsSection: some View {
        VStack(spacing: 20) {
            SectionTagView("Ce que la recherche contemporaine \u{00e9}claire", center: true)

            Text("Comment les m\u{00e9}moires traumatiques se lib\u{00e8}rent")
                .font(.title2.weight(.medium))
                .foregroundColor(Tok.plumDark)
                .multilineTextAlignment(.center)

            Text("Depuis vingt ans, des \u{00e9}quipes de Harvard Medical School ont mesur\u{00e9}, \u{00e0} l\u{2019}IRMf et au TEP, ce que les traditions \u{00e9}nerg\u{00e9}tiques pressentaient.")
                .font(.callout).foregroundColor(Tok.textSecondary)
                .multilineTextAlignment(.center)

            ForEach(mechanisms) { m in
                MechanismCardView(item: m)
            }

            // Implicit vs Explicit
            VStack(alignment: .leading, spacing: 12) {
                Text("Pourquoi le trauma ne se raconte pas \u{2014} il se ressent")
                    .font(.headline).foregroundColor(Tok.plumDark)

                Text("Certaines exp\u{00e9}riences ne s\u{2019}inscrivent pas comme r\u{00e9}cit mais comme fragments \u{2014} sensations, perceptions, \u{00e9}motions \u{2014} qui r\u{00e9}-\u{00e9}mergent sans que vous reconnaissiez leur origine.")
                    .font(.callout).foregroundColor(Tok.textSecondary)

                HStack(spacing: 12) {
                    MemoryTypeCard(title: "M\u{00e9}moire implicite", text: "Pas de rappel conscient. Encod\u{00e9}e comme r\u{00e9}actions corporelles, sch\u{00e9}mas \u{00e9}motionnels.", borderColor: Tok.rose)
                    MemoryTypeCard(title: "M\u{00e9}moire explicite", text: "Rappel conscient des faits. Encod\u{00e9}e par l\u{2019}hippocampe puis int\u{00e9}gr\u{00e9}e comme r\u{00e9}cit autobiographique.", borderColor: Tok.or)
                }

                Text("Un protocole qui ne s\u{2019}adresse qu\u{2019}\u{00e0} la parole laisse la m\u{00e9}moire implicite intacte. L\u{2019}auto-soin \u{00e9}nerg\u{00e9}tique parle directement au corps qui se souvient.")
                    .font(.callout.italic()).foregroundColor(Tok.textSecondary)
            }
            .padding(20)
            .background(Tok.ivoire)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Tok.sableDark, lineWidth: 1))
        }
        .padding(24)
    }

    // MARK: - Instrumentarium (6 outils)

    private var instrumentariumSection: some View {
        VStack(spacing: 16) {
            SectionTagView("L\u{2019}instrumentarium", center: true)

            Text("Six outils, un m\u{00ea}me cadre")
                .font(.title2.weight(.medium))
                .foregroundColor(Tok.plumDark)
                .multilineTextAlignment(.center)

            Text("L\u{2019}ensemble forme le c\u{0153}ur du syst\u{00e8}me hDOM. Deux sont accessibles en d\u{00e9}monstration interactive ci-dessous.")
                .font(.callout).foregroundColor(Tok.textSecondary)
                .multilineTextAlignment(.center)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(toolItems) { item in
                    ToolCardView(item: item)
                }
            }
        }
        .padding(24)
        .background(Tok.ivoire)
    }

    // MARK: - Rose des Vents (interactive)

    private var roseDesVentsSection: some View {
        VStack(spacing: 20) {
            SectionTagView("Outil n\u{00ba} 1", center: true)

            Text("Johrei_25 \u{2014} Rose des Vents")
                .font(.title2.weight(.medium))
                .foregroundColor(Tok.plumDark)
                .multilineTextAlignment(.center)

            Text("Touchez une direction pour explorer ce qu\u{2019}elle r\u{00e9}v\u{00e8}le.")
                .font(.callout).foregroundColor(Tok.textSecondary)
                .multilineTextAlignment(.center)

            // Compass grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                ForEach(roseDirections) { dir in
                    let isActive = activeDir == dir.id
                    let recommendedColor = activeColor != nil ? chromoColors[activeColor!].id : nil
                    let dirColorId = dirToColorId[dir.id]
                    let isRecommended = recommendedColor != nil && recommendedColor == dirColorId

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            activeDir = isActive ? nil : dir.id
                        }
                    } label: {
                        VStack(spacing: 2) {
                            Text(dir.abbr)
                                .font(.system(size: 13, weight: .bold, design: .serif))
                            Text(dir.element.components(separatedBy: " ").first ?? "")
                                .font(.system(size: 9))
                                .lineLimit(1)
                        }
                        .foregroundColor(isActive ? .white : Tok.plumDark)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(isActive ? Tok.plum : elementBgColor(dir.element))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isRecommended && !isActive ? Tok.or : .clear,
                                        style: StrokeStyle(lineWidth: 2, dash: isRecommended && !isActive ? [4, 3] : []))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Detail card
            if let dirIdx = activeDir {
                let dir = roseDirections[dirIdx]
                let recColorId = dirToColorId[dirIdx]
                let recColor = chromoColors.first(where: { $0.id == recColorId })

                VStack(alignment: .leading, spacing: 12) {
                    Text("Direction activ\u{00e9}e").font(.caption).foregroundColor(Tok.or)
                        .textCase(.uppercase).tracking(1.5)
                    Text(dir.label).font(.title3.weight(.medium)).foregroundColor(Tok.plumDark)

                    HStack(spacing: 6) {
                        ChipView(dir.element)
                        ChipView(dir.saison)
                        ChipView(dir.organe)
                    }

                    Text("\u{00ab} \(dir.theme) \u{00bb}")
                        .font(.callout.italic()).foregroundColor(Tok.textSecondary)

                    if let rc = recColor {
                        Divider()
                        HStack(spacing: 6) {
                            Text("Couleur sugg\u{00e9}r\u{00e9}e :").font(.caption.bold()).foregroundColor(Tok.plum)
                            Circle().fill(Color(hex: rc.hex)).frame(width: 14, height: 14)
                            Text("\(rc.name) \u{2014} \(rc.usage)").font(.caption).foregroundColor(Tok.textSecondary)
                        }
                    }
                }
                .padding(20)
                .background(Tok.ivoire)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Tok.sableDark, lineWidth: 1))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(24)
        .background(Tok.blancChaud)
    }

    // MARK: - Palette chromo (interactive)

    private var paletteSection: some View {
        VStack(spacing: 20) {
            SectionTagView("Outil n\u{00ba} 2", center: true)

            Text("Palette de Lumi\u{00e8}re")
                .font(.title2.weight(.medium))
                .foregroundColor(Tok.plumDark)
                .multilineTextAlignment(.center)

            Text("Chaque couleur porte une dimension, une intention, un soutien.")
                .font(.callout).foregroundColor(Tok.textSecondary)
                .multilineTextAlignment(.center)

            // Color hex grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(Array(chromoColors.enumerated()), id: \.element.id) { idx, color in
                    let isActive = activeColor == idx
                    let recommendedId = activeDir != nil ? dirToColorId[activeDir!] : nil
                    let isRecommended = recommendedId == color.id

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            activeColor = isActive ? nil : idx
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(Color(hex: color.hex))
                                .frame(width: 36, height: 36)
                                .overlay(Circle().stroke(isActive ? Tok.plumDark : .clear, lineWidth: 3))
                                .overlay(Circle().stroke(isRecommended && !isActive ? Tok.or : .clear,
                                                          style: StrokeStyle(lineWidth: 2.5, dash: [4, 3])))
                            Text(color.name)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(Tok.plumDark)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Detail card
            if let colIdx = activeColor {
                let col = chromoColors[colIdx]

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        Circle().fill(Color(hex: col.hex))
                            .frame(width: 44, height: 44)
                            .overlay(Circle().stroke(Tok.blancChaud, lineWidth: 2))
                            .shadow(color: Tok.sableDark, radius: 2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Couleur activ\u{00e9}e").font(.caption).foregroundColor(Tok.or)
                                .textCase(.uppercase).tracking(1.5)
                            Text(col.name).font(.title3.weight(.medium)).foregroundColor(Tok.plumDark)
                        }
                    }

                    ChipView(col.dimension)

                    Text("\u{00ab} \(col.usage) \u{00bb}")
                        .font(.callout.italic()).foregroundColor(Tok.textSecondary)

                    Divider()
                    HStack(alignment: .top, spacing: 6) {
                        Text("Comment l\u{2019}utiliser :").font(.caption.bold()).foregroundColor(Tok.plum)
                        Text(col.how).font(.caption).foregroundColor(Tok.textSecondary)
                    }
                }
                .padding(20)
                .background(Tok.blancChaud)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Tok.sableDark, lineWidth: 1))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(24)
        .background(Tok.sable)
    }

    // MARK: - Tiers (Parcours)

    private var tiersSection: some View {
        VStack(spacing: 16) {
            SectionTagView("Le parcours", center: true)

            Text("Quatre tiers, un seul fil")
                .font(.title2.weight(.medium))
                .foregroundColor(Tok.plumDark)
                .multilineTextAlignment(.center)

            Text("Chacun\u{00b7}e entre par la porte qui lui convient \u{2014} et peut y rester, ou approfondir.")
                .font(.callout).foregroundColor(Tok.textSecondary)
                .multilineTextAlignment(.center)

            ForEach(tierItems) { tier in
                TierCardView(tier: tier)
            }
        }
        .padding(24)
        .background(Tok.ivoire)
    }

    // MARK: - Cercles de Lumieres

    private var cerclesDeLumieresSection: some View {
        VStack(spacing: 16) {
            SectionTagView("Le r\u{00e9}seau \u{00e9}tendu", center: true)

            Text("Cercles de Lumi\u{00e8}res \u{2014} nos th\u{00e9}rapeutes certifi\u{00e9}es")
                .font(.title2.weight(.medium))
                .foregroundColor(Tok.plumDark)
                .multilineTextAlignment(.center)

            Text("Chacune porte sa vibration propre. Votre premier message WhatsApp vous dispatche vers celle qui r\u{00e9}sonne avec ce que vous venez chercher.")
                .font(.callout).foregroundColor(Tok.textSecondary)
                .multilineTextAlignment(.center)

            ForEach(therapists) { t in
                TherapistCardView(therapist: t)
            }
        }
        .padding(24)
        .background(Tok.sable)
    }

    // MARK: - Constellation

    private var constellationSection: some View {
        VStack(spacing: 16) {
            SectionTagView("La s\u{00e9}ance signature", center: true)

            Text("Constellation \u{2014} d\u{00e9}codage \u{00e0} 4 mains")
                .font(.title2.weight(.medium))
                .foregroundColor(Tok.plumDark)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 12) {
                Text("Le principe des 4 mains")
                    .font(.headline).foregroundColor(Tok.plumDark)

                BulletText("Patrick", detail: "d\u{00e9}code la carte \u{00e9}nerg\u{00e9}tique \u{2014} cadre hDOM, lign\u{00e9}es, dimensions, m\u{00e9}moires \u{00e0} lib\u{00e9}rer.")
                BulletText("La th\u{00e9}rapeute", detail: "qui a r\u{00e9}sonn\u{00e9} avec vous m\u{00e8}ne le soin \u{2014} pr\u{00e9}sence corporelle, \u{00e9}coute, rythme juste.")
                BulletText("Vous", detail: "\u{00ea}tes tenue par deux pr\u{00e9}sences \u{2014} la carte et la main, la structure et la vibration.")
            }
            .padding(20)
            .background(Tok.blancChaud)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Tok.sableDark, lineWidth: 1))

            VStack(alignment: .leading, spacing: 8) {
                Text("Le cadre pratique")
                    .font(.headline).foregroundColor(Tok.plumDark)
                Text("CHF 299").font(.title.weight(.medium)).foregroundColor(Tok.plum)
                Text("Pour une s\u{00e9}ance compl\u{00e8}te de 2h30").font(.caption).foregroundColor(Tok.textMuted)

                BulletText("Avec la th\u{00e9}rapeute certifi\u{00e9}e", detail: "qui a r\u{00e9}sonn\u{00e9} au Tier I")
                BulletText("Patrick", detail: "en co-accompagnement")
                BulletText("Canal WhatsApp r\u{00e9}serv\u{00e9}", detail: "apr\u{00e8}s la s\u{00e9}ance, Patrick et la th\u{00e9}rapeute restent joignables.")
            }
            .padding(20)
            .background(Tok.blancChaud)
            .cornerRadius(14)
            .overlay(
                VStack(spacing: 0) {
                    Rectangle().fill(Tok.plum).frame(height: 3)
                    Spacer()
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
            )
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Tok.sableDark, lineWidth: 1))

            // CTA WhatsApp
            Link(destination: URL(string: "https://wa.me/41798131926?text=Bonjour%2C%20je%20souhaite%20en%20savoir%20plus%20sur%20la%20s%C3%A9ance%20Constellation")!) {
                Text("Chat avec nous pour Constellation")
                    .font(.callout.weight(.medium))
                    .foregroundColor(Tok.blancChaud)
                    .padding(.horizontal, 24).padding(.vertical, 12)
                    .background(Tok.plum)
                    .cornerRadius(24)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(24)
        .background(Tok.ivoire)
    }

    // MARK: - Progress Indicators

    private var progressSection: some View {
        VStack(spacing: 16) {
            SectionTagView("Ce qui change", center: true)

            Text("Indicateurs de progr\u{00e8}s \u{2014} semaine apr\u{00e8}s semaine")
                .font(.title2.weight(.medium))
                .foregroundColor(Tok.plumDark)
                .multilineTextAlignment(.center)

            Text("Observ\u{00e9}s en consultation et rapport\u{00e9}s spontan\u{00e9}ment.")
                .font(.callout).foregroundColor(Tok.textSecondary)
                .multilineTextAlignment(.center)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(progressIndicators) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.id)
                            .font(.title3.weight(.medium))
                            .foregroundColor(item.note != nil ? Tok.plum : Tok.or)
                        Text(item.text)
                            .font(.caption.weight(.medium))
                            .foregroundColor(Tok.plumDark)
                        if let note = item.note {
                            Text(note).font(.caption2.italic()).foregroundColor(Tok.plum)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Tok.blancChaud)
                    .cornerRadius(8)
                    .overlay(
                        HStack(spacing: 0) {
                            Rectangle().fill(item.note != nil ? Tok.plum : Tok.or).frame(width: 3)
                            Spacer()
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    )
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Tok.sableDark, lineWidth: 1))
                }
            }
        }
        .padding(24)
        .background(Tok.ivoire)
    }

    // MARK: - FAQ

    private var faqSection: some View {
        VStack(spacing: 16) {
            SectionTagView("Questions", center: true)

            Text("Ce qu\u{2019}on nous demande souvent")
                .font(.title2.weight(.medium))
                .foregroundColor(Tok.plumDark)
                .multilineTextAlignment(.center)

            ForEach(faqItems) { item in
                FAQRowView(item: item)
            }
        }
        .padding(24)
        .background(Tok.sable)
    }

    // MARK: - Signature manifesto

    private var signatureSection: some View {
        VStack(spacing: 16) {
            Text("La signature VSLBH")
                .font(.caption).foregroundColor(Tok.orPale)
                .textCase(.uppercase).tracking(2)

            Text("\u{00ab} De victime \u{00e0} \u{00ea}tre ")
            + Text("empowered").fontWeight(.medium).foregroundColor(Tok.orPale)
            + Text(" \u{2014} embrassez totalement la lib\u{00e9}ration et dites non, avec conviction, de ne plus \u{00ea}tre une victime plus longtemps. \u{00bb}")
        }
        .font(.title3.italic())
        .foregroundColor(Tok.blancChaud)
        .multilineTextAlignment(.center)
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Tok.plumDark)
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 16) {
            // CTA
            VStack(spacing: 12) {
                Text("Commencez par un message \u{2014} nous vous orientons")
                    .font(.headline).foregroundColor(Tok.plumDark)
                    .multilineTextAlignment(.center)

                Link(destination: URL(string: "https://wa.me/41798131926?text=Bonjour%2C%20j%27aimerais%20en%20savoir%20plus%20sur%20la%20m%C3%A9thode%20VSLBH")!) {
                    Text("Chat avec nous")
                        .font(.callout.weight(.medium))
                        .foregroundColor(Tok.blancChaud)
                        .padding(.horizontal, 24).padding(.vertical, 12)
                        .background(Tok.plum)
                        .cornerRadius(24)
                }

                Text("Le sommeil est le premier effet constat\u{00e9} par nos patientes.")
                    .font(.callout.italic()).foregroundColor(Tok.plum)
            }
            .padding(24)

            // Footer info
            VStack(spacing: 6) {
                Text("Digital Shaman Lab").font(.caption.weight(.medium)).foregroundColor(Tok.orPale)
                Text("Le Chandon 4 \u{2014} 1580 Avenches, Suisse").font(.caption2).foregroundColor(.white.opacity(0.7))
                Text("TVA CHE-463.639.374 MWST").font(.caption2).foregroundColor(.white.opacity(0.5))

                Divider().background(.white.opacity(0.15)).padding(.vertical, 8)

                Text("\u{00a9} 2026 Digital Shaman Lab \u{2014} Tous droits r\u{00e9}serv\u{00e9}s")
                    .font(.caption2).foregroundColor(.white.opacity(0.5))
                Text("Les accompagnements propos\u{00e9}s ne remplacent pas un suivi m\u{00e9}dical.")
                    .font(.caption2).foregroundColor(.white.opacity(0.5))
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(Tok.plumDark)
        }
        .background(
            VStack(spacing: 0) {
                LinearGradient(colors: [Tok.sable, Tok.ivoire], startPoint: .top, endPoint: .bottom)
                Tok.plumDark
            }
        )
    }

    // MARK: - Helpers

    private func elementBgColor(_ element: String) -> Color {
        let first = element.components(separatedBy: " ").first ?? ""
        switch first {
        case "Eau": return Color(hex: "#C8D7E8")
        case "Bois": return Color(hex: "#D0DEC2")
        case "Feu": return Color(hex: "#E8C5BC")
        case "Terre": return Color(hex: "#E5D4A8")
        case "M\u{00e9}tal": return Color(hex: "#ECE5D6")
        default: return Tok.sable
        }
    }
}

// MARK: - Reusable Sub-Views

private struct SectionTagView: View {
    let text: String
    var center: Bool

    init(_ text: String, center: Bool = false) {
        self.text = text
        self.center = center
    }

    var body: some View {
        Text(text)
            .font(.caption).fontWeight(.medium)
            .foregroundColor(Tok.or)
            .textCase(.uppercase).tracking(2)
            .frame(maxWidth: center ? .infinity : nil, alignment: center ? .center : .leading)
    }
}

private struct ChipView: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.caption2)
            .foregroundColor(Tok.plumDark)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(Tok.sable)
            .cornerRadius(12)
    }
}

private struct BulletText: View {
    let bold: String
    let detail: String

    init(_ bold: String, detail: String) {
        self.bold = bold
        self.detail = detail
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\u{00b7}").font(.title3.bold()).foregroundColor(Tok.or)
            (Text(bold).fontWeight(.semibold).foregroundColor(Tok.plumDark)
             + Text(" \(detail)").foregroundColor(Tok.textSecondary))
                .font(.callout)
        }
    }
}

private struct MechanismCardView: View {
    let item: MechanismItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.id)
                .font(.title.weight(.medium))
                .foregroundColor(Tok.or)
            Text(item.title)
                .font(.headline).foregroundColor(Tok.plumDark)
            Text(item.body)
                .font(.callout).foregroundColor(Tok.textSecondary)
            if let citation = item.citation {
                Text(citation)
                    .font(.callout.italic()).foregroundColor(Tok.plumDark)
                    .padding(.leading, 12)
                    .overlay(alignment: .leading) {
                        Rectangle().fill(Tok.rose).frame(width: 2)
                    }
                    .padding(.top, 4)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Tok.blancChaud)
        .cornerRadius(12)
        .overlay(
            HStack(spacing: 0) {
                Rectangle().fill(Tok.or).frame(width: 3)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        )
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Tok.sableDark, lineWidth: 1))
    }
}

private struct MemoryTypeCard: View {
    let title: String
    let text: String
    let borderColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline.weight(.medium)).foregroundColor(Tok.plumDark)
            Text(text).font(.caption).foregroundColor(Tok.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Tok.blancChaud)
        .cornerRadius(10)
        .overlay(
            HStack(spacing: 0) {
                Rectangle().fill(borderColor).frame(width: 3)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
        )
    }
}

private struct ToolCardView: View {
    let item: ToolItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.status)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(item.statusClass.badgeFg)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(item.statusClass.badgeBg)
                .cornerRadius(3)

            Text(item.title)
                .font(.caption.weight(.medium))
                .foregroundColor(Tok.plumDark)
            Text(item.subtitle)
                .font(.caption2).foregroundColor(Tok.textMuted)
            Text(item.description)
                .font(.caption2).foregroundColor(Tok.textSecondary)
                .lineLimit(3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(item.statusClass == .live ? Tok.ivoire : Tok.blancChaud)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(item.statusClass == .live ? Tok.plum : Tok.sableDark, lineWidth: 1)
        )
    }
}

private struct TierCardView: View {
    let tier: TierItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tier \(tier.id)")
                .font(.caption).foregroundColor(Tok.or)
                .textCase(.uppercase).tracking(2)
            Text(tier.title).font(.headline).foregroundColor(Tok.plumDark)
            Text(tier.access).font(.caption2.weight(.medium))
                .foregroundColor(Tok.plumDark)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Tok.orPale)
                .cornerRadius(3)

            ForEach(tier.features, id: \.self) { f in
                HStack(alignment: .top, spacing: 8) {
                    Text("\u{00b7}").font(.body.bold()).foregroundColor(Tok.or)
                    Text(f).font(.caption).foregroundColor(Tok.textSecondary)
                }
            }

            Divider()
            Text(tier.price).font(.title3.weight(.medium)).foregroundColor(Tok.plumDark)
            Text(tier.priceNote).font(.caption2).foregroundColor(Tok.textMuted)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Tok.blancChaud)
        .cornerRadius(14)
        .overlay(
            VStack(spacing: 0) {
                Rectangle().fill(tier.borderColor).frame(height: 4)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
        )
    }
}

private struct TherapistCardView: View {
    let therapist: TherapistItem

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(therapist.initials)
                .font(.callout.weight(.medium))
                .foregroundColor(therapist.accent)
                .frame(width: 44, height: 44)
                .background(therapist.accent.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(therapist.name).font(.subheadline.weight(.medium)).foregroundColor(Tok.plumDark)
                Text(therapist.specialty).font(.caption2).foregroundColor(Tok.textMuted)
                Text(therapist.description).font(.caption).foregroundColor(Tok.textSecondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Tok.blancChaud)
        .cornerRadius(14)
        .overlay(
            VStack(spacing: 0) {
                Rectangle().fill(therapist.accent).frame(height: 3)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
        )
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Tok.sableDark, lineWidth: 1))
    }
}

private struct FAQRowView: View {
    let item: FAQItemData
    @State private var isOpen = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) { isOpen.toggle() }
            } label: {
                HStack {
                    Text(item.question)
                        .font(.callout.weight(.medium))
                        .foregroundColor(Tok.plumDark)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Text(isOpen ? "\u{2212}" : "+")
                        .font(.title2.weight(.light))
                        .foregroundColor(Tok.or)
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            if isOpen {
                Text(item.answer)
                    .font(.callout).foregroundColor(Tok.textSecondary)
                    .padding(.horizontal, 16).padding(.bottom, 16)
                    .transition(.opacity)
            }
        }
        .background(Tok.blancChaud)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Tok.sableDark, lineWidth: 1))
    }
}
