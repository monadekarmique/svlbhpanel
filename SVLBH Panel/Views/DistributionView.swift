// SVLBHPanel — Views/DistributionView.swift
// Gestion listes de distribution (programmes) + groupes thématiques

import SwiftUI

// MARK: - Vue principale (Patrick only)
struct DistributionView: View {
    @EnvironmentObject var session: SessionState
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    Text("Programmes").tag(0)
                    Text("Groupes").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16).padding(.top, 8)

                if selectedTab == 0 {
                    ProgramListView()
                } else {
                    GroupListView()
                }
            }
            .navigationTitle("Distribution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("OK") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Programmes de recherche
struct ProgramListView: View {
    @EnvironmentObject var session: SessionState
    @State private var newName = ""
    @State private var expandedProgram: String?

    var body: some View {
        List {
            Section("Nouveau programme") {
                HStack {
                    TextField("Nom du programme", text: $newName)
                    Button {
                        let n = newName.trimmingCharacters(in: .whitespaces)
                        guard !n.isEmpty else { return }
                        _ = session.addProgram(nom: n)
                        newName = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color(hex: "#8B3A62"))
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            ForEach(session.researchPrograms) { prog in
                Section {
                    // En-tête programme
                    Button {
                        withAnimation {
                            expandedProgram = expandedProgram == prog.id ? nil : prog.id
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(prog.nom).font(.body.bold()).foregroundColor(.primary)
                                let count = prog.shamaneCodes.count
                                Text("\(count) shamane\(count > 1 ? "s" : "")")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: expandedProgram == prog.id ? "chevron.up" : "chevron.down")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }

                    // Détail : shamanes dans ce programme
                    if expandedProgram == prog.id {
                        let members = session.shamaneProfiles.filter { prog.shamaneCodes.contains($0.code) }
                        let nonMembers = session.shamaneProfiles.filter { !prog.shamaneCodes.contains($0.code) }

                        if members.isEmpty {
                            Text("Aucune shamane dans ce programme")
                                .font(.caption).foregroundColor(.secondary).italic()
                        }
                        ForEach(members) { s in
                            HStack {
                                Text(s.displayName).font(.subheadline)
                                Text(s.codeFormatted).font(.caption.monospaced()).foregroundColor(.secondary)
                                Spacer()
                                Button {
                                    session.removeShamaneFromProgram(shamaneCode: s.code, programId: prog.id)
                                } label: {
                                    Image(systemName: "minus.circle.fill").foregroundColor(.red)
                                }
                            }
                        }

                        if !nonMembers.isEmpty {
                            Menu {
                                ForEach(nonMembers) { s in
                                    Button("\(s.displayName) ·\(s.codeFormatted)") {
                                        session.addShamaneToProgram(shamaneCode: s.code, programId: prog.id)
                                    }
                                }
                            } label: {
                                Label("Ajouter une shamane", systemImage: "plus")
                                    .font(.caption).foregroundColor(Color(hex: "#8B3A62"))
                            }
                        }
                    }
                } header: {
                    HStack {
                        Circle()
                            .fill(prog.actif ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                        Text(prog.actif ? "ACTIF" : "INACTIF")
                    }
                }
            }
            .onDelete { indices in
                for i in indices { session.removeProgram(session.researchPrograms[i]) }
            }
        }
    }
}

// MARK: - Groupes thématiques
struct GroupListView: View {
    @EnvironmentObject var session: SessionState
    @State private var newName = ""
    @State private var expandedGroup: String?

    var body: some View {
        List {
            Section("Nouveau groupe") {
                HStack {
                    TextField("Nom du groupe (pathologie)", text: $newName)
                    Button {
                        let n = newName.trimmingCharacters(in: .whitespaces)
                        guard !n.isEmpty else { return }
                        _ = session.addGroup(nom: n)
                        newName = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color(hex: "#8B3A62"))
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            if session.thematicGroups.isEmpty {
                Section {
                    Text("Aucun groupe thématique")
                        .foregroundColor(.secondary).italic()
                }
            }

            ForEach(session.thematicGroups) { grp in
                Section(grp.nom) {
                    Button {
                        withAnimation {
                            expandedGroup = expandedGroup == grp.id ? nil : grp.id
                        }
                    } label: {
                        HStack {
                            let count = grp.shamaneCodes.count
                            Text("\(count) shamane\(count > 1 ? "s" : "")")
                                .font(.subheadline).foregroundColor(.primary)
                            Spacer()
                            Image(systemName: expandedGroup == grp.id ? "chevron.up" : "chevron.down")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }

                    if expandedGroup == grp.id {
                        let members = session.shamaneProfiles.filter { grp.shamaneCodes.contains($0.code) }
                        let nonMembers = session.shamaneProfiles.filter { !grp.shamaneCodes.contains($0.code) }

                        if members.isEmpty {
                            Text("Aucune shamane dans ce groupe")
                                .font(.caption).foregroundColor(.secondary).italic()
                        }
                        ForEach(members) { s in
                            HStack {
                                Text(s.displayName).font(.subheadline)
                                Text(s.codeFormatted).font(.caption.monospaced()).foregroundColor(.secondary)
                                Spacer()
                                Button {
                                    session.removeShamaneFromGroup(shamaneCode: s.code, groupId: grp.id)
                                } label: {
                                    Image(systemName: "minus.circle.fill").foregroundColor(.red)
                                }
                            }
                        }

                        if !nonMembers.isEmpty {
                            Menu {
                                ForEach(nonMembers) { s in
                                    Button("\(s.displayName) ·\(s.codeFormatted)") {
                                        session.addShamaneToGroup(shamaneCode: s.code, groupId: grp.id)
                                    }
                                }
                            } label: {
                                Label("Ajouter une shamane", systemImage: "plus")
                                    .font(.caption).foregroundColor(Color(hex: "#8B3A62"))
                            }
                        }
                    }
                }
            }
            .onDelete { indices in
                for i in indices { session.removeGroup(session.thematicGroups[i]) }
            }
        }
    }
}
