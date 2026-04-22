// SVLBHPanel — Views/MainTabView.swift
// v4.8.0 — Auto-scan sources + SyncBar badge + SessionTracker + Closure

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var session: SessionState
    @EnvironmentObject var sync: MakeSyncService
    @StateObject private var tracker = SessionTracker()
    @State private var selectedTab = 0
    @State private var showDiffLog = false
    @State private var showPINAlert = false
    @State private var pinInput = ""
    @State private var pendingPayload = ""
    @State private var showTimeline = false
    @State private var showPasserelleAccess = false
    @State private var showSMSComposer = false

    /// Onglet Passerelle visible pour superviseur, Cornelia (0300), Anne (0302)
    private var showPasserelle: Bool {
        if session.role.isSuperviseur { return true }
        if case .shamane(let p) = session.role {
            return ["0300", "0302"].contains(p.codeFormatted)
        }
        return false
    }

    /// L'utilisateur courant n'apparaît pas dans la Planche Tactique
    private var isUnlistedUser: Bool {
        if session.role.isSuperviseur { return false }
        if case .shamane(let p) = session.role {
            return !session.shamaneProfiles.contains(where: { $0.code == p.code })
        }
        return true
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // ── Tabs ──
                TabView(selection: $selectedTab) {
                    SVLBHTab(selectedTab: $selectedTab)
                        .tabItem { Label("SVLBH", systemImage: "atom") }
                        .tag(0)
                if isUnlistedUser {
                    LeadBubbleTab()
                        .tabItem { Label("Comment faire ?", systemImage: "person.wave.2") }
                        .tag(12)
                }
                DecodageTab()
                    .tabItem { Label("Épuisement", systemImage: "list.bullet.rectangle") }
                    .badge(sync.diffs.decode > 0 ? sync.diffs.decode : 0)
                    .tag(2)
                SLMTab()
                    .tabItem { Label("SLM", systemImage: "light.max") }
                    .tag(3)
                ChronoFuTab()
                    .tabItem { Label("Chrono 六腑", systemImage: "clock.arrow.circlepath") }
                    .tag(4)
                ChakrasTab()
                    .tabItem { Label("Conditions", systemImage: "circle.hexagongrid") }
                    .badge(sync.diffs.chakras > 0 ? sync.diffs.chakras : 0)
                    .tag(5)
                ToresLumiereTab()
                    .tabItem { Label("PR 03 Endom\u{00e9}triose", systemImage: "hurricane") }
                    .tag(13)
                if showPasserelle {
                    PasserelleTab()
                        .tabItem { Label("PR 03 Dyspepsie", systemImage: "arrow.left.arrow.right") }
                        .tag(6)
                    ToreGlycemieScleroseView()
                        .tabItem { Label("PR 05 Glyc\u{00e9}mies", systemImage: "hurricane") }
                        .tag(7)
                    PR05GlycemiesTab()
                        .tabItem { Label("PR 05 Glyc\u{00e9}mies", systemImage: "arrow.left.arrow.right") }
                        .tag(8)
                    PR07HistoriquesTab()
                        .tabItem { Label("PR 07 Historiques", systemImage: "arrow.left.arrow.right") }
                        .tag(9)
                    PR09SclerosesTab()
                        .tabItem { Label("PR 09 Scl\u{00e9}roses", systemImage: "arrow.left.arrow.right") }
                        .tag(10)
                    EtApresTab()
                        .tabItem { Label("Et apr\u{00e8}s ?", systemImage: "sparkles") }
                        .tag(11)
                }
            }
            .modifier(TabBarOnlyModifier())
            .environmentObject(session)
            .environmentObject(sync)
            .environmentObject(tracker)
            }  // close VStack (breadcrumb + tabs)

            // ── Timeline panel (rétractable) ──
            SessionTimelinePanel(isVisible: $showTimeline)
                .environmentObject(tracker)

            .onChange(of: selectedTab) { tab in
                switch tab {
                case 1: break  // Comment faire ? — pas de badge
                case 2: sync.diffs.decode = 0
                case 3: break  // SLM
                case 4: sync.diffs.pierres = 0
                case 5: sync.diffs.chakras = 0
                default: break
                }
            }

            // SyncBar uniquement sur l'onglet SVLBH
            if selectedTab == 0 {
                VStack {
                    Spacer()
                    SyncBar(showDiffLog: $showDiffLog,
                            showPINAlert: $showPINAlert,
                            pendingPayload: $pendingPayload)
                        .environmentObject(session)
                        .environmentObject(sync)
                }
                .task {
                    if session.role.isOwner {
                        // Owner : auto-scan des sources shamanes
                        if sync.pendingSources.isEmpty && !sync.isScanning {
                            await sync.scanSources(session: session)
                        }
                    } else if session.role.isIdentified {
                        // Non-owner : vérifier la boîte INBOX pour un soin en attente
                        await sync.checkInbox(session: session)
                        if sync.inboxPullKey != nil {
                            await doPullFromInbox()
                        }
                    }
                }
            }
        }
        .onAppear {
            tracker.startSession()
        }
        .sheet(isPresented: $showDiffLog) {
            DiffLogView().environmentObject(sync)
        }
        .alert("🔐 PIN requis", isPresented: $showPINAlert) {
            TextField("PIN 4 chiffres", text: $pinInput)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)  // iOS détecte le SMS et propose le code
            Button("Valider") { validatePIN() }
            Button("Annuler", role: .cancel) { pendingPayload = ""; pinInput = "" }
        } message: {
            Text("Patrick a envoyé un soin. Entrez le PIN reçu par SMS.")
        }
        .sheet(isPresented: $showSMSComposer) {
            if let phone = sync.smsPhone, let pin = sync.smsPin {
                SMSComposerView(phone: phone, pin: pin) {
                    sync.smsPhone = nil
                    sync.smsPin = nil
                }
            }
        }
        .onChange(of: sync.smsPin) { newPin in
            if newPin != nil && SMSComposerView.canSend {
                showSMSComposer = true
            }
        }
    }

    private func validatePIN() {
        let lines = pendingPayload.split(separator: "\n").map(String.init)
        if let first = lines.first, first.hasPrefix("PIN:") {
            let expected = String(first.dropFirst(4)).trimmingCharacters(in: .whitespaces)
            if pinInput == expected {
                let payload = lines.dropFirst().joined(separator: "\n")
                sync.applyPayload(payload, to: session)
                // sessionNum reste stable pendant le cycle correctif
                // (l'incrément se fait manuellement via nouveau patient/séance)
                sync.lastPin = nil          // P2 fix — effacer le PIN après validation
                showDiffLog = true
            }
        }
        pendingPayload = ""; pinInput = ""
    }

    /// Pull automatique déclenché par la découverte INBOX
    private func doPullFromInbox() async {
        guard let raw = await sync.pull(session: session, manual: true) else { return }
        if raw == "PIN_PENDING" { return }
        let pullKey = session.pullKey
        if raw.hasPrefix("PIN:") {
            // 2FA : le PIN arrive par SMS, la shamane le saisit manuellement
            await MainActor.run {
                pendingPayload = raw
                pinInput = ""  // champ vide — 2FA via SMS
                showPINAlert = true
            }
            await sync.markAsRead(sessionId: pullKey)
        } else {
            await MainActor.run {
                sync.applyPayload(raw, to: session)
                showDiffLog = true
            }
            await sync.markAsRead(sessionId: pullKey)
        }
        await MainActor.run { sync.inboxPullKey = nil }
    }
}

// MARK: - Force bottom tab bar on iPad (iOS 18+)
struct TabBarOnlyModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.tabViewStyle(.tabBarOnly)
        } else {
            content
        }
    }
}
