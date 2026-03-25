// SVLBHPanel — Views/PlancheFloatingView.swift
// v4.8.0 — Planche Tactique flottante sur onglet SVLBH

import SwiftUI

struct PlancheFloatingView: View {
    @EnvironmentObject var session: SessionState
    @Binding var isVisible: Bool
    @State private var selectedProfile: ShamaneProfile?

    var body: some View {
        if isVisible && (session.role.isPatrick || session.currentTier == .certifiee) {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "rectangle.on.rectangle.angled")
                        .font(.caption).foregroundColor(Color(hex: "#8B3A62"))
                    Text("Planche Tactique")
                        .font(.caption.bold())
                        .foregroundColor(Color(hex: "#8B3A62"))
                    Spacer()
                    Button { withAnimation(.spring(response: 0.3)) { isVisible = false } } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 8)

                Divider()

                // Segments avec numéros
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(PlancheCategory.allCases, id: \.self) { cat in
                            PlancheCompactSection(
                                category: cat,
                                profiles: profiles(for: cat),
                                selectedProfile: $selectedProfile
                            )
                        }
                    }
                    .padding(10)
                }

                // Détail si profil sélectionné
                if let profile = selectedProfile {
                    Divider()
                    PlancheProfileDetail(
                        profile: profile,
                        allCategories: categoriesFor(profile),
                        onClose: { selectedProfile = nil }
                    )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
            )
            .padding(.horizontal, 12)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func profiles(for category: PlancheCategory) -> [ShamaneProfile] {
        switch category {
        case .tier(let t):
            return session.shamaneProfiles.filter { $0.tier == t }
        case .programme(let p):
            return session.shamaneProfiles.filter { $0.programmes.contains(p) }
        }
    }

    private func categoriesFor(_ profile: ShamaneProfile) -> [PlancheCategory] {
        PlancheCategory.allCases.filter { cat in
            switch cat {
            case .tier(let t): return profile.tier == t
            case .programme(let p): return profile.programmes.contains(p)
            }
        }
    }
}

// MARK: - Section compacte : label + numéros inline

struct PlancheCompactSection: View {
    let category: PlancheCategory
    let profiles: [ShamaneProfile]
    @Binding var selectedProfile: ShamaneProfile?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Label catégorie
            Text(category.label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color(hex: category.badgeColor))

            // Numéros des shamanes
            if profiles.isEmpty {
                Text("—")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 50), spacing: 4)], spacing: 4) {
                    ForEach(profiles) { profile in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedProfile = selectedProfile?.code == profile.code ? nil : profile
                            }
                        } label: {
                            Text(profile.codeFormatted)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(selectedProfile?.code == profile.code ? .white : Color(hex: category.badgeColor))
                                .padding(.horizontal, 7).padding(.vertical, 3)
                                .background(
                                    selectedProfile?.code == profile.code
                                        ? Color(hex: category.badgeColor)
                                        : Color(hex: category.badgeColor).opacity(0.12)
                                )
                                .cornerRadius(5)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(8)
        .background(Color(hex: category.badgeColor).opacity(0.04))
        .cornerRadius(8)
    }
}

// MARK: - Détail profil : catégories d'appartenance

struct PlancheProfileDetail: View {
    let profile: ShamaneProfile
    let allCategories: [PlancheCategory]
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(profile.displayName)
                    .font(.subheadline.bold())
                Text(profile.codeFormatted)
                    .font(.caption.bold().monospaced())
                    .foregroundColor(.white)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color(hex: profile.tier.badgeColor))
                    .cornerRadius(4)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle")
                        .font(.caption).foregroundColor(.secondary)
                }
            }

            // Catégories d'appartenance
            Text("Appartient à :")
                .font(.caption2).foregroundColor(.secondary)

            ForEach(allCategories, id: \.self) { cat in
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: cat.badgeColor))
                        .frame(width: 8, height: 8)
                    Text(cat.label)
                        .font(.caption.bold())
                        .foregroundColor(Color(hex: cat.badgeColor))
                }
            }

            if !profile.whatsapp.isEmpty {
                Label(profile.whatsapp, systemImage: "phone")
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(10)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
        .padding(.horizontal, 10).padding(.bottom, 8)
    }
}

