--#region : dependencies
local ffi = require "ffi"
--#endregion

--#region : localizing
local __L = function(t) local c = {} for k, v in next, t do c[k] = v end return c end
local ffi, client, string = __L(ffi), __L(client), __L(string)
--#endregion

--#region : constants
local signatures = {
    jmp_ecx           = { "engine.dll", "\xFF\xE1", "stdcall" },
    get_module_handle = { "engine.dll", "\xFF\x15\xCC\xCC\xCC\xCC\x85\xC0\x74\x0B", "GetModuleHandle" },
    get_proc_address  = { "engine.dll", "\xFF\x15\xCC\xCC\xCC\xCC\xA3\xCC\xCC\xCC\xCC\xEB\x05", "GetProcAddress" }
}
--#endregion

--#region : memory
local memory = {} do
    for k, v in pairs(signatures) do
        local success, result = pcall(client.find_signature, v[1], v[2])
        if success then memory[k] = result else error(string.format("%s!::%s couldn't be found", v[1], v[3])) end
    end

    memory.thunk = function(address, typestring) return function(...) return ffi.cast(typestring, memory.jmp_ecx)(address, ...) end end

    memory.get_module_handle = memory.thunk(ffi.cast("void***", ffi.cast("uint32_t", memory.get_module_handle) + 2)[0][0], "void*(__thiscall*)(void*, const char*)")
    memory.get_proc_address  = memory.thunk(ffi.cast("void***", ffi.cast("uint32_t", memory.get_proc_address) + 2)[0][0], "void*(__thiscall*)(void*, void*, const char*)")

    memory.bind = function(module_name, address, typestring)
        local handle = memory.get_module_handle(module_name)
        if handle == nil then return nil end

        local proc = memory.get_proc_address(handle, address)
        if proc == nil then return nil end

        return memory.thunk(proc, typestring)
    end

    memory.virtual_alloc   = memory.bind("kernel32.dll", "VirtualAlloc", "void*(__thiscall*)(void*, void*, size_t, unsigned long, unsigned long)")
    memory.virtual_free    = memory.bind("kernel32.dll", "VirtualFree", "int(__thiscall*)(void*, void*, size_t, unsigned long)")

    memory.create_shellcode = function(buffer)
        local size         = #buffer
        local base_address = memory.virtual_alloc(nil, size, 0x3000, 0x40)

        ffi.gc(base_address, function(addr)
            memory.virtual_free(addr, size, 0x00008000)
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
