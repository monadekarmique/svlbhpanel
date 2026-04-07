// SVLBHPanel — Models/ChronoFuData.swift
// Chrono 六腑 — Données des 6 Fu (Zi Wu Liu Zhu 子午流注)

import Foundation
import SwiftUI

// MARK: - Point d'acupression

struct AcuPoint: Identifiable {
    let id = UUID()
    let code: String
    let name: String
    let action: String
    var isStimulated: Bool = false
}

// MARK: - Organe Fu

struct FuOrgan: Identifiable {
    let id: String          // code méridien : GB, LI, ST, SI, BL, TE
    let name: String
    let zh: String          // caractère chinois
    let pinyin: String
    let startHour: Int      // heure de début (0-23)
    let label: String       // ex: "23h – 1h"
    let element: String
    let color: String       // hex couleur principale
    let bg: String          // hex couleur fond
    let tx: String          // hex couleur texte
    let chromoName: String  // nom chromo VLBH
    var points: [AcuPoint]

    var swiftColor: Color { Color(hex: color) }
    var swiftBg: Color { Color(hex: bg) }
    var swiftTx: Color { Color(hex: tx) }

    var endHour: Int {
        startHour == 23 ? 1 : startHour + 2
    }

    /// L'organe est-il actif à l'heure donnée ?
    func isActive(at hour: Int) -> Bool {
        if startHour == 23 { return hour >= 23 || hour < 1 }
        return hour >= startHour && hour < startHour + 2
    }
}

// MARK: - Données statiques

enum ChronoFuData {

    static func allOrgans() -> [FuOrgan] {
        [
            FuOrgan(id: "GB", name: "Vésicule biliaire", zh: "膽", pinyin: "Dǎn",
                    startHour: 23, label: "23h – 1h", element: "Bois",
                    color: "#4A7C3F", bg: "#EAF3DE", tx: "#27500A", chromoName: "Vert forêt",
                    points: [
                        AcuPoint(code: "GB34", name: "Yanglingquan", action: "Tonifie la vésicule biliaire, fluidifie la bile"),
                        AcuPoint(code: "GB41", name: "Foot-Linqi", action: "Point maître Dai Mai, régulation latérale"),
                        AcuPoint(code: "GB21", name: "Jianjing", action: "Libère la tension, descend le Qi digestif")
                    ]),
            FuOrgan(id: "LI", name: "Gros intestin", zh: "大腸", pinyin: "Dà Cháng",
                    startHour: 5, label: "5h – 7h", element: "Métal",
                    color: "#888780", bg: "#F1EFE8", tx: "#444441", chromoName: "Blanc ivoire",
                    points: [
                        AcuPoint(code: "LI4", name: "Hegu", action: "Point souverain – évacuation et transit intestinal"),
                        AcuPoint(code: "LI11", name: "Quchi", action: "Régule la chaleur, favorise l'excrétion"),
                        AcuPoint(code: "LI6", name: "Pianli", action: "Luo – mobilise les liquides corporels")
                    ]),
            FuOrgan(id: "ST", name: "Estomac", zh: "胃", pinyin: "Wèi",
                    startHour: 7, label: "7h – 9h", element: "Terre",
                    color: "#BA7517", bg: "#FAEEDA", tx: "#633806", chromoName: "Jaune ambré",
                    points: [
                        AcuPoint(code: "ST36", name: "Zusanli", action: "Grand tonique digestif, transformation des aliments"),
                        AcuPoint(code: "ST25", name: "Tianshu", action: "Point mu de LI – régulation intestinale directe"),
                        AcuPoint(code: "ST40", name: "Fenglong", action: "Dissout l'humidité et les glaires digestives")
                    ]),
            FuOrgan(id: "SI", name: "Intestin grêle", zh: "小腸", pinyin: "Xiǎo Cháng",
                    startHour: 13, label: "13h – 15h", element: "Feu",
                    color: "#D85A30", bg: "#FAECE7", tx: "#4A1B0C", chromoName: "Rouge vermeil",
                    points: [
                        AcuPoint(code: "SI4", name: "Wangu", action: "Source – sépare le pur de l'impur, assimilation"),
                        AcuPoint(code: "SI6", name: "Yanglao", action: "Xi – douleurs et stagnation de l'intestin grêle"),
                        AcuPoint(code: "SI8", name: "Xiaohai", action: "Mer – calme les fermentations intestinales")
                    ]),
            FuOrgan(id: "BL", name: "Vessie", zh: "膀胱", pinyin: "Páng Guāng",
                    startHour: 15, label: "15h – 17h", element: "Eau",
                    color: "#185FA5", bg: "#E6F1FB", tx: "#042C53", chromoName: "Bleu saphir",
                    points: [
                        AcuPoint(code: "BL25", name: "Dachangshu", action: "Shu dos de LI – transit et évacuation"),
                        AcuPoint(code: "BL27", name: "Xiaochangshu", action: "Shu dos de SI – séparation des liquides"),
                        AcuPoint(code: "BL40", name: "Weizhong", action: "Point commande – dépuration et drainage")
                    ]),
            FuOrgan(id: "TE", name: "Triple réchauffeur", zh: "三焦", pinyin: "Sān Jiāo",
                    startHour: 21, label: "21h – 23h", element: "Feu min.",
                    color: "#993C1D", bg: "#FAECE7", tx: "#4A1B0C", chromoName: "Orange feu",
                    points: [
                        AcuPoint(code: "TE6", name: "Zhigou", action: "Point clé constipation – descend le foyer moyen"),
                        AcuPoint(code: "TE10", name: "Tianjing", action: "Mer – harmonise les 3 foyers (sup/moy/inf)"),
                        AcuPoint(code: "TE4", name: "Yangchi", action: "Source – circule l'énergie originelle Yuan Qi")
                    ])
        ]
    }

    /// Retourne le code de l'organe actif à l'heure donnée, ou nil si fenêtre inactive
    static func activeOrganCode(at hour: Int) -> String? {
        allOrgans().first(where: { $0.isActive(at: hour) })?.id
    }

    /// Prochaine fenêtre après l'heure donnée
    static func nextWindow(after hour: Int) -> FuOrgan {
        let order: [(code: String, start: Int)] = [
            ("LI", 5), ("ST", 7), ("SI", 13), ("BL", 15), ("TE", 21), ("GB", 23)
        ]
        let organs = allOrgans()
        for entry in order {
            if hour < entry.start {
                return organs.first(where: { $0.id == entry.code })!
            }
        }
        return organs.first(where: { $0.id == "LI" })! // wraparound
    }
}
