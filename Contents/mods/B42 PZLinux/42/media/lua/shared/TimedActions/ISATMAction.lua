ISATMAction = ISBaseTimedAction:derive("ISATMAction")

function ISATMAction:isValid()
    return true
end

function ISATMAction:waitToStart()
    return false
end

function ISATMAction:update()
    return false
end

function ISATMAction:start()
    return false
end

function ISATMAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISATMAction:perform()
    AtmMenu_ShowUI(self.character)
    ISBaseTimedAction.perform(self)
end

function ISATMAction:new(character)
    local o = ISBaseTimedAction.new(self, character)
    o.maxTime = 5
    return o
end