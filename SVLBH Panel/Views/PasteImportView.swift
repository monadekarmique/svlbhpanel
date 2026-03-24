// SVLBHPanel — Views/PasteImportView.swift
// v0.1.1 — Import par collage texte export VLBH

import SwiftUI

struct PasteImportView: View {
    @EnvironmentObject var session: SessionState
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var pastedText: String = ""
    @State private var importCount: Int? = nil
    @State private var showConfirm = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {

                // Instructions
                HStack(spacing: 8) {
                    Image(systemName: "doc.on.clipboard")
                        .foregroundColor(Color(hex: "#8B3A62"))
                    Text("Colle ici l'export VLBH reçu par WhatsApp ou iMessage")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "#8B3A62").opacity(colorScheme == .dark ? 0.18 : 0.07))

                Divider()

                // Zone de collage
                ZStack(alignment: .topLeading) {
                    if pastedText.isEmpty {
                        Text("=== SVLBH · hDOM · … ===\n\n── DÉCODAGE G. ──\n✓ G-25 | …\n\n── PIERRES ──\n…")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color.secondary.opacity(0.5))
                            .padding(12)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $pastedText)
                        .font(.system(size: 12, design: .monospaced))
                        .padding(8)
                        .background(Color.clear)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()

                // Résultat import
                if let count = importCount {
                    HStack(spacing: 6) {
                        Image(systemName: count > 0 ? "checkmark.circle.fill" : "exclamationmark.circle")
                            .foregroundColor(count > 0 ? Color(hex: "#1D9E75") : .orange)
                        Text(count > 0
                             ? "\(count) éléments importés avec succès"
                             : "Aucun élément reconnu — vérifie le format")
                            .font(.caption.bold())
                            .foregroundColor(count > 0 ? Color(hex: "#1D9E75") : .orange)
                    }
                    .padding(.vertical, 8)
                }

                // Boutons
                HStack(spacing: 12) {
                    Button {
                        pastedText = UIPasteboard.general.string ?? ""
                    } label: {
                        Label("Coller", systemImage: "doc.on.clipboard")
                            .font(.callout.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(hex: "#8B3A62").opacity(colorScheme == .dark ? 0.3 : 0.12))
                            .cornerRadius(10)
                            .foregroundColor(Color(hex: "#8B3A62"))
                    }

                    Button {
                        guard !pastedText.isEmpty else { return }
                        showConfirm = true
                    } label: {
                        Label("Importer", systemImage: "arrow.down.circle.fill")
                            .font(.callout.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(pastedText.isEmpty
                                ? Color.secondary.opacity(0.2)
                                : Color(hex: "#1D9E75"))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    }
                    .disabled(pastedText.isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .navigationTitle("Import WhatsApp")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .alert("Fusionner avec les données actuelles ?", isPresented: $showConfirm) {
                Button("Fusionner") {
                    let count = PasteParser.apply(pastedText, to: session)
                    importCount = count
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Les données importées seront fusionnées avec votre travail existant.")
            }
        }
        .navigationViewStyle(.stack)
    }
}
