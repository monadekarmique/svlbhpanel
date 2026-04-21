// SVLBHPanel — Views/LingguiBafaView.swift
// Linggui Bafa 灵龟八法 — Daytable des 8 points de confluence des merveilleux vaisseaux
// Calcul basé sur Tian Gan / Di Zhi (Heavenly Stems / Earthly Branches)

import SwiftUI

// MARK: - Data Model

/// Les 8 points de confluence des vaisseaux extraordinaires
private struct BafaPoint: Identifiable {
    let id: Int          // 1-8 (numéro Bafa)
    let code: String     // ex: "R6 / KD6"
    let pinyin: String   // ex: "zhaohai"
    let vessel: String   // ex: "Yin Qiao Mai"
}

/// Créneau horaire de 2h avec paire de points
private struct BafaSlot: Identifiable {
    let id: Int
    let startHour: Int
    let endHour: Int
    let upper: BafaPoint
    let lower: BafaPoint
}

// MARK: - Les 8 points Bafa

private let bafaPoints: [BafaPoint] = [
    .init(id: 1, code: "L4 / SP4",    pinyin: "gongsun",  vessel: "Chong Mai"),
    .init(id: 2, code: "Pc6 / P6",    pinyin: "neiguan",  vessel: "Yin Wei Mai"),
    .init(id: 3, code: "IT3 / SI3",   pinyin: "houxi",    vessel: "Du Mai"),
    .init(id: 4, code: "V62 / UB62",  pinyin: "shenmo",   vessel: "Yang Qiao Mai"),
    .init(id: 5, code: "T5 / SJ5",    pinyin: "waiguan",  vessel: "Yang Wei Mai"),
    .init(id: 6, code: "F41 / GB41",  pinyin: "linqi",    vessel: "Dai Mai"),
    .init(id: 7, code: "R6 / KD6",    pinyin: "zhaohai",  vessel: "Yin Qiao Mai"),
    .init(id: 8, code: "P7 / LU7",    pinyin: "lieque",   vessel: "Ren Mai"),
]

// MARK: - Linggui Bafa Calculation Engine

/// Tian Gan (10 Heavenly Stems) — coefficients pour le calcul
private let tianGanCoeff = [1, 6, 2, 7, 3, 8, 4, 9, 5, 10]

/// Di Zhi (12 Earthly Branches) — coefficients pour le calcul
private let diZhiCoeff = [1, 6, 2, 7, 3, 8, 4, 9, 5, 10, 1, 6]

/// Mapping du résultat modulo 9 vers les indices de paires de points Bafa
/// Chaque créneau de 2h donne une paire (point principal + point couplé)
private let bafaPairMap: [(upper: Int, lower: Int)] = [
    (7, 8),  // R6/KD6 + P7/LU7
    (7, 8),  // R6/KD6 + P7/LU7
    (5, 6),  // T5/SJ5 + F41/GB41
    (4, 3),  // V62/UB62 + IT3/SI3
    (7, 8),  // R6/KD6 + P7/LU7
    (5, 6),  // T5/SJ5 + F41/GB41
    (1, 2),  // L4/SP4 + Pc6/P6
    (6, 5),  // F41/GB41 + T5/SJ5
    (7, 8),  // R6/KD6 + P7/LU7
]

/// Calcule le Tian Gan index (0-9) pour un jour donné
private func tianGanIndex(for date: Date) -> Int {
    // Référence : 1er janvier 1900 = Tian Gan index 0 (Jia 甲)
    let cal = Calendar(identifier: .gregorian)
    let ref = cal.date(from: DateComponents(year: 1900, month: 1, day: 1))!
    let days = cal.dateComponents([.day], from: ref, to: date).day ?? 0
    return ((days % 10) + 10) % 10
}

/// Calcule le Di Zhi index (0-11) pour un créneau de 2h
private func diZhiIndex(hour: Int) -> Int {
    // 23-01 = Zi(0), 01-03 = Chou(1), 03-05 = Yin(2), ...
    let adjusted = (hour + 1) % 24
    return adjusted / 2
}

/// Calcule la paire de points Bafa pour un jour et créneau donné
private func bafaPairForSlot(date: Date, startHour: Int) -> (upper: BafaPoint, lower: BafaPoint) {
    let tg = tianGanIndex(for: date)
    let dz = diZhiIndex(hour: startHour)
    let sum = tianGanCoeff[tg] + diZhiCoeff[dz]
    let idx = sum % 9
    let pair = bafaPairMap[idx]
    return (bafaPoints[pair.upper - 1], bafaPoints[pair.lower - 1])
}

/// Génère les 12 créneaux d'un jour
private func daySlots(for date: Date) -> [BafaSlot] {
    var slots: [BafaSlot] = []
    // 12 créneaux de 2h commençant à une heure basée sur la correction
    // Les heures sont fixes : 0,2,4,6,8,10,12,14,16,18,20,22
    let startHours = stride(from: 0, to: 24, by: 2)
    for (i, h) in startHours.enumerated() {
        let pair = bafaPairForSlot(date: date, startHour: h)
        slots.append(BafaSlot(
            id: i,
            startHour: h,
            endHour: (h + 2) % 24,
            upper: pair.upper,
            lower: pair.lower
        ))
    }
    return slots
}

// MARK: - True Local Time Correction

/// Calcule la correction en secondes entre le fuseau horaire et le temps solaire vrai
/// longitude de référence : Avenches ~7.04°E → fuseau UTC+1 = 15°E
private func trueLocalTimeCorrection(longitude: Double, utcOffset: Int) -> Int {
    let solarOffset = longitude / 15.0 * 3600.0  // secondes par rapport à Greenwich
    let zoneOffset = Double(utcOffset)            // secondes du fuseau
    return Int(solarOffset - zoneOffset)
}

private func formatCorrection(_ totalSeconds: Int) -> String {
    let sign = totalSeconds < 0 ? "-" : "+"
    let abs = Swift.abs(totalSeconds)
    let h = abs / 3600
    let m = (abs % 3600) / 60
    let s = abs % 60
    return "\(sign)\(h)H \(m)M \(s)S"
}

// MARK: - View

struct LingguiBafaView: View {
    @State private var selectedDate = Date()
    @State private var showTimeZonePicker = false
    @State private var selectedTimeZone = TimeZone.current
    // Avenches default longitude
    @State private var longitude: Double = 7.04

    private var utcOffset: Int {
        selectedTimeZone.secondsFromGMT(for: selectedDate)
    }

    private var correction: Int {
        trueLocalTimeCorrection(longitude: longitude, utcOffset: utcOffset)
    }

    private var correctedMinuteOffset: Int {
        // Décalage en minutes à appliquer aux heures affichées
        let totalSec = correction
        return totalSec / 60
    }

    private var slots: [BafaSlot] {
        daySlots(for: selectedDate)
    }

    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "EEEE, d MMMM yyyy"
        df.locale = Locale(identifier: "en_US")
        df.timeZone = selectedTimeZone
        return df
    }

    private func formatHour(_ h: Int) -> String {
        let totalMin = h * 60 + correctedMinuteOffset
        let adjustedMin = ((totalMin % 1440) + 1440) % 1440
        let hh = adjustedMin / 60
        let mm = adjustedMin % 60
        return String(format: "%d:%02d", hh, mm)
    }

    // Current slot highlight
    private var currentSlotIndex: Int? {
        let cal = Calendar.current
        let h = cal.component(.hour, from: Date())
        return h / 2
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Date picker
                HStack {
                    Button { selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate } label: {
                        Image(systemName: "chevron.left").font(.caption)
                    }
                    Spacer()
                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                    Spacer()
                    Button { selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate } label: {
                        Image(systemName: "chevron.right").font(.caption)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 8)

                // Date header
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateFormatter.string(from: selectedDate).uppercased())
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)

                    // Timezone button — tap to change
                    Button { showTimeZonePicker = true } label: {
                        HStack(spacing: 4) {
                            Text("TRUE LOCAL TIME CORRECTION: \(formatCorrection(correction))")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondary)
                            Image(systemName: "globe").font(.system(size: 10)).foregroundColor(.blue)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)

                Divider()

                // Slots
                ForEach(slots) { slot in
                    let isCurrent = slot.id == currentSlotIndex && Calendar.current.isDateInToday(selectedDate)
                    VStack(spacing: 0) {
                        HStack(alignment: .top, spacing: 0) {
                            // Hours
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(formatHour(slot.startHour))
                                    .font(.system(size: 14, weight: isCurrent ? .bold : .regular, design: .monospaced))
                                Text(formatHour(slot.endHour))
                                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 50, alignment: .trailing)
                            .padding(.trailing, 12)

                            // Divider line
                            Rectangle()
                                .fill(isCurrent ? Color.blue : Color.secondary.opacity(0.3))
                                .frame(width: isCurrent ? 2 : 1)
                                .padding(.vertical, 2)

                            // Points
                            VStack(alignment: .leading, spacing: 4) {
                                pointRow(slot.upper, isCurrent: isCurrent)
                                pointRow(slot.lower, isCurrent: isCurrent)
                            }
                            .padding(.leading, 12)

                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(isCurrent ? Color.blue.opacity(0.05) : Color.clear)

                        Divider().padding(.leading, 62)
                    }
                }

                Spacer().frame(height: 80)
            }
        }
        .navigationTitle("Daytable")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showTimeZonePicker) {
            TimeZonePickerSheet(
                selectedTimeZone: $selectedTimeZone,
                longitude: $longitude,
                isPresented: $showTimeZonePicker
            )
        }
    }

    private func pointRow(_ pt: BafaPoint, isCurrent: Bool) -> some View {
        HStack(spacing: 16) {
            Text(pt.code)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 110, alignment: .leading)
            Text(pt.pinyin)
                .font(.system(size: 15))
                .foregroundColor(.blue)
        }
    }
}

// MARK: - TimeZone Picker

private struct TimeZonePickerSheet: View {
    @Binding var selectedTimeZone: TimeZone
    @Binding var longitude: Double
    @Binding var isPresented: Bool
    @State private var search = ""

    private let commonZones: [(label: String, id: String, lon: Double)] = [
        ("Suisse (Avenches)", "Europe/Zurich", 7.04),
        ("France (Paris)", "Europe/Paris", 2.35),
        ("Italie (Rome)", "Europe/Rome", 12.50),
        ("Allemagne (Berlin)", "Europe/Berlin", 13.40),
        ("Royaume-Uni (Londres)", "Europe/London", -0.12),
        ("USA Est (New York)", "America/New_York", -74.00),
        ("USA Ouest (Los Angeles)", "America/Los_Angeles", -118.24),
        ("Japon (Tokyo)", "Asia/Tokyo", 139.69),
        ("Inde (Delhi)", "Asia/Kolkata", 77.21),
        ("Australie (Sydney)", "Australia/Sydney", 151.21),
        ("Br\u{00e9}sil (S\u{00e3}o Paulo)", "America/Sao_Paulo", -46.63),
        ("Maroc (Casablanca)", "Africa/Casablanca", -7.59),
    ]

    private var filtered: [(label: String, id: String, lon: Double)] {
        if search.isEmpty { return commonZones }
        let q = search.lowercased()
        return commonZones.filter { $0.label.lowercased().contains(q) || $0.id.lowercased().contains(q) }
    }

    private func utcLabel(for zoneId: String, lon: Double) -> String {
        guard let tz = TimeZone(identifier: zoneId) else { return "?" }
        let h = tz.secondsFromGMT() / 3600
        let sign = h >= 0 ? "+" : ""
        return "UTC\(sign)\(h) \u{00b7} lon \(String(format: "%.1f", lon))\u{00b0}"
    }

    var body: some View {
        NavigationView {
            List {
                Section("Fuseau horaire") {
                    ForEach(filtered, id: \.id) { zone in
                        let isSelected = selectedTimeZone.identifier == zone.id
                        Button {
                            if let tz = TimeZone(identifier: zone.id) {
                                selectedTimeZone = tz
                                longitude = zone.lon
                            }
                            isPresented = false
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(zone.label).font(.callout).foregroundColor(.primary)
                                    Text(utcLabel(for: zone.id, lon: zone.lon))
                                        .font(.caption2).foregroundColor(.secondary)
                                }
                                Spacer()
                                if isSelected {
                                    Image(systemName: "checkmark").foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }

                Section("Longitude personnalis\u{00e9}e") {
                    HStack {
                        Text("Longitude")
                        Spacer()
                        TextField("7.04", value: $longitude, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("\u{00b0}")
                    }
                }
            }
            .searchable(text: $search, prompt: "Chercher un fuseau")
            .navigationTitle("Fuseau horaire")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { isPresented = false }
                }
            }
        }
    }
}
