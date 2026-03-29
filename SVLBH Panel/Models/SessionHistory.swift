import Foundation

/// A single entry in the practitioner's session history
struct SessionHistoryEntry: Codable, Identifiable, Hashable {
    var id: String { key }
    let key: String              // e.g. "00-12-002-0301"
    let patientId: String        // e.g. "12"
    let sessionNum: String       // e.g. "002"
    let programCode: String      // e.g. "00"
    let practitionerCode: String // e.g. "0301"
    let timestamp: Date          // when it was pushed
    let headerLine: String       // first SVLBH line for display context

    var displayTitle: String {
        "P\(patientId) · S\(sessionNum)"
    }

    var displaySubtitle: String {
        let df = DateFormatter()
        df.dateFormat = "dd.MM.yyyy HH:mm"
        return "\(programCode) · \(df.string(from: timestamp))"
    }
}

/// Persistent registry of session keys pushed by this practitioner
class SessionHistory {
    private static let storageKey = "svlbh_session_history"
    private static let maxEntries = 500

    static func all() -> [SessionHistoryEntry] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let entries = try? JSONDecoder().decode([SessionHistoryEntry].self, from: data) else {
            return []
        }
        return entries.sorted { $0.timestamp > $1.timestamp }
    }

    static func record(key: String, programCode: String, patientId: String,
                        sessionNum: String, practitionerCode: String, headerLine: String) {
        var entries = all()
        // Update existing or add new
        if let idx = entries.firstIndex(where: { $0.key == key }) {
            entries[idx] = SessionHistoryEntry(
                key: key, patientId: patientId, sessionNum: sessionNum,
                programCode: programCode, practitionerCode: practitionerCode,
                timestamp: Date(), headerLine: headerLine)
        } else {
            entries.insert(SessionHistoryEntry(
                key: key, patientId: patientId, sessionNum: sessionNum,
                programCode: programCode, practitionerCode: practitionerCode,
                timestamp: Date(), headerLine: headerLine), at: 0)
        }
        // Trim oldest
        if entries.count > maxEntries { entries = Array(entries.prefix(maxEntries)) }
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    /// Group entries by patientId, sorted by most recent first
    static func groupedByPatient() -> [(patientId: String, entries: [SessionHistoryEntry])] {
        let entries = all()
        let grouped = Dictionary(grouping: entries) { $0.patientId }
        return grouped.map { (patientId: $0.key, entries: $0.value) }
            .sorted { ($0.entries.first?.timestamp ?? .distantPast) > ($1.entries.first?.timestamp ?? .distantPast) }
    }
}
