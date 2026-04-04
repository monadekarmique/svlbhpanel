// SVLBHPanel — Views/PierresSheetButton.swift
// Bouton réutilisable pour ouvrir PierresTab en sheet

import SwiftUI

struct PierresSheetButton: View {
    @Binding var showPierres: Bool

    var body: some View {
        Button { showPierres = true } label: {
            HStack(spacing: 6) {
                Image(systemName: "diamond")
                    .font(.system(size: 12))
                Text("Pierres")
                    .font(.system(size: 13, weight: .semibold))
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 10))
            }
            .foregroundColor(Color(hex: "#8B3A62"))
            .padding(.horizontal, 14).padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Color(hex: "#8B3A62").opacity(0.08))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(hex: "#8B3A62").opacity(0.2), lineWidth: 1)
            )
        }
    }
}
