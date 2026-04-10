// SVLBHPanel — Views/PasseportRatioSheet.swift
// Phase 2 Managed Agents — affiche le passeport rédigé par
// `passeport-ratio-agent` à partir du calcul Ratio 4D local.

import SwiftUI

struct PasseportRatioSheet: View {

    @EnvironmentObject var session: SessionState
    @EnvironmentObject var passeportAgent: PasseportRatioAgentService
    @Environment(\.dismiss) private var dismiss

    /// Snapshot du calcul local produit par Ratio4DDetailView.
    /// Passé en `init` car ce sheet peut être présenté depuis une vue
    /// qui n'a pas l'agent en environnement encore.
    let localCalcul: Ratio4DLocalCalcul

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Passeport SVLBH")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Fermer") {
                            passeportAgent.reset()
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        if case .success = passeportAgent.state {
                            Button {
                                Task {
                                    await passeportAgent.generatePasseport(
                                        session: session,
                                        localCalcul: localCalcul
                                    )
                                }
                            } label: {
                                Label("Relancer", systemImage: "arrow.clockwise")
                            }
                        }
                    }
                }
        }
        .task {
            if case .idle = passeportAgent.state {
                await passeportAgent.generatePasseport(
                    session: session,
                    localCalcul: localCalcul
                )
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch passeportAgent.state {
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
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            Text("Prêt à générer le passeport").font(.headline)
            Button {
                Task {
                    await passeportAgent.generatePasseport(
                        session: session,
                        localCalcul: localCalcul
                    )
                }
            } label: {
                Label("Générer", systemImage: "play.fill")
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
            Text("Rédaction du passeport…")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("L'agent passeport-ratio interprète le Ratio 4D et le cluster pour rédiger la narrative clinique.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func resultView(_ result: PasseportRatioResult) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ratioHeader
                Divider()
                section(title: "Narrative clinique", icon: "text.quote", body: result.narrative)
                Divider()
                section(title: "Passeport complet", icon: "doc.text", body: result.passeportMarkdown)

                if !result.recommendations.isEmpty {
                    Divider()
                    recommendationsSection(result.recommendations)
                }

                if let metadata = result.metadata, !metadata.isEmpty {
                    Divider()
                    metadataSection(metadata)
                }
            }
            .padding()
        }
    }

    private var ratioHeader: some View {
        VStack(spacing: 6) {
            Text(localCalcul.cluster)
                .font(.caption).fontWeight(.semibold).textCase(.uppercase)
                .foregroundStyle(.secondary)
            Text(localCalcul.ratio4D.map { String(format: "%.2f×", $0) } ?? "—")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.accent)
            Text("Ratio 4D — \(localCalcul.pays)")
                .font(.subheadline).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
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

    private func recommendationsSection(_ recos: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Recommandations", systemImage: "checklist")
                .font(.title3).bold()
                .foregroundColor(.accentColor)
            ForEach(Array(recos.enumerated()), id: \.offset) { _, reco in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundColor(.accentColor)
                        .padding(.top, 7)
                    Text(reco)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
            }
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
            Text("Génération impossible").font(.headline)
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .textSelection(.enabled)
            Button {
                Task {
                    await passeportAgent.generatePasseport(
                        session: session,
                        localCalcul: localCalcul
                    )
                }
            } label: {
                Label("Réessayer", systemImage: "arrow.clockwise")
                    .frame(minWidth: 160)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
