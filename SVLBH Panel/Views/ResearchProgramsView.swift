// SVLBHPanel — Views/ResearchProgramsView.swift
// Programmes de recherche SVLBH — Digital Shaman Lab
// Visible par shamanes certifiées et superviseurs

import SwiftUI

struct ResearchProgramsView: View {
    @EnvironmentObject var session: SessionState
    @EnvironmentObject var sync: MakeSyncService
    @Environment(\.dismiss) private var dismiss
    @State private var allKeys: [String] = []
    @State private var isLoading = false
    @State private var hasLoaded = false
    @State private var errorMessage: String?
    @State private var showPayload = false
    @State private var payloadText = ""
    @State private var payloadKey = ""
    @State private var loadingKey: String?
    @State private var expandedPrograms: Set<String> = []
    @State private var selectedShamaneCode: String = "all"

    private static let historyURL = URL(string: "https://hook.eu2.make.com/73qifx9u3askirqjixgz7786hev2nxqh")!

    /// Known research program codes
    private var programCodes: [(code: String, nom: String)] {
        let defaults: [(String, String)] = [
            ("01", "Scleroses chromatiques transg\u{00e9}n\u{00e9}rationnelles multiples"),
            ("03", "Accumulations masculines sur l\u{2019}endom\u{00e8}tre"),
            ("05", "Glyc\u{00e9}mies I, II et III"),
        ]
        // Add any custom programs from session
        let defaultCodes = Set(defaults.map(\.0))
        let custom = session.researchPrograms
            .filter { $0.actif && !defaultCodes.contains($0.programCode) }
            .map { ($0.programCode, $0.nom) }
        return defaults + custom
    }

    /// Available shamanes from the keys
    private var availableShamanes: [(code: String, name: String)] {
        var codes = Set<String>()
        for raw in allKeys {
            let key = raw.split(separator: "|").first.map(String.init) ?? raw
            let parts = key.split(separator: "-")
            if parts.count >= 4 { codes.insert(String(parts.last!)) }
        }
        return codes.sorted().compactMap { code in
            if let profile = session.shamaneProfiles.first(where: { $0.codeFormatted == code }) {
                return (code: code, name: profile.displayName)
            }
            if PractitionerTier.from(code: Int(code) ?? 0) == .superviseur { return (code: code, name: "\u{1f52c} \(code)") }
            return (code: code, name: code)
        }
    }

    /// Filter keys by program code and selected shamane
    private func keysForProgram(_ code: String) -> [String] {
        let myCode = session.role.code
        return allKeys.filter { raw in
            let key = raw.split(separator: "|").first.map(String.init) ?? raw
            guard key.hasPrefix("\(code)-") else { return false }
            // Shamane filter
            if selectedShamaneCode != "all" {
                guard key.hasSuffix("-\(selectedShamaneCode)") else { return false }
            }
            if session.role.isSuperviseur { return true }
            return key.hasSuffix("-\(myCode)")
        }
    }

    /// Programs that have at least one session
    private var activePrograms: [(code: String, nom: String, keys: [String])] {
        programCodes.compactMap { prog in
            let keys = keysForProgram(prog.code)
            guard !keys.isEmpty else { return nil }
            return (code: prog.code, nom: prog.nom, keys: keys)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if !hasLoaded && !isLoading {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "flask")
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: "#5B2C8E"))
                        Text("Programmes de recherche SVLBH")
                            .font(.headline).foregroundColor(.secondary)
                        Text("Digital Shaman Lab")
                            .font(.caption).foregroundColor(.secondary)
                        Button {
                            Task { await loadHistory() }
                        } label: {
                            Label("Charger les programmes", systemImage: "arrow.down.circle")
                                .font(.body.bold())
                                .padding(.horizontal, 20).padding(.vertical, 10)
                                .background(Color(hex: "#5B2C8E"))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    Spacer()
                } else if isLoading {
                    Spacer()
                    ProgressView("Chargement...")
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle").font(.system(size: 40)).foregroundColor(.orange)
                        Text(error).font(.caption).foregroundColor(.secondary)
                        Button("R\u{00e9}essayer") { Task { await loadHistory() } }.font(.caption.bold())
                    }
                    Spacer()
                } else if activePrograms.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "tray").font(.system(size: 40)).foregroundColor(.secondary)
                        Text("Aucune session de recherche").font(.headline).foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    // Filtre shamane
                    if session.role.isSuperviseur && !availableShamanes.isEmpty {
                        HStack(spacing: 8) {
                            Text("Shamane").font(.caption.bold()).foregroundColor(Color(hex: "#333333"))
                            Picker("", selection: $selectedShamaneCode) {
                                Text("Toutes").tag("all")
                                ForEach(availableShamanes, id: \.code) { s in
                                    Text(s.name).tag(s.code)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Color(hex: "#5B2C8E"))
                            Spacer()
                        }
                        .padding(.horizontal, 16).padding(.vertical, 4)
                    }

                    List {
                        ForEach(activePrograms, id: \.code) { prog in
                            DisclosureGroup(
                                isExpanded: Binding(
                                    get: { expandedPrograms.contains(prog.code) },
                                    set: { if $0 { expandedPrograms.insert(prog.code) } else { expandedPrograms.remove(prog.code) } }
                                )
                            ) {
                                ForEach(prog.keys, id: \.self) { raw in
                                    researchKeyRow(raw)
                                }
                            } label: {
                                HStack {
                                    Text(prog.code)
                                        .font(.system(.caption, design: .monospaced).bold())
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8).padding(.vertical, 4)
                                        .background(Color(hex: "#5B2C8E"))
                                        .cornerRadius(6)
                                    Text(prog.nom)
                                        .font(.subheadline.bold())
                                    Spacer()
                                    Text("\(prog.keys.count)")
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8).padding(.vertical, 2)
                                        .background(Color(hex: "#5B2C8E").opacity(0.7))
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Programmes de recherche")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
                if hasLoaded {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button { Task { await loadHistory() } } label: {
                            Image(systemName: "arrow.clockwise")
                        }.disabled(isLoading)
                    }
                }
            }
            .sheet(isPresented: $showPayload) {
                PayloadPreviewSheet(payload: payloadText, key: payloadKey)
            }
        }
        .navigationViewStyle(.stack)
    }

    private func researchKeyRow(_ raw: String) -> some View {
        let key = raw.split(separator: "|").first.map(String.init) ?? raw
        let header = raw.split(separator: "|").dropFirst().first.map(String.init) ?? ""
        let dateStr = extractDate(from: header)

        return HStack(spacing: 10) {
            if !dateStr.isEmpty {
                Text(dateStr)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 110, alignment: .leading)
            }
            Text(key)
                .font(.system(.caption, design: .monospaced))
            Spacer()
            if loadingKey == key {
                ProgressView()
            } else {
                Button {
                    Task { await loadSession(key) }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func extractDate(from header: String) -> String {
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
                // Auto-expand all programs
                expandedPrograms = Set(activePrograms.map(\.code))
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
        if let result = try? await sync.pullSingleKey(key) {
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
