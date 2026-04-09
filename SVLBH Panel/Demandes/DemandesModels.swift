// DemandesModels.swift
// SVLBHPanel — Modèles pour le portail client "Demandes"
// Compatible avec l'API iTherapeut 6.0 (vlbh-energy-mcp)

import Foundation

// MARK: - Invoice

struct DemandesInvoice: Codable, Identifiable {
    let id: String
    let invoiceNumber: String
    let patientId: String
    let practitionerId: String?
    let amount: Double
    let currency: String
    let status: InvoiceStatus
    let issueDate: String
    let dueDate: String?
    let paidDate: String?
    let description: String?
    let items: [InvoiceItem]?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case invoiceNumber = "invoice_number"
        case patientId = "patient_id"
        case practitionerId = "practitioner_id"
        case amount, currency, status
        case issueDate = "issue_date"
        case dueDate = "due_date"
        case paidDate = "paid_date"
        case description, items
        case createdAt = "created_at"
    }
}

enum InvoiceStatus: String, Codable {
    case draft = "draft"
    case sent = "sent"
    case paid = "paid"
    case overdue = "overdue"
    case cancelled = "cancelled"

    var label: String {
        switch self {
        case .draft: return "Brouillon"
        case .sent: return "Envoyée"
        case .paid: return "Payée"
        case .overdue: return "En retard"
        case .cancelled: return "Annulée"
        }
    }

    var color: String {
        switch self {
        case .draft: return "#999999"
        case .sent: return "#BA7517"
        case .paid: return "#1D9E75"
        case .overdue: return "#E24B4A"
        case .cancelled: return "#666666"
        }
    }
}

struct InvoiceItem: Codable {
    let description: String?
    let quantity: Double?
    let unitPrice: Double?
    let amount: Double?

    enum CodingKeys: String, CodingKey {
        case description, quantity
        case unitPrice = "unit_price"
        case amount
    }
}

// MARK: - Therapy Session (vue client)

struct DemandesSession: Codable, Identifiable {
    let id: String
    let patientId: String
    let practitionerId: String?
    let sessionDate: String
    let duration: Int?
    let method: String?
    let notes: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case practitionerId = "practitioner_id"
        case sessionDate = "session_date"
        case duration, method, notes, status
    }
}

// MARK: - Patient Profile

struct DemandesPatient: Codable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String?
    let phone: String?
    let dateOfBirth: String?

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case email, phone
        case dateOfBirth = "date_of_birth"
    }

    var fullName: String { "\(firstName) \(lastName)" }
}

// MARK: - API List Responses

struct InvoiceListResponse: Codable {
    let invoices: [DemandesInvoice]
    let total: Int?
}

struct SessionListResponse: Codable {
    let sessions: [DemandesSession]
    let total: Int?
}
