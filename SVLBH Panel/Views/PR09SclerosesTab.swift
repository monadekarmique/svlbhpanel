// SVLBHPanel — Views/PR09SclerosesTab.swift
// v2.7.0 — Article pilier : Regles douloureuses et energie bloquee — MTC, Gui, chromo, hDOM

import SwiftUI

// MARK: - Design Tokens (article medical)

private enum Art {
    static let bleu = Color(hex: "#2B5EA7")
    static let bleuDark = Color(hex: "#1E4D8C")
    static let or = Color(hex: "#C28D43")
    static let bgBlue = Color(hex: "#F2F6FD")
    static let bgCream = Color(hex: "#FBF6EC")
    static let bgWhite = Color.white
    static let text = Color(hex: "#2D2D2D")
    static let textLight = Color(hex: "#555555")
    static let plum = Color(hex: "#8B3A62")
}

// MARK: - Data

private struct StagnationType: Identifiable {
    let id: String
    let title: String
    let intro: String
    let symptoms: [String]
    let scoring: String
}

private struct ChromoItem: Identifiable {
    let id = UUID()
    let color: String
    let hex: String
    let freq: String
    let subtitle: String
    let points: [String]
}

private struct ProtocoleStep: Identifiable {
    let id: String
    let title: String
    let body: String
    let bullets: [String]
}

private struct Temoignage: Identifiable {
    let id = UUID()
    let text: String
    let author: String
    let pattern: String
}

private struct SignalCategory: Identifiable {
    let id = UUID()
    let title: String
    let signals: [String]
}

private struct PR09FAQ: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

// MARK: - Static Data

private let stagnationTypes: [StagnationType] = [
    .init(id: "1", title: "Stagnation du Qi de LR (Foie)",
          intro: "Pattern le plus fr\u{00e9}quent chez les femmes actives, sous pression ou en frustration chronique.",
          symptoms: ["Tension pr\u{00e9}menstruelle marqu\u{00e9}e (irritabilit\u{00e9}, sautes d\u{2019}humeur)", "Manifestations abdominales distensives, am\u{00e9}lior\u{00e9}es par le mouvement", "Gonflement des seins avant les r\u{00e8}gles", "Soupirs fr\u{00e9}quents, oppression thoracique", "R\u{00e8}gles irr\u{00e9}guli\u{00e8}res avec d\u{00e9}but difficile"],
          scoring: "Score SLA g\u{00e9}n\u{00e9}ralement \u{00e9}lev\u{00e9} sur les dimensions \u{00e9}motionnelles et h\u{00e9}patiques de l\u{2019}arbre hDOM."),
    .init(id: "2", title: "Stase de Sang",
          intro: "Quand la stagnation de Qi perdure, elle affecte la circulation du Sang. Niveau de blocage plus profond.",
          symptoms: ["Crampes intenses, fixes, en coups de poignard", "Caillots sombres dans le flux menstruel", "Manifestations am\u{00e9}lior\u{00e9}es apr\u{00e8}s expulsion des caillots", "Teint sombre, l\u{00e8}vres violac\u{00e9}es", "R\u{00e8}gles retard\u{00e9}es puis abondantes"],
          scoring: "Score SLSA r\u{00e9}v\u{00e8}le souvent des stagnations anciennes, li\u{00e9}es \u{00e0} des \u{00e9}v\u{00e9}nements \u{00e9}motionnels non r\u{00e9}solus."),
    .init(id: "3", title: "Accumulation de Froid dans l\u{2019}ut\u{00e9}rus",
          intro: "Le Froid contracte, ralentit et fige. Install\u{00e9} dans l\u{2019}ut\u{00e9}rus, il bloque la circulation du Qi et du Sang.",
          symptoms: ["Crampes am\u{00e9}lior\u{00e9}es par la chaleur (bouillotte)", "Flux p\u{00e2}le, aqueux, avec petits caillots", "Retard menstruel", "Membres froids, lombes froides", "Aversion pour le froid en phase pr\u{00e9}menstruelle"],
          scoring: "Causes fr\u{00e9}quentes\u{00a0}: exposition au froid pendant les r\u{00e8}gles, aliments froids et crus, constitution Yang d\u{00e9}ficiente."),
    .init(id: "4", title: "Chaleur-Humidit\u{00e9} dans le Jiao Inf\u{00e9}rieur",
          intro: "Combine deux facteurs pathog\u{00e8}nes\u{00a0}: la Chaleur et l\u{2019}Humidit\u{00e9}, qui stagnent dans le bas-ventre.",
          symptoms: ["Flux abondant, rouge vif ou fonc\u{00e9}, visqueux", "R\u{00e8}gles en avance sur le cycle", "Lourdeur et chaleur pelvienne", "Leucorrh\u{00e9}es jaunes ou malodorantes", "Irritabilit\u{00e9}, soif, urine fonc\u{00e9}e"],
          scoring: "Causes fr\u{00e9}quentes\u{00a0}: alimentation riche et grasse, stress chronique g\u{00e9}n\u{00e9}rant de la Chaleur."),
    .init(id: "5", title: "Vide de KI (Rein) \u{2014} Yin et/ou Yang",
          intro: "Racine profonde de nombreuses manifestations cycliques, surtout dans la dur\u{00e9}e.",
          symptoms: ["KI-Yin\u{00a0}: r\u{00e8}gles peu abondantes, s\u{00e9}cheresse, bouff\u{00e9}es de chaleur nocturnes", "KI-Yin\u{00a0}: vertiges, acouph\u{00e8}nes, insomnie", "KI-Yang\u{00a0}: r\u{00e8}gles retard\u{00e9}es, flux p\u{00e2}le et aqueux", "KI-Yang\u{00a0}: froid dans le dos et le ventre, fatigue profonde", "KI-Yang\u{00a0}: mictions fr\u{00e9}quentes, selles molles le matin"],
          scoring: "Le scoring SLPMO cartographie la combinaison de patterns, car ces cinq types coexistent souvent.")
]

private let chromoItems: [ChromoItem] = [
    .init(color: "Orange", hex: "#FF923D", freq: "~480 THz", subtitle: "Lib\u{00e9}ration pelvienne",
          points: ["R\u{00e9}sonne avec le 2\u{1d49} chakra (Svadhisthana)", "Stimule la circulation du Qi dans le Jiao Inf\u{00e9}rieur", "Indiqu\u{00e9} pour la stagnation de Qi de LR et la stase de Sang"]),
    .init(color: "Rouge profond", hex: "#C53030", freq: "~430 THz", subtitle: "R\u{00e9}chauffement ut\u{00e9}rin",
          points: ["Active le KI-Yang et r\u{00e9}chauffe l\u{2019}ut\u{00e9}rus", "Indiqu\u{00e9} en cas d\u{2019}accumulation de Froid", "Utilis\u{00e9} sur CV-4 et CV-6"]),
    .init(color: "Vert", hex: "#66B032", freq: "~560 THz", subtitle: "Harmonisation h\u{00e9}patique",
          points: ["R\u{00e9}sonne avec le m\u{00e9}ridien LR et le 4\u{1d49} chakra", "Favorise la libre circulation du Qi de LR", "Apaise l\u{2019}irritabilit\u{00e9} pr\u{00e9}menstruelle"]),
    .init(color: "Violet", hex: "#7B5AB8", freq: "~700 THz", subtitle: "Lib\u{00e9}ration transg\u{00e9}n\u{00e9}rationnelle",
          points: ["R\u{00e9}sonne avec le 7\u{1d49} chakra (Sahasrara)", "Facilite l\u{2019}acc\u{00e8}s aux m\u{00e9}moires transg\u{00e9}n\u{00e9}rationnelles via Ghost Points", "Accompagne le d\u{00e9}codage profond"]),
    .init(color: "Bleu indigo", hex: "#798EF6", freq: "~670 THz", subtitle: "Apaisement de la Chaleur",
          points: ["Refroidit la Chaleur-Humidit\u{00e9} du Jiao Inf\u{00e9}rieur", "Utilis\u{00e9} sur SP-6 et SP-10", "Accompagne les cycles trop abondants"])
]

private let protocoleSteps: [ProtocoleStep] = [
    .init(id: "01", title: "Bilan \u{00e9}nerg\u{00e9}tique complet (S\u{00e9}ance D\u{00e9}couverte)",
          body: "S\u{00e9}ance D\u{00e9}couverte (CHF 59), 1h15 incluant 30 min d\u{2019}\u{00e9}change et 45 min de bilan.",
          bullets: ["Anamnese compl\u{00e8}te\u{00a0}: historique menstruel, ant\u{00e9}c\u{00e9}dents familiaux", "\u{00c9}valuation des m\u{00e9}ridiens SP, LR, KI et CV", "Premier scoring SLA", "Premi\u{00e8}re lecture de l\u{2019}arbre hDOM", "Plan d\u{2019}accompagnement personnalis\u{00e9}"]),
    .init(id: "02", title: "Sessions individuelles de lib\u{00e9}ration",
          body: "CHF 159, dur\u{00e9}e totale 2h (15 min pr\u{00e9}paration + 75 min s\u{00e9}ance + 30 min int\u{00e9}gration).",
          bullets: ["Travail sur les m\u{00e9}ridiens (SP-6, LR-3, KI-3, CV-4)", "Chromoth\u{00e9}rapie cibl\u{00e9}e selon le type de stagnation", "D\u{00e9}codage transg\u{00e9}n\u{00e9}rationnel (dimension 6 hDOM)", "Framework Gui\u{00a0}: Ghost Points pertinents", "Mise \u{00e0} jour du scoring SLA/SLSA/SLPMO"]),
    .init(id: "03", title: "Int\u{00e9}gration et autonomie",
          body: "L\u{2019}objectif est de rendre la femme autonome dans la gestion de son \u{00e9}nergie cyclique.",
          bullets: ["Exercices de Qi Gong adapt\u{00e9}s au pattern", "Recommandations alimentaires selon la di\u{00e9}t\u{00e9}tique chinoise", "Pratiques d\u{2019}auto-acupression sur points cl\u{00e9}s", "Suivi via le scoring SLA"])
]

private let temoignages: [Temoignage] = [
    .init(text: "Depuis l\u{2019}adolescence, chaque cycle \u{00e9}tait un cauchemar. Apr\u{00e8}s trois sessions VLBH, j\u{2019}ai compris que je portais une col\u{00e8}re \u{00e9}norme li\u{00e9}e \u{00e0} mon travail. Le travail sur le m\u{00e9}ridien LR et la chromoth\u{00e9}rapie verte ont \u{00e9}t\u{00e9} r\u{00e9}v\u{00e9}lateurs. Les manifestations ont diminu\u{00e9} de 80\u{00a0}%.", author: "Sophie, 29 ans", pattern: "Stagnation de Qi de LR"),
    .init(text: "Mes cycles devenaient de plus en plus courts. Patrick a identifi\u{00e9} un Vide de KI-Yin et une m\u{00e9}moire de perte dans ma lign\u{00e9}e maternelle. Le travail avec les Ghost Points a \u{00e9}t\u{00e9} profond\u{00e9}ment \u{00e9}mouvant. Apr\u{00e8}s huit sessions, mes cycles se sont r\u{00e9}gularis\u{00e9}s.", author: "Marie, 41 ans", pattern: "Vide de KI-Yin + m\u{00e9}moire transg\u{00e9}n\u{00e9}rationnelle"),
    .init(text: "Des caillots \u{00e9}normes, des crampes insupportables. La Constellation 4-mains avec Cornelia a \u{00e9}t\u{00e9} un tournant pour lib\u{00e9}rer une m\u{00e9}moire de ma lign\u{00e9}e paternelle. Neuf sessions plus tard, mes cycles sont m\u{00e9}connaissables.", author: "Nathalie, 36 ans", pattern: "Stase de Sang + Froid")
]

private let signalCategories: [SignalCategory] = [
    .init(title: "Signaux physiques", signals: ["Crampes qui modifient vos activit\u{00e9}s", "Caillots r\u{00e9}currents", "Cycles tr\u{00e8}s irr\u{00e9}guliers (<21j ou >35j)", "Flux anormalement abondant ou faible", "Froid persistant bas-ventre/lombaires", "Fatigue extr\u{00ea}me pendant les r\u{00e8}gles"]),
    .init(title: "Signaux \u{00e9}motionnels", signals: ["Irritabilit\u{00e9} disproportionn\u{00e9}e en phase pr\u{00e9}menstruelle", "Tristesse ou d\u{00e9}sespoir cycliques", "Anxi\u{00e9}t\u{00e9} li\u{00e9}e au cycle", "D\u{00e9}connexion de sa f\u{00e9}minit\u{00e9}", "Col\u{00e8}re chronique sans cause apparente"]),
    .init(title: "Signaux transg\u{00e9}n\u{00e9}rationnels", signals: ["M\u{00e8}re/grand-m\u{00e8}re avec patterns similaires", "Pertes p\u{00e9}rinatales ou violences dans la lign\u{00e9}e", "Sensation de porter quelque chose qui ne vous appartient pas", "R\u{00e9}p\u{00e9}tition de sch\u{00e9}mas f\u{00e9}minins dans la famille"]),
    .init(title: "Signaux \u{00e9}nerg\u{00e9}tiques", signals: ["\u{00c9}nergie bloqu\u{00e9}e dans le bassin", "Froid ou chaleur locale sans cause", "Fatigue chronique que le repos ne r\u{00e9}sout pas", "Difficult\u{00e9} \u{00e0} se connecter \u{00e0} sa cr\u{00e9}ativit\u{00e9}"])
]

private let pr09FaqItems: [PR09FAQ] = [
    .init(question: "L\u{2019}approche VLBH remplace-t-elle un suivi m\u{00e9}dical ?",
          answer: "Non. L\u{2019}accompagnement est compl\u{00e9}mentaire et ne se substitue jamais \u{00e0} un suivi m\u{00e9}dical. L\u{2019}approche \u{00e9}nerg\u{00e9}tique travaille sur des plans que la m\u{00e9}decine conventionnelle n\u{2019}adresse pas, et vice versa."),
    .init(question: "Combien de s\u{00e9}ances sont n\u{00e9}cessaires ?",
          answer: "Pattern simple (LR seul)\u{00a0}: 3 \u{00e0} 5 sessions. Pattern combin\u{00e9}\u{00a0}: 5 \u{00e0} 8 sessions. Avec composante transg\u{00e9}n\u{00e9}rationnelle\u{00a0}: 8 \u{00e0} 12 sessions. Le scoring SLA/SLSA mesure la progression objectivement."),
    .init(question: "Est-ce que la s\u{00e9}ance est inconfortable ?",
          answer: "L\u{2019}approche est douce et non invasive. Pas d\u{2019}aiguilles. Travail par stimulation \u{00e9}nerg\u{00e9}tique, chromoth\u{00e9}rapie et accompagnement verbal. Profond\u{00e9}ment relaxant, parfois \u{00e9}motionnellement intense."),
    .init(question: "\u{00c0} quel moment du cycle consulter ?",
          answer: "S\u{00e9}ance D\u{00e9}couverte\u{00a0}: n\u{2019}importe quand. Sessions\u{00a0}: le protocole est adapt\u{00e9} \u{00e0} la phase (menstruelle = soutien doux, folliculaire = tonification, lut\u{00e9}ale = pr\u{00e9}vention stagnation)."),
    .init(question: "Qu\u{2019}est-ce que le scoring SLA / SLSA / SLPMO ?",
          answer: "SLA = Stagnation Level Assessment (niveau global). SLSA = Systemic Assessment (dimensions transg\u{00e9}n\u{00e9}rationnelles). SLPMO = Pattern Multi-Organ (par m\u{00e9}ridien et dimension hDOM). \u{00c9}tablis \u{00e0} chaque s\u{00e9}ance."),
    .init(question: "Compatible avec la contraception hormonale ?",
          answer: "Oui, l\u{2019}accompagnement travaille sur la circulation du Qi et du Sang dans les m\u{00e9}ridiens (LR, SP, KI, CV) ind\u{00e9}pendamment de la contraception."),
    .init(question: "Les manifestations cycliques chez les adolescentes ?",
          answer: "Oui, l\u{2019}approche est adapt\u{00e9}e \u{00e0} tout \u{00e2}ge. L\u{2019}accompagnement pr\u{00e9}coce \u{00e9}vite que des patterns ne se cristallisent. Consentement parental requis pour les mineures."),
    .init(question: "Les manifestations menstruelles sont-elles h\u{00e9}r\u{00e9}ditaires ?",
          answer: "La dimension transg\u{00e9}n\u{00e9}rationnelle est centrale en VLBH. Les m\u{00e9}moires ut\u{00e9}rines et empreintes \u{00e9}motionnelles de la lign\u{00e9}e maternelle peuvent influencer votre v\u{00e9}cu menstruel.")
]

// MARK: - Meridien data (section 1)

private struct MeridienInfo: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let body: String
    let points: [String]
    let keyPoint: String
}

private let meridiens: [MeridienInfo] = [
    .init(id: "SP", title: "M\u{00e9}ridien SP (Rate)", subtitle: "La terre nourrici\u{00e8}re",
          body: "Gardien du Sang en MTC. Production et contention du Sang, gestion de l\u{2019}humidit\u{00e9}.",
          points: ["Production du Sang \u{2014} SP transforme l\u{2019}essence des aliments en Qi et en Sang", "Contention du Sang \u{2014} maintient le Sang dans les vaisseaux", "Gestion de l\u{2019}humidit\u{00e9} \u{2014} ballonnements, lourdeur pelvienne"],
          keyPoint: "SP-6 (Sanyinjiao) \u{2014} point ma\u{00ee}tre de la gyn\u{00e9}cologie en MTC"),
    .init(id: "LR", title: "M\u{00e9}ridien LR (Foie)", subtitle: "Le libre flux du Qi",
          body: "Le plus impliqu\u{00e9} dans les manifestations cycliques. Assure la libre circulation du Qi et stocke le Sang.",
          points: ["Tension pr\u{00e9}menstruelle, irritabilit\u{00e9}", "Manifestations dans les seins", "Crampes avant et pendant les r\u{00e8}gles", "C\u{00e9}phal\u{00e9}es temporales"],
          keyPoint: "LR-3 (Taichong) \u{2014} \u{00ab} la Grande Pouss\u{00e9}e \u{00bb}"),
    .init(id: "KI", title: "M\u{00e9}ridien KI (Rein)", subtitle: "La racine du Yin et du Yang",
          body: "Racine de toute l\u{2019}\u{00e9}nergie vitale. KI-Yin nourrit l\u{2019}ut\u{00e9}rus, KI-Yang r\u{00e9}chauffe, KI-Jing d\u{00e9}termine le rythme reproductif.",
          points: ["KI-Yin \u{2014} nourrit l\u{2019}ut\u{00e9}rus, soutient la phase folliculaire", "KI-Yang \u{2014} r\u{00e9}chauffe l\u{2019}ut\u{00e9}rus, soutient la phase lut\u{00e9}ale", "KI-Essence (Jing) \u{2014} d\u{00e9}termine le rythme de la vie reproductive"],
          keyPoint: "KI-3 (Taixi) \u{2014} point source du m\u{00e9}ridien"),
    .init(id: "CV", title: "M\u{00e9}ridien CV (Vaisseau Conception)", subtitle: "Le vaisseau de la f\u{00e9}minit\u{00e9}",
          body: "Ren Mai \u{2014} gouverne tous les m\u{00e9}ridiens Yin et l\u{2019}ensemble de la sph\u{00e8}re g\u{00e9}nitale f\u{00e9}minine.",
          points: ["CV-3 (Zhongji) \u{2014} point local majeur pour l\u{2019}ut\u{00e9}rus", "CV-4 (Guanyuan) \u{2014} Barri\u{00e8}re de la Source Originelle", "CV-6 (Qihai) \u{2014} Mer du Qi"],
          keyPoint: "Couple fonctionnel avec le Chong Mai \u{2014} Mer du Sang")
]

// MARK: - Tab principal

struct PR09SclerosesTab: View {
    @EnvironmentObject var session: SessionState

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    introSection
                    meridienSection
                    stagnationSection
                    guiFrameworkSection
                    chromoSection
                    hdomSection
                    protocoleSection
                    temoignagesSection
                    signauxSection
                    faqPR09Section
                    ctaSection
                    footerPR09
                }
            }
            .background(Art.bgWhite)
            .navigationTitle("PR 09 : Scl\u{00e9}roses")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Intro

    private var introSection: some View {
        VStack(spacing: 16) {
            Text("R\u{00e8}gles douloureuses et \u{00e9}nergie bloqu\u{00e9}e")
                .font(.title2.bold())
                .foregroundColor(Art.bleu)
                .multilineTextAlignment(.center)

            Text("Comprendre et lib\u{00e9}rer votre cycle avec la m\u{00e9}decine chinoise")
                .font(.callout).foregroundColor(Art.textLight)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 10) {
                ArticleText("Chaque mois, des millions de femmes vivent leur cycle comme une \u{00e9}preuve. Crampes intenses, fatigue \u{00e9}crasante, humeur instable, migraines\u{00a0}: ces manifestations sont si courantes qu\u{2019}elles finissent par \u{00ea}tre consid\u{00e9}r\u{00e9}es comme \u{00ab}\u{00a0}normales\u{00a0}\u{00bb}. Pourtant, dans la vision de la MTC et de l\u{2019}approche VLBH, un cycle harmonieux ne devrait g\u{00e9}n\u{00e9}rer aucune manifestation invalidante.")

                ArticleText("Les manifestations cycliques sont des signaux. Elles indiquent que le Qi ne circule pas librement dans les m\u{00e9}ridiens qui gouvernent la sph\u{00e8}re gyn\u{00e9}cologique. Ce blocage s\u{2019}inscrit dans un r\u{00e9}seau de tensions physiques, \u{00e9}motionnelles et parfois transg\u{00e9}n\u{00e9}rationnelles.")

                ArticleText("L\u{2019}approche VLBH combine la sagesse mill\u{00e9}naire de la MTC, le d\u{00e9}codage transg\u{00e9}n\u{00e9}rationnel, la chromoth\u{00e9}rapie et le framework Gui \u{9b3c} pour identifier les racines profondes du d\u{00e9}s\u{00e9}quilibre et accompagner le corps vers sa propre capacit\u{00e9} de lib\u{00e9}ration.")
            }
        }
        .padding(24)
        .background(Art.bgBlue)
    }

    // MARK: - Meridiens (Section 1)

    private var meridienSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ArticleH2("Comprendre l\u{2019}\u{00e9}nergie du cycle menstruel en MTC")

            ArticleText("Quatre m\u{00e9}ridiens principaux orchestrent la danse cyclique. Lorsque l\u{2019}un d\u{2019}eux est perturb\u{00e9}, l\u{2019}ensemble du cycle s\u{2019}en ressent.")

            ForEach(meridiens) { m in
                VStack(alignment: .leading, spacing: 8) {
                    Text(m.title).font(.headline).foregroundColor(Art.bleuDark)
                    Text(m.subtitle).font(.subheadline.italic()).foregroundColor(Art.or)
                    Text(m.body).font(.callout).foregroundColor(Art.text)

                    ForEach(m.points, id: \.self) { p in
                        ArtBullet(p)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill").foregroundColor(Art.or).font(.caption)
                        Text(m.keyPoint).font(.caption.weight(.medium)).foregroundColor(Art.bleuDark)
                    }
                    .padding(10)
                    .background(Art.bgBlue)
                    .cornerRadius(8)
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.07), radius: 6, y: 2)
            }
        }
        .padding(24)
        .background(Art.bgCream)
    }

    // MARK: - 5 Types de stagnation (Section 2)

    private var stagnationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ArticleH2("Les 5 types de stagnation \u{00e9}nerg\u{00e9}tique li\u{00e9}s au cycle")

            ArticleText("Les manifestations cycliques correspondent \u{00e0} des patterns \u{00e9}nerg\u{00e9}tiques sp\u{00e9}cifiques que le scoring SLA permet d\u{2019}\u{00e9}valuer avec pr\u{00e9}cision.")

            ForEach(stagnationTypes) { st in
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(st.id). \(st.title)").font(.headline).foregroundColor(Art.bleuDark)
                    Text(st.intro).font(.callout).foregroundColor(Art.text)

                    Text("Manifestations typiques :").font(.caption.bold()).foregroundColor(Art.bleuDark)
                    ForEach(st.symptoms, id: \.self) { s in
                        ArtBullet(s)
                    }

                    Text(st.scoring).font(.caption.italic()).foregroundColor(Art.textLight)
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.07), radius: 6, y: 2)
            }
        }
        .padding(24)
        .background(Art.bgBlue)
    }

    // MARK: - Framework Gui (Section 3)

    private var guiFrameworkSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ArticleH2("Le framework Gui \u{9b3c} et les m\u{00e9}moires transg\u{00e9}n\u{00e9}rationnelles du f\u{00e9}minin")

            Text("Les 13 Ghost Points : 1300 ans de sagesse").font(.subheadline.bold()).foregroundColor(Art.bleuDark)

            ArticleText("Le framework Gui, codifi\u{00e9} par Sun Si Miao au VII\u{1d49} si\u{00e8}cle, identifie 13 points li\u{00e9}s aux perturbations de l\u{2019}esprit. Dans l\u{2019}approche VLBH, ils repr\u{00e9}sentent des m\u{00e9}moires \u{00e9}nerg\u{00e9}tiques h\u{00e9}rit\u{00e9}es \u{00e0} travers les g\u{00e9}n\u{00e9}rations.")

            VStack(alignment: .leading, spacing: 6) {
                GhostPointRow(point: "GV-26 (Gui Gong)", desc: "Palais du Fant\u{00f4}me \u{2014} reconnexion \u{00e0} la conscience")
                GhostPointRow(point: "LU-11 (Gui Xin)", desc: "Confiance du Fant\u{00f4}me \u{2014} deuils non faits, s\u{00e9}parations")
                GhostPointRow(point: "SP-1 (Gui Lei)", desc: "Fort du Fant\u{00f4}me \u{2014} ancrage et retour au corps")
                GhostPointRow(point: "PC-7 (Gui Xin)", desc: "C\u{0153}ur du Fant\u{00f4}me \u{2014} protection du Shen")
                GhostPointRow(point: "GV-23 (Gui Tang)", desc: "Hall du Fant\u{00f4}me \u{2014} clart\u{00e9} mentale")
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.07), radius: 6, y: 2)

            Text("L\u{2019}h\u{00e9}ritage transg\u{00e9}n\u{00e9}rationnel du f\u{00e9}minin").font(.subheadline.bold()).foregroundColor(Art.bleuDark)

            VStack(alignment: .leading, spacing: 6) {
                ArtBullet("M\u{00e9}moires de honte \u{2014} r\u{00e8}gles \u{00ab}\u{00a0}sales\u{00a0}\u{00bb}, \u{00ab}\u{00a0}impures\u{00a0}\u{00bb} ou tabou")
                ArtBullet("M\u{00e9}moires de souffrance reproductive \u{2014} fausses couches, avortements subis")
                ArtBullet("M\u{00e9}moires de soumission \u{2014} mariages forc\u{00e9}s, violences conjugales")
                ArtBullet("M\u{00e9}moires de perte de pouvoir \u{2014} femmes praticiennes pers\u{00e9}cut\u{00e9}es")
            }
        }
        .padding(24)
        .background(Art.bgCream)
    }

    // MARK: - Chromotherapie (Section 4)

    private var chromoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ArticleH2("Chromoth\u{00e9}rapie appliqu\u{00e9}e au cycle")

            ArticleText("Chaque couleur correspond \u{00e0} une fr\u{00e9}quence vibratoire sp\u{00e9}cifique qui interagit avec les m\u{00e9}ridiens et les centres \u{00e9}nerg\u{00e9}tiques.")

            ForEach(chromoItems) { item in
                HStack(alignment: .top, spacing: 12) {
                    Circle().fill(Color(hex: item.hex))
                        .frame(width: 36, height: 36)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(item.color) (\(item.freq))").font(.subheadline.bold()).foregroundColor(Art.bleuDark)
                        Text(item.subtitle).font(.caption.italic()).foregroundColor(Art.or)
                        ForEach(item.points, id: \.self) { p in
                            ArtBullet(p)
                        }
                    }
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.07), radius: 6, y: 2)
            }
        }
        .padding(24)
        .background(Art.bgBlue)
    }

    // MARK: - Arbre hDOM (Section 5)

    private var hdomSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ArticleH2("L\u{2019}arbre hDOM : 9 dimensions et 33 chakras")

            ArticleText("L\u{2019}arbre hDOM organise le champ \u{00e9}nerg\u{00e9}tique humain en 9 dimensions crois\u{00e9}es avec 33 chakras.")

            let dimensions = [
                "1. Physique \u{2014} corps, organes, m\u{00e9}ridiens",
                "2. \u{00c9}th\u{00e9}rique \u{2014} champ vital imm\u{00e9}diat",
                "3. \u{00c9}motionnelle \u{2014} \u{00e9}motions stock\u{00e9}es, patterns r\u{00e9}actifs",
                "4. Mentale \u{2014} croyances, sch\u{00e9}mas de pens\u{00e9}e",
                "5. Causale \u{2014} causes profondes, karma",
                "6. Ancestrale \u{2014} h\u{00e9}ritage transg\u{00e9}n\u{00e9}rationnel",
                "7. Arch\u{00e9}typale \u{2014} M\u{00e8}re, Guerri\u{00e8}re, Praticienne\u{2026}",
                "8. Cosmique \u{2014} connexion aux cycles universels",
                "9. Unitaire \u{2014} int\u{00e9}gration de toutes les dimensions"
            ]

            VStack(alignment: .leading, spacing: 4) {
                ForEach(dimensions, id: \.self) { d in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\u{25c6}").font(.caption2).foregroundColor(Art.or)
                        Text(d).font(.caption).foregroundColor(Art.text)
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.07), radius: 6, y: 2)

            Text("Application au cycle f\u{00e9}minin").font(.subheadline.bold()).foregroundColor(Art.bleuDark)

            VStack(alignment: .leading, spacing: 6) {
                ArtBullet("Dim. 1 (physique) \u{2014} stagnation de Qi, stase de Sang, Froid")
                ArtBullet("Dim. 3 (\u{00e9}motionnelle) \u{2014} col\u{00e8}re refoul\u{00e9}e (LR), peur (KI), rumination (SP)")
                ArtBullet("Dim. 4 (mentale) \u{2014} croyances limitantes sur la f\u{00e9}minit\u{00e9}")
                ArtBullet("Dim. 6 (ancestrale) \u{2014} m\u{00e9}moires identifi\u{00e9}es via framework Gui")
                ArtBullet("Dim. 7 (arch\u{00e9}typale) \u{2014} sur-activation du Guerrier, d\u{00e9}connexion Femme Cyclique")
            }
        }
        .padding(24)
        .background(Art.bgCream)
    }

    // MARK: - Protocole (Section 6)

    private var protocoleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ArticleH2("Le protocole VLBH \u{00e9}tape par \u{00e9}tape")

            ForEach(protocoleSteps) { step in
                VStack(alignment: .leading, spacing: 8) {
                    Text(step.id)
                        .font(.title2.bold())
                        .foregroundColor(Art.or)
                    Text(step.title).font(.headline).foregroundColor(Art.bleuDark)
                    Text(step.body).font(.callout).foregroundColor(Art.text)

                    ForEach(step.bullets, id: \.self) { b in
                        ArtBullet(b)
                    }
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    HStack(spacing: 0) {
                        Rectangle().fill(Art.or).frame(width: 4)
                        Spacer()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                )
                .shadow(color: .black.opacity(0.07), radius: 6, y: 2)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Nombre de sessions indicatif :").font(.caption.bold()).foregroundColor(Art.bleuDark)
                ArtBullet("Pattern simple (LR seul)\u{00a0}: 3 \u{00e0} 5 sessions")
                ArtBullet("Pattern combin\u{00e9}\u{00a0}: 5 \u{00e0} 8 sessions")
                ArtBullet("Composante transg\u{00e9}n\u{00e9}rationnelle forte\u{00a0}: 8 \u{00e0} 12 sessions")
            }
            .padding(16)
            .background(Art.bgCream)
            .cornerRadius(12)
        }
        .padding(24)
        .background(Art.bgBlue)
    }

    // MARK: - Temoignages (Section 7)

    private var temoignagesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ArticleH2("Parcours de lib\u{00e9}ration : t\u{00e9}moignages")

            Text("Tous les pr\u{00e9}noms ont \u{00e9}t\u{00e9} modifi\u{00e9}s pour respecter la confidentialit\u{00e9}.")
                .font(.caption.italic()).foregroundColor(Art.textLight)

            ForEach(temoignages) { t in
                VStack(alignment: .leading, spacing: 8) {
                    Text("\u{201c}").font(.system(size: 40, design: .serif)).foregroundColor(Art.or.opacity(0.3))
                        .padding(.bottom, -20)
                    Text(t.text).font(.callout.italic()).foregroundColor(Art.text)
                    HStack(spacing: 4) {
                        Text("\u{2014} \(t.author)").font(.caption.bold()).foregroundColor(Art.bleu)
                        Text("\u{2014} \(t.pattern)").font(.caption).foregroundColor(Art.textLight)
                    }
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.07), radius: 6, y: 2)
            }
        }
        .padding(24)
        .background(Art.bgCream)
    }

    // MARK: - Signaux d'alerte (Section 10)

    private var signauxSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ArticleH2("Quand consulter : signaux d\u{2019}alerte \u{00e9}nerg\u{00e9}tiques")

            ArticleText("Votre cycle vous parle. Voici les signaux qui indiquent qu\u{2019}un accompagnement VLBH pourrait \u{00ea}tre pertinent.")

            ForEach(signalCategories) { cat in
                VStack(alignment: .leading, spacing: 6) {
                    Text(cat.title).font(.subheadline.bold()).foregroundColor(Art.bleuDark)
                    ForEach(cat.signals, id: \.self) { s in
                        ArtBullet(s)
                    }
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.07), radius: 6, y: 2)
            }

            Text("Si vous reconnaissez trois ou plus de ces signaux, une s\u{00e9}ance D\u{00e9}couverte permettra d\u{2019}\u{00e9}valuer votre situation.")
                .font(.callout.italic()).foregroundColor(Art.textLight)
        }
        .padding(24)
        .background(Art.bgBlue)
    }

    // MARK: - FAQ

    private var faqPR09Section: some View {
        VStack(alignment: .leading, spacing: 12) {
            ArticleH2("Questions fr\u{00e9}quentes")

            ForEach(pr09FaqItems) { item in
                PR09FAQRow(item: item)
            }
        }
        .padding(24)
        .background(Art.bgCream)
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: 16) {
            Text("Lib\u{00e9}rez votre cycle")
                .font(.title2.bold())
                .foregroundColor(.white)

            Text("Les manifestations cycliques ne sont pas une fatalit\u{00e9}. Elles sont un langage \u{2014} celui de votre corps, de vos \u{00e9}motions, et parfois de votre lign\u{00e9}e.")
                .font(.callout).foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 4) {
                Text("S\u{00e9}ance D\u{00e9}couverte \u{2014} CHF 59").font(.callout.bold()).foregroundColor(.white)
                Text("30 min d\u{2019}\u{00e9}change + 45 min de bilan = 1h15").font(.caption).foregroundColor(.white.opacity(0.8))
            }

            VStack(alignment: .leading, spacing: 4) {
                ArtBulletWhite("Bilan \u{00e9}nerg\u{00e9}tique complet de votre cycle")
                ArtBulletWhite("Premi\u{00e8}re cartographie hDOM")
                ArtBulletWhite("Scoring SLA initial")
                ArtBulletWhite("Plan d\u{2019}accompagnement personnalis\u{00e9}")
            }

            Link(destination: URL(string: "https://wa.me/41798131926?text=Bonjour%2C%20je%20souhaite%20r%C3%A9server%20une%20s%C3%A9ance%20D%C3%A9couverte")!) {
                Text("R\u{00e9}server votre s\u{00e9}ance D\u{00e9}couverte")
                    .font(.callout.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 24).padding(.vertical, 12)
                    .background(Art.or)
                    .cornerRadius(8)
            }

            VStack(spacing: 2) {
                Text("Ma \u{2014} 13h\u{2013}20h | Me \u{2014} 10h\u{2013}22h | Sa \u{2014} 9h\u{2013}13h").font(.caption2).foregroundColor(.white.opacity(0.7))
                Text("Le Chandon 4, 1580 Avenches").font(.caption2).foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(Art.bleuDark)
        .cornerRadius(12)
        .padding(24)
    }

    // MARK: - Footer

    private var footerPR09: some View {
        Text("Digital Shaman Lab \u{2014} vlbh.energy \u{2014} 2026")
            .font(.caption2).foregroundColor(Art.textLight)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
    }
}

// MARK: - Reusable sub-views

private struct ArticleText: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text).font(.callout).foregroundColor(Art.text)
    }
}

private struct ArticleH2: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.title3.bold())
            .foregroundColor(Art.bleu)
            .padding(.leading, 14)
            .overlay(alignment: .leading) {
                Rectangle().fill(Art.or).frame(width: 4)
            }
    }
}

private struct ArtBullet: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle().fill(Art.or).frame(width: 7, height: 7).padding(.top, 5)
            Text(text).font(.caption).foregroundColor(Art.text)
        }
    }
}

private struct ArtBulletWhite: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle().fill(Art.or).frame(width: 7, height: 7).padding(.top, 5)
            Text(text).font(.caption).foregroundColor(.white.opacity(0.9))
        }
    }
}

private struct GhostPointRow: View {
    let point: String
    let desc: String
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\u{9b3c}").font(.caption).foregroundColor(Art.or)
            (Text(point).fontWeight(.semibold).foregroundColor(Art.bleuDark)
             + Text(" \u{2014} \(desc)").foregroundColor(Art.text))
                .font(.caption)
        }
    }
}

private struct PR09FAQRow: View {
    let item: PR09FAQ
    @State private var isOpen = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) { isOpen.toggle() }
            } label: {
                HStack {
                    Text(item.question)
                        .font(.callout.weight(.medium))
                        .foregroundColor(Art.bleu)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Text(isOpen ? "\u{2212}" : "+")
                        .font(.title2.weight(.light))
                        .foregroundColor(Art.or)
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if isOpen {
                Text(item.answer)
                    .font(.callout).foregroundColor(Art.textLight)
                    .padding(.horizontal, 14).padding(.bottom, 14)
                    .transition(.opacity)
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.07), radius: 6, y: 2)
    }
}
