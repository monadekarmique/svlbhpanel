// SVLBHPanel — Views/ReferenceSystemView.swift
// v4.0.0 — Systèmes de référence (groupes d'images) + broadcast

import SwiftUI

// MARK: - Liste des systèmes de référence
struct ReferenceSystemView: View {
    @EnvironmentObject var session: SessionState
    @EnvironmentObject var sync: MakeSyncService
    @Environment(\.dismiss) var dismiss
    @State private var showComposer = false
    @State private var editingSet: ReferenceImageSet?

    var body: some View {
        NavigationView {
            List {
                if session.referenceImageSets.isEmpty {
                    Section {
                        Text("Aucun système de référence")
                            .foregroundColor(.secondary).italic()
                    }
                }

                ForEach(session.referenceImageSets) { set in
                    Section(set.nom) {
                        if !set.description.isEmpty {
                            Text(set.description)
                                .font(.caption).foregroundColor(.secondary)
                        }

                        // Preview grid (max 6 thumbnails)
                        let paths = set.imagePaths().prefix(6)
                        if !paths.isEmpty {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 4) {
                                ForEach(Array(paths.enumerated()), id: \.offset) { _, path in
                                    if let img = UIImage(contentsOfFile: path) {
                                        Image(uiImage: img)
                                            .resizable().scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipped().cornerRadius(6)
                                    }
                                }
                                if set.imageFileNames.count > 6 {
                                    Text("+\(set.imageFileNames.count - 6)")
                                        .font(.caption.bold()).foregroundColor(.secondary)
                                        .frame(width: 60, height: 60)
                                        .background(Color.gray.opacity(0.15))
                                        .cornerRadius(6)
                                }
                            }
                        }

                        HStack {
                            Text("\(set.imageFileNames.count) images")
                                .font(.caption).foregroundColor(.secondary)
                            Spacer()

                            // Éditer
                            Button {
                                editingSet = set
                                showComposer = true
                            } label: {
                                Label("Éditer", systemImage: "pencil")
                                    .font(.caption)
                            }

                            // Broadcast
                            if !session.shamanesCertifiees.isEmpty {
                                Button {
                                    // TODO: broadcast via Make.com avec les images
                                } label: {
                                    Label("Broadcast", systemImage: "antenna.radiowaves.left.and.right")
                                        .font(.caption).foregroundColor(Color(hex: "#B8965A"))
                                }
                            }
                        }
                    }
                }
                .onDelete { indices in
                    for i in indices { session.removeImageSet(session.referenceImageSets[i]) }
                }
            }
            .navigationTitle("Systèmes de référence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        editingSet = nil
                        showComposer = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("OK") { dismiss() }
                }
            }
            .sheet(isPresented: $showComposer) {
                ImageSetComposer(existingSet: editingSet)
                    .environmentObject(session)
            }
        }
    }
}

// MARK: - Composer un système (sélectionner des images)
struct ImageSetComposer: View {
    @EnvironmentObject var session: SessionState
    @Environment(\.dismiss) var dismiss
    var existingSet: ReferenceImageSet?

    @State private var nom = ""
    @State private var desc = ""
    @State private var selectedFiles: Set<String> = []
    @State private var allFiles: [String] = []

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // En-tête formulaire
                VStack(spacing: 8) {
                    TextField("Nom du système", text: $nom)
                        .textFieldStyle(.roundedBorder)
                    TextField("Description (optionnel)", text: $desc)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                    HStack {
                        Text("\(selectedFiles.count) / \(allFiles.count) images sélectionnées")
                            .font(.caption).foregroundColor(.secondary)
                        Spacer()
                        Button("Tout") { selectedFiles = Set(allFiles) }
                            .font(.caption)
                        Button("Rien") { selectedFiles = [] }
                            .font(.caption)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 10)

                Divider()

                // Grille d'images
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 6) {
                        ForEach(allFiles, id: \.self) { fileName in
                            let path = "\(ReferenceImageSet.basePath)/\(fileName)"
                            let isSelected = selectedFiles.contains(fileName)
                            Button {
                                if isSelected { selectedFiles.remove(fileName) }
                                else { selectedFiles.insert(fileName) }
                            } label: {
                                ZStack(alignment: .topTrailing) {
                                    if let img = UIImage(contentsOfFile: path) {
                                        Image(uiImage: img)
                                            .resizable().scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipped()
                                    } else {
                                        Rectangle().fill(Color.gray.opacity(0.2))
                                            .frame(width: 80, height: 80)
                                    }
                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color(hex: "#8B3A62"))
                                            .background(Circle().fill(.white).frame(width: 18, height: 18))
                                            .padding(4)
                                    }
                                }
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(isSelected ? Color(hex: "#8B3A62") : .clear, lineWidth: 2)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                }
            }
            .navigationTitle(existingSet == nil ? "Nouveau système" : "Éditer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Enregistrer") {
                        let n = nom.trimmingCharacters(in: .whitespaces)
                        guard !n.isEmpty else { return }
                        if var existing = existingSet {
                            existing.nom = n
                            existing.description = desc
                            existing.imageFileNames = allFiles.filter { selectedFiles.contains($0) }
                            session.updateImageSet(existing)
                        } else {
                            _ = session.addImageSet(
                                nom: n, description: desc,
                                fileNames: allFiles.filter { selectedFiles.contains($0) }
                            )
                        }
                        dismiss()
                    }
                    .disabled(nom.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                loadDriveFiles()
                if let e = existingSet {
                    nom = e.nom
                    desc = e.description
                    selectedFiles = Set(e.imageFileNames)
                }
            }
        }
    }

    private func loadDriveFiles() {
        let fm = FileManager.default
        let path = ReferenceImageSet.basePath
        guard let files = try? fm.contentsOfDirectory(atPath: path) else { return }
        allFiles = files
            .filter { $0.hasSuffix(".jpg") || $0.hasSuffix(".png") || $0.hasSuffix(".JPG") || $0.hasSuffix(".PNG") }
            .sorted()
    }
}
