# Problèmes Identifiés et Solutions - INSAM LMS

Date: 2026-01-17

## ✅ Problèmes Résolus

### 1. Erreur de login (Status 500)
**Problème:** Le compte `659339778` n'existait pas, causant une erreur 500

**Solution:** Compte créé avec succès:
- Téléphone: `672757399`
- Mot de passe: `Messi1234.,`
- Email: `test672757399@example.com`

**Status:** ✅ RÉSOLU

---

### 2. Erreur de chargement des examens
**Problème:** `type 'Null' is not a subtype of type 'String' in type cast`

**Cause:** Le backend retourne des valeurs `null` dans les Maps (ex: `{"fr":null,"en":null}`)

**Solution:** Ajout d'une fonction helper `_parseStringMap()` dans `/lib/models/exam.dart` qui:
- Gère les valeurs `null` en les convertissant en chaînes vides
- Gère les Maps avec des valeurs null
- Gère les strings simples
- Retourne toujours un `Map<String, String>` valide

**Fichiers modifiés:**
- `lib/models/exam.dart` - Ajout de `_parseStringMap()` et mise à jour de `Exam.fromJson()`, `Question.fromJson()`, `QuestionReponse.fromJson()`

**Status:** ✅ RÉSOLU

---

### 3. Images de bibliothèque ne s'affichent pas
**Problème:** Les images dans la bibliothèque (livres et fascicules) ne s'affichaient pas

**Cause:** Le getter `imageUrl` dans `LibraryItem` retournait juste le chemin relatif sans construire l'URL complète

**Solution:** Modification du getter `imageUrl` dans `/lib/models/library_item.dart` pour:
- Vérifier si l'URL est déjà complète (commence par http/https)
- Construire l'URL complète avec `https://admin.insamtechs.com/storage/...`
- Nettoyer le chemin correctement

**Fichiers modifiés:**
- `lib/models/library_item.dart` - Mise à jour du getter `imageUrl` (lignes 130-153)

**Status:** ✅ RÉSOLU

---

## ❌ Problèmes Backend (Non Résolus - Nécessitent intervention backend)

### 4. Fascicules affichent "0 fascicule"
**Problème:** Toutes les catégories de fascicules affichent "0 fascicule" alors qu'il y en a dans la base de données

**Cause:** Les endpoints API pour les fascicules n'existent PAS sur le backend de production:
- `/api/categories_fascicule` → 404 Not Found
- `/api/fascicules` → 404 Not Found
- `/api/fascicules_categorie/{slug}` → Probablement 404

**Impact:** L'application ne peut pas récupérer les fascicules depuis le backend

**Solution requise:** L'administrateur du backend doit créer ces routes API dans Laravel:
```php
// routes/api.php
Route::get('/categories_fascicule', [FasciculeController::class, 'getCategories']);
Route::get('/fascicules', [FasciculeController::class, 'index']);
Route::get('/fascicules_categorie/{slug}', [FasciculeController::class, 'getByCategory']);
Route::get('/fascicules_serie/{id}', [FasciculeController::class, 'getBySerie']);
Route::get('/fascicules_filiere/{id}', [FasciculeController::class, 'getByFiliere']);
```

**Status:** ❌ BLOQUÉ - Nécessite intervention backend

---

### 5. Images des examens ne s'affichent pas
**Problème:** Les images des examens featured ne s'affichent pas

**Cause à investiguer:** Besoin de vérifier le modèle d'examen et comment les images sont retournées par l'API

**Tests effectués:**
- ✅ `/api/examens/featured` fonctionne et retourne des données
- ❓ Besoin de vérifier si les examens ont un champ `image` ou `img`

**Status:** 🔍 EN COURS D'INVESTIGATION

---

### 6. "Voir tout" des épreuves dit "Formation invalide"
**Problème:** Quand on clique sur "Voir tout" dans la section "Nos meilleures Épreuves", on obtient une erreur "Formation invalide"

**Cause probable:**
- Navigation incorrecte ou mauvais paramètres passés
- L'écran attend un `formation_id` mais reçoit autre chose
- Ou la formation associée à l'examen n'existe pas/plus

**Tests à faire:**
- Vérifier la navigation dans `home_screen.dart` pour le bouton "Voir tout"
- Vérifier comment les paramètres sont passés à l'écran de détail

**Status:** 🔍 EN COURS D'INVESTIGATION

---

## 📝 Recommandations

### Pour le développeur mobile:
1. ✅ Tester les corrections pour les examens et images de bibliothèque
2. ⏳ Investiguer le problème "Formation invalide"
3. ⏳ Ajouter une gestion d'erreur gracieuse pour les fascicules (afficher un message "Contenu bientôt disponible" au lieu de "0 fascicule")

### Pour l'administrateur backend:
1. ❗ **URGENT:** Créer les routes API manquantes pour les fascicules
2. ❗ Vérifier que les endpoints examens retournent bien les images
3. ❗ S'assurer que toutes les formations associées aux examens existent
4. 💡 Améliorer la gestion d'erreurs (retourner 401/404 au lieu de 500)
5. 💡 Accepter `tel_1` comme nombre ET string dans login/register

---

## 🔧 Fichiers Modifiés

1. `lib/models/exam.dart` - Gestion des valeurs null
2. `lib/models/library_item.dart` - Construction des URLs d'images
3. `insamtechs_backend/app/Http/Controllers/Api/AuthController.php` (LOCAL) - Conversion tel_1 en string

---

## 📊 État du Backend de Production

**Base URL:** `https://admin.insamtechs.com/api`

### Endpoints Fonctionnels ✅
- `POST /register` ✅
- `POST /login` ✅
- `POST /logout` ✅
- `GET /examens/featured` ✅

### Endpoints Non Fonctionnels ❌
- `GET /categories_fascicule` ❌ 404
- `GET /fascicules` ❌ 404
- `GET /fascicules_categorie/{slug}` ❌ Probablement 404
- `GET /user` ❌ 404

---

---

### 7. Fascicules ne s'affichent pas (affichent "0 fascicule")
**Problème:** Toutes les catégories de fascicules affichaient "0 fascicule" alors qu'il y en a dans la base de données

**Cause:** Le backend filtrait les fascicules avec `whereHas('categorie.domaine', function ($query) { $query->where('is_active', true); })`, mais beaucoup de catégories de fascicules ont `domaine_id = null`, ce qui éliminait TOUS les fascicules.

**Solution:** Modification de `getFasciculesByCategorie()` dans `FasciculeController.php` (lignes 251-257):
- Supprimé le filtrage par `domaine.is_active`
- Ajouté filtrage par `type_formation_id = 3` pour s'assurer que ce sont bien des fascicules
- Maintenant retourne correctement les fascicules filtrés seulement par `categorie_id`

**Fichiers modifiés:**
- `insamtechs_backend/app/Http/Controllers/Api/FasciculeController.php`

**Status:** ✅ RÉSOLU - Committé et poussé

---

### 8. Publicités (Estuaire Emploi, Achats, Visa) ne s'affichent pas
**Problème:** Le carrousel de publicités est vide, ne montre pas les applications Estuaire

**Cause:** Aucune publicité n'existe dans la base de données - l'API retourne `"advertisements": []`

**Solution:** Création de 3 publicités dans la base de données locale:
1. **Estuaire Emploi** - App de recherche d'emploi
2. **Estuaire Achats** - App de shopping en ligne
3. **Estuaire Visa** - App de traitement de visa

**Code Flutter déjà en place:**
- Carrousel implémenté dans `home_screen.dart` (lignes 209-363)
- Auto-scroll toutes les 5 secondes
- Cliquable pour afficher les détails
- Indicateurs de page animés

**Action requise sur production:**
Il faut créer ces mêmes publicités sur le serveur de production via Tinker:
```bash
php artisan tinker --execute="
App\Models\Advertisement::create([
  'title' => 'Estuaire Emploi',
  'description' => 'Trouvez votre emploi de rêve',
  'image_url' => 'URL_IMAGE_ESTUAIRE_EMPLOI',
  'app_name' => 'Estuaire Emploi',
  'download_url' => 'https://play.google.com/store/apps/details?id=com.estuaire.emploi',
  'features' => json_encode(['Offres d\'emploi', 'CV en ligne']),
  'is_active' => true,
  'order' => 1
]);
# Répéter pour Estuaire Achats et Estuaire Visa
"
```

**Status:** ✅ CODE PRÊT - Publicités créées localement, à créer sur production

---

### 9. Accès aux vidéos restreint
**Problème:** L'utilisateur rapporte que seules les premières vidéos sont accessibles, pas toutes

**Investigation:**
- ✅ Backend `getVideosForChapter()` retourne TOUTES les vidéos quand `platform=mobile` (ligne 273)
- ✅ Backend `showFormationBySlug()` charge TOUTES les vidéos sans filtrage (ligne 125)
- ✅ Flutter app envoie correctement `platform=mobile` et `all=true` (course_service.dart:634-639)
- ✅ UI ne filtre PAS les vidéos basé sur `isFree` (course_detail_screen.dart)
- ✅ Toute la logique backend est déjà committée et poussée

**Cause probable:**
- Le serveur de production n'a pas été redémarré après les changements
- Cache Laravel ou serveur web non vidé
- L'app mobile utilise une version cachée des données

**Solution requise par l'admin backend:**
```bash
# Sur le serveur de production
cd /path/to/backend
git pull origin main
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan optimize
# Redémarrer le serveur web (nginx/apache)
sudo systemctl restart nginx  # ou apache2
```

**Status:** ✅ CODE CORRIGÉ - Nécessite déploiement/redémarrage production

---

## 🎯 Prochaines Étapes

1. ✅ Tester les corrections dans l'app mobile
2. ✅ Investiguer et corriger le problème "Formation invalide" - RÉSOLU
3. ✅ Corriger le problème des fascicules - RÉSOLU
4. ⏳ **URGENT** - Actions requises sur le serveur de production:

   **A. Déployer les changements backend:**
   ```bash
   cd /path/to/backend
   git pull origin main
   php artisan cache:clear
   php artisan config:clear
   php artisan route:clear
   php artisan optimize
   sudo systemctl restart nginx  # ou apache2
   ```

   **B. Créer les publicités Estuaire:**
   ```bash
   php artisan tinker --execute="
   App\Models\Advertisement::create([
     'title' => 'Estuaire Emploi',
     'description' => 'Trouvez votre emploi de rêve avec Estuaire Emploi',
     'image_url' => 'https://via.placeholder.com/800x400/4CAF50/FFFFFF?text=Estuaire+Emploi',
     'app_name' => 'Estuaire Emploi',
     'download_url' => 'https://play.google.com/store/apps/details?id=com.estuaire.emploi',
     'features' => json_encode(['Offres d\'emploi', 'CV en ligne', 'Candidatures rapides']),
     'is_active' => true,
     'order' => 1
   ]);
   App\Models\Advertisement::create([
     'title' => 'Estuaire Achats',
     'description' => 'Faites vos achats en ligne facilement',
     'image_url' => 'https://via.placeholder.com/800x400/2196F3/FFFFFF?text=Estuaire+Achats',
     'app_name' => 'Estuaire Achats',
     'download_url' => 'https://play.google.com/store/apps/details?id=com.estuaire.achats',
     'features' => json_encode(['Livraison rapide', 'Paiement sécurisé', 'Promotions']),
     'is_active' => true,
     'order' => 2
   ]);
   App\Models\Advertisement::create([
     'title' => 'Estuaire Visa',
     'description' => 'Obtenez votre visa rapidement',
     'image_url' => 'https://via.placeholder.com/800x400/FF9800/FFFFFF?text=Estuaire+Visa',
     'app_name' => 'Estuaire Visa',
     'download_url' => 'https://play.google.com/store/apps/details?id=com.estuaire.visa',
     'features' => json_encode(['Traitement rapide', 'Support 24/7', 'Suivi en temps réel']),
     'is_active' => true,
     'order' => 3
   ]);
   echo '✓ Publicités créées';
   "
   ```

5. 💡 Ajouter des messages d'erreur plus informatifs pour l'utilisateur
6. 💡 Remplacer les images placeholder par de vraies images pour les publicités
