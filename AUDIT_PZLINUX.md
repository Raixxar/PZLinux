# Audit technique complet PZLinux - preparation v1.0.0

Date : 2026-08-01

Cible : Project Zomboid Build 42.20.0 Stable

Branche auditee : `dev/release-v1.0.0`

Perimetre : depot local complet, code Lua client/server/shared, donnees, economie,
missions, persistance, securite MP, traductions, interfaces, assets, outils et
documentation de publication.

## 1. Resume executif

PZLinux est une **release candidate avancee**. Le socle solo est jouable et les
principaux flux multijoueurs ne reposent plus sur la confiance accordee au client.
Banque, ATM, Dark Web, Trading, contrats, Requests, Mails, Hacking, Blackjack,
Zombie Race et Poker possedent un coeur serveur en MP et reutilisent le meme coeur
local en solo.

L'audit statique ne met plus en evidence de P0 exploitable connu permettant a un
client de choisir librement un paiement, un prix, une location de contrat ou un
objectif monde. Les commandes sensibles sont prefixees, dispatches par le module
`PZLinux`, validees par domaine et protegees contre la repetition d'un meme
`requestId`.

Le mod ne doit toutefois pas encore etre presente comme « MP complet » ou pret pour
un grand serveur public. Le verrou principal n'est plus une faiblesse evidente du
code : c'est l'absence d'une campagne reproductible sur serveur dedie avec deux
clients, reconnexion, concurrence, objectifs voles, unload/reload de chunks et
redemarrage au milieu des transactions.

| Cible | Verdict | Motif |
| --- | --- | --- |
| Solo B42.20 | Release candidate | Retest final des 12 contrats et d'une sauvegarde longue requis |
| Serveur heberge | Fonctionnel avec reserves | Plusieurs flux ont ete testes en direct et corriges, mais pas toute la matrice |
| Serveur dedie | Non certifie production | Pas de campagne complete deux clients/restart documentee |
| Securite MP statique | Bonne base | Aucun P0 connu; tests de commandes forgees encore necessaires |
| Traductions | Infrastructure valide, contenu incomplet | 20 catalogues synchronises, textes hardcodes et qualite linguistique a reprendre |
| Split-screen | Non garanti | Reponses reseau generiques encore appliquees au joueur local par defaut |
| Manette | Non supportee officiellement | Aucun parcours de focus/navigation complet |

### Decision de release

La v1.0.0 peut entrer en phase de **release candidate testable**. Une publication
publique raisonnable demande au minimum :

1. une campagne MP a deux joueurs sur serveur dedie ;
2. les tests de reconnexion et rollback apres redemarrage ;
3. les tests finaux des limitations split-screen et manette deja annoncees ;
4. un passage d'equilibrage sur les cadeaux Mail et le bonus du contrat Package.

Il n'est pas necessaire de corriger les 110 warnings Luacheck avant la release. Les
deux warnings fonctionnels W411/W311 doivent etre examines; les shadowings UI et le
whitespace peuvent etre traites ensuite.

## 2. Mesures du depot

Resultats mesures le 2026-08-01 :

| Mesure | Resultat |
| --- | ---: |
| Fichiers Lua | 56 |
| Lignes Lua | 16 642 |
| Fichiers media/mod | 117 |
| Taille du mod | 7,4 MiB |
| Catalogues `IG_UI.json` | 20 |
| Cles par catalogue | 299 |
| Modules de tests Lua | 9 |
| Warnings Luacheck | 110 |
| Erreurs Luacheck | 0 |
| Fonctions/declarations non prefixees (heuristique) | 276 |
| Textes hardcodes candidats (heuristique large) | 1 983 |
| Appels directs `getPlayer()` hors helper central | 0 |
| Noms de fonctions globales dupliques | 2 |

Le fichier [ISPZLinuxVariablesTables.lua](Contents/mods/B42%20PZLinux/42/media/lua/shared/ISPZLinuxVariablesTables.lua)
mesure encore 3 753 lignes. Les donnees les plus volumineuses ont ete extraites,
mais ce fichier reste le runtime central pour banque, ATM, jeux, callbacks reseau,
contrats, Requests, Mails et Hacking.

## 3. Resultats automatiques

| Controle | Resultat | Commentaire |
| --- | --- | --- |
| Syntaxe Lua 5.1, 56 fichiers | OK | Aucun parse error |
| Luacheck complet | 110 warnings / 0 errors | La commande globale retourne non-zero a cause des warnings |
| Audit statique P0 historique | OK | `Pric2`, debug force, index contrat 7 et helper Mail duplique absents |
| Assets ImageMagick/FFprobe | OK | PNG/JPG/OGG/WAV lisibles |
| Locations B42.20 | OK | IDs, coordonnees et entrees activees valides |
| Traductions | OK structurel | 20 langues, 299 cles et placeholders identiques |
| Autorite contrats | OK | 12 missions canoniques et dialogues couverts |
| Autorite objectifs contrats | OK | Evenements interdits et validations monde couverts statiquement |
| Livraison Dark Web | OK | Creation, synchronisation inventaire et retry |
| Proximite Mailbox | OK | Objet, distance et niveau Z |
| Secret Hacking | OK | Mot de passe absent des reponses client |
| Trading fee | OK | Commission serveur de 5 % |
| Poker engine | OK | Evaluation, actions, side pots et sessions |
| Zombie Race settlement | OK | Paiement uniquement apres fin de course |
| Typing | OK | UTF-8, profils et timing partage |

Ces tests sont des tests Lua hors-jeu et des assertions statiques. Ils ne remplacent
pas le moteur Project Zomboid, le streaming des chunks, les paquets conteneur, les
timed actions, ni deux clients reels.

### Repartition Luacheck

| Code | Nombre | Risque | Action |
| --- | ---: | --- | --- |
| W432 | 47 | Faible | Shadowing `self` dans closures UI historiques |
| W611 | 20 | Aucun fonctionnel | Lignes contenant du whitespace |
| W211 | 12 | Faible/moyen | Variables locales inutilisees |
| W612 | 8 | Aucun fonctionnel | Trailing whitespace |
| W613 | 6 | A verifier | Espaces dans des strings, parfois volontaires |
| W581 | 5 | Faible | Expressions booleennes simplifiables |
| W614 | 4 | Aucun fonctionnel | Whitespace dans commentaires |
| W213 | 4 | Faible | Variables de boucle inutilisees |
| W431 | 2 | Moyen | Shadowing d'upvalue |
| W411 | 1 | Moyen | Variable redefinie dans Wallet |
| W311 | 1 | Moyen | Affectation inutilisee dans Mail |

Priorite de correction conseillee : W411, W311, W211, W431, puis nettoyage du
reste sans modifier les strings de dialogue aveuglement.

## 4. Architecture actuelle

```text
Contents/mods/B42 PZLinux/
  common/                         metadonnees communes
  42/
    mod.info
    media/
      lua/client/Context/World/   UI, menus et interactions locales
      lua/server/                 dispatch serveur des commandes MP
      lua/shared/TimedActions/    timed actions Project Zomboid
      lua/shared/PZLinux/         donnees et moteurs partages par domaine
      lua/shared/Translate/       catalogues IG_UI/Sandbox
      lua/shared/ISPZLinuxVariablesTables.lua
      sandbox-options.txt
      scripts/                    definitions sons
      sound/ et ui/               assets
tools/                            audits, tests et suivi console
doc/                              release notes, FAQ et presentation
```

Modules partages deja extraits :

- `PZLinuxConfig.lua`
- `PZLinuxContractMission.lua`
- `PZLinuxContractRequestData.lua`
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
- `PZLinuxTyping.lua`
- `PZLinuxWorldInteractions.lua`

### Dette architecturale principale

- `ISPZLinuxVariablesTables.lua` reste un point de couplage tres important.
- Les domaines Mail, banque/ATM, Blackjack/Race et Hacking peuvent encore etre
  extraits sans changer leurs APIs publiques.
- Les callbacks reseau sont stockes dans `PZLinux.callbacks` sans timeout. Une
  reponse perdue laisse un callback en memoire jusqu'au redemarrage/reload Lua.
- Le cache d'idempotence serveur est volontairement en memoire, limite a 128
  entrees par joueur et deux heures monde.
- Les fonctions `PZLinuxTrading_initializePrices` et
  `PZLinuxUpdateTradingPrices` sont encore definies dans le shared et le client.
  Le comportement actuel sert de wrapper, mais l'ecrasement depend de l'ordre de
  chargement et doit etre supprime avant une maintenance longue.

## 5. Etat fonctionnel

| Domaine | Solo | MP code | Persistance/restart | Etat restant |
| --- | --- | --- | --- | --- |
| Ordinateur/Internet | Oui | Player explicite dans les UI | Player ModData | Pause, split-screen, manette |
| Banque | Oui | Serveur | Player ModData | Crash entre mutation et persistance |
| ATM | Oui | Serveur, reserve atomique | ATM object + joueur | Concurrence deux joueurs |
| Dark Web achats | Oui | Offres/prix/debit serveur | Pending orders | Reconnexion et mailbox distante forgee |
| Dark Web ventes | Oui | Inventaire et credit serveur | Pending sales | Double redemption/concurrence live |
| Trading/Wallet | Oui | Prix globaux serveur | Global + Player ModData | Restart et wrappers dupliques |
| Contrats board | Oui | Board global serveur | Global ModData | Rotation/concurrence live |
| Contrats preview/accept | Oui | Mission canonique serveur | Cache + World ModData | Reconnexion et offre prise par autre joueur |
| Objectifs contrats | Oui | Entites/tags/proximite serveur | Monde + Global ModData | Streaming chunk et vol live |
| Completion contrats | Oui | Reward et reputation serveur | Player + World ModData | Crash consistency et commandes forgees live |
| Requests items | Oui | Prix/debit/livraison serveur | Pending Player ModData | Reconnexion/double clic |
| Requests vehicules | Oui | Spawn serveur | Pending puis monde | Chunk indisponible/double spawn live |
| Mails | Oui | Generation/retrait/reward serveur | Player ModData | Equilibrage reward et traductions |
| Hacking | Oui | Secret et transfert serveur | Rollback cartes | Cooldown et restart live |
| Blackjack | Oui | Deck/payout serveur | Refund mise interrompue | Restart live |
| Zombie Race | Oui | Resultat/payout serveur | Refund mise interrompue | Esperance mathematique |
| Poker | Oui | Session/IA/actions serveur | Rollback stack/cashout | Deux sessions MP et restart live |
| Traductions | Partiel | Identique | Fichiers statiques | Textes visibles et relecture native |
| Split-screen | Partiel | Non garanti | n/a | Routage reponses vers joueur 0 |
| Manette | Non | n/a | n/a | Navigation complete a implementer |

## 6. Autorite serveur et securite MP

### Protections en place

- Toutes les commandes serveur sont sous le module `PZLinux`.
- Les noms de commandes reseau sont prefixes `PZLinux*`.
- Chaque handler serveur passe par `PZLinuxServerProcessIdempotent`.
- Le joueur est fourni par Project Zomboid au handler serveur; le client ne choisit
  pas l'objet joueur a muter.
- Banque, prix, rewards, quantites et soldes sont recalcules ou lus cote serveur.
- ATM et mailboxes sont resolus depuis une reference monde puis controles en
  distance et niveau Z.
- Le client n'envoie que `contractId` pour accepter un contrat.
- Location, Z, cible, item, quantite, reward et note sont generes cote serveur.
- Les objectifs monde utilisent `PZLinuxContractId`, un statut global et des tags
  persistants lorsque l'API de l'entite le permet.
- Cargo, Manhunt, Blood, Capture et Protect resolvent une entite reelle cote
  serveur avant mutation.
- Kill/Protect/Blood utilisent `Events.OnZombieDead` serveur et le dernier
  attaquant, pas un compteur fourni par le client.
- `zombieKilled` et `clearCargo` envoyes par un client sont explicitement refuses.
- Le mot de passe Hacking ne quitte pas la session serveur.
- Poker ne transmet pas les cartes IA masquees ni leur niveau avant revelation.
- Les mises temporaires Blackjack/Race, cartes Hacking et stack Poker disposent
  d'une donnee de rollback persistante.

### Points de vigilance restants

#### P1 - Split-screen et routage des reponses

Le listener `Events.OnServerCommand` applique encore les soldes et etats contrats
generiques avec `PZLinuxGetPlayer()` sans index. Sur un client split-screen, cela
peut mettre a jour le joueur 0 alors que la requete appartenait au joueur 1. Les UI
passent majoritairement un joueur explicite, mais le bus de reponse ne conserve pas
encore cette association.

Correction attendue : stocker `playerNum` avec chaque callback/requestId et
resoudre le bon joueur lors de la reponse, ou laisser exclusivement le callback
metier appliquer l'etat au joueur capture.

#### P1 - Crash consistency

L'idempotence evite un resend dans un serveur qui continue de tourner, mais son
cache n'est pas persistant. Plusieurs operations effectuent successivement debit ou
credit, mise a jour d'etat, puis transmission ModData. Un arret brutal exactement
entre ces etapes peut produire une fenetre de double paiement, de perte ou de
rollback rejoue.

Ce risque est faible en frequence mais important economiquement. Il faut tester en
tuant volontairement le serveur pendant :

- `ContractComplete` apres credit ;
- un achat/livraison Dark Web ;
- un cashout Poker ;
- l'application d'un rollback interrompu.

Une vraie correction demanderait un journal persistant de transaction ou un statut
`pending/applied` durable par operation economique critique.

#### P2 - Rate limiting

L'idempotence ne limite pas un client qui fabrique toujours de nouveaux
`requestId`. Les validations empechent les gains illegitimes connus, mais un client
peut spammer sync, preview, mail generation ou actions invalides. Ajouter un petit
rate limit par joueur/commande reduirait le bruit serveur et les risques de DoS.

#### P3 - Endpoint banque generique

`PZLinuxBankDebit` accepte encore un montant et une raison client. Il ne permet que
de retirer l'argent du joueur emetteur et ne constitue pas un cheat rentable connu,
mais les domaines majeurs debitent deja directement cote serveur. Cette surface
generique devrait etre reservee a une allowlist de raisons ou retiree si elle n'est
plus necessaire.

## 7. Contrats et locations

### Etat des 12 contrats

- Les 12 definitions sont generees par `PZLinuxContractsBuildMission`.
- Les contrats avec location ne tirent que parmi les villes disposant d'un point
  actif dans leur pool.
- Les introductions des 12 conversations s'affichent immediatement.
- Les reponses suivantes utilisent le profil partage de 1,8 a 4,2 secondes.
- Les dialogues continuent avec `OnTickEvenPaused` et sont nettoyes a la fermeture.
- Une preview refusee n'affiche plus un ecran vide : l'offre reste visible et le
  code d'erreur est traduit.
- Un contrat n'est retire du board qu'apres acceptation serveur.
- La notification de completion est idempotente par joueur et
  `PZLinuxContractId`; un clic droit/sync ne rejoue plus son, halo et effets humeur.
- Le depot mailbox retire et synchronise l'item cote serveur.

### Pools B42.20 valides

| Pool | Nombre | Couverture |
| --- | ---: | --- |
| packages | 37 | 9 villes |
| cargo | 22 | 8 villes |
| manhunt | 16 | 7 villes |
| protect | 7 | 3 villes |
| vehicles | 36 | 8 villes |
| mailDrops.ammo | 37 | Reutilise packages |
| mailDrops.medical | 37 | Reutilise packages |

La structure est robuste, mais la distribution geographique reste volontairement
inegale : Fallas Lake et Valley Station n'ont aucun point actif; Ekron est surtout
couvert par Protect; Coalfield par Package/Cargo.

### Point d'equilibrage important

`PZLinuxContractsGiveContractCase` contient encore un bonus aleatoire :

- 1 chance sur 5 environ de recevoir un revolver ;
- le meilleur tirage ajoute aussi jusqu'a 1 999 billets.

Le joueur peut potentiellement vider le contenu avant de renvoyer la valise. Ce
bonus est tres eleve pour un contrat Package deja remunere et doit etre supprime,
plafonne ou integre explicitement au calcul du reward.

## 8. Economie et progression

### Points positifs

- Les prix Dark Web puissants ont ete releves.
- Les Requests sont un service de confort couteux et non une source de loot gratuit.
- La remise PlantScavenging est plafonnee a 15 %.
- Trading applique 5 % de fee serveur sur achats et ventes.
- Les contrats faciles paient moins que les objectifs dangereux.
- Le niveau Z ajoute 5 % de reward par etage absolu, sur un Z choisi par le serveur.
- La reputation est attribuee cote serveur et decroit dans le temps.
- Les soldes ATM sont limites et persistants.
- Le bonus cash Mail est limite a 100-300 dollars.

### Risques d'equilibrage

#### P1 - Cadeaux Mail

`PZLinuxMailGiveReward` tire encore entre 1 et 5 objets dans l'ensemble de
`PZLinuxDarkWebItemsTable`. Le tirage peut donc fournir un objet end-game, puis
ajouter un revolver. Le plafonnement cash ne suffit pas a controler la puissance du
cadeau.

Correction recommandee : trois tiers de reward avec allowlists et poids, lies a la
difficulte/quantite du Mail et a la reputation.

#### P1 - Bonus Package

Le revolver et les 1 999 billets possibles dans la valise de contrat contournent
l'equilibrage normal des rewards.

#### P2 - Hacking

Le Hacking reste une source de cash repetable sans cooldown serveur long ni
rendement decroissant documente.

#### P2 - Zombie Race

Le settlement est correct, mais aucune simulation statistique massive ne prouve
encore que les cotes donnent une esperance joueur negative et raisonnable.

#### P2 - Reputation

La reputation existe et decroit, mais son impact concret sur Dark Web/deals reste
moins visible que son infrastructure. Les seuils et avantages doivent etre mesures
sur une partie longue.

## 9. Traductions et UI

### Infrastructure

- 20 catalogues `IG_UI.json` valides en UTF-8.
- 299 cles identiques par langue.
- Controle automatique des doublons, cles et placeholders `%s`/`<name>`.
- Request utilise un `ISRichTextPanel` fixe, wrappe, scrollable et auto-scroll.
- Les descriptions de locations utilisent des cles traduisibles et un fallback.
- Poker/Blackjack ont ete ajustes au CRT avec cartes, table et actions compactes.
- Les symboles de cartes utilisent des textures rouge/noir, evitant les limites de
  glyphes de `ISLabel`.

### Limites

- L'audit large trouve 1 983 strings candidates hors catalogues.
- 204 motifs visibles simples restent notamment dans boutons, labels, halos et
  menus; ce chiffre contient encore des faux positifs.
- 16 `context:addOption` sont encore ecrits en dur.
- `Sandbox.json` n'existe qu'en anglais.
- Les catalogues automatiques ont des erreurs semantiques visibles. Exemple :
  `ALL-IN` est traduit par `TODO INCLUIDO` en espagnol et `TUDO INCLUIDO` en
  portugais au lieu du terme de poker.
- Plusieurs textes de Mail, context menus, feedbacks et notes de contrat restent en
  anglais.
- Le boot du PC peut rester en anglais par choix de lore; les commandes et erreurs
  joueur doivent etre traduites.

Avant release, migrer en priorite : context menus, erreurs reseau, confirmation des
transactions, etapes de contrats, Mail et Hacking. Une relecture native ou
communautaire est indispensable pour les 18 catalogues generes.

## 10. Namespace et compatibilite autres mods

### Etat

- Les commandes reseau critiques sont prefixees.
- Les nouveaux moteurs partages utilisent majoritairement `PZLinux*`.
- Aucun appel direct `getPlayer()` ne reste hors helper central selon l'audit.
- 276 declarations heuristiques ne commencent toujours pas par `PZLinux`.
- 26 classes UI/TimedActions globales restent non prefixees.
- Plusieurs callbacks d'evenements restent globaux et non prefixes.

Les 276 entrees ne sont pas 276 bugs : une grande partie sont des methodes de
classes historiques comme `AtmUI:on...`. Le vrai risque concerne les racines de
classes et fonctions globales : `AtmUI`, `linuxUI`, `MailBoxUI`,
`ISBloodAction`, `isNearTarget`, `generatePseudo`, etc.

Migration conseillee : domaine par domaine, avec renommage de la classe, de sa
chaine `derive`, de toutes les references et event callbacks dans le meme patch.
Eviter un remplacement global massif avant la 1.0.0.

## 11. Manette, clavier et split-screen

### Manette

Etat : **non implemente systematiquement**.

- Aucun `onGainJoypadFocus`/`onJoypad...` n'est present dans le mod.
- Les champs de mise, quantite, mot de passe et prix supposent clavier/souris.
- Les listes n'ont pas d'ordre de focus controller commun.
- Back/B n'est pas mappe de facon coherente.
- Le clavier virtuel n'est pas teste.

La v1.0.0 peut sortir avec cette limitation annoncee. Elle ne doit pas revendiquer
la compatibilite manette avant implementation et test.

### Split-screen

Les UI utilisent beaucoup mieux le joueur transmis par PZ, mais le listener reseau
commun reste centre sur `PZLinuxGetPlayer()` sans index. La compatibilite
split-screen complete ne doit pas etre annoncee avant correction et test de deux
joueurs locaux.

## 12. Metadonnees et packaging release

Etat : **metadonnees v1.0.0 harmonisees**.

- `README.md`, `workshop.txt` et `doc/overview.md` presentent PZLinux 1.0.0 sans
  marqueur BETA ou version 0.1.x.
- `workshop.txt` conserve correctement `version=1`, qui designe la version du
  format Workshop et non celle du mod.
- Le `mod.info` versionne declare `modversion=1.0.0`, `versionMin=42.20`, la
  categorie `features` et les compatibilites/limitations principales.
- Le doublon `common/mod.info` a ete supprime. Le dossier `common` reste present,
  comme l'exige la structure Build 42.
- L'ID historique `B42_PZLinux` est conserve pour ne pas casser sauvegardes,
  abonnements et configurations serveur.
- La description Workshop couvre Poker, Blackjack, l'autorite serveur, les 20
  catalogues de traduction et les limitations manette/split-screen.
- `tools/check_release_metadata.lua` empeche le retour accidentel de BETA, d'une
  version 0.1.x ou d'un second `mod.info`.
- Plusieurs scripts `.sh` dans `tools/` sont suivis en mode `100644`; `./tools/...`
  echoue avec « Permission denied ». Ils fonctionnent avec `bash tools/...`.

Avant tag, il reste seulement a rendre les outils shell executables si l'usage direct
est souhaite et a valider les captures definitives du Workshop.

## 13. Checklist de tests manuels

### Solo B42.20

- [ ] Nouvelle sauvegarde : ordinateur, Internet, fermeture et reouverture.
- [ ] Sauvegarde existante pre-v1 : migration sans perte banque/contrat/mail.
- [ ] ATM : depot, retrait, reserve, manque de cash et reload save.
- [ ] Dark Web : achat, perte, livraison, vente, redemption et reconnexion.
- [ ] Trading : snapshot, achat, vente, Wallet et progression sur plusieurs jours.
- [ ] Jouer, annuler et completer les 12 contrats.
- [ ] Verifier qu'une sync/clic droit ne rejoue plus la completion d'un contrat.
- [ ] Echantillonner packages, cargo, manhunt, protect et vehicules B42.20.
- [ ] Requests item/vehicule, double clic et chunk temporairement indisponible.
- [ ] Mails ammo/medical, accept/delete/complete et inventaire insuffisant.
- [ ] Hacking manuel/auto, lock, transfert et restart.
- [ ] Blackjack win/lose/push/blackjack et fermeture en cours de partie.
- [ ] Zombie Race win/lose, animation puis paiement final.
- [ ] Poker : cinq joueurs, eliminations, duel final, side pot et cashout.
- [ ] Tester EN, FR, DE, RU, TH, JP, KO, CN et CH sur les UI principales.

### MP serveur dedie, deux clients

- [ ] Meme solde apres sync/reconnexion pour chaque joueur.
- [ ] Deux depots/retraits simultanes sur le meme ATM.
- [ ] Meme snapshot/prix Trading pour les deux joueurs.
- [ ] Trading simultane et fee 5 % apres redemarrage.
- [ ] Dark Web : achat, reconnexion, livraison et redemption par le bon joueur.
- [ ] Commandes mailbox forgees a distance/mauvais Z refusees.
- [ ] Meme board de contrats pour les deux joueurs.
- [ ] Offre acceptee simultanement : un seul gagnant, board resynchronise.
- [ ] Objectif Package/Cargo/Manhunt vole et livre par un autre joueur.
- [ ] Unload/reload chunk conserve tags et statut d'objectif.
- [ ] ContractAccept forge avec location/Z/reward/info ignores.
- [ ] ContractComplete forge refuse sans credit.
- [ ] Chaque event monde forge a distance/mauvaise entite refuse.
- [ ] Request vehicule ne spawn qu'une fois apres double commande/reconnexion.
- [ ] Mail complete simultane ne retire/reward qu'une fois.
- [ ] Deux Blackjack/Race/Poker simultanes sans fuite d'etat.
- [ ] Restart pendant Blackjack/Race/Hacking/Poker applique un rollback exact.
- [ ] Arret brutal pendant ContractComplete et cashout ne duplique pas le credit.

### Controller et split-screen

- [ ] Deux joueurs locaux conservent banque, callbacks et contrats independants.
- [ ] Une reponse serveur met a jour le bon joueur local.
- [ ] Focus initial sur chaque UI.
- [ ] Navigation complete sans souris.
- [ ] Scroll listes/RichTextPanel au D-pad ou stick.
- [ ] Saisie via clavier virtuel.
- [ ] Back/B ferme ou revient sans perdre une transaction.

## 14. Todo priorisee avant v1.0.0

### P0 - Gates de release

- [x] Retirer l'autorite client des prix, soldes, rewards et missions.
- [x] Durcir les mailboxes et objectifs monde par distance/Z/entite/statut.
- [x] Ne plus transmettre le mot de passe Hacking.
- [x] Ajouter l'idempotence par commande/requestId.
- [ ] Executer la campagne MP deux clients complete.
- [ ] Tester reconnexion, unload/reload chunk et redemarrage serveur.
- [ ] Tester les commandes forgees listees dans la checklist.
- [ ] Valider une sauvegarde pre-v1 et documenter la strategie de backup.

### P1 - Avant publication publique

- [x] Corriger le routage des reponses reseau en split-screen ou annoncer la
  limitation explicitement.
- [ ] Tester puis durcir les fenetres de crash des paiements critiques.
- [ ] Refaire les rewards Mail avec tiers/allowlists.
- [ ] Supprimer ou plafonner le revolver/cash du contrat Package.
- [x] Harmoniser `README.md`, `workshop.txt`, `overview.md` et `mod.info` en 1.0.0.
- [ ] Corriger les traductions automatiques manifestement erronees.

### P2 - Maintenabilite et robustesse

- [ ] Extraire Mail runtime/rewards hors `ISPZLinuxVariablesTables.lua`.
- [ ] Extraire banque/ATM, jeux et Hacking par domaine.
- [ ] Supprimer les deux wrappers Trading globaux dupliques.
- [ ] Ajouter timeout/nettoyage aux callbacks client sans reponse.
- [ ] Ajouter rate limit serveur par joueur/commande.
- [ ] Examiner W411 Wallet, W311 Mail, W211 et W431.
- [ ] Ajouter tests directs ATM, banque, Blackjack, Mail et Requests.
- [ ] Simuler au moins 100 000 Zombie Races et mesurer le RTP.
- [ ] Ajouter cooldown ou rendement decroissant Hacking.

### P3 - Traductions, namespace et accessibilite

- [ ] Migrer les textes visibles restants vers `IG_UI`.
- [ ] Creer les `Sandbox.json` manquants ou documenter le fallback anglais.
- [ ] Faire relire les 18 langues generees par des locuteurs.
- [ ] Renommer classes, TimedActions et globals non prefixes par domaine.
- [ ] Implementer la navigation manette.
- [ ] Completer et tester le split-screen.
- [ ] Completer Fallas Lake/Valley Station si une couverture totale est souhaitee.

### P4 - Finition

- [ ] Nettoyer les warnings Luacheck cosmetiques.
- [ ] Rendre les scripts `tools/*.sh` executables ou documenter `bash tools/...`.
- [ ] Ajouter un changelog 1.0.0 lisible a partir de `doc/release.md`.
- [ ] Mettre a jour les captures Workshop des nouvelles features.
- [ ] Faire une sauvegarde longue de plusieurs semaines monde.

## 15. Roadmap apres 1.0.0

### 1.1 - Economie et services

- Panier Request multi-items avec devis serveur.
- Depot libre de ressources via allowlist economique.
- Matieres premieres Trading et historique saisonnier.
- Acces PZLinux par radio ou satellite.
- Reputation reliee a des offres, prix et avantages explicites.
- Options Sandbox : fee, reserves ATM, rewards, reputation et cooldowns.

### 1.1 - Nouveaux contrats

- Station radio attirant une horde.
- Livraison chronometree.
- Recuperation piegee avec alarme serveur.
- Livraison de carburant/eau avec capacites reelles.
- Reapprovisionnement d'un ATM sans duplication de cash.
- Livraison d'un vehicule validee par identite/position/etat.

### 1.2 - Narratif

- Objets rares et documents thematiques.
- Coursier mort avec choix moral sur le colis.
- Livraison d'eau avec controle de contamination.
- Transport d'animaux avec API Build 42.

### Regles pour toute nouvelle feature

- Le serveur choisit ou valide prix, quantite, objectif, timer, spawn et reward.
- Le client envoie une intention et des references minimales.
- Toute mutation economique est idempotente et possede une strategie de restart.
- Toute mission utilise `PZLinuxMissionLocations` et un ID persistant.
- Tout texte visible nait dans `IG_UI` avec UI adaptee aux textes longs.
- Toute logique calculable hors-jeu recoit un test Lua.
- Toute feature recoit un scenario solo, MP, reconnexion et restart.

## 16. Commandes de validation

```bash
find "Contents/mods/B42 PZLinux/42/media/lua" -type f -name '*.lua' -print0 \
  | xargs -0 -n1 luac5.1 -p

luacheck --config tools/.luacheckrc \
  "Contents/mods/B42 PZLinux/42/media/lua"

bash tools/run_static_audit.sh
bash tools/audit_namespace.sh
bash tools/audit_function_prefixes.sh
bash tools/audit_hardcoded_text.sh
bash tools/audit_assets.sh

lua5.1 tools/audit_locations.lua
lua5.1 tools/check_translations.lua

for test_file in tools/test_*.lua; do
  lua5.1 "$test_file" . || exit 1
done
```

## 17. Conclusion

Le travail de migration a transforme PZLinux d'un mod essentiellement solo en un
mod disposant d'une architecture MP credible. Les flux economiques et missions les
plus sensibles sont maintenant serveur-autoritatifs dans le code, les erreurs
rencontrees en serveur heberge ont ete corrigees avec des tests de regression, et
la structure des donnees est nettement plus maintenable.

La prochaine etape utile n'est pas un nouveau grand refactor. Il faut figer les
features, executer la campagne MP/restart, corriger les deux rewards trop genereux,
regler les metadonnees de release et traiter uniquement les defauts observes. Une
fois ces gates franchies, PZLinux pourra raisonnablement quitter BETA pour une
v1.0.0, avec controller/split-screen annonces comme limitations si ces chantiers ne
sont pas termines.
