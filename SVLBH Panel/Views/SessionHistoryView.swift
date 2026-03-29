import SwiftUI

struct SessionHistoryView: View {
    @ObservedObject var session: SessionState
    @ObservedObject var syncService: MakeSyncService
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var loadingKey: String?
    @State private var showPayload = false
    @State private var payloadText = ""
    @State private var payloadKey = ""

    var body: some View {
        NavigationView {
            historyList
                .navigationTitle("Historique")
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

    @ViewBuilder
    private var historyList: some View {
        let grouped = SessionHistory.groupedByPatient()
        if grouped.isEmpty {
            emptyState
        } else {
            List {
                ForEach(grouped, id: \.patientId) { group in
                    Section("Patient \(group.patientId)") {
                        ForEach(group.entries) { entry in
                            entryRow(entry)
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Aucun historique")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Les sessions apparaissent ici\napr\u{00e8}s chaque PUSH")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private func entryRow(_ entry: SessionHistoryEntry) -> some View {
        Button {
            Task { await loadSession(entry) }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.displayTitle)
                        .font(.headline)
                    Text(entry.displaySubtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if !entry.headerLine.isEmpty {
                        Text(entry.headerLine)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                if isLoading && loadingKey == entry.key {
                    ProgressView()
                } else {
                    Image(systemName: "arrow.down.circle")
                        .foregroundColor(.accentColor)
                }
            }
        }
        .disabled(isLoading)
    }

    private func loadSession(_ entry: SessionHistoryEntry) async {
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

struct PayloadPreviewSheet: View {
    let payload: String
    let key: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                Text(payload)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(key)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}
