-- Define our module
local M = {}

-- Cache frequently used _G[*] functions for performance
local require, vtable_bind, vtable_thunk, type, tostring = require, vtable_bind, vtable_thunk, type, tostring

-- Dependencies
local ffi = require "ffi"
local vector = require "vector" -- The holy vector library

-- Cache frequently used ffi.* functions for performance
local ffi_typeof, ffi_cast, ffi_new, ffi_string, ffi_metatype, ffi_sizeof = ffi.typeof, ffi.cast, ffi.new, ffi.string, ffi.metatype, ffi.sizeof

-- Cache frequently used client.* and string.* functions for performance
local client_find_signature, string_match = client.find_signature, string.match

-- Define PlayerInfo_t: replica of the struct from https://github.com/perilouswithadollarsign/cstrike15_src/blob/master/public/cdll_int.h#L159
local PlayerInfo_t, PlayerInfo_mt = ffi_typeof([[
    struct {
        uint64_t version;
        uint64_t __xuid;
        char __name[128];
        int userID;
        char __guid[33];
        unsigned int friendsID;
        char __friendsName[128];
        bool fakeplayer;
        bool ishltv;
        unsigned int customFiles[4];
        unsigned char filesDownloaded;
    }
]]), {}

-- Define Stream_t: combination of bf_write and CUtlMemory<byte>
local Stream_t = ffi_typeof([[
    struct {
        uint8_t* data;
        int32_t data_bytes;
        int32_t data_bits;
        int32_t cur_bit;
        bool overflow;
        bool assert_on_overflow;
        const char* name;
        uint8_t* memory;
        int32_t allocation_count;
        int32_t grow_size;
    }
]])

-- Define CBaseClientState_t: replica of the struct from https://gitlab.com/KittenPopo/csgo-2018-source/-/blob/main/engine/baseclientstate.h#L235
local CBaseClientState_t = ffi_typeof([[
    struct {
        char pad0[156];
        struct {
            char pad0[24];
            int32_t out_sequence_nr;
            int32_t in_sequence_nr;
            int32_t out_sequence_nr_ack;
            int32_t out_reliable_state;
            int32_t in_reliable_state;
            int32_t choked_packets;
            $ reliable_stream;
            $ unreliable_stream;
            $ voice_stream;
            int32_t socket;
            int32_t stream_socket;
            uint32_t max_reliable_payload_size;
            bool was_last_message_reliable;
        }* net_channel;
    }***
]], Stream_t, Stream_t, Stream_t)

-- Define Matrix_t: 4x4 matrix with float values
local VMatrix = ffi_typeof "struct { float m[4][4]; }"

local native_GetPlayerInfo = vtable_bind("engine.dll", "VEngineClient014", 8, "bool(__thiscall*)(void*, int, $*)", PlayerInfo_t)
local native_ConIsVisible = vtable_bind("engine.dll", "VEngineClient014", 11, "bool(__thiscall*)(void*)")
local native_GetLastTimeStamp = vtable_bind("engine.dll", "VEngineClient014", 14, "float(__thiscall*)(void*)")
local native_GetViewAngles = vtable_bind("engine.dll", "VEngineClient014", 18, "Vector(__thiscall*)(void*)")
local native_SetViewAngles = vtable_bind("engine.dll", "VEngineClient014", 19, "void(__thiscall*)(void*, Vector&)")
local native_IsInGame = vtable_bind("engine.dll", "VEngineClient014", 26, "bool(__thiscall*)(void*)")
local native_IsConnected = vtable_bind("engine.dll", "VEngineClient014", 27, "bool(__thiscall*)(void*)")
local native_IsConnecting = vtable_bind("engine.dll", "VEngineClient014", 28, "bool(__thiscall*)(void*)")
local native_GetGameDirectory = vtable_bind("engine.dll", "VEngineClient014", 36, "const char*(__thiscall*)(void*)")
local native_WorldToScreenMatrix = vtable_bind("engine.dll", "VEngineClient014", 37, "$*(__thiscall*)(void*)", VMatrix)
local native_WorldToViewMatrix = vtable_bind("engine.dll", "VEngineClient014", 38, "$*(__thiscall*)(void*)", VMatrix)
local native_GetLevelName = vtable_bind("engine.dll", "VEngineClient014", 52, "char const*(__thiscall*)(void*)")
local native_GetTimescale = vtable_bind("engine.dll", "VEngineClient014", 91, "float(__thiscall*)(void*)")
local native_IsTakingScreenshot = vtable_bind("engine.dll", "VEngineClient014", 92, "bool(__thiscall*)(void*)")
local native_GetUILanguage = vtable_bind("engine.dll", "VEngineClient014", 97, "void(__thiscall*)(void*, char*, int)")
local native_WriteScreenshot = vtable_bind("engine.dll", "VEngineClient014", 133, "void(__thiscall*)(void*, const char*)")
local native_GetServerSimulationFrameTime = vtable_bind("engine.dll", "VEngineClient014", 175, "float(__thiscall*)(void*)")
local native_IsActiveApp = vtable_bind("engine.dll", "VEngineClient014", 196, "bool(__thiscall*)(void*)")

local native_WriteToBuffer = vtable_thunk(5, "bool(__thiscall*)(void*, void*)")
local native_IsReliable = vtable_thunk(6, "bool(__thiscall*)(void*)")
local native_Transmit = vtable_thunk(47, "void(__thiscall*)(void*, bool)")

local NetChannelInfo_ptr do
    local result, success = pcall(client_find_signature, "engine.dll", "\x7E\x3E\x8B\x3D\xCC\xCC\xCC\xCC")
    if success then NetChannelInfo_ptr = ffi_cast(CBaseClientState_t, ffi_cast("char*", result) + 4)[0][0].net_channel else error("engine.dll!::CBaseClientState couldn't be found") end
end

local player_info = {
    xuid = function(self) return string_match(tostring(self.__xuid), "%d+") end,
    name = function(self) return ffi_string(self.__name, 128) end,
    uid = function(self) return string_match(tostring(self.userID), "%d+") end,
    guid = function(self) return ffi_string(self.__guid, 33) end,
    friends_id = function(self) return string_match(tostring(self.friendsID), "%d+") end,
    friends_name = function(self) return ffi_string(self.__friendsName, 128) end,
    is_fake_player = function(self) return tostring(self.fakeplayer) end,
    is_hltv = function(self) return tostring(self.ishltv) end,

    custom_files = function(self)
        local files = self.customFiles
        return { files[0], files[1], files[2], files[3] }
    end
}

-- Define metatable index function for PlayerInfo_t
function PlayerInfo_mt:__index(index)
    return player_info[index](self) or nil
end

-- Set metatype for PlayerInfo_t
ffi_metatype(PlayerInfo_t, PlayerInfo_mt)

M.is_console_visible = native_ConIsVisible
M.get_last_timestamp = native_GetLastTimeStamp
M.get_view_angles = native_GetViewAngles
M.set_view_angles = native_SetViewAngles
M.is_in_game = native_IsInGame
M.is_connected = native_IsConnected
M.is_connecting = native_IsConnecting
M.get_time_scale = native_GetTimescale
M.is_taking_screenshot = native_IsTakingScreenshot
M.get_server_simtime = native_GetServerSimulationFrameTime
M.is_app_active = native_IsActiveApp

M.get_player_info = function(entindex)
    if type(entindex) ~= "number" then return nil end

    local out = PlayerInfo_t(0xFFFFFFFFFFFFF002ULL)
    if native_GetPlayerInfo(entindex, out) then return out end
end

M.get_game_directory = function()
    local dir = native_GetGameDirectory()
    return ffi_string(dir)
end

M.world_to_screen_matrix = function()
    return native_WorldToScreenMatrix().m
end

M.world_to_view_matrix = function()
    return native_WorldToViewMatrix().m
end

M.get_ui_language = function()
    local buffer = ffi_new "char[64]"
    native_GetUILanguage(buffer, 64)

    return ffi_string(buffer)
end

M.write_screenshot = function(name)
    local success, result = pcall(tostring, name)
    if success then native_WriteScreenshot(result) end
end

M.transmit = function(reliable_only)
    if NetChannelInfo_ptr == nil then return end
    native_Transmit(NetChannelInfo_ptr, reliable_only)
end

M.is_reliable = function(message)
    return native_IsReliable(message)
end

M.send_net_message = function(message, stream_name)
    if NetChannelInfo_ptr == nil then return end

    if stream_name == nil then
        stream_name = native_IsReliable(message) and "reliable" or "unreliable"
    end

    local stream = NetChannelInfo_ptr[stream_name .. "_stream"]
    native_WriteToBuffer(message, ffi_cast("void*", stream))
end

return M
