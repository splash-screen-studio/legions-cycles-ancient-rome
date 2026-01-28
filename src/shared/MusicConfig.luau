--!strict
--[[
    MusicConfig - Track definitions and configuration for the ambient music system
    Contains Roman-themed soundtrack asset IDs and playback settings
]]

local MusicConfig = {}

-- Track asset IDs (uploaded to Roblox)
MusicConfig.TRACKS = {
    dawn = {
        id = "rbxassetid://123517555949581",
        name = "Dawn",
        theme = "Morning, peaceful start",
    },
    forum = {
        id = "rbxassetid://92805060343276",
        name = "Forum",
        theme = "Marketplace, social areas",
    },
    march = {
        id = "rbxassetid://139982351033320",
        name = "March",
        theme = "Military, marching",
    },
    colosseum = {
        id = "rbxassetid://94282741928731",
        name = "Colosseum",
        theme = "Arena, combat",
    },
    caesar = {
        id = "rbxassetid://83679996557602",
        name = "Caesar",
        theme = "Imperial, grand",
    },
    eternal = {
        id = "rbxassetid://122383615563909",
        name = "Eternal",
        theme = "Evening, reflective",
    },
}

-- Playlist order for sequential playback
MusicConfig.PLAYLIST_ORDER = {
    "dawn",
    "forum",
    "march",
    "colosseum",
    "caesar",
    "eternal",
}

-- Playback settings
MusicConfig.CROSSFADE_DURATION = 3 -- seconds
MusicConfig.DEFAULT_VOLUME = 0.5 -- 0.0 to 1.0
MusicConfig.MIN_VOLUME = 0
MusicConfig.MAX_VOLUME = 1

return MusicConfig
