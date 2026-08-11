# Vault — Vision Produit

## Concept
Application iOS de gestion visuelle des bons de réduction, coupons d'achat et cartes cadeaux.
Chaque bon est affiché comme une carte colorée (style carte bancaire), organisée par catégorie, avec des rappels automatiques avant expiration.

---

## Cible utilisateurs
Grand public — toute personne qui reçoit des bons de réduction et qui les oublie ou les perd.

---

## Fonctionnalités principales

### Ajout d'un bon (3 méthodes)
1. **Saisie manuelle** — formulaire : marque, valeur/montant, code promo, date d'expiration, catégorie, couleur de carte
2. **Scan QR / code-barres** — via la caméra de l'iPhone
3. **iOS Share Extension** — l'utilisateur appuie sur "Partager" dans une autre app (McDonald's, Uber Eats, etc.) et sauvegarde directement dans Vault

### Affichage
- Cartes visuelles colorées avec : nom de la marque, valeur du bon, code, date d'expiration
- Vue liste et vue grille
- Filtrage par catégorie (chips horizontaux en haut)

### Catégories
Mode, Restau & Food, Cartes cadeaux, Loisirs, Voyage, Beauté & Santé, Maison, Tech & Jeux, Autres

### Rappels d'expiration
- Notifications push automatiques : 7 jours, 3 jours, 1 jour avant expiration
- Bandeau d'alerte en haut de l'écran accueil pour les bons urgents
- Section dédiée "Expire bientôt"

### Apple Wallet (optionnel, phase 2)
- Export des cartes cadeaux vers l'app Cartes d'Apple via PassKit

---

## Modèle de données (SwiftData)

```swift
// Coupon
- id: UUID
- brand: String              // Nom de la marque
- value: String              // Ex: "−20%" ou "CHF 25"
- code: String               // Code promo ou numéro de carte
- category: Category         // Enum des catégories
- expirationDate: Date?      // Nil = pas d'expiration
- notes: String?             // Notes optionnelles
- cardColor: String          // Hex color pour la carte visuelle
- createdAt: Date
- isUsed: Bool               // Marqué comme utilisé
- source: CouponSource       // manual / scan / shareExtension
```

---

## Monétisation — Freemium

### Gratuit
- Maximum 10 bons sauvegardés
- Toutes les catégories disponibles
- Rappels d'expiration basiques (1 seul rappel à J-1)
- Publicité (bannière Google AdMob discrète en bas)

### Premium — 1.99€/mois ou 14.99€/an
- Bons illimités
- Zéro publicité
- Sync iCloud multi-appareils (CloudKit)
- Export Apple Wallet (PassKit)
- Rappels avancés : 7j / 3j / 1j avant expiration
- **Fonctionnalité exclusive : Stats d'économies** — tableau de bord montrant le montant total économisé (par mois, par année, par catégorie)

---

## Stack technique

| Composant | Technologie |
|-----------|-------------|
| UI | SwiftUI |
| Persistance locale | SwiftData |
| Sync cloud | CloudKit (iCloud) |
| Abonnements | StoreKit 2 |
| Notifications | UNUserNotification |
| Scan | AVFoundation (caméra) |
| Partage | iOS Share Extension |
| Apple Wallet | PassKit |
| Publicités | Google AdMob |

---

## Architecture du projet

```
Vault/
├── App/
│   └── VaultApp.swift
├── Models/
│   ├── Coupon.swift          // SwiftData model
│   ├── Category.swift        // Enum catégories
│   └── UserSubscription.swift
├── Views/
│   ├── Home/
│   │   ├── HomeView.swift
│   │   ├── CouponCardView.swift
│   │   └── AlertBannerView.swift
│   ├── AddCoupon/
│   │   ├── AddCouponView.swift
│   │   └── ScannerView.swift
│   ├── Detail/
│   │   └── CouponDetailView.swift
│   ├── Categories/
│   │   └── CategoriesView.swift
│   ├── Alerts/
│   │   └── AlertsView.swift
│   ├── Settings/
│   │   └── SettingsView.swift
│   └── Premium/
│       └── PaywallView.swift
├── ViewModels/
│   ├── HomeViewModel.swift
│   └── AddCouponViewModel.swift
├── Services/
│   ├── NotificationService.swift
│   ├── SubscriptionService.swift
│   └── SyncService.swift
├── Extensions/
└── Resources/
    └── Assets.xcassets
```

---

## Roadmap

| Phase | Durée | Contenu |
|-------|-------|---------|
| 1 — Fondations | Mois 1–2 | Architecture, navigation, modèle de données, écrans vides |
| 2 — Core | Mois 3–4 | Ajout manuel, scan QR, affichage cartes, catégories, recherche |
| 3 — Engagement | Mois 5–6 | Notifications, Share Extension, publicités AdMob |
| 4 — Monétisation | Mois 7–8 | StoreKit 2, iCloud sync, Apple Wallet, stats économies |
| 5 — Lancement | Mois 9 | Polissage, screenshots App Store, soumission review Apple |

---

## Règles de développement
- Langue de l'UI : Français (priorité) avec localisation Anglais prévue en v2
- iOS minimum : iOS 17 (requis pour SwiftData)
- Design : clean, moderne, minimaliste — inspiration apps fintech (cartes colorées)
- Pas de dépendances externes inutiles — privilégier les frameworks Apple natifs
- Code commenté en français
