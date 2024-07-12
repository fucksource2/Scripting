-- Cache frequently used _G[*] functions for performance
local require, error = require, error

-- Dependencies
local ffi = require "ffi"

-- Cache frequently used ffi.* & client.* functions for performance
local ffi_cast, client_find_signature = ffi.cast, client.find_signature

-- Find the jmp ecx instruction in engine.dll
local signature_jmpecx = client_find_signature("engine.dll", "\xFF\xE1") or error "engine.dll!::jmp ecx couldn't be found"

-- Find GetModuleHandle and GetProcAddress in engine.dll
local signature_GetModuleHandle = client_find_signature("engine.dll", "\xFF\x15\xCC\xCC\xCC\xCC\x85\xC0\x74\x0B") or error "engine.dll!::GetModuleHandle couldn't be found"
local signature_GetProcAddress = client_find_signature("engine.dll", "\xFF\x15\xCC\xCC\xCC\xCC\xA3\xCC\xCC\xCC\xCC\xEB\x05") or error "engine.dll!::GetProcAddress couldn't be found"

-- Define a thunk function for calling function pointers with specified address and typestring
local thunk = function(address, typestring)
    return function(...) return ffi_cast(typestring, signature_jmpecx)(address, ...) end
end

-- Initialize the GetModuleHandle and GetProcAddress functions using the previously found addresses and jmp instruction
local native_GetModuleHandle = thunk(ffi_cast("void***", ffi_cast("uint32_t", signature_GetModuleHandle) + 2)[0][0], "void*(__thiscall*)(void*, const char*)")
local native_GetProcAddress = thunk(ffi_cast("void***", ffi_cast("uint32_t", signature_GetProcessAddress) + 2)[0][0], "void*(__thiscall*)(void*, void*, const char*)")

-- Define a bind function to retrieve function pointers by module name, address, and typestring
local bind = function(module_name, address, typestring)
    local handle = native_GetModuleHandle(module_name)
    return function(...) return thunk(native_GetProcessAddress(handle, address), typestring) end
end

-- Example usage: binding FindWindowA function from kernel32.dll
local native_FindWindowA = bind("kernel32.dll", "FindWindowA", "void*(__thiscall*)(void*, const char*, const char*)")
