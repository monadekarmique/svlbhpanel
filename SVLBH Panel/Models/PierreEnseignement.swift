// SVLBHPanel — Models/PierreEnseignement.swift
// Fiches d'enseignement des 8 pierres de protection SVLBH
// Source: 8-pierres-svlbh-landscape-v0.9.5.docx

import Foundation

struct PierreEnseignement {
    let id: String              // matches PierreSpec.id
    let symbole: String
    let formule: String
    let absorbe: [String]       // tags "Champs denses", etc.
    let signature: String       // one-liner
    let contexte: String        // paragraph
    let usage: String           // paragraph

    static let fiches: [String: PierreEnseignement] = {
        var d: [String: PierreEnseignement] = [:]

        d["tourm"] = PierreEnseignement(
            id: "tourm", symbole: "\u{25fc}", formule: "Schorl \u{2014} NaFe\u{2083}Al\u{2086}(BO\u{2083})\u{2083}Si\u{2086}O\u{2081}\u{2088}(OH)\u{2084}",
            absorbe: ["Champs denses", "Empreintes vibratoires", "Liens ancestraux"],
            signature: "Bouclier vibratoire de premi\u{00e8}re ligne \u{2014} absorbe et neutralise les champs denses sur 15 niveaux de r\u{00e9}sonance ancestrale.",
            contexte: "La Tourmaline noire est la gardienne principale de l\u{2019}espace d\u{2019}accompagnement SVLBH. Sa structure cristalline pyro\u{00e9}lectrique g\u{00e9}n\u{00e8}re un champ \u{00e9}lectromagn\u{00e9}tique naturel qui entre en r\u{00e9}sonance avec les couches denses du champ aurique. Elle harmonise les empreintes vibratoires lourdes transmises sur de nombreuses g\u{00e9}n\u{00e9}rations \u{2014} ces h\u{00e9}ritages fr\u{00e9}quentiels qui circulent dans les tuyaux ancestraux sans que la personne en soit consciente. Dans la pratique SVLBH, elle est active \u{00e0} tous les niveaux du corps de lumi\u{00e8}re et constitue la fondation de tout espace d\u{2019}accompagnement.",
            usage: "Dispos\u{00e9}e en p\u{00e9}rim\u{00e8}tre de l\u{2019}espace de soin et sous la table. Indispensable avant toute session pour cr\u{00e9}er un conteneur vibratoire coh\u{00e9}rent. L\u{2019}accompagnant peut en porter une en poche pour maintenir son propre champ lumineux stable.")

        d["obsid"] = PierreEnseignement(
            id: "obsid", symbole: "\u{25c9}", formule: "Verre volcanique \u{2014} SiO\u{2082} amorphe",
            absorbe: ["Liens vibratoires parasitaires", "Empreintes ancestrales", "Champs transg\u{00e9}n\u{00e9}rationnels"],
            signature: "Miroir vibratoire \u{2014} r\u{00e9}v\u{00e8}le et dissout les liens \u{00e9}nerg\u{00e9}tiques parasitaires transmis sur 25 niveaux g\u{00e9}n\u{00e9}rationnels.",
            contexte: "L\u{2019}Obsidienne noire est un verre volcanique n\u{00e9} de la solidification ultra-rapide de la lave. Elle n\u{2019}a pas de structure cristalline, ce qui en fait un miroir vibratoire parfait. Dans la pratique SVLBH, elle agit sur les liens vibratoires qui relient deux personnes dans une dynamique d\u{00e9}s\u{00e9}quilibr\u{00e9}e : l\u{2019}une capte l\u{2019}\u{00e9}nergie de l\u{2019}autre sans que ni l\u{2019}une ni l\u{2019}autre n\u{2019}en soit consciente. Ces liens peuvent traverser 25 niveaux g\u{00e9}n\u{00e9}rationnels et s\u{2019}ancrer d\u{00e8}s la conception.",
            usage: "Pos\u{00e9}e dans les mains du consultant.e ou plac\u{00e9}e sur le centre CV1 (p\u{00e9}rin\u{00e9}e) pour ancrer la dissolution des liens dans le corps physique. L\u{2019}accompagnant ne la touche pas directement durant la session.")

        d["nuum"] = PierreEnseignement(
            id: "nuum", symbole: "\u{25c8}", formule: "Amphibolite m\u{00e9}tamorphique \u{2014} 3,5 milliards d\u{2019}ann\u{00e9}es",
            absorbe: ["Empreintes pr\u{00e9}-biologiques", "\u{00c9}nergie vitale ancestrale", "M\u{00e9}moires profondes"],
            signature: "Pierre la plus ancienne de la collection \u{2014} acc\u{00e8}de aux empreintes vibratoires ant\u{00e9}rieures \u{00e0} la naissance biologique et aux m\u{00e9}moires de l\u{2019}\u{00e9}nergie vitale originelle.",
            contexte: "La Nuummite du Groenland est l\u{2019}une des roches les plus anciennes de la plan\u{00e8}te (3,5 milliards d\u{2019}ann\u{00e9}es). Cette antiquit\u{00e9} en fait un vecteur vibratoire unique : elle r\u{00e9}sonne avec des couches de m\u{00e9}moire qui pr\u{00e9}c\u{00e8}dent toute forme de vie terrestre. Dans la pratique SVLBH, elle acc\u{00e8}de aux empreintes vibratoires stock\u{00e9}es dans l\u{2019}\u{00e9}nergie vitale (Jing) \u{2014} cette r\u{00e9}serve ancestrale re\u{00e7}ue de nos parents, de leurs parents, jusqu\u{2019}\u{00e0} l\u{2019}origine. Elle est associ\u{00e9}e au chakra 12 dans le protocole SVLBH.",
            usage: "Plac\u{00e9}e sur le GV4 (Mingmen, bas du dos) ou sur le KI1 (plante du pied). Utilisation uniquement par l\u{2019}accompagnant form\u{00e9} \u{2014} jamais laiss\u{00e9}e seule sur le consultant.e.")

        d["shung"] = PierreEnseignement(
            id: "shung", symbole: "\u{25c6}", formule: "Carbone natif amorphe \u{2014} C > 98%",
            absorbe: ["Protection praticien", "Harmonisation \u{00e9}lectromagn\u{00e9}tique", "Champs parasitaires intimes"],
            signature: "Pierre de protection de l\u{2019}accompagnant \u{2014} bouclier fr\u{00e9}quentiel stable face aux champs vibratoires parasitaires intimes et aux \u{00e9}missions \u{00e9}lectromagn\u{00e9}tiques.",
            contexte: "La Shungite \u{00e9}lite est une forme rare de carbone quasi-pur originaire de Car\u{00e9}lie, Russie. Sa structure en fuller\u{00e8}nes lui conf\u{00e8}re des propri\u{00e9}t\u{00e9}s de r\u{00e9}sonance \u{00e9}lectromagn\u{00e9}tique uniques. Dans la pratique SVLBH, elle est la pierre de protection personnelle de l\u{2019}accompagnant : elle maintient la coh\u{00e9}rence de son champ lumineux face aux r\u{00e9}sonances intimes denses et aux perturbations des appareils \u{00e9}lectroniques pr\u{00e9}sents dans l\u{2019}espace de soin.",
            usage: "Port\u{00e9}e en poche par l\u{2019}accompagnant pendant toute la dur\u{00e9}e de la session. Plac\u{00e9}e aux coins du cabinet \u{00e0} c\u{00f4}t\u{00e9} des prises et appareils connect\u{00e9}s. Ne doit pas \u{00ea}tre partag\u{00e9}e entre praticiens.")

        d["aegir"] = PierreEnseignement(
            id: "aegir", symbole: "\u{25c7}", formule: "Pyrox\u{00e8}ne sodique \u{2014} NaFe\u{00b3}\u{207a}Si\u{2082}O\u{2086}",
            absorbe: ["Champs non-harmoniques denses", "Influences ext\u{00e9}rieures intenses", "R\u{00e9}sonances collectives"],
            signature: "Bouclier vibratoire de haute intensit\u{00e9} \u{2014} harmonise les champs vibratoires ext\u{00e9}rieurs tr\u{00e8}s denses qui r\u{00e9}sistent aux autres pierres de la collection.",
            contexte: "L\u{2019}Aegyrine est un pyrox\u{00e8}ne sodique de teinte noire \u{00e0} reflets verts, form\u{00e9} dans des environnements g\u{00e9}ologiques extr\u{00ea}mes. Cette origine dans l\u{2019}extr\u{00ea}me en fait un outil vibratoire pour les situations o\u{00f9} d\u{2019}autres pierres ne suffisent plus \u{2014} quand le champ aurique est soumis \u{00e0} des r\u{00e9}sonances ext\u{00e9}rieures particuli\u{00e8}rement intenses, op\u{00e9}rant hors des syst\u{00e8}mes herm\u{00e9}tiques habituels. Elle est fragile \u{2014} \u{00e0} manipuler avec soin.",
            usage: "Dispos\u{00e9}e en grille de 4 points autour de la table pour cr\u{00e9}er un conteneur vibratoire renforc\u{00e9}. Utilis\u{00e9}e uniquement lorsque le champ de la personne pr\u{00e9}sente des r\u{00e9}sistances inhabituelles aux autres pierres.")

        d["apache"] = PierreEnseignement(
            id: "apache", symbole: "\u{25cb}", formule: "Perlite obsidienne volcanique \u{2014} SiO\u{2082}",
            absorbe: ["Accompagnement du deuil", "\u{00c2}mes en transition", "Empreintes traumatisme f\u{00e9}minin"],
            signature: "Pierre du passage et du deuil \u{2014} dissout les empreintes vibratoires li\u{00e9}es aux pertes non int\u{00e9}gr\u{00e9}es, particuli\u{00e8}rement dans les lign\u{00e9}es f\u{00e9}minines.",
            contexte: "Les Apache Tears sont de petites nodules d\u{2019}obsidienne perlitique translucides. Dans la pratique SVLBH, elles r\u{00e9}sonnent avec les m\u{00e9}moires vibratoires des \u{00e2}mes qui n\u{2019}ont pas termin\u{00e9} leur passage \u{2014} ces pr\u{00e9}sences en transition li\u{00e9}es \u{00e0} leurs proches par des liens d\u{2019}amour non r\u{00e9}solu. Elles sont particuli\u{00e8}rement associ\u{00e9}es aux traumatismes f\u{00e9}minins transmis de m\u{00e8}re en fille et aux deuils p\u{00e9}rinataux (fausses couches, enfants perdus) qui laissent une empreinte dans la lign\u{00e9}e.",
            usage: "Dispos\u{00e9}es en cercle autour du consultant.e pour cr\u{00e9}er un espace sacr\u{00e9} de passage. Le cercle symbolise la compl\u{00e9}tude du cycle. \u{00c0} utiliser avec une intention d\u{2019}accompagnement bienveillant.")

        d["labra"] = PierreEnseignement(
            id: "labra", symbole: "\u{25d0}", formule: "Feldspath plagioclase \u{2014} (Ca,Na)(Si,Al)\u{2084}O\u{2088}",
            absorbe: ["Protection aura praticien", "Miroir vibratoire", "Coh\u{00e9}rence du champ personnel"],
            signature: "Pierre ma\u{00ee}tresse de l\u{2019}accompagnant SVLBH \u{2014} maintient la coh\u{00e9}rence de l\u{2019}aura du praticien et \u{00e9}vite l\u{2019}absorption des r\u{00e9}sonances du consultant.e.",
            contexte: "La Labradorite agit comme un miroir qui r\u{00e9}fl\u{00e9}chit vers l\u{2019}ext\u{00e9}rieur les fr\u{00e9}quences qui ne lui appartiennent pas, tout en laissant passer la lumi\u{00e8}re propre. Dans la pratique SVLBH, elle est la pierre personnelle de l\u{2019}accompagnant. Elle est \u{00e9}galement utilis\u{00e9}e dans le protocole du Stern-Tetraeder (miroir praticien/patient) pour cr\u{00e9}er une s\u{00e9}paration vibratoire claire entre les deux champs.",
            usage: "Port\u{00e9}e par l\u{2019}accompagnant en continu (autour du cou ou en poche). Jamais retir\u{00e9}e pendant une session. L\u{2019}accompagnant doit avoir sa propre Labradorite \u{2014} non partag\u{00e9}e.")

        d["kyani"] = PierreEnseignement(
            id: "kyani", symbole: "\u{25c1}", formule: "Silicate d\u{2019}aluminium \u{2014} Al\u{2082}SiO\u{2085}",
            absorbe: ["Flux d\u{2019}\u{00e9}nergie vitale", "Tuyau masculin ancestral", "Ancrage sans r\u{00e9}tention"],
            signature: "Pierre du flux libre \u{2014} harmonise le canal de l\u{2019}\u{00e9}nergie vitale ancestrale (lign\u{00e9}e masculine) sans aucune accumulation.",
            contexte: "La Kyanite noire se forme en lames allong\u{00e9}es dans les roches m\u{00e9}tamorphiques sous haute pression. Sa particularit\u{00e9} unique : elle ne retient pas les \u{00e9}nergies qu\u{2019}elle traverse \u{2014} elle est auto-purifiante. Dans la pratique SVLBH, elle est utilis\u{00e9}e sur le canal de transmission de l\u{2019}\u{00e9}nergie vitale de la lign\u{00e9}e masculine, qui peut se bloquer ou porter des empreintes d\u{2019}interruption (trauma, rupture de transmission). La Kyanite noire harmonise ce flux sans jamais accumuler elle-m\u{00ea}me.",
            usage: "Pos\u{00e9}e sur l\u{2019}axe GV4 (Mingmen, bas du dos) \u{2194} KI3 (cheville interne). Seule pierre de la collection ne n\u{00e9}cessitant aucune purification.")

        return d
    }()
}
