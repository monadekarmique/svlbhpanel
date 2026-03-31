// SVLBHPanel — Views/RoutineMatinTab.swift
// v5.2.1 — Routine du matin certifiées — Cercle de Lumière
// Données dynamiques depuis datastore billing_praticien via webhook svlbh-sync-praticien

import SwiftUI

// MARK: - Quota model

struct CertifieeQuota: Identifiable {
    let id: String          // code praticienne
    let nom: String
    let categorie: String
    let max: Int
    let compteur: Int
    var quotaLibre: Int { max - compteur }
    var pourcentage: Double { max == 0 ? 0 : Double(quotaLibre) / Double(max) * 100 }
    var indicateur: String { quotaLibre >= 0 ? "🟢" : "🔴" }
}

// MARK: - View

struct RoutineMatinTab: View {
    @EnvironmentObject var session: SessionState
    @State private var allQuotas: [CertifieeQuota] = []
    @State private var isLoading = false
    @State private var lastRefresh: Date?

    /// Webhook svlbh-sync-praticien — retourne les données billing
    private static let syncURL = URL(string: "https://hook.eu2.make.com/f5ezym67mfmywuwoov7fbb4gf3ufhqq8")!

    private var certifiees: [CertifieeQuota] { allQuotas.filter { $0.categorie == "praticien" } }
    private var patrick: CertifieeQuota? { allQuotas.first { $0.categorie == "superviseur" } }
    private var patrickMax: Int { patrick?.max ?? 0 }

    private var totalCompteurs: Int { certifiees.reduce(0) { $0 + $1.compteur } }
    private var totalMax: Int { certifiees.reduce(0) { $0 + $1.max } }

    // Check 1 — Patrick couvre le cercle
    private var check1Target: Int { totalMax + (totalMax - totalCompteurs) }
    private var check1OK: Bool { patrickMax >= check1Target }

    // Check 2b — Cornelia + Anne vs Irène + Flavia + Chloé
    private var groupA: [CertifieeQuota] { certifiees.filter { ["0300", "0302"].contains($0.id) } }
    private var groupB: [CertifieeQuota] { certifiees.filter { !["0300", "0302"].contains($0.id) } }
    private var capaciteGroupeA: Int { groupA.reduce(0) { $0 + $1.quotaLibre } }
    private var compteurGroupeB: Int { groupB.reduce(0) { $0 + $1.compteur } }
    private var couvertureCheck2: Double {
        compteurGroupeB == 0 ? 100 : Double(capaciteGroupeA) / Double(compteurGroupeB) * 100
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if isLoading && allQuotas.isEmpty {
                        Spacer().frame(height: 80)
                        ProgressView("Chargement du Cercle de Lumière...")
                        Spacer()
                    } else if allQuotas.isEmpty {
                        Spacer().frame(height: 80)
                        VStack(spacing: 12) {
                            Image(systemName: "sun.max.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Button {
                                Task { await fetchQuotas() }
                            } label: {
                                Label("Charger les quotas", systemImage: "arrow.down.circle")
                                    .font(.body.bold())
                                    .padding(.horizontal, 20).padding(.vertical, 10)
                                    .background(Color(hex: "#8B3A62"))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        Spacer()
                    } else {
                        cercleDeLumiere
                        Divider()
                        tableauCertifiees
                        Divider()
                        checksSection

                        if let t = lastRefresh {
                            let df = DateFormatter()
                            let _ = df.dateFormat = "HH:mm:ss"
                            Text("Mis à jour à \(df.string(from: t))")
                                .font(.caption2).foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("Routine du matin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await fetchQuotas() }
                    } label: {
                        if isLoading {
                            ProgressView().scaleEffect(0.7)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption.bold())
                                .foregroundColor(Color(hex: "#8B3A62"))
                        }
                    }
                    .disabled(isLoading)
                }
            }
        }
        .navigationViewStyle(.stack)
        .task { await fetchQuotas() }
    }

    // MARK: - Fetch depuis webhook (action=get par praticienne)

    /// Clés billing connues : certifiées + superviseur
    private static let billingKeys = ["0300", "0301", "0302", "0303", "0304", "455000"]

    private func fetchQuotas() async {
        isLoading = true
        var results: [CertifieeQuota] = []

        await withTaskGroup(of: CertifieeQuota?.self) { group in
            for key in Self.billingKeys {
                group.addTask { await self.fetchSingle(key: key) }
            }
            for await result in group {
                if let q = result { results.append(q) }
            }
        }

        await MainActor.run {
            allQuotas = results
            lastRefresh = Date()
            isLoading = false
        }
    }

    private func fetchSingle(key: String) async -> CertifieeQuota? {
        let body: [String: String] = ["action": "get", "billing_key": key]
        do {
            var req = URLRequest(url: Self.syncURL)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            req.timeoutInterval = 10
            let (data, _) = try await URLSession.shared.data(for: req)
            if let rec = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let code = rec["code"] as? String,
               let nom = rec["nom_praticien"] as? String,
               let max = rec["compteur_max_patient"] as? Int,
               let compteur = rec["compteur"] as? Int {
                let cat = rec["categorie"] as? String ?? "praticien"
                return CertifieeQuota(id: code, nom: nom, categorie: cat, max: max, compteur: compteur)
            }
        } catch {
            print("[RoutineMatinTab] fetchSingle \(key) error: \(error.localizedDescription)")
        }
        return nil
    }

    // MARK: - Cercle de Lumière

    private var cercleDeLumiere: some View {
        VStack(spacing: 8) {
            Image(systemName: "sun.max.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "#BA7517"))

            Text("Cercle de Lumière")
                .font(.title3.bold())
                .foregroundColor(Color(hex: "#8B3A62"))

            Text("Le travail de chacune compte")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text("\(totalCompteurs)")
                        .font(.title2.bold())
                        .foregroundColor(Color(hex: "#8B3A62"))
                    Text("Total compteurs")
                        .font(.caption2).foregroundColor(.secondary)
                }
                VStack(spacing: 2) {
                    Text("\(totalMax)")
                        .font(.title2.bold())
                        .foregroundColor(Color(hex: "#BA7517"))
                    Text("Total max")
                        .font(.caption2).foregroundColor(.secondary)
                }
                VStack(spacing: 2) {
                    Text("\(patrickMax)")
                        .font(.title2.bold())
                        .foregroundColor(Color(hex: "#1D9E75"))
                    Text("Patrick")
                        .font(.caption2).foregroundColor(.secondary)
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color(hex: "#BA7517").opacity(0.06))
        .cornerRadius(12)
    }

    // MARK: - Tableau

    private var tableauCertifiees: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Certifiées — Quotas")
                .font(.subheadline.bold())
                .foregroundColor(Color(hex: "#8B3A62"))

            // Header
            HStack(spacing: 0) {
                Text("").frame(width: 24)
                Text("Praticienne").font(.caption2.bold()).foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Max").font(.caption2.bold()).foregroundColor(.secondary).frame(width: 40)
                Text("Cpt").font(.caption2.bold()).foregroundColor(.secondary).frame(width: 40)
                Text("Libre").font(.caption2.bold()).foregroundColor(.secondary).frame(width: 44)
                Text("%").font(.caption2.bold()).foregroundColor(.secondary).frame(width: 50)
            }
            .padding(.horizontal, 8)

            ForEach(certifiees) { q in
                HStack(spacing: 0) {
                    Text(q.indicateur).font(.caption).frame(width: 24)
                    Text(q.nom).font(.caption).lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(q.max)").font(.system(.caption, design: .monospaced).bold())
                        .frame(width: 40)
                    Text("\(q.compteur)").font(.system(.caption, design: .monospaced))
                        .frame(width: 40)
                    Text("\(q.quotaLibre)")
                        .font(.system(.caption, design: .monospaced).bold())
                        .foregroundColor(q.quotaLibre >= 0 ? Color(hex: "#1D9E75") : Color(hex: "#E24B4A"))
                        .frame(width: 44)
                    Text(String(format: "%.0f%%", q.pourcentage))
                        .font(.system(.caption, design: .monospaced).bold())
                        .foregroundColor(q.quotaLibre >= 0 ? Color(hex: "#1D9E75") : Color(hex: "#E24B4A"))
                        .frame(width: 50)
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(q.quotaLibre < 0 ? Color(hex: "#E24B4A").opacity(0.06) : Color.clear)
                .cornerRadius(6)
            }
        }
    }

    // MARK: - Checks

    private var checksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Checks")
                .font(.subheadline.bold())
                .foregroundColor(Color(hex: "#8B3A62"))

            // Check 1 — Patrick
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(check1OK ? "✅" : "❌")
                    Text("Check 1 — Patrick").font(.caption.bold())
                }
                Text("Compteurs certifiées : \(totalCompteurs)")
                    .font(.caption2).foregroundColor(.secondary)
                Text("Si toutes remplissent max : \(check1Target) → Patrick (\(patrickMax)) \(check1OK ? "couvre" : "ne couvre pas")")
                    .font(.caption2).foregroundColor(.secondary)
            }
            .padding(10)
            .background(Color(hex: check1OK ? "#1D9E75" : "#E24B4A").opacity(0.06))
            .cornerRadius(8)

            // Check 2b — Cross-couverture
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(couvertureCheck2 >= 50 ? "✅" : "❌")
                    Text("Check 2b — Cornelia + Anne vs autres").font(.caption.bold())
                }
                Text("Compteurs à couvrir : \(compteurGroupeB)")
                    .font(.caption2).foregroundColor(.secondary)
                Text("Capacité combinée (Cornelia + Anne) : \(capaciteGroupeA)")
                    .font(.caption2).foregroundColor(.secondary)
                Text("Couverture : \(String(format: "%.0f%%", couvertureCheck2))")
                    .font(.caption2.bold())
                    .foregroundColor(couvertureCheck2 >= 50 ? Color(hex: "#1D9E75") : Color(hex: "#E24B4A"))
            }
            .padding(10)
            .background(Color(hex: couvertureCheck2 >= 50 ? "#1D9E75" : "#E24B4A").opacity(0.06))
            .cornerRadius(8)
        }
    }
}
