function PZLinux_Contract_SendComputer_CreateCoroutine(self, contract, contractsCompanyCodes, contractsCompanyReward, typeText)
    return coroutine.create(function()
        local dialogue = PZLinuxContractDialogue.create(self, contract, contractsCompanyCodes, contractsCompanyReward)
        dialogue.modData.PZLinuxContractInfoCount = 1

        PZLinuxContractDialogue.setSellerLine(self, dialogue, PZLinuxContractDialogue.getText("IGUI_PZLinux_Contracts_SendComputer_Intro", "We are looking for a computer."), true)

        if not PZLinuxContractDialogue.wait(self, dialogue, 100, 200) then return end
        PZLinuxContractDialogue.ask(self, dialogue, PZLinuxContractDialogue.getText("IGUI_PZLinux_Contracts_AskReward", "What is the reward for this mission ?"), typeText)

        if not PZLinuxContractDialogue.wait(self, dialogue, 100, 200) then return end
        PZLinuxContractDialogue.appendSellerLine(self, dialogue, "$" .. dialogue.modData.PZLinuxOnReward, true)

        if not PZLinuxContractDialogue.wait(self, dialogue, 100, 200) then return end
        PZLinuxContractDialogue.appendSellerLine(self, dialogue, PZLinuxContractDialogue.getText("IGUI_PZLinux_Contracts_Deal", "Deal ?"), true)

        PZLinuxContractDialogue.addChoiceButtons(self, contract)
    end)
end
