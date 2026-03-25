// SVLBHPanel — SVLBHPanelApp.swift
// v4.8.0 — Entry point avec identification praticien + auto-identify vendorID

import SwiftUI

@main
struct SVLBHPanelApp: App {
    @StateObject private var session = SessionState()
    @StateObject private var sync = MakeSyncService()
    @StateObject private var identity = PractitionerIdentity()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            if identity.isIdentified {
                MainTabView()
                    .environmentObject(session)
                    .environmentObject(sync)
                    .environmentObject(identity)
                    .preferredColorScheme(.light)
                    .onAppear { identity.applyTo(session) }
            } else {
                OnboardingView()
                    .environmentObject(identity)
                    .environmentObject(session)
                    .preferredColorScheme(.light)
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background, identity.tier == .lead {
                let leadId = PresenceService.shared.leadId
                Task { await PresenceService.shared.disconnect(leadId: leadId) }
            }
            if phase == .active, identity.isIdentified, identity.tier == .lead {
                let leadId = PresenceService.shared.leadId
                Task { await PresenceService.shared.register(leadId: leadId, tier: "lead") }
            }
        }
    }
}
