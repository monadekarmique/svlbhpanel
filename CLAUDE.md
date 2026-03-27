# CLAUDE.md — SVLBH Panel

## Règles de travail

- **Une seule instance Claude Code** modifie les fichiers à la fois. Pas d'instances parallèles sur le même repo.
- Ne jamais donner un prompt à coller dans un autre terminal — faire les modifications directement.
- Build + push TestFlight quand Patrick dit "on pousse" ou "OUI".
- Ne pas committer le bump de version (CURRENT_PROJECT_VERSION / MARKETING_VERSION) sauf demande explicite.

## Architecture

- **Services/** : MakeSyncService, SegmentUpdateService, PresenceService, SubscriptionService
- **Models/** : SessionData (SessionState, ShamaneProfile, PractitionerTier, ShamaneProgramme, PierreState)
- **Views/** : SwiftUI, MainTabView comme point d'entrée des onglets

## Build & Deploy

- Xcode project : `SVLBH Panel.xcodeproj`
- Scheme : `SVLBH Panel`
- Team ID : `NKJ86L447D`
- Bundle ID : `M100-LS100-DM85.SVLBH-Panel`
- Archive : `xcodebuild ... -destination 'generic/platform=iOS' DEVELOPMENT_TEAM=NKJ86L447D CODE_SIGN_STYLE=Automatic clean archive`
- Export : `xcodebuild -exportArchive ... -exportOptionsPlist ExportOptions.plist`
- Simulateur iPad : `iPad Pro 13-inch (M5)`

## Conventions

- SLSA peut dépasser 100% (jusqu'à 50 000%) — ne jamais flaguer comme erreur
- Les diagnostics SourceKit (Cannot find type) sont des faux positifs quand les types sont dans d'autres fichiers — vérifier avec un vrai build
- Le tier est calculé depuis le code numérique (1-99 lead, 100-299 formation, 300-30000 certifiée, 30001+ superviseur)

## Make (hook.eu2.make.com)

- Team ID : 630342
- Data store principal : svlbh-v2 (id: 155674)
- Webhook segment update : `jl32rcoregoc34xeekj3cldngj9rkhh9`
- Webhook push v2 : `1xhfk4o1l5pu4h23m0x26zql6oe8c3ns`
