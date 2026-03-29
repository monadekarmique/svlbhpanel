// SVLBHPanel — Views/PasserelleTab.swift
// Architecture de la passerelle énergétique-médicale

import SwiftUI

struct PasserelleTab: View {
    @EnvironmentObject var session: SessionState

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    architectureSection
                    mesuresSection
                    definitionSection
                    mecanismeSection
                    reglesSection
                    protocoleSection
                    correspondancesSection
                    parametresSection
                    pedagogieSection
                }
                .padding()
            }
            .navigationTitle("Passerelle")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 3) {
            Text("\u{25c8} Passerelle VLBH \u{2194} M\u{00e9}decine")
                .font(.title2.bold()).foregroundColor(Color(hex: "#8B3A62"))
            Text("Yesod 9 \u{00b7} Dyspepsie-TOC \u{00b7} G\u{2212}15")
                .font(.caption).foregroundColor(.secondary)
            Text("Cas arch\u{00e9}type : Blessure d\u{2019}\u{00c2}me 9 Yesod \u{00b7} Inceste monadique \u{00b7} K30 \u{00b7} TOC sonores")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.top, 14)
    }

    // MARK: - 1. Architecture 4 couches

    private var architectureSection: some View {
        sectionCard(title: "1. Architecture passerelle \u{2014} 4 couches", icon: "square.stack.3d.up") {
            VStack(spacing: 0) {
                coucheRow(num: "1", system: "Sephiroth multig\u{00e9}n\u{00e9}rationnel", content: "Lecture lign\u{00e9}es n\u{2212}1 \u{00e0} G\u{2212}15+ \u{00b7} portes ouvertes \u{00b7} Gu identifi\u{00e9}s", color: .purple)
                coucheRow(num: "2", system: "SVLBHPanel \u{2014} hDOM", content: "Scores SLA/SLSA/SLPMO/SLM \u{00b7} Solides de Platon \u{00b7} Linggui Bafa", color: .blue)
                coucheRow(num: "3", system: "M\u{00e9}decine Traditionnelle Chinoise", content: "M\u{00e9}ridiens ST \u{00b7} SP \u{00b7} LR \u{00b7} KI \u{00b7} Qi rebelle \u{2191} \u{00b7} 5 \u{00c9}l\u{00e9}ments", color: .green)
                coucheRow(num: "4", system: "M\u{00e9}decine Occidentale ICD-10", content: "K30 dyspepsie fonctionnelle \u{00b7} R11.0 naus\u{00e9}es \u{00b7} R11.1 vomissements", color: .red)
            }
            Text("K30 r\u{00e9}fractaire aux traitements conventionnels = indicateur diagnostique VLBH.\nL\u{2019}\u{00e9}chec th\u{00e9}rapeutique occidental confirme l\u{2019}origine monadique.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
    }

    private func coucheRow(num: String, system: String, content: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(num)
                .font(.system(.title3, design: .rounded).bold())
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.8))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(system).font(.subheadline.bold())
                Text(content).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }

    // MARK: - 2. Mesures

    private var mesuresSection: some View {
        sectionCard(title: "2. Mesures radiesthésiques", icon: "gauge.with.needle") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                mesureCell(param: "ST 9", val: "Gauche", detail: "Pilier f\u{00e9}minin \u{00b7} lign\u{00e9}e maternelle")
                mesureCell(param: "Gu actifs", val: "15", detail: "Charge massive D5")
                mesureCell(param: "Dimension", val: "D5", detail: "Plans transverses \u{00b7} non-herm\u{00e9}tique")
                mesureCell(param: "Nature Gu", val: "F\u{0153}tales logoïques", detail: "Syst\u{00e8}me f\u{0153}tal logoïque")
                mesureCell(param: "SLM", val: "13%", detail: "Possession active")
                mesureCell(param: "SLM total", val: "1415%", detail: "~14 Monades")
                mesureCell(param: "G\u{00e9}n\u{00e9}ration", val: "G\u{2212}15", detail: "~XVIIe si\u{00e8}cle")
                mesureCell(param: "pH pin\u{00e9}ale", val: "7.4 orange", detail: "Allumage bloqu\u{00e9}")
            }
        }
    }

    private func mesureCell(param: String, val: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(param).font(.caption2).foregroundColor(.secondary)
            Text(val).font(.system(.headline, design: .monospaced))
            Text(detail).font(.caption2).foregroundColor(.secondary).lineLimit(2)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    // MARK: - 3. Définition clinique

    private var definitionSection: some View {
        sectionCard(title: "3. Syst\u{00e8}me f\u{0153}tal logoïque", icon: "brain.head.profile") {
            Text("Fragments de conscience de victimes captur\u{00e9}es au stade f\u{0153}tal de leur incarnation. Elles n\u{2019}ont pas compl\u{00e9}t\u{00e9} leur descente vers Malkuth \u{00e0} cause de la transgression active dans la lign\u{00e9}e. Elles restent bloqu\u{00e9}es en D5, flottantes entre la source logoïque et la manifestation physique, accroch\u{00e9}es au n\u{0153}ud ST 9 gauche.")
                .font(.callout)
            HStack(spacing: 16) {
                protocolLabel("Victimes f\u{0153}tales", shape: "Icosa\u{00e8}dre", color: .blue)
                protocolLabel("Patient z\u{00e9}ro", shape: "Cube", color: .red)
            }
            .padding(.top, 4)
        }
    }

    private func protocolLabel(_ label: String, shape: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color.opacity(0.3)).frame(width: 10, height: 10)
            Text("\(label) \u{2192} **\(shape)**").font(.caption)
        }
    }

    // MARK: - 4. Mécanisme physique

    private var mecanismeSection: some View {
        sectionCard(title: "4. M\u{00e9}canisme pin\u{00e9}ale \u{2192} sphincters", icon: "arrow.down.right.and.arrow.up.left") {
            VStack(alignment: .leading, spacing: 12) {
                Text("**4a. Chemin d\u{2019}allumage matinal bloqu\u{00e9}**").font(.subheadline)
                Text("Pin\u{00e9}ale (pH 7.4) \u{2192} BLOQU\u{00c9}\n  \u{2193} [ne passe pas]\nPituitaire \u{2192} cascade endocrine \u{2192} cortisol\n  \u{2193}\nYang montant \u{2192} ST 7h\u{2013}9h \u{2192} descente Qi ST\n  \u{2193}\nDigestion normale")
                    .font(.system(.caption, design: .monospaced))
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(6)

                Text("**4b. Double verrou sphinct\u{00e9}rien**").font(.subheadline)
                HStack(spacing: 8) {
                    sphincterCard(name: "\u{0152}sophagien inf.", status: "Bloqu\u{00e9} \u{2191}", effect: "Qi rebelle remonte")
                    sphincterCard(name: "Pylorique", status: "Bloqu\u{00e9} \u{2193}", effect: "Contenu stagne")
                }

                Text("**4c. Faux du cerveau \u{2014} TOC sonores**").font(.subheadline)
                Text("D\u{00e9}sintrication : GV 20 \u{2192} GV 24 \u{2192} cluster Tiphereth \u{2192} GV 16 \u{2192} cluster Yesod \u{2192} crista galli")
                    .font(.caption)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(6)
            }
        }
    }

    private func sphincterCard(name: String, status: String, effect: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name).font(.caption.bold())
            Text(status).font(.system(.caption, design: .monospaced)).foregroundColor(.orange)
            Text(effect).font(.caption2).foregroundColor(.secondary)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    // MARK: - 5. Règles cliniques

    private var reglesSection: some View {
        sectionCard(title: "5. R\u{00e8}gles cliniques", icon: "list.number") {
            VStack(alignment: .leading, spacing: 12) {
                regleRow(num: 1, title: "Sens de d\u{00e9}sintrication", body: "La d\u{00e9}sintrication suit le sens de l\u{2019}accumulation.")
                regleRow(num: 2, title: "Boucle ferm\u{00e9}e carotide / faux", body: "La carotide monte (Malkuth\u{2192}Kether) et la faux descend (Kether\u{2192}Malkuth). Signature d\u{2019}un syst\u{00e8}me G encod\u{00e9} sur l\u{2019}axe complet.")
                regleRow(num: 3, title: "D\u{00e9}sintrication simultan\u{00e9}e", body: "M\u{00ea}me axe + m\u{00ea}me origine G \u{2192} un seul geste lib\u{00e8}re toutes les structures.")
                regleRow(num: 4, title: "Cube G = disjoncteur principal", body: "R\u{00e9}soudre le Cube G\u{2212}n AVANT toute d\u{00e9}sintrication.")
                regleRow(num: 5, title: "ST 9 = mesure SLA", body: "ST 9 Renying (Fen\u{00ea}tre du Ciel) sur la carotide \u{2014} n\u{0153}ud de mesure privil\u{00e9}gi\u{00e9} pour la charge Gu.")
            }
        }
    }

    private func regleRow(num: Int, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("R\(num)")
                .font(.system(.caption, design: .rounded).bold())
                .foregroundColor(.white)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Color.accentColor.opacity(0.8))
                .cornerRadius(4)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                Text(body).font(.caption).foregroundColor(.secondary)
            }
        }
    }

    // MARK: - 6. Protocole

    private var protocoleSection: some View {
        sectionCard(title: "6. Protocole complet", icon: "checklist") {
            VStack(alignment: .leading, spacing: 8) {
                protoStep(n: 1, text: "Apaiser la Monade \u{2014} SLM 13% \u{2014} v\u{00e9}rifier cordage")
                protoStep(n: 2, text: "Dod\u{00e9}ca\u{00e8}dre \u{2014} 14 Monades S1\u{2192}S8")
                protoStep(n: 3, text: "Cube G\u{2212}15 \u{2014} patient z\u{00e9}ro lign\u{00e9}e maternelle \u{2014} disjoncteur")
                protoStep(n: 4, text: "D\u{00e9}sintrication simultan\u{00e9}e Kether\u{2192}Malkuth")
                protoStep(n: 5, text: "Icosa\u{00e8}dre \u{00d7} 1 lot \u{2014} 15 consciences f\u{0153}tales D5 ST 9 gauche")
                protoStep(n: 6, text: "Chromoth\u{00e9}rapie pin\u{00e9}ale \u{2014} pH 7.4 orange \u{2192} Yang actif")
                protoStep(n: 7, text: "V\u{00e9}rifier ST 9 gauche \u{2014} SLM post-lib\u{00e9}ration")
                protoStep(n: 8, text: "Linggui Bafa \u{2014} naviguer G\u{2212}15 source XVIIe")
            }
        }
    }

    private func protoStep(n: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(n)")
                .font(.system(.caption, design: .rounded).bold())
                .frame(width: 22, height: 22)
                .background(Color(.systemGray5))
                .clipShape(Circle())
            Text(text).font(.callout)
        }
    }

    // MARK: - 7. Correspondances anatomiques

    private var correspondancesSection: some View {
        sectionCard(title: "7. Correspondances anatomiques", icon: "figure.stand") {
            VStack(spacing: 0) {
                corrHeader
                corrRow("Faux du cerveau", "Kether\u{2192}Malkuth", "GV Du Mai", "Central", "K\u{2192}M")
                corrRow("GV 20 Baihui", "Kether", "GV 20", "Central", "\u{2014}")
                corrRow("ST 9 gauche", "Binah/Geburah", "ST", "Gauche", "M\u{2192}K")
                corrRow("Pin\u{00e9}ale", "Ajna / Daath", "GV 23-24", "Central", "\u{2014}")
                corrRow("SOI", "Tiphereth\u{2192}Yesod", "CV 12", "Central", "\u{2191} bloqu\u{00e9}")
                corrRow("Sphincter pylorique", "Yesod\u{2192}Malkuth", "ST 21", "Central", "\u{2193} lib\u{00e9}rer")
                corrRow("Carotide commune G", "Binah\u{2192}Kether", "ST 9", "Gauche", "\u{2191}")
            }
        }
    }

    private var corrHeader: some View {
        HStack {
            Text("Structure").font(.caption2.bold()).frame(maxWidth: .infinity, alignment: .leading)
            Text("Sephirah").font(.caption2.bold()).frame(maxWidth: .infinity, alignment: .leading)
            Text("M\u{00e9}ridien").font(.caption2.bold()).frame(width: 60, alignment: .leading)
            Text("Pilier").font(.caption2.bold()).frame(width: 55, alignment: .leading)
            Text("Sens").font(.caption2.bold()).frame(width: 45, alignment: .leading)
        }
        .padding(.vertical, 4)
        .background(Color(.systemGray5))
    }

    private func corrRow(_ structure: String, _ seph: String, _ mer: String, _ pilier: String, _ sens: String) -> some View {
        HStack {
            Text(structure).font(.caption2).frame(maxWidth: .infinity, alignment: .leading)
            Text(seph).font(.caption2).frame(maxWidth: .infinity, alignment: .leading)
            Text(mer).font(.system(.caption2, design: .monospaced)).frame(width: 60, alignment: .leading)
            Text(pilier).font(.caption2).frame(width: 55, alignment: .leading)
            Text(sens).font(.caption2).frame(width: 45, alignment: .leading)
        }
        .padding(.vertical, 3)
    }

    // MARK: - 8. Paramètres

    private var parametresSection: some View {
        sectionCard(title: "8. Param\u{00e8}tres SVLBHPanel", icon: "gearshape.2") {
            VStack(alignment: .leading, spacing: 4) {
                paramRow("sens_accumulation", "ascendant | descendant")
                paramRow("mode_d\u{00e9}sintrication", "simultan\u{00e9} | s\u{00e9}quentiel")
                paramRow("condition_simultan\u{00e9}it\u{00e9}", "m\u{00ea}me_axe + m\u{00ea}me_origine_G")
                paramRow("disjoncteur_requis", "Cube_G-n avant d\u{00e9}sintrication")
                paramRow("type_gu", "herm\u{00e9}tique | non-herm\u{00e9}tique | f\u{0153}tal-logoïque")
                paramRow("pilier", "gauche_f\u{00e9}minin | central | droit_masculin")
                paramRow("ph_glandulaire", "valeur + teinte_chromo")
            }
        }
    }

    private func paramRow(_ key: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Text("n\u{0153}ud.\(key)").font(.system(.caption2, design: .monospaced)).foregroundColor(.accentColor)
            Text(":").font(.caption2)
            Text(value).font(.system(.caption2, design: .monospaced)).foregroundColor(.secondary)
        }
    }

    // MARK: - 9. Pédagogie

    private var pedagogieSection: some View {
        sectionCard(title: "9. Valeur p\u{00e9}dagogique", icon: "lightbulb") {
            Text("Le gastroent\u{00e9}rologue observe une dyspepsie matinale r\u{00e9}fractaire K30. La cause r\u{00e9}elle est un Cube non-herm\u{00e9}tique G\u{2212}15 coupant l\u{2019}allumage pin\u{00e9}ale\u{2192}pituitaire \u{00e0} fr\u{00e9}quence orange, h\u{00e9}rit\u{00e9} d\u{2019}une transgression maternelle du XVIIe si\u{00e8}cle, produisant 15 consciences f\u{0153}tales logoïques D5 sur ST 9 gauche, un double verrou sphinct\u{00e9}rien, et des boucles TOC sonores sur la faux du cerveau.")
                .font(.callout)
            Text("Quatre couches. Une seule origine.")
                .font(.headline)
                .padding(.top, 4)
        }
    }

    // MARK: - Section wrapper (style SLM)

    private func sectionCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundColor(Color(hex: "#8B3A62"))
            content()
        }
        .padding(.horizontal, 16)
    }
}
