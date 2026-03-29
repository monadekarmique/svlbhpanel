// SVLBHPanel — Views/PlancheTactiqueTab.swift
// Planche Tactique — Mindzip de cartes shamanes par catégorie

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Catégorie unifiée (tier + programme)

enum PlancheCategory: Hashable, CaseIterable {
    case tier(PractitionerTier)
    case programme(ShamaneProgramme)

    static var allCases: [PlancheCategory] {
        [.tier(.certifiee), .tier(.formation), .tier(.lead),
         .programme(.leadChaud), .programme(.protection), .programme(.mySha), .programme(.formee), .programme(.myShaFa)]
    }

    var label: String {
        switch self {
        case .tier(let t):       return t.label
        case .programme(let p):  return p.label
        }
    }

    var badgeColor: String {
        switch self {
        case .tier(let t):       return t.badgeColor
        case .programme(let p):  return p.badgeColor
        }
    }

    var isProgramme: Bool {
        if case .programme = self { return true }
        return false
    }

    var isTier: Bool {
        if case .tier = self { return true }
        return false
    }
}

// MARK: - Tab principal

struct PlancheTactiqueTab: View {
    @EnvironmentObject var session: SessionState

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(PlancheCategory.allCases, id: \.self) { cat in
                        PlancheSectionView(category: cat, profiles: profiles(for: cat))
                            .environmentObject(session)
                    }
                    // ORCID
                    Link(destination: URL(string: "https://orcid.org/0009-0007-9183-8018")!) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.text.rectangle")
                                .font(.caption)
                            Text("ORCID 0009-0007-9183-8018")
                                .font(.caption.monospaced())
                        }
                        .foregroundColor(Color(hex: "#A6CE39"))
                        .padding(.top, 8)
                    }
                }
                .padding()
            }
            .navigationTitle("Planche Tactique")
            .navigationBarTitleDisplayMode(.inline)
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
}

// MARK: - Section

struct PlancheSectionView: View {
    @EnvironmentObject var session: SessionState
    let category: PlancheCategory
    let profiles: [ShamaneProfile]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // En-tête section
            HStack {
                Text(category.label)
                    .font(.headline.bold())
                    .foregroundColor(Color(hex: category.badgeColor))
                Spacer()
                Text("\(profiles.count)")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(Color(hex: category.badgeColor))
                    .cornerRadius(10)
            }

            if profiles.isEmpty {
                Text("Aucune shamane")
                    .font(.caption).foregroundColor(.secondary).italic()
                    .padding(.vertical, 4)
            } else {
                ForEach(profiles) { profile in
                    ShamaneCardView(profile: profile)
                        .environmentObject(session)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: category.badgeColor).opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: category.badgeColor).opacity(0.2), lineWidth: 1)
        )
        // Zone de drop pour les sections programme
        .conditionalDrop(category: category, session: session)
    }
}

// MARK: - Carte mémoire shamane

struct ShamaneCardView: View {
    @EnvironmentObject var session: SessionState
    let profile: ShamaneProfile
    @State private var showProgrammePicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Ligne 1: Nom + code badge
            HStack {
                Text(profile.displayName)
                    .font(.subheadline.bold())
                Spacer()
                Text(profile.codeFormatted)
                    .font(.caption2.monospaced())
                    .foregroundColor(.white)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color(hex: profile.tier.badgeColor))
                    .cornerRadius(4)
            }

            // Ligne 2: WhatsApp
            if !profile.whatsapp.isEmpty {
                Label(profile.whatsapp, systemImage: "phone")
                    .font(.caption).foregroundColor(.secondary)
            }

            // Ligne 3: Email
            if !profile.email.isEmpty {
                Label(profile.email, systemImage: "envelope")
                    .font(.caption).foregroundColor(.secondary)
            }

            // Ligne 4: Programmes actuels
            if !profile.programmes.isEmpty {
                ForEach(profile.programmes, id: \.self) { prog in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: prog.badgeColor))
                            .frame(width: 8, height: 8)
                        Text(prog.label)
                            .font(.caption2.bold())
                            .foregroundColor(Color(hex: prog.badgeColor))
                    }
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
        )
        .onDrag {
            NSItemProvider(object: profile.code as NSString)
        }
        .onTapGesture(count: 2) {
            showProgrammePicker = true
        }
        .confirmationDialog("Programme", isPresented: $showProgrammePicker) {
            ForEach(ShamaneProgramme.allCases, id: \.self) { prog in
                Button(prog.label) {
                    assignProgramme(prog)
                }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Attribuer \(profile.displayName) à un programme")
        }
    }

    private func assignProgramme(_ programme: ShamaneProgramme) {
        var updated = profile
        let wasProtection = updated.programmes.contains(.protection)
        if programme == .aucun {
            updated.programmes = []
        } else if updated.programmes.contains(programme) {
            updated.programmes.removeAll { $0 == programme }
        } else {
            updated.programmes.append(programme)
        }
        session.updateShamane(updated)

        // Push segment vers Make → svlbh-v2
        Task {
            await SegmentUpdateService.pushSegment(for: updated, autoReply: updated.tier == .lead)

            // Protection de la Sur-Âme : hériter les pierres de Patrick (bays.patrick@icloud.com)
            if programme == .protection && !wasProtection {
                await SegmentUpdateService.pushProtectionPierres(for: updated, pierres: session.pierres)
            }
        }
    }
}

// MARK: - Drop sur sections (tier + programme)

/// Pending tier mutation awaiting user confirmation
struct PendingTierMutation: Identifiable {
    let id = UUID()
    let shamaneCode: String
    let shamaneName: String
    let targetTier: PractitionerTier
    let newCode: String
}

struct DropTargetModifier: ViewModifier {
    let category: PlancheCategory
    @ObservedObject var session: SessionState
    @State private var pendingMutation: PendingTierMutation?

    func body(content: Content) -> some View {
        content
            .onDrop(of: [UTType.plainText], isTargeted: nil) { providers in
                for provider in providers {
                    provider.loadObject(ofClass: NSString.self) { item, _ in
                        guard let code = item as? String else { return }
                        DispatchQueue.main.async {
                            guard let shamane = session.shamaneProfiles.first(where: { $0.code == code }) else { return }

                            switch category {
                            case .tier(let targetTier):
                                guard shamane.tier != targetTier else { return }
                                let newCode = ShamaneProfile.nextCode(tier: targetTier, existing: session.shamaneProfiles)

                                // Confirmation requise pour formation → certifiée
                                if shamane.tier == .formation && targetTier == .certifiee {
                                    pendingMutation = PendingTierMutation(
                                        shamaneCode: shamane.code,
                                        shamaneName: shamane.displayName,
                                        targetTier: targetTier,
                                        newCode: newCode
                                    )
                                    return
                                }

                                applyTierChange(shamaneCode: shamane.code, newCode: newCode)

                            case .programme(let prog):
                                guard !shamane.programmes.contains(prog) else { return }
                                var updated = shamane
                                updated.programmes.append(prog)
                                session.updateShamane(updated)

                                let s = updated
                                Task {
                                    await SegmentUpdateService.pushSegment(for: s, autoReply: s.tier == .lead)
                                    if prog == .protection {
                                        await SegmentUpdateService.pushProtectionPierres(for: s, pierres: session.pierres)
                                    }
                                }
                            }
                        }
                    }
                }
                return true
            }
            .alert(item: $pendingMutation) { mutation in
                Alert(
                    title: Text("Certification"),
                    message: Text("Muter \(mutation.shamaneName) en \(mutation.newCode) certifiée et supprimer ses clés de formation ?\n\nLes clés de recherche importantes sont conservées par Patrick."),
                    primaryButton: .destructive(Text("Confirmer")) {
                        applyTierChange(shamaneCode: mutation.shamaneCode, newCode: mutation.newCode)
                    },
                    secondaryButton: .cancel(Text("Annuler"))
                )
            }
    }

    private func applyTierChange(shamaneCode: String, newCode: String) {
        guard var shamane = session.shamaneProfiles.first(where: { $0.code == shamaneCode }) else { return }
        session.removeShamane(shamane)
        shamane.code = newCode
        session.shamaneProfiles.append(shamane)

        let s = shamane
        Task {
            await SegmentUpdateService.pushSegment(for: s, autoReply: s.tier == .lead)
        }
    }
}

extension View {
    @ViewBuilder
    func conditionalDrop(category: PlancheCategory, session: SessionState) -> some View {
        self.modifier(DropTargetModifier(category: category, session: session))
    }
}
