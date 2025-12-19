--#region : dependencies
local ffi = require "ffi"
--#endregion

--#region : localizing
local __L = function(t) local c = {} for k, v in next, t do c[k] = v end return c end
local ffi, string = __L(ffi), __L(string)
--#endregion

--#region : memory
local memory = {} do
    memory.create_shellcode = function(buffer)
        local size         = #buffer
        local base_address = ffi.C.VirtualAlloc(nil, size, 0x3000, 0x40)

        ffi.gc(base_address, function(addr)
            ffi.C.VirtualFree(addr, size, 0x00008000)
        end)

        ffi.copy(base_address, ffi.new("char[?]", size, buffer), size)
        return base_address
    end
end
--#endregion

--#region : startup
local fn = ffi.cast("uint32_t(__cdecl*)(void)", memory.create_shellcode "\xB8\x37\x13\x00\x00\xC3")
local res = fn()

print(string.format("0x%X", res))
--#endregion
