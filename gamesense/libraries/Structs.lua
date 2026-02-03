local ffi = require "ffi"

local M = {}
M.__index = M

M.new = function()
    return setmetatable({ fields = {} }, M)
end

M.field_at = function(self, type, name, offset, length)
    table.insert(self.fields, { type = type, name = name, offset = offset, length = length })
    return self
end

M.generate = function(self, min_size, alignment)
    table.sort(self.fields, function(a, b) return a.offset < b.offset end)

    local place, fixed_fields = 0, {}

    for k, v in ipairs(self.fields) do
        local pad = v.offset - place

        if pad < 0 then
            local last_entry = fixed_fields[#fixed_fields]

            last_entry.unions = last_entry.unions or {}

            table.insert(last_entry.unions, { offset = v.offset, type = v.type, name = v.name, length = v.length })

            local highest = last_entry

            for k, v in ipairs(last_entry.unions) do
                if highest.offset + ffi.sizeof(highest.type) * (highest.length or 1) < v.offset + ffi.sizeof(v.type) * (v.length or 1) then highest = v end
            end

            place = highest.offset + ffi.sizeof(highest.type) * (highest.length or 1)

        elseif pad > 0 then
            table.insert(fixed_fields, { type = "char", name = "pad_" .. string.format("%04X", place), offset = place, length = pad })
            place = place + pad
        end

        if pad >= 0 then
            table.insert(fixed_fields, v)
            place = place + ffi.sizeof(v.type) * (v.length or 1)
        end
    end

    local struct = "struct __attribute__((packed"

    if alignment ~= nil and alignment > 0 then struct = struct .. ",aligned(" .. tostring(alignment) .. ")" end

    struct = struct .. ")) {"
    local vpad_index = 0

    for k, v in ipairs(fixed_fields) do
        if v.unions ~= nil then
            struct = struct .. "union __attribute__((packed)) {"
            struct = struct .. v.type .. " " .. v.name

            if v.length then struct = struct .. "[" .. v.length .. "]" end
            struct = struct .. ";"

            table.sort(v.unions, function(a, b) return a.offset < b.offset end)

            local lplace = v.offset

            for k2, v2 in ipairs(v.unions) do
                local pad = v2.offset - lplace

                if pad > 0 then
                    struct = struct .. "struct __attribute__((packed)) {"
                    struct = struct .. "char vpad_" .. string.format("%04X", lplace) .. "_" .. string.format("%X", vpad_index) .. "[" .. tostring(pad) .. "];"
                    vpad_index = vpad_index + 1
                end

                struct = struct .. v2.type .. " " .. v2.name

                if v2.length then struct = struct .. "[" .. v2.length .. "]" end
                struct = struct .. ";"

                if pad > 0 then struct = struct .. "};" end
            end

            struct = struct .. "};"
        else
            struct = struct .. v.type .. " " .. v.name
            if v.length then struct = struct .. "[" .. v.length .. "]" end

            struct = struct .. ";"
        end
    end

    if min_size ~= nil and min_size > 0 then
        local size = ffi.sizeof(struct .. "}")

        if size < min_size then
            local pad = min_size - size
            struct = struct .. "char pad_" .. string.format("%04X", place) .. "[" .. tostring(pad) .. "];"
        end
    end

    struct = struct .. "}"

    for k, v in ipairs(fixed_fields) do
        assert(v.offset == ffi.offsetof(struct, v.name), v.name .. " has offset " .. ffi.offsetof(struct, v.name) .. " (needs" .. v.offset .. ")")

        for k2, v2 in ipairs(v.unions or {}) do
            assert(v2.offset == ffi.offsetof(struct, v2.name), v2.name .. " has offset " .. ffi.offsetof(struct, v2.name) .. " (needs" .. v2.offset .. ")")
        end
    end

    return struct
end

M.generate_type = function(self, min_size, alignment)
    return ffi.typeof(self:generate(min_size, alignment))
end

M.generate_ptr_type = function(self, min_size, alignment)
    return ffi.typeof(self:generate(min_size, alignment) .. "*")
end

M.generate_vararr_type = function(self, min_size, alignment)
    return ffi.typeof(self:generate(min_size, alignment) .. "[?]")
end

M.generate_arr_type = function(self, length, min_size, alignment)
    return ffi.typeof(self:generate(min_size, alignment) .. "[" .. tostring(length) .. "]")
end

return M
