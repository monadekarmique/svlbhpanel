# CLAUDE.md — SVLBH Panel

## Build & Deploy
- Xcode project : `SVLBH Panel.xcodeproj`, scheme `SVLBH Panel`
- Bundle ID : M100-LS100-DM85.SVLBH-Panel
- Archive : `xcodebuild ... -destination 'generic/platform=iOS' DEVELOPMENT_TEAM=NKJ86L447D CODE_SIGN_STYLE=Automatic clean archive`
- Export : `xcodebuild -exportArchive ... -exportOptionsPlist ExportOptions.plist`
- Simulateur : iPad Pro 13-inch (M5)
- Ne pas committer le bump de version sauf demande explicite.

## Architecture
- **Services/** : MakeSyncService, SegmentUpdateService, PresenceService, SubscriptionService
- **Models/** : SessionData (SessionState, ShamaneProfile, PractitionerTier, ShamaneProgramme, PierreState)
- **Views/** : SwiftUI, MainTabView point d'entrée des onglets
- Tier calculé depuis le code numérique (1-99 lead, 100-299 formation, 300-30000 certifiée, 30001+ superviseur)

## Make Webhooks
- Data store : svlbh-v2 (id: 155674)
- Segment update : `jl32rcoregoc34xeekj3cldngj9rkhh9`
- Push v2 : `1xhfk4o1l5pu4h23m0x26zql6oe8c3ns`

## TODO / Attente backend
- **User skills persistence** : ne pas bricoler de contournement local. On attend qu'Anthropic persiste nativement les user skills entre sessions côté backend. Branche de suivi : `claude/user-skills-persistence-ta0Js`.
- **Statut** : Managed Agents dispo en bêta publique depuis le 8/04/2026 (header `managed-agents-2026-04-01`). Résout la persistance : un agent défini une fois — modèle, system prompt, tools, MCP servers, Skills — référencé par ID dans toutes les sessions. Tarif : coûts API standards + 0,08 $/session-heure active.

## Roadmap Managed Agents (SVLBH)
Objectif : passer des scénarios Make fragiles à 3 agents managés persistants.

### 1. `hdom-session-agent`
- **Input** : payload iOS (SLA, SLSA, heure de réveil, Rose des Vents).
- **Skills chargés auto** : `sommeil-troubles-nuit`, `endometriose-ferritine`, `hdom-decoder`.
- **Output** : décodage hDOM structuré + protocole + chromothérapie.
- **Remplace** : décodage manuel en session → préparation auto en ~30 s avant consultation.

### 2. `passeport-ratio-agent`
- **Input** : données patient pour Ratio 4D.
- **Action** : calcule le ratio, interroge `svlbh-ref-21s` (data store #157532), identifie le cluster (Hypersensibilité / Sensibilité active / Compression), rédige le passeport complet.
- **Remplace** : scénario Make `SVLBH Passeport Ratio 4D` #8999937 (81 % d'erreurs).

### 3. `whatsapp-vlbh-agent`
- **Input** : message WhatsApp entrant.
- **Action** : consulte profil dans `svlbh-v2` (#155674), applique le skill selon segment (`lead` / `patient_actif` / `praticien`), répond avec la profondeur adaptée. Mémoire de session persistante.
- **Remplace** : Router WhatsApp Make #8944541 (108 erreurs).
