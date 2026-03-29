// SVLBHPanel — Views/ResearchProgramsView.swift
// Programmes de recherche SVLBH — Digital Shaman Lab
// Visible par shamanes certifiées et superviseurs

import SwiftUI

struct ResearchProgramsView: View {
    @EnvironmentObject var session: SessionState
    @EnvironmentObject var sync: MakeSyncService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProgram: ResearchProgram?
    @State private var showPatientHistory = false
    @State private var patientEntries: [SessionHistoryEntry] = []
    @State private var isLoading = false

    /// Programmes accessibles par l'utilisateur courant
    private var visiblePrograms: [ResearchProgram] {
        if session.role.isPatrick {
            return session.researchPrograms.filter { $0.actif }
        }
        // Shamane certifiée : seulement ses programmes
        return session.researchPrograms.filter { $0.actif && $0.shamaneCodes.contains(session.role.code) }
    }

    var body: some View {
        NavigationView {
            Group {
                if visiblePrograms.isEmpty {
                    emptyState
                } else {
                    programList
                }
            }
            .navigationTitle("Programmes de recherche")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .sheet(isPresented: $showPatientHistory) {
                if let program = selectedProgram {
                    ProgramPatientHistoryView(
                        program: program,
                        entries: patientEntries,
                        syncService: sync
                    )
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "flask")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Aucun programme actif")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Les programmes de recherche SVLBH\ndu Digital Shaman Lab apparaissent ici")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var programList: some View {
        List {
            ForEach(visiblePrograms) { program in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(program.programCode)
                            .font(.system(.caption, design: .monospaced).bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color(hex: "#5B2C8E"))
                            .cornerRadius(6)
                        Text(program.nom)
                            .font(.subheadline.bold())
                        Spacer()
                    }

                    if !program.shamaneCodes.isEmpty {
                        let names = program.shamaneCodes.compactMap { code in
                            session.shamaneProfiles.first { $0.codeFormatted == code }?.displayName ?? code
                        }
                        Text("Shamanes : \(names.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Button {
                        loadPatientHistory(for: program)
                    } label: {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("Historique patients")
                            if isLoading && selectedProgram?.id == program.id {
                                ProgressView().padding(.leading, 4)
                            }
                        }
                        .font(.caption.bold())
                        .foregroundColor(Color(hex: "#8B3A62"))
                    }
                    .disabled(isLoading)
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func loadPatientHistory(for program: ResearchProgram) {
        selectedProgram = program
        // Filter session history entries that match this program's code
        let allEntries = SessionHistory.all()
        patientEntries = allEntries.filter { $0.programCode == program.programCode }

        // If shamane (not Patrick), filter to own practitioner code only
        if !session.role.isPatrick {
            let myCode = session.role.code
            patientEntries = patientEntries.filter { $0.practitionerCode == myCode }
        }

        showPatientHistory = true
    }
}

// MARK: - Patient History per Program

struct ProgramPatientHistoryView: View {
    let program: ResearchProgram
    let entries: [SessionHistoryEntry]
    @ObservedObject var syncService: MakeSyncService
    @Environment(\.dismiss) private var dismiss
    @State private var showPayload = false
    @State private var payloadText = ""
    @State private var payloadKey = ""
    @State private var isLoading = false
    @State private var loadingKey: String?

    private var grouped: [(patientId: String, entries: [SessionHistoryEntry])] {
        let dict = Dictionary(grouping: entries) { $0.patientId }
        return dict.map { (patientId: $0.key, entries: $0.value.sorted { $0.timestamp > $1.timestamp }) }
            .sorted { ($0.entries.first?.timestamp ?? .distantPast) > ($1.entries.first?.timestamp ?? .distantPast) }
    }

    var body: some View {
        NavigationView {
            Group {
                if entries.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("Aucune session enregistr\u{00e9}e")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Programme \(program.programCode) \u{2014} \(program.nom)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(grouped, id: \.patientId) { group in
                            Section("Patient \(group.patientId)") {
                                ForEach(group.entries) { entry in
                                    Button {
                                        Task { await loadEntry(entry) }
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(entry.displayTitle).font(.headline)
                                                Text(entry.displaySubtitle).font(.caption).foregroundColor(.secondary)
                                                if !entry.headerLine.isEmpty {
                                                    Text(entry.headerLine).font(.caption2).foregroundColor(.secondary).lineLimit(1)
                                                }
                                            }
                                            Spacer()
                                            if isLoading && loadingKey == entry.key {
                                                ProgressView()
                                            } else {
                                                Image(systemName: "arrow.down.circle").foregroundColor(.accentColor)
                                            }
                                        }
                                    }
                                    .disabled(isLoading)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Programme \(program.programCode)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .sheet(isPresented: $showPayload) {
                PayloadPreviewSheet(payload: payloadText, key: payloadKey)
            }
        }
    }

    private func loadEntry(_ entry: SessionHistoryEntry) async {
        isLoading = true
        loadingKey = entry.key
        let pullKey = "\(entry.programCode)-\(entry.patientId)-\(entry.sessionNum)-\(ActiveRole.patrickCode)"
        let text: String
        if let result = try? await syncService.pullSingleKey(pullKey) {
            text = result
        } else {
            text = "(Aucune donn\u{00e9}e trouv\u{00e9}e pour \(pullKey))"
        }
        await MainActor.run {
            payloadText = text
            payloadKey = entry.displayTitle
            isLoading = false
            showPayload = true
        }
    }
}
