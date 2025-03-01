ISMailBoxAction = ISBaseTimedAction:derive("ISMailBoxAction")

function ISMailBoxAction:isValid()
    return true
end

function ISMailBoxAction:waitToStart()
    return false
end

function ISMailBoxAction:update()
    return false
end

function ISMailBoxAction:start()
    return false
end

function ISMailBoxAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISMailBoxAction:perform()
    MailBoxMenu_ShowUI(self.character)
    ISBaseTimedAction.perform(self)
end

function ISMailBoxAction:new(character)
    local o = ISBaseTimedAction.new(self, character)
    o.maxTime = 5
    return o
end