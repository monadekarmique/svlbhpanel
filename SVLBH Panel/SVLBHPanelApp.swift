// SVLBHPanel — SVLBHPanelApp.swift
// v4.8.0 — Entry point avec identification praticien + auto-identify vendorID

import SwiftUI

@main
struct SVLBHPanelApp: App {
    @StateObject private var session = SessionState()
    @StateObject private var sync = MakeSyncService()
    @StateObject private var identity = PractitionerIdentity()
    @Environment(\.scenePhase) private var scenePhase
    @State private var subscriptionStatus: SubscriptionStatus?
    @State private var isCheckingSubscription = false

    var body: some Scene {
        WindowGroup {
            if !identity.isIdentified {
                OnboardingView()
                    .environmentObject(identity)
                    .environmentObject(session)
                    .preferredColorScheme(.light)
            } else if let sub = subscriptionStatus, !sub.isActive {
                SubscriptionWallView(status: sub) {
                    Task { await checkSubscription() }
                }
                .preferredColorScheme(.light)
            } else {
                MainTabView()
                    .environmentObject(session)
                    .environmentObject(sync)
                    .environmentObject(identity)
                    .environmentObject(SegmentUpdateService.shared)
                    .preferredColorScheme(.light)
                    .onAppear {
                        identity.applyTo(session)
                        MakeSyncService.requestNotificationPermission()
                    }
                    .task {
                        if subscriptionStatus == nil {
                            await checkSubscription()
                        }
                        await SegmentUpdateService.shared.checkWhatsAppConnectivity()
                    }
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background, identity.tier == .lead {
                let leadId = PresenceService.shared.leadId
                Task { await PresenceService.shared.disconnect(leadId: leadId) }
            }
            if phase == .active {
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
            if phase == .active, identity.isIdentified, identity.tier == .lead {
                let leadId = PresenceService.shared.leadId
                Task { await PresenceService.shared.register(leadId: leadId, tier: "lead") }
            }
        }
    }

    private func checkSubscription() async {
        let code = identity.code
        guard !code.isEmpty else { return }
        // Superviseur = toujours actif
        if identity.isPatrick {
            await MainActor.run {
                subscriptionStatus = SubscriptionStatus(code: code, status: "active",
                                                        paidUntil: "2099-12-31", trialDaysLeft: nil)
            }
            return
        }
        let status = await SubscriptionService.shared.check(code: code)
        await MainActor.run { subscriptionStatus = status }
    }
}
