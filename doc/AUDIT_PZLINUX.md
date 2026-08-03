# Audit technique complet PZLinux - preparation v1.0.0

Date : 2026-08-02

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
| Securite MP statique | Bonne base | Aucun P0 connu; assertions de commandes forgees OK, campagne live encore necessaire |
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

Il n'est pas necessaire de corriger les 70 warnings Luacheck avant la release. Les
warnings restants sont principalement des shadowings UI historiques et quelques
expressions ou espaces contenus dans des chaines; ils peuvent etre traites ensuite.

## 2. Mesures du depot

Resultats mesures le 2026-08-01 :

| Mesure | Resultat |
| --- | ---: |
| Fichiers Lua | 59 |
| Lignes Lua | 17 056 |
| Fichiers media/mod | 122 |
| Taille du mod | 7,4 MiB |
| Catalogues `IG_UI.json` | 20 |
| Cles par catalogue | 314 |
| Modules de tests Lua | 15 |
| Warnings Luacheck | 70 |
| Erreurs Luacheck | 0 |
| Fonctions/declarations non prefixees (heuristique) | 277 |
| Textes hardcodes candidats (heuristique large) | 2 004 |
| Appels directs `getPlayer()` hors helper central | 0 |
| Noms de fonctions globales dupliques | 0 |

Le fichier [ISPZLinuxVariablesTables.lua](../Contents/mods/B42%20PZLinux/42/media/lua/shared/ISPZLinuxVariablesTables.lua)
mesure encore 3 783 lignes. Les donnees les plus volumineuses ont ete extraites,
mais ce fichier reste le runtime central pour banque, ATM, jeux, callbacks reseau,
contrats, Requests, Mails et Hacking.

## 3. Resultats automatiques

| Controle | Resultat | Commentaire |
| --- | --- | --- |
| Syntaxe Lua 5.1, 60 fichiers | OK | Aucun parse error |
| Luacheck complet | 52 warnings / 0 errors | La commande globale retourne non-zero a cause des warnings historiques hors fichiers modifies |
| Audit statique P0 historique | OK | `Pric2`, debug force, index contrat 7 et helper Mail duplique absents |
| Assets ImageMagick/FFprobe | OK | PNG/JPG/OGG/WAV lisibles |
| Locations B42.20 | OK | IDs, coordonnees et entrees activees valides |
| Traductions | OK structurel | 20 langues, 310 cles et placeholders identiques |
| Suite de regression Lua | OK | 16 modules executes avec succes |
| Stock Dark Web | OK | Paliers, renouvellement et concurrence sur le dernier exemplaire |
| Autorite contrats | OK | 12 missions canoniques et dialogues couverts |
| Autorite objectifs contrats | OK | Evenements interdits et validations monde couverts statiquement |
| Livraison Dark Web | OK | Creation, synchronisation inventaire et retry |
| Proximite Mailbox | OK | Objet, distance et niveau Z |
| Inventaire autoritaire | OK | Ajouts/retraits et paquets conteneur MP couverts |
| Inventaire ATM | OK | Sacs imbriques, bundles, monnaie et rollback couverts |
| Livraison Request | OK | Colis/cle, anti-ecrasement, enregistrement reseau MP et retry sans duplication couverts |
| Secret Hacking | OK | Mot de passe absent des reponses client |
| Economie/reputation | OK | Penurie, reputation et arrondis par palier couverts |
| Trading fee | OK | Commission serveur de 5 % |
| Poker engine | OK | Evaluation, actions, side pots et sessions |
| Zombie Race settlement | OK | Cinq departs/jour, tickets persistants et paiement automatique |
| Zombie Race balance | OK | RTP favori 94,50 %, avantage maison 5,50 % sur 100 000 courses |
| Typing | OK | UTF-8, profils et timing partage |

Ces tests sont des tests Lua hors-jeu et des assertions statiques. Ils ne remplacent
pas le moteur Project Zomboid, le streaming des chunks, les paquets conteneur, les
timed actions, ni deux clients reels.

### Repartition Luacheck

| Code | Nombre | Risque | Action |
| --- | ---: | --- | --- |
| W432 | 47 | Faible | Shadowing `self` dans closures UI historiques |
| W612 | 8 | Aucun fonctionnel | Trailing whitespace |
| W613 | 6 | A verifier | Espaces dans des strings, parfois volontaires |
| W581 | 5 | Faible | Expressions booleennes simplifiables |
| W213 | 4 | Faible | Variables de boucle inutilisees |

Priorite de correction conseillee : nettoyage prudent du
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
- `PZLinuxInventoryCash.lua`
- `PZLinuxMailData.lua`
- `PZLinuxMissionLocations.lua`
- `PZLinuxPokerConfig.lua`
- `PZLinuxPokerEngine.lua`
- `PZLinuxRaceEngine.lua`
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

## 5. Etat fonctionnel

| Domaine | Solo | MP code | Persistance/restart | Etat restant |
| --- | --- | --- | --- | --- |
| Ordinateur/Internet | Oui | Player explicite dans les UI | Player ModData | Pause, split-screen, manette |
| Banque | Oui | Serveur | Player ModData | Crash entre mutation et persistance |
| ATM | Oui | Serveur, reserve atomique et inventaire synchronise | ATM object + joueur | Concurrence deux joueurs live |
| Dark Web achats | Oui | Offres/prix/stock/debit/livraison serveur | Marche global + pending orders | Reconnexion et concurrence deux clients live |
| Dark Web ventes | Oui | Inventaire et credit serveur | Pending sales | Double redemption/concurrence live |
| Trading/Wallet | Oui | Prix globaux serveur | Global + Player ModData | Reconnexion et restart live |
| Contrats board | Oui | Board global serveur | Global ModData | Rotation/concurrence live |
| Contrats preview/accept | Oui | Mission canonique serveur | Cache + World ModData | Reconnexion et offre prise par autre joueur |
| Objectifs contrats | Oui | Entites/tags/proximite serveur | Monde + Global ModData | Streaming chunk et vol live |
| Completion contrats | Oui | Reward, reputation et recu serveur | Player + World ModData | Crash consistency et affichage MP live |
| Requests items | Oui | Prix/debit/livraison serveur | Pending Player ModData | Reconnexion/double clic live |
| Requests vehicules | Oui | Spawn et validation reseau serveur | Pending puis monde tague | Streaming/reconnexion live |
| Mails | Oui | Generation/retrait/reward serveur | Player ModData | Equilibrage reward et traductions |
| Hacking | Oui | Secret et transfert serveur | Rollback cartes | Cooldown et restart live |
| Blackjack | Oui | Deck/payout serveur | Refund mise interrompue | Restart live |
| Zombie Race | Oui | Calendrier/pool/resultat/payout serveur | Global ModData + tickets | Flux MP valide; simultane/restart a tester |
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
- La resolution d'un contrat actif repare les index joueur obsoletes uniquement
  depuis un enregistrement serveur canonique du bon type et accepte par ce joueur.
- Cargo, Manhunt, Blood, Capture et Protect resolvent une entite reelle cote
  serveur avant mutation.
- Manhunt utilise un rayon d'activation partage et configurable de 80 cases. Le
  client demande puis retente le spawn meme si sa copie de la case cible n'est
  pas encore chargee; le serveur decide quand la zone est exploitable. Les
  actions finales restent limitees a leur controle de proximite strict.
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

- 2 chances sur 5 de recevoir un revolver ;
- dont 1 chance sur 5 avec jusqu'a 1 999 billets en plus.

Le joueur peut potentiellement vider le contenu avant de renvoyer la valise. Ce
bonus est tres eleve pour un contrat Package deja remunere et doit etre supprime,
plafonne ou integre explicitement au calcul du reward.

## 8. Economie et progression

### Points positifs

- Les prix Dark Web puissants ont ete releves.
- Le catalogue Dark Web dispose maintenant d'un stock mondial persistant, commun
  a tous les joueurs et renouvele toutes les 24 heures de jeu. Deux clients voient
  les memes articles et les memes quantites; le prix final reste personnalise par
  la reputation et les autres multiplicateurs du joueur.
- Les quantites sont tirees selon le prix de reference serveur : 10-15 sous $500,
  8-10 sous $1 000, 6-8 sous $2 500, 4-6 sous $5 000, 2-4 sous $10 000 et 1-2 a
  partir de $10 000. Le dernier exemplaire est attribue par le serveur et une vue
  client obsolete ne peut pas depasser le stock restant.
- Les Requests sont un service de confort couteux et non une source de loot gratuit.
- La remise PlantScavenging est plafonnee a 15 %.
- Trading applique 5 % de fee serveur sur achats et ventes.
- La penurie est centralisee : Dark Web et Requests restent a x1 pendant les trois
  premiers mois, progressent tous les trois mois et plafonnent a x8 apres deux ans.
- Les contrats sont volontairement exclus de la penurie mondiale.
- Les prix finaux utilisent des paliers configurables de 5, 10, 50, 100 et 500
  dollars; achats, reventes et rewards ont chacun leur direction d'arrondi.
- Les contrats faciles paient moins que les objectifs dangereux.
- Le niveau Z ajoute 5 % de reward par etage absolu, sur un Z choisi par le serveur.
- La reputation est attribuee cote serveur, revient lentement vers le neutre et
  modifie les prix Dark Web/Request avec surcharge ou remise plafonnee.
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

#### Zombie Race - corrige

La formule de vitesse continue historique est restauree et les egalites a
l'arrivee sont departagees aleatoirement. Les anciennes cotes fixes ont ete
remplacees par un pool pari-mutuel serveur : 200 a 800 parieurs virtuels misent des
montants variables, une commission configurable de 15 % est retiree, puis le pool
net est partage proportionnellement entre les mises gagnantes. Le serveur ajoute
4 % des mises virtuelles comme liquidite pour soutenir les gains des outsiders.
Les cotes sont affichees en `N/1` et incluent cette somme.
Le marche est versionne : apres une modification du modele de cotes, les courses
ouvertes sans ticket sont regenerees, tandis que les paris deja engages gardent
leur carte et leur pool d'origine.

Les courses sont maintenant des rendez-vous globaux a **08:00, 10:00, 12:00,
14:00 et 16:00** selon l'horloge du monde. Un joueur peut programmer un ticket
sur plusieurs departs; le serveur simule et paie les courses meme lorsque
l'interface est fermee. Jusqu'a cinq resultats non lus sont conserves par joueur,
affiches dans l'ordre lors de la prochaine visite puis marques comme consultes.
Le dimanche du calendrier en jeu a
16:00 utilise 500 a 1 300 parieurs virtuels et ajoute $50 000 apres commission.
Son ticket est plafonne a $500 par joueur : une simulation dediee de 10 000
cagnottes mesure environ 119 % de RTP sur le favori, rendement promotionnel
positif mais limite a un seul rendez-vous hebdomadaire.
Les courses reglees sans ticket en attente sont purgees apres 48 heures en jeu;
une course due a un joueur hors ligne reste conservee jusqu'au paiement.

Le principal probleme d'exploitation de cette feature est donc corrige. Les
courses ne peuvent plus etre relancees sans limite depuis l'interface : le
calendrier global joue le role de cooldown serveur, commun a tous les joueurs et
impossible a contourner avec une reconnexion ou la reouverture du terminal. La
super cagnotte reste limitee a un rendez-vous par semaine en jeu et a un ticket
de $500 par joueur.

La campagne reproductible de 100 000 courses avec pari systematique sur le favori
mesure **94,50 % de RTP**, **5,50 % d'avantage maison** et **29,73 % de victoires**.
Aucune position ne s'ecarte de plus de 0,27 point du taux symetrique de 12,50 %.
Etat : **equilibre statique et flux principal MP valides**. Le serveur charge les
cinq prochains departs, conserve les cinq resultats non lus et credite correctement
le compte gagnant. Les paris simultanes de deux joueurs et le redemarrage pendant
des tickets en attente restent a tester. Voir
[RAPPORT_ZOMBIE_RACES.md](RAPPORT_ZOMBIE_RACES.md).

#### P2 - Reputation

L'impact sur Dark Web et Requests est maintenant actif et teste automatiquement.
Son rythme de progression, sa recuperation apres reputation negative et les
plafonds de remise/surcharge doivent encore etre mesures sur une partie longue.

## 9. Traductions et UI

### Infrastructure

- 20 catalogues `IG_UI.json` valides en UTF-8.
- 314 cles identiques par langue.
- Controle automatique des doublons, cles et placeholders `%s`/`<name>`.
- Request utilise un `ISRichTextPanel` fixe, wrappe, scrollable et auto-scroll.
- Les descriptions de locations utilisent des cles traduisibles et un fallback.
- Poker/Blackjack ont ete ajustes au CRT avec cartes, table et actions compactes.
- Les symboles de cartes utilisent des textures rouge/noir, evitant les limites de
  glyphes de `ISLabel`.

### Limites

- L'audit large trouve 2 004 strings candidates hors catalogues.
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
- 277 declarations heuristiques ne commencent toujours pas par `PZLinux`.
- 26 classes UI/TimedActions globales restent non prefixees.
- Plusieurs callbacks d'evenements restent globaux et non prefixes.

Les 277 entrees ne sont pas 277 bugs : une grande partie sont des methodes de
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

Le graphique Wallet capture maintenant le joueur explicite de son interface au
lieu de rappeler implicitement le joueur 0; ce correctif local ne resout pas encore
le routage generique des reponses reseau.

## 12. Metadonnees et packaging release

Etat : **metadonnees v1.0.0 harmonisees**.

- `README.md`, `workshop.txt` et `doc/OVERVIEW.md` presentent PZLinux 1.0.0 sans
  marqueur BETA ou version 0.1.x.
- `doc/RELEASE.md` fournit une synthese publique courte et `doc/CHANGELOG.md`
  centralise la 1.0.0 ainsi que les 25 versions/RC historiques 0.x.
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
- `tools/check_release_metadata.lua` controle les chemins documentaires actuels,
  les liens README, BETA, les versions et l'unicite de `mod.info`.
- Plusieurs scripts `.sh` dans `tools/` sont suivis en mode `100644`; `./tools/...`
  echoue avec « Permission denied ». Ils fonctionnent avec `bash tools/...`.

Pour le packaging seul, il reste a rendre les outils shell executables si l'usage
direct est souhaite et a valider les captures definitives du Workshop. Les gates
MP et equilibrage des sections suivantes restent applicables avant publication.

## 13. Checklist de tests manuels

### Solo B42.20

- [x] Nouvelle sauvegarde : ordinateur, Internet, fermeture et reouverture.
- [x] Sauvegarde existante pre-v1 : migration sans perte banque/contrat/mail.
- [x] ATM : depot, retrait, reserve, manque de cash et reload save.
- [x] Dark Web : achat, perte, livraison, vente, redemption et reconnexion.
- [x] Trading : snapshot, achat, vente, Wallet et progression sur plusieurs jours.
- [ ] Jouer, annuler et completer les 12 contrats.
- [ ] Verifier qu'une sync/clic droit ne rejoue plus la completion d'un contrat.
- [ ] Echantillonner packages, cargo, manhunt, protect et vehicules B42.20.
- [ ] Requests item/vehicule, double clic et chunk temporairement indisponible.
- [ ] Mails ammo/medical, accept/delete/complete et inventaire insuffisant.
- [x] Hacking manuel/auto, lock, transfert et restart.
- [x] Blackjack win/lose/push/blackjack et fermeture en cours de partie.
- [x] Zombie Race : programmer plusieurs departs, fermer l'UI, verifier les
  paiements automatiques, le dernier recap et la super cagnotte du dimanche 16:00.
- [x] Poker : six sieges, eliminations, duel final, side pot et cashout.
- [x] Tester EN, FR, DE, RU, TH, JP, KO, CN et CH sur les UI principales.

### MP serveur dedie, deux clients

Progression fonctionnelle des contrats en MP : **11/12 valides**.

- [x] 1 - Kill zombies.
- [x] 2 - Retrieve the package : recuperation, expedition et paiement valides en MP.
- [ ] 3 - Eliminate the target : cible serveur de nouveau assise et immobilisee,
  recherche de case libre elargie. La cible v3 utilise en priorite le helper natif
  `addZombieSitting`, puis deux methodes de repli. Les tests B42.20 MP ont montre
  qu'une cible visible peut conserver `onlineId=-1` : elle est donc reconnue par
  ses coordonnees confirmees et reutilisee, tandis que les doublons sont supprimes.
  Des diagnostics serveur/client couvrent chaque demande, rejet et methode de spawn.
  La restauration attend que le chunk client soit charge et est relancee chaque
  seconde meme si le joueur s'arrete apres son arrivee sur place. A la mort, le
  serveur memorise la position de la cible afin que la decapitation reste valide
  meme si les tags ne sont pas recopies sur le cadavre en MP ;
  la cible v4 reste repliquee et immobilisee cote serveur, puis devient passive
  seulement apres son apparition cote client. Elle est conservee dans un
  registre runtime pour stopper les respawns, et son statut `target_down` est
  synchronise explicitement pour afficher l'action de decoupe. Les anciennes
  cibles v3 et leurs doublons sont remplaces lors de la restauration ; re-test
  visuel, mort et decoupe en MP requis.
- [x] 4 - Collect zombie blood.
- [x] 5 - Send automobile parts.
- [x] 6 - Capture a live zombie.
- [x] 7 - Prepare the cargo : interaction, evenement et validation testes en MP.
  La caisse v3 utilise desormais un `IsoThumpable` special avec sprite transmis.
- [ ] Visibilite Cargo : confirmer sur le client Windows que la migration v2 vers
  v3 affiche bien la caisse classique, puis verifier unload/reload du chunk.
- [x] Outil admin de test : le menu contextuel `PZLinux Admin > Force contract on
  board` permet a un administrateur de placer l'un des 12 contrats en tete du
  tableau partage. La commande est validee cote serveur, prefixee, idempotente et
  refusee aux joueurs ordinaires. Le contrat force reste disponible jusqu'a son
  acceptation ou au prochain renouvellement normal du tableau. En solo, ce menu
  est strictement masque sauf lorsque le jeu est lance avec `-debug`.
- [x] 8 - Protect the building.
- [x] 9 - Send medical equipment.
- [x] 10 - Send weapons.
- [x] 11 - Send a computer : livraison, retrait et paiement valides en MP.
- [x] 12 - Send a fridge : livraison, retrait et paiement valides en MP.

- [x] ATM MP : depot/retrait, debit/credit bancaire, reserve persistante, refus a
  $0 et renflouement au-dela de la reserve initiale de $50 000 valides.
- [x] Zombie Race MP : cinq prochains departs charges, cinq resultats non lus
  affiches et gain credite sur le compte bancaire.
- [x] Dark Web MP : achats simples et multiples, reception des colis, vente,
  expedition et credit bancaire valides sur serveur heberge.
- [x] Meme solde apres sync/reconnexion pour chaque joueur.
- [x] Deux depots/retraits simultanes sur le meme ATM.
- [x] Meme snapshot/prix Trading pour les deux joueurs.
- [x] Trading simultane et fee 5 % apres redemarrage.
- [ ] Dark Web : reconnexion avec achat/vente en attente et redemption par le bon
  joueur; achat simultane du dernier exemplaire avec deux clients.
- [ ] Commandes mailbox forgees a distance/mauvais Z refusees.
- [x] Meme board de contrats pour les deux joueurs.
- [x] Offre acceptee simultanement : un seul gagnant, board resynchronise.
- [x] Objectif Package/Cargo/Manhunt vole et livre par un autre joueur.
- [ ] Unload/reload chunk conserve tags et statut d'objectif.
- [ ] ContractAccept forge avec location/Z/reward/info ignores.
- [ ] ContractComplete forge refuse sans credit.
- [ ] Chaque event monde forge a distance/mauvaise entite refuse.
- [ ] Request vehicule : livraison en deux phases ajoutee (une voiture par devis,
  modele/location canoniques, tag persistant, ID reseau valide, retransmission,
  cle unique, anti-ecrasement et confirmation de visibilite client); re-test MP
  apres double commande/reconnexion et unload/reload du chunk requis.
- [ ] Mail complete simultane ne retire/reward qu'une fois.
- [ ] Deux Blackjack/Race/Poker simultanes sans fuite d'etat.
- [x] Restart pendant Blackjack/Race/Hacking/Poker applique un rollback exact.
- [x] Arret brutal pendant ContractComplete et cashout ne duplique pas le credit.

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
- [x] Recalibrer Zombie Race : pool pari-mutuel, RTP favori de 94,50 % sur
  100 000 courses et aucun biais de position significatif.
- [x] Remplacer les Zombie Races relancables sans limite par cinq departs serveur
  quotidiens et une super cagnotte hebdomadaire plafonnee a $500 par joueur.
- [x] Harmoniser `README.md`, `workshop.txt`, `doc/OVERVIEW.md` et `mod.info` en 1.0.0.
- [ ] Corriger les traductions automatiques manifestement erronees.

### P2 - Maintenabilite et robustesse

- [ ] Extraire Mail runtime/rewards hors `ISPZLinuxVariablesTables.lua`.
- [ ] Extraire banque/ATM, jeux et Hacking par domaine.
- [x] Centraliser les wrappers Trading dans le shared et supprimer les redéfinitions client.
- [ ] Ajouter timeout/nettoyage aux callbacks client sans reponse.
- [ ] Ajouter rate limit serveur par joueur/commande.
- [x] Supprimer les 12 variables locales inutilisees W211 sans changer le comportement.
- [x] Corriger la redefinition W411 des colonnes Quantity/Price du Wallet.
- [x] Supprimer l'affectation W311 inutilisee dans la mise en page Mail.
- [x] Corriger les deux W431, dont la resolution implicite du joueur dans Wallet.
- [x] Ajouter tests directs ATM, Requests, inventaire autoritaire et economie.
- [ ] Ajouter tests metier directs banque, Blackjack et Mail hors inventaire.
- [x] Simuler 100 000 Zombie Races : RTP favori 94,50 %, dans la cible 85-95 %.
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
- [x] Supprimer les 20 W611 et 4 W614 sans toucher aux strings W613.
- [x] Documenter `bash tools/...` pour les scripts shell non executables.
- [x] Separer les notes publiques `RELEASE.md` du journal technique `CHANGELOG.md`.
- [ ] Mettre a jour les captures Workshop des nouvelles features.
- [ ] Faire une sauvegarde longue de plusieurs semaines monde.

## 15. Next steps avant publication Steam

Cette section donne l'ordre de travail recommande. La priorite n'est plus
d'ajouter beaucoup de code : il faut maintenant prouver que les fonctions deja
presentes restent coherentes en solo, en serveur heberge et en serveur dedie.

### Etape 1 - Geler les features et deboguer les parcours existants

Objectif : ne plus modifier les regles metier pendant la campagne de validation,
sauf pour corriger un bug reproductible.

- [ ] Geler la liste des features de la 1.0.0.
- [ ] Rejouer les 12 contrats du debut a la fin en solo puis en MP.
- [ ] Utiliser `PZLinux Admin > Force contract on board` pour tester chaque contrat
  sans attendre le renouvellement hebdomadaire; le contrat 7 correspond a Cargo.
- [ ] Pour chaque bug, noter le contexte, les etapes exactes, le resultat attendu,
  le resultat obtenu et les lignes pertinentes de `console.txt`.
- [ ] Garder `tools/watch_console.ps1` ouvert sur Windows ou
  `bash tools/watch_console.sh` dans le conteneur avec `/pz-logs` monte.
- [ ] Verifier qu'aucune erreur Lua, traceback ou commande serveur rejetee de facon
  inattendue n'apparait dans les logs.
- [ ] Tester les interfaces en 1280x720, 1920x1080 et avec au moins une langue aux
  textes longs, par exemple allemand ou russe.
- [ ] Ne corriger pendant cette phase que les regressions fonctionnelles, pertes
  d'items, doubles paiements, desynchronisations et blocages de progression.

### Etape 2 - Campagne de tests bloquante

La publication Steam publique doit attendre les scenarios suivants :

- [ ] Serveur dedie B42.20.x avec deux vrais clients simultanes.
- [ ] Achat, vente, depot, retrait et livraison verifies par les deux joueurs.
- [ ] Vol d'un objectif de contrat par un autre joueur, puis completion valide.
- [ ] Deux joueurs tentent d'accepter la meme offre au meme moment.
- [ ] Reconnexion pendant un contrat et pendant une livraison en attente.
- [ ] Redemarrage serveur pendant ATM, Dark Web, Request, Hacking, Blackjack,
  Zombie Race et Poker; chaque debit doit etre finalise ou rembourse une fois.
- [ ] Unload/reload du chunk contenant un colis, zombie, cadavre, vehicule ou cargo.
- [ ] Sauvegarde pre-1.0 chargee apres backup, sans perte de banque, reputation,
  contrats actifs ni commandes en attente.
- [ ] Verification des commandes reseau forgees et des controles de proximite avec
  un client de test, sans utiliser ce test sur un serveur public.
- [ ] Partie longue de plusieurs semaines monde pour observer prix, reputation,
  rotations de contrats et nettoyage des etats temporaires.

### Etape 3 - Scripts de validation a ajouter

Les tests hors-jeu ne remplacent pas Project Zomboid, mais ils raccourcissent
fortement chaque cycle de correction.

- [x] Creer `tools/simulate_zombie_races.lua` en reutilisant exactement les tables
  et le calcul de resultat du mod, sans recopier une seconde formule divergente.
- [x] Creer `tools/simulate_zombie_races.sh` comme lanceur. Par defaut, il simule
  1 000 courses; une option `--runs 100000` produit la mesure de release.
- [x] Afficher pour chaque coureur : nombre de victoires, taux de victoire, cote
  moyenne, mises, gains, perte maison et RTP joueur.
- [x] Faire echouer la simulation si le RTP sort de la plage d'equilibrage choisie
  ou si une position/cote devient manifestement dominante.
- [ ] Creer `tools/run_release_gate.sh` pour enchainer syntaxe, audit statique,
  assets, locations, traductions, metadata et tous les `test_*.lua`.
- [ ] Ajouter un test de probabilites et payouts Blackjack sur au moins 100 000
  mains simulees avec la strategie fixe du croupier.
- [ ] Ajouter une simulation Poker longue ciblant conservation totale des jetons,
  side pots, eliminations et fin de tournoi.
- [ ] Ajouter un test de progression economique aux ages 0, 3, 6, 12 et 24 mois,
  avec reputations minimale, neutre et maximale.
- [ ] Ajouter un analyseur de `console.txt` qui resume erreurs Lua, tracebacks,
  commandes rejetees, remboursements et idempotence au lieu de relire tout le log.
- [ ] Ajouter des tests metier directs pour banque, Blackjack et rewards Mail.

Pour les Zombie Races, 1 000 executions donnent un retour rapide mais restent
trop sensibles au hasard pour certifier l'equilibrage. Le rapport final doit donc
etre calcule sur au moins 100 000 courses avec une graine affichee et reproductible.

### Etape 4 - Warnings et maintenabilite

Les 70 warnings actuels ne bloquent pas a eux seuls la 1.0.0. Ils doivent etre
traites par categorie, avec un test entre chaque petit lot :

- [ ] Verifier manuellement les 6 W613, car les espaces sont situes dans des textes
  et peuvent faire partie de leur mise en forme.
- [ ] Corriger les 4 W213 de variables de boucle inutilisees.
- [ ] Simplifier les 5 W581 uniquement lorsque les operandes ne peuvent pas etre
  des tables ou des valeurs speciales.
- [ ] Nettoyer les 8 W612 de fin de ligne.
- [ ] Traiter les 47 W432 `self` fichier par fichier, sans changement massif des
  callbacks UI avant la campagne MP.
- [ ] Continuer l'extraction de `ISPZLinuxVariablesTables.lua` apres la 1.0.0,
  sauf si un bug de release impose de toucher au domaine concerne.

Le critere de release reste **0 erreur Lua et aucun warning fonctionnel connu**,
pas necessairement 0 warning cosmetique.

### Etape 5 - Contrats, locations et nouvelles features

- [ ] Ajouter en priorite des locations a Fallas Lake et Valley Station, qui ne
  sont actuellement representees dans aucun pool.
- [ ] Renforcer ensuite Ekron et Coalfield, puis les pools `protect` et `manhunt`
  dans les villes peu couvertes.
- [ ] Valider chaque nouveau point en jeu : accessibilite, niveau Z, interieur ou
  exterieur, espace de spawn et comportement lorsque le chunk est decharge.
- [ ] Conserver les descriptions via des cles `IG_UI` et ne jamais remettre une
  location directement dans le code d'un contrat.
- [ ] Ne pas ajouter de nouveau type de contrat avant la publication, sauf si les
  12 contrats actuels laissent un manque gameplay bloquant constate en test.
- [ ] Placer les nouveaux contrats, services et jeux dans la roadmap 1.1 afin de
  stabiliser la base serveur-autoritative de la 1.0.0.

Les nouvelles locations sont moins risquees que de nouvelles features, mais elles
doivent rester un enrichissement final. Une location non testee peut bloquer une
mission aussi surement qu'un bug de code.

### Etape 6 - Preparation de la page Steam

- [ ] Corriger ou documenter les deux rewards encore trop genereux : Mail et
  valise Package.
- [ ] Faire relire au minimum EN et FR, puis les langues generees prioritaires.
- [ ] Mettre a jour les captures avec ATM, contrats, Dark Web, Poker et Blackjack.
- [ ] Publier une liste honnete des limitations : manette, split-screen et langues
  non relues par un locuteur natif.
- [ ] Documenter installation solo, serveur heberge, serveur dedie, mise a jour
  depuis la beta et procedure de backup.
- [ ] Executer le release gate depuis un clone propre de la branche candidate.
- [ ] Creer un tag `v1.0.0`, archiver les resultats de tests et conserver une copie
  de la version Workshop publiee.

### Definition de done 1.0.0

PZLinux peut etre publie lorsque les P0/P1 sont fermes ou explicitement documentes,
que les 12 contrats passent en solo et MP, que deux clients survivent a une
reconnexion et un redemarrage sans duplication ni perte, que le release gate est
vert, et qu'aucun traceback reproductible ne reste ouvert. Les warnings cosmetiques,
la manette complete, les nouvelles features et les nouveaux contrats peuvent alors
continuer en 1.1.

## 16. Roadmap apres 1.0.0

### 1.1 - Economie et services

- Panier Request multi-items avec devis serveur.
- Depot libre de ressources via allowlist economique.
- Matieres premieres Trading et historique saisonnier.
- Acces PZLinux par radio ou satellite.
- Reputation reliee a des offres, prix et avantages explicites.
- Options Sandbox : fee, reserves ATM, rewards, reputation et cooldowns.

### 1.1 - Nouveaux contrats

Les nouveaux contrats doivent raconter une petite histoire avec les mecanismes de
Project Zomboid, sans simuler des PNJ complexes. Chaque proposition ci-dessous est
concue comme une machine a etats canonique geree par le serveur.

#### Priorite A - Realistes et reutilisant les briques actuelles

1. **La porte scellee** - Une cible zombifiee porte une cle de mission taguee.
   Le joueur doit identifier et tuer la bonne cible, recuperer la cle, rejoindre
   une seconde location, deverrouiller une porte ou une cache et prendre l'objet.
   La cle, la porte/cache et l'objet portent le meme `PZLinuxContractId`. En MP,
   tout joueur peut voler la cle ou le contenu. La porte vanilla ne doit etre
   modifiee que si son etat initial peut etre restaure; une cache PZLinux verrouillee
   sert de fallback plus fiable.
2. **Reprise de vehicule** - Trouver un vehicule identifie, le remettre en etat et
   le conduire dans une zone de livraison. Le serveur valide l'ID persistant, la
   position, un minimum de carburant, l'etat moteur et eventuellement des pieces
   imposees. Le vehicule reste visible et volable pendant toute la mission.
3. **Relais radio de secours** - Recuperer une batterie, des composants radio et
   du cable, les installer sur un site, puis tenir la position pendant une emission
   bruyante. La mission combine livraison d'items, timed action et logique Protect,
   avec une horde proportionnelle a la difficulte.
4. **Chaine du froid** - Recuperer une caisse medicale dans un refrigerateur ou
   une pharmacie et la livrer avant une echeance. Le serveur enregistre l'heure de
   retrait et refuse une caisse trop tardive ou ouverte. Une variante difficile
   demande d'alimenter le refrigerateur avec un generateur avant le retrait.
5. **Coursier disparu** - Retrouver un cadavre identifie, prendre sa note ou sa
   carte, puis suivre l'indice vers une seconde cache. Aucun PNJ vivant n'est requis;
   la narration repose sur le corps, les objets et les deux locations persistantes.
6. **Nettoyage de batiment** - Vider un petit batiment marque de tous ses zombies,
   puis confirmer la securisation depuis l'interieur. Le serveur compte uniquement
   les zombies presents dans les limites canoniques du batiment et exige que le
   joueur reste sur place pendant la verification.

#### Priorite B - Plus riches, apres validation des APIs B42/MP

7. **Livraison de carburant ou d'eau** - Remplir puis livrer un ou plusieurs
   recipients avec une quantite et un fluide precis. Le serveur valide le type de
   fluide et le volume reel, puis retire exactement la quantite livree.
8. **Fragments de code** - Trois cibles ou caches donnent chacune un fragment.
   Les trois fragments permettent d'ouvrir un coffre final de grande valeur. Cette
   mission longue est adaptee a la difficulte 5 et encourage concurrence ou entraide
   en MP sans exposer le code final au client avant validation.
9. **Remise sous tension** - Transporter, poser, raccorder et alimenter un generateur
   dans une zone designee, puis maintenir son fonctionnement pendant une duree
   donnee. Le contrat valide l'objet monde, son carburant et son etat; il ne doit
   jamais confisquer un generateur preexistant appartenant a un joueur.
10. **Boite noire** - Localiser une epave, demonter une piece ou recuperer une radio
    taguee, puis l'envoyer par la poste. Une variante impose un niveau Mechanics ou
    un outil, mais le skill ne doit jamais etre transmis comme autorite par le client.
11. **Balise de ravitaillement** - Installer une radio ou une balise dans une zone
    ouverte, attendre la synchronisation et survivre au bruit. Une caisse apparait
    seulement apres la fin du timer serveur; le contrat se termine quand cette
    caisse est deposee a un second point.
12. **Reapprovisionnement ATM** - Un contrat designe un ATM pauvre ou vide et une
    somme a livrer. Le joueur doit retirer son propre argent, transporter les
    billets physiquement puis les deposer dans l'ATM cible. Il risque donc de mourir
    en route et de laisser une somme importante recuperable par les autres joueurs.
    Le serveur valide les billets retires de l'inventaire et l'identite persistante
    de l'ATM dans une transaction atomique, augmente sa reserve reelle, puis rembourse
    le capital engage et verse la reward du contrat. En MP, le cash reste volable et
    un autre joueur peut renflouer l'ATM; la regle d'attribution de la reward devra
    etre explicite pour eviter blocage, duplication ou perte du capital.

#### Idees B42 a garder pour 1.2

- **Transport d'animaux** - Recuperer un animal ou un petit groupe et le livrer
  vivant dans une zone d'elevage. L'idee correspond bien a B42, mais depend des APIs
  animaux, cordes, remorques et persistance MP encore plus fragiles.
- **Echantillon de fluide contamine** - Prelever un liquide precis dans une source
  designee et le livrer sans melange. A conserver tant que la validation serveur des
  fluides et recipients n'a pas ete prototypee.

#### Ordre d'implementation conseille

1. La porte scellee, car elle reutilise Manhunt, Package et les tags persistants.
2. La reprise de vehicule, car le spawn et l'identite vehicule existent deja.
3. Le coursier disparu, premiere vraie mission en deux locations.
4. Le relais radio, qui reutilise ensuite Protect et les timed actions.
5. La chaine du froid, apres ajout d'un timer serveur persistant et testable.

Chaque contrat multi-etapes doit conserver `step`, `locationId`, IDs des objectifs,
deadline et etat initial du monde dans le registre serveur. Une rotation du board,
une reconnexion ou un redemarrage ne doit ni sauter une etape, ni recreer un objet,
ni effacer un contrat accepte.

Nouveaux pools de locations envisages : `lockedCaches`, `vehicleDeliveries`,
`relaySites`, `coldStorage`, `courierBodies`, `cleanupBuildings`, `fluidDeliveries`,
`crashSites` et `beaconSites`. Comme les pools actuels, ils restent classes par
ville et utilisent des descriptions traduisibles.

### 1.2 - Narratif

#### Mails narratifs debloques par reputation

Les mails peuvent porter des histoires plus personnelles que les contrats de
societes. Un survivant contacte le joueur parce que sa reputation inspire assez
confiance, puis lui demande de rechercher un proche, un collegue ou un ancien
refuge. Ces missions ne donnent **jamais d'argent** : la recompense est un objet,
une cache ou du materiel laisse par la personne recherchee.

Le mail initial ne doit pas donner directement le point final. Il ouvre une petite
enquete persistante :

1. lire le mail et accepter la demande;
2. visiter une residence ou un lieu de travail;
3. trouver une note, une photo, une cle, une carte annotee ou un objet personnel;
4. suivre cet indice vers un point B, puis eventuellement un point C;
5. decouvrir le sort du survivant et recuperer ou refuser la recompense.

Le denouement est choisi par le serveur au debut de l'histoire et reste secret
jusqu'a la derniere etape. La cible peut etre morte, zombifiee, partie vers un autre
refuge, avoir franchi le perimetre de Knox ou n'avoir laisse aucune certitude. Dire
qu'elle a quitte la zone d'exclusion est plus coherent avec le lore que garantir
qu'elle a quitte le pays.

##### Paliers proposes

| Reputation | Type de mail | Longueur | Recompense possible |
| ---: | --- | ---: | --- |
| 0 a 24 | Appel prudent | 2 etapes | Nourriture, piles, soins ou carte |
| 25 a 74 | Recommandation locale | 2-3 etapes | Outils, radio, livres ou munitions limitees |
| 75 a 124 | Demande confidentielle | 3-4 etapes | Materiel de qualite ou manuel rare |
| 125 et plus | Secret personnel | 4-5 etapes | Cache exceptionnelle, sans arme ultime garantie |

Une reputation negative ne doit pas produire artificiellement des missions rares.
Elle peut limiter ces mails aux appels anonymes, messages incomplets ou tentatives
d'arnaque sans reward important. Chaque histoire principale est unique par joueur
et ne peut pas etre generee en boucle pour farmer ses objets.

##### Arcs narratifs possibles

1. **Aucune nouvelle de ma soeur** - Le joueur fouille sa maison, trouve un mot
   mentionnant une station-service, puis une voiture abandonnee. Le dernier indice
   mene vers un corps, un refuge vide ou une note indiquant qu'elle a passe le
   perimetre. La recompense est la cle d'une petite cache familiale.
2. **La derniere frequence** - Un radioamateur a cesse d'emettre. Son domicile
   contient une frequence et un journal; le relais indique ensuite son dernier lieu
   d'emission. Le joueur retrouve son sac technique, son corps ou un message final.
3. **Le cabinet ferme** - Un ancien patient cherche un medecin. Une ordonnance au
   cabinet mene vers une pharmacie puis un refuge improvise. La recompense est une
   reserve medicale coherente avec ce qui reste sur place.
4. **Les cles du garde-meuble** - Un parent demande de verifier un appartement.
   Une facture et une cle conduisent a un entrepot. La cellule peut contenir des
   outils, des souvenirs sans valeur ou une cache utile selon le denouement.
5. **Le convoi fantome** - Un manifeste trouve dans un depot conduit a un camion
   abandonne, puis a l'endroit ou le conducteur a tente de poursuivre a pied. Le
   chargement restant constitue la recompense, pas un paiement magique.
6. **Le voisin du 3B** - Une residence vide montre des signes de depart precipite.
   Plusieurs indices contradictoires menent a une planque barricadee. Le survivant
   peut etre devenu zombie et porter la cle de sa propre reserve.
7. **Ils sont sortis de Knox** - Les indices semblent annoncer un massacre, mais
   le dernier message confirme qu'un petit groupe a poursuivi sa route hors de la
   zone. Le joueur ne trouve aucun corps; une cache de remerciement conclut l'arc.
8. **La derniere livraison** - Le joueur retrouve un coursier mort et un colis
   scelle. Il peut respecter la demande et livrer le colis, ou l'ouvrir et conserver
   son contenu. Le choix ferme une branche et peut influencer les mails futurs.

##### Architecture et securite MP

- Stocker `storyId`, `chapter`, `outcomeSeed`, `locationIds`, `objectiveIds`,
  `rewardTier`, `status` et `completedAt` dans l'etat serveur du joueur.
- Generer toute la chaine au moment de l'acceptation, mais ne transmettre au client
  que le chapitre et la location actuellement connus.
- Taguer indices, cles, notes, corps et caches avec `PZLinuxMailStoryId` et un ID
  d'objectif persistant.
- Rendre chaque transition idempotente; relire une note ou rouvrir une cache ne
  doit jamais recreer la recompense.
- Conserver l'etape pendant rotation des mails, reconnexion, reload du chunk et
  redemarrage serveur.
- Choisir la recompense sur une allowlist serveur propre a chaque tier. Le client
  ne transmet ni item, ni quantite, ni denouement.
- Creer physiquement la recompense dans la cache finale lorsque cela est logique,
  plutot que de la faire apparaitre automatiquement dans l'inventaire.
- Autoriser les objets a rester visibles et transportables en MP. Un autre joueur
  peut voler un indice, mais le serveur suit son ID; il faut prevoir abandon,
  recuperation admin ou expiration si l'objet est detruit ou perdu.
- Ne jamais verrouiller definitivement une maison de joueur ou modifier une porte
  existante sans enregistrer son etat initial et une strategie de restauration.

Nouveaux pools proposes : `storyHomes`, `storyWorkplaces`, `storyClues`,
`storyVehicles`, `storyShelters`, `storyCorpses` et `storyCaches`. Une histoire peut
reutiliser une ville pour ses deux premieres etapes puis envoyer le joueur plus loin
pour son denouement, avec une recompense adaptee a la distance et au danger.

#### Autres pistes narratives 1.2

- Objets rares et documents thematiques relies aux histoires Mail.
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

## 17. Commandes de validation

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

## 18. Conclusion

Le travail de migration a transforme PZLinux d'un mod essentiellement solo en un
mod disposant d'une architecture MP credible. Les flux economiques et missions les
plus sensibles sont maintenant serveur-autoritatifs dans le code, les erreurs
rencontrees en serveur heberge ont ete corrigees avec des tests de regression, et
la structure des donnees est nettement plus maintenable.

La prochaine etape utile n'est pas un nouveau grand refactor. Il faut figer les
features, executer la campagne MP/restart, corriger les deux rewards trop genereux,
valider les metadonnees de release et traiter uniquement les defauts observes. Une
fois ces gates franchies, PZLinux pourra raisonnablement quitter BETA pour une
v1.0.0, avec controller/split-screen annonces comme limitations si ces chantiers ne
sont pas termines.
