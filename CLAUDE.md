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
