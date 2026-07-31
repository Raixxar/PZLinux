# Audit technique PZLinux - preparation v1.0.0

Date : 2026-07-31

Cible : Project Zomboid Build 42.20.0 Stable

Perimetre : depot local complet, Lua client/server/shared, economie, missions, MP, traductions, outils et qualite release.

## 1. Resume executif

PZLinux est maintenant beaucoup plus proche d'une release 1.0.0 qu'au debut de la migration. Les flux economiques majeurs disposent d'un chemin serveur en MP et conservent un fallback local en solo : banque/ATM, Dark Web, Trading, contrats, Requests, Mails, Hacking, Blackjack, courses et Poker.

La structure des donnees a aussi progresse. Les catalogues Dark Web et Trading, les formules economie, les definitions de contrats et Requests, le Poker et les locations B42.20 sont dans des modules `shared/PZLinux/` dedies. Le vieux fichier `RetrievePackage.lua` a ete retire et les dialogues de contrats ont ete fortement mutualises.

Verdict actuel : **release candidate avancee, mais pas encore publiable comme MP complet**.

| Cible | Verdict | Motif principal |
| --- | --- | --- |
| Solo | Fonctionnel, retest final requis | Les derniers changements locations/traductions doivent etre rejoues en B42.20.0 |
| MP coop | Fonctionnel avec reserves | Les grands flux et mailboxes sont serveur-autoritatifs, mais les tests live restent a traiter |
| Serveur dedie | Non valide en production | Aucun test complet deux joueurs/reconnexion/redemarrage n'est documente |
| Traductions | Structure complete, qualite a relire | 20 catalogues synchronises, mais 18 sont des premieres traductions automatiques |
| Manette | Non garanti | Navigation/focus controller non implementes systematiquement |

Les deux P0 contrats identifies sont maintenant corriges. `PZLinuxContractsApplyComplete` ignore les anciennes donnees de paiement client et `PZLinuxContractsApplyAccept` ne lit plus que `contractId`. Le serveur prepare et conserve un brouillon canonique contenant location, cible, demande, quantite, reward et note, puis consomme ce brouillon a l'acceptation.

Les durcissements P1 les plus sensibles sont egalement termines dans le code : les actions mailbox et objectifs de contrats sont validees contre le monde et la position serveur, le comptage des zombies morts appartient au serveur, et le mot de passe Hacking ne quitte plus la session serveur. Le principal verrou avant production n'est donc plus une mutation economique client connue, mais la campagne de tests reels : deux clients, commandes forgees, streaming des objectifs, reconnexion et redemarrage du serveur.

## 2. Travaux realises

### Autorite serveur et MP

- Commandes reseau regroupees sous le module `PZLinux` et noms de commandes sensibles prefixes `PZLinux*`.
- Banque et ATM serveur-autoritatifs en MP, avec depot/retrait atomique et reserve ATM persistante de `$10k-$50k`.
- Dark Web achat, vente, offres, commandes, livraisons et encaissements migres vers le serveur.
- Les colis Dark Web crees par le serveur sont explicitement synchronises vers l'inventaire client; une creation echouee conserve la commande pending pour permettre un retry.
- Livraisons Dark Web/Request, encaissements Dark Web et depots de contrats limites par le serveur a une vraie mailbox situee a deux cases maximum et sur le meme niveau Z.
- Trading et Wallet bases sur les prix globaux serveur et un snapshot commun.
- Board de contrats global, accept/cancel/deposit/complete et evenements monde relies au serveur.
- Preview de contrat genere et cache cote serveur; l'acceptation client n'envoie que `contractId`.
- Registre global `PZLinuxContractsWorld` et tags persistants `PZLinuxContractId` sur objectifs/items compatibles.
- Les commandes d'objectifs ne font plus confiance a un `contractId` ou a des coordonnees client : le serveur resout l'objet, le cadavre ou le zombie reel, controle distance/Z/tag/statut, puis effectue lui-meme spawn, retrait et reward.
- `OnZombieDead` est traite cote serveur a partir du dernier attaquant et des tags d'objectif; les commandes client `zombieKilled` et `clearCargo` sont refusees.
- Requests, livraisons d'items et spawn de vehicules migres vers le serveur.
- Mails : generation, acceptation, suppression, completion, retrait des items et reward migres vers le serveur.
- Hacking : consommation de cartes, session, tentatives, lock et transfert migres vers le serveur.
- Le mot de passe Hacking reste dans la session serveur; le client ne recoit que sa longueur et le feedback de ses propres tentatives.
- Blackjack, course et Texas Hold'em resolus cote serveur en MP.
- Idempotence generique par joueur, commande et `requestId` pour limiter doubles clics et retries reseau.
- Politique de redemarrage : remboursement Blackjack, restauration des cartes Hacking et cashout/rollback Poker.
- Appels directs `getPlayer()` elimines hors helper central selon `tools/run_static_audit.sh`.

### Economie et gameplay

- Prix Dark Web releves pour les armes, munitions, explosifs, livres, generateurs, armures et objets rares.
- Requests rencheries et remise PlantScavenging plafonnee a 15 %.
- Recompenses des contrats faciles reduites; contrats dangereux conserves comme activite de milieu/fin de partie.
- Bonus rare de mail plafonne a `$100-$300`.
- Reputation centralisee, attribuee cote serveur et soumise a une decroissance periodique.
- Bonus vertical de location : `+5 %` de recompense par niveau absolu de Z.
- Effets stress/bonheur/ennui ajoutes aux paris.

### Poker et betting

- Texas Hold'em ajoute avec quatre lobbies, buy-in, blinds, IA, evaluation complete des mains et pots secondaires.
- Sessions isolees par joueur, actions et cashout serveur-autoritatifs.
- Fermeture/minimisation de l'UI Poker : cashout automatique pour eviter la perte des fonds temporaires.
- Table reduite a cinq places au total et historique separe visuellement des cartes/joueurs.
- Cartes rendues lisibles avec rangs `A, 2-10, J, Q, K` et symboles de couleur quand la police PZ les supporte.
- Test hors-jeu du moteur Poker disponible et passant.

### Donnees, contrats et locations

- `PZLinuxDarkWebData.lua` : catalogue/prix Dark Web.
- `PZLinuxTradingData.lua` : societes, codes et prix initiaux.
- `PZLinuxWorldInteractions.lua` : references monde et validation serveur des mailboxes, objets, cadavres et zombies.
- `PZLinuxEconomy.lua` : normalisation argent, prix, inflation, reputation et delais.
- `PZLinuxContractsData.lua` : definitions des 12 contrats et companies.
- `PZLinuxContractRequestData.lua` : noms de cibles et demandes auto/medical/armes.
- `PZLinuxContractMission.lua` : generation canonique serveur des previews et notes de contrats.
- `PZLinuxRequestsData.lua` : catalogues, poids, prix et donnees Requests.
- `PZLinuxMissionLocations.lua` : villes et pools B42.20 mutualises.
- `PZLinuxContractDialogue.lua` : squelette de conversation commun aux contrats.
- Suppression du fichier legacy `RetrievePackage.lua`; le contrat colis utilise le flux commun.
- Dialogues des contrats 2 a 12 restructures sans changer volontairement leur ton IRC.
- Request refactorise pour consommer ses donnees partagees au lieu de longues tables inline.

Etat des pools de locations valide par `tools/audit_locations.lua` :

| Pool | Nombre | Etat |
| --- | ---: | --- |
| packages | 37 | OK |
| cargo | 22 | OK |
| manhunt | 16 | OK |
| protect | 7 | OK |
| vehicles | 36 | OK |
| mailDrops.ammo | 37 | Reutilise packages, OK |
| mailDrops.medical | 37 | Reutilise packages, OK |

Les villes sans point pour une activite restent dans la liste globale, mais ne doivent pas etre tirees pour ce pool. La repartition est encore inegale : Ekron n'a que Protect, Coalfield seulement Package/Cargo, et Fallas Lake/Valley Station n'ont actuellement aucun point actif.

### UI et traductions

- Request utilise maintenant un `ISRichTextPanel` de taille fixe avec retour a la ligne, scroll conditionnel et descente automatique.
- Le texte tape et les boutons Oui/Non restent hors du panneau de conversation.
- Descriptions de locations converties en cles traduisibles avec fallback anglais.
- Reference EN et traduction FR synchronisees.
- 18 catalogues supplementaires crees : `CS`, `DE`, `ES`, `HU`, `IT`, `JP`, `KO`, `NL`, `NO`, `PL`, `PT`, `PTBR`, `RU`, `TH`, `TR`, `UA`, `CN`, `CH`.
- Total : 20 langues, 284 cles par langue.
- `tools/check_translations.lua` controle fichiers, table Lua, UTF-8, doublons, cles manquantes/supplementaires et signatures `%s`/`<parametre>`.
- `tools/generate_translations.pl` permet de regenerer une langue en preservant les placeholders et noms propres.

Attention : la presence des catalogues ne signifie pas que tout le mod est traduit. L'audit heuristique trouve encore 1927 chaines candidates, dont beaucoup sont des identifiants, noms d'items, etats internes ou textes volontairement anglais. Les textes visibles doivent etre tries et migres domaine par domaine.

## 3. Architecture actuelle

```text
media/lua/client/Context/World/     UI, context menus, affichage et interactions
media/lua/server/                   dispatch des commandes MP
media/lua/shared/TimedActions/      actions temporisees PZ
media/lua/shared/PZLinux/           donnees et moteurs partages par domaine
media/lua/shared/Translate/         catalogues de traduction
ISPZLinuxVariablesTables.lua        helpers, wrappers MP/solo et runtimes restants
tools/                              audits, tests et suivi console
```

`ISPZLinuxVariablesTables.lua` mesure encore 3483 lignes. Son role est plus raisonnable qu'avant, mais il contient toujours banque/ATM, betting, wrappers reseau, contrats, mails, Hacking et sessions temporaires. Les prochaines extractions doivent etre faites par domaine sans renommer brutalement les cles ModData historiques.

Modules partages actuels :

- `PZLinuxConfig.lua`
- `PZLinuxContractRequestData.lua`
- `PZLinuxContractMission.lua`
- `PZLinuxContractsData.lua`
- `PZLinuxDarkWeb.lua`
- `PZLinuxDarkWebData.lua`
- `PZLinuxEconomy.lua`
- `PZLinuxGamblingData.lua`
- `PZLinuxMailData.lua`
- `PZLinuxMissionLocations.lua`
- `PZLinuxPokerConfig.lua`
- `PZLinuxPokerEngine.lua`
- `PZLinuxRequestsData.lua`
- `PZLinuxTradingData.lua`
- `PZLinuxWorldInteractions.lua`

## 4. Etat fonctionnel detaille

| Fonctionnalite | Solo | MP code | Persistance/restart | Validation restante |
| --- | --- | --- | --- | --- |
| Ordinateur et connexion | Oui | Player explicite | ModData | Split-screen/controller |
| Banque | Oui | Serveur | Player ModData | Reconnexion et double commande |
| ATM reserve/depot/retrait | Oui | Serveur atomique | Object + Player ModData | Deux joueurs sur le meme ATM |
| Dark Web achat/vente | Oui | Serveur + mailbox validee | Pending Player ModData | Reconnexion et test commande distante |
| Trading/Wallet | Oui | Prix globaux serveur | Global + Player ModData | Deux clients, restart, commission 5 % |
| Contrats board | Oui | Global serveur | Global ModData | Rotation et concurrence |
| Contrats accept | Oui | Serveur-autoritatif | Player + World ModData | Test client forge et UX MP |
| Contrats objectifs volables | Oui | Resolution/tag/distance/statut serveur | Object/Item/Global ModData | Streaming chunks et vol entre joueurs |
| Contrats completion | Oui | Serveur, reward serveur | Player/Global ModData | Test legitime + commande forgee |
| Requests items | Oui | Serveur + mailbox validee | Pending Player ModData | Test commande distante |
| Requests vehicules | Oui | Serveur | Pending puis monde | Chunk charge, double spawn, MP |
| Mails | Oui | Serveur | Player ModData | Reward tiers et tests distance |
| Hacking | Oui | Session et secret serveur | Rollback cartes | Tests MP/restart et economie |
| Blackjack | Oui | Serveur | Refund mise au retour | Restart live |
| Course | Oui | Serveur | Pas de stake persistant bloque | Esperance mathematique |
| Poker | Oui | Serveur | Rollback/cashout stack | Test MP/restart/UI resolutions |
| Traductions | Partiel | Identique | Fichiers statiques | Relecture native et textes restants |
| Manette | Non garanti | n/a | n/a | Implementation complete |

## 5. Audit MP et securite

### Protections en place

- Le serveur recalcule les prix Dark Web, Trading et Requests.
- Les mutations d'argent majeures passent par les helpers banque serveur.
- Les commandes economiques utilisent un `requestId` idempotent.
- La completion des contrats ne fait plus confiance au reward client.
- Les contrats monde ont un identifiant persistant et un statut global.
- Les commandes banque, ATM et betting utilisent toutes le prefixe `PZLinux`.
- Les commandes mailbox resolvent l'objet cote serveur depuis ses coordonnees et son sprite, puis valident son type, la distance et le niveau Z du joueur.
- Les commandes contrats resolvent une reference technique vers l'entite chargee cote serveur; elles ne lisent ni `args.contractId` ni position de mission fournie par le client.
- Package/Protect exigent un objet reel proche du joueur et du point canonique; Cargo/Manhunt exigent le tag persistant du contrat; Blood/Capture exigent un cadavre ou zombie reel a portee.
- Le serveur retire le cargo, le cadavre ou le zombie seulement apres validation et transition atomique de l'etat global.
- Le comptage Kill/Protect/Blood vient de `Events.OnZombieDead` cote serveur et de `zombie:getAttackedBy()`, pas d'une commande client.
- Le mot de passe Hacking n'est jamais inclus dans une reponse reseau; chaque proposition est comparee dans la session serveur.

### P0 corriges

- Completion : le serveur utilise uniquement son ModData pour valider et payer le contrat.
- Acceptation : `PZLinuxContractPreview` genere la mission cote serveur et `PZLinuxContractAccept` ne recoit que `requestId` et `contractId`.
- Le serveur choisit la location dans le pool/city du board, la cible, l'item, la quantite, le niveau Z, la recompense et la note.
- Un contrat en etat actif, depose ou pret a encaisser bloque toute nouvelle preview/acceptation.
- `tools/test_contract_authority.lua` verifie les generations canoniques et interdit la reintroduction de champs `state.*` sensibles.
- `tools/test_contract_world_authority.lua` interdit le retour du comptage client, des coordonnees/IDs de contrat client et des suppressions d'entites cote client.

### P1 implementation terminee, validation live requise

- Les evenements monde contrats sont durcis statiquement mais doivent encore etre testes avec commandes forgees, objets stream/unstream et objectifs appartenant a un autre joueur.

### P2 et robustesse

- Le cache idempotent est en memoire; sa tenue et son nettoyage sur serveur long doivent etre observes.
- ATM simultane, livraison simultanee et deux cashouts Poker exigent un test reel a deux clients.
- Deux fonctions globales ont des definitions client/shared en doublon : `PZLinuxTrading_initializePrices` et `PZLinuxUpdateTradingPrices`. Clarifier wrappers ou rendre les versions client locales.
- Les cles ModData historiques doivent rester compatibles avec les sauvegardes existantes.

## 6. Audit economie

L'economie est mieux calibree qu'avant : le Dark Web n'offre plus aussi vite les objets les plus puissants, les Requests sont du confort cher et les petits contrats ne financent plus immediatement l'equipement end-game.

Points encore a mesurer :

- Trading applique maintenant une commission serveur de 5 % a l'achat comme a la vente. Un aller-retour au meme prix rend environ 90,48 % de la somme effectivement debitee a l'achat, avant arrondi.
- Course : le payout `mise * cote` doit etre confronte a la probabilite reelle de victoire par une simulation massive.
- Hacking peut rester une source de cash repetable sans cooldown/rendement decroissant.
- `PZLinuxMailGiveReward` tire encore 1 a 5 objets dans tout le catalogue Dark Web et peut ajouter un revolver. Le cash est plafonne, pas la puissance de l'objet.
- Le bonus de reward par Z est raisonnable a 5 % et utilise maintenant uniquement le Z choisi par le serveur.
- La reputation existe et decroit, mais ses seuils/avantages doivent etre observes sur une partie longue.

Recommandations avant publication :

1. Tester en serveur dedie les controles mailbox avec un client legitime puis des commandes distantes forgees.
2. Mesurer en partie longue si la commission Trading de 5 % freine suffisamment les gros capitaux sans rendre les petits ordres frustrants.
3. Simuler au moins 100 000 courses par configuration et maintenir une esperance joueur negative moderee.
4. Ajouter un cooldown Hacking de 12 a 24 heures monde ou des rendements decroissants.
5. Remplacer le reward mail global par trois tiers ponderes.

## 7. Qualite statique et namespace

Resultats mesures le 2026-07-31 :

| Controle | Resultat |
| --- | --- |
| Lua 5.1 `luac5.1 -p` sur 55 fichiers | OK |
| Luacheck | 113 warnings, 0 errors |
| Audit statique P0 historique | OK |
| Appels `getPlayer()` hors helper | 0 |
| Assets PNG/OGG | OK |
| Locations B42.20 | OK, 7 pools |
| Traductions | OK, 20 langues x 284 cles |
| Test moteur Poker | OK |
| Test autorite contrats | OK |
| Test autorite objectifs contrats | OK |
| Test secret Hacking | OK |
| Test proximite mailbox | OK |
| Test livraison Dark Web MP | OK |
| Test commission Trading | OK |
| Fonctions globales non prefixees | 294 declarations |
| Textes hardcodes | 1927 candidats heuristiques |

Repartition Luacheck :

| Code | Nombre | Priorite | Action |
| --- | ---: | --- | --- |
| W432 | 50 | Faible | Shadowing `self` dans closures UI; renommer progressivement |
| W611 | 20 | Faible | Lignes vides avec whitespace |
| W211 | 12 | Moyenne | Variables locales inutilisees |
| W612 | 8 | Faible | Trailing whitespace |
| W613 | 6 | A verifier | Whitespace dans strings, ne pas corriger aveuglement |
| W581 | 5 | Faible | Expressions booleennes simplifiables |
| W614 | 4 | Faible | Whitespace dans commentaires |
| W213 | 4 | Faible | Variables de boucle inutilisees |
| W431 | 2 | Moyenne | Shadowing d'upvalue |
| W411 | 1 | Importante | Variable redefinie dans Wallet |
| W311 | 1 | Importante | Affectation inutilisee dans Mail |

Le script `tools/check_lua_syntax.sh` retourne actuellement un code d'erreur parce qu'il enchaine Luacheck apres la syntaxe. La syntaxe seule est bien valide; la commande globale restera rouge tant que les 113 warnings ne seront pas traites ou explicitement toleres.

Les 294 declarations non prefixees comprennent beaucoup de methodes de classes UI historiques (`linuxUI`, `darkWebUI`, `AtmUI`, etc.). Leur renommage reste souhaitable pour eviter les collisions entre mods, mais doit etre fait classe par classe avec toutes les references et, si necessaire, un alias temporaire.

## 8. Traductions et UI

Etat positif : tous les catalogues possedent exactement les memes 284 cles et placeholders que l'anglais. La syntaxe Lua et l'UTF-8 passent.

Limites :

- Les 18 nouvelles langues sont des premieres passes automatiques; elles exigent une relecture communautaire/native.
- Les textes visibles hors catalogue restent nombreux dans Mail, Hacking, Trading, Wallet, context menus, evenements et certaines TimedActions.
- Le boot PC peut rester en anglais par choix artistique, mais erreurs, boutons, objectifs et feedback joueur doivent etre traduits.
- Les UIs autres que Request et certains ecrans Betting n'ont pas toutes une zone scrollable adaptee aux textes longs.
- Les symboles de cartes dependent de la police chargee par PZ; le fallback ASCII doit rester disponible.

Commandes utiles :

```bash
lua5.1 tools/check_translations.lua
perl tools/generate_translations.pl --locale DE --force
bash tools/audit_hardcoded_text.sh
```

## 9. Audit manette et split-screen

Etat : **non implemente de maniere systematique**.

Travail restant :

- Definir un focus initial dans chaque fenetre.
- Construire l'ordre de navigation D-pad/stick entre boutons et listes.
- Mapper Back/B a fermeture ou retour.
- Rendre les listes scrollables au controller.
- Remplacer ou accompagner les champs numeriques par presets/steppers.
- Verifier le clavier virtuel pour Hacking, Trading, Betting et Request.
- Tester deux joueurs locaux et verifier qu'aucune UI ne reprend le joueur 0.

Ce chantier peut etre annonce comme limitation de la 1.0.0, mais une compatibilite manette complete ne doit pas etre revendiquee avant test.

## 10. Checklist de tests manuels

### Solo B42.20.0

- [ ] Nouveau personnage : ordinateur, connexion, fermeture/reouverture et sauvegarde.
- [ ] ATM : depot/retrait, reserve locale, limites, reconnexion et reload save.
- [ ] Dark Web : offre, achat, perte, livraison, vente et encaissement.
- [ ] Trading : snapshot, achat, vente et Wallet apres plusieurs jours monde.
- [ ] Hacking : no card, manuel, six echecs, auto, transfert et restart.
- [ ] Jouer les 12 contrats, annuler et completer chaque type.
- [ ] Verifier les 37 packages, 22 cargos, 16 manhunts, 7 protects par echantillonnage en jeu.
- [ ] Requests items et les 36 emplacements vehicules.
- [ ] Mails ammo/medical, accept/delete/complete/missing items.
- [ ] Blackjack : win/lose/push/blackjack et fermeture.
- [ ] Course : win/lose, mise invalide et fermeture.
- [ ] Poker : chaque lobby, fold/call/raise/all-in, side pot, next hand, cashout et fermeture.
- [ ] Charger EN, FR, DE, RU, TH, JP, KO, CN et CH pour verifier glyphes/debordements.

### MP serveur dedie

- [ ] Deux joueurs sur le meme ATM avec retraits simultanes.
- [ ] Deux joueurs voient exactement les memes prix Trading.
- [ ] Achat/vente Trading puis reconnexion et redemarrage serveur.
- [ ] Dark Web : livraison apres reconnexion et tentative de commande distante forgee.
- [ ] Contrat global : meme board, objectif vole et livre par un autre joueur.
- [ ] Tester les tags objectif apres unload/reload du chunk.
- [ ] Tester ContractComplete legitime et commande forgee.
- [ ] Tester ContractAccept forge avec location/Z/info modifies; le serveur doit les ignorer.
- [ ] Forger chaque evenement contrat (`zombieKilled`, spawn, package, cargo, protect, decapitate, blood, capture) a distance ou avec une mauvaise reference; le serveur doit refuser sans mutation.
- [ ] Requests : double clic, retry, livraison distante et double spawn vehicule.
- [ ] Mails : completion simultanee et commande distante.
- [ ] Redemarrage pendant Blackjack, Hacking et Poker; verifier remboursement exact.
- [ ] Deux sessions Poker simultanees sans fuite de cartes/stack.

### Controller/split-screen

- [ ] Focus initial et fermeture de chaque UI.
- [ ] Navigation de toutes les actions sans souris.
- [ ] Scroll des listes et RichTextPanels.
- [ ] Saisie numerique/texte avec clavier virtuel.
- [ ] Deux joueurs locaux avec soldes, contrats et UI independants.

## 11. Todo avant release 1.0.0

### P0 - Bloquant

- [x] Rendre `PZLinuxContractsApplyAccept` totalement serveur-autoritatif : seul `contractId` vient du client.
- [x] Durcir tous les evenements monde contrats : resolution d'entite, proximite/Z, tag, etat canonique, comptage des kills et suppression cote serveur.
- [ ] Tester la completion de contrat legitime et forgee sur serveur dedie.
- [ ] Executer un cycle MP deux joueurs complet sur ATM, Trading, Dark Web, contrats et Requests.

### P1 - Securite et economie

- [x] Ajouter validation serveur d'une mailbox et de la distance pour Dark Web, Request, encaissement et depot contrat.
- [x] Garder le password Hacking dans la session serveur et ne renvoyer que sa longueur et le feedback de tentative.
- [ ] Tester les rollbacks Blackjack/Hacking/Poker apres redemarrage reel.
- [ ] Rebalancer les rewards mails par tiers.
- [ ] Simuler et corriger l'esperance des courses.
- [x] Ajouter une commission Trading serveur de 5 % par transaction.
- [ ] Ajouter cooldown ou rendements decroissants Hacking.

### P2 - Maintenabilite

- [x] Extraire Dark Web data/runtime, Trading data et economie.
- [x] Extraire contrats, demandes de contrats, Requests, Poker et locations.
- [x] Mutualiser les dialogues contrats et retirer `RetrievePackage.lua`.
- [ ] Extraire Mail rewards/runtime hors `ISPZLinuxVariablesTables.lua`.
- [ ] Extraire banque/ATM, betting et Hacking par domaine.
- [ ] Resoudre les deux definitions globales Trading en doublon.
- [ ] Corriger W411 Wallet et W311 Mail, puis W211/W431.
- [ ] Renommer les classes UI et TimedActions non prefixees par lots.

### P3 - Traductions et accessibilite

- [x] Creer 20 catalogues synchronises et le validateur automatique.
- [x] Rendre Request scrollable et migrer ses dialogues principaux.
- [x] Rendre les descriptions de locations traduisibles.
- [ ] Trier les 1927 candidats et migrer tous les textes visibles restants.
- [ ] Faire relire les 18 traductions automatiques.
- [ ] Tester textes longs et glyphes sur les langues representatives.
- [ ] Implementer la navigation manette et tester split-screen.

### P4 - Finition release

- [ ] Completer les villes/pools encore vides si la couverture geographique est souhaitee.
- [ ] Nettoyer les 113 warnings Luacheck ou documenter les exceptions acceptees.
- [ ] Relancer syntaxe, Luacheck, assets, locations, traductions et Poker apres le dernier patch.
- [ ] Mettre a jour README/Workshop, compatibilite B42.20.0 et limitations manette.
- [ ] Faire une sauvegarde longue, une reconnexion et un redemarrage serveur avant publication.

## 12. Roadmap et idees futures

Cette section fusionne l'ancienne `doc/roadmap.md`. Elle distingue les travaux necessaires a la 1.0.0 des extensions qui pourront etre developpees sans retarder la release.

Legende :

- `[x]` socle implemente.
- `[ ]` idee retenue ou a concevoir.
- `[?]` decision de gameplay encore necessaire avant implementation.

### Version 1.0.0 - stabilisation et finition

- [ ] Rendre les interfaces compatibles manette et split-screen; suivre les controles detailles des sections 9, 10 et 11.
- [ ] Ajouter un message de bienvenue lors de la premiere connexion a PZLinux, avec un flag persistant par joueur pour ne pas le rejouer.
- [ ] Ecrire le lore minimal de la 1.0.0 : origine du reseau, societes de Trading, contrats, Dark Web et coherence des mails.
- [x] Limiter la reserve initiale d'un ATM entre `$10 000` et `$50 000` et la persister en solo/MP.
- [x] Ajouter une reputation par contrat, calculee notamment depuis la difficulte, puis la faire diminuer avec le temps.
- [ ] Relier concretement la reputation aux avantages, prix Dark Web, qualite des offres et penalites d'annulation; calibrer et expliquer les seuils au joueur.
- [ ] Completer les options Sandbox pour les valeurs d'equilibrage importantes : commission Trading, reserves ATM, rewards, reputation, cooldowns et multiplicateurs de prix.

### Version 1.1 - economie et services PZLinux

- [ ] Ajouter un panier Request personnalisable : le joueur choisit plusieurs articles et quantites, recoit un devis serveur, confirme puis attend la livraison.
- [ ] Ajouter un point de depot libre de ressources. Le serveur identifie les items deposes, retire les quantites et calcule leur valeur depuis une allowlist economique.
- [ ] Ajouter les matieres premieres au Trading, avec prix saisonniers ou mensuels et historique global commun a tous les joueurs.
- [ ] Faire de la connexion radio un moyen d'acces ou de communication avec PZLinux.
- [ ] Ajouter une solution satellite pour obtenir Internet sur un ordinateur, avec objet requis, alimentation et condition d'installation.
- [?] Definir la regle « cargo brule » : echec automatique du contrat, livraison partielle interdite, ou compensation possible selon l'etat du cargo.
- [ ] Limiter le piratage de carte bancaire a un ATM proche et a trois tentatives validees par le serveur.

### Version 1.1 - nouveaux contrats

- [ ] Station radio : activer une diffusion qui attire des zombies dans la zone pendant une duree donnee.
- [ ] Livraison chronometree : recuperer puis remettre des items avant l'expiration du contrat.
- [ ] Recuperation piegee : utiliser un ordinateur avec une chance d'alarme et de horde serveur.
- [ ] Logistique : livrer `200 L` de carburant ou d'eau en tenant compte des capacites reelles des conteneurs.
- [ ] Reapprovisionner un ATM avec une somme imposee, sans permettre de dupliquer le cash ou la reserve ATM.
- [ ] Livrer un vehicule dans une zone precise; valider cote serveur l'identite, la position, l'etat et les eventuels objets requis.
- [ ] Contrat a forte angoisse : declencher une horde en contrepartie d'un loot rare apportant un avantage temporaire de survie.

### Version 1.2 et au-dela - quetes narratives

- [ ] Trouver un objet rare, par exemple un grand Spiffo ou un masque a gaz.
- [ ] Recuperer des documents chez un medecin ou dans un autre lieu thematique.
- [ ] Retrouver un coursier mort et decider de livrer ou garder son colis.
- [ ] Livrer de l'eau potable avec controle de quantite et de contamination.
- [ ] Transporter et livrer des animaux en s'appuyant sur les API Build 42 et une validation serveur adaptee.

### Principes communs aux futures features

- Le serveur choisit ou valide les objectifs, prix, quantites, timers, spawns et rewards; le client ne transmet que l'intention et les identifiants necessaires.
- Toute nouvelle mission utilise `PZLinuxMissionLocations`, des IDs persistants et des pools par ville plutot que des coordonnees inline dans l'UI.
- Toute mutation economique est atomique, idempotente et compatible solo via le meme coeur partage.
- Les nouveaux textes visibles utilisent les catalogues `IG_UI` des leur creation et l'UI supporte textes longs, glyphes et controller.
- Chaque feature recoit au minimum un test Lua hors-jeu pour ses calculs et un scenario manuel solo/MP/restart dans cet audit.

## 13. Commandes de validation

```bash
bash tools/run_static_audit.sh
find "Contents/mods/B42 PZLinux/42/media/lua" -type f -name '*.lua' -print0 | xargs -0 -n1 luac5.1 -p
luacheck --config tools/.luacheckrc "Contents/mods/B42 PZLinux/42/media/lua"
bash tools/audit_function_prefixes.sh
bash tools/audit_hardcoded_text.sh
bash tools/audit_assets.sh
lua5.1 tools/audit_locations.lua
lua5.1 tools/check_translations.lua
lua5.1 tools/test_poker_engine.lua
lua5.1 tools/test_contract_authority.lua
lua5.1 tools/test_contract_world_authority.lua
lua5.1 tools/test_hacking_authority.lua
lua5.1 tools/test_mailbox_proximity.lua
lua5.1 tools/test_darkweb_delivery.lua
lua5.1 tools/test_trading_fee.lua
```

## 14. Decision de release

La base solo est suffisamment avancee pour poursuivre les tests de release. Les controles mailbox, les objectifs de contrats et le secret Hacking sont maintenant serveur-autoritatifs dans le code; la mention **100 % serveur-autoritatif** doit encore attendre les essais a deux clients et les tests de redemarrage.

Ordre conseille pour la prochaine passe :

1. Tests MP/restart, dont ContractAccept, objectifs monde et commandes mailbox forges.
2. Economie Mail/Trading/Race/Hacking.
3. Traductions visibles restantes et relecture.
4. Namespace, Luacheck, controller et finition Workshop.
