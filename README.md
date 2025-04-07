
# 📱 MySourcing2 - Flutter + Firebase App

## 🧩 Fonctionnalités principales

### 👥 Authentification
- Connexion via Firebase Authentication
- Sécurisation des accès Firestore par utilisateur

### 🧾 Gestion des formulaires
- ✅ Création de formulaire avec titre + champs dynamiques (texte, nombre, image…)
- ✏️ Modification complète (titre + champs)
- 🗑️ Suppression
- 🌀 Duplication
- 📝 Renommage rapide depuis le menu contextuel
- 📥 Ajout d'une entrée via "Ajouter un produit"

### ✍️ Gestion des entrées (réponses)
- 🧾 Saisie de données via formulaire dynamique
- 📂 Upload d’images vers Firebase Storage
- 📋 Affichage des entrées par formulaire
- 🛠️ Modification ou suppression d’une réponse

---

## 🗂️ Arborescence utile

| Dossier / Fichier                      | Rôle |
|---------------------------------------|------|
| `lib/main.dart`                       | Entrée de l’application |
| `lib/forms/form_list_screen.dart`     | Liste des formulaires + actions |
| `lib/forms/create_form_screen.dart`   | Création de formulaire |
| `lib/forms/edit_form_screen.dart`     | Édition complète d’un formulaire |
| `lib/forms/fill_form_screen.dart`     | Remplir un formulaire (ajouter un produit) |
| `lib/forms/entry_list_screen.dart`    | Liste des réponses d’un formulaire |
| `lib/forms/edit_entry_screen.dart`    | Modifier une entrée existante |
| `lib/forms/form_service.dart`         | Toutes les opérations Firestore centralisées |
| `lib/forms/form_model.dart`           | Modèle de champ de formulaire (`FormFieldData`) |

---

## 🔐 Sécurité Firestore (exemple de règles)

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/forms/{formId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      match /entries/{entryId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

---

## ✅ À faire avant de lancer
- Configurer Firebase dans `firebase_options.dart`
- S’assurer que les règles Firestore sont bien déployées
- `flutter pub get`
- `flutter run`

---

## 🤝 Contribuer
Fork, modifie, propose ! On est là pour collaborer 👊

---

© 2025 - Projet Flutter & Firebase - MySourcing2
