--!strict
--[[
    MusicManager - Client-side ambient music system for Legions & Cycles: Ancient Rome
    Handles playback of Roman-themed soundtrack with smooth crossfading between tracks.

    Features:
    - Play individual tracks or shuffle playlist
    - Smooth crossfade transitions between tracks
    - Volume control (master volume)
    - Auto-advance to next track on completion

    Based on BRicey ambient music techniques
]]

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MusicConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MusicConfig"))
local Maid = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Maid"))

local MusicManager = {}
MusicManager.__index = MusicManager

export type MusicManager = typeof(setmetatable({} :: {
    _sounds: { [string]: Sound },
    _currentTrack: string?,
    _currentSound: Sound?,
    _masterVolume: number,
    _isPlaying: boolean,
    _playlistIndex: number,
    _shuffleMode: boolean,
    _shuffledPlaylist: { string },
    _maid: Maid.Maid,
    _crossfadeThread: thread?,
}, MusicManager))

--- Creates a new MusicManager instance
function MusicManager.new(): MusicManager
    local self = setmetatable({
        _sounds = {} :: { [string]: Sound },
        _currentTrack = nil :: string?,
        _currentSound = nil :: Sound?,
        _masterVolume = MusicConfig.DEFAULT_VOLUME,
        _isPlaying = false,
        _playlistIndex = 1,
        _shuffleMode = false,
        _shuffledPlaylist = {} :: { string },
        _maid = Maid.new(),
        _crossfadeThread = nil :: thread?,
    }, MusicManager)

    self:_createSounds()
    return self
end

--- Creates Sound instances in SoundService for each track
function MusicManager:_createSounds(): ()
    -- Create a SoundGroup for music if it doesn't exist
    local musicGroup = SoundService:FindFirstChild("MusicGroup") :: SoundGroup?
    if not musicGroup then
        musicGroup = Instance.new("SoundGroup")
        musicGroup.Name = "MusicGroup"
        musicGroup.Volume = 1
        musicGroup.Parent = SoundService
    end

    -- Create Sound instances for each track
    for trackName, trackData in MusicConfig.TRACKS do
        local sound = Instance.new("Sound")
        sound.Name = trackName
        sound.SoundId = trackData.id
        sound.Volume = 0
        sound.Looped = false -- We handle looping via playlist
        sound.SoundGroup = musicGroup
        sound.Parent = SoundService

        self._sounds[trackName] = sound
        self._maid:give(sound)

        -- Connect to track end event for auto-advance
        self._maid:give(sound.Ended:Connect(function()
            if self._currentTrack == trackName and self._isPlaying then
                self:_advancePlaylist()
            end
        end))
    end
end

--- Generates a shuffled playlist
function MusicManager:_generateShuffledPlaylist(): ()
    -- Copy the playlist order
    self._shuffledPlaylist = table.clone(MusicConfig.PLAYLIST_ORDER)

    -- Fisher-Yates shuffle
    for i = #self._shuffledPlaylist, 2, -1 do
        local j = math.random(1, i)
        self._shuffledPlaylist[i], self._shuffledPlaylist[j] = self._shuffledPlaylist[j], self._shuffledPlaylist[i]
    end
end

--- Gets the current playlist (shuffled or sequential)
function MusicManager:_getCurrentPlaylist(): { string }
    if self._shuffleMode then
        if #self._shuffledPlaylist == 0 then
            self:_generateShuffledPlaylist()
        end
        return self._shuffledPlaylist
    end
    return MusicConfig.PLAYLIST_ORDER
end

--- Advances to the next track in the playlist
function MusicManager:_advancePlaylist(): ()
    local playlist = self:_getCurrentPlaylist()
    self._playlistIndex = self._playlistIndex + 1

    -- Loop back to start if we've finished the playlist
    if self._playlistIndex > #playlist then
        self._playlistIndex = 1
        -- Reshuffle if in shuffle mode
        if self._shuffleMode then
            self:_generateShuffledPlaylist()
        end
    end

    local nextTrack = playlist[self._playlistIndex]
    self:playTrack(nextTrack)
end

--- Performs a smooth crossfade between two tracks
function MusicManager:_crossfade(fromSound: Sound?, toSound: Sound, duration: number): ()
    -- Cancel any existing crossfade
    if self._crossfadeThread then
        task.cancel(self._crossfadeThread)
        self._crossfadeThread = nil
    end

    self._crossfadeThread = task.spawn(function()
        toSound.Volume = 0
        toSound:Play()

        local startTime = tick()
        while tick() - startTime < duration do
            local alpha = (tick() - startTime) / duration
            local easeAlpha = alpha * alpha * (3 - 2 * alpha) -- Smoothstep easing

            if fromSound then
                fromSound.Volume = (1 - easeAlpha) * self._masterVolume
            end
            toSound.Volume = easeAlpha * self._masterVolume

            task.wait()
        end

        -- Ensure final values
        if fromSound then
            fromSound:Stop()
            fromSound.Volume = 0
        end
        toSound.Volume = self._masterVolume

        self._crossfadeThread = nil
    end)
end

--- Plays a specific track by name
function MusicManager:playTrack(trackName: string): ()
    local sound = self._sounds[trackName]
    if not sound then
        warn("[MusicManager] Track not found:", trackName)
        return
    end

    local previousSound = self._currentSound
    self._currentTrack = trackName
    self._currentSound = sound
    self._isPlaying = true

    -- Update playlist index to match the track
    local playlist = self:_getCurrentPlaylist()
    for i, name in playlist do
        if name == trackName then
            self._playlistIndex = i
            break
        end
    end

    -- Crossfade from previous track (or just fade in if none)
    self:_crossfade(previousSound, sound, MusicConfig.CROSSFADE_DURATION)
end

--- Stops the currently playing track with fade out
function MusicManager:stop(): ()
    if not self._currentSound then
        return
    end

    self._isPlaying = false

    -- Cancel any existing crossfade
    if self._crossfadeThread then
        task.cancel(self._crossfadeThread)
        self._crossfadeThread = nil
    end

    -- Fade out
    local soundToStop = self._currentSound
    task.spawn(function()
        local startVolume = soundToStop.Volume
        local startTime = tick()
        local duration = MusicConfig.CROSSFADE_DURATION

        while tick() - startTime < duration do
            local alpha = (tick() - startTime) / duration
            soundToStop.Volume = startVolume * (1 - alpha)
            task.wait()
        end

        soundToStop:Stop()
        soundToStop.Volume = 0
    end)

    self._currentSound = nil
    self._currentTrack = nil
end

--- Pauses the currently playing track
function MusicManager:pause(): ()
    if self._currentSound and self._isPlaying then
        self._currentSound:Pause()
        self._isPlaying = false
    end
end

--- Resumes the currently paused track
function MusicManager:resume(): ()
    if self._currentSound and not self._isPlaying then
        self._currentSound:Resume()
        self._isPlaying = true
    end
end

--- Sets the master volume (0.0 to 1.0)
function MusicManager:setVolume(volume: number): ()
    self._masterVolume = math.clamp(volume, MusicConfig.MIN_VOLUME, MusicConfig.MAX_VOLUME)

    -- Update current sound if playing and not in crossfade
    if self._currentSound and self._isPlaying and not self._crossfadeThread then
        self._currentSound.Volume = self._masterVolume
    end
end

--- Gets the current master volume
function MusicManager:getVolume(): number
    return self._masterVolume
end

--- Starts playing through the playlist
function MusicManager:playPlaylist(shuffle: boolean?): ()
    self._shuffleMode = shuffle or false
    self._playlistIndex = 1

    if self._shuffleMode then
        self:_generateShuffledPlaylist()
    end

    local playlist = self:_getCurrentPlaylist()
    local firstTrack = playlist[1]
    self:playTrack(firstTrack)
end

--- Skips to the next track in the playlist
function MusicManager:nextTrack(): ()
    if self._isPlaying then
        self:_advancePlaylist()
    end
end

--- Returns to the previous track in the playlist
function MusicManager:previousTrack(): ()
    local playlist = self:_getCurrentPlaylist()
    self._playlistIndex = self._playlistIndex - 1

    if self._playlistIndex < 1 then
        self._playlistIndex = #playlist
    end

    local prevTrack = playlist[self._playlistIndex]
    self:playTrack(prevTrack)
end

--- Gets the name of the currently playing track
function MusicManager:getCurrentTrack(): string?
    return self._currentTrack
end

--- Returns whether music is currently playing
function MusicManager:isPlaying(): boolean
    return self._isPlaying
end

--- Toggles shuffle mode
function MusicManager:setShuffle(enabled: boolean): ()
    self._shuffleMode = enabled
    if enabled then
        self:_generateShuffledPlaylist()
    end
end

--- Returns whether shuffle mode is enabled
function MusicManager:isShuffleEnabled(): boolean
    return self._shuffleMode
end

--- Cleans up the MusicManager
function MusicManager:destroy(): ()
    self:stop()
    self._maid:destroy()
end

-- Create singleton instance and start playing
local musicManager = MusicManager.new()

-- Start playing the soundtrack playlist
musicManager:playPlaylist(false) -- Sequential playback

-- Expose the manager globally for debugging/other scripts
_G.MusicManager = musicManager

print("[MusicManager] Initialized - Playing Roman soundtrack")

return MusicManager
