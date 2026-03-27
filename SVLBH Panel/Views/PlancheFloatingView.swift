// SVLBHPanel — Views/PlancheFloatingView.swift
// v4.9.0 — Planche Tactique flottante + drag-drop tier/programme

import SwiftUI
import UniformTypeIdentifiers

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
                            .environmentObject(session)
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
            .frame(width: 260)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 4, y: 0)
            )
            .padding(.vertical, 60)
            .padding(.leading, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .transition(.move(edge: .leading).combined(with: .opacity))
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

// MARK: - Section compacte : label + numéros inline + drag & drop

struct PlancheCompactSection: View {
    @EnvironmentObject var session: SessionState
    let category: PlancheCategory
    let profiles: [ShamaneProfile]
    @Binding var selectedProfile: ShamaneProfile?
    @State private var isTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Label catégorie
            Text(category.label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color(hex: category.badgeColor))

            // Numéros des shamanes
            if profiles.isEmpty {
                Text("Glisser ici")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary).italic()
                    .frame(maxWidth: .infinity, minHeight: 30)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 50), spacing: 4)], spacing: 4) {
                    ForEach(profiles) { profile in
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
                            .onDrag {
                                NSItemProvider(object: profile.code as NSString)
                            }
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedProfile = selectedProfile?.code == profile.code ? nil : profile
                                }
                            }
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: category.badgeColor).opacity(isTargeted ? 0.2 : 0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isTargeted ? Color(hex: category.badgeColor) : .clear, lineWidth: 2)
        )
        .cornerRadius(8)
        .onDrop(of: [UTType.plainText], isTargeted: $isTargeted) { providers in
            for provider in providers {
                provider.loadObject(ofClass: NSString.self) { item, _ in
                    guard let code = item as? String else { return }
                    DispatchQueue.main.async {
                        guard var shamane = session.shamaneProfiles.first(where: { $0.code == code }) else { return }

                        switch category {
                        case .tier(let targetTier):
                            guard shamane.tier != targetTier else { return }
                            let newCode = ShamaneProfile.nextCode(tier: targetTier, existing: session.shamaneProfiles)
                            session.removeShamane(shamane)
                            shamane.code = newCode
                            session.shamaneProfiles.append(shamane)

                        case .programme(let prog):
                            guard !shamane.programmes.contains(prog) else { return }
                            shamane.programmes.append(prog)
                            session.updateShamane(shamane)
                        }

                        // PUSH segment vers Make → svlbh-v2
                        let s = shamane
                        Task {
                            await SegmentUpdateService.pushSegment(for: s, autoReply: s.tier == .lead)
                        }
                        selectedProfile = nil
                    }
                }
            }
            return true
        }
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

