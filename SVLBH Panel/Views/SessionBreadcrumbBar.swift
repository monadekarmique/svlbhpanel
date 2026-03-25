// SVLBHPanel — Views/SessionBreadcrumbBar.swift
// v4.8.0 — Fil d'Ariane horizontal scrollable

import SwiftUI

struct SessionBreadcrumbBar: View {
    @EnvironmentObject var tracker: SessionTracker

    var body: some View {
        if tracker.isActive && !tracker.events.isEmpty {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(tracker.events) { event in
                            BreadcrumbBadge(event: event)
                                .id(event.id)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .background(Color(UIColor.systemBackground).opacity(0.95))
                .onChange(of: tracker.events.count) { _ in
                    if let last = tracker.events.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .trailing) }
                    }
                }
            }
            .frame(height: 36)
        }
    }
}

struct BreadcrumbBadge: View {
    let event: SessionEvent

    var body: some View {
        HStack(spacing: 3) {
            Text(event.category.icon)
                .font(.system(size: 10))
            Text(shortLabel)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color(hex: event.category.colorHex))
                .lineLimit(1)
        }
        .padding(.horizontal, 7).padding(.vertical, 4)
        .background(Color(hex: event.category.colorHex).opacity(0.12))
        .cornerRadius(6)
    }

    private var shortLabel: String {
        let words = event.label.split(separator: " ")
        if words.count > 2 {
            return words.prefix(2).joined(separator: " ")
        }
        return event.label
    }
}
