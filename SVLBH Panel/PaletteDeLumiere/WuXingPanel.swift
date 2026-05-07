// WuXingPanel.swift — Les 5 Éléments (五行) Sheng/Ke
// Porté de SVLBH VIFA WuXingTab.swift (Patrick 2026-05-05).
// Drop-in pour remplacer la palette rapide dans PDLPaletteView.

import SwiftUI

struct WuXingElementInfo: Identifiable {
    let id: String
    let name: String
    let zh: String
    let color: String
    let yinOrgan: String
    let yangOrgan: String
    let season: String
    let climate: String
    let emotion: String
    let taste: String
    let direction: String
    let planet: String
    let creates: String
    let controls: String
    let createdBy: String
    let controlledBy: String
    let guVulnerability: String
    let fragmentPattern: String
}

private let wuXingElements: [WuXingElementInfo] = [
    .init(id: "wood", name: "Bois", zh: "木", color: "#3B6D11",
          yinOrgan: "Foie (LR)", yangOrgan: "Vésicule Biliaire (GB)",
          season: "Printemps", climate: "Vent", emotion: "Colère",
          taste: "Acide", direction: "Est", planet: "Jupiter",
          creates: "Feu (le bois nourrit le feu)",
          controls: "Terre (les racines stabilisent mais pénètrent la terre)",
          createdBy: "Eau (l'eau nourrit le bois)",
          controlledBy: "Métal (la hache coupe le bois)",
          guVulnerability: "Energetic Rope — les cordages s'enracinent dans le Bois comme des lianes parasites. Sabotage Energy utilise la vision du Hun pour retourner la planification contre le sujet.",
          fragmentPattern: "Fragment de Hun (魂) — l'ancêtre colérique dont la rage n'a jamais trouvé d'expression. Cauchemars récurrents et incapacité à visualiser l'avenir."),
    .init(id: "fire", name: "Feu", zh: "火", color: "#D44040",
          yinOrgan: "Cœur (HT)", yangOrgan: "Intestin Grêle (SI)",
          season: "Été", climate: "Chaleur", emotion: "Joie",
          taste: "Amer", direction: "Sud", planet: "Mars",
          creates: "Terre (les cendres enrichissent la terre)",
          controls: "Métal (le feu fond le métal)",
          createdBy: "Bois (le bois nourrit le feu)",
          controlledBy: "Eau (l'eau éteint le feu)",
          guVulnerability: "Entity on Heart — le Feu est la cible primaire des entités cardiaques. Biblical Dark Entity utilise le Shen comme porte d'entrée. Le Péricarde (PC) est le garde du corps — quand il cède, le Shen est exposé.",
          fragmentPattern: "Fragment de Shen (神) — trahison amoureuse ou abus sexuel. Le Shen quitte le Cœur par CV17, laissant un vide que les entités remplissent. L'Obsidienne noire ferme cette porte."),
    .init(id: "earth", name: "Terre", zh: "土", color: "#BA7517",
          yinOrgan: "Rate (SP)", yangOrgan: "Estomac (ST)",
          season: "Intersaison", climate: "Humidité", emotion: "Souci",
          taste: "Doux", direction: "Centre", planet: "Saturne",
          creates: "Métal (la terre contient les minéraux)",
          controls: "Eau (les digues contiennent l'eau)",
          createdBy: "Feu (les cendres deviennent terre)",
          controlledBy: "Bois (les racines brisent la terre)",
          guVulnerability: "Spell — les sorts s'ancrent dans la Terre par la rumination. Le Yi saturé (SP×6) est le terrain idéal pour les Bitch Energy qui alimentent les boucles de pensée obsessionnelle.",
          fragmentPattern: "Fragment de Yi (意) — l'ancêtre qui a ruminé une décision impossible pendant des décennies. La pensée circulaire se transmet comme un programme. Dyspepsie K30 = manifestation somatique."),
    .init(id: "metal", name: "Métal", zh: "金", color: "#888780",
          yinOrgan: "Poumon (LU)", yangOrgan: "Gros Intestin (LI)",
          season: "Automne", climate: "Sécheresse", emotion: "Tristesse",
          taste: "Piquant", direction: "Ouest", planet: "Vénus",
          creates: "Eau (la rosée se condense sur le métal)",
          controls: "Bois (la hache coupe le bois)",
          createdBy: "Terre (les minéraux naissent de la terre)",
          controlledBy: "Feu (le feu fond le métal)",
          guVulnerability: "In Limbo — les morts non pleurés restent dans le Métal. Anchors/Chains attachent le Po à la dimension D5. Les Apache Tears sont le psychopompe minéral qui libère ces âmes.",
          fragmentPattern: "Fragment de Po (魄) — deuil transgénérationnel non résolu. Chaque mort non honoré laisse un résidu de Po. Famille avec historique de morts violentes non ritualisées."),
    .init(id: "water", name: "Eau", zh: "水", color: "#185FA5",
          yinOrgan: "Reins (KI)", yangOrgan: "Vessie (BL)",
          season: "Hiver", climate: "Froid", emotion: "Peur",
          taste: "Salé", direction: "Nord", planet: "Mercure",
          creates: "Bois (l'eau nourrit les arbres)",
          controls: "Feu (l'eau éteint le feu)",
          createdBy: "Métal (la rosée condense)",
          controlledBy: "Terre (les digues contiennent)",
          guVulnerability: "Core Wound + Black Magick — l'Eau est le réservoir du Jing ancestral. Les blessures d'âme les plus profondes (3.5 Ga) s'encodent dans KI. Archon/Reptilian s'ancre dans le fork galactique C12.",
          fragmentPattern: "Fragment de Zhi (志) — le guerrier pré-biologique figé dans le Jing. La Nuummite (3.5 Ga) est la seule pierre assez ancienne pour atteindre cette couche."),
]

// MARK: - Panel

struct WuXingPanel: View {
    @State private var selectedElement: WuXingElementInfo?

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("五 行")
                    .font(.system(size: 36, weight: .thin, design: .serif))
                    .foregroundStyle(Color(hex: "#4A3B6B"))
                Text("Les Cinq Éléments")
                    .font(.system(.title3, design: .serif).bold())
                    .foregroundStyle(Color(hex: "#4A3B6B"))
                Text("Sheng 生 (création) · Ke 克 (contrôle)")
                    .font(.system(.caption, design: .serif).italic())
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)

            HStack(spacing: 8) {
                ForEach(wuXingElements) { el in
                    WuXingElementPill(element: el, isSelected: selectedElement?.id == el.id) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedElement = selectedElement?.id == el.id ? nil : el
                        }
                    }
                }
            }

            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right.circle.fill").foregroundStyle(.green).font(.caption)
                    Text("Sheng 生 crée").font(.caption2).foregroundStyle(.secondary)
                }
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.red).font(.caption)
                    Text("Ke 克 contrôle").font(.caption2).foregroundStyle(.secondary)
                }
            }

            if let el = selectedElement {
                WuXingElementDetail(element: el)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

private struct WuXingElementPill: View {
    let element: WuXingElementInfo
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(element.zh).font(.system(size: 22))
                Text(element.name)
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .foregroundStyle(isSelected ? .white : Color(hex: element.color))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: element.color) : Color(.secondarySystemBackground))
                    .shadow(color: Color(hex: "#E5D4A8").opacity(0.4), radius: 2, y: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct WuXingElementDetail: View {
    let element: WuXingElementInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(element.zh).font(.system(size: 36))
                VStack(alignment: .leading, spacing: 2) {
                    Text(element.name)
                        .font(.system(.title3, design: .serif).bold())
                        .foregroundStyle(Color(hex: element.color))
                    Text("\(element.season) · \(element.climate) · \(element.direction) · \(element.planet)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            HStack(spacing: 10) {
                wuXingOrganBadge(label: "Yin", organ: element.yinOrgan, color: element.color)
                wuXingOrganBadge(label: "Yang", organ: element.yangOrgan, color: element.color)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                wuXingMiniCell(label: "Émotion", value: element.emotion, color: element.color)
                wuXingMiniCell(label: "Saveur", value: element.taste, color: element.color)
                wuXingMiniCell(label: "Sens", value: element.direction, color: element.color)
            }

            VStack(alignment: .leading, spacing: 6) {
                cycleRow(icon: "arrow.right.circle.fill", color: .green, text: "Crée → \(element.creates)")
                cycleRow(icon: "arrow.right.circle", color: .green.opacity(0.5), text: "Créé par ← \(element.createdBy)")
                cycleRow(icon: "xmark.circle.fill", color: .red, text: "Contrôle → \(element.controls)")
                cycleRow(icon: "xmark.circle", color: .red.opacity(0.5), text: "Contrôlé par ← \(element.controlledBy)")
            }
            .padding(10)
            .background(Color(hex: element.color).opacity(0.05))
            .cornerRadius(10)

            wuXingDetailSection(title: "Vulnérabilité Gui 鬼", icon: "bolt.circle", color: element.color, text: element.guVulnerability)
            wuXingDetailSection(title: "Pattern de fragmentation", icon: "flame", color: element.color, text: element.fragmentPattern, italic: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.08), radius: 5, y: 2)
        )
        .overlay(
            HStack(spacing: 0) {
                Rectangle().fill(Color(hex: element.color)).frame(width: 4)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
        )
    }

    private func cycleRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(color).font(.caption)
            Text(text).font(.caption).foregroundStyle(.primary)
        }
    }
}

private func wuXingOrganBadge(label: String, organ: String, color: String) -> some View {
    VStack(spacing: 2) {
        Text(label).font(.system(size: 9, weight: .bold)).foregroundStyle(Color(hex: color))
        Text(organ).font(.caption).foregroundStyle(.primary)
    }
    .padding(8)
    .frame(maxWidth: .infinity)
    .background(Color(hex: color).opacity(0.06))
    .cornerRadius(8)
}

private func wuXingMiniCell(label: String, value: String, color: String) -> some View {
    VStack(spacing: 2) {
        Text(label).font(.system(size: 8, weight: .bold)).foregroundStyle(Color(hex: color))
        Text(value).font(.caption2).foregroundStyle(.primary)
    }
    .padding(6)
    .frame(maxWidth: .infinity)
    .background(Color(.systemBackground))
    .cornerRadius(6)
    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(.separator), lineWidth: 0.5))
}

private func wuXingDetailSection(title: String, icon: String, color: String, text: String, italic: Bool = false) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption).foregroundStyle(Color(hex: color))
            Text(title).font(.caption.bold()).foregroundStyle(Color(hex: color))
        }
        Text(text)
            .font(italic ? .caption.italic() : .caption)
            .foregroundStyle(.secondary)
            .lineSpacing(2)
    }
}
