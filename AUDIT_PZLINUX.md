# AUDIT_PZLINUX.md

Date : 2026-07-31  
Cible : Project Zomboid Build 42 stable  
Perimetre : depot local complet, Lua client/server/shared, docs existantes, traductions, outils, economie, MP et qualite release.

## 1. Resume executif

PZLinux est un mod riche et deja bien avance pour une release 1.0.0 : ordinateur interactif, ATM, banque, Dark Web, Trading, Wallet, contrats, missions, Requests, Mails, Hacking, Blackjack et course de zombies existent vraiment dans le depot.

Les grosses migrations MP recentes ont change la situation : la plupart des flux economiques sensibles passent maintenant par `server/PZLinuxServerCommands.lua` et des helpers partages `PZLinux*`. Le probleme principal n'est plus l'absence totale d'architecture serveur, mais le durcissement de cette architecture avant annonce "MP complet".

Verdict global : **Corrections importantes necessaires**.

Verdicts separes :

- SOLO : **Compatible avec corrections mineures**, mais a retester en jeu apres les migrations serveur/fallback.
- MP coop : **Fonctionnel avec reserves**, car les grands flux sont migrés mais quelques validations serveur restent trop permissives.
- Serveur dedie : **Fonctionnel avec reserves importantes**, surtout contrats, sessions temporaires et tests de redemarrage.
- Reconnexion/redemarrage : **Fragile** pour les sessions temporaires de jeux/hacking/offres, meilleur pour les etats stockes en ModData.
- Utilisation simultanee : **A tester en jeu**, meme si un cache idempotent serveur par joueur/commande/requestId protege maintenant les retries reseau et doubles clics simples.

Point critique corrige : `PZLinuxContractsApplyComplete` n'accepte plus `state.activeContract`, `state.reward` ni `state.companyUp` envoyes par le client comme fallback. Le serveur complete maintenant un contrat uniquement depuis le ModData serveur du joueur. Voir [ISPZLinuxVariablesTables.lua](/root/git/PZLinux/Contents/mods/B42%20PZLinux/42/media/lua/shared/ISPZLinuxVariablesTables.lua:3069).

## 3. Architecture actuelle

Structure observee :

- `media/lua/client/Context/World` : UI, context menus, interactions ordinateur/ATM/mailboxes.
- `media/lua/server/PZLinuxServerCommands.lua` : reception des commandes MP et execution serveur.
- `media/lua/shared/ISPZLinuxVariablesTables.lua` : gros fichier central contenant encore helpers, economie, wrappers client/solo, callbacks et sessions.
- `media/lua/shared/PZLinux/` : premiere extraction des donnees configurables/statiques pour la release 1.0.0.
- `media/lua/shared/TimedActions` : timed actions pour ordinateur, ATM, mailboxes, contrats et reparations.
- `media/lua/shared/Translate/EN` : debut de localisation uniquement anglais.
- `media/sandbox-options.txt` : multiplicateurs achat/vente.
- `tools/` : scripts d'audit local, Luacheck, assets et logs.

Point positif : `getPlayer()` direct est centralise. `rg -n "getPlayer\\("` ne trouve que 4 occurrences dans `ISPZLinuxVariablesTables.lua`, dont le helper `PZLinux.getPlayer`.

Point faible en cours de correction : `ISPZLinuxVariablesTables.lua` fait encore trop de choses. Les donnees ATM/Blackjack, locations, courses, Requests, contrats, mails, Dark Web, Trading et formules economie ont ete sorties dans des modules `shared/PZLinux/*`. Le runtime Dark Web vient aussi d'etre separe. Il reste surtout rewards mails, autres runtimes domaine et sessions runtime a separer.

## 4. Etat des fonctionnalites

| Fonctionnalite | Fichiers | SOLO | MP | Serveur dedie | Persistance | Etat | Problemes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Ordinateur/PZLinux UI | `ISContextLinuxMenu.lua`, `ISPZLinuxAction.lua`, `PZLinuxConnectInternet.lua` | Oui | Oui avec reserves | A tester | ModData joueur/objet | Fonctionnel avec reserves | UI souris, noms globaux, textes hardcodes |
| Energie ordinateur/reparation | `ISPZLinuxAction.lua`, `ISPZLinuxRepareAction.lua`, `PZLinuxCondition.lua`, `PZLinuxUtils.lua` | Oui | A tester | A tester | Object ModData | Fonctionnel avec reserves | Timed actions non prefixees, valeurs hardcodees |
| Banque | `ISPZLinuxVariablesTables.lua`, `PZLinuxServerCommands.lua`, `ISContextAtmMenu.lua` | Oui | Oui | Oui avec reserves | Player ModData | Fonctionnel avec reserves | Idempotence serveur ajoutee, reste test simultane |
| ATM cash limite | `ISContextAtmMenu.lua`, `ISATMAction.lua`, shared helpers | Oui | Oui | A tester simultane | Object ModData | A tester en jeu | Course possible a verifier avec 2 joueurs meme ATM |
| Argent liquide | shared helpers ATM | Oui | Oui | A tester | Inventaire joueur | Fonctionnel avec reserves | Ajout/retrait serveur OK, mais a tester conteneurs/equivalence bundle |
| Dark Web achat | `PZLinuxDarkWeb.lua`, shared, server | Oui | Oui | Oui avec reserves | Player ModData pending orders | Fonctionnel avec reserves | Offre en session memoire, idempotence serveur ajoutee |
| Dark Web vente | `PZLinuxDarkWeb.lua`, mailbox contexts, shared | Oui | Oui | Oui avec reserves | Item ModData + Player ModData | Fonctionnel avec reserves | Vente scanne inventaire principal; demande timed action/confirmation |
| Livraison mailbox/street mailbox | `ISContextMailBox.lua`, `ISContextStreetMailBox.lua`, shared | Oui | Oui | A tester | Player ModData | Fonctionnel avec reserves | Double ouverture simultanee a tester |
| Trading/bourse | `PZLinuxTrading.lua`, `PZLinuxWallet.lua`, shared | Oui | Oui | Oui avec reserves | Global ModData + Player ModData | Fonctionnel avec reserves | Volatilite positive attendue, pas de taxes/cooldowns |
| Wallet | `PZLinuxWallet.lua` | Oui | Oui avec snapshot | A tester | Player ModData | Fonctionnel avec reserves | Cle historique `ZLinuxPlayerWallet*` non prefixee PZLinux |
| Hacking bancaire | `PZLinuxHacking.lua`, shared, server | Oui | Oui | Oui avec reserves | Session memoire + bank ModData | Fonctionnel avec reserves | Password renvoye au client; session perdue au redemarrage |
| Cartes ID/Credit card | Hacking shared | Oui | Oui | Oui avec reserves | Inventaire joueur | Fonctionnel avec reserves | Consommation serveur OK, types a maintenir |
| Contrats board | `PZLinuxContracts.lua`, shared, server | Oui | Oui | Oui avec reserves | Global ModData | Fonctionnel avec reserves | Locations encore poussees depuis dialogues client |
| Contrats completion/reward | `PZLinuxContracts.lua`, shared, timed actions | Oui | Fragile | Fragile | Player/Global ModData | Fragile | Fallback client dangereux sur complete |
| Objectifs volables | shared contracts, timed actions | Oui | A tester | A tester | Global/Object/Item ModData | A tester en jeu | Tags IsoObject/zombie apres streaming/reconnexion |
| Requests | `PZLinuxRequest.lua`, shared, server | Oui | Oui | Oui avec reserves | Player ModData | Fonctionnel avec reserves | Table UI dupliquee avec definitions shared |
| Vehicules Requests | shared request spawn | Oui | Oui | A tester | Player ModData puis monde | A tester en jeu | Spawn serveur a tester sur chunk charge |
| Mails missions | `PZLinuxMail.lua`, `PZLinuxMail*.lua`, shared, server | Oui | Oui | Oui avec reserves | Player ModData | Fonctionnel avec reserves | Reward cadeau tres aleatoire/puissant |
| Betting Blackjack | `PZLinuxBetting.lua`, shared, server | Oui | Oui | Oui avec reserves | Session memoire pendant jeu | Fonctionnel avec reserves | Session/stake perdus au redemarrage |
| Betting course | `PZLinuxBetting.lua`, shared, server | Oui | Oui | Oui avec reserves | Session memoire pendant carte | Fonctionnel avec reserves | Esperance possiblement positive selon rating |
| Traductions | Translate/EN + UI | Partiel | Partiel | Partiel | Fichiers lang | Incomplet | EN seulement, 1471 textes candidats hardcodes |
| Manette | Toutes UI ISPanel | Non garanti | Non garanti | Non garanti | n/a | Incomplet | Pas de focus/navigation controller dedies |

## 5. Audit reseau et synchronisation

Module reseau unique : `PZLinux`.

| Module | Commande | Emetteur | Recepteur | Validation serveur | Risque | Correction |
| --- | --- | --- | --- | --- | --- | --- |
| Bank | `PZLinuxBankRequestSync` | Client | Serveur | Lit solde serveur | Bas | OK |
| Bank | `PZLinuxBankDebit` | Client | Serveur | Valide amount > 0 et solde | Moyen | Eviter commande generique debit client; utiliser commandes metier |
| ATM | `PZLinuxAtmRequestSync` | Client | Serveur | Resolve ATM ref | Bas | Tester chunk/objet manquant |
| ATM | `PZLinuxAtmWithdrawal` | Client | Serveur | Solde banque + cash ATM + amount | Moyen | Idempotence ajoutee; tester double joueur |
| ATM | `PZLinuxAtmDeposit` | Client | Serveur | Cash inventaire + amount | Moyen | Idempotence ajoutee |
| Betting | `PZLinuxBlackjackStart/Hit/Stand` | Client | Serveur | Session serveur/debit | Moyen | Gerer restart |
| Betting | `PZLinuxRaceCard/Start` | Client | Serveur | Session serveur/debit | Moyen | Verifier EV |
| Dark Web | `PZLinuxDarkWeb*` | Client | Serveur | Offres serveur, item existe, inventaire | Moyen | Idempotence/double clic |
| Trading | `PZLinuxTradingSnapshot/Buy/Sell` | Client | Serveur | Code, quantite, prix serveur, wallet | Moyen | Idempotence ajoutee; reste taxe/spread |
| Contracts | `PZLinuxContractsBoard` | Client | Serveur | Board serveur | Bas | OK |
| Contracts | `PZLinuxContractAccept` | Client | Serveur | ContractId dans board | Moyen | Ne plus accepter location/info/note client |
| Contracts | `PZLinuxContractCancel` | Client | Serveur | Active player state | Bas | Appliquer malus reputation |
| Contracts | `PZLinuxContractDeposit` | Client | Serveur | Inventaire serveur | Moyen | Distance mailbox a valider cote serveur |
| Contracts | `PZLinuxContractComplete` | Client | Serveur | Corrige : ModData serveur uniquement | Moyen | Tester client forge + completion legitime MP |
| Contracts | `PZLinuxContractWorldEvent` | Client | Serveur | Event name + etat joueur | Moyen | Valider distance/objet/zombie par id |
| Request | `PZLinuxRequestOrder` | Client | Serveur | Type/items/vehicle/location/prix serveur | Bas a moyen | Supprimer table UI dupliquee |
| Request | `PZLinuxRequestDeliver` | Client | Serveur | Pending delivery serveur | Moyen | Distance mailbox a valider |
| Request | `PZLinuxRequestSpawnVehicle` | Client | Serveur | Distance location + pending vehicle | Moyen | Idempotence spawn |
| Mail | `PZLinuxMailAccept/Delete/Complete/Generate` | Client | Serveur | MailId/statut/items/distance | Moyen | Generation client-command a limiter/admin? |
| Hacking | `PZLinuxHackingStart/Auto/Guess/Transfer` | Client | Serveur | Cartes/session/guess/unlock | Moyen | Ne pas renvoyer password complet |

Problemes confirmes :

- Corrige : [PZLinuxServerCommands.lua](/root/git/PZLinux/Contents/mods/B42%20PZLinux/42/media/lua/server/PZLinuxServerCommands.lua:196) n'expose plus les commandes reseau non prefixees `BankRequestSync`, `BankDebit`, `BlackjackStart`, `BlackjackHit`, `BlackjackStand`, `RaceCard`, `RaceStart`. Les handlers utilisent maintenant `PZLinuxBank*`, `PZLinuxBlackjack*` et `PZLinuxRace*`.
- Corrige : [ISPZLinuxVariablesTables.lua](/root/git/PZLinux/Contents/mods/B42%20PZLinux/42/media/lua/shared/ISPZLinuxVariablesTables.lua:3069) ne lit plus `state.activeContract`, `state.reward` ni `state.companyUp` pour la completion contrat.

Risques probables :

- Corrige : un cache idempotent serveur en memoire traite chaque paire joueur/commande/requestId une seule fois et renvoie le resultat cache aux retries.
- Sessions temporaires en tables Lua (`PZLinux.blackjackSessions`, `raceSessions`, `hackingSessions`, offres Dark Web) disparaissent au redemarrage serveur. Cela ne duplique pas forcement, mais peut perdre un stake ou bloquer une UI.
- En heberge, les fichiers shared peuvent executer fallback solo si `isClient()` est faux dans un contexte inattendu. A retester en serveur dedie.

## 6. Audit economique

Sources de revenus :

- Banque initiale aleatoire : [shared line 148](/root/git/PZLinux/Contents/mods/B42%20PZLinux/42/media/lua/shared/ISPZLinuxVariablesTables.lua:148), `$500-$3999`.
- Dark Web vente : prix serveur par item, colis suspect, encaissement mailbox.
- Contrats : rewards de base `$750-$14000`, bonus `zombieCount * 5` a completion.
- Mails : cadeau contenant 1-5 items Dark Web, parfois revolver + argent.
- Hacking : manuel `ZombRand(5,1000)*(Electricity+1)`, auto `ZombRand(300,501)*(Electricity+1)*cartes`.
- Trading : achat/vente d'actions avec variation horaire.
- Betting : Blackjack et course de zombies.

Depenses :

- ATM retrait/depot ne cree pas de richesse, transfert banque <-> cash.
- Dark Web buy.
- Request order.
- Trading buy.
- Betting stake.

Deséquilibres demontrables :

- [PZLinuxMailGiveReward](/root/git/PZLinux/Contents/mods/B42%20PZLinux/42/media/lua/shared/ISPZLinuxVariablesTables.lua:3772) peut encore creer des items puissants choisis dans `PZLinuxDarkWebItemsTable`; le bonus cash rare a ete plafonne de `ZombRand(1, 2000)` a `ZombRand(100, 301)`, soit `$100-$300`.
- [PZLinuxContractsApplyComplete](/root/git/PZLinux/Contents/mods/B42%20PZLinux/42/media/lua/shared/ISPZLinuxVariablesTables.lua:3069) paie `reward + zombieCount * 5`; le reward est maintenant lu depuis le ModData serveur, ce qui retire le risque de reward forge par commande client.
- [PZLinuxTradingGenerateNextPrice](/root/git/PZLinux/Contents/mods/B42%20PZLinux/42/media/lua/shared/ISPZLinuxVariablesTables.lua:2220) donne 1 chance de baisse, 1 chance de hausse et 1 chance stable; l'amplitude basse est jusqu'a -maxPercent, hausse jusqu'a +maxPercent, mais les strategies buy/sell sans frais peuvent exploiter les variations avec assez de capital.
- [PZLinuxRaceStart](/root/git/PZLinux/Contents/mods/B42%20PZLinux/42/media/lua/shared/ISPZLinuxVariablesTables.lua:1156) paie `amount * rating`. Il faut calculer l'esperance exacte par simulation; les ratings faibles sont meilleurs en course, mais le payout utilise le rating du gagnant, ce qui peut creer des cartes a EV positive.

Choix subjectifs de game design :

- Les prix Dark Web rebalances semblent plus proches d'une economie de luxe.
- Les Requests sont cheres, ce qui est sain si le but est du confort payant.
- Hacking est fun mais peut devenir une source de cash sans cooldown si les cartes sont farmables.

Recommandations chiffrees :

- Mail reward : cash rare plafonne a `$100-$300`. Prochaine passe conseillee : remplacer le cadeau Dark Web aleatoire par tiers. T1 70% consommables/outils, T2 25% ammo/medical, T3 5% arme/rare.
- Hacking : cooldown par joueur 12-24h ou chance de lock plus forte; auto hack rendement divise par 2 a 3.
- Trading : ajouter spread/taxe 2%-5% a l'achat et a la vente; limiter la frequence de transaction par heure monde.
- Course : simuler 100k courses par rating pour calculer EV; cap payout net a rating * 0.75 si EV positive.
- Contrats : reputation `gain = difficulty * 2`, annulation `loss = max(1, difficulty)`, decay `0.02` toutes les 10 minutes de jeu.
- ATM : cash initial `$10k-$50k` OK; ajouter journal serveur pour gros retraits > `$10k`.

Debut/milieu/fin de partie :

- Debut : banque initiale + hacking/cartes peut accelerer l'acces a Requests/Dark Web. A limiter par cooldown.
- Milieu : contrats et Requests donnent une boucle de gameplay saine si les missions forcent la sortie.
- Fin : capital important + Trading sans taxe + Dark Web peut transformer le mod en catalogue. Ajouter rendements decroissants/reputation/cooldowns.

## 7. Exploitations et duplication

| Priorite | Probleme | Scenario | Resultat actuel | Attendu | Correction |
| --- | --- | --- | --- | --- | --- |
| P0 | Completion contrat acceptait `state.*` client | Client modifie envoie `PZLinuxContractComplete` avec `activeContract=9`, `reward` | Corrige : le serveur ignore ces champs | Serveur paie seulement si ModData serveur `PZLinuxActiveContract` est 9/10 | Fait, reste test MP |
| P1 | Pas d'idempotence globale | Double clic/retry sur buy/sell/complete | Corrige cote serveur : resultat cache par joueur/commande/requestId | Une transaction `requestId` traitee une seule fois | Fait, reste test live |
| P1 | Distance mailbox pas toujours serveur | Client declenche completion depuis UI contexte | Certains flux se basent surtout sur pending state | Serveur valide objet/mailbox et distance | Passer coord/object ref dans commandes et verifier cote serveur |
| P2 | Sessions jeu/hacking perdues au restart | Redemarrage pendant Blackjack/Hacking | Corrige partiel : rollback persistant de mise Blackjack et cartes Hacking | Remboursement/restauration propre | Fait pour Blackjack/Hacking, reste test live |
| P2 | Hacking password renvoye au client | Client modifie lit le code | Anti-triche faible | Client ne recoit que feedback | Garder password serveur uniquement |
| P2 | Mail reward trop aleatoire | Farm mails | Objets rares/cash gratuits | Reward par tier/cooldown | Rebalancer |

## 8. Audit namespace PZLinux

Resultat script : `293 function declarations do not start with PZLinux`.

Classes/timed actions globales non prefixees principales :

| Nom actuel | Type | Fichier | Risque | Nouveau nom propose | References |
| --- | --- | --- | --- | --- | --- |
| `linuxUI` | UI class | `ISContextLinuxMenu.lua` | Moyen | `PZLinuxComputerUI` | constructeur/show/menu |
| `AtmUI` | UI class | `ISContextAtmMenu.lua` | Moyen | `PZLinuxAtmUI` | `AtmMenu_ShowUI` |
| `darkWebUI` | UI class | `PZLinuxDarkWeb.lua` | Moyen | `PZLinuxDarkWebUI` | callbacks boutons |
| `contractsUI` | UI class | `PZLinuxContracts.lua` | Moyen | `PZLinuxContractsUI` | contrats coroutines |
| `requestUI` | UI class | `PZLinuxRequest.lua` | Moyen | `PZLinuxRequestUI` | show/menu |
| `mailUI` | UI class | `PZLinuxMail.lua` | Moyen | `PZLinuxMailUI` | mail menu |
| `hackingUI` | UI class | `PZLinuxHacking.lua` | Moyen | `PZLinuxHackingUI` | `hackingMenu_ShowUI` |
| `tradingUI` | UI class | `PZLinuxTrading.lua` | Moyen | `PZLinuxTradingUI` | wallet/trading |
| `walletUI` | UI class | `PZLinuxWallet.lua` | Moyen | `PZLinuxWalletUI` | show/menu |
| `conditionUI` | UI class | `PZLinuxCondition.lua` | Bas | `PZLinuxConditionUI` | show/menu |
| `connectUI` | UI class | `PZLinuxConnectInternet.lua` | Bas | `PZLinuxConnectUI` | show/menu |
| `ISATMAction` | TimedAction | `ISATMAction.lua` | Moyen | `PZLinuxAtmAction` | context ATM |
| `ISMailBoxAction` | TimedAction | `ISMailBoxAction.lua` | Moyen | `PZLinuxMailBoxAction` | mailbox |
| `ISStreetMailBoxAction` | TimedAction | `ISStreetMailBoxAction.lua` | Moyen | `PZLinuxStreetMailBoxAction` | street mailbox |
| `ISDropTheMailAction` | TimedAction | `ISTDropTheMailAction.lua` | Moyen | `PZLinuxDropMailAction` | mail completion |
| `ISTakeTheCargoAction` | TimedAction | `ISTakeTheCargoAction.lua` | Moyen | `PZLinuxTakeCargoAction` | contracts |
| `ISTakeThePackageAction` | TimedAction | `ISTakeThePackageAction.lua` | Moyen | `PZLinuxTakePackageAction` | contracts |
| `ISBloodAction` | TimedAction | `ISBloodAction.lua` | Moyen | `PZLinuxBloodAction` | contracts |
| `ISCaptureAction` | TimedAction | `ISCaptureAction.lua` | Moyen | `PZLinuxCaptureAction` | contracts |
| `ISDecapitateAction` | TimedAction | `ISDecapitateAction.lua` | Moyen | `PZLinuxDecapitateAction` | contracts |
| `ISProtectBuildingAction` | TimedAction | `ISProtectBuildingAction.lua` | Moyen | `PZLinuxProtectBuildingAction` | contracts |

Fonctions globales generiques a traiter en priorite :

- `saveAtmBalance`, `loadAtmBalance` : garder wrappers compatibilite, ajouter `PZLinuxSaveAtmBalance/PZLinuxLoadAtmBalance`.
- `linuxMenu_*`, `AtmMenu_*`, `MailBoxMenu_*`, `StreetMailBoxMenu_*`, `completeContractMenu_*`, `completeMail*`.
- `isNearTarget`, `reverseString`, `generatePseudo`, `bagContainsCorpse`, `contractsDrawOnMap`, `getNearbyGenerator`.
- `generateUsername` dans shared.

Risque de migration :

- Renommer une classe UI ou TimedAction casse tous les constructeurs si une reference est oubliee.
- Renommer les commandes reseau casse les clients/serveurs qui ne sont pas a jour. Prevoir alias transitoires.
- Renommer les cles ModData (`ZLinuxPlayerWallet*`, `PZLinux...`) peut casser les sauvegardes. Faire migration douce, jamais suppression directe.

## 9. Analyse Luacheck

Commande :

```bash
luacheck --config tools/.luacheckrc "Contents/mods/B42 PZLinux/42/media/lua"
```

Resultat global :

```text
Total: 128 warnings / 0 errors in 46 files
```

Syntaxe Lua : OK via `luac5.1 -p` sur tous les fichiers Lua.  
Assets PNG/OGG : `tools/audit_assets.sh` n'a pas remonte d'erreur.

| Code | Niveau | Nombre | Fichiers concernes | Explication | Correction |
| --- | --- | ---: | --- | --- | --- |
| W212 | Corrige | 0 | UI/timed actions | arguments callbacks PZ inutilises | Arguments explicites renommes `_button`, `_x`, `_y`, `_self`, etc. |
| W432 | Mineur/Moyen | 53 | UI | shadowing `self` dans closures | Renommer param closure ou accepter si PZ pattern |
| W611 | Mineur | 20 | UI | lignes vides avec whitespace | Nettoyage format |
| W211 | Moyen | 14 | Mail/Condition/DarkWeb | locales inutilisees | Supprimer ou utiliser |
| W612 | Mineur | 8 | UI/Mails | trailing whitespace | Nettoyage |
| W311 | Important | 7 | Contracts/Request/Mail | valeur ecrasee/non lue | Verifier logique, surtout `message` |
| W613 | Mineur | 6 | Mails | whitespace dans strings | Verifier textes voulus |
| W581 | Mineur | 5 | Context menus | expression boolean simplifiable | Facultatif |
| W213 | Mineur | 4 | Trading/Wallet | variable de boucle inutilisee | `_` |
| W614 | Mineur | 4 | commentaires | trailing whitespace comment | Nettoyage |
| W431 | Moyen | 3 | Mail/Request/Wallet | shadowing upvalue | Renommer |
| W231 | Moyen | 1 | Request | variable jamais lue | Supprimer/corriger |
| W411 | Moyen | 1 | Wallet | variable redefinie | Corriger |
| W421 | Moyen | 1 | Request | shadowing local | Renommer |
| W422 | Moyen | 1 | Request | shadowing argument | Renommer |

Classification :

- Erreurs critiques Luacheck : aucune.
- Warnings importants avant release : W311, W411, W421, W422, W231.
- Warnings mineurs restants : W432, W611, W612, W613, W614, W581, W213.
- W212 corrige : les callbacks gardent leur signature compatible PZ, mais les arguments volontairement inutilises sont maintenant prefixes par `_`.
- Faux positifs/acceptables PZ : beaucoup de callbacks UI et TimedAction.

## 10. Separation donnees et logique

Extraction realisee dans cette passe :

- [PZLinuxConfig.lua](/root/git/PZLinux/Contents/mods/B42%20PZLinux/42/media/lua/shared/PZLinux/PZLinuxConfig.lua) : limites ATM `$10k-$50k` et deck Blackjack.
- [PZLinuxMissionLocations.lua](/root/git/PZLinux/Contents/mods/B42%20PZLinux/42/media/lua/shared/PZLinux/PZLinuxMissionLocations.lua) : locations mails et scaffolding locations missions.
- [PZLinuxGamblingData.lua](/root/git/PZLinux/Contents/mods/B42%20PZLinux/42/media/lua/shared/PZLinux/PZLinuxGamblingData.lua) : runners de course.
- [PZLinuxRequestsData.lua](/root/git/PZLinux/Contents/mods/B42%20PZLinux/42/media/lua/shared/PZLinux/PZLinuxRequestsData.lua) : definitions Requests et locations vehicules.
- [PZLinuxContractsData.lua](/root/git/PZLinux/Contents/mods/B42%20PZLinux/42/media/lua/shared/PZLinux/PZLinuxContractsData.lua) : definitions contrats et villes.
- [PZLinuxMailData.lua](/root/git/PZLinux/Contents/mods/B42%20PZLinux/42/media/lua/shared/PZLinux/PZLinuxMailData.lua) : definitions mails et items demandes.
- [PZLinuxDarkWebData.lua](/root/git/PZLinux/Contents/mods/B42%20PZLinux/42/media/lua/shared/PZLinux/PZLinuxDarkWebData.lua) : catalogue items/prix Dark Web.
- [PZLinuxDarkWeb.lua](/root/git/PZLinux/Contents/mods/B42%20PZLinux/42/media/lua/shared/PZLinux/PZLinuxDarkWeb.lua) : runtime Dark Web, generation offres, achats/ventes, deliveries et wrappers callbacks MP/solo.
- [PZLinuxTradingData.lua](/root/git/PZLinux/Contents/mods/B42%20PZLinux/42/media/lua/shared/PZLinux/PZLinuxTradingData.lua) : societes Trading, codes et prix initiaux.
- [PZLinuxEconomy.lua](/root/git/PZLinux/Contents/mods/B42%20PZLinux/42/media/lua/shared/PZLinux/PZLinuxEconomy.lua) : formules argent, prix Dark Web/Requests/Trading, reputation et delai mails.
- [PZLinuxPokerConfig.lua](/root/git/PZLinux/Contents/mods/B42%20PZLinux/42/media/lua/shared/PZLinux/PZLinuxPokerConfig.lua) : lobbies Texas Hold'em, caves, tapis IA, difficultes et noms IA.
- [PZLinuxPokerEngine.lua](/root/git/PZLinux/Contents/mods/B42%20PZLinux/42/media/lua/shared/PZLinux/PZLinuxPokerEngine.lua) : moteur Poker commun solo/MP, evaluation des mains, IA, pots secondaires, sessions isolees et cashout.

Donnees configurables restantes :

| Donnees | Emplacement actuel | Nouveau fichier propose | Validation necessaire | Risque migration |
| --- | --- | --- | --- | --- |
| ATM min/max cash | `PZLinuxConfig.lua` | Fait | min <= max, nombres positifs | Bas |
| Prix Dark Web | `PZLinuxDarkWebData.lua` | Fait | item existe, price > 0, rarete valide | Moyen |
| Request items/prix | `PZLinuxRequestsData.lua` | Fait | table complete, prix > 0 | Moyen |
| Locations mission | `PZLinuxMissionLocations.lua` | Fait partiel | x/y/z numeriques, zone chargeable | Moyen |
| Contrats definitions | `PZLinuxContractsData.lua` | Fait | difficulty 1-5, reward, type | Moyen |
| Trading companies | `PZLinuxTradingData.lua` | Fait | code unique, prix initial > 0 | Moyen |
| Formules economie/prix/reputation | `PZLinuxEconomy.lua` | Fait | comportement identique, pas de mutation client | Moyen |
| Betting configs | `PZLinuxGamblingData.lua`, `PZLinuxConfig.lua` | Fait partiel | odds, min/max stake | Bas |
| Mail rewards | `PZLinuxMailGiveReward` | `PZLinuxMailRewards.lua` | item existe, quantite, tiers | Moyen |
| Textes UI | Lua partout + EN partiel | Translate files | placeholders identiques | Eleve |

Architecture cible conseillee :

- `PZLinux.Config` : defaults globaux, sandbox, limites.
- `PZLinux.Economy` : formules pures, taxes, inflation, reputation.
- `PZLinux.Items` : Dark Web, Requests, Mails.
- `PZLinux.Contracts` : definitions statiques de contrats.
- `PZLinux.Missions` : locations/spawns statiques.
- `PZLinux.Stocks` : societes, prix, volatilite.
- `PZLinux.Gambling` : blackjack, races, futurs jeux.
- `PZLinux.Translations` : cles et helpers.

Chaque fichier config doit contenir uniquement nombres, strings, booleens et tables simples. La logique doit valider `nil`, prix negatif, quantite invalide, probabilite > 100, cooldown negatif, item inexistant, type incorrect et table incomplete.

## 11. Nettoyage et qualite du code

Suppression sure :

- Whitespace Luacheck W611/W612/W614.
- Variables locales inutilisees non exposees : `LAST_CONNECTION_TIME`, `STAY_CONNECTED_TIME` dans certaines UI si plus utilisees.

Suppression a confirmer :

- `DebugMenu_OnDebug1/2` et `ISContextDebug.lua` si non destines a release publique.
- `doc/prompt.md` et `doc/roadmap.md` apres consolidation.

Simplification/fusion :

- Unifier `MailBoxUI` et `StreetMailBoxUI`.
- Unifier les boutons topbar des UI.
- Extraire le code de boot/typing/coroutines repetitif.
- Remplacer les tables UI dupliquees Request par les definitions shared.

Conservation necessaire :

- Wrappers `loadAtmBalance/saveAtmBalance` pour compat ancienne UI/sauvegardes, mais a deprecier.
- Cles ModData historiques.
- Alias de commandes reseau pendant une version si renommage.

Performance :

- Events `OnPlayerMove` surveillent les spawns de contrats/vehicules/box. Correct si checks rapides, mais a profiler en serveur peuple.
- `EveryTenMinutes` serveur mail/reputation est raisonnable.

## 12. Etat des traductions

Langues demandees par PZ : EN, AF, DE, NL, VI, TR, CA, ES, FR, IT, HU, NO, PL, PT-BR, PT, CS, RU, UK, TH, ZH-HANS, ZH-HANT, JA, KO.

Etat actuel :

| Langue | Fichiers | Cles manquantes | Cles obsoletes | Textes hardcodes | Risque |
| --- | --- | ---: | ---: | ---: | --- |
| EN | `IG_UI_EN.txt`, `Sandbox_EN.txt` | Reference incomplete | A verifier | 1471 candidats | Moyen |
| Toutes les autres | Aucun fichier | Toutes | 0 | 1471 candidats | Eleve |

Passages sensibles :

- `context:addOption(...)` dans context menus.
- `HaloTextHelper.addGoodText/addBadText`.
- Labels/boutons dans toutes UI.
- Contrats : variables `message` dans `PZLinuxContracts.lua`, `RetrievePackage.lua`, `PZLinuxKillZombies.lua`, `PZLinuxSendComputer.lua`, `PZLinuxSendFridge.lua`.
- Mails : sujets, corps, rewards, erreurs.
- Request IRC : dialogues concatenes, placeholders prix/items.

Ne pas traduire automatiquement pendant cette phase. Le boot PC peut rester en anglais pour realisme, mais boutons, erreurs et feedback joueur doivent etre localises.

## 13. Audit manette

Etat : **Incomplet / non bloquant 1.0.0 si annonce comme clavier-souris**.

Risques :

- ISPanel custom sans focus chain explicite.
- Beaucoup de boutons crees dynamiquement sans navigation directionnelle.
- Scroll panels Dark Web/Trading/Wallet/Contracts non verifies au controller.
- Champs texte Hacking/Request/Trading demandent clavier.
- Retour/fermeture et changement d'onglet pas mappes controller.
- Ecran partage : l'usage du `player` est meilleur depuis la passe getPlayer, mais le focus UI reste a tester.

Plan manette :

1. Ajouter focus initial par fenetre.
2. Definir ordre de navigation pour boutons visibles.
3. Ajouter gestion B/Back pour fermer/revenir.
4. Ajouter scrolling liste via stick/dpad.
5. Remplacer les champs numeriques critiques par steppers ou presets quand possible.
6. Tester split-screen deux joueurs.

## 14. Problemes classes P0 a P4

### P0 - Critique

| Probleme | Fichier/lignes | Scenario | Actuel | Attendu | Correction | Risque regression | Difficulte |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Completion contrat avec donnees client | `ISPZLinuxVariablesTables.lua:3069-3088` | Client forge `PZLinuxContractComplete` | Corrige dans le code : les champs client ne sont plus lus | Serveur ignore tous les montants client | Fait, a valider en MP live | Moyen sur contrats legitimes | Moyenne |

### P1 - Majeur

| Probleme | Fichier/lignes | Scenario | Actuel | Attendu | Correction | Risque | Difficulte |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Absence idempotence globale | `PZLinuxServerCommands.lua:5-76` | Double clic/retry | Corrige : handler renvoie le resultat cache sans rejouer la mutation | requestId unique rejoue resultat sans mutation | Fait, reste test live | Bas | Moyenne |
| Contrat accept utilise location/info client | `ISPZLinuxVariablesTables.lua:2992-2998` | Client forge location/objectif | Etat mission serveur pollue | Serveur choisit location/objectifs | Deplacer generation de mission cote serveur | Moyen | Elevee |
| Distance mailbox a durcir | mailbox contexts/shared | Client appelle deliver/complete hors contexte | Certains flux valident pending seulement | Coord objet + distance serveur | Passer object ref/coords et verifier | Moyen | Moyenne |

### P2 - Important

- Corrige : commandes reseau `Bank*`, `Blackjack*`, `Race*` prefixees en `PZLinux*`.
- 293 fonctions/classes non prefixees.
- Hacking renvoie le password complet au client.
- Trading sans taxe/spread.
- Mail reward trop aleatoire et potentiellement trop fort.
- Corrige partiel : rollback serveur au retour joueur pour mise Blackjack et cartes Hacking apres redemarrage.

### P3 - Robustesse/architecture

- 1471 textes hardcodes candidats.
- Donnees configurables melangees avec UI/logique.
- Gros fichier shared trop central.
- UI controller incomplete.
- Luacheck warnings importants restants : W311/W411/W421/W422/W231.

### P4 - Nettoyage

- Whitespace.
- Variables inutilisees de callbacks.
- Commentaires historiques.
- Consolidation docs terminee par ce fichier.

## 15. Plan de correction

1. Durcir contrats accept/world events : generation locations et objectifs cote serveur.
2. Durcir mailbox/request/darkweb delivery avec distance/objet cote serveur.
3. Renommer classes UI/timed actions par lots, avec recherche references avant chaque patch.
4. Continuer l'extraction des configs statiques en modules `PZLinux.*`, surtout rewards mails et sessions runtime.
5. Rebalancer Mail rewards par tiers, Hacking cooldown, Trading taxe/spread, Race EV.
6. Migrer traductions EN puis generer fichiers langue vides/anglais de fallback.
7. Nettoyer Luacheck important restant : W311/W411/W421/W422/W231.
8. Nettoyer Luacheck mineur restant : W432, whitespace, W581, W213.
9. Ajouter support manette.

## 16. Checklist de tests manuels

SOLO :

- Nouveau personnage : ouvrir ordinateur, connecter internet, fermer/reouvrir.
- ATM : depot, retrait, retrait superieur au solde, retrait superieur au cash ATM.
- Dark Web : achat item, livraison perdue, livraison reussie, vente et encaissement.
- Trading : snapshot, buy, sell, wallet apres achat.
- Hacking : no card, manuel reussi, 6 echecs lock, auto, transfert.
- Request : item, vehicule, location trop loin, livraison mailbox.
- Contracts : accepter chaque type, annuler, completer, recevoir paiement.
- Mails : generation, accept, delete, complete, missing items.
- Betting : Blackjack win/lose/push/blackjack, race win/lose.

MP serveur dedie :

- Deux joueurs ouvrent le meme ATM, retrait simultane.
- Deux joueurs Trading : meme prix, achat/vente persistants apres reconnexion.
- Deux joueurs Dark Web : offres, achats, livraison apres reconnexion.
- Deux joueurs contrat global : objectif vole livre par autre joueur.
- Redemarrage serveur avec order pending Dark Web/Request.
- Redemarrage pendant Blackjack/Race/Hacking : verifier perte ou recovery.
- Client modifie : tenter `PZLinuxContractComplete` sans completion serveur.
- Tester split-screen si supporte par environnement.

Controller :

- Focus initial dans chaque UI.
- Navigation boutons topbar.
- Scroll listes longues.
- Champ Hacking/quantite avec clavier virtuel ou fallback.
- Fermeture/revenir.

## 17. Todo restante avant release 1.0.0

### P0 - Bloquant release

- [ ] Tester en jeu la correction serveur-autoritaire de `PZLinuxContractsApplyComplete` avec un client legitime et un client forge.
- [x] Ajouter une idempotence serveur generique par joueur/commande/requestId pour eviter les doubles clics, resend reseau et doubles paiements.
- [ ] Durcir `PZLinuxContractAccept` : le serveur doit choisir et valider les locations/objectifs, sans accepter de payload gameplay critique pousse par le client.
- [ ] Durcir les deliveries mailbox/Dark Web/Request : validation serveur de la distance, du type d'objet et de l'etat pending avant mutation.

### P1 - Important MP et economie

- [ ] Tester MP dedie avec deux joueurs : ATM simultane, trading meme prix, Dark Web livraison, contrat vole/livre par un autre joueur.
- [x] Decider et appliquer une politique de redemarrage serveur : rollback/remboursement. Blackjack rembourse la mise persistante, Hacking restaure les cartes consommees, Race et Dark Web offers n'ont pas de ressource bloquee durablement dans l'etat actuel.
- [ ] Retirer le password complet des reponses Hacking client et ne renvoyer que le feedback de tentative.
- [ ] Ajouter taxe/spread Trading pour eviter les profits trop faciles sur variation de prix.
- [ ] Simuler l'esperance des courses et ajuster payout/ratings si des cartes sont EV positives.
- [ ] Ajouter cooldown ou rendement decroissant au Hacking.
- [ ] Rebalancer les rewards mails par tiers : consommables/outils majoritaires, ammo/medical rares, armes tres rares.

### P2 - Maintenabilite

- [x] Extraire `PZLinuxDarkWebItemsTable` dans un module dedie de donnees Dark Web.
- [x] Extraire `PZLinuxTradingCompanyNameTable` dans un module dedie de donnees Trading.
- [x] Extraire les formules economie/prix/reputation vers un module `PZLinuxEconomy`.
- [x] Extraire le runtime/callbacks Dark Web vers un module domaine `PZLinuxDarkWeb`.
- [x] Ajouter Texas Hold'em Poker server-authoritative avec config dediee, moteur partage, commandes MP et tests moteur hors-jeu.
- [ ] Continuer a reduire `ISPZLinuxVariablesTables.lua` : garder helpers/runtime, sortir tables et callbacks par domaine.
- [ ] Renommer les classes UI/timed actions globales sans prefixe par lots, avec recherche de references apres chaque lot.
- [ ] Nettoyer les warnings Luacheck importants restants : W311, W411, W421, W422, W231.

### P3 - Accessibilite et localisation

- [ ] Migrer les textes UI hardcodes vers `Translate/EN`.
- [ ] Creer les fichiers de langues supportees par PZ avec fallback anglais au depart.
- [ ] Tester les textes longs avec scroll/retours ligne pour eviter les debordements UI.
- [ ] Ajouter support manette : focus initial, ordre de navigation, back/cancel, scroll listes, champs numeriques.
- [ ] Tester split-screen ou au minimum verifier que les helpers player ne reviennent pas au joueur 0.

### P4 - Nettoyage final

- [ ] Nettoyer whitespace W611/W612/W614 hors strings voulues.
- [ ] Remplacer les variables de boucle inutilisees W213 par `_`.
- [ ] Simplifier les expressions W581 quand c'est lisible.
- [ ] Mettre a jour `doc/release.md`, `README`/Workshop si present, et l'audit final apres tests live.
- [ ] Faire une passe finale `luac5.1`, `luacheck`, audit assets PNG/OGG et test en jeu B42.20.0 Stable.

## 18. Git diff resume

Etat observe du diff suivi avant creation de ce rapport central :

```text
41 files changed, 13055 insertions(+), 9324 deletions(-)
```

Etat apres cette phase d'audit :

```text
?? AUDIT_PZLINUX.md
M  doc/release.md
anciens audits/TODO supprimes du dossier doc/ mais non affiches comme deletions car ils etaient non suivis par Git
```

Le diff existant est deja massif suite aux migrations precedentes. Cette phase d'audit ne modifie pas le code fonctionnel du mod.
