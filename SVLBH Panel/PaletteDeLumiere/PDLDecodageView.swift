//
//  PDLDecodageView.swift
//  SVLBH Panel — importé de Palette de Lumière
//

import SwiftUI

struct PDLDecodageView: View {
    @EnvironmentObject var chromoManager: ChromotherapyManager
    @State private var memoires: [MemoireTransgenerationnelle] = []
    @State private var showingAddMemoire = false
    @State private var selectedLignee: MemoireTransgenerationnelle.Lignee = .maternelle

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                introCard; genealogyTree; ligneeSelector; memoiresSection
                if !memoires.isEmpty { liberationStats }
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAddMemoire = true } label: { Image(systemName: "plus.circle.fill") }
            }
        }
        .sheet(isPresented: $showingAddMemoire) {
            PDLAddMemoireSheet(onAdd: addMemoire)
        }
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tree").font(.title).foregroundStyle(.green)
                Text("Mémoires Transgénérationnelles").font(.headline)
            }
            Text("Identifiez et libérez les mémoires transmises par vos ancêtres à travers les lignées paternelle et maternelle.")
                .font(.subheadline).foregroundStyle(.secondary)
            HStack {
                Rectangle().fill(Color.purple).frame(width: 3)
                Text("\"Nous sommes fils et filles du divin, attachés à nos ancêtres par la transmission de l'énergie polarisée depuis l'origine.\"")
                    .font(.caption).italic().foregroundStyle(.secondary)
            }
            .padding(.top, 8)
        }
        .padding().background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16)).shadow(radius: 5)
    }

    private var genealogyTree: some View {
        VStack(spacing: 16) {
            Text("Arbre Énergétique").font(.headline)
            HStack(spacing: 40) {
                VStack(spacing: 8) {
                    PDLGenerationCircle(generation: 3, label: "Arr. GP", color: .blue.opacity(0.3), count: memoiresCount(lignee: .paternelle, generation: 3))
                    PDLGenerationCircle(generation: 2, label: "GP", color: .blue.opacity(0.5), count: memoiresCount(lignee: .paternelle, generation: 2))
                    PDLGenerationCircle(generation: 1, label: "Père", color: .blue, count: memoiresCount(lignee: .paternelle, generation: 1))
                }
                VStack {
                    Spacer()
                    Circle().fill(LinearGradient(colors: [.blue, .pink], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 60, height: 60)
                        .overlay(Text("Moi").font(.caption).fontWeight(.bold).foregroundStyle(.white))
                }
                VStack(spacing: 8) {
                    PDLGenerationCircle(generation: 3, label: "Arr. GM", color: .pink.opacity(0.3), count: memoiresCount(lignee: .maternelle, generation: 3))
                    PDLGenerationCircle(generation: 2, label: "GM", color: .pink.opacity(0.5), count: memoiresCount(lignee: .maternelle, generation: 2))
                    PDLGenerationCircle(generation: 1, label: "Mère", color: .pink, count: memoiresCount(lignee: .maternelle, generation: 1))
                }
            }
        }
        .padding().background(Color(.systemBackground)).clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var ligneeSelector: some View {
        HStack(spacing: 12) {
            ForEach(MemoireTransgenerationnelle.Lignee.allCases, id: \.self) { lignee in
                Button {
                    withAnimation { selectedLignee = lignee }
                } label: {
                    Text(lignee.rawValue).font(.subheadline)
                        .fontWeight(selectedLignee == lignee ? .semibold : .regular)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(selectedLignee == lignee ? colorForLignee(lignee) : Color.gray.opacity(0.1))
                        .foregroundStyle(selectedLignee == lignee ? .white : .primary)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var memoiresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mémoires identifiées").font(.headline)
            let filteredMemoires = memoires.filter { $0.lignee == selectedLignee || selectedLignee == .mixte }
            if filteredMemoires.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "leaf").font(.largeTitle).foregroundStyle(.secondary)
                    Text("Aucune mémoire enregistrée").foregroundStyle(.secondary)
                    Button("Ajouter une mémoire") { showingAddMemoire = true }.font(.subheadline)
                }
                .frame(maxWidth: .infinity).padding(40)
            } else {
                ForEach(filteredMemoires) { memoire in
                    PDLMemoireCard(memoire: memoire) { toggleLiberation(memoire) }
                }
            }
        }
    }

    private var liberationStats: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progression").font(.headline)
            let total = memoires.count
            let liberees = memoires.filter { $0.estLiberee }.count
            let progress = total > 0 ? Double(liberees) / Double(total) : 0
            VStack(spacing: 8) {
                HStack {
                    Text("\(liberees)/\(total) mémoires libérées").font(.subheadline)
                    Spacer()
                    Text("\(Int(progress * 100))%").font(.headline).foregroundStyle(.green)
                }
                ProgressView(value: progress).tint(.green)
            }
            HStack(spacing: 16) {
                ForEach(TCMElement.allCases) { element in
                    let count = memoires.filter { $0.elementAssocie == element }.count
                    if count > 0 {
                        VStack { Text(element.symbol); Text("\(count)").font(.caption).fontWeight(.semibold) }
                            .padding(8).background(element.color.opacity(0.2)).clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding().background(Color(.systemBackground)).clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func colorForLignee(_ lignee: MemoireTransgenerationnelle.Lignee) -> Color {
        switch lignee { case .paternelle: return .blue; case .maternelle: return .pink; case .mixte: return .purple }
    }
    private func memoiresCount(lignee: MemoireTransgenerationnelle.Lignee, generation: Int) -> Int {
        memoires.filter { $0.lignee == lignee && $0.generation == generation }.count
    }
    private func addMemoire(_ memoire: MemoireTransgenerationnelle) { memoires.append(memoire) }
    private func toggleLiberation(_ memoire: MemoireTransgenerationnelle) {
        if let index = memoires.firstIndex(where: { $0.id == memoire.id }) {
            memoires[index].estLiberee.toggle()
            memoires[index].dateLiberarion = memoires[index].estLiberee ? Date() : nil
        }
    }
}

struct PDLGenerationCircle: View {
    let generation: Int; let label: String; let color: Color; let count: Int
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle().fill(color).frame(width: 44, height: 44)
                if count > 0 {
                    Circle().fill(Color.red).frame(width: 18, height: 18)
                        .overlay(Text("\(count)").font(.caption2).fontWeight(.bold).foregroundStyle(.white))
                        .offset(x: 16, y: -16)
                }
            }
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }
}

struct PDLMemoireCard: View {
    let memoire: MemoireTransgenerationnelle; let onToggle: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            Circle().fill(Color(hex: memoire.couleurLiberatrice)).frame(width: 40, height: 40)
                .overlay(Text(memoire.elementAssocie.symbol))
            VStack(alignment: .leading, spacing: 4) {
                Text(memoire.description).font(.subheadline).lineLimit(2)
                HStack {
                    Text("Génération \(memoire.generation)").font(.caption).foregroundStyle(.secondary)
                    Text("•").foregroundStyle(.secondary)
                    Text(memoire.lignee.rawValue).font(.caption).foregroundStyle(memoire.lignee == .paternelle ? .blue : .pink)
                }
            }
            Spacer()
            Button(action: onToggle) {
                Image(systemName: memoire.estLiberee ? "checkmark.circle.fill" : "circle")
                    .font(.title2).foregroundStyle(memoire.estLiberee ? .green : .gray)
            }
        }
        .padding().background(memoire.estLiberee ? Color.green.opacity(0.1) : Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12)).shadow(radius: 2)
    }
}

struct PDLAddMemoireSheet: View {
    let onAdd: (MemoireTransgenerationnelle) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var description = ""
    @State private var generation = 1
    @State private var lignee: MemoireTransgenerationnelle.Lignee = .maternelle
    @State private var element: TCMElement = .eau

    var body: some View {
        NavigationStack {
            Form {
                Section("Description de la mémoire") { TextEditor(text: $description).frame(minHeight: 80) }
                Section("Origine") {
                    Picker("Génération", selection: $generation) {
                        Text("Parents (1)").tag(1); Text("Grands-parents (2)").tag(2)
                        Text("Arrière-grands-parents (3)").tag(3); Text("Plus ancien (4+)").tag(4)
                    }
                    Picker("Lignée", selection: $lignee) {
                        ForEach(MemoireTransgenerationnelle.Lignee.allCases, id: \.self) { l in Text(l.rawValue).tag(l) }
                    }
                }
                Section("Élément associé") {
                    Picker("Élément TCM", selection: $element) {
                        ForEach(TCMElement.allCases) { e in HStack { Text(e.symbol); Text(e.rawValue) }.tag(e) }
                    }
                    Text("Émotion: \(element.emotion)").font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Nouvelle mémoire").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        let memoire = MemoireTransgenerationnelle(
                            id: UUID(), description: description, generation: generation, lignee: lignee,
                            elementAssocie: element, couleurLiberatrice: element.color.toHex() ?? "#FFFFFF",
                            dateIdentification: Date(), estLiberee: false, dateLiberarion: nil)
                        onAdd(memoire); dismiss()
                    }
                    .disabled(description.isEmpty)
                }
            }
        }
    }
}
