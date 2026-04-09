// DemandesService.swift
// SVLBHPanel — Service réseau pour le portail client Demandes
// Communique avec https://vlbh-energy-mcp.onrender.com

import Foundation

final class DemandesService: ObservableObject {
    static let shared = DemandesService()

    private let baseURL = "https://vlbh-energy-mcp.onrender.com"
    private let urlSession = URLSession.shared

    private var token: String {
        UserDefaults.standard.string(forKey: "vlbh_token") ?? ""
    }

    // MARK: - Invoices

    func fetchInvoices(patientId: String) async throws -> [DemandesInvoice] {
        let url = URL(string: "\(baseURL)/invoices?patient_id=\(patientId)")!
        let data = try await get(url: url)
        let response = try JSONDecoder().decode(InvoiceListResponse.self, from: data)
        return response.invoices
    }

    func fetchInvoice(id: String) async throws -> DemandesInvoice {
        let url = URL(string: "\(baseURL)/invoices/\(id)")!
        let data = try await get(url: url)
        return try JSONDecoder().decode(DemandesInvoice.self, from: data)
    }

    func fetchInvoicePDF(id: String) async throws -> Data {
        let url = URL(string: "\(baseURL)/invoices/\(id)/pdf")!
        return try await get(url: url)
    }

    // MARK: - Sessions

    func fetchSessions(patientId: String) async throws -> [DemandesSession] {
        let url = URL(string: "\(baseURL)/therapy-sessions?patient_id=\(patientId)")!
        let data = try await get(url: url)
        let response = try JSONDecoder().decode(SessionListResponse.self, from: data)
        return response.sessions
    }

    // MARK: - Patient Profile

    func fetchPatient(id: String) async throws -> DemandesPatient {
        let url = URL(string: "\(baseURL)/patients/\(id)")!
        let data = try await get(url: url)
        return try JSONDecoder().decode(DemandesPatient.self, from: data)
    }

    // MARK: - QR Bill

    func fetchQRBill(invoiceId: String) async throws -> String {
        let url = URL(string: "\(baseURL)/qrbill/generate")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(token, forHTTPHeaderField: "X-VLBH-Token")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["invoice_id": invoiceId])

        let (data, response) = try await urlSession.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw DemandesServiceError.requestFailed("QR bill generation failed")
        }
        return String(data: data, encoding: .utf8) ?? ""
    }

    // MARK: - Private

    private func get(url: URL) async throws -> Data {
        var req = URLRequest(url: url)
        req.setValue(token, forHTTPHeaderField: "X-VLBH-Token")
        req.timeoutInterval = 15

        let (data, response) = try await urlSession.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw DemandesServiceError.requestFailed(body)
        }
        return data
    }
}

enum DemandesServiceError: LocalizedError {
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .requestFailed(let msg): return "Erreur: \(msg)"
        }
    }
}
