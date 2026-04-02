// SVLBHPanel — Views/VisiteursSettingsView.swift
// v5.3.4 — Gestion visiteurs : max dynamique + accès certifiées

import SwiftUI

struct VisiteursSettingsView: View {
    @EnvironmentObject var session: SessionState
    @Environment(\.dismiss) private var dismiss

    /// Codes certifiées ayant accès au menu Visiteurs (persisté)
    private static let accessKey = "svlbh_visiteurs_access_codes"

    static func allowedCodes() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: accessKey) ?? ["0300", "0302"])
    }

    static func hasAccess(code: String) -> Bool {
        allowedCodes().contains(code)
    }

    @State private var allowedCodes: Set<String> = VisiteursSettingsView.allowedCodes()

    var body: some View {
        NavigationView {
            List {
                // Max visiteurs
                Section("Capacité visiteurs") {
                    Stepper("Maximum : \(session.maxActiveLeads)", value: $session.maxActiveLeads, in: 1...100)
                    HStack {
                        Text("Connectés actuellement")
                            .font(.caption).foregroundColor(.secondary)
                        Spacer()
                        Text("\(session.activeLeadCount)")
                            .font(.caption.bold())
                            .foregroundColor(session.canAcceptLead ? Color(hex: "#1D9E75") : Color(hex: "#E24B4A"))
                    }
                }

                // Accès certifiées
                Section("Certifiées avec accès Visiteurs") {
                    ForEach(session.shamaneProfiles.filter { $0.tier == .certifiee }) { s in
                        Button {
                            if allowedCodes.contains(s.codeFormatted) {
                                allowedCodes.remove(s.codeFormatted)
                            } else {
                                allowedCodes.insert(s.codeFormatted)
                            }
                            UserDefaults.standard.set(Array(allowedCodes), forKey: Self.accessKey)
                        } label: {
                            HStack {
                                Text(s.displayName)
                                    .foregroundColor(.primary)
                                Text(s.codeFormatted)
                                    .font(.caption.bold().monospaced())
                                    .foregroundColor(Color(hex: "#8B3A62"))
                                Spacer()
                                if allowedCodes.contains(s.codeFormatted) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color(hex: "#1D9E75"))
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Visiteurs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}
