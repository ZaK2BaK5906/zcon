# ESX Taxi Job

Job de taxi pour ESX avec missions PNJ et système de facturation.

## Fonctionnalités

- **Menu F6** pour accéder aux fonctions du job
- **20 missions PNJ** avec prix entre 700-1000$
- **Système de facturation** pour les citoyens
- **Menu boss** (retrait/dépôt argent société, recrutement)
- **3 grades** : Chauffeur, Gérant, Boss

## Installation

1. Importer le fichier `taxi.sql` dans votre base de données
2. Placer le script dans votre dossier resources
3. Ajouter `ensure ztaxi` dans votre server.cfg

## Dépendances

- es_extended
- ox_lib
- ox_target
- oxmysql

## Configuration

Modifiez le fichier `config.lua` pour ajuster :
- Zone du menu boss
- Missions PNJ (pickup, dropoff, prix)
- Prix de la société

## Utilisation

### Pour les employés
- Appuyez sur **F6** pour ouvrir le menu
- Sélectionnez une mission PNJ
- Récupérez le client au point de pickup (blip jaune)
- Déposez-le à destination (blip vert)
- Recevez le paiement dans la société

### Facturation
- Ouvrez le menu F6
- Sélectionnez "Facturer un citoyen"
- Entrez l'ID du joueur et le montant
- Le joueur reçoit une facture qu'il peut accepter ou refuser

### Pour les boss
- Rendez-vous à la zone boss menu (blip)
- Retirez/déposez de l'argent de la société
- Recrutez des employés
