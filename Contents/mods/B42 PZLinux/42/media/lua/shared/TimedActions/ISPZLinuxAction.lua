ISPZLinuxAction = ISBaseTimedAction:derive("ISPZLinuxAction")

function ISPZLinuxAction:isValid()
    return true
end

function ISPZLinuxAction:waitToStart()
    return false
end

function ISPZLinuxAction:update()
    return false
end

function ISPZLinuxAction:start()
    return false
end

function ISPZLinuxAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISPZLinuxAction:perform()
    linuxMenu_ShowUI(self.character)
    ISBaseTimedAction.perform(self)
end

function ISPZLinuxAction:new(character)
    local o = ISBaseTimedAction.new(self, character)
    o.maxTime = 5
    return o
end