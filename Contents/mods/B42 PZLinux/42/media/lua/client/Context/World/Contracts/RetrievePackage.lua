function PZLinux_Contract_RetrievePackage_CreateCoroutine(self, contract, contractsCompanyCodes, contractsCompanyReward, typeText)
    return coroutine.create(function()
        local modData = getPlayer():getModData()
        local globalVolume = getCore():getOptionSoundVolume() / 50
        local playerName = generatePseudo(string.lower(getPlayer():getUsername()))
        local sellerName = "<" .. contractsCompanyCodes[contract] .. "> "

        modData.PZLinuxOnReward = contractsCompanyReward[contract]
        modData.PZLinuxContractCompanyUp = "PZLinuxTrading" .. contractsCompanyCodes[contract]
        local message = ""

        local sleepSFX = 1
        if modData.PZLinuxUISFX ==  0 then sleepSFX = 0.1 end
        print(contractsCityId[contract])

        local elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
        local letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
        while elapsed < letterDelay do
            if self.isClosing then return end
            coroutine.yield()
            elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
        end

        if self.isClosing then return end

        message = sellerName .. "We are looking for a courier to retrieve a package."
        self.loadingMessage:setName(message)
        
        letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
        while elapsed < letterDelay do
            if self.isClosing then return end
            coroutine.yield()
            elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
        end

        if self.isClosing then return end

        typeText(self.typingMessage, "Where is the package exactly ?", function()
            message = message .. "\n" .. playerName .. "Where is the package exactly ?"
            self.loadingMessage:setName(message)
            self.typingMessage:setName("")
        end)
        
        letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
        while elapsed < letterDelay do
            if self.isClosing then return end
            coroutine.yield()
            elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
        end

        if self.isClosing then return end

        local quests = {}
        if contractsCityId[contract] == 1 then
            quests = {
                [1] = { description = "In a house of Irvington, in a gray cabinet.", x = 2650, y = 13407, z = 0, city = "Irvington" },
                [2] = { description = "At the Liquor Store of Irvington, in a green crate.", x = 2542, y = 14468, z = 0, city = "Irvington" },
                [3] = { description = "At the Gun Club of Irvington, on a metal shelf.", x = 1855, y = 14163, z = 0, city = "Irvington" },
                [4] = { description = "At the Public Pool of Irvington, in a blue locker.", x = 1883, y = 14461, z = 0, city = "Irvington" },
                [5] = { description = "At the Sport Store of Irvington, on a metal shelf.", x = 1862, y = 14853, z = 0, city = "Irvington" },
                [6] = { description = "At the Farming Supply Store of Irvington, in a box.", x = 2466, y = 14317, z = 0, city = "Irvington" },
                [7] = { description = "At the School of Irvington, in a library.", x = 2238, y = 14359, z = 0, city = "Irvington" },
            }
        end

        if contractsCityId[contract] == 2 then
            quests = {
                [1] = { description = "In the Metal Workshop of Ekron, in the trash outside.", x = 622, y = 9854, z = 0, city = "Ekron" },
                [2] = { description = "In the Book Store of Ekron, in a library.", x = 451, y = 9794, z = 0, city = "Ekron" },
                [3] = { description = "In the Broken Train of Ekron, in a box.", x = 550, y = 9861, z = 0, city = "Ekron" },
                [4] = { description = "In the Gas Station of Ekron, in a small trash outside.", x = 675, y = 9921, z = 0, city = "Ekron" },
                [5] = { description = "In the Church of Ekron, on the piano upstairs.", x = 445, y = 9914, z = 1, city = "Ekron" },
            }
        end

        if contractsCityId[contract] == 3 then
            quests = {
                [1] = { description = "In a house of Brandenburg, in the fridge.", x = 2471, y = 6390, z = 0, city = "Brandenburg" },
                [2] = { description = "At the Police Station of Brandenburg, in the bathroom.", x = 2037 , y = 5975, z = 0, city = "Brandenburg" },
                [3] = { description = "At the Dentist of Brandenburg, in a gray shelf.", x = 2077, y = 5912, z = 0, city = "Brandenburg" },
                [4] = { description = "At the Community Center of Brandenburg, in the yellow locker.", x = 1858, y = 5944, z = 0, city = "Brandenburg" },
                [5] = { description = "At the Fire Department of Brandenburg, in a tool cart.", x = 2069, y = 6288, z = 0, city = "Brandenburg" },
                [6] = { description = "At the Destroyed Pile-O-Crepe of Brandenburg, on the table inside.", x = 2137, y = 6427, z = 0, city = "Brandenburg" },
            }
        end

        if contractsCityId[contract] == 4 then
            quests = {
                [1] = { description = "In the Auto Repair Shop of Echo Creek, on the table inside.", x = 3676, y = 10893, z = 0, city = "Echo Creek" },
                [2] = { description = "In the Church of Echo Creek, on the piano.", x = 3534, y = 11203, z = 0, city = "Echo Creek" },
                [3] = { description = "In the Diner of Echo Creek, in the freezer.", x = 3571, y = 10907, z = 0, city = "Echo Creek" },
            }
        end

        if contractsCityId[contract] == 5 then
            quests = {
                [1] = { description = "In a house, in the box.", x = 6575, y = 5533, z = 0, city = "Riverside" },
            }
        end

        if contractsCityId[contract] == 6 then
            quests = {
                [1] = { description = "In the Police Station of Fallas Lake, in an archive cabinet.", x = 7251, y = 8378, z = 0, city = "Fallas Lake" },
                [2] = { description = "In the Bar of Fallas Lake, in a jukebox.", x = 7248, y = 8521, z = 0, city = "Fallas Lake" },
                [3] = { description = "In the Doctor's Office of Fallas Lake, in a fridge.", x = 7301, y = 8387, z = 0, city = "Fallas Lake" },
                [4] = { description = "In the Burger Joint of Fallas Lake, under the sink.", x = 7234, y = 8208, z = 0, city = "Fallas Lake" },
            }
        end

        if contractsCityId[contract] == 7 then
            quests = {
                [1] = { description = "In the police station of Rosewood, in a paper cabinet.", x = 8073, y = 11736, z = 0, city = "Rosewood" },
                [2] = { description = "In the elementary school of Rosewood, in a school locker.", x = 8333, y = 11616, z = 0, city = "Rosewood" },
                [3] = { description = "In the church of Rosewood, in a gray cabinet.", x = 8134, y = 11542, z = 0, city = "Rosewood" },
                [4] = { description = "In the bar of Rosewood, under the sink in a cabinet.", x = 8022, y = 11423, z = 0, city = "Rosewood"  },
                [5] = { description = "In the Knox Country Court of Justice of Rosewood, in a gray cabinet.", x = 8062, y = 11653, z = 0, city = "Rosewood" },
                [6] = { description = "In the Prison of Rosewood, in a fridge upstairs.", x = 7695, y = 11901, z = 1, city = "Rosewood" },
                [7] = { description = "In the Military Research Facility of Rosewood, in a morgue locker.", x = 5566, y = 12437, z = -17, city = "Rosewood" },
                [8] = { description = "In the Military Research Facility of Rosewood, in an archive cabinet in the basement.", x = 5581, y = 12469, z = -17, city = "Rosewood" },
            }
        end

        if contractsCityId[contract] == 8 then
            quests = {
                [1] = { description = "At the church of March Ridge, in a library.", x = 10322, y = 12800, z = 0, city = "March Ridge" },
                [2] = { description = "In the insurance office of March Ridge, in a paper box.", x = 10070, y = 12778, z = 0, city = "March Ridge" },
                [3] = { description = "At the community center of March Ridge, in the blue locker.", x = 10038, y = 12720, z = 0, city = "March Ridge" },
                [4] = { description = "At the Knox military apartments of March Ridge, in the clothing washer.", x = 10064, y = 12623, z = 0, city = "March Ridge" },
                [5] = { description = "In the bar of March Ridge, in the trash inside.", x = 10171, y = 12667, z = 0, city = "March Ridge" },
                [6] = { description = "In the Bunker of March Ridge, in a trash.", x = 9962, y = 12611, z = -4, city = "March Ridge" },
            }
        end

        if contractsCityId[contract] == 9 then
            quests = {
                [1] = { description = "At the Electrical Substation, in a gray cabinet.", x = 10380, y = 10061, z = 0, city = "Muldraugh" },
                [2] = { description = "At Jays Chicken of Muldraugh, in a big trash outside.", x = 10627, y = 9564, z = 0, city = "Muldraugh" },
                [3] = { description = "At the police station of Muldraugh, in a blue locker.", x = 10646, y = 10409, z = 0, city = "Muldraugh" },
                [4] = { description = "In the Cortman medical of Muldraugh, in an antique piece of furniture.", x = 10880, y = 10024, z = 0, city = "Muldraugh" },
                [5] = { description = "At the electronics store of Muldraugh, in a fridge.", x = 10617, y = 9872, z = 0, city = "Muldraugh" },
                [6] = { description = "In the McCoy logging Corp of Muldraugh, in a yellow locker.", x = 10310, y = 9340, z = 0, city = "Muldraugh" },
            }
        end

        if contractsCityId[contract] == 10 then
            quests = {
                [1] = { description = "At a house, in a fridge.", x = 11366, y = 7024, z = 0, city = "West Point" },
                [2] = { description = "At the Mini Hotel of West Point, In the trash outside.", x = 12020, y = 6932, z = 0, city = "West Point" },
                [3] = { description = "At the Thunder Gas of West Point, In a freezer.", x = 11825, y = 6868, z = 0, city = "West Point" },
                [4] = { description = "At the Pizza Whirled of West Point, under the sink.", x = 11655, y = 7084, z = 0, city = "West Point" },
                [5] = { description = "At the Church and Cemetery of West Point, On a tombstone.", x = 11070, y = 6703, z = 0, city = "West Point" },
                [6] = { description = "At the Knox Bank of West Point, in a office.", x = 11899, y = 6909, z = 1, city = "West Point" },
            }
        end

        if contractsCityId[contract] == 11 then
            quests = {
                [1] = { description = "In the Yummers of Valley Station, in a fridge.", x = 13581, y = 5744, z = 0, city = "Valley Station" },
                [2] = { description = "In the Knox Bank of Valley Station, in a flower pot.", x = 13656, y = 5734, z = 0, city = "Valley Station" },
                [3] = { description = "In the Elementary School of Valley Station, in a yellow locker.", x = 12861, y = 4863, z = 0, city = "Valley Station" },
                [4] = { description = "In the Church of Valley Station, in boxs.", x = 14556, y = 4964, z = 0, city = "Valley Station" },
            }
        end

        if contractsCityId[contract] == 12 then
            quests = {
                [1] = { description = "In a house, in a box.", x = 12264, y = 3355, z = 0, city = "Louisville" },
                [2] = { description = "In the repurposed building of Louisville, in a box.", x = 12436, y = 1420, z = 0, city = "Louisville" },
                [3] = { description = "At the fire department of Louisville, in a gray wardrobe.", x = 13729, y = 1784, z = 0, city = "Louisville" },
                [4] = { description = "At the Knox bank of Louisville, on the last floor in a paper box.", x = 12653, y = 1636, z = 15, city = "Louisville" },
                [5] = { description = "In the hospital of Louisville, in a trash.", x = 12923, y = 2060, z = 2, city = "Louisville" },
                [6] = { description = "At the Scarlet Oak Distillery of Louisville, in a box.", x = 12021, y = 1934, z = 0, city = "Louisville" },
                [7] = { description = "At the Knox bank of Louisville, on the third floor in a metal cabinet.", x = 12561, y = 1707, z = 2, city = "Louisville" },
                [8] = { description = "At the Awl Work and Sew Play of Louisville, in the container somewhere below the register.", x = 12491, y = 1695, z = 0, city = "Louisville" },
                [9] = { description = "In the Evergreen public school of Louisville, in a yellow locker.", x = 13581, y = 2782, z = 0, city = "Louisville" },
                [10] = { description = "In the Leafhill heights elementary school of Louisville, in the yellow locker.", x = 12351, y = 3247, z = 1, city = "Louisville" },
                [11] = { description = "In the Pizza Whirled of Louisville, in the fridge.", x = 13224, y = 2103, z = 0, city = "Louisville" },
            }
        end

        local randomQuest = 1
        if #quests > 1 then
            randomQuest = ZombRand(1, #quests + 1)
        end

        local quest = quests[randomQuest]
        if quest then
            message = message .. "\n" .. sellerName .. quest.description
            modData.PZLinuxContractLocationX = quest.x
            modData.PZLinuxContractLocationY = quest.y
            modData.PZLinuxContractLocationZ = quest.z
            locationQuestTown = quest.city .. ":\n* " .. quest.description
        end

        getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 20, 1, true):setVolume(globalVolume)
        self.loadingMessage:setName(message)

        letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
        while elapsed < letterDelay do
            if self.isClosing then return end
            coroutine.yield()
            elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
        end

        if self.isClosing then return end
        
        typeText(self.typingMessage, "What is the reward for this mission ?", function()
            message = message .. "\n" .. playerName .. "What is the reward for this mission ?"
            self.loadingMessage:setName(message)
            self.typingMessage:setName("")
        end)

        letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
        while elapsed < letterDelay do
            if self.isClosing then return end
            coroutine.yield()
            elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
        end

        if self.isClosing then return end
        
        getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 20, 1, true):setVolume(globalVolume)
        message = message .. "\n" .. sellerName .. "$" .. modData.PZLinuxOnReward 
        self.loadingMessage:setName(message)

        letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
        while elapsed < letterDelay do
            if self.isClosing then return end
            coroutine.yield()
            elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
        end

        if self.isClosing then return end

        typeText(self.typingMessage, "How do I give you the package ?", function()
            message = message .. "\n" .. playerName .. "How do I give you the package ?"
            self.loadingMessage:setName(message)
            self.typingMessage:setName("")
        end)

        letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
        while elapsed < letterDelay do
            if self.isClosing then return end
            coroutine.yield()
            elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
        end

        if self.isClosing then return end

        getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 20, 1, true):setVolume(globalVolume)
        message = message .. "\n" .. sellerName .. "Put the package in a mailbox."
        
        self.loadingMessage:setName(message)

        letterDelay = math.ceil(getGameTime():getWorldAgeHours() * 3600) + ZombRand(20, 100) * sleepSFX
        while elapsed < letterDelay do
            if self.isClosing then return end
            coroutine.yield()
            elapsed = math.ceil(getGameTime():getWorldAgeHours() * 3600)
        end

        if self.isClosing then return end

        getSoundManager():PlayWorldSound("ircNotification", false, getPlayer():getSquare(), 0, 20, 1, true):setVolume(globalVolume)
        message = message .. "\n" .. sellerName .. "Deal ?"
        
        self.loadingMessage:setName(message)

        self.yesButton = ISButton:new(self.width * 0.35, self.height * 0.65, 80, 25, "Yes", self, self.onYesButton)
        self.yesButton.contractId = contract
        self.yesButton:initialise()
        self.yesButton:instantiate()
        self.topBar:addChild(self.yesButton)
        
        self.noButton = ISButton:new(self.width * 0.50, self.height * 0.65, 80, 25, "No", self, self.onMinimizeBack)
        self.noButton:initialise()
        self.noButton:instantiate()
        self.topBar:addChild(self.noButton)
    end)
end    
