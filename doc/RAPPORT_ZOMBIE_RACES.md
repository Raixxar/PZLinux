# Rapport d'equilibrage Zombie Race

Rapport genere le 2026-08-02 15:24:21 UTC.

## Scenario

- Courses simulees : **100000**
- Mise fixe : **$100.00**
- Graine aleatoire : **42020**
- Sensibilite des parieurs : exposant **39**
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
| Gains verses | $9449793.00 |
| Resultat net joueur | $-550207.00 |
| Resultat net maison | $550207.00 |
| Victoires joueur | 29730 / 100000 |
| Taux de victoire | 29.73% |
| RTP joueur | 94.50% |
| Avantage maison | 5.50% |
| Intervalle RTP 95 % | 93.57% - 95.42% |
| Cartes avec favoris ex aequo | 0.41% |
| Nombre moyen de favoris minimum | 1.00 |
| Duree moyenne | 20.80 ticks |
| Parieurs virtuels moyens | 500.83 |
| Mises virtuelles moyennes | $131468.88 |
| Liquidite serveur moyenne | $5256.36 |
| Pool de prix moyen | $136725.24 |
| Tranches de cote significatives fortement hors cible | 0 |

## Distribution des pools

Les percentiles montrent la variation produite par les parieurs virtuels sur l'ensemble de la campagne.

| Indicateur | Min | P10 | Mediane | Moyenne | P90 | Max |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Parieurs virtuels | 200 | 260 | 502 | 501 | 740 | 800 |
| Mises virtuelles | $46155.00 | $68280.00 | $131625.00 | $131468.88 | $194300.00 | $222535.00 |
| Liquidite serveur | $1845.00 | $2730.00 | $5265.00 | $5256.36 | $7770.00 | $8900.00 |
| Pool de prix | $48000.00 | $71010.00 | $136890.00 | $136725.24 | $202070.00 | $231435.00 |
| Pari joueur maximum | $2000.00 | $2000.00 | $2000.00 | $2000.00 | $2000.00 | $2000.00 |
| Cote finale du favori | 0.00/1 | 1.49/1 | 2.28/1 | 2.31/1 | 3.16/1 | 5.20/1 |
| Cotes indicatives, tous concurrents | 0.00/1 | 2.53/1 | 6.78/1 | 97.88/1 | 185.70/1 | 7495.66/1 |

### Frequence des grandes cotes

Une carte contient huit concurrents. La cote d'un concurrent est indicative avant la mise du joueur; sa cote finale est recalculee au lancement.

| Seuil | Concurrents concernes | Part des places | Cartes avec au moins un | Part des cartes |
| ---: | ---: | ---: | ---: | ---: |
| 10/1 ou plus | 286706 | 35.84% | 99699 | 99.70% |
| 15/1 ou plus | 200956 | 25.12% | 95490 | 95.49% |
| 20/1 ou plus | 162411 | 20.30% | 89205 | 89.20% |
| 25/1 ou plus | 143622 | 17.95% | 84379 | 84.38% |
| 50/1 ou plus | 115009 | 14.38% | 74435 | 74.44% |
| 100/1 ou plus | 96057 | 12.01% | 67011 | 67.01% |

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
| 0.0/1-0.1/1 | 1 | 0.00% | 1 | 100.00% | 100.00% |
| 0.2/1-0.3/1 | 4 | 0.00% | 3 | 75.00% | 94.00% |
| 0.3/1-0.4/1 | 13 | 0.01% | 10 | 76.92% | 103.38% |
| 0.4/1-0.5/1 | 27 | 0.03% | 16 | 59.26% | 86.22% |
| 0.5/1-0.6/1 | 66 | 0.07% | 39 | 59.09% | 91.61% |
| 0.6/1-0.7/1 | 135 | 0.14% | 76 | 56.30% | 92.98% |
| 0.7/1-0.8/1 | 227 | 0.23% | 122 | 53.74% | 94.07% |
| 0.8/1-0.9/1 | 391 | 0.39% | 190 | 48.59% | 89.85% |
| 0.9/1-1.0/1 | 612 | 0.61% | 297 | 48.53% | 94.51% |
| 1.0/1-1.1/1 | 890 | 0.89% | 398 | 44.72% | 91.69% |
| 1.1/1-1.2/1 | 1291 | 1.29% | 579 | 44.85% | 96.34% |
| 1.2/1-1.3/1 | 1856 | 1.86% | 771 | 41.54% | 93.52% |
| 1.3/1-1.4/1 | 2002 | 2.00% | 806 | 40.26% | 94.65% |
| 1.4/1-1.5/1 | 2681 | 2.68% | 1018 | 37.97% | 92.93% |
| 1.5/1-1.6/1 | 3392 | 3.39% | 1231 | 36.29% | 92.41% |
| 1.6/1-1.7/1 | 4097 | 4.10% | 1462 | 35.68% | 94.43% |
| 1.7/1-1.8/1 | 4600 | 4.60% | 1584 | 34.43% | 94.53% |
| 1.8/1-1.9/1 | 5154 | 5.15% | 1713 | 33.24% | 94.59% |
| 1.9/1-2.0/1 | 5365 | 5.37% | 1737 | 32.38% | 95.31% |
| 2.0/1-2.1/1 | 5828 | 5.83% | 1793 | 30.77% | 93.66% |
| 2.1/1-2.2/1 | 5824 | 5.82% | 1726 | 29.64% | 93.19% |
| 2.2/1-2.3/1 | 6149 | 6.15% | 1766 | 28.72% | 93.22% |
| 2.3/1-2.4/1 | 5926 | 5.93% | 1698 | 28.65% | 95.83% |
| 2.4/1-2.5/1 | 5808 | 5.81% | 1583 | 27.26% | 93.86% |
| 2.5/1-2.6/1 | 5466 | 5.47% | 1520 | 27.81% | 98.55% |
| 2.6/1-2.7/1 | 4871 | 4.87% | 1291 | 26.50% | 96.58% |
| 2.7/1-2.8/1 | 4602 | 4.60% | 1108 | 24.08% | 90.13% |
| 2.8/1-2.9/1 | 4224 | 4.22% | 1039 | 24.60% | 94.54% |
| 2.9/1-3.0/1 | 3593 | 3.59% | 892 | 24.83% | 97.93% |
| 3.0/1-3.1/1 | 3309 | 3.31% | 791 | 23.90% | 96.75% |
| 3.1/1-3.2/1 | 2368 | 2.37% | 546 | 23.06% | 95.61% |
| 3.2/1-3.3/1 | 2175 | 2.17% | 520 | 23.91% | 101.44% |
| 3.3/1-3.4/1 | 1764 | 1.76% | 367 | 20.80% | 90.35% |
| 3.4/1-3.5/1 | 1439 | 1.44% | 300 | 20.85% | 92.61% |
| 3.5/1-3.6/1 | 1020 | 1.02% | 214 | 20.98% | 95.38% |
| 3.6/1-3.7/1 | 802 | 0.80% | 157 | 19.58% | 90.95% |
| 3.7/1-3.8/1 | 595 | 0.60% | 110 | 18.49% | 87.69% |
| 3.8/1-3.9/1 | 476 | 0.48% | 93 | 19.54% | 94.59% |
| 3.9/1-4.0/1 | 317 | 0.32% | 50 | 15.77% | 78.01% |
| 4.0/1-4.1/1 | 237 | 0.24% | 50 | 21.10% | 106.37% |
| 4.1/1-4.2/1 | 138 | 0.14% | 17 | 12.32% | 63.36% |
| 4.2/1-4.3/1 | 103 | 0.10% | 23 | 22.33% | 116.89% |
| 4.3/1-4.4/1 | 65 | 0.07% | 8 | 12.31% | 65.66% |
| 4.4/1-4.5/1 | 41 | 0.04% | 8 | 19.51% | 105.98% |
| 4.5/1-4.6/1 | 22 | 0.02% | 1 | 4.55% | 25.23% |
| 4.6/1-4.7/1 | 21 | 0.02% | 2 | 9.52% | 53.95% |
| 4.7/1-4.8/1 | 5 | 0.01% | 1 | 20.00% | 115.80% |
| 4.8/1-4.9/1 | 4 | 0.00% | 2 | 50.00% | 291.50% |
| 4.9/1-5.0/1 | 2 | 0.00% | 0 | 0.00% | 0.00% |
| 5.1/1-5.2/1 | 1 | 0.00% | 1 | 100.00% | 610.00% |
| 5.2/1-5.3/1 | 1 | 0.00% | 0 | 0.00% | 0.00% |

## Biais par position sur la carte

Une course parfaitement symetrique donnerait environ 12,50 % de victoires a chaque position.

| Position | Victoires | Taux | Ecart a 12,50 % |
| ---: | ---: | ---: | ---: |
| 1 | 12457 | 12.46% | -0.04 points |
| 2 | 12454 | 12.45% | -0.05 points |
| 3 | 12347 | 12.35% | -0.15 points |
| 4 | 12492 | 12.49% | -0.01 points |
| 5 | 12524 | 12.52% | +0.02 points |
| 6 | 12618 | 12.62% | +0.12 points |
| 7 | 12680 | 12.68% | +0.18 points |
| 8 | 12428 | 12.43% | -0.07 points |

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
| Alpha Rot | 19838 | 11.02 | 2649 | 13.35% | 2485 | 92.60% |
| Ash King | 20106 | 25.93 | 1029 | 5.12% | 949 | 87.55% |
| Ash Runner | 19980 | 6.05 | 4263 | 21.34% | 5384 | 94.17% |
| Backstreet | 19986 | 11.06 | 2628 | 13.15% | 2583 | 91.11% |
| Bad Omen | 19682 | 8.49 | 3315 | 16.84% | 3457 | 94.70% |
| Bare Bones | 20065 | 10.97 | 2681 | 13.36% | 2512 | 91.98% |
| Blue Rot | 19965 | 51.08 | 489 | 2.45% | 461 | 87.90% |
| Broken Shoes | 20248 | 11.02 | 2792 | 13.79% | 2484 | 99.14% |
| Cloud Cover | 20005 | 50.99 | 517 | 2.58% | 472 | 105.75% |
| Cold Track | 19948 | 8.53 | 3269 | 16.39% | 3447 | 92.23% |
| County Line | 20026 | 8.56 | 3389 | 16.92% | 3407 | 97.39% |
| Crown Fall | 19950 | 51.21 | 500 | 2.51% | 466 | 93.87% |
| Dead Sprint | 19848 | 8.50 | 3357 | 16.91% | 3362 | 94.20% |
| Door Knock | 20018 | 10.98 | 2628 | 13.13% | 2501 | 95.43% |
| Dust Walker | 19915 | 8.48 | 3347 | 16.81% | 3444 | 91.55% |
| Fence Jumper | 20022 | 11.03 | 2702 | 13.50% | 2529 | 94.91% |
| Fever Dream | 19851 | 25.84 | 1041 | 5.24% | 956 | 91.55% |
| Final Bite | 20043 | 10.96 | 2670 | 13.32% | 2481 | 94.74% |
| Grave Pace | 20063 | 8.49 | 3390 | 16.90% | 3461 | 92.69% |
| Green River | 19861 | 10.94 | 2698 | 13.58% | 2551 | 97.99% |
| Headwind | 20169 | 26.12 | 991 | 4.91% | 941 | 92.40% |
| Hungry Road | 20221 | 10.96 | 2758 | 13.64% | 2604 | 96.33% |
| Last Hour | 20512 | 50.75 | 531 | 2.59% | 495 | 98.60% |
| Last Turn | 20032 | 8.52 | 3405 | 17.00% | 3436 | 97.05% |
| Long Road | 20088 | 8.54 | 3383 | 16.84% | 3467 | 94.81% |
| Lost Arms | 20157 | 11.07 | 2647 | 13.13% | 2464 | 88.38% |
| Moon Walker | 19793 | 8.47 | 3335 | 16.85% | 3377 | 95.50% |
| Nameless | 20083 | 10.91 | 2706 | 13.47% | 2524 | 97.64% |
| Night Signal | 19774 | 8.49 | 3352 | 16.95% | 3478 | 92.53% |
| No Witness | 20137 | 11.01 | 2646 | 13.14% | 2539 | 93.52% |
| Old Shambler | 20038 | 11.00 | 2656 | 13.25% | 2553 | 94.14% |
| Pine Ridge | 19942 | 25.98 | 1015 | 5.09% | 927 | 97.81% |
| Raven Creek | 19853 | 6.00 | 4296 | 21.64% | 5337 | 97.54% |
| Red Mile | 19965 | 8.53 | 3425 | 17.16% | 3444 | 94.97% |
| Rotten Luck | 19741 | 10.87 | 2695 | 13.65% | 2551 | 100.68% |
| Sleepless | 19992 | 8.50 | 3391 | 16.96% | 3478 | 95.84% |
| South Horde | 19957 | 10.97 | 2620 | 13.13% | 2518 | 89.34% |
| Spark Plug | 20088 | 26.15 | 1012 | 5.04% | 980 | 90.59% |
| Storm Rider | 20083 | 11.00 | 2699 | 13.44% | 2540 | 94.81% |
| Wormwood | 19955 | 26.02 | 1083 | 5.43% | 955 | 87.54% |

## Diagnostic automatique

- La frequence des favoris de pool ex aequo est de 0.41%.
- Aucun biais de position superieur a 1 point n'est visible dans cet echantillon.
- Le RTP de la strategie favorite se situe dans la plage cible.
- Le payout inclut la mise retournee et depend du pool final : `pool net x mise joueur / mises gagnantes`.

## Etude : course cagnote du dimanche

La course hebdomadaire avec **$50,000 ajoutes par le serveur** est implementee comme un rendez-vous global. Ajouter $50,000 a chaque session personnelle aurait permis a chaque joueur de recreer la subvention et aurait ete exploitable.

Architecture retenue :

1. Creer une seule course partagee le dimanche du calendrier en jeu a 16:00.
2. Ouvrir les mises avant la course, avec 500 a 1,300 parieurs virtuels et les mises reelles de tous les joueurs.
3. Fermer les mises a 16:00, verrouiller les cotes, puis calculer un seul vainqueur autoritaire.
4. Calculer `pool net = mises apres commission + $50,000`, afin que toute la cagnote promotionnelle soit distribuee.
5. Conserver les tickets dans le ModData serveur et crediter aussi les gagnants deconnectes lors de leur prochaine connexion.
6. Limiter chaque joueur a un ticket de $500 maximum pour contenir le RTP promotionnel et eviter la manipulation des cotes.

Exemple indicatif avec 900 parieurs a $262.50 de moyenne :

| Element | Montant |
| --- | ---: |
| Mises virtuelles | $236,250 |
| Pool apres commission de 15 % | $200,812 |
| Cagnote serveur ajoutee | $50,000 |
| Masse finale a partager | $250,812 |

Une simulation separee de 10 000 super cagnottes mesure environ 119 % de RTP en jouant toujours le favori, avec 900 parieurs et $236,326 de mises virtuelles en moyenne. Ce rendement promotionnel est volontaire mais justifie le plafond hebdomadaire de $500 par joueur.

Cette variante est couverte par un test deterministe du calendrier, des tickets multiples, du reglement automatique et du paiement bancaire. Une validation avec deux clients sur serveur dedie reste requise.

## Corrections recommandees

1. Verifier en jeu que le pool, le nombre de parieurs, le plafond et les cotes restent lisibles dans le CRT.
2. Tester plusieurs tailles de mises pour confirmer que le partage proportionnel ne produit aucun gain inferieur a la mise sur un pari gagnant autorise.
3. Comparer la strategie favorite a un pari aleatoire et aux autres tranches de multiplicateur avant de figer la commission.

## Reproduction

```bash
bash tools/simulate_zombie_races.sh --runs 100000 --stake 100 --seed 42020 --target-min 0.85 --target-max 0.95
```
