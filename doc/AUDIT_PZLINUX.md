# Audit technique complet de PZLinux

Date de l'audit : 16 aout 2026  
Version analysee : v1.0.13 en cours de preparation  
Cible : Project Zomboid B42.20.x Stable, solo et multijoueur  
Branche de travail : `dev/release_v1.0.12`, avec changements v1.0.13 non commites

## 1. Verdict executif

| Mode | Verdict | Motif principal |
|---|---|---|
| Solo, nouvelle sauvegarde | Candidat release avec tests manuels | Les chemins nominaux sont bien couverts, mais les redemarrages, la mort du personnage et les transitions interrompues doivent encore etre testes dans le vrai moteur. |
| Solo, ancienne sauvegarde | Prudence et sauvegarde obligatoire | Les migrations historiques importent encore des donnees depuis le `ModData` du personnage. |
| MP prive entre joueurs de confiance | Jouable pour continuer la recette | Les principales features fonctionnent, mais quelques etats economiques ne sont pas encore reellement canoniques cote serveur. |
| MP public | **NO-GO en production** | Plusieurs commandes serveur font encore confiance a du `ModData` joueur falsifiable par un client modifie. Elles permettent potentiellement de creer de l'argent, des objets, des actions ou des recompenses. |

Le mod est nettement plus robuste qu'au debut de la migration : commandes reseau prefixees et listees explicitement, banque et livraisons partiellement migrees vers des registres serveur, stock Dark Web partage, contrats monde persistants, controles de proximite sur les boites aux lettres et tests locaux nombreux.

Le principal travail restant n'est plus un nettoyage Lua. C'est la fin de la migration vers un modele serveur autoritaire : le `ModData` joueur doit devenir un miroir d'affichage et de compatibilite, jamais une preuve suffisante pour payer, livrer, valider une mission ou restaurer une session.

## 2. Portee et limites

L'audit couvre :

- les 66 fichiers Lua du mod, soit environ 26 466 lignes ;
- les commandes client/serveur et leur allowlist ;
- la banque, les ATM, Dark Web, Trading, Request, Sell Surplus, contrats, mails, reputation, entrainement, hacking et paris ;
- la persistance, les reconnexions, la mort et la recreation d'un personnage ;
- les spawns monde, files de livraison, recus et risques de double paiement ;
- les traductions, l'UI, les controles et les collisions avec d'autres mods ;
- les metadonnees Workshop, assets et scripts de verification.

Limites :

- l'environnement local ne contient pas le moteur Project Zomboid ni un serveur B42.20.2 reel ;
- les tests Lua utilisent des mocks. Ils prouvent les chemins nominaux, mais ne reproduisent pas toutes les particularites Kahlua/Java, le chargement des chunks et la synchronisation reseau reelle ;
- la JavaDoc B42 est non officielle et peut etre en retard sur la version Stable ;
- un constat marque MP suppose un client modifie capable de fabriquer des commandes `PZLinux` ou d'alterer son propre `ModData`. C'est le bon modele de menace pour un serveur public.

## 3. Resultats automatiques

| Controle | Resultat |
|---|---:|
| Fichiers Lua | 66 |
| Erreurs `luac5.1` | 0 |
| Warnings LuaCheck | 58 |
| Tests unitaires locaux | 53/53 reussis |
| Traductions verifiees | 20 catalogues, 600 cles chacun |
| Erreurs de cles/parametres de traduction | 0 |
| Metadonnees release | v1.0.13, B42.20+, valides |
| Appels `getPlayer()` directs hors helper central | 1 fallback volontaire |
| Fonctions globales dupliquees detectees | 0 |
| Assets PNG/OGG invalides | 0 detecte |

Repartition des 58 warnings :

| Code | Nombre | Evaluation |
|---|---:|---|
| W432 | 49 | Shadowing `self` dans des closures UI historiques, faible risque fonctionnel |
| W213 | 4 | Variables de boucle inutilisees, nettoyage simple |
| W411 | 1 | Variable redefinie dans l'UI ATM, a nettoyer |
| W581 | 1 | Simplification booleenne, cosmetique |
| W612 | 3 | Whitespace final, cosmetique |

Ces warnings ne bloquent pas une release. Ils ne doivent pas detourner l'effort des problemes P0/P1 ci-dessous.

## 4. Points solides

Les elements suivants sont correctement engages ou deja robustes :

- toutes les commandes reseau passent par le module `PZLinux` et une allowlist serveur ;
- les exceptions des workers serveur sont interceptees et journalisees ;
- une idempotence par `requestId` existe pour eviter la majorite des doubles clics ;
- le solde bancaire courant possede un registre global par identite de personnage ;
- la file de livraison v2 possede des `orderId`, des statuts et une recuperation des colis materialises ;
- le poids de livraison est limite a deux fois la capacite du joueur et les reliquats restent en attente ;
- le stock Dark Web et les prix Trading sont generes par le serveur et partages ;
- les contrats disponibles et les objectifs monde possedent un etat global ;
- les mots de passe Hacking restent sur le serveur ;
- les interactions boites aux lettres verifient l'objet et la proximite cote serveur ;
- les spawns Cargo, Manhunt et vehicules possedent des mecanismes de restauration et de deduplication ;
- les achats et depots utilisent l'inventaire reel vu par le serveur ;
- les metadonnees v1.0.13 et les assets passent les outils de release.

## 5. Modele d'autorite actuel

| Domaine | Source serveur canonique | Etat |
|---|---|---|
| Banque | `PZLinuxCharacterBankLedger` | Bon apres creation du compte, migration initiale a durcir |
| Livraisons | `PZLinuxDeliveryLedger` | Bon pour les nouvelles commandes, migrations legacy dangereuses |
| Stock Dark Web | Global `ModData` serveur | Bon |
| Prix Trading | Global `ModData` serveur | Bon |
| Parts Trading du joueur | `ModData` joueur | Non autoritaire |
| Contrats disponibles | Global `ModData` serveur | Bon |
| Objectif de contrat | Registre monde + miroir joueur | Partiel : plusieurs validations finales lisent encore le miroir |
| Mails | `ModData` joueur | Non autoritaire |
| Reputation | `ModData` joueur | Non autoritaire |
| Training | `PZLinuxTrainingLedger` par personnage + miroir joueur | Bon pour offres, prix, progression et XP ; fermeture a la mort a ajouter |
| Request quotidien et vehicule en attente | `ModData` joueur | Non autoritaire |
| Sell Surplus quotidien | `ModData` joueur | Non autoritaire |
| Sessions Blackjack/Poker/Hacking | Memoire serveur + rollback dans `ModData` joueur | Partiel |
| Tickets Zombie Race | Global serveur indexe par pseudo | Persistant, mais mauvaise identite |

## 6. P0 - Bloquants pour un MP public

### P0-01 - Les migrations legacy acceptent des donnees joueur sans preuve

Les migrations automatiques lisent directement d'anciens champs du personnage lors du premier acces au nouveau registre :

- la banque peut adopter `PZLinuxBank`/`PZLinuxBankBackup` lors de la creation d'un compte sans entree serveur ;
- Dark Web decode `PZLinuxOnItemBuyOnDarkWebQueue` puis enregistre les noms et quantites transmis ;
- Request decode `PZLinuxOnItemRequestQueue` puis enregistre les noms d'items transmis ;
- Mail convertit `PZLinuxOnMailReward` en autant de cadeaux en attente.

References :

- `ISPZLinuxVariablesTables.lua:547-587`
- `PZLinux/PZLinuxDarkWeb.lua:58-77`
- `ISPZLinuxVariablesTables.lua:2137-2160`
- `ISPZLinuxVariablesTables.lua:6682-6696`
- `PZLinux/PZLinuxDeliveryQueue.lua:121-162`

Impact potentiel : solde arbitraire sur un nouveau personnage, livraison de n'importe quel item scriptable, quantite excessive provoquant un gel pendant la materialisation, ou cadeaux de mails en boucle.

Correction attendue :

1. Desactiver par defaut l'import legacy depuis le `ModData` joueur en MP.
2. Introduire un flag serveur de migration du monde et une fenetre de migration explicite.
3. Valider chaque item contre l'ancienne table canonique, plafonner les quantites et refuser toute valeur inconnue.
4. Ne jamais adopter un solde client sur un personnage nouvellement cree ; utiliser le solde initial configure.
5. Prevoir une commande admin de migration pour les rares anciennes sauvegardes problematiques.

### P0-02 - La completion et plusieurs transitions de contrats utilisent le miroir joueur

`PZLinuxContractsApplyComplete` lit encore :

- `PZLinuxActiveContract` ;
- `PZLinuxOnReward` ;
- `PZLinuxOnZombieDead` ;
- `PZLinuxContractCompanyUp` ;
- `PZLinuxContractId`.

Il credite ensuite la banque avant de reconstruire le recu. Le depot postal, l'annulation et le contrat de rechargement ATM suivent egalement des flags et valeurs du `ModData` joueur. `PZLinuxContractsMarkWorldContract` ne verifie ni le proprietaire ni la transition de statut demandee.

References :

- `ISPZLinuxVariablesTables.lua:4432-4455`
- `ISPZLinuxVariablesTables.lua:4541-4559`
- `ISPZLinuxVariablesTables.lua:4670-4702`
- `ISPZLinuxVariablesTables.lua:4864-4953`
- `ISPZLinuxVariablesTables.lua:4962-5032`
- `ISPZLinuxVariablesTables.lua:5034-5083`

Impact potentiel : paiement fabrique, fermeture ou vol d'un contrat previsible, recompense modifiee, validation avec un item plus simple que celui attendu.

Correction attendue : le client envoie seulement l'intention (`deposit`, `cancel`, `complete`) et l'identifiant du contexte. Le serveur retrouve obligatoirement le contrat par `worldData.byCharacter[characterKey]`, verifie son proprietaire ou sa politique `claimableBy`, son statut courant, l'objectif canonique, puis calcule le paiement depuis `record.reward` et `record.zombieCount`.

### P0-03 - Les colis de vente ne sont pas compares au registre des recus

Dark Web et Sell Surplus lisent le montant depuis le `ModData` du `Base.SuspiciousPackage`. Dark Web accepte meme le prix parse depuis le nom `$123`. Un `receiptId` vide reste payable. Un `receiptId` present est seulement teste contre la liste des recus deja encaisses : le code ne compare pas le proprietaire, la source, le statut et `metadata.amount` du recu emis.

References :

- `PZLinux/PZLinuxDarkWeb.lua:539-603`
- `ISPZLinuxVariablesTables.lua:2638-2693`
- `PZLinux/PZLinuxDeliveryQueue.lua:398-461`

Impact potentiel : creation d'argent par colis renomme ou `ModData` falsifie, utilisation du recu d'un autre joueur, montant du colis different du montant emis.

Correction attendue : ignorer totalement le nom et le montant de l'item. Le colis ne doit porter qu'un `receiptId`. Le serveur charge le recu, exige `status == issued`, `receipt.player == characterKey`, la bonne `source`, puis paie exclusivement `receipt.metadata.amount` et marque le recu encaisse dans la meme transaction logique.

### P0-04 - Les parts Trading sont stockees dans le `ModData` joueur

L'achat ajoute les parts dans `ZLinuxPlayerWallet<code>`. La vente relit cette valeur, credite la banque, puis la decremente.

Reference : `ISPZLinuxVariablesTables.lua:3605-3724`.

Impact potentiel : un client modifie peut augmenter ses parts avant une vente et convertir cette valeur en argent serveur.

Correction attendue : creer un portefeuille serveur indexe par `PZLinuxGetCharacterKey`. Le `ModData` joueur ne recoit qu'un snapshot en lecture pour l'UI.

### P0-05 - Sell Surplus fait confiance a la demande quotidienne du joueur

Les quantites, totaux negocies et flags `greatDeal` sont conserves dans `PZLinuxSellDemand`. La vente utilise directement `demand.quantity` et `demand.total` pour emettre le colis de paiement.

Reference : `ISPZLinuxVariablesTables.lua:2413-2621`.

Impact potentiel : demande et montant arbitraires, puis paiement via le colis de vente.

Correction attendue : stocker les offres du jour dans le registre serveur du personnage, avec un identifiant d'offre opaque. Le client ne renvoie que cet identifiant et l'action `negotiate` ou `sell`.

### P0-06 - Mails et reputation restent canoniques dans le personnage

Problemes relies :

- les mails, leur type, objet, quantite, location et statut sont lus depuis `pzlinux.mails` du joueur ;
- la reputation servant aux prix et aux mails est lue et modifiee dans ce meme arbre ;
- une completion Mail retire les objets avant de garantir l'enregistrement du cadeau.

Training a ete retire de ce constat en v1.0.16. Ses offres, prix, echeance,
formation active et progression sont desormais conserves dans
`PZLinuxTrainingLedger`, indexe par l'identite persistante du personnage. Le
`ModData` joueur n'est plus qu'un miroir et le serveur reconstruit les champs
sensibles d'une ancienne formation lors de la migration.

References :

- `ISPZLinuxVariablesTables.lua:2744-3128` pour le correctif Training
- `ISPZLinuxVariablesTables.lua:5101-5156`
- `ISPZLinuxVariablesTables.lua:6433-6511`
- `ISPZLinuxVariablesTables.lua:6550-6798`

Impact potentiel restant : faux mail facile contre cadeau rare, reputation positive falsifiee et remises indues.

Correction attendue : deplacer ces domaines dans un `PZLinuxCharacterState` global serveur. Le personnage ne conserve qu'une copie d'affichage et, pour le solo, le meme module serveur local est utilise.

### P0-07 - La generation manuelle de mails est exposee a tous les clients

`PZLinuxMailGenerate` est dans l'allowlist publique et appelle directement le generateur aleatoire sans controle admin. Le serveur possede deja une commande separee `PZLinuxContractAdminForceMail` correctement protegee.

References :

- `PZLinuxServerCommands.lua:551-555`
- `PZLinuxServerCommands.lua:581-645`
- `ISPZLinuxVariablesTables.lua:3977-3995`

Impact potentiel : spam de mails, reroll jusqu'a une mission avantageuse, grossissement du `ModData` et farm de cadeaux.

Correction attendue : retirer `PZLinuxMailGenerate` de l'allowlist. Les mails naturels sont deja generes par le tick serveur, et les admins disposent de leur commande dediee.

### P0-08 - Les rollbacks de sessions interrompues sont falsifiables

Avant chaque commande, le serveur appelle `PZLinuxApplyInterruptedSessionRollbacks`. Cette fonction lit dans le `ModData` joueur :

- le montant Blackjack ;
- le montant Race legacy ;
- les types de cartes Hacking a restituer ;
- le stack Poker.

Un `bootId` different suffit pour declencher le remboursement si la session memoire n'existe plus.

References :

- `PZLinuxServerCommands.lua:83-91`
- `ISPZLinuxVariablesTables.lua:693-802`

Impact potentiel : credit arbitraire ou creation de cartes Hacking apres redemarrage.

Correction attendue : le registre des sessions interrompues doit etre un Global `ModData` serveur indexe par identite de personnage. Le miroir joueur ne doit jamais etre rembourse directement.

### P0-09 - La livraison de vehicule Request repose sur un etat joueur

Le spawn valide bien le script contre la table Request, la location contre les locations connues et la proximite a 50 cases. Cependant, l'existence meme de la commande payee, le script choisi, la location et le `deliveryId` proviennent encore de `PZLinuxOnItemRequestCar*` dans le personnage.

Reference : `ISPZLinuxVariablesTables.lua:3139-3275`.

Impact potentiel : fabrication d'une commande de vehicule valide sans debit correspondant, puis creation du vehicule et de sa cle.

Correction attendue : enregistrer l'achat et le statut du vehicule dans le registre serveur avant le debit finalise. Le spawn retrouve uniquement cet enregistrement par identite de personnage.

## 7. P1 - Risques eleves de perte, duplication ou incoherence

### P1-01 - Proximite ATM incomplete

Les operations ATM retrouvent l'objet depuis les coordonnees client, mais ne comparent pas la position du joueur a l'ATM. Le contrat de rechargement compare l'ATM a la cible, sans verifier la distance entre le joueur et cette cible.

References :

- `ISPZLinuxVariablesTables.lua:983-1103`
- `ISPZLinuxVariablesTables.lua:4962-5032`

Risque : commande a distance vers un ATM dont le chunk est charge par un autre joueur.

Correction : helper serveur unique `PZLinuxValidateAtmInteraction(player, atmRef, radius)` utilise par sync, depot, retrait et refill.

### P1-02 - Ordre des mutations ATM non atomique

Le retrait ajoute d'abord le cash physique, puis change le compte et l'ATM. Le refill retire le cash, appelle le credit sans verifier `credit.ok`, remplit l'ATM et avance le contrat.

Risques : cash ajoute sans debit lors d'un echec rare, ou cash retire sans remboursement sur personnage marque mort/erreur de registre.

Correction : valider toutes les preconditions, reserver la transaction, appliquer les mutations, puis confirmer. En cas d'echec, restaurer explicitement l'etat precedent.

### P1-03 - Plusieurs etats persistants sont indexes par pseudo

`PZLinuxGetPlayerKey` renvoie le pseudo. Ce pseudo indexe encore :

- contrats actifs `worldData.byPlayer` ;
- sessions Blackjack, Poker, Hacking et Race legacy ;
- tickets et resultats des courses programmees ;
- cache d'idempotence ;
- sessions temporaires Dark Web.

References :

- `ISPZLinuxVariablesTables.lua:413-420`
- `PZLinuxServerCommands.lua:27-57`
- `PZLinux/PZLinuxRaceSchedule.lua:209-280`
- `ISPZLinuxVariablesTables.lua:4200-4242`

Risque solo et MP : un nouveau personnage portant le meme pseudo peut heriter d'un contrat, d'un ticket gagnant, d'une session ou d'une reponse idempotente de l'ancien personnage.

Correction : utiliser `PZLinuxGetCharacterKey` pour tout etat economique ou persistant. Le pseudo reste uniquement une information d'affichage et de log.

### P1-04 - La mort ne ferme pas tous les domaines

`OnPlayerDeath` ferme les livraisons, la banque et l'identite. Il ne ferme pas explicitement :

- le contrat actif ;
- le portefeuille Trading ;
- les tickets Race ;
- les sessions de jeu et Hacking ;
- Training, Request, Mail, Reputation et Sell Surplus.

Reference : `PZLinuxServerCommands.lua:659-679`.

Correction : une fonction serveur `PZLinuxCloseCharacterState` doit traiter tous les domaines avec une politique documentee : annuler, perdre, rembourser uniquement depuis un journal serveur, ou archiver.

### P1-05 - Les ventes ne sont pas transactionnelles

Dark Web et Sell Surplus :

1. creent le colis et le recu ;
2. retirent ensuite les objets vendus ;
3. en cas de retrait partiel, suppriment le colis mais ne restaurent pas les objets deja retires.

A l'encaissement, le compte est credite avant que le recu soit marque encaisse et le colis retire.

Risques : perte d'items en cas d'echec partiel, ou double paiement si le processus s'interrompt entre credit et marquage du recu.

References :

- `PZLinux/PZLinuxDarkWeb.lua:475-522`
- `PZLinux/PZLinuxDarkWeb.lua:584-594`
- `ISPZLinuxVariablesTables.lua:2568-2617`
- `ISPZLinuxVariablesTables.lua:2668-2678`

### P1-06 - Absence de rate limiting serveur

L'idempotence est ignoree lorsque `requestId` est absent. Un client peut donc appeler rapidement les commandes de generation de snapshots, d'offres ou les workers les plus couteux.

Reference : `PZLinuxServerCommands.lua:83-119`.

Correction : exiger un `requestId` valide pour les mutations et ajouter une limite glissante par personnage/commande. L'idempotence et le rate limiting sont deux protections differentes.

### P1-07 - Le cycle Request/Sell quotidien reste falsifiable

La disponibilite des categories Request, les categories consommees, la demande Sell, les negociations et les ventes du jour sont stockees chez le joueur.

References :

- `ISPZLinuxVariablesTables.lua:1998-2086`
- `ISPZLinuxVariablesTables.lua:2413-2527`

Meme apres correction des paiements directs P0, un client pourrait contourner les cooldowns et rerolls tant que ces donnees ne sont pas dans le registre serveur.

### P1-08 - La garantie d'identite native doit etre validee en jeu

L'identite utilise le champ B42 `sqlId`, puis `getDescriptor():getID()` en fallback. Les tests couvrent les mocks et le remplacement d'une identite morte, mais ils ne prouvent pas que ces valeurs restent identiques apres reconnexion et redemarrage complet d'un serveur dedie.

Reference : `PZLinux/PZLinuxIdentity.lua:58-206`.

Test indispensable : meme personnage avant/apres reconnexion et restart, puis mort et nouveau personnage avec le meme pseudo. Journaliser `characterId`, `characterKey`, `sqlId` et descriptor ID.

## 8. P2 - Fiabilite et maintenance

### P2-01 - Fenetres de crash entre debit, queue et stock

Dark Web et Request debitent, enregistrent ensuite la livraison et mettent enfin a jour leur stock/etat. Les remboursements couvrent un echec Lua normal, pas un crash ou arret entre deux etapes.

Recommandation : petit journal de transaction serveur avec statuts `prepared`, `debited`, `committed`, `rolled_back`.

### P2-02 - Completion Mail non reversible

Les objets demandes sont retires avant l'enregistrement garanti du cadeau. Si `PZLinuxDeliveryEnqueue` echoue, le resultat signale l'echec mais les objets ne sont pas restitues.

Reference : `ISPZLinuxVariablesTables.lua:6757-6787`.

### P2-03 - Croissance de certains registres

- les contrats termines/annules restent dans `PZLinuxContractsWorld.active` ;
- l'historique de livraison ne peut retirer que les ordres `delivered` ou `lost` ;
- une accumulation anormale de `pending` peut donc croitre sans borne pratique.

Ajouter une retention configurable et un outil admin de diagnostic/nettoyage.

### P2-04 - `ISPZLinuxVariablesTables.lua` reste un point de couplage majeur

Le fichier contient encore 7 370 lignes. Il melange banque, ATM, reseau, sessions, Request, Sell, Training, Trading, contrats, mails, reputation, Hacking et callbacks.

Ce n'est pas un bug immediat, mais toute correction transverse augmente le risque de regression et rend les tests difficiles a isoler.

Extraction recommandee, apres les P0/P1 :

- `PZLinuxCharacterState.lua` ;
- `PZLinuxBank.lua` et `PZLinuxATM.lua` ;
- `PZLinuxContractsServer.lua` ;
- `PZLinuxRequestsServer.lua` ;
- `PZLinuxMailServer.lua` ;
- `PZLinuxTrainingServer.lua` ;
- `PZLinuxHackingServer.lua`.

### P2-05 - API Java optionnelles testees par acces direct

Plusieurs chemins font `if zombie.setTarget then`, `if vehicle.isExistInTheWorld then` ou equivalent. Le bug recent `NetworkZombieAI.extraUpdate` a montre qu'avec certains objets Java/Kahlua, le simple acces a une methode absente peut lever une exception avant l'appel protege.

References sensibles :

- `PZLinuxOnEvents.lua:6-10`
- `ISPZLinuxVariablesTables.lua:3127-3137`
- `ISPZLinuxVariablesTables.lua:5329-5344`
- `ISPZLinuxVariablesTables.lua:5384`

Ne pas modifier les appels deja valides en jeu sans raison. Pour toute nouvelle API incertaine, utiliser un helper de reflexion protege et valider contre le `.jar` exact de B42.20.x.

### P2-06 - Textes encore hardcodes

Les 20 catalogues existants ont une parite parfaite de 600 cles, y compris `CN` et `CH`. La plainte chinoise reste neanmoins plausible, car des textes visibles sont encore ecrits directement en anglais :

- notifications de livraison et de contrat ;
- messages d'erreur de boites aux lettres ;
- une partie de Hacking et Condition ;
- libelles Wallet/Trading historiques ;
- messages admin/debug.

Exemples :

- `PZLinuxOnEvents.lua:193,425`
- `ISContextMailBox.lua:123-175`
- `ISContextStreetMailBox.lua:117-169`
- `PZLinuxCondition.lua:178`
- `PZLinuxWallet.lua:233`

Le scanner trouve 2 537 candidats, mais ce chiffre inclut logs, cles reseau et commentaires. Il faut traiter par surface UI, pas par remplacement aveugle.

### P2-07 - Trois langues annoncees ne sont pas livrees

Les catalogues actuels sont : `EN`, `FR`, `CS`, `DE`, `ES`, `HU`, `IT`, `JP`, `KO`, `NL`, `NO`, `PL`, `PT`, `PTBR`, `RU`, `TH`, `TR`, `UA`, `CN`, `CH`.

Il manque encore :

- Afrikaans (`AF`) ;
- catalan (`CA`) ;
- vietnamien (`VI`).

Le checker doit etre etendu a ces trois codes avant d'annoncer toutes les langues de la liste PZ fournie.

### P2-08 - Support manette incomplet

Aucun vrai flux Joypad n'a ete detecte dans les panneaux principaux. Les boutons sont concus pour la souris et certains champs attendent le clavier.

Consequences : navigation au D-pad/stick, focus visible, retour, listes scrollables et saisie des mises ne sont pas garantis.

Avant d'annoncer le support controller : definir l'ordre de focus, implementer `onJoypadDown`/navigation standard PZ, puis tester Xbox sur toutes les interfaces CRT.

### P2-09 - Globals historiques non prefixes

L'audit trouve 308 declarations dont le nom textuel ne commence pas par `PZLinux`. Ce total inclut les methodes de classes, donc il surestime les collisions reelles. Les globals libres et classes restent toutefois nombreux : `linuxUI`, `AtmUI`, `MailBoxUI`, `contractsUI`, `ISBloodAction`, `AtmMenu_*`, `linuxMenu_*`, etc.

Il n'existe actuellement aucun doublon interne, mais un autre mod peut definir le meme global.

Correction progressive : alias prefixe, migration des appels, puis suppression de l'ancien alias sur une version majeure. Ne pas renommer toutes les classes juste avant release sans tests UI complets.

### P2-10 - Localisation serveur des objets persistants

Les notes et noms d'items crees sur un serveur dedie utilisent la langue du serveur, pas celle de chaque client. Sur un serveur multilingue, deux joueurs peuvent donc voir la meme note monde dans une langue qui n'est pas la leur.

Pour les donnees persistantes, stocker une cle et ses parametres quand l'API le permet ; sinon documenter cette limite.

## 9. P3/P4 - Dette faible et finition

- 49 warnings W432 dans les anciennes closures UI : faibles risques, nettoyage apres la recette fonctionnelle.
- Un W411 dans ATM et quatre W213 : faciles a corriger avant le tag final.
- Trois trailing whitespaces et un W581 : cosmetiques.
- Les dossiers optionnels `AnimSets`/`actiongroups` absents peuvent produire du bruit lors d'un Reload Lua B42, sans preuve d'impact sur PZLinux.
- Manhunt ne possede qu'une location Muldraugh : fonctionnel mais tres repetitif.
- Fallas Lake, Valley Station et plusieurs villes manquent de couverture pour certains pools de missions.
- Les logs de restauration Manhunt/Vehicle sont utiles en RC, mais devront etre rendus configurables pour une release publique moins bruyante.

## 10. Matrice fonctionnelle

| Feature | Solo nominal | MP nominal | Securite MP public | Reconnexion/restart |
|---|---|---|---|---|
| Banque | Bon | Bon | Partiel, migration initiale | A tester sur serveur reel |
| ATM | Bon | Bon selon tests live | Proximite incomplete | Persistance objet correcte a confirmer |
| Dark Web achat/livraison | Bon | Bon selon tests live | Migration legacy P0 | File v2 robuste |
| Dark Web vente | Bon nominal | Bon nominal | Recu falsifiable P0 | Fenetre de double paiement |
| Sell Surplus | Bon nominal | Bon nominal | Demande/recu P0 | Fenetres transactionnelles |
| Trading prix | Bon | Partage serveur | Bon | Global persistant |
| Trading portefeuille | Bon nominal | Sync UI | Non autoritaire P0 | Heritages possibles |
| Contrats board/spawns | Bon | Partage serveur | Objectifs monde plutot bons | Contrat indexe pseudo |
| Contrats paiement/depot | Bon nominal | Bon nominal | Non autoritaire P0 | Etat de mort incomplet |
| Request items | Bon nominal | Livraison v2 | Roll legacy P0 | Queue robuste apres migration |
| Request vehicule | Bon selon tests | Spawn serveur | Pending joueur P0 | Restaurations complexes a retester |
| Mails | Bon nominal | Tick serveur | Non autoritaire P0 | Migration reward dangereuse |
| Reputation | Bon nominal | Snapshot serveur du miroir | Non autoritaire P0 | Mort non traitee |
| Training | Bon | Registre serveur par personnage | Bon hors migration legacy initiale | Fermeture a la mort non traitee |
| Hacking | Bon | Mot de passe serveur | Bon hors rollback | Session/rollback a migrer |
| Blackjack/Poker | Bon nominal | Sessions serveur | Bon hors rollback/identite | Politique restart partielle |
| Zombie Race planifiee | Bon | Serveur planifie | Paiement serveur | Tickets indexes pseudo |
| Traductions | 20 catalogues valides | Identique | Sans objet | Couverture UI incomplete |
| Controller | Non garanti | Non garanti | Sans objet | Non teste |

## 11. Architecture cible recommandee

Creer un registre serveur unique, par exemple `PZLinuxCharacterStateV1`, indexe par `PZLinuxGetCharacterKey(player, true)` :

```lua
state.players[characterKey] = {
    reputation = 1,
    tradingHoldings = {},
    request = {},
    sell = {},
    training = {},
    mails = {},
    interruptedSessions = {},
}
```

Regles :

1. Le serveur cree et modifie ce registre.
2. Le client envoie uniquement une intention et des identifiants opaques.
3. Le serveur calcule prix, quantite, reward, statut suivant et ownership.
4. Le `ModData` joueur est reconstruit depuis le registre pour les anciennes UI et le solo.
5. Toute mutation economique possede un `transactionId` et un statut persistant.
6. La mort ferme l'etat du `characterKey` sans toucher au nouveau personnage du meme compte.

Cette architecture permet de conserver exactement le meme gameplay solo : en solo, le processus local joue simplement le role du serveur autoritaire.

## 12. Roadmap durcissement MP public - v1.3.0

Ces corrections restent obligatoires avant de presenter PZLinux comme resistant
a des clients modifies sur un serveur public ou competitif. Elles ne bloquent
pas necessairement la branche 1.0.x lorsque son perimetre annonce reste le solo
et les serveurs prives cooperatifs entre joueurs de confiance.

- [ ] P0-01 : verrouiller/desactiver les migrations legacy non prouvees.
- [ ] P0-07 : retirer `PZLinuxMailGenerate` de l'allowlist publique.
- [ ] P0-03/P0-05 : rendre les recus et Sell Surplus entierement canoniques.
- [ ] P0-02 : faire de `PZLinuxContractsWorld` l'unique source pour depot, annulation et paiement.
- [ ] Creer `PZLinuxCharacterStateV1` et migrer Trading, Reputation, Mails et Request/Sell ; integrer ou conserver explicitement le registre Training existant.
- [ ] P0-08 : deplacer les rollbacks dans le registre serveur.
- [ ] P0-09 : deplacer la commande de vehicule payee dans le registre serveur.
- [ ] P1-03/P1-04 : remplacer les index pseudo et fermer tous les domaines a la mort.
- [ ] P1-01/P1-02 : ajouter la proximite ATM et les rollbacks de transaction.
- [ ] P1-06 : exiger les `requestId` et ajouter un rate limit.
- [ ] Ajouter les tests adversariaux et de fault injection.
- [ ] Faire la recette SP/MP de redemarrage et d'identite native.
- [ ] Completer traductions, controller et warnings seulement apres les blocants.

## 13. Checklist de tests manuels

### Solo neuf

- [ ] Creer une nouvelle sauvegarde B42.20.x et verifier le solde initial.
- [ ] Acheter deux articles Dark Web, vendre un article, puis tout retirer en une seule interaction mailbox.
- [ ] Recommencer avec un inventaire proche de deux fois le poids maximum et verifier le reliquat.
- [ ] Tester les 13 contrats, annulation, completion et rapport de paiement.
- [ ] Tester chaque transition apres fermeture/reouverture du PC.
- [ ] Tester Cargo, Manhunt et vehicule apres marche normale, teleport debug et Reload Lua.
- [ ] Tester un restart complet entre achat et livraison, puis entre objectif et completion.
- [ ] Mourir avec contrat, ticket Race, Training et commandes en attente ; recreer le meme pseudo.

### Migration ancienne sauvegarde

- [ ] Copier la sauvegarde avant test.
- [ ] Verifier une seule importation du solde et des anciennes queues legitimes.
- [ ] Verifier qu'une queue invalide, un item inconnu ou une quantite enorme est refuse.
- [ ] Verifier que le nouveau personnage du meme compte n'importe rien de l'ancien.

### Serveur dedie, deux clients

- [ ] Verifier deux soldes independants avant/apres reconnexion et restart.
- [ ] Accepter un contrat avec A, verifier sa disparition du board pour B et son ownership.
- [ ] Voler un objectif monde avec B selon les regles voulues, sans pouvoir falsifier le paiement.
- [ ] Deconnecter A a chaque etape de chaque contrat, puis reprendre apres reconnexion.
- [ ] Acheter le dernier stock Dark Web simultanement avec A et B.
- [ ] Tester depot/retrait ATM simultane et ATM a zero/plein.
- [ ] Tester Poker, Blackjack, Hacking et Race pendant un restart serveur.
- [ ] Mourir puis recreer le meme pseudo et verifier absence d'heritage economique.
- [ ] Verifier l'identite native dans les logs avant/apres restart complet.

### UI, langues et controller

- [ ] Tester EN, FR, DE, RU, CN, CH et une langue a texte long sur chaque ecran CRT.
- [ ] Verifier tooltips, scrollbars, textes longs et boutons a faible resolution.
- [ ] Rechercher les notifications anglaises restantes en jouant en CN/FR.
- [ ] Tester manette Xbox sans souris : ouverture, navigation, validation, retour, scroll et saisie.

## 14. Tests automatiques a ajouter

- [ ] `test_untrusted_player_moddata.lua` : falsifier chaque champ historique avant chaque commande serveur.
- [ ] `test_legacy_migration_allowlist.lua` : item inconnu, quantite enorme, nouveau personnage, migration deja faite.
- [ ] `test_contract_state_machine.lua` : toutes les transitions autorisees/interdites et ownership.
- [ ] `test_sale_receipt_authority.lua` : recu vide, faux montant, mauvais owner, mauvaise source, deja encaisse.
- [ ] `test_character_state_death.lua` : meme pseudo, deux character IDs, aucune fuite de domaine.
- [ ] `test_atm_remote_commands.lua` : ATM valide mais joueur trop loin.
- [ ] `test_transaction_faults.lua` : echec simule apres chaque etape debit/queue/stock/recu.
- [ ] `test_server_rate_limit.lua` : spam sans `requestId`, replay et request IDs invalides.
- [ ] `test_translation_visible_literals.lua` : liste d'exceptions explicites pour les textes anglais realistes du boot.
- [ ] Un smoke test serveur Windows qui demarre PZ, connecte deux clients de test et archive `console.txt`.

## 15. Decision release

Pour une RC solo ou un serveur prive de recette entre joueurs de confiance, la
v1.0.13 peut continuer a etre testee apres sauvegarde du monde. Les risques P0
decrits ici demandent principalement un client modifie, des commandes reseau
fabriquees ou une alteration volontaire du `ModData` ; ils ne correspondent pas
a des actions disponibles dans l'interface normale.

Le chantier P0/P1 d'autorite serveur est planifie pour la v1.3.0 dans
`doc/ROADMAP.md`. Avant d'annoncer une compatibilite MP publique resistante a la
triche, les P0-01 a P0-09 devront etre corriges et la checklist MP rejouee sur un
serveur dedie B42.20.x. Les warnings LuaCheck et le refactor des grosses UI
peuvent attendre cette migration.
