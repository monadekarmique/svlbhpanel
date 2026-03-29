import SwiftUI

struct PR03EndometreTab: View {
    @EnvironmentObject var session: SessionState

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(spacing: 3) {
                        Text("\u{25c8} PR 03 : Endom\u{00e8}tre")
                            .font(.title2.bold()).foregroundColor(Color(hex: "#8B3A62"))
                        Text("Accumulations \u{00e9}nerg\u{00e9}tiques sur l\u{2019}endom\u{00e8}tre")
                            .font(.caption).foregroundColor(Color(hex: "#333333"))
                    }
                    .padding(.top, 14)

                    VStack(alignment: .leading, spacing: 12) {
                        Divider()
                        Label("Programme en cours de r\u{00e9}daction", systemImage: "doc.text")
                            .font(.headline).foregroundColor(Color(hex: "#8B3A62"))
                        Text("Ce programme de recherche documente les accumulations \u{00e9}nerg\u{00e9}tiques transg\u{00e9}n\u{00e9}rationnelles sur l\u{2019}endom\u{00e8}tre, leur impact sur les cycles f\u{00e9}minins et les protocoles SVLBH de lib\u{00e9}ration associ\u{00e9}s.")
                            .font(.callout).foregroundColor(Color(hex: "#333333"))
                    }
                    .padding(.horizontal, 16)
                }
                .padding()
                .padding(.bottom, 80)
            }
            .navigationTitle("PR 03 : Endom\u{00e8}tre")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }
}
