- Add options to the mod to make it sandbox.
- Prevent a trade by burning a cargo.
- Player can create a request basket of our own choice and wait for it to be presented to us.
- Make the mod compatible with controllers.
- Add a place where players can drop resources freely, with the quantity determining the amount of money.
- write the lore
- trading: add raw items for trading, price depending month
- chance credit card hack, only with atm with 3 chances.
- new contract: Radio station activates a message that attracts zombies to the area.
- new contract: add contract with timer for items
- new contract: retrieval via a computer triggers an alarm (chance) and spawns a horde.
- new contract: Delivering 200L of fuel / Water..
- new contract: Add money to ATM
- New contract: drop off a vehicle in a specific area. 
- Quest: Obtainaing rare item, Big Spiffo or gas mask
- Quest: get document from doctor or other.
- Quest: search courier died, keep the package.
- Quest: deliver drinking water.
- Quest: Delivering Animals
- Change limit for ATM to $50k
- add radio connection for PZlinux.
- Add message for first connexion after PZLinux.
- Add a satellite to get internet on the computer.
- Add contract with extra stress (spawn hord) but also loot that can temporarily boost survival
- Add Reputation for each contract with lvl (rep = difficulty lvl * 2)

# Update v.0.1.12
- In contracts where you need to find a briefcase, you now have a chance to find money and a weapon inside.
- Reduced resale prices for all items on the dark web.
- Added all skill magazines to the dark web.
- Added all skill books to the dark web.
- Reduced computer wear by half, meaning it will need to be repaired less often.
- Fixed a bug where the contract requiring zombie kills was not counting kills toward contract completion.
- Reduced the reward for the contract requiring a live zombie capture.
- Removed the note from the inventory when the player requests a car.
- Add Random sold for new player.
- Increased prices for requests to adjust the mod’s balance.
- The reward for the contract requiring zombie kills is now based on the number of zombies to eliminate. A higher kill requirement will now grant more money.
- Added a chance that no one connects to the room for the player’s requests.
- Increased the waiting time for player requests.
- Your parcels now have a 10% chance of being stolen when you try to retrieve them from the mailbox.
- You can now find electronic equipment on the dark web.
- It is now possible to hack multiple cards at the same time using the auto function. However, this feature provides lower rewards.
- Due to major changes in the Lua API, the mod is no longer compatible with versions prior to B42.13.
- New contract: To complete it, you must send a computer.
- New contract: To complete it, you must send a fridge.
- Added a reputation system to the game. The more contracts you successfully complete, the higher your reputation, unlocking various advantages.
- Added a mail interface: other survivors can now contact you for special missions.
- Added missions requiring ammunition delivery in mail UI
- Added missions requiring medical supply delivery in mail UI
- Changed the email domain from Hotmail to AOL, which is more consistent with the 1994 time period.
- Added ads and spam emails.
- Added a notification for new emails on the PZLinux desktop.

# Update v.0.1.11-rc6
- Fix the LUA errors in the ATM interface when the password is entered.
- Fix an issue where the computer couldn't be repaired even if you had the electronic parts in your inventory.
- Computer repair now only appears below 15%, whereas it was at 50% before.
  
# Update v.0.1.11-rc5
- Change of the formula for the player's typing speed on the computer keyboard; it is now more realistic.
- Change of the mod sound volume; the sounds are slightly decreased.
- Fixed an issue where players could receive an empty package when purchasing a quantity of 0 in the DW.
- Fixed an issue where players could increase their skill without making any purchases.
- Fixed LUA errors when the player kills a zombie.
- Information about car parts to be sent is now in the contract note.
- Fixed an issue where car parts couldn't be sent to complete the contract.
- Adjusted the reward for the car parts contract; the values are now more realistic with the parts' worth.

# Update v.0.1.11-rc4
- Added a sandbox option as a multiplier for sale prices.
- Fixes an issue where the quest completion menu does not display correctly for certain contracts.
- Fixes LUA errors for the quest requiring zombie kills.

# Update v.0.1.11-rc3
- Fixes an issue where the contract could not be properly removed in a new game.
- Added a sandbox option to the mod to adjust the multiplier on item prices.

# Update v.0.1.11-rc2
- Resolve an issue where you might have information from an unaccepted contract.

# Update v.0.1.11-rc1
- Fix an issue where the second player couldn't properly use the mod.
- Changes to online betting: the odds are never 1/1, which offers no return on a win. The minimum odds are now 2/1.
- Buying or selling items increases your 'Foraging' level.
- Contracts now display the destination city when necessary.
- Fixing the computer increases your electricity level.
- Succeeding in hacking increases your electricity level.
- Hacking a credit card now reduces your boredom. 
- Successfully hacking for profit boosts your joy and lowers your stress.
- Betting reduces your boredom. 
- Losing an online bet, depending on the wager amount, decreases your joy and increases your stress, while winning boosts your joy and lowers your stress.
- Selling stocks based on their value increases your happiness and reduces your stress.
- Successfully completing a contract reduces your boredom and stress while increasing your happiness.
- Some of the tables are now separated into a separate file, allowing you to modify them as you wish.

# Update v.0.1.11
- The contract log is now on a piece of paper to take up less space in the player's inventory.
- Added more information about the ongoing mission in the contract note.
- Fixed an issue where the message could overflow off the computer screen.
- Fix the LUA error on mailbox that could occur if a request was not initialized correctly.
- Requesting a car now adds a note to your inventory for easily locating this vehicle.
- Adding music when you successfully complete a contract.
- Annotations on the map are now removed if you cancel or complete a contract.
- The computer now consumes energy for the generators.
- The ATM now consumes energy for the generators.
- You can view this energy consumption in the generator info sheet.
- Computers now have a condition like generators and require electronic parts for repairs.
- Added a menu to track the computer's status.
- Introduced two different startup sounds based on its condition. A computer in poor condition will have its disk click at startup.
- Bars and ingots are now available for DW.
- Items purchased on the dark web must now be collected from a mailbox.
- Items in the request interface are now affected by your 'Foraging' skill. A skill reduces the price of items.
- Added multiple halo alert messages to assist the player.

# Update v.0.1.10-rc2
- Fix a bug where the annotation does not appear correctly if the player has never opened their map.
- Fix a bug where the price was not updated correctly for stock actions if the player has never opened the trading interface.

# Update v.0.1.10-rc1
- Fixed a bug where the indicator on the map didn't appear correctly in new games.
- Contracts are now available in the first week for new saves.
- Fix the error message for mailboxes when sending a package.

# Update v.0.1.10
- Added multiple spawns for the quest to retrieve a package. 
- In a mission, each zombie killed = $5 bonus.
- Fix a bug where the pagination did not disappear properly after selecting a query.
- Fix a bug where the capture quest was not correctly reset upon completion.
- Items in the requests are now mixed to create a diverse selection in the delivery box.
- Adding electronic components to the requests.
- Adding repairing components to the requests.
- Adding materials components to the requests.
- Adding seeds components to the requests.
- New contract: prepare a cargo to be airlifted by helicopter (lvl:4)
- New contract: Protect a building (lvl:5)
- New contract: Find and send medical equipment (lvl:2)
- New contract: Find and send weapons (lvl:3)
- Contracts now add a circle and a summary directly on the map.
- Fixed a bug where the ID card was not properly consumed after pressing 'Next'.
- It is now possible to hack credit cards like ID cards.
- When you request a car, it now appears on your map for you to pick up.
- Mailboxes now allow for taking and depositing with a single click.
- Zombies killed are now added to the contract notebook to track your mission status.

# Update v.0.1.9-rc1
- Fix an issue where the quest to collect zombie blood did not require killing a new target.
- Fix an issue where TimedAction wasn't properly closed after an interface closure.
- Fix for a glitch where the credit card was not properly consumed.
- Fix an issue where the fish were not delivered after a purchase.

# Update v.0.1.9
- Create zombie races for online betting.
- Add a contract to capture a live zombie for the race.
- Reducing the contract interface during message animation now correctly links back to the contract list.
- Fixing a bug or buying and selling an item closes the PZLinux interface.
- Added all modern and normal pieces to the auto part quest rotation.
- Increase the detection menu radius for the PZLinux menu.
- It is now possible to purchase vehicles.
- PZLinux actions can now be accelerated over time.

# Update v.0.1.8-rc2
- Correct a variable error in contracts due to the v0.1.8-rc1 update. Sorry! 

# Update v.0.1.8-rc1
- Added an SFX button to shorten the duration of mod animation messages.

# Update v.0.1.8
- All values are now integrated into ModData. the PZLinux.ini file is no longer used.
- Fix an issue where the interface position resets to default with each submenu change.
- Add cigarettes and cigars to the list of items that can be bought and sold.
- Add several knives and hats to purchase and sale on Dark Web. Thank you CdrCanteets for your help.
- Add credit cards on the Dark Web. These cards can then be hacked to obtain more money.
- Fix an issue where stock prices for companies were capped.
- Added bounty contracts for hunting down targets and eliminating them.
- Added contracts for object retrieval.
- Added contracts for zombie blood analysis.
- Added contract to send sports car parts.
- Fix an issue where the computer could be launched remotely
- Fixed an issue where mailboxes could be opened remotely.
- Fixed an issue where the ATM could be opened remotely.
- The value of purchases is now indexed to the world's time. The longer survival lasts, the more expensive prices become.
- You can now make requests on IRC to purchase canned goods, fish, books, fruits, meats, and vegetables.
- Added a notification sound for new messages on IRC
- Price balancing on the dark web. With contracts and requests features, selling prices are adjusted downward to balance the mod.
- Fix an issue where the interface closes correctly if the player moves away from the computer.

# Update v.0.1.7-rc1
- Fix the issue where the mailbox interface was not available based on the mailbox direction.

# Update v0.1.7
- Correct a spelling mistake on the hacking interface regarding the word 'transfer'.
- All interfaces are now movable to make handling in your inventory easier.
- Fixed a bug where the dark web couldn't generate an object list for the first 24h.
- Fix a bug where the item was not properly removed after a sale on the dark web while performing another action.
- Changing the 'Sold' button to 'Sell' on the dark web interface for better understanding.
- The sound volume of the different interfaces is now adjusted according to the overall game volume level.
- Added a new interface for selling items.
- Added two new interfaces for dropping off your packages.
- Buying and selling are now two separate interfaces.
- Selling items now generates a suspicious package.
- To finalize your sale, you must drop your package in a mailbox.
- Reduction of items available for purchase to a maximum of 50. The previous limit was 100 before the update.
- Added a help interface that shows the list of items available for sale and purchase.
- The limit in the mastermind menu is now correctly set to 6 attempts.
- Entering a code other than 4 digits no longer counts as a try.

# Update v0.1.6
- Fixed a bug where the token count was not displaying correctly in the trading interface.
- Fixed a bug where money deposited in the ATM is not accounted for players with special characters in their names.
- Integration of modData for player money, meaning the debug file will soon be removed.
- Added modes and magazines for your weapons.
- Added a hacking interface. This allows hacking bank accounts using ID cards found on zombies.
- Fix the interface to support 4K resolutions.
- Added buttons to navigate through the different submenus of the mod. You no longer need to type commands to enter the submenus.
- Clean up the wallet when the quantity of your stocks reaches 0 for better clarity in this interface.

# Update v0.1.5
- The connection speed on the internet is now linked to your electrical skills. A higher level allows for a faster connection.
- Fix the search issue that hasn't been working properly since the last update.
- The value of prices is now linked to your search skill. A higher skill results in lower purchase prices and higher selling prices.
- You can now press enter in the search field to initiate your search.
- Article updates on the dark web are now done every 24 hours, game time. You can find new articles every day in the game.
- Add a trading interface, allows for trading in Project Zomboid. 
- A wallet interface has also been added to track your assets.
- Code cleanup that should resolve button overlap issues.
- For clarity, the mode name will switch to a new name: PZLinux.
- You must now use this mod with the PZLinux menu.
- You must now be connected to the internet to navigate through the different submenus.
- You are now connected for 24 hours, game time, before being automatically disconnected.
- The computer also stays on for 24 hours before shutting down automatically.
- Add a sound when the computer starts.
- Add a message if you are not connected to invite you to do so before using the submenus.
- The power button is now located at the bottom left of the CRT.

# Update v0.1.4
- Resolve the issue where the dark web could be accessed on non-computer devices.
- Fix the problem preventing items with the same name in the interface from being sold.

# Update v0.1.3
- Add ATM for storing money
- Add Sound for ATM
- Add Deposit option
- Add Withdraw option
- Add Ability to move money from backpack
- Add Sound for buy/sell action
- Add Sound for buy/sell error
- Add Button to stay connected
- Add Button 3 to scroll in the menu
- Add Link ATM to the dark web
- Fix Scroll menu not centered
- Fixed bug in logs when the computer starts

# Update v0.1.2
- Fix a bug that prevents selling in nearby inventories.
- Add the option to pay with Money Bundles, each worth 100 Money.
- Improve performance to prevent crashes or FPS issues.

# Update v0.1.1
- Added a "Power OFF" button to shut down the computer before initialization finishes.
- Fixed the bug where the interface wouldn't completely disappear upon disconnection.
- The Power OFF button now replaces the disconnection button.