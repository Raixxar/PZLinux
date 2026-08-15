# Rapport d'equilibrage Zombie Race

Rapport genere le 2026-08-15 14:47:59 UTC.

## Scenario

- Courses simulees : **1000**
- Mise fixe : **$100.00**
- Graine aleatoire : **1786805279**
- Sensibilite des parieurs : exposant **39**
- Strategie : choisir la cote pari-mutuel la plus basse; departager les ex aequo au hasard.
- Reglement : pool pari-mutuel, commission de **15.00%**, partage proportionnel aux mises gagnantes.
- Liquidite serveur ajoutee au pool : **4.00%** des mises virtuelles.
- Cible RTP configuree : **85.00% a 95.00%**

La simulation charge directement `PZLinuxGamblingData.lua` et `PZLinuxRaceEngine.lua`, le meme moteur pur que le serveur.

## Verdict

**Genereux pour le joueur : le RTP depasse la cible configuree.**

| Indicateur | Resultat |
| --- | ---: |
| Mises totales | $100000.00 |
| Gains verses | $99852.00 |
| Resultat net joueur | $-148.00 |
| Resultat net maison | $148.00 |
| Victoires joueur | 311 / 1000 |
| Taux de victoire | 31.10% |
| RTP joueur | 99.85% |
| Avantage maison | 0.15% |
| Intervalle RTP 95 % | 90.36% - 109.34% |
| Cartes avec favoris ex aequo | 0.50% |
| Nombre moyen de favoris minimum | 1.00 |
| Duree moyenne | 20.82 ticks |
| Parieurs virtuels moyens | 508.02 |
| Mises virtuelles moyennes | $133469.33 |
| Liquidite serveur moyenne | $5336.38 |
| Pool de prix moyen | $138805.70 |
| Tranches de cote significatives fortement hors cible | 0 |

## Distribution des pools

Les percentiles montrent la variation produite par les parieurs virtuels sur l'ensemble de la campagne.

| Indicateur | Min | P10 | Mediane | Moyenne | P90 | Max |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Parieurs virtuels | 201 | 262 | 510 | 508 | 747 | 800 |
| Mises virtuelles | $50625.00 | $67895.00 | $133070.00 | $133469.33 | $197720.00 | $217910.00 |
| Liquidite serveur | $2025.00 | $2715.00 | $5320.00 | $5336.38 | $7905.00 | $8715.00 |
| Pool de prix | $52650.00 | $70610.00 | $138390.00 | $138805.70 | $205625.00 | $226625.00 |
| Pari joueur maximum | $2000.00 | $2000.00 | $2000.00 | $2000.00 | $2000.00 | $2000.00 |
| Cote finale du favori | 0.72/1 | 1.49/1 | 2.23/1 | 2.28/1 | 3.10/1 | 4.63/1 |
| Cotes indicatives, tous concurrents | 0.72/1 | 2.49/1 | 6.76/1 | 95.88/1 | 185.46/1 | 5823.20/1 |

### Frequence des grandes cotes

Une carte contient huit concurrents. La cote d'un concurrent est indicative avant la mise du joueur; sa cote finale est recalculee au lancement.

| Seuil | Concurrents concernes | Part des places | Cartes avec au moins un | Part des cartes |
| ---: | ---: | ---: | ---: | ---: |
| 10/1 ou plus | 2930 | 36.62% | 999 | 99.90% |
| 15/1 ou plus | 2041 | 25.51% | 959 | 95.90% |
| 20/1 ou plus | 1641 | 20.51% | 893 | 89.30% |
| 25/1 ou plus | 1439 | 17.99% | 841 | 84.10% |
| 50/1 ou plus | 1140 | 14.25% | 744 | 74.40% |
| 100/1 ou plus | 956 | 11.95% | 671 | 67.10% |

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
| 0.7/1-0.8/1 | 2 | 0.20% | 2 | 100.00% | 174.00% |
| 0.8/1-0.9/1 | 3 | 0.30% | 2 | 66.67% | 120.33% |
| 0.9/1-1.0/1 | 6 | 0.60% | 3 | 50.00% | 98.83% |
| 1.0/1-1.1/1 | 9 | 0.90% | 4 | 44.44% | 90.89% |
| 1.1/1-1.2/1 | 13 | 1.30% | 4 | 30.77% | 65.69% |
| 1.2/1-1.3/1 | 19 | 1.90% | 7 | 36.84% | 83.79% |
| 1.3/1-1.4/1 | 20 | 2.00% | 8 | 40.00% | 93.85% |
| 1.4/1-1.5/1 | 28 | 2.80% | 11 | 39.29% | 96.36% |
| 1.5/1-1.6/1 | 30 | 3.00% | 11 | 36.67% | 93.53% |
| 1.6/1-1.7/1 | 47 | 4.70% | 18 | 38.30% | 101.19% |
| 1.7/1-1.8/1 | 40 | 4.00% | 9 | 22.50% | 61.70% |
| 1.8/1-1.9/1 | 58 | 5.80% | 21 | 36.21% | 103.12% |
| 1.9/1-2.0/1 | 59 | 5.90% | 20 | 33.90% | 99.81% |
| 2.0/1-2.1/1 | 70 | 7.00% | 20 | 28.57% | 86.76% |
| 2.1/1-2.2/1 | 67 | 6.70% | 21 | 31.34% | 98.42% |
| 2.2/1-2.3/1 | 69 | 6.90% | 21 | 30.43% | 98.70% |
| 2.3/1-2.4/1 | 58 | 5.80% | 16 | 27.59% | 92.16% |
| 2.4/1-2.5/1 | 65 | 6.50% | 20 | 30.77% | 105.75% |
| 2.5/1-2.6/1 | 54 | 5.40% | 18 | 33.33% | 118.31% |
| 2.6/1-2.7/1 | 49 | 4.90% | 11 | 22.45% | 81.96% |
| 2.7/1-2.8/1 | 34 | 3.40% | 11 | 32.35% | 121.03% |
| 2.8/1-2.9/1 | 34 | 3.40% | 7 | 20.59% | 78.76% |
| 2.9/1-3.0/1 | 36 | 3.60% | 10 | 27.78% | 109.72% |
| 3.0/1-3.1/1 | 31 | 3.10% | 7 | 22.58% | 91.23% |
| 3.1/1-3.2/1 | 17 | 1.70% | 3 | 17.65% | 73.12% |
| 3.2/1-3.3/1 | 25 | 2.50% | 6 | 24.00% | 102.28% |
| 3.3/1-3.4/1 | 7 | 0.70% | 4 | 57.14% | 248.00% |
| 3.4/1-3.5/1 | 5 | 0.50% | 1 | 20.00% | 88.20% |
| 3.5/1-3.6/1 | 10 | 1.00% | 7 | 70.00% | 317.50% |
| 3.6/1-3.7/1 | 7 | 0.70% | 1 | 14.29% | 66.14% |
| 3.7/1-3.8/1 | 7 | 0.70% | 1 | 14.29% | 67.43% |
| 3.8/1-3.9/1 | 5 | 0.50% | 1 | 20.00% | 96.00% |
| 3.9/1-4.0/1 | 7 | 0.70% | 2 | 28.57% | 141.57% |
| 4.0/1-4.1/1 | 3 | 0.30% | 1 | 33.33% | 167.67% |
| 4.1/1-4.2/1 | 2 | 0.20% | 1 | 50.00% | 257.50% |
| 4.3/1-4.4/1 | 2 | 0.20% | 0 | 0.00% | 0.00% |
| 4.4/1-4.5/1 | 1 | 0.10% | 0 | 0.00% | 0.00% |
| 4.6/1-4.7/1 | 1 | 0.10% | 1 | 100.00% | 563.00% |

## Biais par position sur la carte

Une course parfaitement symetrique donnerait environ 12,50 % de victoires a chaque position.

| Position | Victoires | Taux | Ecart a 12,50 % |
| ---: | ---: | ---: | ---: |
| 1 | 121 | 12.10% | -0.40 points |
| 2 | 114 | 11.40% | -1.10 points |
| 3 | 107 | 10.70% | -1.80 points |
| 4 | 125 | 12.50% | +0.00 points |
| 5 | 140 | 14.00% | +1.50 points |
| 6 | 137 | 13.70% | +1.20 points |
| 7 | 121 | 12.10% | -0.40 points |
| 8 | 135 | 13.50% | +1.00 points |

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
| Alpha Rot | 205 | 11.28 | 31 | 15.12% | 22 | 145.73% |
| Ash King | 184 | 26.08 | 8 | 4.35% | 12 | 87.08% |
| Ash Runner | 194 | 6.13 | 44 | 22.68% | 60 | 110.98% |
| Backstreet | 203 | 10.77 | 30 | 14.78% | 31 | 104.32% |
| Bad Omen | 191 | 8.66 | 26 | 13.61% | 31 | 102.55% |
| Bare Bones | 181 | 11.94 | 16 | 8.84% | 18 | 35.83% |
| Blue Rot | 187 | 52.95 | 4 | 2.14% | 5 | 123.40% |
| Broken Shoes | 189 | 11.03 | 31 | 16.40% | 31 | 139.58% |
| Cloud Cover | 209 | 51.82 | 6 | 2.87% | 5 | 231.80% |
| Cold Track | 244 | 8.79 | 43 | 17.62% | 40 | 54.75% |
| County Line | 199 | 8.35 | 29 | 14.57% | 36 | 93.89% |
| Crown Fall | 187 | 48.84 | 2 | 1.07% | 6 | 135.83% |
| Dead Sprint | 195 | 8.34 | 30 | 15.38% | 37 | 100.57% |
| Door Knock | 213 | 10.61 | 26 | 12.21% | 26 | 73.73% |
| Dust Walker | 207 | 8.54 | 38 | 18.36% | 23 | 136.61% |
| Fence Jumper | 203 | 10.50 | 32 | 15.76% | 28 | 97.25% |
| Fever Dream | 213 | 27.13 | 9 | 4.23% | 9 | 155.56% |
| Final Bite | 209 | 11.33 | 29 | 13.88% | 25 | 108.52% |
| Grave Pace | 200 | 8.76 | 38 | 19.00% | 37 | 75.68% |
| Green River | 210 | 10.94 | 33 | 15.71% | 24 | 95.17% |
| Headwind | 204 | 24.55 | 11 | 5.39% | 9 | 102.56% |
| Hungry Road | 215 | 12.15 | 32 | 14.88% | 23 | 83.43% |
| Last Hour | 179 | 52.39 | 4 | 2.23% | 4 | 96.00% |
| Last Turn | 204 | 8.21 | 41 | 20.10% | 43 | 111.42% |
| Long Road | 192 | 8.08 | 31 | 16.15% | 43 | 85.23% |
| Lost Arms | 205 | 11.41 | 32 | 15.61% | 25 | 126.12% |
| Moon Walker | 189 | 9.03 | 30 | 15.87% | 25 | 116.40% |
| Nameless | 191 | 11.40 | 25 | 13.09% | 18 | 160.44% |
| Night Signal | 197 | 8.86 | 29 | 14.72% | 36 | 103.06% |
| No Witness | 224 | 10.80 | 26 | 11.61% | 24 | 97.17% |
| Old Shambler | 186 | 10.80 | 27 | 14.52% | 23 | 123.52% |
| Pine Ridge | 235 | 27.57 | 14 | 5.96% | 11 | 94.82% |
| Raven Creek | 206 | 6.13 | 36 | 17.48% | 44 | 47.27% |
| Red Mile | 183 | 8.58 | 30 | 16.39% | 36 | 110.19% |
| Rotten Luck | 195 | 11.43 | 20 | 10.26% | 26 | 87.88% |
| Sleepless | 178 | 8.52 | 33 | 18.54% | 36 | 102.06% |
| South Horde | 187 | 10.64 | 28 | 14.97% | 25 | 90.92% |
| Spark Plug | 203 | 25.59 | 6 | 2.96% | 7 | 42.86% |
| Storm Rider | 200 | 11.44 | 24 | 12.00% | 24 | 78.25% |
| Wormwood | 204 | 24.55 | 16 | 7.84% | 12 | 140.00% |

## Diagnostic automatique

- La frequence des favoris de pool ex aequo est de 0.50%.
- Un biais de position superieur a 1 point est mesure et merite un echantillon plus large.
- La strategie favorite paie au-dessus de la cible. Il faut reduire le payout ou renforcer l'avantage maison.
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
bash tools/simulate_zombie_races.sh --runs 1000 --stake 100 --seed 1786805279 --target-min 0.85 --target-max 0.95
```
