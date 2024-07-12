-- Cache frequently used _G[*] functions for performance
local require, error, pcall = require, error, pcall

-- Dependencies
local ffi = require "ffi"

-- Cache frequently used ffi.* functions for performance
local ffi_typeof, ffi_cast = ffi.typeof, ffi.cast

local bind_table = function(library, signature, struct, offset)
    local success, result = pcall(client.find_signature, library, signature)

    if success then
        local T = ffi_typeof("$*", struct)
        return ffi_cast(T, ffi_cast("uintptr_t", result) + offset)
    end
end

-- Example

local G = bind_table("client.dll", "\xA1\xCC\xCC\xCC\xCC\x8B\x40\x10\x89\x87", ffi_typeof([[
    struct {
        float real_time;
        int frame_count;
        float absolute_frametime;
        float absolute_frame_start_time_std_dev;
        float curtime;
        float frametime;
        int max_clients;
        int tickcount;
        float tick_interval;
        float interp_amount;
        int sim_ticks;
        int network_protocol;
    }**
]]), 1)[0][0]

client.set_event_callback("net_update_end", function()
    print(G.max_clients == globals.maxplayers()) -- prints 'true'
end)
