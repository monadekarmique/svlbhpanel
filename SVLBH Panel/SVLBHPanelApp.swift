// SVLBHPanel — SVLBHPanelApp.swift
// v4.2.10 — Entry point avec identification praticien

import SwiftUI

@main
struct SVLBHPanelApp: App {
    @StateObject private var session = SessionState()
    @StateObject private var sync = MakeSyncService()
    @StateObject private var identity = PractitionerIdentity()

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
    }
}
