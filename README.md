# SVLBHPanel

**Vibrational Light Body Healing — Panel Praticien iOS**

Application iOS SwiftUI pour praticiens VLBH (Vibrational Light Body Healing).  
**Digital Shaman Lab** · [vlbh.energy](https://vlbh.energy) · Avenches 🇨🇭  
[![ORCID](https://img.shields.io/badge/ORCID-0009--0007--9183--8018-A6CE39?style=flat&logo=orcid&logoColor=white)](https://orcid.org/0009-0007-9183-8018)

---

## Ce que fait cette app

- Encode et transmet des séances de soin énergétique (hDOM — holistic Dimensional Operating Model)
- Synchronise les décodages entre praticiens via une architecture PUSH/PULL Make.com
- Gère l'historique des sessions par VIFA (Vibration Intervalle Fréquences Accumulation)
- Supporte les programmes de recherche multi-praticiens

## Architecture clé

```
{prog}-{VIFA}-{sessionNum}-{codePraticien}

ex: 01-345-004-0300
    │   │    │    └─ Cornelia (0300)
    │   │    └─── Session 4
    │   └──────── VIFA 345 (pattern séphirothique)
    └──────────── Programme recherche (01)
```

## Stack technique

- SwiftUI + iOS 16+
- Make.com (PUSH/PULL webhook → datastore)
- TestFlight (distribution interne)
- StoreKit 2 + RevenueCat (abonnements — roadmap v0.7.x)

## Roadmap

| Version | Feature |
|---|---|
| v4.3.0 | Sélecteur sessionNum + programCode manuel |
| v0.5.x | HistoryTab VIFA — vue sessions par pattern |
| v0.6.x | VIFARegistry tier gratuit (emoji + couleur + libellé) |
| v0.7.x | VIFARegistry tier payant (upload image + CloudKit + StoreKit 2) |

## Contribuer

Voir [CONTRIBUTING.md](CONTRIBUTING.md) — notamment pour les **traductions**.

Chaque langue = un fichier `{lang}.lproj/Localizable.strings`.  
Ouvrir une PR avec votre traduction pour rejoindre le réseau de praticiens.

## Licence

Infrastructure technique : MIT  
Méthodologie VLBH/hDOM : propriétaire — Digital Shaman Lab © 2026
