// SVLBHPanel — Views/HDOMPreparationSheet.swift
// Phase 1 Managed Agents — affiche le résultat de `hdom-session-agent`.

import SwiftUI

struct HDOMPreparationSheet: View {

    @EnvironmentObject var session: SessionState
    @EnvironmentObject var tracker: SessionTracker
    @EnvironmentObject var hdomAgent: HDOMSessionAgentService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Préparation hDOM")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Fermer") {
                            hdomAgent.reset()
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        if case .success = hdomAgent.state {
                            Button {
                                Task { await hdomAgent.prepareSession(session: session, tracker: tracker) }
                            } label: {
                                Label("Relancer", systemImage: "arrow.clockwise")
                            }
                        }
                    }
                }
        }
        .task {
            if case .idle = hdomAgent.state {
                await hdomAgent.prepareSession(session: session, tracker: tracker)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch hdomAgent.state {
        case .idle:
            idleView
        case .loading:
            loadingView
        case .success(let result):
            resultView(result)
        case .error(let message):
            errorView(message)
        }
    }

    // MARK: - States

    private var idleView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            Text("Prêt à préparer la séance").font(.headline)
            Button {
                Task { await hdomAgent.prepareSession(session: session, tracker: tracker) }
            } label: {
                Label("Préparer", systemImage: "play.fill")
                    .frame(minWidth: 160)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Décodage hDOM en cours…")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("L'agent charge les skills hdom-decoder, sommeil-troubles-nuit, endometriose-ferritine et analyse le payload.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func resultView(_ result: HDOMPreparationResult) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                section(title: "Décodage", icon: "text.magnifyingglass", body: result.decodage)
                Divider()
                section(title: "Protocole", icon: "list.number", body: result.protocole)
                Divider()
                section(title: "Chromothérapie", icon: "paintpalette.fill", body: result.chromotherapie)

                if let metadata = result.metadata, !metadata.isEmpty {
                    Divider()
                    metadataSection(metadata)
                }
            }
            .padding()
        }
    }

    private func section(title: String, icon: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.title3).bold()
                .foregroundColor(.accentColor)
            Text(body)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
    }

    private func metadataSection(_ metadata: [String: String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Métadonnées", systemImage: "info.circle")
                .font(.title3).bold()
                .foregroundColor(.secondary)
            ForEach(metadata.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                HStack(alignment: .top) {
                    Text(key).font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Text(value).font(.caption.monospaced())
                }
            }
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            Text("Préparation impossible").font(.headline)
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .textSelection(.enabled)
            Button {
                Task { await hdomAgent.prepareSession(session: session, tracker: tracker) }
            } label: {
                Label("Réessayer", systemImage: "arrow.clockwise")
                    .frame(minWidth: 160)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
