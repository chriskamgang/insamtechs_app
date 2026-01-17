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

## 🎯 Prochaines Étapes

1. Tester les corrections dans l'app mobile
2. Investiguer et corriger le problème "Formation invalide"
3. Contacter l'admin backend pour créer les routes fascicules
4. Ajouter des messages d'erreur plus informatifs pour l'utilisateur
