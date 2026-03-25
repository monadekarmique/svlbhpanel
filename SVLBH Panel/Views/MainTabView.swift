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

    /// L'utilisateur courant n'apparaît pas dans la Planche Tactique
    private var isUnlistedUser: Bool {
        if session.role.isPatrick { return false }
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
                        .tag(1)
                }
                DecodageTab()
                    .tabItem { Label("Épuisement", systemImage: "list.bullet.rectangle") }
                    .badge(sync.diffs.decode > 0 ? sync.diffs.decode : 0)
                    .tag(2)
                SLMTab()
                    .tabItem { Label("SLM", systemImage: "light.max") }
                    .tag(3)
                PierresTab()
                    .tabItem { Label("Pierres", systemImage: "diamond") }
                    .badge(sync.diffs.pierres > 0 ? sync.diffs.pierres : 0)
                    .tag(4)
                ChakrasTab()
                    .tabItem { Label("Conditions", systemImage: "circle.hexagongrid") }
                    .badge(sync.diffs.chakras > 0 ? sync.diffs.chakras : 0)
                    .tag(5)
                if session.role.isPatrick || session.currentTier == .certifiee {
                    PlancheTactiqueTab()
                        .tabItem { Label("Planche", systemImage: "rectangle.on.rectangle.angled") }
                        .tag(6)
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
                VStack(spacing: 0) {
                    SyncBar(showDiffLog: $showDiffLog,
                            showPINAlert: $showPINAlert,
                            pendingPayload: $pendingPayload)
                        .environmentObject(session)
                        .environmentObject(sync)
                    Spacer().frame(height: 49)
                }
                .task {
                    // Auto-scan au lancement si Patrick
                    if session.role.isPatrick && sync.pendingSources.isEmpty && !sync.isScanning {
                        await sync.scanSources(session: session)
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
            TextField("PIN 4 chiffres", text: $pinInput).keyboardType(.numberPad)
            Button("Valider") { validatePIN() }
            Button("Annuler", role: .cancel) { pendingPayload = ""; pinInput = "" }
        } message: {
            Text("Patrick a envoyé des données. Entrez le PIN reçu par iMessage.")
        }
    }

    private func validatePIN() {
        let lines = pendingPayload.split(separator: "\n").map(String.init)
        if let first = lines.first, first.hasPrefix("PIN:") {
            let expected = String(first.dropFirst(4)).trimmingCharacters(in: .whitespaces)
            if pinInput == expected {
                let payload = lines.dropFirst().joined(separator: "\n")
                sync.applyPayload(payload, to: session)
                session.incrementSession()  // P2 — auto-increment séance
                sync.lastPin = nil          // P2 fix — effacer le PIN après validation
                showDiffLog = true
            }
        }
        pendingPayload = ""; pinInput = ""
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
