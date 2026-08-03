# Changelog

## Correctifs post-1.0.0

- Menu PZLinux : les boutons "SEND A REQUEST" et "SELL SURPLUS" sont
  renommes en "BUY GOODS" et "SELL GOODS", plus explicites sur le fait que ce
  sont des biens de consommation courante qu'on achete ou qu'on vend (pas
  des contrats). Le bouton SELL GOODS est aussi deplace juste en dessous de
  BUY GOODS dans le menu (les deux features formant une paire logique),
  au lieu d'etre tout en bas de la liste.

- Requests (objets et vehicules) : correctif d'incoherence -- apres un achat
  reussi, la categorie restait affichee et achetable dans la liste, comme si
  le vendeur avait un stock infini. Un achat reussi marque desormais la
  categorie comme consommee pour le reste de la journee, exactement comme un
  refus de prix : elle disparait de la liste jusqu'au reset du jour de jeu
  suivant. Renommage interne de `PZLinuxRequestCategoryRejected` en
  `PZLinuxRequestCategoryConsumed` (couvre desormais achat ET refus) dans
  `ISPZLinuxVariablesTables.lua`, nouvelle fonction partagee
  `PZLinuxRequestsMarkCategoryConsumed`. Voir `tools/test_request_vehicle_delivery.lua`
  pour la couverture du cas rapporte (acheter puis retenter la meme
  categorie le meme jour doit etre refuse).
- Sell Surplus : equilibrage des prix pour eviter que la feature ne devienne
  plus rentable que les contrats (risque de faire du farming d'objets au lieu
  de jouer les contrats). Le prix de base passe de 30-50 % a 15-25 % de la
  valeur de reference. Le "great deal" (10 % de chance) devient beaucoup plus
  large et moins garanti : 25-125 % au lieu de 110-130 % -- il peut desormais
  retomber pres du prix de base au lieu d'etre toujours un bon prix, mais
  peut aussi ponctuellement depasser largement la valeur de l'objet. Voir
  `PZLinux.Config.Sell` (`basePricePercentMin/Max`,
  `greatDealMinPercent/MaxPercent`) dans `PZLinuxConfig.lua`.
- Sell Surplus : correctif d'un debordement visuel de la liste (elle
  depassait le cadre visible du moniteur). La zone de defilement occupait 60
  % de la hauteur du panneau, ce qui deborde de la zone d'ecran reellement
  visible sur la texture du moniteur CRT (bordure/bezel de l'image). Reduite
  a 46 % (memes proportions que le Dark Web) avec une vraie barre de
  defilement visible ajoutee.
- Sell Surplus : deuxieme refonte complete, cette fois pour ressembler au
  Dark Web (icones, liste defilante) au lieu d'un systeme par categorie. La
  demande n'est plus tiree une fois par jour pour une categorie entiere, mais
  independamment pour CHAQUE objet vendable des Requests (toutes categories
  sauf le vehicule) : 15 % de chance par jour qu'un acheteur le veuille, pour
  une quantite aleatoire entre 1 et 10. Le joueur doit posseder au moins
  cette quantite exacte dans son inventaire principal pour vendre (aucune
  vente partielle : c'est une limite volontaire pour eviter les abus); un
  objet absent de la liste signifie simplement que personne ne veut l'acheter
  aujourd'hui. Le prix est tire entre 30 et 50 % de la valeur de reference de
  l'objet, avec 10 % de chance de tomber sur un gros acheteur payant 110 a
  130 %. La vente est desormais instantanee comme le Dark Web : cliquer sur
  "SELL" retire immediatement les objets de l'inventaire et les remplace par
  un colis nomme "$<prix>" a deposer dans une boite aux lettres pour etre
  paye. Nouveau bouton "NEGOTIATE" : le joueur peut tenter de faire monter le
  prix de 100 $ a chaque clic, avec 50 % de chance de succes; en cas
  d'echec, l'acheteur retire completement son offre et l'objet ne peut plus
  etre vendu avant le lendemain. Voir `PZLinux.Config.Sell` (
  `demandChancePercent`, `quantityMin/Max`, `basePricePercentMin/Max`,
  `negotiateIncrement`, `negotiateSuccessChancePercent`) dans
  `PZLinuxConfig.lua`, les fonctions `PZLinuxSellGetOffers` /
  `PZLinuxSellNegotiate` / `PZLinuxSellApplySell` dans
  `ISPZLinuxVariablesTables.lua` (le depot en boite aux lettres,
  `PZLinuxSellApplyRedeemPackage`, est inchange), et
  `tools/test_sell_surplus.lua` pour la couverture complete.
- Requests (objets) : correctif d'un plantage ("attempted index: setVisible
  of non-table: null") lors du clic sur une categorie dans le menu Requests.
  Les boutons de pagination precedent/suivant n'etaient crees que s'il y
  avait plus d'une page; avec le filtrage par disponibilite quotidienne, la
  plupart des jours n'affichent qu'une poignee de categories qui tiennent sur
  une seule page, laissant le bouton "suivant" a `nil` et provoquant le
  plantage au clic. Corrige en verifiant l'existence des boutons avant de les
  manipuler.
- Requests (objets et vehicules) : refonte complete de la rarete des
  vendeurs. Le mecanisme de "recherche de fournisseur" avec delai et 40 %
  d'echec apres paiement est supprime, remplace par un tirage quotidien
  independant par categorie (14 categories, vehicule inclus) qui decide si
  un vendeur existe ne serait-ce que pour aujourd'hui. Seules les categories
  ou le tirage a reussi apparaissent dans la liste du menu Requests (un
  "check rapide" de ce qui est recuperable aujourd'hui), au lieu de laisser
  le joueur lancer une recherche dans une categorie qui n'a jamais eu la
  moindre chance d'aboutir. Refuser une offre affichee (bouton "Non" une fois
  qu'un prix a ete propose) masque desormais cette categorie jusqu'au reset
  du jour suivant, exactement comme si personne n'avait ete trouve — ceci
  evite de pouvoir re-tenter en boucle pour obtenir une meilleure offre.
  La rarete augmente avec le temps de jeu : la chance de ne trouver personne
  demarre a 50 % en debut de partie et grimpe lineairement jusqu'a 75 % au
  bout de 180 jours de jeu (environ 6 mois, plafonnee ensuite), pour simuler
  la disparition progressive des survivants/vendeurs au fil du temps. Voir
  `PZLinux.Config.Requests` (`unavailableChancePercentStart`,
  `unavailableChancePercentMax`, `unavailableRampGameDays`) dans
  `PZLinuxConfig.lua`, les nouvelles fonctions
  `PZLinuxRequestsGetAvailableCategories` / `PZLinuxRequestsRejectCategory`
  dans `ISPZLinuxVariablesTables.lua`, et `tools/test_request_vehicle_delivery.lua`
  pour la couverture (liste filtree, refus qui masque une categorie, reset le
  jour suivant, cas "personne nulle part aujourd'hui", et progression de la
  rarete dans le temps).
- Sell Surplus : revision complete du flux suite aux premiers tests en jeu.
  L'interface liste desormais uniquement les types d'objets de la categorie
  demandee que le joueur possede reellement dans son inventaire principal
  (comme le Dark Web), avec au plus 5 lignes affichees a la fois et une
  pagination (< / >) pour le reste, ce qui corrige le debordement visuel de
  la liste. La limite artificielle de 6 objets par vente a disparu : la
  vente porte desormais sur la quantite reellement possedee de chaque type
  selectionne. Le flux de validation devient un vrai aller-retour en deux
  temps : "Obtenir un devis" fige le prix propose par l'acheteur (affiche a
  l'ecran, variable selon la categorie et selon le tirage "gros acheteur"),
  puis le joueur choisit ACCEPTER (les objets disparaissent immediatement de
  l'inventaire, remplaces par un colis nomme "$<prix>", exactement comme le
  Dark Web) ou ANNULER. Dans les deux cas l'opportunite du jour est deja
  consommee des l'obtention du devis (comme pour la recherche de fournisseur
  des Requests) : annuler affiche "Plus personne ne veut acheter d'objets
  aujourd'hui" et il faut attendre le jour de jeu suivant. Le paiement reel
  n'intervient qu'au depot du colis dans une boite aux lettres. Cote code,
  `PZLinuxSellApplyConfirmDrop` (qui verifiait l'inventaire et payait en une
  seule etape a la boite aux lettres) est remplace par trois fonctions
  distinctes : `PZLinuxSellAcceptOffer` (retire les objets, cree le colis),
  `PZLinuxSellCancelOffer` (annule sans toucher a l'inventaire) et
  `PZLinuxSellApplyRedeemPackage` (credite la banque au depot du colis, sur
  le meme modele que `PZLinuxDarkWebApplyRedeemSales`). Voir
  `tools/test_sell_surplus.lua` pour la couverture de tous ces cas
  (objets manquants entre devis et acceptation, annulation, jour suivant,
  prix de base vs. gros acheteur).
- Correctif critique : un bug de syntaxe Lua (ambiguite classique
  `print(...)` suivi d'une ligne commencant par `(` sur la ligne suivante,
  interprete par Lua comme un appel de fonction chaine plutot que deux
  instructions distinctes) dans `PZLinuxRequestWaitForSupplier`
  (`PZLinuxRequest.lua`, feature de recherche de fournisseur ajoutee
  precedemment) rendait tout le fichier invalide au chargement, cassant
  entierement l'envoi de Requests ("Send Requests ne marche plus", crash
  `Object tried to call nil in update` sur `ISPZLinuxAction.lua:52`). Corrige
  en extrayant l'evenement de tick dans une variable locale unique. Le
  nouveau fichier `PZLinuxSell.lua` n'etait pas en cause. Par la meme
  occasion, `tools/check_lua_syntax.sh` a ete corrige : son resume final ne
  refletait que les avertissements `luacheck` (qui sort toujours en erreur
  des qu'il y a un avertissement cosmetique, meme sans vrai probleme) et
  masquait silencieusement les echecs de parsing `luac5.1 -p`, qui s'affichaient
  bien dans la sortie mais n'etaient jamais comptes ni pris en compte pour le
  code de sortie du script. Le script compte et affiche desormais
  explicitement `luac5.1 parse errors: N` et ne fait echouer le gate que sur
  ce compteur.
- Nouvelle feature "Sell Surplus" (l'inverse de Requests), compatible
  solo/MP : une fois par jour de jeu, 15 % de chance qu'un acheteur recherche
  exactement une des 13 categories de Requests (vehicule exclu). Le joueur
  choisit jusqu'a 6 objets a vendre depuis l'interface ordinateur; le prix
  (50 % du prix de reference, avec 10 % de chance de tomber sur un gros
  acheteur payant 110-130 % du prix normal) est tire et fige immediatement
  cote serveur des la demande de devis, avant meme que le joueur ne se rende
  a une boite aux lettres pour deposer les objets et finaliser la vente. Toute
  la logique (tirage quotidien, devis, retrait d'inventaire, credit bancaire)
  est autoritaire cote serveur; le client ne fait que proposer une intention.
  Voir `PZLinux.Config.Sell` dans `PZLinuxConfig.lua` et
  `tools/test_sell_surplus.lua`.
- Hacking : retrait des cartes d'identite (`Base.IDcard`, `Base.IDcard_Stolen`,
  `Base.IDcard_Female`, `Base.IDcard_Male`) de `PZLinuxHackingCardTypes`. Seules
  les cartes de credit (`Base.CreditCard`, `Base.CreditCard_Stolen`, deja plus
  rares en jeu) permettent desormais de lancer un hack, ce qui est plus
  coherent avec le monde reel qu'un piratage de carte d'identite. Textes UI et
  documentation (`OVERVIEW.md`, `FAQ.md`) mis a jour en consequence.
- Requests (objets) : nouvelle etape de "recherche de fournisseur" apres le
  paiement d'une commande d'objet. Le resultat (fournisseur trouve ou non, 40 %
  d'echec par defaut) est tire immediatement et de facon autoritative cote
  serveur au moment de la commande, mais seulement revele au client apres un
  delai aleatoire de 10 a 90 secondes reelles (configurable), affiche via le
  systeme de frappe deja accelere par la vitesse de jeu. Le tirage ne peut
  donc jamais etre influence en fermant l'interface ou en se deconnectant,
  puisqu'il est deja fige des la commande. En cas d'echec, le joueur est
  rembourse integralement et un cooldown d'un jour de jeu (configurable)
  s'applique uniquement au type d'objet concerne
  (`PZLinuxRequestSearchCooldowns`), sans bloquer les autres types de
  commandes. Le cooldown suit un compteur de jours de jeu ecoules (et non la
  date calendaire affichee) pour qu'un echec juste avant minuit ne permette
  pas de retenter deux minutes de jeu plus tard a 00h01. Voir
  `PZLinux.Config.Requests` dans `PZLinuxConfig.lua`.
- Manhunt : le rayon d'activation client/serveur passe a 80 cases et devient
  configurable. Une cible situee entre 50 et 80 cases n'est plus ignoree lors
  du chargement de son chunk; le rayon d'interaction final reste inchange.
- Manhunt : suppression du blocage client silencieux lorsque la case exacte de
  la cible n'est pas encore presente. Le serveur recoit la demande et les essais
  reprennent automatiquement toutes les cinq secondes jusqu'au chargement.
- Contrats : le serveur repare un identifiant joueur obsolete depuis son registre
  canonique `byPlayer` ou le dernier contrat actif accepte par ce meme joueur.
  Le type, le proprietaire et le statut restent controles cote serveur.
- Manhunt : seule la destination Muldraugh `10609,9221,0`, validee en jeu, reste
  active. Les autres emplacements sont suspendus jusqu'a leur remplacement.
- Manhunt : la mort est aussi reconnue depuis la cible canonique conservee par
  le serveur lorsque B42 ne restitue pas ses tags ModData dans `OnZombieDead`.
  Le contrat passe alors a `target_down` sans faire reapparaitre la cible.
- Manhunt : suppression du double chemin `addZombieSitting` puis fallback qui
  pouvait creer deux cibles. Une seule API de spawn MP synchrone est utilisee,
  puis la posture passive est appliquee a l'entite obtenue.
- Contrats monde : une exception serveur renvoie maintenant `server_exception`
  au client et laisse une trace explicite, au lieu de provoquer des retries
  silencieux susceptibles de dupliquer un objectif.
- Contrats monde : le detail de l'exception serveur (`errorDetail`) est
  desormais transmis au client afin de diagnostiquer les echecs sans acces
  aux logs serveur.
- Manhunt : le test d'existence de `NetworkZombieAI.extraUpdate` hors du
  `pcall` faisait planter `spawnManhunt` sur les versions de B42 ou cette
  methode n'existe pas. Le `pcall` seul suffisait en MP (le serveur tourne
  dans son propre contexte), mais en solo `spawnManhunt` s'execute de facon
  synchrone et reentrante depuis la boucle de mise a jour du joueur
  (`OnPlayerMove` -> `IsoPlayer.update`), et l'appel a
  `getNetworkCharacterAI()`/`extraUpdate()` y provoquait un veritable crash
  moteur que Kahlua ne peut pas rattraper avec `pcall`. L'appel est supprime :
  la methode n'existe de toute facon pas sur cette version de B42 et ne
  servait a rien.
- Manhunt/vehicules de contrat/cargo/protect : `checkAndSpawnZombie`,
  `checkAndSpawnVehicle`, `checkAndSpawnBox` et
  `PZLinuxRestoreProtectContract` n'ecoutent plus `Events.OnPlayerMove`, qui
  les appelait de facon reentrante depuis l'interieur meme de la mise a jour
  du joueur (`IsoCell.ProcessObjects` -> `IsoPlayer.update`). C'est ce meme
  chemin reentrant qui a fait planter la demande de vehicule de contrat en
  solo (`PZLinuxRequestsFindDeliveredVehicle`, "tried to call nil" sur
  `getCell():getVehicles()`). Ces quatre fonctions restent appelees pour
  chaque joueur local via le sondage `PZLinuxPollWorldObjectiveRestores`,
  deja present sur `Events.OnTick` et limite a une fois par seconde reelle;
  au pire un delai d'une seconde avant reaction au lieu d'un crash.
- Requests : `PZLinuxRequestsFindDeliveredVehicle` protege desormais son
  parcours de la liste des vehicules avec un `pcall` par mesure de securite
  supplementaire.
- Requests (vehicule) : cause reelle du "tried to call nil" identifiee dans le
  bytecode Java du jeu (`projectzomboid.jar`) : `IsoCell:getVehicles()` renvoie
  un `java.util.Set`, qui n'a pas de methode `:get(index)` (seulement `:size()`
  et `:toArray()`, d'ou l'echec systematique une fois entre dans la boucle).
  Un premier correctif est passe par `VehicleManager.instance:getVehicles()`
  (une vraie `ArrayList`), mais ce registre reseau n'est pas fiable en solo et
  laissait la recherche echouer silencieusement, provoquant le meme
  empilement de vehicules. Les deux fonctions de recherche de vehicule livre
  (cote serveur et cote client) convertissent maintenant le `Set` d'origine
  via `:toArray()` puis `ipairs()`, exactement comme le fait deja le jeu
  lui-meme pour un autre `Set` (`item:getTags():toArray()` dans
  `server/Vehicles/Vehicles.lua`), sans dependre d'aucun registre reseau.
- Requests (vehicule) MP : la commande de vehicule ne livrait jamais rien en
  MP reel bien que le debit et le point sur la carte fonctionnaient. Cause :
  `PZLinuxOnItemRequestCar`, `PZLinuxRequestLocationX/Y/Z` et
  `PZLinuxRequestVehicleDeliveryId` n'etaient ecrits que dans la copie serveur
  du ModData; contrairement a chaque champ de contrat, ils n'etaient jamais
  recopies explicitement dans le ModData local du client a la reception de
  `PZLinuxRequestOrderResult`, qui se contentait d'afficher le point sur la
  carte depuis la reponse brute. Le suivi client (`checkAndSpawnVehicle`) ne
  voyait donc jamais la demande en attente. Ces champs sont desormais
  recopies explicitement, comme les champs de contrat le sont deja.
- Requests (vehicule) : les logs de diagnostic ajoutes pour la MP ci-dessus
  spammaient une ligne par tick indefiniment tant qu'une livraison restait en
  attente de confirmation visuelle (par exemple si le joueur s'eloigne du
  vehicule deja livre). Ils sont maintenant limites a une ligne toutes les 20
  secondes et distinguent explicitement "en attente de confirmation visuelle"
  de "trop loin pour redemander un spawn".
- Dialogues et frappe (`PZLinuxTyping.lua`) : tous les delais (boot, connexion,
  dialogues de contrat, dialogues de requests) etaient mesures avec l'horloge
  reelle (`getTimestampMs()`), independante de la vitesse de simulation. Un
  joueur en vitesse x2/x3/x4 ne voyait donc aucune acceleration. L'horloge
  interne accumule maintenant le temps reel ecoule multiplie par
  `getGameSpeed()`, ce qui accelere avec la vitesse de jeu tout en continuant
  d'avancer normalement en pause (`getGameSpeed() == 0` est traite comme 1x
  pour ne pas geler les dialogues pendant une pause, comportement deja voulu
  par l'usage de `Events.OnTickEvenPaused`).
- Requests (vehicule) : une livraison ne se confirme cote serveur que si le
  client la voit visuellement pres du joueur. Si cette confirmation n'arrivait
  jamais (le joueur repart avec le vehicule sans jamais re-declencher le
  sondage au bon moment, perte reseau ponctuelle), `PZLinuxOnItemRequestCar`
  pouvait rester bloque a 1 indefiniment, empechant toute nouvelle commande
  Request pour ce joueur. Une nouvelle tentative de commande verifie desormais
  l'anciennete de la livraison en attente (`PZLinuxRequestVehicleOrderedHour`)
  et l'auto-repare si elle date de plus de deux heures de jeu -- mais
  uniquement si le vehicule a deja ete cree cote serveur (via
  `PZLinuxRequestsFindDeliveredVehicle`). Le vehicule et sa cle ne sont crees
  que lorsque le joueur s'approche une premiere fois du point de livraison
  (`dist < 50` dans `checkAndSpawnVehicle`); si le joueur n'a jamais fait ce
  trajet, rien n'existe encore et l'auto-reparation ne doit surtout pas
  effacer le flag, sous peine de faire perdre silencieusement au joueur le
  vehicule et la cle qu'il a deja payes, sans aucun moyen de les recuperer.
  Un test dedie couvre les deux cas (jamais spawne -> reste bloque; deja
  livre -> se repare).
- Admin : nouvelle option `PZLinux Admin > Add funds to bank` (menu contextuel
  du monde) pour ajouter des fonds a son propre compte a des fins de test.
  Meme protection que "Force contract on board" : reservee a `-debug` en solo
  et au niveau d'acces admin en MP, avec verification d'autorite cote serveur
  (`PZLinuxContractsHasAdminAccess`) independante du client. Reutilise
  `PZLinuxApplyBankCredit` deja utilise par les rewards de contrat.
- Requests (vehicule) : tant que la recherche ci-dessus echouait, chaque
  relance (toutes les 5 secondes) qui ne retrouvait pas le vehicule deja
  livre en spawnait un nouveau, empilant des doublons identiques. La
  recherche retire desormais explicitement tout doublon partageant le meme
  `PZLinuxRequestVehicleDeliveryId` et ne garde que le premier, sur le meme
  principe que le nettoyage des doublons Manhunt. Une sauvegarde deja
  affectee se corrige toute seule au prochain sondage tant que la livraison
  est encore en attente.
- Manhunt : la depouille de la cible decapitee est maintenant retiree cote
  client via un broadcast `PZLinuxContractDeadBodyRemoved`, comme cela se
  faisait deja pour les zombies captures. Le corps ne restait visible que
  parce que sa suppression serveur n'etait jamais synchronisee.
- Ordinateur/Contrats/Mailbox/ATM : les timed actions a duree infinie
  (`ISPZLinuxAction`, `ISMailBoxAction`, `ISStreetMailBoxAction`, `ISATMAction`)
  se terminent maintenant d'elles-memes quand leur panneau se ferme sans
  qu'un autre menu soit demande a la place (valider ou annuler un contrat,
  deposer un colis, etc.). Avant ce correctif, le personnage restait fige
  dans l'animation jusqu'a ce que le joueur bouge ou appuie sur echap.
- Capturer un zombie vivant : `PZLinuxFindZombie` exigeait un `getOnlineID()`
  valide (>= 0). En solo (et sur certains zombies MP) cet ID reste toujours a
  -1, donc le contrat 6 echouait systematiquement en solo depuis son
  introduction du 2026-08-01, independamment des correctifs Manhunt/MP de
  cette session. Un repli par position confirmee (meme principe que
  `PZLinuxFindDeadBody` et le ciblage Manhunt) corrige la capture en solo.

All notable changes to PZLinux are documented in this file. Pre-1.0 entries are
preserved as historical notes and may describe systems replaced by 1.0.0.

## [1.0.0] - Unreleased

### Added

- Added a translated Network Reputation screen showing the authoritative score,
  status, purchase-price modifier and qualitative mail frequency without
  revealing future mail timing.
- Added Blackjack with a real 52-card deck, dealer rules, server-side settlement
  and mood effects based on the size and outcome of a bet.
- Added six-seat Texas Hold'em Poker with configurable lobbies, AI opponents,
  persistent table stacks, side pots, all-in handling and hand evaluation.
- Added Poker hand names and a 300-sample equity estimate calculated without
  reading hidden opponent cards.
- Added finite, persistent ATM cash reserves initialized between $10,000 and
  $50,000.
- Added a shared weekly Contracts board and persistent world-contract registry.
- Added persistent objective ownership and `PZLinuxContractId` tags for shared
  and stealable multiplayer contract objectives.
- Added server idempotency by player, command and request ID to prevent duplicate
  payments or world mutations after clicks and network retries.
- Added restart rollback for temporary Blackjack, Hacking, Poker and Zombie Race
  sessions.
- Added a persistent server-wide Dark Web catalog refreshed every 24 in-game
  hours, with finite stock tiers from 10-15 common items down to 1-2 items worth
  $10,000 or more.
- Added shared, city-aware Build 42.20 location pools: 37 package destinations,
  22 cargo points, 16 manhunt points, 7 protection points and 36 vehicle points.
- Added 20 synchronized B42 JSON translation catalogs and automated key,
  placeholder and UTF-8 validation.
- Added local validation tools for Lua syntax, LuaCheck, assets, translations,
  locations, authority boundaries, Poker and server log monitoring.

### User Interface

- Reworked Dark Web offer rows into fixed responsive columns with separate name
  and price/stock lines, UTF-8-safe truncation and full item tooltips so long
  item names and translated action labels cannot overlap quantities or buttons.
- Fixed missing values on translated Reputation lines and rounded all displayed
  reputation scores, thresholds and modifiers to whole numbers while retaining
  full server-side precision.
- Centralized translated UI formatting around temporary value markers so native
  `getText` cannot erase Reputation or Contract values before Lua renders them.
- Localized contract completion receipts in every shipped language and fixed
  missing reward and zombie-count values by formatting the authoritative receipt
  fields directly in Lua.
- Kept the completion reward visible in rich-text panels by rendering the
  authoritative amount before the dollar suffix and persisting an explicit
  `moneyEarned` receipt field.
- Fixed the initial multiplayer Contracts board schedule, which could postpone
  its first weekly refresh until day 14; legacy boards now regenerate once on
  migration and then refresh every configurable 168 world hours.

### Multiplayer And Security

- Fixed kill-zombie contracts remaining at zero in multiplayer by snapshotting
  and periodically reconciling the server-side player kill counter; clients still
  cannot submit zombie kills themselves.
- Added B42 multiplayer kill attribution through the zombie's server-known
  network owner when `getAttackedBy()` is empty, with delayed-counter absorption
  preventing the same death from being credited twice.
- Removed the legacy empty location header from location-free contract notes,
  eliminating the stray `:` and `*` lines shown above kill objectives.
- Moved bank balances, ATM deposits and withdrawals to server-authoritative
  commands with explicit inventory replication.
- Moved Dark Web offer generation, purchases, sales, pending deliveries and
  mailbox redemption to server-authoritative flows.
- Made Dark Web stock shared by every player and rejected stale purchases when
  another player has already bought the remaining quantity.
- Moved Trading prices, wallets, purchases, sales and the 5% transaction fee to
  a shared server market.
- Moved contract preview, acceptance, cancellation, world objectives, deposits,
  completion, rewards and reputation changes to server-authoritative flows.
- Contract clients now send only the selected contract ID; locations, targets,
  item requests, quantities and rewards are generated from server allowlists.
- Moved Request orders, pricing, pending deliveries, mailbox parcels and vehicle
  spawning to server-authoritative flows.
- Moved Mail generation, mission acceptance, item consumption, rewards and
  reputation to server-authoritative flows.
- Moved Hacking card consumption, account generation, password attempts, locks
  and transfers to server-authoritative flows.
- Removed Hacking passwords from client responses and client state.
- Moved Blackjack, Poker and Zombie Race debit, state and settlement to
  server-authoritative sessions.
- Added distance, Z-level, object identity, objective-state and persistent-tag
  validation to sensitive mailbox and contract world commands.
- Removed client-side authority to delete contract corpses, zombies, cargo or
  delivered inventory items.
- Added explicit B42 container packets for cash, parcels, contract items, reward
  items and requested vehicle keys created or removed by the server.
- Centralized direct player resolution so multiplayer flows do not implicitly
  mutate player zero.
- Restored missing Cargo, Manhunt and Protect world objectives after reconnect
  from their persistent server records, without duplicating tagged entities.
- Hardened Cargo restoration so contract type 7 remains actionable when legacy
  client flags are stale, and replaced invisible legacy objects with a tagged
  `IsoThumpable` crate registered as a special world object before replication.
- Kept killed Manhunt targets in the corpse-interaction state until their proof
  is collected.
- Broadcast validated live-zombie captures from the authoritative server so the
  captured zombie is neutralized and removed from every connected client.
- Spawn Manhunt targets and protection hordes through the game population helper,
  using a nearby free square when the mission marker itself is obstructed.
- Localized contract, mail, mailbox, computer-repair and ATM context-menu actions
  across every language catalog shipped with the mod.
- Restored visible IRC-style sender names in every contract conversation after
  the rich-text migration, using bracketed names that cannot be parsed as tags.
- Fixed Cargo objectives in multiplayer by replicating their world object after
  insertion with its real square index, finding a nearby free spawn tile and
  validating pickup from the authoritative contract location even if the visual
  crate is missing on a client.
- Made Cargo restoration idempotent: repeated client recovery requests now
  reuse and retransmit the same tagged server crate instead of deleting and
  recreating it every five seconds.
- Added a one-time Cargo visual migration from v2 to v3 and explicit sprite
  replication, so contracts already in progress replace their old invisible
  object without creating duplicate crates.
- Fixed Cargo removal ordering so the server broadcasts and removes the world
  object atomically instead of attempting to transmit an object already gone.
- Restored stationary seated Manhunt targets, expanded their free-square search
  radius and returned the authoritative spawn coordinates for MP diagnostics.
- Reworked Manhunt spawning as a three-stage fallback which prefers the native
  `addZombieSitting` helper, then the population outfit helper and finally direct
  creation. B42.20 can replicate a visible target while retaining `onlineId=-1`,
  so v3 targets are also matched by their server-confirmed spawn position. The
  server keeps one canonical target, removes duplicate retries, and logs every
  spawn method and rejection.
- Made Manhunt corpse validation independent from unreliable corpse ModData in
  multiplayer: the server records the canonical target death position and only
  accepts a zombie body at that position while the contract is `target_down`.
- Migrated Manhunt targets to v4 actors kept replicated and immobile by the
  server, then made passive only after becoming visible to the client. Their
  ModData is no longer sent before B42 registers the moving object. A runtime
  canonical reference prevents repeated recovery requests from spawning
  duplicates, while the synchronized `target_down` status and a wider corpse
  scan restore the decapitation context action in multiplayer.
- Restricted package-context diagnostics to package contracts so Manhunt right
  clicks no longer flood the client log with misleading `option missing` lines.
- Added a once-per-second world-objective recovery poll for Manhunt, Cargo,
  Protect and requested vehicles. Manhunt now waits for its client chunk before
  requesting creation, and retries continue even after the player stops moving.
- Added an administrator-only context menu for forcing any of the 12 contracts
  onto the shared board. The server validates access, keeps the forced offer
  available for testing and removes it normally when a player accepts it. Solo
  players only receive this menu when the game is launched with `-debug`.
- Migrated requested vehicle delivery to the positioned B42 vehicle-spawn API,
  with canonical model/location/proximity checks, nearby free-square selection,
  synchronized key rollback on failure and throttled client retry requests.
- Changed requested vehicles to a two-phase MP delivery: paid state remains
  pending until the tagged vehicle has a valid server network registration and
  the client sees it. Retries retransmit the same vehicle, empty/stale IDs cannot
  match another car and forged confirmations cannot consume the order.
- Fixed vehicle Request quotes selecting several cars while the server delivered
  only one. Each quote now contains one vehicle at the authoritative price, and
  conflicting vehicle/item deliveries are rejected before debit instead of
  overwriting an already-paid pending order.
- Prevented contract completion and cancellation responses from opening a
  second Contracts window over the existing payment receipt.
- Localized both mailbox interfaces and selected their action label from the
  authoritative pending pickup and contract-delivery state.

### Economy

- Rebalanced Dark Web prices for firearms, ammunition, explosives, generators,
  armor, strong melee weapons, books and rare magazines.
- Displayed the remaining Dark Web stock beside each purchase price and disabled
  exhausted offers immediately after their last unit is purchased. Sell offers
  also display the total quantity available in the player's inventory.
- Increased Request base prices and capped the Plant Scavenging discount at 15%.
- Reduced easy contract rewards while retaining stronger payouts for dangerous
  objectives.
- Added a configurable 5% Trading fee: purchases pay gross plus fee and sales
  receive gross minus fee.
- Added a configurable reputation range from -99 to 200. Contract cancellations
  apply a server-side penalty, completed contracts grant reputation and passive
  decay slowly returns positive or negative values toward neutral.
- Applied reputation surcharges and discounts to authoritative Dark Web and
  Request purchase prices.
- Centralized world-age scarcity for Dark Web and Request purchases: prices stay
  at x1 for the first three months, rise every three months and cap at x8 after
  two years. Contract rewards are deliberately excluded.
- Added configurable price-rounding tiers of $5, $10, $50, $100 and $500.
  Purchases round up, Dark Web resale rounds down and final contract rewards
  round to the nearest tier after mission modifiers.
- Capped the rare Mail cash bonus at $100-$300.

### Contracts And World Objectives

- Rebuilt all 12 contract mission definitions around one canonical mission and
  dialogue structure while preserving their informal IRC writing style.
- Extracted contract target names and automobile, medical and weapon request
  allowlists into dedicated shared data modules.
- Added canonical contract previews and notes generated from server state.
- Added live Kill Zombies progress to the synchronized inventory note.
- Fixed active Kill Zombies contracts disappearing after the first server-side
  kill update.
- Fixed accepted contracts becoming hidden when the weekly board renewed.
- Consumed accepted offers globally until the next weekly board generation,
  preventing repeated acceptance and payment of the same offer.
- Added contract synchronization on reconnect, computer close and relevant
  context-menu interactions.
- Made package retrieval depend on the player's real position inside a
  configurable five-tile objective zone rather than a clicked map object.
- Made contract delivery item removal server-authoritative and explicitly
  synchronized to the owning client.
- Made contract completion feedback idempotent so repeated context-menu opening
  cannot replay rewards, sounds or mood effects.
- Made Cargo objectives recoverable after reconnect or chunk loss: the server
  reuses an existing tagged crate and recreates it only when it is missing.
- Added persistent unread contract-payment receipts, acknowledged only after the
  Contracts UI displays the authoritative reward amount.
- Kept contract-payment reports visible until the player explicitly opens the
  available-contract list, preventing asynchronous board refreshes from hiding
  the reward summary.
- Replaced single-line contract dialogue labels with fixed-size wrapped panels,
  automatic scrolling and controls kept outside the transcript for long
  translations.
- Fixed Auto Parts, Medical and Weapons previews displaying a transient `nil`
  quantity, and resolved requested item names through the player's local Project
  Zomboid translation catalog.
- Added a 5% reward modifier per absolute Z level for elevated and underground
  mission objectives.
- Removed the legacy `RetrievePackage.lua` implementation.

### Betting And Interface

- Replaced the Poker list with a compact oval table for the CRT interface.
- Reduced Poker to six total seats and hide eliminated opponents from the table.
- Kept authoritative AI difficulty active while removing it from client
  snapshots and visible UI.
- Displayed each seat's latest action, current stack, cumulative hand
  contribution and revealed showdown cards.
- Added a stable randomized visual seat for the player.
- Added translation-safe Poker action rows and end-of-hand controls.
- Fixed Poker hands stalling after the player folded.
- Distinguished player elimination from table victory when a Poker session ends.
- Automatically cash out the player's remaining Poker stack when leaving,
  minimizing or closing the betting interface.
- Rebuilt Blackjack on a face-to-face oval table with dealer and player cards,
  values, bet and outcome contained inside the CRT.
- Rendered hearts and diamonds in red while clubs and spades retain the terminal
  green color.
- Replaced Zombie Race progress text with moving runner icons and delayed payout
  until the animation reaches the finish.
- Restored the continuous Zombie Race speed formula, removed finish-position tie
  bias and replaced fixed odds with a server-authoritative pari-mutuel pool.
- Added 200-800 virtual bettors, proportional payout sharing, a configurable 15%
  pool commission, estimated multipliers and a $2,000 ordinary-race bet cap.
- Recalibrated virtual-bettor weighting for the larger crowds so favorites no
  longer receive systematically underpriced odds.
- Added race-market versioning so obsolete open cards without player tickets
  are regenerated after an odds-model update.
- Added 4% server liquidity to each Zombie Race prize pool and restored
  fractional `N/1` odds: final 25/1 odds return the stake plus 25 times its value.
- Replaced unlimited instant Zombie Races with five shared server departures per
  in-game day at 08:00, 10:00, 12:00, 14:00 and 16:00.
- Added persistent scheduled tickets, multiple advance bets, automatic server
  settlement while the UI is closed and a compact recap of up to five unread
  results.
- Added automatic cleanup for settled races while retaining races with unpaid
  offline tickets.
- Added a shared Sunday 16:00 super jackpot race with 500-1,300 virtual bettors
  and $50,000 of post-commission server liquidity, capped at one $500 ticket per
  player to contain its deliberately positive promotional return.
- Removed the obsolete SFX toggle from computer interfaces.
- Reworked the ATM layout to show ATM cash and player balance without overlap.

### Localization And Text

- Migrated UI and Sandbox translations to B42 `IG_UI.json` and `Sandbox.json`
  catalogs.
- Added English and French catalogs plus Czech, German, Spanish, Hungarian,
  Italian, Japanese, Korean, Dutch, Norwegian, Polish, Portuguese, Brazilian
  Portuguese, Russian, Thai, Turkish, Ukrainian, Simplified Chinese and
  Traditional Chinese catalogs.
- Migrated Request messages, mission-location descriptions, contract controls
  and major betting labels away from hard-coded UI text.
- Replaced the Request conversation label with a fixed rich-text panel supporting
  wrapping, conditional scrolling and automatic scrolling to new messages.
- Centralized UTF-8-safe simulated typing and human reply delays across Contracts,
  Requests, Internet login and ATM authentication.

### Fixed

- Fixed hosted multiplayer ATM deposits not removing physical cash and
  withdrawals not creating synchronized cash.
- Fixed nested carried bags and exact bundle change during ATM deposits.
- Fixed Dark Web and Request mailbox deliveries being consumed without creating
  a synchronized parcel or vehicle key.
- Fixed Mail and Dark Web reward flows consuming mission items before confirming
  reward creation.
- Fixed contract dialogue tracebacks caused by stale or missing local reward
  snapshots.
- Fixed contract objective flags not reaching hosted multiplayer clients after
  acceptance.
- Fixed delivered contract packages remaining in the player's inventory.
- Fixed repeated contract-completion messages and sounds after right-clicking.
- Fixed Request vehicle price display differing from the authoritative debit.
- Fixed empty Dark Web parcels, zero-quantity purchases and hidden quantity
  controls after filtering.
- Fixed Hacking manual input, attempt counters, card restoration and password
  leakage.
- Fixed Trading and Wallet charts when every displayed value is identical.
- Fixed cargo cleanup and duplicate zombie-spawn event registration.
- Fixed timed actions and UI paths receiving a missing world object or resolving
  the wrong local player.

### Internal

- Split static configuration and domain data into modules for economy, Dark Web,
  Trading, requests, contracts, mission locations, mail, gambling and Poker.
- Centralized the Trading initialization and refresh wrappers in shared runtime
  code, removing client redefinitions and Lua load-order dependent behavior.
- Kept existing public table and helper names where required for save, UI and
  server compatibility.
- Prefixed sensitive network commands and results with `PZLinux`.
- Added Project Zomboid-aware LuaCheck configuration and removed the unsafe
  undefined-global warning class from the migration backlog.
- Removed the 12 remaining W211 unused-local warnings from Condition, Dark Web
  and Mail without changing runtime behavior; LuaCheck now reports 98 warnings
  and 0 errors.
- Fixed the Wallet W411 local-variable redefinition by assigning distinct names
  to the Quantity and Price column controls; LuaCheck now reports 97 warnings and
  0 errors.
- Removed the unused Mail layout assignment reported as W311 without changing
  list positioning; LuaCheck now reports 96 warnings and 0 errors.
- Removed both W431 upvalue shadowing cases. Mail now distinguishes its header
  coordinate from mouse coordinates, and the Wallet chart captures the explicit
  UI player instead of resolving player zero implicitly; LuaCheck now reports 94
  warnings and 0 errors.
- Removed all 20 whitespace-only W611 warnings and all 4 comment-whitespace W614
  warnings without changing W613 dialogue strings; LuaCheck now reports 70
  warnings and 0 errors.
- Added cross-platform live log monitoring with a native Windows PowerShell
  watcher and automatic `/pz-logs` detection for Windows-hosted dev containers.
- Extracted the authoritative Zombie Race card, winner and payout calculations to
  a shared pure Lua engine, then added a reproducible balance simulator and
  Markdown report for the lowest-odds betting strategy.
- Calibrated the pari-mutuel crowd model over 100,000 deterministic races: the
  favorite strategy records 21.16% wins, 94.85% RTP and no position bias above
  one percentage point.
- Added deterministic schedule regression coverage for Sunday detection, daily
  slots, multiple tickets, duplicate rejection, recap replacement and automatic
  bank settlement.
- Final release validation still requires an updated full-repository metrics run
  and the documented two-client dedicated-server campaign.

### Known Limitations

- Controller navigation is not yet implemented.
- Split-screen is not officially supported.
- Afrikaans, Catalan and Vietnamese translation catalogs are not yet included.
- Generated translations still benefit from native-speaker proofreading.

## [0.1.12-rc1]

- Fixed the contract interface offering only a single contract type.

## [0.1.12]

- Added a chance to find money and a weapon inside contract briefcases.
- Reduced Dark Web resale prices.
- Added all skill magazines and books to the Dark Web.
- Reduced computer wear by half.
- Fixed Kill Zombies contracts not counting kills.
- Reduced the live-zombie capture reward.
- Removed the inventory note after requesting a vehicle.
- Added a randomized initial balance for new players.
- Increased Request prices to improve balance.
- Based Kill Zombies rewards on the number of required kills.
- Added a chance that no contact answers a Request and increased reply delays.
- Added a 10% chance for parcels to be stolen during mailbox retrieval.
- Added electronic equipment to the Dark Web.
- Added lower-yield multi-card automatic Hacking.
- Dropped compatibility with versions before Build 42.13 after Lua API changes.
- Added contracts to deliver a computer or a fridge.
- Added the first reputation system.
- Added the Mail interface, ammunition and medical delivery missions, spam and
  advertisements.
- Changed the email domain from Hotmail to AOL for the 1994 setting.
- Added desktop notifications for new mail.

## [0.1.11-rc6]

- Fixed Lua errors in the ATM password interface.
- Fixed computer repairs failing with electronic parts in the inventory.
- Limited computer repair actions to condition below 15% instead of 50%.

## [0.1.11-rc5]

- Adjusted simulated keyboard typing speed and reduced interface sound volume.
- Prevented zero-quantity Dark Web purchases from creating empty packages or XP.
- Fixed Lua errors triggered by zombie kills.
- Added requested automobile-part details to contract notes.
- Fixed automobile parts not being accepted for delivery.
- Balanced automobile-part rewards against part value.

## [0.1.11-rc4]

- Added a Sandbox multiplier for sale prices.
- Fixed completion menus for several contract types.
- Fixed Lua errors in Kill Zombies contracts.

## [0.1.11-rc3]

- Fixed stale contracts not being removed in a new game.
- Added a Sandbox multiplier for purchase prices.

## [0.1.11-rc2]

- Fixed mission information appearing before a contract was accepted.

## [0.1.11-rc1]

- Improved support for a second local player.
- Changed Zombie Race minimum odds to 2/1.
- Added Foraging XP to Dark Web purchases and sales.
- Added destination cities to relevant contracts.
- Added Electricity XP for computer repairs and successful Hacking.
- Added boredom, stress and happiness effects to Hacking, betting, Trading and
  contract completion.
- Began extracting editable data tables from feature files.

## [0.1.11]

- Replaced the contract log with a compact inventory paper note.
- Added more active-mission information to contract notes.
- Fixed computer messages overflowing the screen.
- Fixed mailbox Lua errors caused by uninitialized Requests.
- Added a map note for requested vehicles.
- Added contract-completion music and removed map annotations after cancellation
  or completion.
- Added generator power consumption for computers and ATMs.
- Added computer condition, electronic-part repairs and condition-specific boot
  sounds.
- Added bars and ingots to the Dark Web.
- Moved Dark Web purchase collection to mailboxes.
- Applied the Foraging discount to Request items.
- Added halo notifications for important actions.

## [0.1.10-rc2]

- Fixed map annotations in saves where the map had never been opened.
- Fixed stock-action prices before the Trading interface was opened.

## [0.1.10-rc1]

- Fixed map indicators in new games.
- Made contracts available during the first week.
- Fixed mailbox package error messages.

## [0.1.10]

- Added multiple package-retrieval destinations.
- Added a $5 contract bonus per zombie killed.
- Fixed Request pagination and live-zombie capture reset behavior.
- Mixed Request items for more varied delivery parcels.
- Added electronic, repair, material and seed Request categories.
- Added cargo, building protection, medical delivery and weapon delivery
  contracts.
- Added contract circles and summaries to the map.
- Fixed ID cards not being consumed after Hacking progression.
- Added credit-card Hacking.
- Added requested-vehicle map markers.
- Combined mailbox collection and deposit interactions.
- Added kill progress to the contract notebook.

## [0.1.9-rc1]

- Fixed zombie-blood contracts accepting an old target.
- Fixed timed actions remaining active after closing an interface.
- Fixed credit cards not being consumed.
- Fixed fish missing from Request deliveries.

## [0.1.9]

- Added Zombie Race betting.
- Added the live-zombie capture contract.
- Fixed minimizing a contract during dialogue returning to the wrong screen.
- Fixed Dark Web purchases and sales closing the PZLinux interface.
- Added all modern and standard parts to automobile-part contracts.
- Increased the PZLinux world-menu detection radius.
- Added vehicle Requests.
- Allowed PZLinux timed actions to follow game-speed acceleration.

## [0.1.8-rc2]

- Fixed a contract variable regression introduced in 0.1.8-rc1.

## [0.1.8-rc1]

- Added an SFX button to shorten interface message animations.

## [0.1.8]

- Migrated persistent values from `PZLinux.ini` to ModData.
- Preserved interface position while navigating between menus.
- Added cigarettes, cigars, knives and hats to Dark Web trading.
- Added hackable credit cards to the Dark Web.
- Removed the cap on company stock prices.
- Added manhunt, package retrieval, zombie blood and automobile-part contracts.
- Prevented remote use of computers, mailboxes and ATMs.
- Indexed purchase prices to world age.
- Added IRC Requests for canned goods, fish, books, fruit, meat and vegetables.
- Added IRC message notifications.
- Reduced Dark Web resale prices to account for Contracts and Requests.
- Fixed interfaces remaining open after the player moved away from a computer.

## [0.1.7-rc1]

- Fixed mailbox availability depending on mailbox direction.

## [0.1.7]

- Corrected Hacking interface text.
- Made interfaces movable.
- Fixed the Dark Web offer list during the first 24 world hours.
- Fixed sold items not being removed after consecutive Dark Web actions.
- Renamed the Dark Web `Sold` action to `Sell`.
- Linked interface sound volume to the game audio setting.
- Split Dark Web buying and selling into separate interfaces.
- Added suspicious sale packages and mailbox sale completion.
- Reduced the maximum visible Dark Web offer list from 100 to 50.
- Added Dark Web buy/sell help screens.
- Limited Mastermind to six attempts and ignored invalid non-four-digit inputs.

## [0.1.6]

- Fixed Trading token counts.
- Fixed ATM deposits for player names containing special characters.
- Began storing player money in ModData.
- Added weapon mods and magazines.
- Added ID-card Hacking.
- Improved 4K interface support.
- Added menu buttons for direct submenu navigation.
- Removed zero-quantity positions from the Trading wallet.

## [0.1.5]

- Linked connection speed to Electricity skill.
- Fixed Dark Web search and added Enter-key submission.
- Linked Dark Web prices to Foraging skill.
- Refreshed Dark Web offers every 24 world hours.
- Added Trading and its wallet interface.
- Renamed the mod to PZLinux and introduced the unified terminal menu.
- Required an active internet connection for online submenus.
- Added 24-hour internet sessions and computer uptime.
- Added computer boot sound and connection-status messages.
- Moved the CRT power button to the bottom-left corner.

## [0.1.4]

- Prevented Dark Web access from non-computer world objects.
- Fixed selling items that shared the same display name.

## [0.1.3]

- Added ATM deposits, withdrawals and persistent bank storage.
- Added ATM, buy, sell and error sounds.
- Added support for depositing cash carried in backpacks.
- Added connection extension and menu navigation controls.
- Linked ATM access from the Dark Web interface.
- Fixed menu scrolling alignment and computer startup logs.

## [0.1.2]

- Fixed selling items from nearby inventories.
- Added Money Bundles worth $100.
- Improved performance to reduce crashes and FPS issues.

## [0.1.1]

- Added a power-off button during computer initialization.
- Fixed incomplete interface cleanup after disconnecting.
- Replaced the disconnect button with the power-off button.
