import SwiftUI

struct EtApresTab: View {
    @EnvironmentObject var session: SessionState

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(spacing: 3) {
                        Text("\u{25c8} Et apr\u{00e8}s ?")
                            .font(.title2.bold()).foregroundColor(Color(hex: "#8B3A62"))
                        Text("Prochaines \u{00e9}tapes du Digital Shaman Lab")
                            .font(.caption).foregroundColor(Color(hex: "#333333"))
                    }
                    .padding(.top, 14)

                    VStack(alignment: .leading, spacing: 12) {
                        Divider()
                        Label("Contenu \u{00e0} venir", systemImage: "sparkles")
                            .font(.headline).foregroundColor(Color(hex: "#8B3A62"))
                        Text("Cette section documentera les perspectives d\u{2019}\u{00e9}volution du programme SVLBH, les nouvelles pistes de recherche et les prochaines \u{00e9}tapes pour les shamanes certifi\u{00e9}es.")
                            .font(.callout).foregroundColor(Color(hex: "#333333"))
                    }
                    .padding(.horizontal, 16)
                }
                .padding()
                .padding(.bottom, 80)
            }
            .navigationTitle("Et apr\u{00e8}s ?")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }
}
