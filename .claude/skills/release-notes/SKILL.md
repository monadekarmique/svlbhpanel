---
name: release-notes
description: Rédige des release notes structurées pour une version produit (mobile, web, API). Utiliser quand une version est prête à sortir et qu'il faut documenter les changements pour les utilisateurs finaux, les stakeholders internes ou l'App Store. Déclencheurs — "release notes", "changelog", "notes de version", "quoi de neuf", "what's new".
---

# Release Notes

Tu agis comme **Program Manager** produisant des release notes claires pour différentes audiences.

## Deux audiences, deux formats

### 1. Release notes **utilisateurs finaux**
Ton : marketing-friendly, orienté bénéfice, pas de jargon technique.

**Destination** : App Store, Google Play, site produit, in-app "what's new".

### 2. Release notes **techniques / stakeholders internes**
Ton : factuel, exhaustif, avec références (PR, ticket, risk note).

**Destination** : `CHANGELOG.md`, email stakeholders, documentation interne.

## Format utilisateur final

```markdown
# Version <X.Y.Z> — <date>

## ✨ Nouveautés
- **<Feature>** — <bénéfice utilisateur en une phrase>

## 🚀 Améliorations
- <Amélioration perceptible> 

## 🐛 Corrections
- <Bug fixé côté utilisateur>
```

**Règles** :
- **Maximum 4-5 items par section** — au-delà, personne ne lit
- **Pas de vocabulaire technique** : "on a migré vers GraphQL" → ❌ ; "L'app charge plus vite" → ✅
- **Verbe d'action** au début de chaque bullet
- **Bénéfice avant la feature** quand possible : "Gagnez 30s à chaque consultation avec la nouvelle recherche instantanée"
- Pour l'**App Store** (iOS) : max **4000 caractères**, les premiers 250 sont critiques (visible sans "read more")

## Format technique / CHANGELOG

Suit [Keep a Changelog](https://keepachangelog.com/) + [SemVer](https://semver.org/).

```markdown
## [X.Y.Z] — YYYY-MM-DD

### Added
- <Nouvelle fonctionnalité> (#PR, ISSUE-123)

### Changed
- <Changement de comportement existant>

### Deprecated
- <Fonctionnalité marquée comme obsolète>

### Removed
- <Fonctionnalité supprimée>

### Fixed
- <Bug corrigé>

### Security
- <Fix de sécurité>
```

## SemVer : comment incrémenter ?

Depuis la version `MAJOR.MINOR.PATCH` :

| Changement | Incrément |
|------------|-----------|
| Breaking change (API, comportement) | **MAJOR** |
| Nouvelle fonctionnalité rétrocompatible | **MINOR** |
| Bug fix / amélioration interne | **PATCH** |

## Processus recommandé

1. **Pendant le sprint** : chaque PR ajoute une entrée dans `CHANGELOG.md` sous `## [Unreleased]`
2. **Release prep** :
   - Renommer `[Unreleased]` en `[X.Y.Z] — YYYY-MM-DD`
   - Créer un nouveau `[Unreleased]` vide en haut
   - Tagger le commit : `git tag vX.Y.Z`
3. **Traduction utilisateur** : extraire les entrées de `CHANGELOG.md` et les réécrire pour l'audience finale
4. **Publication** :
   - Push du tag
   - Update App Store Connect / Play Console avec les release notes user-friendly
   - Email stakeholders avec version technique

## Template email stakeholders

```
Objet : [Release] <Produit> vX.Y.Z déployé le <date>

Bonjour,

La version X.Y.Z de <Produit> est maintenant disponible en production.

## Ce qui change pour les utilisateurs
- <bullet 1>
- <bullet 2>

## Ce qui change en interne
- <bullet technique 1>

## Points d'attention
- <migration données, config à changer, feature flag à activer...>

## Rollback
En cas de problème : <procédure>

## Liens
- Changelog : <lien>
- PRs incluses : <lien>

<signature>
```

## App Store (iOS) — contraintes

- **Release notes** : 4000 caractères max
- **Localisation** : traduire pour chaque market
- **No promotional content** : Apple rejette les phrases marketing excessives ("Best app ever!")
- **Highlighting** : les 2 premières lignes sont critiques, visible sans dérouler

## Questions à poser

Si inconnu, demande :
- Numéro de version et type (major/minor/patch)
- Date de release
- Liste des PRs / tickets inclus depuis la dernière version
- Plateformes visées (iOS, Android, web)
- Audience à adresser (utilisateurs finaux ? B2B ? interne ?)
- Y a-t-il un breaking change ou une migration nécessaire ?

## Anti-patterns

- **"Bug fixes and performance improvements"** : trop générique, n'apporte rien
- **Notes techniques aux utilisateurs** : "Refactor du module d'auth" → personne ne comprend
- **Oublier les breaking changes** : toujours les mettre en tête, en gras
- **Ne pas maintenir le CHANGELOG** : il dérive et devient inutilisable
- **Dupliquer l'info** : CHANGELOG + doc interne + email qui se contredisent
