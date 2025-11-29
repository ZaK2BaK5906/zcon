# ZCon - ESX Concess Job

Système complet de concessionnaire avec grades, gestion de stock, commandes et système de livraison avec flatbed.

## Caractéristiques

### Job & Permissions
- **Job ESX**: `concess` avec 3 grades:
  - Employé (grade 0)
  - Gérant (grade 1)
  - Boss (grade 2)
- Accès au menu selon le grade
- Système de société ESX intégré

### Zones ox_target
- **Bureau/Tablette**: Ouvrir le menu de gestion
- **Garage employé**: Sortir le véhicule de service (flatbed)
- **Zone de livraison**: Déchargement des véhicules

### Menu Tablette (ox_lib)
- **📊 Gestion Stock**: Voir le stock actuel, quantités, prix d'achat/vente
- **🛒 Passer Commande**: Commander des véhicules (1-10 unités)
- **📦 Commandes en cours**: Voir et démarrer les missions de livraison
- **💰 Menu Boss**: Retrait/dépôt d'argent société (grade boss uniquement)

### Système de Livraison
1. Commander des véhicules via le menu
2. Récupérer le flatbed au garage
3. GPS automatique vers point de livraison aléatoire
4. Charger les véhicules sur le flatbed
5. Retourner à la concession
6. Décharger les véhicules
7. Stock mis à jour automatiquement

## Dépendances

- **es_extended** (ESX Framework)
- **ox_lib** (Menus et notifications)
- **ox_target** (Zones d'interaction)
- **oxmysql** (Base de données)
- **esx_addonaccount** (Système de société)

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
1. Se rendre au bureau et utiliser la tablette
2. Consulter le stock disponible
3. Passer des commandes
4. Récupérer les livraisons

### Pour les gérants
- Mêmes fonctionnalités que les employés
- Accès complet aux commandes

### Pour le boss
- Toutes les fonctionnalités
- Accès au menu patron:
  - Voir le solde de la société
  - Retirer de l'argent
  - Déposer de l'argent

## Workflow de livraison

1. **Passer une commande**
   - Ouvrir le menu au bureau
   - Sélectionner "Passer Commande"
   - Choisir une catégorie
   - Choisir un véhicule
   - Sélectionner la quantité (1-10)
   - Confirmer

2. **Démarrer la livraison**
   - Menu > "Commandes en cours"
   - Cliquer sur une commande en attente
   - Le GPS s'active automatiquement

3. **Récupérer le flatbed**
   - Aller au garage
   - Interagir avec la zone garage
   - Le flatbed apparaît

4. **Charger les véhicules**
   - Conduire le flatbed au point de livraison
   - Interagir avec la zone
   - Animation de chargement
   - Les véhicules apparaissent sur le flatbed

5. **Décharger**
   - Retourner à la zone de déchargement
   - Interagir avec la zone
   - Animation de déchargement
   - Stock mis à jour
   - Argent débité de la société

## Support

Pour toute question ou problème:
- Créer une issue sur GitHub
- Vérifier que toutes les dépendances sont installées
- Vérifier les logs serveur pour les erreurs

## Crédits

Développé par ZaK2BaK5906

## License

MIT License
