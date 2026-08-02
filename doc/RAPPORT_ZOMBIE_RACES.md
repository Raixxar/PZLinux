# Rapport d'equilibrage Zombie Race

Rapport genere le 2026-08-02 14:58:36 UTC.

## Scenario

- Courses simulees : **100000**
- Mise fixe : **$100.00**
- Graine aleatoire : **42020**
- Strategie : choisir la cote pari-mutuel la plus basse; departager les ex aequo au hasard.
- Reglement : pool pari-mutuel, commission de **15.00%**, partage proportionnel aux mises gagnantes.
- Liquidite serveur ajoutee au pool : **4.00%** des mises virtuelles.
- Cible RTP configuree : **85.00% a 95.00%**

La simulation charge directement `PZLinuxGamblingData.lua` et `PZLinuxRaceEngine.lua`, le meme moteur pur que le serveur.

## Verdict

**Dans la cible configuree.**

| Indicateur | Resultat |
| --- | ---: |
| Mises totales | $10000000.00 |
| Gains verses | $9485003.00 |
| Resultat net joueur | $-514997.00 |
| Resultat net maison | $514997.00 |
| Victoires joueur | 21157 / 100000 |
| Taux de victoire | 21.16% |
| RTP joueur | 94.85% |
| Avantage maison | 5.15% |
| Intervalle RTP 95 % | 93.70% - 96.00% |
| Cartes avec favoris ex aequo | 0.51% |
| Nombre moyen de favoris minimum | 1.01 |
| Duree moyenne | 20.80 ticks |
| Parieurs virtuels moyens | 139.81 |
| Mises virtuelles moyennes | $36697.97 |
| Liquidite serveur moyenne | $1465.52 |
| Pool de prix moyen | $38163.49 |
| Tranches de cote significatives fortement hors cible | 0 |

## Distribution des pools

Les percentiles montrent la variation produite par les parieurs virtuels sur l'ensemble de la campagne.

| Indicateur | Min | P10 | Mediane | Moyenne | P90 | Max |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Parieurs virtuels | 80 | 91 | 140 | 140 | 188 | 200 |
| Mises virtuelles | $17345.00 | $23985.00 | $36630.00 | $36697.97 | $49435.00 | $58810.00 |
| Liquidite serveur | $690.00 | $955.00 | $1465.00 | $1465.52 | $1975.00 | $2350.00 |
| Pool de prix | $18035.00 | $24940.00 | $38095.00 | $38163.49 | $51410.00 | $61160.00 |
| Pari joueur maximum | $1730.00 | $2395.00 | $3660.00 | $3667.56 | $4940.00 | $5880.00 |
| Cote finale du favori | 1.30/1 | 2.80/1 | 3.57/1 | 3.56/1 | 4.31/1 | 5.53/1 |
| Cotes indicatives, tous concurrents | 1.32/1 | 3.81/1 | 5.98/1 | 12.05/1 | 13.26/1 | 1941.25/1 |

### Frequence des grandes cotes

Une carte contient huit concurrents. La cote d'un concurrent est indicative avant la mise du joueur; sa cote finale est recalculee au lancement.

| Seuil | Concurrents concernes | Part des places | Cartes avec au moins un | Part des cartes |
| ---: | ---: | ---: | ---: | ---: |
| 10/1 ou plus | 133612 | 16.70% | 85448 | 85.45% |
| 15/1 ou plus | 65846 | 8.23% | 54059 | 54.06% |
| 20/1 ou plus | 43776 | 5.47% | 38686 | 38.69% |
| 25/1 ou plus | 32952 | 4.12% | 30215 | 30.21% |
| 50/1 ou plus | 14051 | 1.76% | 13607 | 13.61% |
| 100/1 ou plus | 6232 | 0.78% | 6155 | 6.16% |

## Grille de gains par cote

Le paiement total inclut le remboursement de la mise. La derniere colonne indique la masse nette necessaire pour conserver cette cote lorsque le total des mises gagnantes vaut $1,000.

| Cote finale | Mise | Benefice | Paiement total | Pool net pour $1,000 gagnants |
| ---: | ---: | ---: | ---: | ---: |
| 1/1 | $100.00 | $100.00 | $200.00 | $2000.00 |
| 2/1 | $100.00 | $200.00 | $300.00 | $3000.00 |
| 3/1 | $100.00 | $300.00 | $400.00 | $4000.00 |
| 5/1 | $100.00 | $500.00 | $600.00 | $6000.00 |
| 10/1 | $100.00 | $1000.00 | $1100.00 | $11000.00 |
| 15/1 | $100.00 | $1500.00 | $1600.00 | $16000.00 |
| 20/1 | $100.00 | $2000.00 | $2100.00 | $21000.00 |
| 25/1 | $100.00 | $2500.00 | $2600.00 | $26000.00 |
| 50/1 | $100.00 | $5000.00 | $5100.00 | $51000.00 |
| 100/1 | $100.00 | $10000.00 | $10100.00 | $101000.00 |

## Resultats par cote selectionnee

| Cote | Paris | Part | Victoires | Taux victoire | RTP |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 1.2/1-1.3/1 | 1 | 0.00% | 1 | 100.00% | 230.00% |
| 1.4/1-1.5/1 | 9 | 0.01% | 5 | 55.56% | 135.78% |
| 1.5/1-1.6/1 | 12 | 0.01% | 4 | 33.33% | 85.33% |
| 1.6/1-1.7/1 | 27 | 0.03% | 9 | 33.33% | 87.81% |
| 1.7/1-1.8/1 | 45 | 0.04% | 11 | 24.44% | 67.36% |
| 1.8/1-1.9/1 | 87 | 0.09% | 20 | 22.99% | 65.45% |
| 1.9/1-2.0/1 | 152 | 0.15% | 50 | 32.89% | 96.85% |
| 2.0/1-2.1/1 | 235 | 0.24% | 70 | 29.79% | 90.82% |
| 2.1/1-2.2/1 | 351 | 0.35% | 116 | 33.05% | 104.02% |
| 2.2/1-2.3/1 | 572 | 0.57% | 154 | 26.92% | 87.42% |
| 2.3/1-2.4/1 | 828 | 0.83% | 226 | 27.29% | 91.38% |
| 2.4/1-2.5/1 | 1202 | 1.20% | 306 | 25.46% | 87.74% |
| 2.5/1-2.6/1 | 1631 | 1.63% | 451 | 27.65% | 98.10% |
| 2.6/1-2.7/1 | 2100 | 2.10% | 526 | 25.05% | 91.33% |
| 2.7/1-2.8/1 | 2591 | 2.59% | 643 | 24.82% | 93.00% |
| 2.8/1-2.9/1 | 3210 | 3.21% | 782 | 24.36% | 93.70% |
| 2.9/1-3.0/1 | 3876 | 3.88% | 967 | 24.95% | 98.46% |
| 3.0/1-3.1/1 | 5179 | 5.18% | 1224 | 23.63% | 95.77% |
| 3.1/1-3.2/1 | 4650 | 4.65% | 1025 | 22.04% | 91.47% |
| 3.2/1-3.3/1 | 5768 | 5.77% | 1299 | 22.52% | 95.61% |
| 3.3/1-3.4/1 | 6303 | 6.30% | 1378 | 21.86% | 94.99% |
| 3.4/1-3.5/1 | 6475 | 6.48% | 1480 | 22.86% | 101.57% |
| 3.5/1-3.6/1 | 6418 | 6.42% | 1322 | 20.60% | 93.62% |
| 3.6/1-3.7/1 | 6684 | 6.68% | 1376 | 20.59% | 95.63% |
| 3.7/1-3.8/1 | 6399 | 6.40% | 1331 | 20.80% | 98.68% |
| 3.8/1-3.9/1 | 6098 | 6.10% | 1133 | 18.58% | 89.99% |
| 3.9/1-4.0/1 | 5663 | 5.66% | 1096 | 19.35% | 95.69% |
| 4.0/1-4.1/1 | 5054 | 5.05% | 919 | 18.18% | 91.71% |
| 4.1/1-4.2/1 | 4264 | 4.26% | 810 | 19.00% | 97.70% |
| 4.2/1-4.3/1 | 3652 | 3.65% | 667 | 18.26% | 95.76% |
| 4.3/1-4.4/1 | 2912 | 2.91% | 513 | 17.62% | 94.11% |
| 4.4/1-4.5/1 | 2425 | 2.43% | 410 | 16.91% | 92.08% |
| 4.5/1-4.6/1 | 1800 | 1.80% | 293 | 16.28% | 90.19% |
| 4.6/1-4.7/1 | 1222 | 1.22% | 195 | 15.96% | 89.99% |
| 4.7/1-4.8/1 | 871 | 0.87% | 157 | 18.03% | 103.61% |
| 4.8/1-4.9/1 | 540 | 0.54% | 98 | 18.15% | 105.97% |
| 4.9/1-5.0/1 | 315 | 0.32% | 37 | 11.75% | 69.78% |
| 5.0/1-5.1/1 | 209 | 0.21% | 30 | 14.35% | 86.73% |
| 5.1/1-5.2/1 | 102 | 0.10% | 11 | 10.78% | 66.17% |
| 5.2/1-5.3/1 | 38 | 0.04% | 10 | 26.32% | 164.05% |
| 5.3/1-5.4/1 | 19 | 0.02% | 1 | 5.26% | 33.42% |
| 5.4/1-5.5/1 | 10 | 0.01% | 1 | 10.00% | 64.60% |
| 5.5/1-5.6/1 | 1 | 0.00% | 0 | 0.00% | 0.00% |

## Biais par position sur la carte

Une course parfaitement symetrique donnerait environ 12,50 % de victoires a chaque position.

| Position | Victoires | Taux | Ecart a 12,50 % |
| ---: | ---: | ---: | ---: |
| 1 | 12573 | 12.57% | +0.07 points |
| 2 | 12552 | 12.55% | +0.05 points |
| 3 | 12513 | 12.51% | +0.01 points |
| 4 | 12232 | 12.23% | -0.27 points |
| 5 | 12515 | 12.52% | +0.02 points |
| 6 | 12442 | 12.44% | -0.06 points |
| 7 | 12518 | 12.52% | +0.02 points |
| 8 | 12655 | 12.65% | +0.15 points |

## Vitesse et cotes du pool

La vitesse conserve la formule continue historique : `5 + random(0, 100 - rating) / 25`.

| Rating | Avance par tick | Avance moyenne |
| ---: | ---: | ---: |
| 2 | 5.00 a 8.92 | 6.96 |
| 25 | 5.00 a 8.00 | 6.50 |
| 50 | 5.00 a 7.00 | 6.00 |
| 75 | 5.00 a 6.00 | 5.50 |
| 100 | 5.00 | 5.00 |

Le rating pilote uniquement la performance. La cote `N/1` est derivee du pool : une cote finale de 25/1 rend la mise et verse 25 fois la mise en benefice.

## Resultats par coureur

| Coureur | Apparitions | Rating moyen | Victoires | Taux victoire | Paris favori | RTP favori |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Alpha Rot | 20071 | 10.95 | 2689 | 13.40% | 2634 | 95.23% |
| Ash King | 20003 | 25.97 | 1060 | 5.30% | 1094 | 78.82% |
| Ash Runner | 19983 | 6.00 | 4264 | 21.34% | 4150 | 113.90% |
| Backstreet | 19867 | 10.96 | 2674 | 13.46% | 2667 | 97.03% |
| Bad Omen | 19984 | 8.50 | 3297 | 16.50% | 3390 | 96.95% |
| Bare Bones | 19828 | 10.93 | 2660 | 13.42% | 2652 | 88.03% |
| Blue Rot | 19931 | 51.11 | 489 | 2.45% | 543 | 82.06% |
| Broken Shoes | 19954 | 10.94 | 2688 | 13.47% | 2657 | 93.60% |
| Cloud Cover | 20028 | 51.07 | 486 | 2.43% | 562 | 76.78% |
| Cold Track | 19908 | 8.48 | 3333 | 16.74% | 3311 | 101.92% |
| County Line | 20145 | 8.53 | 3370 | 16.73% | 3460 | 95.22% |
| Crown Fall | 19922 | 50.91 | 487 | 2.44% | 562 | 87.42% |
| Dead Sprint | 19999 | 8.49 | 3414 | 17.07% | 3390 | 99.55% |
| Door Knock | 19909 | 10.97 | 2705 | 13.59% | 2683 | 93.57% |
| Dust Walker | 19916 | 8.46 | 3419 | 17.17% | 3364 | 101.80% |
| Fence Jumper | 20165 | 11.10 | 2673 | 13.26% | 2620 | 86.76% |
| Fever Dream | 20054 | 25.86 | 1085 | 5.41% | 1115 | 98.91% |
| Final Bite | 19912 | 10.99 | 2707 | 13.59% | 2669 | 94.10% |
| Grave Pace | 19991 | 8.57 | 3347 | 16.74% | 3325 | 92.29% |
| Green River | 20181 | 10.95 | 2752 | 13.64% | 2736 | 97.81% |
| Headwind | 19843 | 26.19 | 981 | 4.94% | 968 | 85.95% |
| Hungry Road | 20185 | 10.94 | 2672 | 13.24% | 2682 | 85.39% |
| Last Hour | 20511 | 50.84 | 493 | 2.40% | 536 | 80.44% |
| Last Turn | 19928 | 8.49 | 3344 | 16.78% | 3318 | 94.88% |
| Long Road | 20026 | 8.50 | 3291 | 16.43% | 3367 | 92.34% |
| Lost Arms | 19914 | 11.03 | 2614 | 13.13% | 2692 | 89.01% |
| Moon Walker | 19933 | 8.46 | 3378 | 16.95% | 3316 | 98.05% |
| Nameless | 20009 | 10.96 | 2669 | 13.34% | 2683 | 95.57% |
| Night Signal | 20189 | 8.51 | 3356 | 16.62% | 3376 | 96.63% |
| No Witness | 19905 | 10.99 | 2614 | 13.13% | 2645 | 87.22% |
| Old Shambler | 20069 | 11.00 | 2614 | 13.03% | 2686 | 90.45% |
| Pine Ridge | 19831 | 25.83 | 1097 | 5.53% | 1051 | 79.58% |
| Raven Creek | 20080 | 6.00 | 4363 | 21.73% | 4247 | 107.11% |
| Red Mile | 19935 | 8.50 | 3288 | 16.49% | 3304 | 99.51% |
| Rotten Luck | 19985 | 10.96 | 2780 | 13.91% | 2677 | 94.03% |
| Sleepless | 20011 | 8.53 | 3346 | 16.72% | 3358 | 95.74% |
| South Horde | 19980 | 10.99 | 2709 | 13.56% | 2667 | 89.48% |
| Spark Plug | 19875 | 25.98 | 1038 | 5.22% | 1062 | 83.42% |
| Storm Rider | 20053 | 11.00 | 2712 | 13.52% | 2720 | 91.18% |
| Wormwood | 19987 | 25.94 | 1042 | 5.21% | 1061 | 84.73% |

## Diagnostic automatique

- La frequence des favoris de pool ex aequo est de 0.51%.
- Aucun biais de position superieur a 1 point n'est visible dans cet echantillon.
- Le RTP de la strategie favorite se situe dans la plage cible.
- Le payout inclut la mise retournee et depend du pool final : `pool net x mise joueur / mises gagnantes`.

## Etude : course cagnote du dimanche

La course hebdomadaire avec **$50,000 ajoutes par le serveur** est implementee comme un rendez-vous global. Ajouter $50,000 a chaque session personnelle aurait permis a chaque joueur de recreer la subvention et aurait ete exploitable.

Architecture retenue :

1. Creer une seule course partagee le dimanche du calendrier en jeu a 16:00.
2. Ouvrir les mises avant la course, avec 500 a 1,000 parieurs virtuels et les mises reelles de tous les joueurs.
3. Fermer les mises a 16:00, verrouiller les cotes, puis calculer un seul vainqueur autoritaire.
4. Calculer `pool net = mises apres commission + $50,000`, afin que toute la cagnote promotionnelle soit distribuee.
5. Conserver les tickets dans le ModData serveur et crediter aussi les gagnants deconnectes lors de leur prochaine connexion.
6. Limiter chaque joueur a un ticket de $500 maximum pour contenir le RTP promotionnel et eviter la manipulation des cotes.

Exemple indicatif avec 750 parieurs a $262 de moyenne :

| Element | Montant |
| --- | ---: |
| Mises virtuelles | $196,500 |
| Pool apres commission de 15 % | $167,025 |
| Cagnote serveur ajoutee | $50,000 |
| Masse finale a partager | $217,025 |

Une simulation separee de 10 000 super cagnottes mesure environ 164 % de RTP en jouant toujours le favori. Ce rendement promotionnel est volontaire mais justifie le plafond hebdomadaire de $500 par joueur.

Cette variante est couverte par un test deterministe du calendrier, des tickets multiples, du reglement automatique et du paiement bancaire. Une validation avec deux clients sur serveur dedie reste requise.

## Corrections recommandees

1. Verifier en jeu que le pool, le nombre de parieurs, le plafond et les cotes restent lisibles dans le CRT.
2. Tester plusieurs tailles de mises pour confirmer que le partage proportionnel ne produit aucun gain inferieur a la mise sur un pari gagnant autorise.
3. Comparer la strategie favorite a un pari aleatoire et aux autres tranches de multiplicateur avant de figer la commission.

## Reproduction

```bash
bash tools/simulate_zombie_races.sh --runs 100000 --stake 100 --seed 42020 --target-min 0.85 --target-max 0.95
```
