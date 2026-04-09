// DemandesView.swift
// SVLBHPanel — Portail client : point d'entrée Demandes
// Accès séparé du panel praticien — le client voit uniquement ses factures et séances

import SwiftUI

struct DemandesView: View {
    let patientId: String
    let patientName: String
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header client
            VStack(spacing: 4) {
                Text("Mes Demandes")
                    .font(.title2.bold())
                    .foregroundColor(Color(hex: "#8B3A62"))
                Text(patientName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 12)
            .padding(.bottom, 8)

            TabView(selection: $selectedTab) {
                DemandesInvoiceListView(patientId: patientId)
                    .tabItem { Label("Factures", systemImage: "doc.text.fill") }
                    .tag(0)

                DemandesSessionListView(patientId: patientId)
                    .tabItem { Label("Séances", systemImage: "calendar") }
                    .tag(1)

                DemandesProfileView(patientId: patientId)
                    .tabItem { Label("Profil", systemImage: "person.circle") }
                    .tag(2)
            }
        }
    }
}

// MARK: - Invoice List

struct DemandesInvoiceListView: View {
    let patientId: String
    @State private var invoices: [DemandesInvoice] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var selectedInvoice: DemandesInvoice?

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Chargement des factures...")
                } else if let error = error {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Réessayer") { Task { await loadInvoices() } }
                            .buttonStyle(.bordered)
                    }
                    .padding()
                } else if invoices.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 40))
                            .foregroundColor(Color(hex: "#8B3A62"))
                        Text("Aucune facture")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List(invoices) { invoice in
                        Button {
                            selectedInvoice = invoice
                        } label: {
                            InvoiceRow(invoice: invoice)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Factures")
            .navigationBarTitleDisplayMode(.inline)
            .task { await loadInvoices() }
            .refreshable { await loadInvoices() }
            .sheet(item: $selectedInvoice) { invoice in
                DemandesInvoiceDetailView(invoice: invoice)
            }
        }
        .navigationViewStyle(.stack)
    }

    private func loadInvoices() async {
        isLoading = true
        error = nil
        do {
            invoices = try await DemandesService.shared.fetchInvoices(patientId: patientId)
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
}

// MARK: - Invoice Row

struct InvoiceRow: View {
    let invoice: DemandesInvoice

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(invoice.invoiceNumber)
                    .font(.headline.monospaced())
                Text(invoice.issueDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let desc = invoice.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.2f CHF", invoice.amount))
                    .font(.subheadline.bold().monospaced())
                Text(invoice.status.label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(hex: invoice.status.color))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Invoice Detail

struct DemandesInvoiceDetailView: View {
    let invoice: DemandesInvoice
    @State private var isLoadingPDF = false
    @State private var pdfData: Data?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 8) {
                        Text(invoice.invoiceNumber)
                            .font(.title.bold().monospaced())
                            .foregroundColor(Color(hex: "#8B3A62"))
                        Text(invoice.status.label)
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(hex: invoice.status.color))
                            .cornerRadius(6)
                    }
                    .padding(.top, 8)

                    // Amounts
                    GroupBox(label: Label("Montant", systemImage: "creditcard")) {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Total")
                                Spacer()
                                Text(String(format: "%.2f CHF", invoice.amount))
                                    .font(.title2.bold().monospaced())
                            }
                            Divider()
                            HStack {
                                Text("Date d'émission")
                                Spacer()
                                Text(invoice.issueDate).foregroundColor(.secondary)
                            }
                            if let due = invoice.dueDate {
                                HStack {
                                    Text("Échéance")
                                    Spacer()
                                    Text(due).foregroundColor(invoice.status == .overdue ? .red : .secondary)
                                }
                            }
                            if let paid = invoice.paidDate {
                                HStack {
                                    Text("Payée le")
                                    Spacer()
                                    Text(paid).foregroundColor(.green)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }

                    // Items
                    if let items = invoice.items, !items.isEmpty {
                        GroupBox(label: Label("Détail", systemImage: "list.bullet")) {
                            VStack(spacing: 8) {
                                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                                    HStack {
                                        Text(item.description ?? "Service")
                                            .font(.caption)
                                        Spacer()
                                        if let qty = item.quantity, let price = item.unitPrice {
                                            Text("\(Int(qty)) x \(String(format: "%.2f", price))")
                                                .font(.caption.monospaced())
                                                .foregroundColor(.secondary)
                                        }
                                        if let amt = item.amount {
                                            Text(String(format: "%.2f", amt))
                                                .font(.caption.bold().monospaced())
                                        }
                                    }
                                }
                            }
                            .padding(.top, 4)
                        }
                    }

                    // Actions
                    VStack(spacing: 10) {
                        Button {
                            Task { await downloadPDF() }
                        } label: {
                            HStack {
                                if isLoadingPDF {
                                    ProgressView().scaleEffect(0.8).tint(.white)
                                } else {
                                    Image(systemName: "arrow.down.doc.fill")
                                }
                                Text("Télécharger PDF")
                            }
                            .frame(maxWidth: .infinity)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .background(Color(hex: "#8B3A62"))
                            .cornerRadius(10)
                        }
                        .disabled(isLoadingPDF)
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .navigationTitle("Facture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }

    private func downloadPDF() async {
        isLoadingPDF = true
        do {
            pdfData = try await DemandesService.shared.fetchInvoicePDF(id: invoice.id)
            // TODO: présenter le PDF via QuickLook ou UIActivityViewController
        } catch {
            print("[Demandes] PDF download failed: \(error.localizedDescription)")
        }
        isLoadingPDF = false
    }
}

// MARK: - Session List (vue client)

struct DemandesSessionListView: View {
    let patientId: String
    @State private var sessions: [DemandesSession] = []
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Chargement...")
                } else if sessions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar")
                            .font(.system(size: 40))
                            .foregroundColor(Color(hex: "#8B3A62"))
                        Text("Aucune séance enregistrée")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List(sessions) { session in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.sessionDate)
                                    .font(.headline)
                                if let method = session.method {
                                    Text(method)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            if let dur = session.duration {
                                Text("\(dur) min")
                                    .font(.caption.bold().monospaced())
                                    .foregroundColor(Color(hex: "#8B3A62"))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Séances")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                isLoading = true
                sessions = (try? await DemandesService.shared.fetchSessions(patientId: patientId)) ?? []
                isLoading = false
            }
            .refreshable {
                sessions = (try? await DemandesService.shared.fetchSessions(patientId: patientId)) ?? []
            }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Profile (vue client)

struct DemandesProfileView: View {
    let patientId: String
    @State private var patient: DemandesPatient?
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Chargement...")
                } else if let p = patient {
                    List {
                        Section("Identité") {
                            LabeledContent("Nom", value: p.fullName)
                            if let email = p.email { LabeledContent("Email", value: email) }
                            if let phone = p.phone { LabeledContent("Téléphone", value: phone) }
                            if let dob = p.dateOfBirth { LabeledContent("Date de naissance", value: dob) }
                        }
                        Section("Code patient") {
                            LabeledContent("ID", value: patientId)
                        }
                    }
                    .listStyle(.insetGrouped)
                } else {
                    Text("Profil introuvable")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Mon profil")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                isLoading = true
                patient = try? await DemandesService.shared.fetchPatient(id: patientId)
                isLoading = false
            }
        }
        .navigationViewStyle(.stack)
    }
}
