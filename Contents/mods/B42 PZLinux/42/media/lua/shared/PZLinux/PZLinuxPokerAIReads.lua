-- Shared opponent tracking for poker AI engines that pay attention.
--
-- An engine is only ever asked to decide on its own turn, so it cannot watch
-- the table continuously. What it can do is look at what changed since it last
-- looked: every seat carries its most recent action, and the hand number and
-- phase say when that action happened. Signing each observation with
-- hand/phase/seat/action makes the same action count exactly once no matter
-- how many times the engine is asked to act.
--
-- Everything accumulates in context.memory, which is the one writable surface
-- an engine has and which persists for as long as that seat is at the table.
-- Nothing here reads hole cards: these reads are built from betting behaviour
-- alone, the same information a human at the table would have.
--
-- Usage from an engine's decide():
--
--   local reads = PZLinuxPokerAIObserve(context, PZLinuxPokerAIMemoryOptions(context))
--   local villain = reads.byName[aggressorName]
--   if villain and villain.bluffRate > 0.4 then ... end

PZLinux = PZLinux or {}
PZLinux.Poker = PZLinux.Poker or {}

local function PZLinuxPokerAIActionKind(lastAction)
    local action = tostring(lastAction or "")
    if action == "" then return nil end
    if action:sub(1, 4) == "FOLD" then return "fold" end
    if action:sub(1, 5) == "CHECK" then return "check" end
    if action:sub(1, 4) == "CALL" then return "call" end
    if action:sub(1, 5) == "RAISE" then return "raise" end
    if action:sub(1, 6) == "ALL-IN" then return "allin" end
    return nil
end

local function PZLinuxPokerAIBlankRead(name)
    return {
        name = name,
        actions = 0,
        raises = 0,
        calls = 0,
        checks = 0,
        folds = 0,
        -- Hands in which this seat put in a raise. The denominator for how
        -- often that aggression turned out to be worth nothing.
        aggressiveHands = 0,
        -- Raised earlier in a hand, then folded it before showdown. Not proof
        -- of a bluff -- a real hand can be outdrawn and given up -- but over a
        -- session it is the closest read available without seeing cards.
        foldedAfterRaising = 0,
        handsSeen = 0,
        aggression = 0,
        foldRate = 0,
        bluffRate = 0,
    }
end

-- Derived rates, recomputed after each observation so callers never divide.
local function PZLinuxPokerAIRefreshRead(read)
    local decisions = read.raises + read.calls + read.checks
    read.aggression = decisions > 0 and (read.raises / decisions) or 0
    read.foldRate = read.actions > 0 and (read.folds / read.actions) or 0
    read.bluffRate = read.aggressiveHands > 0 and (read.foldedAfterRaising / read.aggressiveHands) or 0
end

-- options (all optional, from PZLinuxPokerAIMemoryOptions):
--   accuracy  0..1 chance an action is recorded at all
--   window    hands over which old evidence fades; 0 never forgets
--   random    the engine's random source, needed for accuracy
function PZLinuxPokerAIObserve(context, options)
    options = options or {}
    local accuracy = options.accuracy or 1
    local window = options.window or 0
    local random = options.random or context.random

    local memory = context.memory
    local session = context.session
    memory.reads = memory.reads or {}
    memory.hand = memory.hand or {}

    local handNumber = session.handNumber or 0
    if memory.hand.number ~= handNumber then
        -- Evidence fades geometrically rather than dropping off a cliff, so a
        -- read built over a long session stays proportioned while old hands
        -- stop dominating it. Counters are kept fractional on purpose.
        if window > 0 then
            local keep = 1 - (1 / window)
            for _, read in pairs(memory.reads) do
                read.actions = read.actions * keep
                read.raises = read.raises * keep
                read.calls = read.calls * keep
                read.checks = read.checks * keep
                read.folds = read.folds * keep
                read.aggressiveHands = read.aggressiveHands * keep
                read.foldedAfterRaising = read.foldedAfterRaising * keep
            end
        end

        -- New hand: the per-hand marks reset, the per-session totals do not.
        memory.hand = { number = handNumber, raised = {}, folded = {}, seen = {} }
        for _, seat in ipairs(session.seats or {}) do
            if not seat.isHuman or true then
                local read = memory.reads[seat.name]
                if read and seat.inHand then read.handsSeen = read.handsSeen + 1 end
            end
        end
    end

    for index, seat in ipairs(session.seats or {}) do
        if index ~= context.seatIndex then
            local read = memory.reads[seat.name] or PZLinuxPokerAIBlankRead(seat.name)
            memory.reads[seat.name] = read

            local kind = PZLinuxPokerAIActionKind(seat.lastAction)
            if kind then
                -- Sign the observation so re-seeing the same action on a later
                -- turn of the same betting round does not count it twice.
                local signature = table.concat({
                    tostring(handNumber), tostring(session.phase), tostring(index),
                    tostring(seat.lastAction), tostring(seat.committed or 0),
                }, "|")
                -- An imperfect memory simply misses things. The action still
                -- happened; this engine just never files it.
                local noticed = accuracy >= 1 or random(100) < accuracy * 100
                if not memory.hand.seen[signature] and noticed then
                    memory.hand.seen[signature] = true
                    read.actions = read.actions + 1
                    if kind == "raise" or kind == "allin" then
                        read.raises = read.raises + 1
                        if not memory.hand.raised[seat.name] then
                            memory.hand.raised[seat.name] = true
                            read.aggressiveHands = read.aggressiveHands + 1
                        end
                    elseif kind == "call" then
                        read.calls = read.calls + 1
                    elseif kind == "check" then
                        read.checks = read.checks + 1
                    elseif kind == "fold" then
                        read.folds = read.folds + 1
                    end
                end
            end

            -- Giving up a hand it had raised, counted once per hand.
            if seat.folded and memory.hand.raised[seat.name] and not memory.hand.folded[seat.name] then
                memory.hand.folded[seat.name] = true
                read.foldedAfterRaising = read.foldedAfterRaising + 1
            end

            PZLinuxPokerAIRefreshRead(read)
        end
    end

    -- Who is being faced right now: the live opponent whose bet set the price.
    local aggressor = nil
    for index, seat in ipairs(session.seats or {}) do
        if index ~= context.seatIndex and not seat.folded and seat.inHand
            and (seat.bet or 0) > 0 and (seat.bet or 0) >= (session.currentBet or 0) then
            aggressor = memory.reads[seat.name]
        end
    end

    local live, foldRateTotal, samples = 0, 0, 0
    for index, seat in ipairs(session.seats or {}) do
        if index ~= context.seatIndex and seat.inHand and not seat.folded then
            live = live + 1
            local read = memory.reads[seat.name]
            if read and read.actions >= 4 then
                foldRateTotal = foldRateTotal + read.foldRate
                samples = samples + 1
            end
        end
    end

    return {
        byName = memory.reads,
        aggressor = aggressor,
        liveOpponents = live,
        -- Average of the opponents this engine has enough actions to judge.
        -- nil rather than a guess when the table is still unread.
        tableFoldRate = samples > 0 and (foldRateTotal / samples) or nil,
        confident = samples > 0,
    }
end
