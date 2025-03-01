ISStreetMailBoxAction = ISBaseTimedAction:derive("ISStreetMailBoxAction")

function ISStreetMailBoxAction:isValid()
    return true
end

function ISStreetMailBoxAction:waitToStart()
    return false
end

function ISStreetMailBoxAction:update()
    return false
end

function ISStreetMailBoxAction:start()
    return false
end

function ISStreetMailBoxAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISStreetMailBoxAction:perform()
    StreetMailBoxMenu_ShowUI(self.character)
    ISBaseTimedAction.perform(self)
end

function ISStreetMailBoxAction:new(character)
    local o = ISBaseTimedAction.new(self, character)
    o.maxTime = 5
    return o
end