// SVLBHPanel — Views/SyncBar.swift
// v4.0.3 — Dropdown shamane "Décoder et Envoyer" + roles dynamiques + broadcast ciblé

import SwiftUI

struct SyncBar: View {
    @EnvironmentObject var session: SessionState
    @EnvironmentObject var sync: MakeSyncService
    @Binding var showDiffLog: Bool
    @Binding var showPINAlert: Bool
    @Binding var pendingPayload: String
    @State private var selectedShamane: ShamaneProfile?
    @State private var isRenvoyer: Bool = false  // true = clé existante, pas de dropdown
    @State private var showTierWarning = false
    @State private var tierWarningMessage = ""
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }  // iPhone = compact, iPad = regular

    private var currentTier: PractitionerTier {
        switch session.role {
        case .unidentified: return .lead
        case .patrick: return .superviseur
        case .shamane(let s): return s.tier
        }
    }

    var body: some View {
        if !session.role.isIdentified {
            unidentifiedBar
        } else if currentTier == .lead {
            leadSyncBar
        } else {
            fullSyncBar
        }
    }

    // Non identifié : bloquer tout sync
    private var unidentifiedBar: some View {
        VStack(spacing: 8) {
            Divider()
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Identifiez-vous pour envoyer et recevoir des soins")
                    .font(.caption).foregroundColor(Color(hex: "#8B3A62"))
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
        .background(Color(hex: "#8B3A62").opacity(0.08))
    }

    // Leads : pas de sync, juste le contact WhatsApp
    private var leadSyncBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                Text("Toi")
                    .font(.caption.bold()).foregroundColor(Color(hex: "#8B3A62"))
                Spacer()
                if let url = currentTier.whatsappURL {
                    Link(destination: url) {
                        HStack(spacing: 4) {
                            Image(systemName: "message.fill").font(.caption)
                            Text("Contacte Cornelia et Patrick").font(.caption.bold())
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color(hex: "#1D9E75")).cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(Color(UIColor.systemBackground))
        }
    }

    // Formation / Certifiées / Superviseur : sync complet
    private var fullSyncBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 8) {
                // Rôle fixé par l'identification — affichage seul
                Text(session.role.displayName)
                    .font(.caption.bold())
                    .foregroundColor(Color(hex: "#8B3A62"))
                    .padding(.horizontal, 9).padding(.vertical, 6)
                    .background(Color(hex: "#8B3A62").opacity(0.10))
                    .cornerRadius(7)

                // Broadcast ciblé (certifiées / programme / groupe)
                if session.role.isSuperviseur && !session.shamaneProfiles.isEmpty {
                    Menu {
                        if !session.shamanesCertifiees.isEmpty {
                            Button {
                                Task { await doBroadcast(target: .allCertifiees) }
                            } label: {
                                Label("Toutes certifiées (×\(session.shamanesCertifiees.count))",
                                      systemImage: "antenna.radiowaves.left.and.right")
                            }
                        }
                        let activePrograms = session.researchPrograms.filter { $0.actif && !$0.shamaneCodes.isEmpty }
                        if !activePrograms.isEmpty {
                            Divider()
                            ForEach(activePrograms) { prog in
                                Button {
                                    Task { await doBroadcast(target: .program(prog)) }
                                } label: {
                                    Label("\(prog.nom) (×\(prog.shamaneCodes.count))",
                                          systemImage: "flask")
                                }
                            }
                        }
                        if !session.thematicGroups.isEmpty {
                            Divider()
                            ForEach(session.thematicGroups.filter { !$0.shamaneCodes.isEmpty }) { grp in
                                Button {
                                    Task { await doBroadcast(target: .group(grp)) }
                                } label: {
                                    Label("\(grp.nom) (×\(grp.shamaneCodes.count))",
                                          systemImage: "person.3")
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 3) {
                            if sync.isSending { ProgressView().scaleEffect(0.65) }
                            else { Text("📡") }
                            if !isCompact { Text("Broadcast").font(.caption.bold()) }
                        }
                        .foregroundColor(Color(hex: "#B8965A"))
                        .padding(.horizontal, isCompact ? 5 : 7).padding(.vertical, 5)
                        .overlay(RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(hex: "#B8965A"), lineWidth: 1.5))
                    }
                    .disabled(sync.isSending || sync.isReceiving)
                }

                Spacer()

                if sync.pushSuccess {
                    Text("PUSH OK ✅")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Color(hex: "#1D9E75"))
                        .cornerRadius(5)
                        .transition(.opacity)
                        .animation(.easeInOut, value: sync.pushSuccess)
                }
                // PINs de la shamane sélectionnée
                if let code = selectedShamane?.codeFormatted,
                   let pins = sync.pinsByShamane[code], !pins.isEmpty {
                    let df = DateFormatter()
                    let _ = df.dateFormat = "HH:mm"
                    ForEach(Array(pins.enumerated()), id: \.offset) { _, entry in
                        Text("📌 \(entry.pin) · \(df.string(from: entry.date))")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color(hex: "#8B3A62"))
                            .cornerRadius(4)
                    }
                } else if let pin = sync.lastPin, !pin.isEmpty, selectedShamane == nil {
                    Text("📌 \(pin)")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Color(hex: "#8B3A62"))
                        .cornerRadius(5)
                }

                // ── Recevoir : scan + badge + menu (Patrick) ou bouton simple (shamane) ──
                if session.role.isSuperviseur {
                    Menu {
                        Button {
                            Task { await sync.scanSources(session: session) }
                        } label: {
                            Label(sync.isScanning ? "Scan en cours…" : "Scanner les sources",
                                  systemImage: "antenna.radiowaves.left.and.right")
                        }
                        .disabled(sync.isScanning)

                        if !sync.pendingSources.isEmpty {
                            Divider()
                            ForEach(sync.pendingSources) { src in
                                Button {
                                    session.pullSource = src
                                    Task { await doPull() }
                                } label: {
                                    Label("← \(src.displayName) ·\(src.codeFormatted)",
                                          systemImage: "envelope.fill")
                                }
                            }
                        } else if !sync.isScanning {
                            Text("Aucun envoi en attente")
                        }
                    } label: {
                        HStack(spacing: 3) {
                            if sync.isReceiving || sync.isScanning {
                                ProgressView().scaleEffect(0.65)
                            } else {
                                Image(systemName: "antenna.radiowaves.left.and.right").font(.caption)
                            }
                            if !isCompact { Text("Recevoir").font(.caption.bold()) }
                            if !sync.pendingSources.isEmpty {
                                Text("\(sync.pendingSources.count)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 18, height: 18)
                                    .background(Color.red)
                                    .clipShape(Circle())
                            }
                        }
                        .foregroundColor(Color(hex: "#8B3A62"))
                        .padding(.horizontal, 9).padding(.vertical, 6)
                        .overlay(RoundedRectangle(cornerRadius: 7)
                            .stroke(Color(hex: "#8B3A62"), lineWidth: 1.5))
                    }
                    .disabled(sync.isReceiving || sync.isSending)
                } else {
                    Button { Task { await doPull() } } label: {
                        HStack(spacing: 3) {
                            if sync.isReceiving { ProgressView().scaleEffect(0.65) }
                            else { Image(systemName: "antenna.radiowaves.left.and.right").font(.caption) }
                            if !isCompact { Text("Recevoir").font(.caption.bold()) }
                        }
                        .foregroundColor(Color(hex: "#8B3A62"))
                        .padding(.horizontal, isCompact ? 5 : 9).padding(.vertical, 6)
                        .overlay(RoundedRectangle(cornerRadius: 7)
                            .stroke(Color(hex: "#8B3A62"), lineWidth: 1.5))
                    }
                    .disabled(sync.isReceiving || sync.isSending)
                }

                // ── Shamane dropdown (mode B "Décoder et Envoyer") ──
                if session.role.isSuperviseur && !isRenvoyer {
                    let certifiees = session.shamaneProfiles.filter { $0.tier == .certifiee }
                    let formation = session.shamaneProfiles.filter { $0.tier == .formation }
                    Menu {
                        if !certifiees.isEmpty {
                            Section("Certifiées") {
                                ForEach(certifiees) { s in
                                    Button {
                                        selectedShamane = s
                                    } label: {
                                        HStack {
                                            Text("\(s.displayName) · \(s.codeFormatted)")
                                            if selectedShamane?.code == s.code { Image(systemName: "checkmark") }
                                        }
                                    }
                                }
                            }
                        }
                        if !formation.isEmpty {
                            Section("En formation") {
                                ForEach(formation) { s in
                                    Button {
                                        selectedShamane = s
                                    } label: {
                                        HStack {
                                            Text("\(s.displayName) · \(s.codeFormatted)")
                                            if selectedShamane?.code == s.code { Image(systemName: "checkmark") }
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Text(selectedShamane?.displayName ?? "Shamane…")
                                .font(.caption.bold())
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 8))
                        }
                        .foregroundColor(selectedShamane != nil ? Color(hex: "#1D9E75") : .secondary)
                        .padding(.horizontal, 7).padding(.vertical, 5)
                        .background(Color(hex: "#1D9E75").opacity(0.10))
                        .cornerRadius(6)
                    }
                }

                Button { checkTierAndPush() } label: {
                    HStack(spacing: 3) {
                        if sync.isSending { ProgressView().scaleEffect(0.65) }
                        else { Image(systemName: "waveform").font(.caption) }
                        if !isCompact { Text(isRenvoyer ? "Renvoyer" : "Envoyer").font(.caption.bold()) }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, isCompact ? 5 : 9).padding(.vertical, 6)
                    .background(canSend ? Color(hex: "#8B3A62") : Color.gray)
                    .cornerRadius(7)
                }
                .disabled(!canSend)
                .alert("Attention", isPresented: $showTierWarning) {
                    Button("Envoyer quand même") { Task { await doPush() } }
                    Button("Annuler", role: .cancel) {}
                } message: {
                    Text(tierWarningMessage)
                }

                // ↺ Refaire — visible uniquement en mode relay (Patrick renvoie un soin)
                if session.role.isSuperviseur && isRenvoyer {
                    Button {
                        Task { await doRelayRepeat() }
                    } label: {
                        HStack(spacing: 3) {
                            if sync.isSending { ProgressView().scaleEffect(0.65) }
                            else { Text("↺") }
                            if !isCompact { Text("Refaire").font(.caption.bold()) }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, isCompact ? 5 : 9).padding(.vertical, 6)
                        .background(Color(hex: "#B8965A"))
                        .cornerRadius(7)
                    }
                    .disabled(sync.isSending)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(Color(UIColor.systemBackground))
        }
    }

    private func checkTierAndPush() {
        // Vérifier si la shamane destinataire a un tier limité
        if session.role.isSuperviseur, let shamane = selectedShamane {
            let shamaneMax = shamane.tier.maxGenerations
            let patrickCount = session.visibleGenerations.filter(\.validated).count
            if patrickCount > shamaneMax {
                tierWarningMessage = "\(shamane.displayName) (\(shamane.tier.label)) ne verra que \(shamaneMax)/\(patrickCount) générations"
                showTierWarning = true
                return
            }
        }
        Task { await doPush() }
    }

    /// Mode B requires a shamane selected; mode A (renvoyer) always allowed
    private var canSend: Bool {
        guard !sync.isSending && !sync.isReceiving else { return false }
        if session.role.isSuperviseur && !isRenvoyer {
            return selectedShamane != nil
        }
        return true
    }

    private func doPush() async {
        // Mode B: override pullSource with selected shamane's profile
        if session.role.isSuperviseur, !isRenvoyer, let shamane = selectedShamane {
            session.pullSource = shamane
        }
        _ = await sync.push(session: session, forShamaneCode: selectedShamane?.codeFormatted)
    }

    /// ↺ Refaire un cycle relay : efface les clés READ puis renvoie le soin
    private func doRelayRepeat() async {
        // 1. Effacer les clés READ du sessionNum courant pour tous les praticiens
        await sync.prepareRelayRepeat(session: session, profiles: session.shamaneProfiles)
        // 2. Attendre que Make.com ait enregistré les écrasements
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        // 3. Re-push le soin sur la même clé
        _ = await sync.push(session: session)
    }

    private func doBroadcast(target: BroadcastTarget = .allCertifiees) async {
        _ = await sync.broadcastPush(session: session, target: target)
    }

    private func doPull() async {
        let pullKey = session.pullKey  // capturer avant le pull
        guard let raw = await sync.pull(session: session, manual: true) else { return }
        if raw == "PIN_PENDING" { return }
        if raw.hasPrefix("PIN:") {
            await MainActor.run { pendingPayload = raw; showPINAlert = true }
            // Mark as read après réception PIN
            await sync.markAsRead(sessionId: pullKey)
        } else {
            await MainActor.run {
                sync.applyPayload(raw, to: session)
                if let src = session.pullSource {
                    sync.pendingSources.removeAll { $0.code == src.code }
                }
                showDiffLog = true
            }
            // Mark as read après merge réussi
            await sync.markAsRead(sessionId: pullKey)
        }
    }
}
