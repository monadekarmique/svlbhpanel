// SVLBHPanel — Views/SessionTimelinePanel.swift
// v4.8.0 — Panneau timeline latéral rétractable

import SwiftUI

struct SessionTimelinePanel: View {
    @EnvironmentObject var tracker: SessionTracker
    @Binding var isVisible: Bool

    var body: some View {
        if isVisible && tracker.isActive {
            HStack(spacing: 0) {
                Spacer()
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("TIMELINE")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(hex: "#8B3A62"))
                        Spacer()
                        Button { withAnimation { isVisible = false } } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 12).padding(.vertical, 10)

                    Divider()

                    // Events
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(tracker.events) { event in
                                TimelineEventRow(event: event, tracker: tracker)
                                Divider().padding(.leading, 40)
                            }
                        }
                    }

                    Divider()

                    // Footer durée
                    HStack {
                        Text("Durée")
                            .font(.caption2).foregroundColor(.secondary)
                        Spacer()
                        Text(durationString)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(hex: "#8B3A62"))
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                }
                .frame(width: 220)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.15), radius: 12, x: -4, y: 0)
                .padding(.vertical, 60)
                .padding(.trailing, 4)
            }
            .transition(.move(edge: .trailing))
        }
    }

    private var durationString: String {
        let elapsed = Date().timeIntervalSince(tracker.sessionStart)
        let min = Int(elapsed) / 60
        let sec = Int(elapsed) % 60
        return String(format: "%02d:%02d", min, sec)
    }
}

struct TimelineEventRow: View {
    let event: SessionEvent
    let tracker: SessionTracker

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Timestamp
            Text(tracker.timeString(event.timestamp))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 36)

            // Icon
            Text(event.category.icon)
                .font(.system(size: 12))

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(event.label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: event.category.colorHex))
                    .lineLimit(2)
                if let niveau = event.niveau {
                    Text(niveau)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(hex: event.category.colorHex).opacity(0.7))
                }
                if event.isLiberated {
                    Text("Libéré ✓")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(hex: "#1D9E75"))
                }
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
    }
}
