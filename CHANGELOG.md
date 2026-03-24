# Changelog SVLBHPanel

## v4.2.10 (build 17) — 24 mars 2026
- Fix debounce queue-drain post-update TestFlight (3s minimum entre pulls)
- Guard pullKey invalide dans pull() et scanSources()

## v4.2.9 (build 14) — 24 mars 2026
- Fix PatientRegistry.nextId() : max(current+1, minPatientId=12)
- Guard pullKey malformé dans pull()
- Guard patientId dans scanSources() avant envoi

## v4.2.8 (build 13) — 24 mars 2026
- Guard pullKey vide → BundleValidationError Make.com éliminé
- Guard scanSources : rejette les scans avant patientId valide

## v4.2.7 (build 12) — 24 mars 2026
- Fix PatientRegistry.nextId() v2 : max(current+1, 12) — couvre UserDefaults=1

## v4.2.6 (build 11) — 24 mars 2026
- Fix PatientRegistry.nextId() : démarrage à minPatientId=12 sur appareil vierge
- Nouveau onglet LeadBubbleTab (tag 5) — présentation iPad lead
  - Silhouette corps + 7 chakras
  - Séquence 3 bulles : Pierres → Chakras/Dimensions → WA Button
  - Timer 15s + neutraliser

## v4.2.5 (build 10) — 23 mars 2026
- SVLBH PULL v2 opérationnel
- Architecture PUSH/PULL Make.com datastore svlbh-v2 (ID: 155674)
- Rôles : Patrick (455000), Cornelia (0300), Flavia (0301), Anne (0302)

---

*Format : version (build) — date*
*Chaque build TestFlight correspond à un tag Git*
