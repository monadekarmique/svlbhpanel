//
//  ChronoFuSidePanel.swift
//  SVLBH Panel — Panneau latéral escamotable Chrono 六腑
//

import SwiftUI

struct ChronoFuSidePanel<Content: View>: View {
    @Binding var isOpen: Bool
    let content: Content
    private let panelWidth: CGFloat = 360

    init(isOpen: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._isOpen = isOpen
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            content

            if isOpen {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(.easeInOut(duration: 0.25)) { isOpen = false } }
            }

            HStack(spacing: 0) {
                Spacer()
                VStack(spacing: 0) {
                    HStack {
                        Text("Chrono 六腑")
                            .font(.headline)
                        Spacer()
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) { isOpen = false }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()

                    Divider()

                    ChronoFuTab()
                }
                .frame(width: panelWidth)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 12, x: -4)
                .offset(x: isOpen ? 0 : panelWidth + 20)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isOpen)
    }
}

// MARK: - Toolbar button

struct ChronoFuToolbarButton: View {
    @Binding var isOpen: Bool

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) { isOpen.toggle() }
        } label: {
            Label("Chrono 六腑", systemImage: "clock.arrow.circlepath")
        }
    }
}
