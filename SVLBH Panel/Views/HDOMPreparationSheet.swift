// SVLBHPanel — Views/HDOMPreparationSheet.swift
// Phase 1 Managed Agents — affiche le résultat de `hdom-session-agent`.
//
// v0.2 — ajoute la section "Propositions à valider par radiesthésie"
// avec badges de confiance, rationale déplié si < 95 %, boutons ✓/✗
// qui loggent la décision radiesthésique dans SessionTracker.

import SwiftUI

struct HDOMPreparationSheet: View {

    @EnvironmentObject var session: SessionState
    @EnvironmentObject var tracker: SessionTracker
    @EnvironmentObject var hdomAgent: HDOMSessionAgentService
    @Environment(\.dismiss) private var dismiss

    /// Décisions radiesthésiques locales, clés = proposition.id.
    @State private var validationState: [String: RadiesthesieDecision] = [:]

    enum RadiesthesieDecision { case validated, invalidated }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Préparation hDOM")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Fermer") {
                            hdomAgent.reset()
                            validationState = [:]
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        if case .success = hdomAgent.state {
                            Button {
                                validationState = [:]
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
            Text("L'agent charge les skills et analyse le payload : sécurité praticienne → Zi Wu Liu → scores → propositions Type A + Type B.")
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

                if !result.propositions.isEmpty {
                    Divider()
                    propositionsSection(result.propositions)
                }

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

    // MARK: - Propositions (Type A + Type B) à valider par radiesthésie

    private func propositionsSection(_ propositions: [HDOMPreparationResult.Proposition]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Propositions à valider par radiesthésie", systemImage: "hand.raised.circle.fill")
                    .font(.title3).bold()
                    .foregroundColor(.accentColor)
                Spacer()
                Text("\(validationState.count)/\(propositions.count)")
                    .font(.caption.monospaced())
                    .foregroundColor(.secondary)
            }
            Text("Chaque proposition requiert ta validation au pendule avant application. Les propositions < 95 % affichent leur rationale.")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(propositions) { proposition in
                propositionCard(proposition)
            }
        }
    }

    private func propositionCard(_ p: HDOMPreparationResult.Proposition) -> some View {
        let decision = validationState[p.id]
        let isLocked = decision != nil

        return VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: p.type.iconName)
                    .font(.title3)
                    .foregroundColor(colorFor(confidence: p.confidence))
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 4) {
                    Text(p.type.displayName)
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    Text(p.label)
                        .font(.body.bold())
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
                Spacer(minLength: 8)
                ConfidenceBadge(confidence: p.confidence)
            }

            // Rationale (seulement si < 95 %)
            if p.requiresRationale, let rationale = p.rationale {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text(rationale)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
                .padding(10)
                .background(Color.orange.opacity(0.08))
                .cornerRadius(6)
            }

            // Détails structurés (dict libre)
            if let details = p.details, !details.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(details.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        HStack {
                            Text(key)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(value)
                                .font(.caption.monospaced())
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(8)
                .background(Color(.tertiarySystemFill))
                .cornerRadius(6)
            }

            // Actions validation radiesthésique
            HStack(spacing: 8) {
                Button {
                    logDecision(for: p, decision: .validated)
                } label: {
                    Label("Validée", systemImage: "checkmark.circle.fill")
                        .font(.caption.bold())
                }
                .buttonStyle(.bordered)
                .tint(.green)
                .disabled(isLocked)

                Button {
                    logDecision(for: p, decision: .invalidated)
                } label: {
                    Label("Invalidée", systemImage: "xmark.circle.fill")
                        .font(.caption.bold())
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(isLocked)

                Spacer()

                if let decision = decision {
                    Text(decision == .validated ? "✓ validée pendule" : "✗ invalidée pendule")
                        .font(.caption2.bold())
                        .foregroundColor(decision == .validated ? .green : .red)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(borderColorFor(decision: decision), lineWidth: decision != nil ? 1.5 : 0)
                )
        )
    }

    // MARK: - Helpers

    private func logDecision(for proposition: HDOMPreparationResult.Proposition, decision: RadiesthesieDecision) {
        validationState[proposition.id] = decision

        guard tracker.isActive else { return }
        let verb = (decision == .validated) ? "validée" : "invalidée"
        let ratPart = proposition.rationale.map { " rationale=\"\($0)\"" } ?? ""
        let event = SessionEvent(
            category: .custom,
            label: "Radiesthésie \(verb): \(proposition.label)",
            detail: "type=\(proposition.type.rawValue) confidence=\(String(format: "%.2f", proposition.confidence))\(ratPart)"
        )
        tracker.logEvent(event)
    }

    private func colorFor(confidence: Double) -> Color {
        if confidence >= 0.95 { return .green }
        if confidence >= 0.80 { return .orange }
        return .red
    }

    private func borderColorFor(decision: RadiesthesieDecision?) -> Color {
        switch decision {
        case .validated: return .green
        case .invalidated: return .red
        case .none: return .clear
        }
    }

    // MARK: - Metadata + Error

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

// MARK: - Confidence badge

private struct ConfidenceBadge: View {
    let confidence: Double

    var body: some View {
        Text("\(Int((confidence * 100).rounded())) %")
            .font(.caption.bold().monospacedDigit())
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor)
            .cornerRadius(6)
    }

    private var badgeColor: Color {
        if confidence >= 0.95 { return .green }
        if confidence >= 0.80 { return .orange }
        return .red
    }
}
