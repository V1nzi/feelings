Feelings = {}
Feelings.__index = Feelings

function Feelings.new(gain, max_hear_distance)
    local self = setmetatable({}, Feelings)
    self.gain = gain
    self.max_hear_distance = max_hear_distance
    return self
end

local feeling_sounds = {
    { name = 'feelings_scream1', duration = 1.6 },
    { name = 'feelings_scream2', duration = 1.6 },
    { name = 'feelings_scream3', duration = 1.8 },
    { name = 'feelings_scream4', duration = 2.4 },
    { name = 'feelings_scream6', duration = 2.1 },
    { name = 'feelings_curses4', duration = 0.7 },
    { name = 'feelings_curses5', duration = 2.6 }
}

local function get_random_feeling()
    math.randomseed(os.clock() ^ 5)
    return feeling_sounds[math.random(1, table.getn(feeling_sounds))]
end

local active_feelings = {} -- store, who (or what) is currently feeling what

local function stop_feeling(sentient_identifier)
    local feeling_handle = active_feelings[sentient_identifier]

    if feeling_handle ~= nil then
        minetest.sound_stop(feeling_handle)
        active_feelings[sentient_identifier] = nil
    end
end

function Feelings:feel(pos, sentient_identifier, connected_object)
    local active_feeling = active_feelings[sentient_identifier]

    if not active_feeling then
        local feeling = get_random_feeling()

        active_feelings[sentient_identifier] = minetest.sound_play(feeling.name, {
            pos = pos,
            object = connected_object,
            gain = self.gain,
            max_hear_distance = self.max_hear_distance
        })

        minetest.after(feeling.duration, stop_feeling, sentient_identifier)
    end
end

function Feelings:stop_feeling(sentient_identifier) stop_feeling(sentient_identifier) end