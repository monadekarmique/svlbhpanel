// SVLBHPanel — SVLBHPanelApp.swift
// v4.8.0 — Entry point avec identification praticien + auto-identify vendorID

import SwiftUI

@main
struct SVLBHPanelApp: App {
    @StateObject private var session = SessionState()
    @StateObject private var sync = MakeSyncService()
    @StateObject private var identity = PractitionerIdentity()
    @StateObject private var hdomAgent = HDOMSessionAgentService()
    @Environment(\.scenePhase) private var scenePhase
    @State private var subscriptionStatus: SubscriptionStatus?
    @State private var isCheckingSubscription = false
    @State private var buildBlocked = false
    @State private var buildStatus: BuildGateService.BuildStatus?

    var body: some Scene {
        WindowGroup {
            if buildBlocked, let status = buildStatus {
                BuildGateView(status: status)
                    .preferredColorScheme(.light)
            } else if !identity.isIdentified {
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
                    .environmentObject(hdomAgent)
                    .preferredColorScheme(.light)
                    .onAppear {
                        identity.applyTo(session)
                        MakeSyncService.requestNotificationPermission()
                    }
                    .task {
                        await checkBuildGate()
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
                // Re-vérifier le build gate à chaque retour foreground
                if identity.isIdentified, !identity.isPatrick {
                    Task { await checkBuildGate() }
                }
            }
            if phase == .active, identity.isIdentified, identity.tier == .lead {
                let leadId = PresenceService.shared.leadId
                Task { await PresenceService.shared.register(leadId: leadId, tier: "lead") }
            }
        }
    }

    private func checkBuildGate() async {
        // Patrick (superviseur) n'est jamais bloqué
        guard !identity.isPatrick else { return }
        let status = await BuildGateService.shared.check()
        await MainActor.run {
            buildStatus = status
            buildBlocked = !status.isAllowed
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
