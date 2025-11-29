# ZCon - ESX Concess Job

Système complet de concessionnaire avec grades, gestion de stock, commandes et système de livraison avec flatbed. Interface NUI moderne et élégante.

## Caractéristiques

### Job & Permissions
- **Job ESX**: `concess` avec 3 grades:
  - Employé (grade 0)
  - Gérant (grade 1)
  - Boss (grade 2)
- Accès au menu selon le grade
- Système de société ESX intégré avec gestion directe de la base de données

### Interface NUI
- **Interface moderne** avec design élégant et animations fluides
- **Menu principal** avec accès rapide à toutes les fonctionnalités
- **Gestion du stock** avec affichage en temps réel
- **Catalogue de véhicules** organisé par catégories
- **Suivi des commandes** en cours
- **Menu Boss** avec gestion complète de la société
- **Responsive** et optimisé pour les performances

### Zones ox_target
- **Bureau/Tablette**: Ouvrir l'interface de gestion
- **Garage employé**: Sortir le véhicule de service (flatbed)
- **Zone de livraison**: Déchargement des véhicules

### Fonctionnalités Interface
- **📊 Gestion Stock**: Voir le stock actuel, quantités, prix d'achat/vente
- **🛒 Passer Commande**: Commander des véhicules par catégories (1-10 unités)
- **📦 Commandes en cours**: Voir et démarrer les missions de livraison
- **💰 Menu Boss**: Retrait/dépôt d'argent société (grade boss uniquement)
- **Affichage en temps réel** du solde de la société

### Système de Livraison
1. Commander des véhicules via l'interface
2. Récupérer le flatbed au garage
3. GPS automatique vers point de livraison aléatoire (7 localisations)
4. Charger les véhicules sur le flatbed avec animation
5. Retourner à la concession
6. Décharger les véhicules
7. Stock mis à jour automatiquement
8. Argent débité de la société

## Dépendances

- **es_extended** (ESX Framework)
- **ox_target** (Zones d'interaction)
- **oxmysql** (Base de données)

## Installation

1. **Copier le resource**
   ```bash
   cd resources
   git clone [repository] zcon
   ```

2. **Importer la base de données**
   ```bash
   mysql -u root -p your_database < zcon/concess.sql
   ```

   **Important**: Le script SQL inclut:
   - Tables pour le stock et les commandes
   - Job et grades
   - Compte société (`society_concess`)
   - Initialisation du compte société

3. **Ajouter au server.cfg**
   ```
   ensure zcon
   ```

4. **Configurer les zones**
   Éditer `config.lua` et ajuster les coordonnées des zones selon votre serveur:
   - `Config.Zones.Office` - Bureau/Menu
   - `Config.Zones.Garage` - Garage de service
   - `Config.Zones.Unload` - Zone de déchargement

5. **Configurer les points de livraison**
   Modifier `Config.DeliveryLocations` pour ajouter vos propres points de livraison

6. **Donner de l'argent à la société (optionnel)**
   ```sql
   UPDATE addon_account_data SET money = 100000 WHERE account_name = 'society_concess';
   ```

## Configuration

### Modifier les véhicules disponibles
Éditer `Config.Vehicles` dans `config.lua`:
```lua
{
    category = 'Ma Catégorie',
    vehicles = {
        {model = 'adder', name = 'Adder', price = 1000000},
        -- Ajouter plus de véhicules ici
    }
}
```

### Modifier le multiplicateur de prix de vente
```lua
Config.SellPriceMultiplier = 1.2  -- Vendre à 120% du prix d'achat
```

### Modifier le véhicule de service
```lua
Config.ServiceVehicle = {
    model = 'flatbed',
    livery = 0
}
```

### Activer le mode debug
Pour voir les marqueurs des zones:
```lua
Config.Zones.Office.debug = true
Config.Zones.Garage.debug = true
Config.Zones.Unload.debug = true
```

## Utilisation

### Pour les employés
1. Se rendre au bureau et utiliser la tablette (ox_target)
2. L'interface NUI s'ouvre
3. Consulter le stock disponible
4. Passer des commandes
5. Récupérer les livraisons

### Pour les gérants
- Mêmes fonctionnalités que les employés
- Accès complet aux commandes

### Pour le boss
- Toutes les fonctionnalités
- Accès au menu patron:
  - Voir le solde de la société en temps réel
  - Retirer de l'argent
  - Déposer de l'argent

## Workflow de livraison

1. **Passer une commande**
   - Ouvrir l'interface au bureau
   - Cliquer sur "Passer Commande"
   - Sélectionner une catégorie
   - Choisir un véhicule
   - Entrer la quantité (1-10)
   - Confirmer (vérifie les fonds de la société)

2. **Démarrer la livraison**
   - Cliquer sur "Commandes en cours"
   - Cliquer sur "Aller chercher" pour une commande en attente
   - Le GPS s'active automatiquement

3. **Récupérer le flatbed**
   - Aller au garage
   - Interagir avec la zone garage (ox_target)
   - Le flatbed apparaît automatiquement

4. **Charger les véhicules**
   - Conduire le flatbed au point de livraison
   - Interagir avec la zone (ox_target)
   - Animation de chargement (5 secondes)
   - Les véhicules apparaissent sur le flatbed

5. **Décharger**
   - Retourner à la zone de déchargement
   - Interagir avec la zone (ox_target)
   - Animation de déchargement (5 secondes)
   - Stock mis à jour
   - Argent débité de la société

## Interface NUI

L'interface est construite avec:
- **HTML/CSS/JS** moderne
- **Font Awesome** pour les icônes
- **jQuery** pour les interactions
- **Animations fluides** avec transitions CSS
- **Design responsive** adaptatif
- **Thème sombre** élégant avec dégradés

### Personnalisation de l'interface

Pour modifier les couleurs:
- Éditer `nui/style.css`
- Modifier les gradients dans les sections `.tablet-header`, `.menu-icon`, etc.

## Système de société

Le script utilise une gestion directe de la base de données pour le compte société:
- Lecture depuis `addon_account_data`
- Mise à jour directe avec MySQL
- Aucune dépendance à `esx_addonaccount` events
- Plus fiable et performant

## Dépannage

### Le compte société est introuvable
Vérifier que la table `addon_account_data` contient:
```sql
SELECT * FROM addon_account_data WHERE account_name = 'society_concess';
```

Si vide, exécuter:
```sql
INSERT INTO addon_account_data (account_name, money, owner) VALUES ('society_concess', 0, NULL);
```

### L'interface ne s'ouvre pas
1. Vérifier la console F8 pour les erreurs
2. Vérifier que vous avez le job `concess`
3. Vérifier que ox_target est installé
4. Activer le debug des zones pour voir les marqueurs

### Les véhicules ne se chargent pas
1. Vérifier que vous êtes dans un flatbed
2. Vérifier la console pour les erreurs de spawn
3. S'assurer que le modèle de véhicule existe dans le jeu

## Support

Pour toute question ou problème:
- Créer une issue sur GitHub
- Vérifier que toutes les dépendances sont installées
- Vérifier les logs serveur pour les erreurs
- Vérifier que le compte société existe dans la base de données

## Crédits

Développé par ZaK2BaK5906

## License

MIT License

## Changelog

### v2.0.0
- Remplacement de ox_lib par une interface NUI personnalisée
- Amélioration du système de gestion du compte société
- Interface moderne avec animations
- Meilleure gestion des erreurs
- Performance optimisée
- Suppression de la dépendance ox_lib

### v1.0.0
- Version initiale avec ox_lib
