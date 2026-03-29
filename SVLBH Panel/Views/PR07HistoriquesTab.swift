import SwiftUI

struct PR07HistoriquesTab: View {
    @EnvironmentObject var session: SessionState

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(spacing: 3) {
                        Text("\u{25c8} PR 07 : Accumulations historiques")
                            .font(.title2.bold()).foregroundColor(Color(hex: "#8B3A62"))
                        Text("Accumulations historiques erron\u{00e9}es")
                            .font(.caption).foregroundColor(Color(hex: "#333333"))
                    }
                    .padding(.top, 14)

                    VStack(alignment: .leading, spacing: 12) {
                        Divider()
                        Label("Programme en cours de r\u{00e9}daction", systemImage: "doc.text")
                            .font(.headline).foregroundColor(Color(hex: "#8B3A62"))
                        Text("Ce programme de recherche \u{00e9}tudie les accumulations \u{00e9}nerg\u{00e9}tiques bas\u{00e9}es sur des interpr\u{00e9}tations historiques erron\u{00e9}es, transmises sur plusieurs g\u{00e9}n\u{00e9}rations et leur impact sur le corps de lumi\u{00e8}re.")
                            .font(.callout).foregroundColor(Color(hex: "#333333"))
                    }
                    .padding(.horizontal, 16)
                }
                .padding()
                .padding(.bottom, 80)
            }
            .navigationTitle("PR 07 : Historiques")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }
}
