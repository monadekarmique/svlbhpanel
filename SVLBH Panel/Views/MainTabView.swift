// SVLBHPanel — Views/MainTabView.swift
// v4.8.0 — Auto-scan sources + SyncBar badge + SessionTracker + Closure

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var session: SessionState
    @EnvironmentObject var sync: MakeSyncService
    @StateObject private var tracker = SessionTracker()
    // PDL managers lifted to top-level pour partager entre Palette/Diagnostic/Séance/Décodage
    // promus en onglets de premier niveau (Patrick 2026-05-04).
    @StateObject private var pdlChromo = ChromotherapyManager()
    @StateObject private var pdlElements = FiveElementsManager()
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

    @State private var showImport = false
    @State private var showExport = false
    @State private var exportedText = ""
    @State private var showHotline = false

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // ── 3 onglets : Routine du Matin + Tores + Épuisement ──
                // (refonte 2026-05-03 : SVLBHTab/Planche Tactique retirés ; SVLBHTab
                //  sera migré vers SVLBH Clé Electromagnétique dans une prochaine release.
                //  Onglet Tores ré-exposé directement 2026-05-04 sur demande Patrick.)
                TabView(selection: $selectedTab) {
                    RoutineMatinTab()
                        .tabItem { Label("Routine du matin", systemImage: "sunrise.fill") }
                        .tag(0)

                    NavigationStack { PDLPaletteView()
                        .navigationTitle("Palette 5 \u{00e9}l\u{00e9}ments")
                        .navigationBarTitleDisplayMode(.inline)
                    }
                    .environmentObject(pdlChromo).environmentObject(pdlElements)
                    .tabItem { Label("Palette", systemImage: "paintpalette.fill") }
                    .tag(3)

                    NavigationStack { PDLDiagnosticView()
                        .navigationTitle("Diagnostic")
                        .navigationBarTitleDisplayMode(.inline)
                    }
                    .environmentObject(pdlChromo).environmentObject(pdlElements)
                    .tabItem { Label("Diagnostic", systemImage: "waveform.path.ecg") }
                    .tag(4)

                    NavigationStack { PDLSessionView()
                        .navigationTitle("S\u{00e9}ance")
                        .navigationBarTitleDisplayMode(.inline)
                    }
                    .environmentObject(pdlChromo).environmentObject(pdlElements)
                    .tabItem { Label("S\u{00e9}ance", systemImage: "rays") }
                    .tag(5)

                    NavigationStack { PDLDecodageView()
                        .navigationTitle("D\u{00e9}codage")
                        .navigationBarTitleDisplayMode(.inline)
                    }
                    .environmentObject(pdlChromo).environmentObject(pdlElements)
                    .tabItem { Label("D\u{00e9}codage", systemImage: "tree") }
                    .tag(6)

                    ToresLumiereTab()
                        .tabItem { Label("Tores", systemImage: "hurricane") }
                        .tag(1)

                    DecodageTab()
                        .tabItem { Label("\u{00c9}puisement", systemImage: "list.bullet.rectangle") }
                        .badge(sync.diffs.decode > 0 ? sync.diffs.decode : 0)
                        .tag(2)

                    // Impo — d\u{00e9}clenche le sheet import
                    Color.clear
                        .tabItem { Label("Impo", systemImage: "doc.on.clipboard") }
                        .tag(100)
                        .onAppear {
                            if selectedTab == 100 {
                                showImport = true
                                selectedTab = 0
                            }
                        }

                    // Expo — d\u{00e9}clenche le sheet export
                    Color.clear
                        .tabItem { Label("Expo", systemImage: "square.and.arrow.up") }
                        .tag(101)
                        .onAppear {
                            if selectedTab == 101 {
                                exportedText = SessionExporter.export(session)
                                showExport = true
                                selectedTab = 0
                            }
                        }
                }
                .environmentObject(session)
                .environmentObject(sync)
                .environmentObject(tracker)
            }  // close VStack

            // ── Bouton ⚡ Hotline flottant (Patrick 2026-05-04) ──
            // Ouvre le sidebar PDLHotlineSidebarView (style overlay slide-in)
            // depuis la home, comme dans Palette de Lumière.
            // sheet() au lieu d'overlay car WKWebView (Tores) écrase les overlays SwiftUI
            // (problème de z-order connu sur iOS 18).
            VStack {
                HStack {
                    Spacer()
                    // Lien praticiennes (logo Cercle de Lumière → svlbh-com.onrender.com/praticiennes)
                    Link(destination: URL(string: "https://svlbh-com.onrender.com/praticiennes")!) {
                        Image("cercle_de_lumiere")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                            .background(Circle().fill(Color(.systemBackground).opacity(0.95)).padding(-3))
                            .shadow(color: .black.opacity(0.15), radius: 4)
                    }
                    .padding(.trailing, 8)
                    .padding(.top, 8)
                    // Bouton ⚡ Hotline
                    Button { showHotline = true } label: {
                        Image(systemName: "bolt.circle.fill")
                            .font(.title)
                            .foregroundStyle(Color(hex: "#8B3A62"))
                            .padding(8)
                            .background(Circle().fill(Color(.systemBackground).opacity(0.95)))
                            .shadow(color: .black.opacity(0.15), radius: 4)
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 8)
                }
                Spacer()
            }
            .zIndex(1000)

            // ── Timeline panel (rétractable) ──
            SessionTimelinePanel(isVisible: $showTimeline)
                .environmentObject(tracker)

            .onChange(of: selectedTab) { tab in
                if tab == 2 { sync.diffs.decode = 0 }
            }
        }
        .onAppear {
            tracker.startSession()
        }
        .sheet(isPresented: $showHotline) {
            NavigationStack {
                PDLHotlineSidebarView(isOpen: $showHotline, embedded: true)
                    .navigationTitle("Hotline")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Fermer") { showHotline = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showImport) {
            PasteImportView().environmentObject(session).environmentObject(sync)
        }
        .sheet(isPresented: $showExport) {
            ExportView(text: exportedText)
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
