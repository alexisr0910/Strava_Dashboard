# 🏃‍♂️ Strava Data Analytics Pipeline

Ce projet implémente un pipeline ELT (Extract, Load, Transform) complet pour automatiser la récupération de mes données Strava et les transformer en données exploitables.

###  [Consulter le Dashboard Power BI](https://app.powerbi.com/view?r=eyJrIjoiZGI0ZDRmZWUtMjQ5Zi00ZjU1LTllMzQtZjU2ZTYyNDczOTBhIiwidCI6IjI3YTU4YjYzLTg2ODQtNDBmNy1iNzM3LWM5YTUzNGU2NTc0NSJ9)

##  Choix Technologiques & Architecture

## Phase 1 : Récupérer des données (Extract & Load)
* **Source** : API Strava (OAuth2).
* **Outil de transport** : **Airbyte Open Source** déployé sur Docker.

Airbyte est une plateforme d'intégration de données qui aide à répliquer et à consolider facilement des données provenant de différentes sources (bases de données, API, applications SaaS). J'ai choisi cet outil car il est open source et propose un connecteur déjà prêt pour l'API Strava. C'est une solution reconnue qui répondait exactement à mon besoin technique.

####  Installation (Airbyte)
Lors de l'installation, j'ai rencontré des difficultés liées à la puissance de calcul de mon Mac. Pour optimiser l'utilisation de la RAM sur MacOS, j'ai utilisé le mode spécifique de consommation réduite `--low-resource-mode`.

**Commandes de gestion :**
* **Démarrer** : `abctl local install --low-resource-mode --insecure-cookies`
* **Stopper** : `abctl local uninstall`

####  Configuration de la Source (Strava API)
* **Connexion** : Utilisation du protocole **OAuth2** en suivant la documentation officielle d'Airbyte.
* **Historique** : Paramétrage de la date de début au **1er janvier 2015** afin d'importer l'intégralité de mon historique sportif.
* **Sécurité** : Les identifiants sensibles (`Client ID`, `Client Secret`) sont gérés uniquement dans l'interface locale d'Airbyte.

#### Configuration de la Destination (Google BigQuery)
Pour le stockage et l'analyse, j'ai choisi **Google BigQuery** comme Data Warehouse Cloud pour sa capacité à gérer de gros volumes et sa facilité de connexion aux outils de visualisation.

* **Projet GCP (Google Cloud Platform)** : Création du projet `dashboardstrava1`.
* **Sécurité** : Création d'un **compte de service** spécifique pour isoler les accès.
* **Droits d'accès** :
    * `Administrateur BigQuery` : Pour permettre à l'outil d'écrire les données.
    * `Administrateur Storage` : Sert de zone tampon pour fluidifier l'importation des gros volumes.
* **Dataset** : Données stockées dans `strava_raw` (Localisation : EU).

![img.png](images/Airbyte_connexion.png)

##  Paramétrage du flux (Sync Mode)

J'ai configuré deux modes différents dans Airbyte pour optimiser le pipeline :

* **Activités (`Incremental | Append + Deduped`)** :
  Ce mode permet de ne récupérer que les nouvelles activités sportives. Airbyte utilise l'identifiant unique (`id`) pour éviter les doublons. Cela permet un chargement plus rapide et réduit la consommation de ressources.

* **Statistiques (`Full Refresh | Overwrite`)** :
  Pour mes records personnels et totaux globaux, j'ai choisi de remplacer intégralement les données à chaque passage. Ces informations n'ayant pas d'ID unique, ce mode est nécessaire pour garantir des données toujours à jour.

![img_1.png](images/Airbyte_data.png)
---

## Phase 2 : Transformation (Couche ODS)

L'objectif de cette étape est de transformer les données brutes (`strava_raw`) pour créer un dataset ODS (`strava_ods`) propre et structuré.

### Objectifs de la couche ODS
* **Nettoyage** : Passage d'un format JSON à une structure SQL exploitable.
* **Extraction des données** : Sélection des seules données jugées pertinentes (distance, vitesse, dénivelé, kudos, etc.).
* **Données sensibles** : Suppression définitive des coordonnées GPS et des identifiants personnels dès cette étape pour ne pas les stocker dans le reste du projet.

### Points techniques de la mise en place
* **Vérification du typage** : Utilisation d'une table de test (`test_format`) pour confirmer que BigQuery et Airbyte interprètent correctement les types numériques (`NUMERIC`, `INTEGER`).
* **Traitement du JSON** : Extraction des données imbriquées pour la table `athlete_stats`. J'ai utilisé la fonction **`CAST`** pour transformer les données textuelles issues du JSON en formats numériques, ce qui permet de réaliser des calculs par la suite.

> **Pour consulter le détail du mapping, les justifications de filtrage et les échantillons de données, voir : [Documentation détaillée ODS](./docs/ODS/README.md)**
---

---

## Phase 3 : Modélisation (Couche DWH)

L'objectif de cette dernière étape de transformation est de passer d'une structure de données "plate" à un **modèle dimensionnel (Schéma en Étoile)** dans le dataset `strava_dwh`. Ce modèle est optimisé pour les performances et la clarté des analyses dans Power BI.

### Architecture du modèle en étoile
Pour ce projet, j'ai structuré les données autour d'une table de faits centrale et de plusieurs dimensions :

* **Table de Faits (`fct_activites`)** : Centralise toutes les mesures granulaires (distance, temps, vitesse).
* **Dimensions (`dim_calendar`, `dim_moment_journee`)** : Fournissent le contexte temporel et horaire pour filtrer les données.
* **Table Snapshot (`fct_global_stats`)** : Stocke les totaux historiques depuis 2015 pour servir de référentiel de vérité.

### Logique de transformation et calculs métiers
Plusieurs transformations ont été opérées pour normaliser les indicateurs de performance :

1.  **Standardisation des unités** : Conversion des données brutes en unités lisibles : mètres vers **kilomètres**, m/s vers **km/h**, et secondes vers **minutes**.
2.  **Calcul de l'allure ** : Création de la métrique `allure_min_km`. C'est l'indicateur principal pour la course à pied, calculé via `SAFE_DIVIDE` pour garantir la stabilité du pipeline.
3.  **Choix du format numérique** : Les durées sont stockées en format **décimal** (`FLOAT64`) et non en format horaire. Ce choix technique permet à Power BI de réaliser des calculs mathématiques (moyennes, sommes) avant le formatage visuel final.
4.  **Localisation (Français)** : Contrairement aux réglages par défaut de BigQuery (Anglais), j'ai intégré la traduction des jours et des mois directement en SQL via des instructions `CASE`. Cela permet de livrer un dataset "prêt à l'emploi" pour la visualisation.

### Optimisation pour la visualisation
* **Clé primaire** : Création d'un `date_id` (format `YYYYMMDD`) pour lier les activités au calendrier.
* **Gestion du tri** : Ajout d'une colonne `ordre_tri` dans la dimension pour forcer Power BI à afficher les moments de la journée (Matin, Midi, Soir) chronologiquement plutôt qu'alphabétiquement.

> **Pour consulter le détail de la structure du modèle, les formules SQL et les choix de modélisation, voir : [Documentation détaillée DWH](./docs/DWH/README.md)**
---

## Pistes d'amélioration

Ce projet constitue une **PoC (Proof of Concept)** solide qui démontre la viabilité du flux. Le pipeline est actuellement **semi-automatique** car il dépend d'un environnement local, mais plusieurs axes permettraient de le passer au niveau industriel :

### 1. Automatisation
Actuellement, le pipeline dépend d'Airbyte tournant sur mon Mac (Docker).
* **Amélioration** : Déployer Airbyte sur une instance et utiliser les **Scheduled Queries** de BigQuery. Cela permettrait une synchronisation et une transformation des données totalement autonomes durant la nuit, sans dépendance matérielle.

### 2. Monitoring et Alerting
Le suivi du pipeline nécessite aujourd'hui une vérification visuelle après chaque exécution.
* **Amélioration** : Mettre en place un système de notifications (Email) pour être alerté en cas d'échec de la synchronisation ou d'une erreur SQL.
* **Référence professionnelle** : Cette méthodologie est celle que j'applique dans le cadre de mon alternance au CHU. Chaque script de traitement génère un fichier de log détaillé. Ces fichiers sont ensuite parcourus par un automate qui remonte par mail un rapport d'état chaque matin, permettant de valider le bon déroulement des flux nocturnes ou d'intervenir rapidement en cas d'anomalie.

### 3. Orchestration
Les transformations SQL sont déclenchées manuellement de manière indépendante.
* **Amélioration** : Utiliser un orchestrateur pour gérer les dépendances (ex: ne pas lancer le DWH si l'ODS a échoué).

---
### Power BI
---

# Phase 4 : Conception du Dashboard (Power BI)

![img.png](images/Mode_nuit.png)

Cette dernière étape permet de mettre en image tout le travail effectué en amont sur BigQuery pour transformer la donnée brute en outil d'analyse.

### Pourquoi Power BI ?
Le choix de Power BI s'est imposé naturellement car j'ai pu aborder cet outil lors de mes cours en **Master MIAGE**. Ce projet était l'occasion parfaite de le reprendre en main sur un thème personnel comme Strava. De plus, sa capacité à se connecter nativement à **Google BigQuery** était un avantage majeur pour garantir un flux de données fluide et performant.

### Apprentissage et prise en main
Même si j'avais des bases, j'ai souhaité pousser l'outil plus loin pour ce projet. J'ai appris à utiliser des fonctions avancées à l'aide de l'IA et de vidéos YouTube spécialisées. Cela m'a permis d'intégrer des spécificités précises pour améliorer l'expérience utilisateur :

* **Design Dynamique (Mode Jour/Nuit)** : Création d'un switch intelligent via des signets (bookmarks) et des mesures DAX pour adapter l'interface à l'environnement de consultation.
* **Mesures Dynamiques** : Mise en place de sélecteurs permettant de basculer instantanément l'affichage entre les **valeurs réelles** et les **pourcentages**, offrant ainsi deux niveaux de lecture sur un même visuel.
* **Esthétique** : Travail approfondi sur le design (ombres portées, contrastes adoucis, codes couleurs Strava) pour transformer mon rapport en une interface proche d'une application mobile moderne.

> **Toutes les explications techniques, les captures d'écran du rendu final et le détail du design se trouvent dans le dossier dédié : [Documentation Visualisation](visualisation/README.md)**
> 