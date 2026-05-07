//
//  PaletteDeLumiereView.swift
//  SVLBH Panel — conteneur Palette de Lumière
//

import SwiftUI

struct PaletteDeLumiereView: View {
    @StateObject private var chromoManager = ChromotherapyManager()
    @StateObject private var elementManager = FiveElementsManager()
    @State private var selectedTab: PDLTab

    enum PDLTab: String, CaseIterable {
        case palette, diagnostic, seance, decodage
    }

    init(initialTab: PDLTab = .palette) {
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                PDLPaletteView()
                    .tabItem { Label("Palette", systemImage: "paintpalette.fill") }
                    .tag(PDLTab.palette)

                PDLDiagnosticView()
                    .tabItem { Label("Diagnostic", systemImage: "waveform.path.ecg") }
                    .tag(PDLTab.diagnostic)

                PDLSessionView()
                    .tabItem { Label("Séance", systemImage: "rays") }
                    .tag(PDLTab.seance)

                PDLDecodageView()
                    .tabItem { Label("Décodage", systemImage: "tree") }
                    .tag(PDLTab.decodage)
            }
            .tint(chromoManager.currentElement.color)
            .navigationTitle("Palette de Lumière")
            .navigationBarTitleDisplayMode(.inline)
        }
        .environmentObject(chromoManager)
        .environmentObject(elementManager)
    }
}
