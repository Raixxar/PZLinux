[h1]FAQ[/h1]

[h2]Overview:[/h2]

The Dark Web mod introduces a new layer of gameplay for players by allowing them to utilize in-game currency. With this mod, scavenging takes on a new significance. Collecting money from cash registers or valuable items from zombies becomes worthwhile as you can sell these items for something more valuable. It is important not to keep cash on hand; to make purchases online, you must deposit your blood-stained bills into an ATM to credit your bank account, which will then be accessible on the Dark Web.

[h2]ATM:[/h2]

[h3]How It Works ?[/h3]

A bank account is linked to your game save and character. You can deposit or withdraw money at ATMs. Once transactions are complete, your bank account is automatically updated, and your new balance becomes available for purchases on the Dark Web. Your balance is saved and will be accessible throughout your survival journey. ATMs are generally found around the game’s banks. There are two types of ATMs in the game: freestanding and wall-integrated.

[h2]Computer:[/h2]

[h3]How long does a computer stay on ?[/h3]

The computer stays in sleep mode for 24 hours before automatically shutting down. It also remains connected to the internet for 1 hour if not in use. If you stay on the computer, there's no need to reconnect every 5 minutes with this setup.

[h3]What can we do on the computer?[/h3]

The first submenu is the dark web. This interface allows you to buy weapons, armor, and ammunition, as well as sell items to earn money.

You can also trade with fictional companies. Stock prices are updated every hour, allowing you to speculate, go on expeditions, and sell your stocks later if they’re still valuable. If you haven’t sold, you haven’t lost!

To track your stock market activities and simplify your investment overview, the portfolio will help you. All your stocks are stored in your digital wallet where you can monitor your gains and losses.

The last available submenu is hacking. ID cards from zombies allow you to recover valuable information about bank accounts. Zombies don’t need money, so why not get rid of it! 😄

[h2]Dark Web:[/h2]

[h3]How it works ?[/h3]

Once you have deposited funds into your bank account, you can access the Dark Web to make your first purchases. If you don't have enough money yet, you can also sell items. The Dark Web offers a randomly generated list of 272 items. In the backend, the game rolls a dice between 5 and 100 to create this item list. Some items may appear multiple times at different prices, giving you the opportunity to choose the best deals for selling or buying.

[h3]How does login work?[/h3]

The login mechanism is based on your character's name. In the future, it will utilize the electrical skill to enhance the player’s connection speed. Also, I would like to link this speed with the player's stress level. The more stressed the player is, the longer it takes to enter their login and password. Conversely, the higher their electrical skill, the faster they will be able to input this information.

[h3]How are purchase and selling prices defined ?[/h3]

The prices of items are also generated randomly, allowing you to find items listed at different prices within the same category. To determine the price of an item, I assign a base price that varies depending on its category. For weapons, the price is set based on the damage they can inflict without critical hits, the weight of the item, and the number of hands required to use it. Consequently, two-handed weapons are generally more expensive than one-handed ones. Jewelry and lingerie utilize a value system without a formula, which serves to balance the gameplay by ensuring a steady income for players and rewarding farming efforts. Gold jewelry and the WristWatch are considered reliable items for generating substantial profit.

Once the base price is established, a purchase value is generated that falls between the initial price and three times that value. The selling price is calculated to be between the initial price and one-and-a-half times that price, divided by two. This initial pricing configuration ensures a balance between farming and acquiring rare items within the game.


[h3]How much is an item available for on the dark web ?[/h3]

The item list is generated randomly, as previously mentioned. The list of items is refreshed daily, meaning that each day spent in-game gives you the opportunity to buy or sell new items.

This mechanism allows you sufficient time to gather items that can later be sold or to accrue enough currency to obtain the item you desire. If there is nothing that interests you, this one-hour window is short enough to wait for a new list to become available.

[h2]Trading:[/h2]

[h3]How it works ?[/h3]

'Trading is based on fictional companies you can invest in. To enhance all bank accounts, I've included various companies with different values. Each hour, the values are updated, and they can increase or decrease. Currently, these values are randomly assigned, but I am considering making them more reflective of the real world.

You can buy as many shares as you want as long as your bank account allows it. Conversely, you can sell at any time. The trading interface currently has no commissions, so now is a great time to take advantage of it! 🙂

For a better simulation, I've recreated the trading interface using candlestick charts. By default, this interface is based on H1, but you can also view the value in D1 with button. Writing candlestick graphs in LUA is quite complex, so I'm not sure if I'll offer more than H1 and D1 for now.

[h3]How can I view my purchased assets?[/h3]

Your assets are grouped in your digital wallet, allowing you to track the real-time value of your portfolio, its evolution, and the stock prices of each company you have invested in.

[h2]Hacking:[/h2]

[h3]How it works ?[/h3]

The hacking interface is available as long as you have an ID card. Currently, there are no restrictions for hacking an ID card. Once you have a zombie's name, you try to retrieve the balance of their bank account by hacking the central bank. Your electrical skill level gives you the chance to find more money, but that's not all; to unlock access to the account, you must find the correct code. After six attempts without finding the correct code, the account will be locked and cannot be recovered. Similar to the game Mastermind, the code helps you find the right numbers. You need to find four unique digits; This means there will never be any duplicate or triplicate numbers in the code.

[h3]What is the future of this project ?[/h3]

Currently, only the basic feature that allows for a functional mod is implemented. My aim was to provide something quickly and gather your initial feedback to ensure that I'm heading in the right direction based on community input.

I plan to integrate stock market speculation into this mod (Trading UI), which would give players an additional option to earn more money. Additionally, I would like to replace the current acquisition system, which I believe is not very realistic. Instead of obtaining an item with a simple click, where it either appears in your inventory or disappears upon sale, I envision creating expeditions to retrieve or sell these items, with a nearby safe that introduces an element of risk.

Furthermore, I intend to establish a contract system within the dark web, offering quests of varying difficulty with rewards tied to that difficulty. This would add depth and engagement to the gameplay experience.

Based on the electrical skill, which I believe is the most relevant within the game for using computers, I am considering the integration of IT functionalities, including:

- Hacking a bank to gain a chance to empty a bank account linked to an ID card found on a zombie.
- Hacking the city’s surveillance cameras to examine an area and assess the number of zombies present.
- And more...
