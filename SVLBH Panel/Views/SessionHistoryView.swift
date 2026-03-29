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
    @State private var showResetConfirm = false
    @State private var showResumeConfirm = false
    @State private var resumeKey: String?

    private static let historyURL = URL(string: "https://hook.eu2.make.com/73qifx9u3askirqjixgz7786hev2nxqh")!

    /// Extract pure key (before |)
    private func pureKey(_ raw: String) -> String {
        raw.split(separator: "|").first.map(String.init) ?? raw
    }

    /// Keys filtered for current practitioner
    private var filteredKeys: [String] {
        let code = session.role.code
        let keys: [String]
        if session.role.isPatrick {
            keys = allKeys.filter { let k = pureKey($0); return k.contains("-") && k.first?.isNumber == true }
        } else {
            keys = allKeys.filter { pureKey($0).hasSuffix("-\(code)") }
        }
        if filterText.isEmpty { return keys }
        return keys.filter { $0.localizedCaseInsensitiveContains(filterText) }
    }

    /// Group by patientId (second component of key)
    private var grouped: [(patientId: String, keys: [String])] {
        let parsed = filteredKeys.compactMap { raw -> (patient: String, key: String)? in
            let parts = pureKey(raw).split(separator: "-")
            guard parts.count >= 3 else { return nil }
            return (patient: String(parts[1]), key: raw)
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
                    HStack(spacing: 16) {
                        Button { showResetConfirm = true } label: {
                            Image(systemName: "trash.circle")
                                .foregroundColor(.red)
                        }
                        Button { Task { await loadHistory() } } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .disabled(isLoading)
                    }
                }
            }
            .sheet(isPresented: $showPayload) {
                PayloadPreviewSheet(payload: payloadText, key: payloadKey)
            }
            .alert("Reset complet", isPresented: $showResetConfirm) {
                Button("Annuler", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    session.resetForShamane()
                    dismiss()
                }
            } message: {
                Text("Remettre la session \u{00e0} z\u{00e9}ro pour un nouveau patient ?")
            }
            .alert("Reprendre cette session ?", isPresented: $showResumeConfirm) {
                Button("Annuler", role: .cancel) { resumeKey = nil }
                Button("Reprendre") {
                    if let key = resumeKey {
                        Task { await doResume(key) }
                    }
                }
            } message: {
                Text("La session active sera remplac\u{00e9}e par \(resumeKey ?? "")")
            }
        }
    }

    private func keyRow(_ key: String) -> some View {
        let pk = pureKey(key)
        let header = key.split(separator: "|").dropFirst().first.map(String.init) ?? ""
        let dateStr = extractDate(from: header)

        return HStack(spacing: 10) {
            if !dateStr.isEmpty {
                Text(dateStr)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 110, alignment: .leading)
            }
            Text(pk)
                .font(.system(.subheadline, design: .monospaced))
            Spacer()
            if loadingKey == pk {
                ProgressView()
            } else {
                // Reprendre (charger dans la session active)
                Button {
                    Task { await resumeSession(pk) }
                } label: {
                    Image(systemName: "play.circle")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "#1D9E75"))
                }
                .buttonStyle(.plain)
                // Voir (preview)
                Button {
                    Task { await loadSession(pk) }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }
        }
        .opacity(loadingKey != nil && loadingKey != pk ? 0.5 : 1.0)
    }

    /// Extract date from header like "SVLBH·hDOM·P12·S002·Flavia·28.03.2026 08:55:53" or "PIN:1234"
    private func extractDate(from header: String) -> String {
        // Match dd.MM.yyyy HH:mm:ss pattern
        let pattern = #"(\d{2}\.\d{2}\.\d{4}\s+\d{2}:\d{2}:\d{2})"#
        if let range = header.range(of: pattern, options: .regularExpression) {
            return String(header[range])
        }
        return ""
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

    private func resumeSession(_ key: String) async {
        resumeKey = key
        await MainActor.run { showResumeConfirm = true }
    }

    private func doResume(_ key: String) async {
        loadingKey = key
        if let text = try? await syncService.pullSingleKey(key) {
            await MainActor.run {
                // Parse key components: programCode-patientId-sessionNum-practitionerCode
                let parts = key.split(separator: "-")
                if parts.count >= 3 {
                    session.sessionProgramCode = String(parts[0])
                    session.patientId = String(parts[1])
                    session.sessionNum = String(parts[2])
                }
                // Reset then apply payload
                session.resetForShamane()
                syncService.applyPayload(text, to: session)
                loadingKey = nil
                resumeKey = nil
                dismiss()
            }
        } else {
            await MainActor.run { loadingKey = nil; resumeKey = nil }
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
