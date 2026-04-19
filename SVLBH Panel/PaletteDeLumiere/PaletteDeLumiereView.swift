//
//  PaletteDeLumiereView.swift
//  SVLBH Panel — conteneur Palette de Lumière
//

import SwiftUI

struct PaletteDeLumiereView: View {
    @StateObject private var chromoManager = ChromotherapyManager()
    @StateObject private var elementManager = FiveElementsManager()
    @State private var selectedTab: PDLTab = .palette
    @State private var showHotlineSidebar = false

    enum PDLTab: String, CaseIterable {
        case palette, diagnostic, seance, decodage
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
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { withAnimation(.easeInOut(duration: 0.3)) { showHotlineSidebar.toggle() } } label: {
                        Image(systemName: "bolt.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color(hex: "#8B3A62"))
                    }
                }
            }
            .overlay {
                PDLHotlineSidebarView(isOpen: $showHotlineSidebar)
            }
        }
        .environmentObject(chromoManager)
        .environmentObject(elementManager)
    }
}
