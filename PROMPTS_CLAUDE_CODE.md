# Prompts Claude Code — Vault App
> Utilise ces prompts dans l'ordre, une phase à la fois.
> Commence toujours une nouvelle session par : "Lis VISION.md pour comprendre le projet, puis..."

---

## ✅ PHASE 1 — Fondations (Mois 1–2)

### Prompt 1.1 — Initialisation du projet
```
Lis VISION.md pour comprendre le projet Vault.

Je viens de créer un nouveau projet Xcode appelé "Vault" avec SwiftUI et SwiftData (iOS 17 minimum).

Mets en place l'architecture complète du projet :
1. Crée la structure de dossiers décrite dans VISION.md (Models, Views, ViewModels, Services, Extensions)
2. Crée le modèle SwiftData `Coupon` avec tous les champs décrits dans VISION.md
3. Crée l'enum `Category` avec toutes les catégories (Mode, Restau & Food, Cartes cadeaux, Loisirs, Voyage, Beauté & Santé, Maison, Tech & Jeux, Autres) — chaque catégorie a un nom, une icône SF Symbol et une couleur par défaut
4. Configure `VaultApp.swift` avec le ModelContainer SwiftData
5. Crée une navigation principale avec TabView (5 onglets : Accueil, Catégories, Ajouter, Alertes, Réglages) — les écrans peuvent être vides pour l'instant

Le design doit être moderne et minimaliste, inspiré des apps fintech.
```

---

### Prompt 1.2 — Navigation et écrans vides
```
Lis VISION.md.

Maintenant crée les vues vides pour chaque onglet avec leur structure de base :
1. `HomeView` — avec un header "Vault" en grand (style DM Serif Display si possible, sinon serif système), un sous-titre avec le nombre de bons actifs, et un espace pour les cartes
2. `CategoriesView` — grille de catégories avec icônes et couleurs
3. `AlertsView` — liste vide avec un état "aucune alerte" illustré
4. `SettingsView` — liste de réglages basique (abonnement, notifications, à propos)

Pour chaque vue, ajoute un état "vide" illustré et sympa quand il n'y a pas encore de données.
Utilise les couleurs SF et SF Symbols pour les icônes.
```

---

## ✅ PHASE 2 — Fonctionnalités core (Mois 3–4)

### Prompt 2.1 — Carte visuelle d'un bon
```
Lis VISION.md.

Crée le composant `CouponCardView` qui affiche un bon de réduction comme une carte colorée :
- Format rectangulaire arrondi (style carte bancaire)
- Gradient de couleur basé sur la catégorie du bon
- Affiche : nom de la marque (uppercase, petit), valeur du bon (grande typographie), description courte, code promo (style monospace dans une petite capsule), date d'expiration
- Une ligne en pointillés horizontale sépare les infos principales du code (comme un vrai coupon)
- Badge en haut à droite : "X jours" en rouge si expiration dans moins de 7 jours, sinon la catégorie
- Version compacte (pour la liste) et version étendue (pour le détail)

Crée aussi quelques données de preview Xcode avec 4-5 bons fictifs réalistes pour voir le rendu.
```

---

### Prompt 2.2 — Écran d'accueil complet
```
Lis VISION.md.

Complète `HomeView` avec :
1. Header avec nom de l'app, nombre de bons actifs, avatar/initiales utilisateur
2. Bandeau d'alerte orange/jaune en haut si des bons expirent dans moins de 7 jours (cliquable pour aller sur AlertsView)
3. Chips de filtre horizontal scrollable (Tous, Mode, Restau, Cadeaux, etc.)
4. Liste des bons sous forme de `CouponCardView` filtrés par la catégorie sélectionnée
5. Bouton flottant "+" pour ajouter un bon
6. Barre de recherche (recherche dans le nom de la marque et le code)

La liste doit être triée par : bons expirant bientôt en premier, puis par date d'ajout.
```

---

### Prompt 2.3 — Formulaire d'ajout manuel
```
Lis VISION.md.

Crée `AddCouponView` — une sheet modale pour ajouter un bon manuellement :
1. Champ : Marque/Nom du magasin (avec suggestions automatiques basées sur les bons existants)
2. Champ : Valeur du bon (ex: "-20%", "CHF 25", "Livraison gratuite") 
3. Champ : Code promo (avec bouton copier-coller intégré)
4. Picker : Catégorie (avec icônes)
5. DatePicker : Date d'expiration (optionnelle — toggle "Sans expiration")
6. Champ optionnel : Notes
7. Preview en temps réel de la carte en haut du formulaire qui se met à jour pendant la saisie
8. Bouton "Enregistrer" qui sauvegarde dans SwiftData

Le formulaire doit être fluide, avec validation basique (marque et valeur obligatoires).
```

---

### Prompt 2.4 — Scanner QR et code-barres
```
Lis VISION.md.

Crée `ScannerView` — un écran de scan intégré dans le flux d'ajout :
1. Vue caméra plein écran avec AVFoundation
2. Cadre de scan animé au centre
3. Supporte QR codes ET codes-barres (EAN-13, EAN-8, Code128, Code39)
4. Quand un code est détecté : vibration légère (haptic feedback), le code est automatiquement rempli dans le formulaire d'ajout
5. Bouton pour basculer entre "Scanner" et "Saisie manuelle" en bas

Demande la permission caméra avec un message explicatif sympa si ce n'est pas encore accordé.
```

---

### Prompt 2.5 — Écran de détail d'un bon
```
Lis VISION.md.

Crée `CouponDetailView` — l'écran qui s'ouvre quand on tape sur un bon :
1. Grande carte visuelle en haut (version étendue de CouponCardView)
2. Code promo affiché en grand avec bouton "Copier" bien visible
3. QR code généré automatiquement à partir du code (pour scanner en caisse)
4. Infos complètes : catégorie, date d'ajout, date d'expiration avec compte à rebours
5. Bouton "Marquer comme utilisé" (archive le bon, ne le supprime pas)
6. Bouton "Modifier" et "Supprimer"
7. Partager le bon (Share Sheet natif iOS)

Design immersif avec la couleur de la carte en fond (effet glassmorphism ou gradient discret).
```

---

## ✅ PHASE 3 — Engagement (Mois 5–6)

### Prompt 3.1 — Système de notifications
```
Lis VISION.md.

Crée `NotificationService.swift` :
1. Demande la permission de notifications au premier lancement (avec explication claire)
2. Planifie automatiquement des notifications pour chaque bon avec date d'expiration :
   - Version gratuite : 1 notification à J-1
   - Version premium : 3 notifications à J-7, J-3, J-1
3. Quand un bon est supprimé ou marqué utilisé, annule ses notifications
4. Quand un bon est ajouté ou modifié, replanifie ses notifications
5. Notifications avec titre "⏰ [Marque] expire demain !" et message descriptif
6. Mise à jour automatique après chaque modification dans SwiftData

Intègre le service dans le cycle de vie de l'app et dans AddCouponView/CouponDetailView.
```

---

### Prompt 3.2 — Share Extension
```
Lis VISION.md.

Crée une iOS Share Extension pour Vault :
1. Ajoute une nouvelle target "VaultShareExtension" dans le projet Xcode
2. L'extension apparaît dans le share sheet iOS sous le nom "Sauver dans Vault"
3. Elle accepte : URLs, texte, et images
4. Interface simple : montre un aperçu de ce qui va être sauvegardé, avec un champ pour le nom de la marque et la catégorie
5. Sauvegarde dans le même container SwiftData partagé avec l'app principale (App Group)
6. Confirmation visuelle avec animation avant de fermer

Configure l'App Group dans les entitlements des deux targets (app principale + extension).
```

---

### Prompt 3.3 — Publicités AdMob (version gratuite)
```
Lis VISION.md.

Intègre Google AdMob pour la version gratuite :
1. Ajoute le SDK Google Mobile Ads via Swift Package Manager (package: https://github.com/googleads/swift-package-manager-google-mobile-ads)
2. Configure dans AppDelegate/App init
3. Crée un composant `AdBannerView` (bannière en bas de HomeView)
4. La bannière apparaît SEULEMENT si l'utilisateur n'est pas abonné Premium
5. Laisse des placeholders pour les Ad Unit IDs (je les remplirai depuis la console AdMob)
6. Teste avec les IDs de test AdMob fournis par Google en mode debug

Important : la bannière ne doit pas gêner la navigation — ajoute un padding au-dessus de la TabBar.
```

---

## ✅ PHASE 4 — Monétisation (Mois 7–8)

### Prompt 4.1 — Abonnements StoreKit 2
```
Lis VISION.md.

Crée le système d'abonnement complet avec StoreKit 2 :
1. `SubscriptionService.swift` — classe ObservableObject qui gère :
   - Chargement des produits depuis App Store Connect (IDs : "com.vault.monthly" et "com.vault.annual")
   - État de l'abonnement actuel (gratuit / premium)
   - Achat d'un abonnement
   - Restauration des achats
   - Vérification automatique au lancement
2. `PaywallView.swift` — écran de souscription :
   - Titre accrocheur et liste des avantages premium avec icônes
   - 2 options : mensuel (1.99€) et annuel (14.99€, badge "Économise 37%")
   - L'option annuelle mise en avant visuellement
   - Bouton "Restaurer mes achats"
   - Lien CGU et politique de confidentialité (texte légal requis par Apple)
3. Intègre les gates freemium : blocage à 10 bons, pas de sync, affiche la paywall avec animation

Utilise des IDs de produits fictifs pour l'instant — je les créerai dans App Store Connect.
```

---

### Prompt 4.2 — Sync iCloud (Premium)
```
Lis VISION.md.

Implémente la synchronisation iCloud avec CloudKit pour les utilisateurs Premium :
1. Configure CloudKit dans les entitlements (iCloud capability)
2. SwiftData avec ModelConfiguration pour iCloud sync (disponible iOS 17+)
3. La sync est automatique et transparente quand l'utilisateur est connecté à iCloud ET abonné Premium
4. Si pas Premium : données locales uniquement, pas de sync
5. Gère les conflits de données simplement (last-write-wins)
6. Indicateur discret dans SettingsView montrant l'état de la sync

Documente bien la configuration nécessaire dans Xcode (signing, capabilities) car je devrai l'activer manuellement.
```

---

### Prompt 4.3 — Stats d'économies (fonctionnalité exclusive Premium)
```
Lis VISION.md.

Crée l'écran de statistiques d'économies (fonctionnalité Premium exclusive) :
1. `SavingsStatsView` accessible depuis HomeView (bouton discret) ou Settings
2. Tableau de bord avec :
   - Total économisé ce mois (calculé depuis les bons marqués "utilisés")
   - Total économisé cette année
   - Graphique en barres par mois (12 derniers mois) avec les économies
   - Catégorie où tu économises le plus
   - Nombre de bons utilisés vs expirés sans utilisation
3. Si pas Premium : aperçu flou avec bouton "Débloquer avec Premium"
4. Design sobre et élégant, chiffres mis en valeur

Note : le calcul d'économies parse la valeur textuelle des bons utilisés (ex: "-20%", "CHF 25").
Crée un parser simple qui extrait les montants numériques.
```

---

## ✅ PHASE 5 — Polissage (Mois 9)

### Prompt 5.1 — Polish général UI/UX
```
Lis VISION.md.

Fais un audit complet de l'app et améliore le polish :
1. Ajoute des animations partout où c'est pertinent (transitions, apparition des cartes, feedback boutons)
2. Haptic feedback sur toutes les actions importantes (ajout, suppression, copie de code)
3. États de chargement et erreurs gérés partout
4. Accessibilité : labels VoiceOver sur tous les éléments interactifs
5. Dark mode — vérifie que tout est beau en dark mode
6. Onboarding : 3 écrans simples au premier lancement expliquant les fonctionnalités clés
7. App icon — génère le code pour une icône simple avec le logo "V" stylisé en violet sur fond sombre (je l'exporterai en PNG)
8. Review prompt : demande un avis App Store après que l'utilisateur a utilisé 3 bons (SKStoreReviewController)
```

---

### Prompt 5.2 — Préparation App Store
```
Lis VISION.md.

Aide-moi à préparer la soumission App Store :
1. Crée un fichier `APP_STORE_LISTING.md` avec :
   - Titre de l'app (30 caractères max)
   - Sous-titre (30 caractères max)
   - Description courte (170 caractères)
   - Description complète (4000 caractères max) — en français ET en anglais
   - Mots-clés SEO App Store (100 caractères, séparés par virgules)
   - Notes de version pour la v1.0
2. Liste toutes les permissions nécessaires avec leurs messages d'usage (NSCameraUsageDescription, etc.)
3. Vérifie que l'app respecte les guidelines Apple (App Store Review Guidelines) pour les abonnements
4. Crée le fichier `Privacy Policy` basique (requis pour les apps avec abonnement)

Je devrai créer les screenshots manuellement dans Xcode Simulator.
```

---

## 💡 Prompts bonus (à utiliser à tout moment)

### Si tu es bloqué sur une erreur Xcode
```
J'ai cette erreur dans Xcode :
[COLLE L'ERREUR ICI]

Le contexte : [décris ce que tu essayais de faire]
Lis VISION.md si besoin pour comprendre l'architecture du projet.
```

### Pour ajouter une fonctionnalité non prévue
```
Lis VISION.md.

Je veux ajouter la fonctionnalité suivante à Vault : [décris la fonctionnalité]

Analyse comment l'intégrer dans l'architecture existante sans casser ce qui existe déjà, puis implémente-la.
```

### Pour un review de code
```
Lis VISION.md.

Fais un review du fichier [NOM_DU_FICHIER] :
- Cherche les bugs potentiels
- Suggère des optimisations de performance
- Vérifie que le code respecte l'architecture définie dans VISION.md
- Assure-toi que les bonnes pratiques SwiftUI/SwiftData sont respectées
```
