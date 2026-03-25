// SVLBHPanel — Views/PlancheTactiqueTab.swift
// Planche Tactique — Mindzip de cartes shamanes par catégorie

import SwiftUI

// MARK: - Catégorie unifiée (tier + programme)

enum PlancheCategory: Hashable, CaseIterable {
    case tier(PractitionerTier)
    case programme(ShamaneProgramme)

    static var allCases: [PlancheCategory] {
        [.tier(.certifiee), .tier(.formation), .tier(.lead),
         .programme(.protection), .programme(.mySha), .programme(.myShaFa)]
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
        .onTapGesture(count: 2) {
            showProgrammePicker = true
        }
        .onDrag {
            NSItemProvider(object: profile.code as NSString)
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
        if programme == .aucun {
            updated.programmes = []
        } else if updated.programmes.contains(programme) {
            updated.programmes.removeAll { $0 == programme }
        } else {
            updated.programmes.append(programme)
        }
        session.updateShamane(updated)
    }
}

// MARK: - Drop conditionnel (uniquement sur sections programme)

extension View {
    @ViewBuilder
    func conditionalDrop(category: PlancheCategory, session: SessionState) -> some View {
        if category.isProgramme {
            self.onDrop(of: [.text], isTargeted: nil) { providers in
                guard case .programme(let prog) = category else { return false }
                for provider in providers {
                    provider.loadObject(ofClass: NSString.self) { item, _ in
                        guard let code = item as? String else { return }
                        DispatchQueue.main.async {
                            if var shamane = session.shamaneProfiles.first(where: { $0.code == code }) {
                                if !shamane.programmes.contains(prog) {
                                    shamane.programmes.append(prog)
                                }
                                session.updateShamane(shamane)
                            }
                        }
                    }
                }
                return true
            }
        } else {
            self
        }
    }
}
