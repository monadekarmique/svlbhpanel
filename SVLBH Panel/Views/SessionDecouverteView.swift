//
//  SessionDecouverteView.swift
//  SVLBH Panel — SVLBH Session Découverte (ex SVLBH Demande)
//

import SwiftUI

struct SessionDecouverteView: View {
    @State private var showChronoFu = false

    var body: some View {
        ChronoFuSidePanel(isOpen: $showChronoFu) {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        stepsSection
                    }
                    .padding()
                }
                .navigationTitle("Session Découverte")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        ChronoFuToolbarButton(isOpen: $showChronoFu)
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(Color.accentColor)

            Text("Bienvenue dans votre\nsession découverte")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            Text("Explorez les fondamentaux de la méthode SVLBH à travers une session guidée.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ÉTAPES").font(.caption).foregroundStyle(.secondary).tracking(0.7)

            StepRow(number: 1, title: "Identification", subtitle: "Vérifiez votre profil énergétique", icon: "person.crop.circle")
            StepRow(number: 2, title: "Palette de Lumière", subtitle: "Découvrez votre spectre chromatique", icon: "paintpalette")
            StepRow(number: 3, title: "Chrono 六腑", subtitle: "Synchronisez avec les méridiens actifs", icon: "clock.arrow.circlepath")
            StepRow(number: 4, title: "Bilan", subtitle: "Recevez vos recommandations personnalisées", icon: "doc.text")
        }
    }
}

private struct StepRow: View {
    let number: Int
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(number). \(title)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
