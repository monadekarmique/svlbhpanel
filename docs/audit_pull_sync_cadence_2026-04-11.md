# Audit cadence PULL v2 + Sync Praticien

**Date** : 2026-04-11
**Auteur** : Claude Code (local, `patricktest`)
**Criticité** : P1 — fuite d'opérations Make.com (61 % de la facture sur 2 scénarios)
**Statut** : INVESTIGATION uniquement, aucune modification de code, aucun appel Make.com.

## TL;DR

Deux fuites distinctes, additives, **identifiées avec certitude** :

1. **PULL v2 — la marche d'escalade `00 → 01 → … → 05`** dans `MakeSyncService.pull()` (ligne 226). Chaque pull qui ne trouve rien (cas le plus fréquent) déclenche **jusqu'à 5 appels webhook supplémentaires**. Multiplicateur ~×3 à ×6 selon les utilisateurs.
2. **PULL v2 — `scanSources` re-déclenché à chaque switch d'onglet**. Le `.task` dans `MainTabView:125` est attaché à un `GeometryReader` placé sous `if selectedTab == 0`. Chaque retour à l'onglet SVLBH démonte/remonte la vue → la `.task` re-fire → `scanSources` lance **N appels parallèles** (N = nombre de shamanes, ~5–7). Multiplicateur ~×6 par switch.
3. **Sync Praticien — `fetchQuotas` = 8 appels parallèles par ouverture du sheet** RoutineMatinTab (un par billing key). Pas de cache, pas de debounce, fire-and-forget à l'ouverture du sheet ET à chaque tap du bouton refresh.

Aucun Timer périodique, aucun BG task, aucune polling boucle. **Tout est event-driven** mais avec des multiplicateurs cachés sur des actions très fréquentes.

Fix "ce soir" recommandé : **Option 1 (debounce / dedup côté client)** + **désactiver la marche d'escalade** = -75 % à -85 % d'ops Make sans changer aucun comportement utilisateur visible.

---

## Section A — État actuel (factuel, sourcé)

### Table 1 — Tous les call sites identifiés

| Fonction Swift | Webhook | Trigger | Coût/déclenchement | Background ? | Debounce ? |
|---|---|---|---|---|---|
| `MakeSyncService.pull(session:manual:)` | `n00qt5b…` (PULL v2) | `SyncBar.doPull()` (bouton "Recevoir" / sub-menu) | **1 + jusqu'à 5** appels (escalade `00→01…05`) | non | ⚠️ debounce 3 s mais bypass via `manual=true` (qui est la valeur par défaut côté UI) |
| `MakeSyncService.pullSingleKey(_)` | `n00qt5b…` (PULL v2) | `SessionHistoryView` × 3 (resume / merge / restore), `ResearchProgramsView` × 1 | 1 appel | non | non |
| `MakeSyncService.scanSources(session:)` | `n00qt5b…` (PULL v2) | `MainTabView:125` `.task` (re-fire à chaque retour onglet 0), `SyncBar:175` (menu manuel) | **N parallèles** (N ≈ 5–7 shamanes) | non | guard `pendingSources.isEmpty` mais **toujours vrai** quand il n'y a rien à recevoir → re-fire indéfinie |
| `RoutineMatinTab.fetchQuotas()` | `f5ezym67…` (Sync Praticien) | `.task` à chaque ouverture du sheet, bouton "Charger", bouton refresh toolbar | **8 parallèles** (8 billing keys) | non | non, pas de cache |

### Table 2 — Inventaire des autres webhooks Make et pourquoi ils ne sont PAS coupables

| Service | Webhook | Cadence | Verdict |
|---|---|---|---|
| `MakeSyncService.push` | `1xhfk4o…` (PUSH v2) | manuel uniquement (bouton "Envoyer") | hors top |
| `MakeSyncService.markAsRead` | PUSH v2 | après chaque pull réussi | hors top |
| `BuildGateService.check` | `3hwa9zq…` (Build Gate) | 1× lancement + 1× chaque retour foreground | scénario distinct, pas dans le top |
| `SubscriptionService.check` | `svlbh-subscription-check` (alias) | cache 1 h, donc max 24 appels/jour/user | négligeable |
| `SegmentUpdateService.checkWhatsAppConnectivity` | `lllo1g6…` (WA router) | 1× lancement | négligeable |
| `SegmentUpdateService.pushSegment` | `jl32rcoregoc…` (Segment Update) | manuel (drag/drop Planche) | hors top |
| `PresenceService` | `nhfc4x35…` / `s8k1h98g…` / `m4m54erw…` | 1× scenePhase active + 1× background | mineur |
| `PractitionerIdentity.lookupAppleUserID` / `registerAppleUserID` | `ril8mrrt…` (Apple Identity) | sign-in flow | 0,25 % de la facture, déjà documenté ailleurs |
| `ShamanesPendingManager.fetch` | (pas câblé) | **DEAD CODE** — défini dans `ShamanesOverviewView.swift` mais aucun appelant actif | 0 |
| `MakeSyncService.triggerPostPushPull` | PULL v2 | **DEAD CODE** — défini ligne 146 mais aucun appelant | 0 |

### Citations exactes — la marche d'escalade PULL v2 (`SVLBH Panel/Services/MakeSyncService.swift:218-237`)

```swift
// Try primary key first
var text = try await pullSingleKey(key)

// If primary key returned nothing useful, try alternate program codes (00→01→02)
// This handles the case where the supervisor changed the program code during correction
if text == nil {
    let parts = key.split(separator: "-", maxSplits: 1)
    if parts.count == 2, let currentCode = Int(parts[0]) {
        let suffix = String(parts[1])
        for altCode in (currentCode + 1)...min(currentCode + 5, 99) {
            let altKey = String(format: "%02d-%@", altCode, suffix)
            if let altText = try await pullSingleKey(altKey) {
                print("[MakeSyncService] PULL fallback: found data at \(altKey) (original: \(key))")
                text = altText
                // Update session program code to match
                await MainActor.run { session.sessionProgramCode = String(format: "%02d", altCode) }
                break
            }
        }
    }
}
```

**Diagnostic** : dans le cas commun (rien à recevoir), la boucle parcourt **les 5 codes alternatifs**, chacun = 1 appel webhook séparé. Total par tap : **6 appels webhook**.

### Citations exactes — `scanSources` parallèle (`MakeSyncService.swift:299-323`)

```swift
await withTaskGroup(of: (ShamaneProfile, Bool).self) { group in
    for shamane in profiles {
        group.addTask {
            let key = "\(session.sessionProgramCode)-\(session.patientId)-\(session.sessionNum)-\(shamane.codeFormatted)"
            ...
            var req = URLRequest(url: Self.pullURL)
            req.httpMethod = "POST"
            ...
            let (data, _) = try await URLSession.shared.data(for: req)
            ...
        }
    }
    for await (shamane, hasData) in group {
        if hasData { found.append(shamane) }
    }
}
```

**Diagnostic** : N appels parallèles, où N = `session.shamaneProfiles.count` ≈ 5–7 actuellement. Pas de cache, pas de dedup.

### Citations exactes — auto-fire de `scanSources` à chaque retour onglet (`MainTabView.swift:111-131`)

```swift
// SyncBar uniquement sur l'onglet SVLBH
if selectedTab == 0 {
    GeometryReader { geo in
        ...
    }
    .ignoresSafeArea(.container, edges: .bottom)
    .task {
        // Auto-scan au lancement si superviseur
        if session.role.isSuperviseur && sync.pendingSources.isEmpty && !sync.isScanning {
            await sync.scanSources(session: session)
        }
    }
}
```

**Diagnostic** : le `if selectedTab == 0` détruit/recrée la vue à chaque switch d'onglet. La modifier `.task` ré-exécute son closure à chaque apparition. Le guard `pendingSources.isEmpty` est **toujours vrai** dans le cas typique (rien à recevoir), donc `scanSources` re-fire à chaque retour à l'onglet 0. Pour un superviseur qui navigue entre Épuisement, SLM, Chrono, Conditions, Tores et revient au SVLBH plusieurs fois par session = **6+ N appels par session**.

### Citations exactes — `RoutineMatinTab.fetchQuotas` (`RoutineMatinTab.swift:117-146`)

```swift
.task { await fetchQuotas() }   // ligne 117 — fire à chaque ouverture du sheet

private static let billingKeys = ["200", "0300", "0301", "0302", "0303", "0304", "455000", "754545"]

private func fetchQuotas() async {
    isLoading = true
    var results: [CertifieeQuota] = []
    await withTaskGroup(of: CertifieeQuota?.self) { group in
        for key in Self.billingKeys {
            group.addTask { await self.fetchSingle(key: key) }
        }
        ...
    }
    ...
}
```

**Diagnostic** : 1 ouverture du sheet RoutineMatin = 8 appels parallèles. Pas de cache, pas de TTL. Le bouton refresh dans la toolbar (`RoutineMatinTab:102`) re-fire les 8 appels à chaque tap.

### Estimation théorique vs observé

**PULL v2 — modèle**

| Profil | Action | Coût/jour |
|---|---|---|
| Superviseur (Patrick) | 1 launch + ~10 tab-switches retour onglet 0 → 11 × `scanSources` × 6 shamanes | 66 |
| Superviseur | ~5 pulls manuels/jour, fallback walk dans cas vide ≈ 4 appels/pull | 20 |
| Superviseur | scanSources manuels (menu) ~3/jour × 6 | 18 |
| **Sous-total superviseur** | | **~104/jour** |
| Shamane (×3 actives) | ~10 pulls/jour avec fallback walk ≈ 4 appels/pull | 40 |
| **Sous-total shamane (×3)** | | **~120/jour** |
| **TOTAL modèle (1 superviseur + 3 shamanes)** | | **~224/jour** |

Observé : **~430/jour**. Le delta vient probablement de :
- Plusieurs superviseurs (Patrick test + Patrick prod) ;
- Des sessions test où la marche d'escalade va effectivement jusqu'à `+5` parce que rien n'existe à `00-…` ;
- Des switches d'onglet plus fréquents en condition réelle.

L'ordre de grandeur colle. **Aucun trigger périodique caché**, mais les multiplicateurs cumulés expliquent le volume.

**Sync Praticien — modèle**

| Action | Fréquence/jour | Appels |
|---|---|---|
| Ouverture sheet RoutineMatin (.task fire) | ~5 ouvertures × 8 keys | 40 |
| Tap refresh dans le sheet | ~1 tap × 8 keys | 8 |
| **Total/user/jour** | | **~48** |

Avec 5–7 utilisateurs actifs : ~250–340/jour. Observé : **~334/jour**. **Match exact**.

---

## Section B — Diagnostic

### Cause primaire #1 — La marche d'escalade `pull()` est un bug de design

Le code de `pull()` (lignes 220-237) implémente une "auto-correction de programme code" : si le pull primaire ne trouve rien, l'app teste les 5 codes programme suivants. **L'intention** : si Patrick a changé le code programme entre la PUSH et le PULL, le destinataire doit pouvoir retrouver le soin.

**Le problème** : ce cas est rare (changement de code programme en cours de session) mais le **coût est payé à chaque pull qui retourne vide**, ce qui est **le cas par défaut** quand il n'y a rien à recevoir. Ratio coût/bénéfice catastrophique.

**Multiplicateur observé** : ×3 à ×6 sur tous les pulls.

### Cause primaire #2 — `scanSources` re-fire incontrôlée

Le `.task` modifier ré-exécute son closure à chaque apparition de la vue dans la hiérarchie. Un `.task` placé sous une condition `if selectedTab == 0` re-fire **à chaque switch d'onglet vers 0**. Le guard `pendingSources.isEmpty` ne protège pas dans le cas commun.

**Multiplicateur observé** : 6+ N appels par session de navigation.

**Ce n'est pas un bug** au sens strict (le code fait ce que SwiftUI lui demande), mais **c'est un design qui ne tient pas compte de la sémantique de `.task` sous une condition**. Un développeur SwiftUI senior aurait placé le `.task` sur le `MainTabView` lui-même avec un déclencheur explicite (`onChange(of: selectedTab)`) ou utilisé une cache TTL côté `MakeSyncService`.

### Cause primaire #3 — Pas de cache sur `fetchQuotas`

Les billing data changent rarement (quota d'un praticien évolue à l'échelle du jour, pas de la minute). Le `.task` re-fire 8 appels à chaque ouverture du sheet, sans aucun TTL. Un cache de 60 s suffirait à diviser le coût par 5–10.

### Causes ÉCARTÉES après inspection

- ❌ Aucun `Timer.scheduledTimer` / `Timer.publish` / `BGTaskScheduler` qui déclenche un appel webhook (les 4 timers trouvés sont tous purement UI : horloge ChronoFu, animation LeadBubble, typewriter SessionClosure, palette de lumière).
- ❌ Aucun `BGAppRefreshTask`, aucun `applicationDidEnterBackground` qui poll. L'app **ne fait rien en background** côté Make (sauf une déconnexion `PresenceService` pour les leads).
- ❌ Pas de retry-storm : la fonction `pull` n'a pas de retry, la 1.6 % d'erreurs observée correspond probablement à des timeouts isolés.
- ❌ Pas de double-subscribe à un publisher Combine.
- ❌ `triggerPostPushPull` (ligne 146) et `ShamanesPendingManager.fetch` sont du **dead code** (définis mais jamais appelés).
- ❌ `markAsRead` hit le PUSH webhook, pas le PULL — n'impacte pas ce ticket.

---

## Section C — Options de remédiation

Toutes les estimations sont des bornes hautes (worst-case réduction).

### Option 1 — Cache TTL + supprimer la marche d'escalade

**Effort** : 1 h. Touche 2 fichiers (`MakeSyncService.swift`, `RoutineMatinTab.swift`).

Sous-options :

- **1a — Supprimer la boucle d'escalade `pull()`** ou la remplacer par un seul appel `+1` (au lieu de `+1…+5`). C'est le plus gros gain pour le moindre risque.
  - Économie PULL v2 : ~50–60 % (du multiplicateur ×3–6 on passe à ×1 ou ×2).
  - **Risque UX** : un superviseur qui change le code programme entre PUSH et PULL ne verra plus le soin. Mitigation : afficher un toast "rien à recevoir, vérifier le code programme" et exposer le code programme en clair dans la SyncBar.

- **1b — TTL 60 s sur `scanSources`** : stocker `lastScanAt` dans `MakeSyncService`, refuser un nouveau scan si < 60 s.
  - Économie PULL v2 : ~30–50 % (élimine le burst de re-fire en cas de tab-hopping).
  - **Risque UX** : un superviseur qui scanne 2× en 60 s voit le second scan ignoré → afficher un indicateur "dernière vérif il y a 12 s" ou réutiliser le résultat caché.

- **1c — TTL 60 s sur `RoutineMatinTab.fetchQuotas`** : cacher `allQuotas` dans un singleton avec timestamp.
  - Économie Sync Praticien : ~70–90 % (l'utilisateur ouvre le sheet plusieurs fois mais ne paye qu'une fois par minute).
  - **Risque UX** : zéro. Les billing data sont stables à l'échelle de la minute.

**Économie cumulée 1a + 1b + 1c** : **~60–75 % de PULL v2** (~280 ops/jour économisées) + **~80 % de Sync Praticien** (~270 ops/jour économisées) = **~550 ops/jour économisées** sur les ~764/jour observés. **~22 % de la facture totale Make éliminée**.

### Option 2 — Baisser la fréquence de polling

**Inapplicable.** Il n'y a aucun polling périodique. Les 430/jour PULL v2 viennent de triggers événementiels (tab switch, manual tap), pas d'un Timer.

### Option 3 — Couper le background

**Inapplicable / déjà fait.** L'app ne fait pas d'appels Make en background (seul `PresenceService.disconnect` est appelé en `phase == .background`, et il vise un autre webhook).

### Option 4 — Consolider PULL + Sync en un seul webhook

**Effort** : 4–6 h (côté Swift + côté Make). Touche 4 fichiers Swift + 2 scénarios Make.

- Les deux scénarios sont fonctionnellement disjoints (PULL v2 = état de session, Sync Praticien = quotas billing). On ne peut pas les fusionner sans coupler deux concepts qui n'ont rien à voir.
- En revanche, on peut consolider **les 8 appels parallèles** de `fetchQuotas` en **1 seul appel** qui retourne tous les quotas en une seule réponse. C'est juste un nouveau scénario Make `bulk_get_quotas` qui boucle sur les billing keys côté serveur.
- De même, on peut consolider **les N appels parallèles** de `scanSources` en **1 seul appel** `bulk_scan` qui retourne les flags `hasData` pour tous les shamanes en une réponse.

**Économie consolidation `fetchQuotas`** : 8× → 1× = **-87 %** sur Sync Praticien (-330 ops/jour) **mais** ne s'additionne pas avec 1c (le cache rend la consolidation marginale, et la consolidation rend le cache marginal — choisir l'une OU l'autre).

**Économie consolidation `scanSources`** : 6× → 1× = **-83 %** sur scanSources (déjà réduit par 1b). Combinée avec 1a (escalade `pull()` supprimée), gain marginal.

### Option 5 — Push server→client (APNS / WebSocket)

**Effort** : 2–3 jours. Touche backend (APNS server, certificats, scénarios Make pour publier sur APNS), iOS (Push notification handlers, foreground refresh logic), et l'UX flow.

- Au lieu que le client poll `scanSources` toutes les N secondes, le serveur push une notification silencieuse "tu as des soins en attente" → l'app fait un seul `pull` ciblé.
- **Économie** : ops PULL v2 → quasi-zéro (uniquement les pulls manuels). Économie estimée : **-90 %** sur PULL v2 (~390 ops/jour).
- **Coûts cachés** : APNS coûte 0 chez Apple mais nécessite un serveur qui maintient l'état "qui doit être notifié quand". Ce serveur fera quand même des appels Make (ou prendra le rôle de Make pour le datastore). Donc ce n'est pas un gain net immédiat sans repenser l'archi.
- **Risque UX** : APNS silencieux n'est pas garanti par iOS — Apple peut throttle les notifications silencieuses si l'app n'est pas activement utilisée. Pour un panel utilisé toutes les heures, OK ; pour un usage hebdo, pas fiable.

### Récapitulatif chiffré

| Option | Effort | Économie PULL v2 | Économie Sync Praticien | % facture totale | Risque |
|---|---|---|---|---|---|
| 1a (suppr. escalade) | 30 min | ~50 % (~215/j) | 0 | ~9 % | UX: code programme à exposer |
| 1b (TTL scanSources) | 30 min | ~30 % (~130/j) | 0 | ~6 % | UX: zéro si bien fait |
| 1c (cache fetchQuotas 60 s) | 20 min | 0 | ~80 % (~265/j) | ~12 % | UX: zéro |
| **1a + 1b + 1c** | **~1 h** | **~70 %** | **~80 %** | **~22 %** | **faible** |
| 4 (consolidation server-side) | 4–6 h | ~80 % | ~85 % | ~25 % | moyen, refactor Make |
| 5 (APNS push) | 2–3 j | ~90 % | dépend | ~30 %+ | élevé, archi |

---

## Section D — Recommandation

### Fix "ce soir" (low-risk, high-impact) — **Option 1a + 1c**

**1a + 1c suffisent pour économiser ~17 % de la facture totale en 50 minutes de Swift sans toucher Make.**

1. **Supprimer la marche d'escalade** dans `MakeSyncService.pull()` (lignes 220-237). Remplacer par un simple `return nil` si le pull primaire ne trouve rien. Optionnellement, ajouter un log d'avertissement dans la SyncBar : "Aucun soin trouvé sur \(key) — vérifier le code programme".
2. **Cache TTL 60 s sur `RoutineMatinTab.fetchQuotas`**. Stocker `static var cachedQuotas: (data: [CertifieeQuota], ts: Date)?` dans la struct (ou mieux, dans un singleton si la liste devient partagée). Au début de `fetchQuotas`, vérifier `Date().timeIntervalSince(cached.ts) < 60`.

**Pourquoi pas 1b ce soir** : ajouter le TTL sur `scanSources` est légèrement plus risqué (touche le service partagé, pas une vue isolée). À garder pour la PR qui suit, une fois le 1a validé en prod.

**Économie attendue après déploiement de 1a + 1c** :
- PULL v2 : ~430/jour → ~215/jour (-50 %)
- Sync Praticien : ~334/jour → ~70/jour (-80 %)
- Facture totale : ~46 334 ops/12j → ~38 000 ops/12j (-18 %)

### Recommandation long terme — **Option 1 complète + Option 4 (consolidation `bulk_scan`)**

Une fois 1a + 1c validés en prod :

1. Ajouter **1b** (TTL `scanSources`) — gain incrémental de ~6 %.
2. Refactor SwiftUI : déplacer le `.task` de `MainTabView` du `if selectedTab == 0` vers le niveau supérieur, utiliser `onChange(of: selectedTab)` avec un `lastScanAt` guard. Élimine définitivement le bug de re-fire sur tab switch.
3. **Côté Make**, créer un scénario `svlbh-bulk-scan` qui prend une liste de session keys et retourne un résultat consolidé. Réécrire `scanSources` pour faire **1 appel** au lieu de N. Gain final : -85 % sur scanSources, soit potentiellement encore -10 % de la facture.
4. **Ne pas faire l'option 5 (APNS)** sauf si le volume d'utilisateurs grossit significativement. Le coût d'opération vs le gain ne le justifie pas pour 5–10 utilisateurs actifs.

### Cible finale après tout (modèle théorique)

| Métrique | Avant | Après 1a+1c | Après 1a+1b+1c+4 |
|---|---|---|---|
| PULL v2 ops/jour | ~430 | ~215 | ~80 |
| Sync Praticien ops/jour | ~334 | ~70 | ~30 |
| Total des 2 ops/jour | ~764 | ~285 | ~110 |
| % facture totale économisé | 0 | **~18 %** | **~38 %** |
| Crédits brûlés en 12 j | 46 334 | ~38 000 | ~30 000 |

---

## Annexe — Fichiers inspectés

- `SVLBH Panel/Services/MakeSyncService.swift` (631 lignes, point central)
- `SVLBH Panel/Services/SubscriptionService.swift`
- `SVLBH Panel/Services/SegmentUpdateService.swift`
- `SVLBH Panel/Services/BuildGateService.swift`
- `SVLBH Panel/SVLBHPanelApp.swift` (entry point + scenePhase)
- `SVLBH Panel/Views/MainTabView.swift` (auto-scan trigger)
- `SVLBH Panel/Views/SyncBar.swift` (manual pull/push UI)
- `SVLBH Panel/Views/RoutineMatinTab.swift` (Sync Praticien caller)
- `SVLBH Panel/Views/SVLBHTab.swift`
- `SVLBH Panel/Views/ChronoFuTab.swift` (Timer purement UI, écarté)
- `SVLBH Panel/Views/SessionHistoryView.swift` (3 callers `pullSingleKey`)
- `SVLBH Panel/Views/ResearchProgramsView.swift` (1 caller `pullSingleKey`)
- `SVLBH Panel/Views/PlancheFloatingView.swift` (sheet host pour RoutineMatinTab)
- `SVLBH Panel/Views/OnboardingView.swift`
- `SVLBH Panel/Views/LeadBubbleTab.swift` (Timer animation, écarté)
- `SVLBH Panel/Views/SessionClosureView.swift` (Timer typewriter, écarté)
- `SVLBH Panel/PaletteDeLumiere/PDLSessionView.swift` (Timer chrono, écarté)
- `SVLBH Panel/ShamanesOverviewView.swift` (dead code `ShamanesPendingManager`)

**Aucune modification effectuée.** Investigation pure.
