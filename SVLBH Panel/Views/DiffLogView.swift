// SVLBHPanel — Views/DiffLogView.swift
// v0.1.0 — Sheet log post-réception

import SwiftUI

struct DiffLogView: View {
    @EnvironmentObject var sync: MakeSyncService
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List(sync.diffLog, id: \.self) { line in
                Text(line)
                    .font(.caption.monospaced())
                    .foregroundColor(
                        line.hasPrefix("📥") || line.hasPrefix("🔀")
                            ? Color(hex: "#8B3A62") : .primary
                    )
            }
            .navigationTitle("Log de synchronisation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}
