// SVLBHPanel — Views/ExportView.swift
// v1.4.1 — P0 : Copier clipboard + ShareSheet fallback

import SwiftUI
import UIKit

struct ExportView: View {
    let text: String
    @Environment(\.dismiss) var dismiss
    @State private var copied = false
    @State private var showShareSheet = false

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // ── Preview (sélectionnable) ──
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(text)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.primary.opacity(0.85))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Divider()
                        Text("SVLBH Panel v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"))")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                }
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal, 16)

                // ── Actions ──
                VStack(spacing: 10) {
                    // ── Bouton COPIER (principal) ──
                    Button {
                        UIPasteboard.general.string = text
                        copied = true
                        let g = UIImpactFeedbackGenerator(style: .medium)
                        g.impactOccurred()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            copied = false
                        }
                    } label: {
                        HStack {
                            Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                            Text(copied ? "Copié ✓" : "Copier dans le presse-papier")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(copied ? Color(hex: "#1D9E75") : Color(hex: "#8B3A62"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }

                    // ── Bouton PARTAGER (secondaire) ──
                    Button {
                        showShareSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Partager…")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .navigationTitle("Export Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("OK") { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(text: text)
            }
        }
    }
}
