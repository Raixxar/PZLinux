function PZLinux_Contract_KillZombie_CreateCoroutine(self, contract, contractsCompanyCodes, contractsCompanyReward, typeText)
    return coroutine.create(function()
        local dialogue = PZLinuxContractDialogue.create(self, contract, contractsCompanyCodes, contractsCompanyReward)
        local zombiesToKill = tonumber(dialogue.modData.PZLinuxOnZombieToKill) or 0

        if not PZLinuxContractDialogue.wait(self, dialogue) then return end
        PZLinuxContractDialogue.setSellerLine(self, dialogue, PZLinuxContractDialogue.getText("IGUI_PZLinux_Contracts_KillZombies_Intro", "We are looking for a mercenary to clean the streets of our city."))

        if not PZLinuxContractDialogue.wait(self, dialogue) then return end
        PZLinuxContractDialogue.ask(self, dialogue, PZLinuxContractDialogue.getText("IGUI_PZLinux_Contracts_KillZombies_AskCount", "How many zombies do you need to kill ?"), typeText)

        if not PZLinuxContractDialogue.wait(self, dialogue) then return end
        PZLinuxContractDialogue.appendSellerLine(self, dialogue, tostring(zombiesToKill), true)

        if not PZLinuxContractDialogue.wait(self, dialogue) then return end
        PZLinuxContractDialogue.ask(self, dialogue, PZLinuxContractDialogue.getText("IGUI_PZLinux_Contracts_AskReward", "What is the reward for this mission ?"), typeText)

        if not PZLinuxContractDialogue.wait(self, dialogue) then return end
        PZLinuxContractDialogue.appendSellerLine(self, dialogue, "$" .. tostring(dialogue.reward), true)

        if not PZLinuxContractDialogue.wait(self, dialogue) then return end
        PZLinuxContractDialogue.appendSellerLine(self, dialogue, PZLinuxContractDialogue.getText("IGUI_PZLinux_Contracts_Deal", "Deal ?"), true)

        PZLinuxContractDialogue.addChoiceButtons(self, contract)
    end)
end
