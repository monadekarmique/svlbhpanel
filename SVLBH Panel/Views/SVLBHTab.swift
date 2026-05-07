// SVLBHPanel — Views/SVLBHTab.swift
// v4.0.0 — Dashboard + Module Shamane + Distribution

import SwiftUI
import UIKit

struct SVLBHTab: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var session: SessionState
    @EnvironmentObject var sync: MakeSyncService
    @Environment(\.colorScheme) var colorScheme
    @State private var showSessionEdit = false
    @State private var showNewPatient = false
    @State private var patientIdDraft = ""
    @State private var sessionNumDraft = ""
    @State private var exportedText = ""
    @State private var showLogoutConfirm = false
    @State private var showResetConfirm = false
    @State private var showPlanche = false
    @State private var showClosure = false
    @State private var activeSubPage: SubPage?
    @State private var visiteurCount: Int = 0

    enum SubPage: String, Identifiable {
        case slm, chrono, conditions, pr03, pr03Dyspepsie, pr05, pr07, pr09, etApres
        case pierres, therapists, distribution, referenceSystems, researchPrograms
        case pasteImport, exportSheet, history
        var id: String { rawValue }
    }

    /// Abonnement actif — pour l'instant toujours true (isCheckingSubscription)
    private var isSubscriptionActive: Bool { true }

    /// Passerelle visible pour superviseur, Cornelia (0300), Anne (0302)
    private var showPasserelle: Bool {
        if session.role.isSuperviseur { return true }
        if case .shamane(let p) = session.role {
            return ["0300", "0302"].contains(p.codeFormatted)
        }
        return false
    }

    /// Comptes superviseur disponibles (Service API Key pattern : 1 compte = 1 fonction)
    private var supervisorAccounts: [ShamaneProfile] {
        session.shamaneProfiles.filter { $0.tier == .superviseur }
    }

    /// Programmes de recherche visibles pour certifiées et superviseurs
    private var showResearchAccess: Bool {
        return session.role.isSuperviseur || currentTier == .certifiee
    }
    @State private var simulatedTier: PractitionerTier?
    @EnvironmentObject var identity: PractitionerIdentity
    @EnvironmentObject var tracker: SessionTracker

    var slaEstimate: Int {
        let n = session.validatedCount
        return n == 0 ? 89 : max(30, 89 - n * 4)
    }
    var dominantGu: GuType? {
        var c: [GuType: Int] = [:]
        for g in session.visibleGenerations { for gu in g.gu { c[gu, default: 0] += 1 } }
        return c.max(by: { $0.value < $1.value })?.key
    }
    var meridianDominant: (Meridian, Int)? {
        var c: [Meridian: Int] = [:]
        for g in session.visibleGenerations where g.validated { for m in g.meridiens { c[m, default: 0] += 1 } }
        return c.max(by: { $0.value < $1.value }).map { ($0.key, $0.value) }
    }
    var hasFork: Bool {
        session.visibleGenerations.filter { $0.meridiens.contains(.KI) || $0.meridiens.contains(.GB) }.count > 3
    }
    var currentTier: PractitionerTier {
        if let sim = simulatedTier { return sim }
        switch session.role {
        case .unidentified: return .lead
        case .shamane(let s): return s.tier
        }
    }
    // Label carte session selon tier
    var tierSessionLabel: String {
        switch currentTier {
        case .lead: return session.patientId.isEmpty ? "Toi" : "Toi · \(session.patientId)"
        case .formation: return session.patientId.isEmpty ? "—" : session.patientId
        case .certifiee, .superviseur: return session.patientId.isEmpty ? "—" : session.patientId
        }
    }
    var currentTierForkResolu: Bool {
        switch session.role {
        case .unidentified: return false
        case .shamane(let s): return s.tier.forkResolu
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 3) {
                        Text("\u{25c8} SVLBH Cl\u{00e9} \u{00e9}lectromagn\u{00e9}tique")
                            .font(.title2.bold()).foregroundColor(Color(hex: "#8B3A62"))
                        Text("hDOM \u{00b7} Corps de Lumi\u{00e8}re")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    .padding(.top, 14)

                    // WhatsApp par tier (sauf lead — déjà dans SyncBar)
                    if currentTier != .lead, let url = currentTier.whatsappURL {
                        Link(destination: url) {
                            HStack(spacing: 4) {
                                Image(systemName: "message.fill").font(.caption)
                                Text("WhatsApp").font(.caption.bold())
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Color(hex: "#1D9E75")).cornerRadius(8)
                        }
                        .padding(.horizontal, 16)
                    }

                    // ── Carte session (bande rose pleine largeur) ──
                    Button {
                        sessionNumDraft = session.sessionNum
                        showSessionEdit = true
                    } label: {
                        VStack(spacing: 8) {
                        // ── En-t\u{00ea}te : Cl\u{00e9} \u{00e9}lectromagn\u{00e9}tique ──
                        HStack {
                            Text("Cl\u{00e9} \u{00e9}lectromagn\u{00e9}tique \u{00b7} Consultante / Syst\u{00e8}me")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color(hex: "#8B3A62").opacity(0.7))
                            Spacer()
                        }
                        HStack(spacing: 12) {
                            // ── Gauche : Cl\u{00e9} S\u{00e9}phirothique + num\u{00e9}ro ──
                            VStack(spacing: 4) {
                                HStack(spacing: 0) {
                                    ForEach(["Cl\u{00e9} S\u{00e9}phirothique", "Syst\u{00e8}me"], id: \.self) { opt in
                                        let isSys = opt == "Syst\u{00e8}me"
                                        let active = isSys == session.isSysteme
                                        Text(isSys ? "Syst\u{00e8}me" : "Cl\u{00e9} S\u{00e9}ph.")
                                            .font(.system(size: 9, weight: active ? .bold : .regular))
                                            .foregroundColor(active ? .white : Color(hex: "#8B3A62"))
                                            .padding(.horizontal, 5).padding(.vertical, 2)
                                            .background(active ? Color(hex: "#8B3A62") : Color.clear)
                                            .cornerRadius(4)
                                            .onTapGesture { session.isSysteme = isSys }
                                    }
                                }
                                .background(Color(hex: "#8B3A62").opacity(0.12))
                                .cornerRadius(5)
                                Text(tierSessionLabel)
                                    .font(.title2.bold()).foregroundColor(Color(hex: "#8B3A62"))
                            }

                            // ── Centre : Ratios empil\u{00e9}s ──
                            if currentTier == .superviseur || currentTier == .certifiee {
                                VStack(spacing: 6) {
                                    Ratio4DCardSection(passeport: session.passeport)
                                    RatioPlaneteCardSection(passeport: session.passeport)
                                }
                            }

                            // ── Droite : Cat\u{00e9}gorie / Niveau / Code ──
                            VStack(spacing: 4) {
                                Text(currentTier.label)
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 5).padding(.vertical, 2)
                                    .background(Color(hex: currentTier.badgeColor))
                                    .cornerRadius(3)
                                VStack(spacing: 1) {
                                    Text("Niveau").font(.system(size: 8)).foregroundColor(.secondary)
                                    Text(session.sessionNum)
                                        .font(.headline.bold()).foregroundColor(Color(hex: "#BA7517"))
                                }
                                if identity.isSuperviseur, supervisorAccounts.count > 1 {
                                    Menu {
                                        ForEach(supervisorAccounts, id: \.code) { acct in
                                            Button("\(acct.codeFormatted) \u{00b7} \(acct.abonnement.isEmpty ? "Superviseur" : acct.abonnement)") {
                                                identity.identify(code: acct.code, name: acct.prenom)
                                                identity.applyTo(session)
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 2) {
                                            Text(session.role.code)
                                                .font(.system(size: 13, weight: .bold))
                                            Image(systemName: "arrow.left.arrow.right")
                                                .font(.system(size: 8, weight: .bold))
                                        }
                                        .foregroundColor(Color(hex: "#185FA5"))
                                    }
                                } else {
                                    Text(session.role.code)
                                        .font(.system(size: 13, weight: .bold)).foregroundColor(Color(hex: "#185FA5"))
                                }
                                if session.role.isSuperviseur {
                                    Button { showResetConfirm = true } label: {
                                        ZStack {
                                            Circle().stroke(Color(hex: "#E24B4A"), lineWidth: 1.5).frame(width: 22, height: 22)
                                            Text("R").font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundColor(Color(hex: "#E24B4A"))
                                        }
                                    }
                                }
                            }
                        }
                        } // close VStack (en-tête + HStack)
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: "#8B3A62").opacity(colorScheme == .dark ? 0.2 : 0.08))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 16)

                    // ── Historique + Programmes ──
                    HStack {
                        Button {
                            activeSubPage = .history
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.arrow.circlepath").font(.system(size: 12))
                                Text("Historique des cl\u{00e9}s").font(.caption.bold())
                            }
                            .foregroundColor(Color(hex: "#8B3A62"))
                        }
                        .disabled(!isSubscriptionActive)
                        .opacity(isSubscriptionActive ? 1.0 : 0.4)
                        Spacer()
                        if showResearchAccess {
                            Button {
                                activeSubPage = .researchPrograms
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock.arrow.circlepath").font(.system(size: 12))
                                    Text("Programmes").font(.caption.bold())
                                }
                                .foregroundColor(Color(hex: "#8B3A62"))
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    // Push/Pull keys (entre carte session et programme)
                    HStack(spacing: 4) {
                        Text("Push:").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundColor(.secondary)
                        Text(session.pushKey).font(.system(size: 9, design: .monospaced)).foregroundColor(Color(hex: "#1D9E75"))
                        Spacer()
                        Text("Pull:").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundColor(.secondary)
                        Text(session.pullKey).font(.system(size: 9, design: .monospaced)).foregroundColor(Color(hex: "#185FA5"))
                    }
                    .padding(.horizontal, 16)

                    // F30 — Programme (Superviseur only : 00 ↔ 01)
                    if session.role.isSuperviseur || simulatedTier != nil {
                        HStack(spacing: 10) {
                            Text("Programme")
                                .font(.caption.bold()).foregroundColor(.secondary)
                            Picker("", selection: $session.sessionProgramCode) {
                                Text("00 — Non classifiée").tag("00")
                                Text("01 — Recherche").tag("01")
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 4)
                    }

                    // Sélecteur de segment déplacé en haut de la carte

                    // Gui dominant + Méridien dominant + Fork (sous Programme)
                    VStack(spacing: 6) {
                        if let gu = dominantGu {
                            InfoRow(label: "Gui 鬼 dominant", value: gu.rawValue, color: Color(hex: "#D4537E"))
                        }
                        if let (m, n) = meridianDominant {
                            InfoRow(label: "Méridien dominant",
                                    value: "\(m.rawValue) ×\(n)", color: Color(hex: m.color))
                        }
                        if currentTierForkResolu {
                            InfoRow(label: "Fork galactique",
                                    value: "Résolu (certifiée)", color: Color(hex: "#1D9E75"))
                        } else {
                            InfoRow(label: "Fork galactique",
                                    value: hasFork ? "Fork 3.5 Ga détecté" : "Pas de fork majeur",
                                    color: hasFork ? Color(hex: "#E24B4A") : Color(hex: "#1D9E75"))
                        }
                    }
                    .padding(.horizontal, 16)

                    // ── KPIs — Générations+Chakras (gauche) | Scores aligné pleine hauteur (droite) ──
                    HStack(alignment: .top, spacing: 12) {
                        // Colonne gauche : Générations + Chakras empilés
                        VStack(spacing: 12) {
                            Button { selectedTab = 2 } label: {
                                KPICard(icon: "✓", label: "Niveaux",
                                        value: "\(session.validatedCount)/\(session.currentTier.maxGenerations)", color: Color(hex: "#1D9E75"))
                            }.buttonStyle(.plain)

                            Button { selectedTab = 5 } label: {
                                ChakrasKPICard(session: session)
                            }.buttonStyle(.plain)
                        }
                        // Colonne droite : Scores étiré pour remplir la hauteur
                        Button { selectedTab = 3 } label: {
                            ScoresKPICard(session: session, estimated: slaEstimate)
                                .frame(maxHeight: .infinity)
                        }.buttonStyle(.plain)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)

                    // ── Ligne 2 : Pierres sur deux colonnes ──
                    Button { activeSubPage = .pierres } label: {
                        PierresKPICard(session: session)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)

                    // ── Breadcrumb séance ──
                    if tracker.isActive && !tracker.events.isEmpty {
                        VStack(spacing: 8) {
                            SessionBreadcrumbBar()
                                .environmentObject(tracker)

                            // Bouton protocole de clôture
                            Button {
                                showClosure = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "seal.fill")
                                        .font(.caption)
                                    Text("Clôturer la séance")
                                        .font(.caption.bold())
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(Color(hex: "#B8965A"))
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)
                    }

                    // F01 — Visiteurs (Superviseur + Certifiées)
                    if session.role.isSuperviseur || currentTier == .certifiee {
                        LeadSlotsView().environmentObject(session)
                    }

                    // Visiteurs connectés
                    if visiteurCount > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "person.2.fill")
                                .font(.caption2)
                                .foregroundColor(Color(hex: "#BA7517"))
                            Text("\(visiteurCount) visiteur\(visiteurCount > 1 ? "s" : "") connecté\(visiteurCount > 1 ? "s" : "")")
                                .font(.caption2.bold())
                                .foregroundColor(Color(hex: "#BA7517"))
                        }
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color(hex: "#BA7517").opacity(0.08))
                        .cornerRadius(8)
                        .padding(.horizontal, 16)
                    }

                    // ── Custom Tab Bar — sous-pages (même taille que menu haut) ──
                    VStack(spacing: 0) {
                        Divider()
                        HStack(spacing: 0) {
                            customTabButton("Historique", icon: "clock.arrow.circlepath") { activeSubPage = .history }
                            customTabButton("Conditions", icon: "circle.hexagongrid") { activeSubPage = .conditions }
                            customTabButton("Endom\u{00e9}triose", icon: "hurricane") { activeSubPage = .pr03 }
                            customTabButton("Dyspepsie", icon: "arrow.left.arrow.right") { activeSubPage = .pr03Dyspepsie }
                            customTabButton("Scl\u{00e9}roses", icon: "arrow.left.arrow.right") { activeSubPage = .pr09 }
                            customTabButton("Et apr\u{00e8}s", icon: "sparkles") { activeSubPage = .etApres }
                        }
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemBackground))
                    }

                    Spacer().frame(height: 120)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if identity.isSuperviseur {
                        Menu {
                            Button("Superviseur (r\u{00e9}el)") {
                                simulatedTier = nil
                                identity.applyTo(session)
                                session.isSuperviseurSimulating = false
                            }
                            Divider()
                            ForEach(session.shamaneProfiles.filter { $0.tier != .superviseur }, id: \.code) { profile in
                                Button("\(profile.displayName) \u{00b7} \(profile.tier.label) (\(profile.codeFormatted))") {
                                    simulatedTier = profile.tier
                                    session.role = .shamane(profile)
                                    session.isSuperviseurSimulating = true
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text("SVLBH").font(.headline.bold())
                                Image(systemName: "chevron.up.chevron.down").font(.system(size: 9))
                            }
                            .foregroundColor(.primary)
                        }
                    } else {
                        Text("SVLBH").font(.headline.bold())
                    }
                }
                // ── Leading : version + sync + menu (ex-"...") ──
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button {
                            activeSubPage = .pasteImport
                        } label: {
                            Label("Importer", systemImage: "doc.on.clipboard")
                        }
                        Button {
                            exportedText = SessionExporter.export(session)
                            activeSubPage = .exportSheet
                        } label: {
                            Label("Exporter WhatsApp", systemImage: "square.and.arrow.up")
                        }
                        Button {
                            activeSubPage = .history
                        } label: {
                            Label("Historique", systemImage: "clock.arrow.circlepath")
                        }
                        if session.role.isSuperviseur {
                            Divider()
                            Button {
                                activeSubPage = .referenceSystems
                            } label: {
                                Label("Syst\u{00e8}mes de r\u{00e9}f\u{00e9}rence", systemImage: "photo.on.rectangle.angled")
                            }
                            Divider()
                            Button(role: .destructive) {
                                showLogoutConfirm = true
                            } label: {
                                Label("Changer d\u{2019}utilisateur", systemImage: "person.crop.circle.badge.minus")
                            }
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"))")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(Color(hex: "#C27894").opacity(0.7))
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(sync.isSending || sync.isReceiving
                                          ? Color(hex: "#BA7517") : Color(hex: "#1D9E75"))
                                    .frame(width: 6, height: 6)
                                Text(sync.isSending ? "Envoi\u{2026}" : sync.isReceiving ? "R\u{00e9}ception\u{2026}" : "Sync pr\u{00ea}t")
                                    .font(.system(size: 9)).foregroundColor(.secondary)
                            }
                        }
                    }
                }
                // ── Trailing : Planche Tactique ──
                if session.role.isSuperviseur || currentTier == .certifiee {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            withAnimation(.spring(response: 0.3)) { showPlanche.toggle() }
                        } label: {
                            Image(systemName: "rectangle.on.rectangle.angled")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(showPlanche ? Color(hex: "#8B3A62") : .accentColor)
                        }
                    }
                }
            }
            .task {
                let status = await PresenceService.shared.check()
                visiteurCount = status.activeCount
            }
            .sheet(item: $activeSubPage) { page in
                Group {
                    switch page {
                    case .slm: SLMTab()
                    case .chrono: ChronoFuTab()
                    case .conditions: ChakrasTab()
                    case .pr03: ToresLumiereTab()
                    case .pr03Dyspepsie: PasserelleTab()
                    case .pr05: ToreGlycemieScleroseView()
                    case .pr07: PR07HistoriquesTab()
                    case .pr09: PR09SclerosesTab()
                    case .etApres: EtApresTab()
                    case .pierres: PierresTab()
                    case .therapists: TherapistManagerView()
                    case .distribution: DistributionView()
                    case .referenceSystems: ReferenceSystemView()
                    case .researchPrograms: ResearchProgramsView()
                    case .pasteImport: PasteImportView()
                    case .exportSheet: ExportView(text: exportedText)
                    case .history: SessionHistoryView(session: session, syncService: sync)
                    }
                }
                .environmentObject(session)
                .environmentObject(sync)
            }
            .fullScreenCover(isPresented: $showClosure) {
                SessionClosureView(isPresented: $showClosure)
                    .environmentObject(tracker)
            }
        }
        .overlay {
            PlancheFloatingView(isVisible: $showPlanche)
                .environmentObject(session)
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Custom Tab Button
    private func customTabButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 14))
                Text(title).font(.system(size: 8, weight: .medium)).lineLimit(1).minimumScaleFactor(0.7)
            }
            .foregroundColor(Color(hex: "#8B3A62"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .alert("Reset session ?", isPresented: $showResetConfirm) {
            Button("Reset", role: .destructive) { session.resetForShamane() }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Toutes les données de la session seront purgées (scores, générations, pierres, chakras). Cette action est irréversible.")
        }
        .alert("Changer d'utilisateur ?", isPresented: $showLogoutConfirm) {
            Button("Déconnexion", role: .destructive) { identity.logout() }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Vous serez redirigé vers l'écran d'identification.")
        }
        .alert("Identifier la session", isPresented: $showSessionEdit) {
            TextField("Patient (ex: 765)", text: $patientIdDraft).keyboardType(.numberPad)
            TextField("Séance (ex: 001)", text: $sessionNumDraft).keyboardType(.numberPad)
            Button("OK") {
                if !patientIdDraft.isEmpty { session.patientId = patientIdDraft }
                if !sessionNumDraft.isEmpty { session.sessionNum = sessionNumDraft }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Code \(session.role.code) (\(session.role.displayName)) — automatique")
        }
    }
}

// MARK: - Scores KPI
struct ScoresKPICard: View {
    @ObservedObject var session: SessionState; let estimated: Int
    @Environment(\.colorScheme) var colorScheme
    func fmt(_ v: Int?) -> String { v.map { "\($0)%" } ?? "—" }
    var body: some View {
        VStack(spacing: 6) {
            // Thérapeute
            VStack(alignment: .leading, spacing: 4) {
                Text("\u{2640} MyShaFa").font(.system(size:14, weight:.medium)).foregroundColor(.secondary)
                ScoreRow(label:"SLA",    val:fmt(session.scoresTherapist.sla ?? session.slaTherapist), c:Color(hex:"#8B3A62"))
                ScoreRow(label:"SLSA",   val:fmt(session.scoresTherapist.slsa),  c:Color(hex:"#8B3A62"))
                ScoreRow(label:"SLM",    val:fmt(session.scoresTherapist.slm),   c:Color(hex:"#8B3A62"))
                ScoreRow(label:"TotSLM", val:fmt(session.scoresTherapist.totSlm),c:Color(hex:"#8B3A62"))
            }
            Divider().padding(.horizontal, 4)
            // Superviseur
            VStack(alignment: .leading, spacing: 4) {
                Text("Superviseur").font(.system(size:14, weight:.medium)).foregroundColor(.secondary)
                ScoreRow(label:"SLA",    val:fmt(session.scoresPatrick.sla ?? session.slaPatrick), c:Color(hex:"#185FA5"))
                ScoreRow(label:"SLSA",   val:fmt(session.scoresPatrick.slsa),  c:Color(hex:"#185FA5"))
                ScoreRow(label:"SLM",    val:fmt(session.scoresPatrick.slm),   c:Color(hex:"#185FA5"))
                ScoreRow(label:"TotSLM", val:fmt(session.scoresPatrick.totSlm),c:Color(hex:"#185FA5"))
            }
            Text("Scores").font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity).padding(10)
        .background(Color(hex:"#8B3A62").opacity(colorScheme == .dark ? 0.2 : 0.08))
        .cornerRadius(10)
    }
}

struct ScoreRow: View {
    let label: String; let val: String; let c: Color
    var body: some View {
        HStack {
            Text(label).font(.system(size:15, weight:.medium)).foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            Spacer()
            Text(val).font(.system(size:18, weight:.bold)).foregroundColor(c)
        }
    }
}

// MARK: - Pierres KPI
struct PierresKPICard: View {
    @ObservedObject var session: SessionState
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        VStack(spacing: 4) {
            Text("₩").font(.title2)
            if session.selectedPierres.isEmpty {
                Text("—").font(.title3.bold()).foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(session.selectedPierres) { p in
                        HStack(spacing: 3) {
                            Text(p.spec.icon).font(.system(size:9))
                            Text(p.spec.nom).font(.system(size:9, weight:.medium))
                                .foregroundColor(Color(hex:"#8B3A62")).lineLimit(1)
                            Spacer()
                            Text("\(p.durationMin) min")
                                .font(.system(size:8, design:.monospaced)).foregroundColor(.secondary)
                        }
                    }
                }
            }
            Text("Pierres").font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(10)
        .background(Color(hex:"#8B3A62").opacity(colorScheme == .dark ? 0.2 : 0.08))
        .cornerRadius(10)
    }
}

// MARK: - Chakras KPI
struct ChakrasKPICard: View {
    @ObservedObject var session: SessionState
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        VStack(spacing: 4) {
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Text("\(session.cleanedClassicCount)/\(session.totalClassicChakras)")
                        .font(.body.bold()).foregroundColor(Color(hex:"#185FA5"))
                    Text("D1–D9").font(.system(size:9)).foregroundColor(.secondary)
                }
                HStack(spacing: 4) {
                    Text("\(session.cleanedChakrasCount)/\(session.totalChakras)")
                        .font(.caption.bold()).foregroundColor(Color(hex:"#185FA5").opacity(0.7))
                    Text("+ Système").font(.system(size:9)).foregroundColor(.secondary)
                }
            }
            Text("Conditions").font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity).padding(10)
        .background(Color(hex:"#185FA5").opacity(colorScheme == .dark ? 0.2 : 0.08))
        .cornerRadius(10)
    }
}

// MARK: - KPICard générique
struct KPICard: View {
    let icon: String; let label: String; let value: String; let color: Color
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        VStack(spacing: 5) {
            Text(value).font(.title3.bold()).foregroundColor(color)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity).padding(12)
        .background(color.opacity(colorScheme == .dark ? 0.2 : 0.08))
        .cornerRadius(10)
    }
}

// MARK: - InfoRow
struct InfoRow: View {
    let label: String; let value: String; let color: Color
    var body: some View {
        HStack {
            Text(label).font(.caption).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.caption.bold()).foregroundColor(color)
                .textSelection(.enabled)
        }
    }
}

// MARK: - Gestion shamanes (Module Shamane minimum)
struct TherapistManagerView: View {
    @EnvironmentObject var session: SessionState
    @Environment(\.dismiss) var dismiss
    @State private var newPrenom = ""
    @State private var newNom = ""
    @State private var newWhatsapp = ""
    @State private var newEmail = ""
    @State private var newAbo = ""
    @State private var newTier: PractitionerTier = .lead
    @State private var newPatientId = ""

    private static let df: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "dd.MM.yyyy"; return f
    }()

    var body: some View {
        NavigationView {
            List {
                // Formulaire ajout
                Section("Nouvelle shamane") {
                    Picker("Tier", selection: $newTier) {
                        ForEach(PractitionerTier.allCases, id: \.self) { t in
                            Text(t.label).tag(t)
                        }
                    }
                    TextField("Prénom", text: $newPrenom)
                        .textContentType(.givenName)
                    TextField("Nom", text: $newNom)
                        .textContentType(.familyName)
                    TextField("WhatsApp", text: $newWhatsapp)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $newEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Abonnement", text: $newAbo)
                    HStack {
                        Text("N° patient").foregroundColor(.secondary)
                        TextField("1–30000", text: $newPatientId)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    if let n = Int(newPatientId), !(1...30000).contains(n) {
                        Text("Le N° patient doit être entre 1 et 30 000")
                            .font(.caption2).foregroundColor(.red)
                    }
                    Button {
                        let p = newPrenom.trimmingCharacters(in: .whitespaces)
                        guard !p.isEmpty else { return }
                        var shamane = session.addShamane(
                            prenom: p,
                            nom: newNom.trimmingCharacters(in: .whitespaces),
                            whatsapp: newWhatsapp.trimmingCharacters(in: .whitespaces),
                            email: newEmail.trimmingCharacters(in: .whitespaces),
                            abonnement: newAbo.trimmingCharacters(in: .whitespaces),
                            tier: newTier
                        )
                        if let pid = Int(newPatientId), (1...30000).contains(pid) {
                            shamane.patientId = pid
                            session.updateShamane(shamane)
                        }
                        newPrenom = ""; newNom = ""; newWhatsapp = ""
                        newEmail = ""; newAbo = ""; newPatientId = ""
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Ajouter")
                        }
                        .foregroundColor(Color(hex: "#8B3A62"))
                    }
                    .disabled(newPrenom.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                // Liste par tier
                ForEach(PractitionerTier.allCases, id: \.self) { tier in
                    let profiles = session.shamaneProfiles.filter { $0.tier == tier }
                    if !profiles.isEmpty {
                        Section {
                            ForEach(profiles) { s in
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack {
                                        Text(s.displayName).font(.body.bold())
                                        Spacer()
                                        Text(s.codeFormatted)
                                            .font(.caption.monospaced())
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6).padding(.vertical, 2)
                                            .background(Color(hex: tier.badgeColor))
                                            .cornerRadius(4)
                                    }
                                    Label("Patient: \(s.patientId)", systemImage: "person.crop.circle")
                                        .font(.caption).foregroundColor(Color(hex: "#BA7517"))
                                    if !s.whatsapp.isEmpty {
                                        Label(s.whatsapp, systemImage: "phone")
                                            .font(.caption).foregroundColor(.secondary)
                                    }
                                    if !s.email.isEmpty {
                                        Label(s.email, systemImage: "envelope")
                                            .font(.caption).foregroundColor(.secondary)
                                    }
                                    if !s.abonnement.isEmpty {
                                        Label(s.abonnement, systemImage: "creditcard")
                                            .font(.caption).foregroundColor(.secondary)
                                    }
                                    // F02 — Zones déséquilibrées
                                    let activeZones = s.zones.filter { !$0.isEmpty }
                                    if !activeZones.isEmpty {
                                        HStack(spacing: 4) {
                                            Image(systemName: "exclamationmark.triangle").font(.caption2)
                                            Text(activeZones.joined(separator: " · "))
                                                .font(.caption2).foregroundColor(Color(hex: "#E24B4A"))
                                        }
                                    }
                                    if let date = s.prochainFacturation {
                                        Label(Self.df.string(from: date), systemImage: "calendar")
                                            .font(.caption).foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                            .onDelete { indices in
                                let list = profiles
                                for i in indices { session.removeShamane(list[i]) }
                            }
                        } header: {
                            Text("\(tier.label) (\(profiles.count))")
                        }
                    }
                }

                if session.shamaneProfiles.isEmpty {
                    Section {
                        Text("Aucune shamane enregistrée")
                            .foregroundColor(.secondary).italic()
                    }
                }
            }
            .navigationTitle("Shamanes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("OK") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Interface par tier
struct TierHeaderView: View {
    @EnvironmentObject var session: SessionState

    private var tier: PractitionerTier {
        switch session.role {
        case .unidentified: return .lead
        case .shamane(let s): return s.tier
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            // Badge tier
            Text(tier.label)
                .font(.caption.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color(hex: tier.badgeColor))
                .cornerRadius(6)

            // Label selon tier
            switch tier {
            case .lead:
                Text("Toi").font(.subheadline.bold()).foregroundColor(Color(hex: "#8B3A62"))
            case .formation:
                Text(session.role.code).font(.subheadline.bold().monospaced())
            case .certifiee:
                Text(session.role.displayName).font(.subheadline.bold())
            case .superviseur:
                Text("🔬 \(session.role.code)").font(.subheadline.bold().monospaced())
            }

            Spacer()

            // WhatsApp par tier
            if let url = tier.whatsappURL {
                Link(destination: url) {
                    HStack(spacing: 4) {
                        Image(systemName: "message.fill")
                            .font(.caption)
                        Text(tier == .lead ? "Contacte-nous" : "WhatsApp")
                            .font(.caption.bold())
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Color(hex: "#1D9E75"))
                    .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 4)
    }
}

// MARK: - F05 — Aide calcul charges méridiens
struct MeridianHelpView: View {
    @State private var expanded = false
    var body: some View {
        Button { withAnimation { expanded.toggle() } } label: {
            HStack(spacing: 4) {
                Image(systemName: "questionmark.circle")
                    .font(.caption2).foregroundColor(Color(hex: "#185FA5"))
                Text("Comment sont calculées les charges ?")
                    .font(.caption2).foregroundColor(Color(hex: "#185FA5"))
            }
        }
        if expanded {
            Text("Charges méridiens : comptage du nombre de fois qu'un méridien apparaît dans les générations validées (✓). Le méridien dominant est celui avec le plus d'occurrences. Méridiens observés : SP, KI, LR, HT, PC, LU, GB.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(10)
                .background(Color.gray.opacity(0.08))
                .cornerRadius(8)
        }
    }
}

// MARK: - F01 — Visiteurs actifs / en attente
struct LeadSlotsView: View {
    @EnvironmentObject var session: SessionState
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Visiteurs")
                    .font(.caption.bold()).foregroundColor(Color(hex: "#E24B4A"))
                Spacer()
                Text("\(session.activeLeadCount)/\(session.maxActiveLeads)")
                    .font(.caption.bold().monospaced())
                    .foregroundColor(session.canAcceptLead ? Color(hex: "#1D9E75") : Color(hex: "#E24B4A"))
            }
            let active = session.leadSlots.filter { $0.status == .active }
            ForEach(active) { slot in
                HStack {
                    if let s = session.shamaneProfiles.first(where: { $0.code == slot.shamaneCode }) {
                        Text(s.displayName).font(.caption)
                        Text(s.codeFormatted).font(.caption2.monospaced()).foregroundColor(.secondary)
                    } else {
                        Text("Code \(slot.shamaneCode)").font(.caption)
                    }
                    Spacer()
                    Text("LEAD").font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .background(Color(hex: "#E24B4A")).cornerRadius(3)
                }
            }
            let waiting = session.waitingLeads
            if !waiting.isEmpty {
                Divider()
                Text("En attente (\(waiting.count))")
                    .font(.caption2.bold()).foregroundColor(Color(hex: "#BA7517"))
                ForEach(waiting) { slot in
                    HStack {
                        if let s = session.shamaneProfiles.first(where: { $0.code == slot.shamaneCode }) {
                            Text(s.displayName).font(.caption)
                        } else {
                            Text("Code \(slot.shamaneCode)").font(.caption)
                        }
                        Spacer()
                        if session.canAcceptLead {
                            Button("Activer") { session.activateLead(shamaneCode: slot.shamaneCode) }
                                .font(.caption2.bold()).foregroundColor(Color(hex: "#1D9E75"))
                        }
                        Text("EN ATTENTE").font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(Color(hex: "#BA7517")).cornerRadius(3)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(hex: "#E24B4A").opacity(0.06))
        .cornerRadius(10)
        .padding(.horizontal, 16)
    }
}

// MARK: - ShareSheet (UIKit wrapper)
struct ShareSheet: UIViewControllerRepresentable {
    let text: String
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }
    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}
