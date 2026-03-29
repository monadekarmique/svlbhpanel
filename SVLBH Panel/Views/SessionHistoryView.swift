// SVLBHPanel — Views/SessionHistoryView.swift
// Historique des clés de session — chargé depuis Make datastore

import SwiftUI

struct SessionHistoryView: View {
    @ObservedObject var session: SessionState
    @ObservedObject var syncService: MakeSyncService
    @Environment(\.dismiss) private var dismiss
    @State private var allKeys: [String] = []
    @State private var isLoading = false
    @State private var hasLoaded = false
    @State private var errorMessage: String?
    @State private var showPayload = false
    @State private var payloadText = ""
    @State private var payloadKey = ""
    @State private var loadingKey: String?
    @State private var filterText = ""
    @State private var expandedPatients: Set<String> = []

    private static let historyURL = URL(string: "https://hook.eu2.make.com/73qifx9u3askirqjixgz7786hev2nxqh")!

    /// Keys filtered for current practitioner
    private var filteredKeys: [String] {
        let code = session.role.code
        let keys: [String]
        if session.role.isPatrick {
            // Patrick sees all session keys (not CT- or hex keys)
            keys = allKeys.filter { $0.contains("-") && $0.first?.isNumber == true }
        } else {
            // Shamane sees only her own keys
            keys = allKeys.filter { $0.hasSuffix("-\(code)") }
        }
        if filterText.isEmpty { return keys }
        return keys.filter { $0.localizedCaseInsensitiveContains(filterText) }
    }

    /// Group by patientId (second component of key)
    private var grouped: [(patientId: String, keys: [String])] {
        let parsed = filteredKeys.compactMap { key -> (patient: String, key: String)? in
            let parts = key.split(separator: "-")
            guard parts.count >= 3 else { return nil }
            return (patient: String(parts[1]), key: key)
        }
        let dict = Dictionary(grouping: parsed) { $0.patient }
        return dict.map { (patientId: $0.key, keys: $0.value.map(\.key).sorted().reversed()) }
            .sorted { (Int($0.patientId) ?? 0) > (Int($1.patientId) ?? 0) }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Filtrer par cl\u{00e9}, patient...", text: $filterText)
                        .textFieldStyle(.plain)
                    if !filterText.isEmpty {
                        Button { filterText = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)

                // Stats
                Text("\(filteredKeys.count) cl\u{00e9}s \u{00b7} \(grouped.count) patients")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)

                if !hasLoaded && !isLoading {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("Historique des cl\u{00e9}s \u{00e9}lectromagn\u{00e9}tiques")
                            .font(.headline).foregroundColor(.secondary)
                        Button {
                            Task { await loadHistory() }
                        } label: {
                            Label("Charger l\u{2019}historique", systemImage: "arrow.down.circle")
                                .font(.body.bold())
                                .padding(.horizontal, 20).padding(.vertical, 10)
                                .background(Color(hex: "#8B3A62"))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    Spacer()
                } else if isLoading {
                    Spacer()
                    ProgressView("Chargement de l\u{2019}historique...")
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle").font(.system(size: 40)).foregroundColor(.orange)
                        Text(error).font(.caption).foregroundColor(.secondary)
                        Button("R\u{00e9}essayer") { Task { await loadHistory() } }
                            .font(.caption.bold())
                    }
                    Spacer()
                } else if grouped.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "tray").font(.system(size: 40)).foregroundColor(.secondary)
                        Text("Aucune cl\u{00e9} trouv\u{00e9}e").font(.headline).foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    // Accordion list
                    List {
                        ForEach(grouped, id: \.patientId) { group in
                            DisclosureGroup(
                                isExpanded: Binding(
                                    get: { expandedPatients.contains(group.patientId) },
                                    set: { if $0 { expandedPatients.insert(group.patientId) } else { expandedPatients.remove(group.patientId) } }
                                )
                            ) {
                                ForEach(group.keys, id: \.self) { key in
                                    keyRow(key)
                                }
                            } label: {
                                HStack {
                                    Text("Patient \(group.patientId)")
                                        .font(.headline)
                                    Spacer()
                                    Text("\(group.keys.count)")
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8).padding(.vertical, 2)
                                        .background(Color(hex: "#8B3A62"))
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Historique")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { Task { await loadHistory() } } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .sheet(isPresented: $showPayload) {
                PayloadPreviewSheet(payload: payloadText, key: payloadKey)
            }
        }
    }

    private func keyRow(_ key: String) -> some View {
        Button {
            Task { await loadSession(key) }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(key)
                        .font(.system(.subheadline, design: .monospaced))
                    // Parse components for display
                    let parts = key.split(separator: "-")
                    if parts.count >= 4 {
                        Text("Prog \(parts[0]) \u{00b7} S\(parts[2]) \u{00b7} Prat \(parts[3])")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                if loadingKey == key {
                    ProgressView()
                } else {
                    Image(systemName: "arrow.down.circle").foregroundColor(.accentColor)
                }
            }
        }
        .disabled(loadingKey != nil)
    }

    // MARK: - Network

    private func loadHistory() async {
        isLoading = true
        errorMessage = nil
        let body: [String: String] = ["practitioner_code": session.role.code]
        do {
            var req = URLRequest(url: Self.historyURL)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            req.timeoutInterval = 15
            let (data, _) = try await URLSession.shared.data(for: req)
            let text = String(data: data, encoding: .utf8) ?? ""
            let keys = text.split(separator: "\n").map(String.init).filter { !$0.isEmpty }
            await MainActor.run {
                allKeys = keys
                isLoading = false
                hasLoaded = true
                // Auto-expand first 3 patients
                let top3 = grouped.prefix(3).map(\.patientId)
                expandedPatients = Set(top3)
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func loadSession(_ key: String) async {
        loadingKey = key
        let text: String
        if let result = try? await syncService.pullSingleKey(key) {
            text = result
        } else {
            text = "(Aucune donn\u{00e9}e trouv\u{00e9}e pour \(key))"
        }
        await MainActor.run {
            payloadText = text
            payloadKey = key
            loadingKey = nil
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
