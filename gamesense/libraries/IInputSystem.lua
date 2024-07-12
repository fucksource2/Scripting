-- Define our module
local M = {}
local MT = { __index = M, __metatable = "inputsystem_key" }

-- Cache frequently used _G[*] functions for performance
local require, vtable_bind, getmetatable, setmetatable, type = require, vtable_bind, getmetatable, setmetatable, type

-- Dependencies
local ffi = require "ffi"

-- Cache frequently used ffi.* functions for performance
local ffi_typeof, ffi_new, ffi_string = ffi.typeof, ffi.new, ffi.string

-- Cache frequently used globals.* functions for performance
local globals_tickcount = globals.tickcount

-- Define EButtonCode: replica of the enum from https://gitlab.com/KittenPopo/csgo-2018-source/-/blob/main/public/inputsystem/ButtonCode.h#L52
local EButtonCode = ffi_typeof([[
    enum {
        BUTTON_CODE_INVALID = -1,
        BUTTON_CODE_NONE = 0,

        KEY_FIRST = 0,

        KEY_NONE = KEY_FIRST,
        KEY_0,
        KEY_1,
        KEY_2,
        KEY_3,
        KEY_4,
        KEY_5,
        KEY_6,
        KEY_7,
        KEY_8,
        KEY_9,
        KEY_A,
        KEY_B,
        KEY_C,
        KEY_D,
        KEY_E,
        KEY_F,
        KEY_G,
        KEY_H,
        KEY_I,
        KEY_J,
        KEY_K,
        KEY_L,
        KEY_M,
        KEY_N,
        KEY_O,
        KEY_P,
        KEY_Q,
        KEY_R,
        KEY_S,
        KEY_T,
        KEY_U,
        KEY_V,
        KEY_W,
        KEY_X,
        KEY_Y,
        KEY_Z,
        KEY_PAD_0,
        KEY_PAD_1,
        KEY_PAD_2,
        KEY_PAD_3,
        KEY_PAD_4,
        KEY_PAD_5,
        KEY_PAD_6,
        KEY_PAD_7,
        KEY_PAD_8,
        KEY_PAD_9,
        KEY_PAD_DIVIDE,
        KEY_PAD_MULTIPLY,
        KEY_PAD_MINUS,
        KEY_PAD_PLUS,
        KEY_PAD_ENTER,
        KEY_PAD_DECIMAL,
        KEY_LBRACKET,
        KEY_RBRACKET,
        KEY_SEMICOLON,
        KEY_APOSTROPHE,
        KEY_BACKQUOTE,
        KEY_COMMA,
        KEY_PERIOD,
        KEY_SLASH,
        KEY_BACKSLASH,
        KEY_MINUS,
        KEY_EQUAL,
        KEY_ENTER,
        KEY_SPACE,
        KEY_BACKSPACE,
        KEY_TAB,
        KEY_CAPSLOCK,
        KEY_NUMLOCK,
        KEY_ESCAPE,
        KEY_SCROLLLOCK,
        KEY_INSERT,
        KEY_DELETE,
        KEY_HOME,
        KEY_END,
        KEY_PAGEUP,
        KEY_PAGEDOWN,
        KEY_BREAK,
        KEY_LSHIFT,
        KEY_RSHIFT,
        KEY_LALT,
        KEY_RALT,
        KEY_LCONTROL,
        KEY_RCONTROL,
        KEY_LWIN,
        KEY_RWIN,
        KEY_APP,
        KEY_UP,
        KEY_LEFT,
        KEY_DOWN,
        KEY_RIGHT,
        KEY_F1,
        KEY_F2,
        KEY_F3,
        KEY_F4,
        KEY_F5,
        KEY_F6,
        KEY_F7,
        KEY_F8,
        KEY_F9,
        KEY_F10,
        KEY_F11,
        KEY_F12,
        KEY_CAPSLOCKTOGGLE,
        KEY_NUMLOCKTOGGLE,
        KEY_SCROLLLOCKTOGGLE,

        KEY_LAST = KEY_SCROLLLOCKTOGGLE,

        MOUSE_FIRST = KEY_LAST + 1,

        MOUSE_LEFT = MOUSE_FIRST,
        MOUSE_RIGHT,
        MOUSE_MIDDLE,
        MOUSE_4,
        MOUSE_5,
        MOUSE_WHEEL_UP,
        MOUSE_WHEEL_DOWN,

        MOUSE_LAST = MOUSE_WHEEL_DOWN
    }
]])

-- Define EInputEventType: replica of the enum from https://gitlab.com/KittenPopo/csgo-2018-source/-/blob/main/public/inputsystem/InputEnums.h#L72
local EInputEventType = ffi_typeof([[
    enum {
        IE_ButtonPressed = 0,
        IE_ButtonReleased,
        IE_ButtonDoubleClicked,
        IE_AnalogValueChanged,

        IE_FirstSystemEvent = 100,
        IE_Quit = IE_FirstSystemEvent,
        IE_ControllerInserted,
        IE_ControllerUnplugged,
        IE_Close,
        IE_WindowSizeChanged,
        IE_PS_CameraUnplugged, 
        IE_PS_Move_OutOfView,

        IE_FirstUIEvent = 200,
        IE_LocateMouseClick = IE_FirstUIEvent,
        IE_SetCursor,
        IE_KeyTyped,
        IE_KeyCodeTyped,
        IE_InputLanguageChanged,
        IE_IMESetWindow,
        IE_IMEStartComposition,
        IE_IMEComposition,
        IE_IMEEndComposition,
        IE_IMEShowCandidates,
        IE_IMEChangeCandidates,
        IE_IMECloseCandidates,
        IE_IMERecomputeModes,
        IE_OverlayEvent,

        IE_FirstVguiEvent = 1000,
        IE_FirstAppEvent = 2000,
    }
]])

-- Define InputEvent_t: replica of the struct from https://gitlab.com/KittenPopo/csgo-2018-source/-/blob/main/public/inputsystem/InputEnums.h#L108
local InputEvent_t = ffi_typeof([[
    struct {
        int m_nType;
        int m_nTick;
        int m_nData;
        int m_nData2;
        int m_nData3;
    }[?]
]])

local pX, pY = ffi_new "int[1]", ffi_new "int[1]"

local native_IsButtonDown = vtable_bind("inputsystem.dll", "InputSystemVersion001", 15, "bool(__thiscall*)(void*, int)")
local native_GetButtonPressedTick = vtable_bind("inputsystem.dll", "InputSystemVersion001", 16, "int(__thiscall*)(void*, int)")
local native_GetButtonReleasedTick = vtable_bind("inputsystem.dll", "InputSystemVersion001", 17, "int(__thiscall*)(void*, int)")
local native_PostUserEvent = vtable_bind("inputsystem.dll", "InputSystemVersion001", 32, "void(__thiscall*)(void*, $*)", InputEvent_t)
local native_ButtonCodeToString = vtable_bind("inputsystem.dll", "InputSystemVersion001", 40, "const char*(__thiscall*)(void*, int)")
local native_ButtonCodeToString = vtable_bind("inputsystem.dll", "InputSystemVersion001", 40, "const char*(__thiscall*)(void*, int)")
local native_ButtonCodeToVirtualKey = vtable_bind("inputsystem.dll", "InputSystemVersion001", 46, "int(__thiscall*)(void*, int)")
local native_SetCursorPosition = vtable_bind("inputsystem.dll", "InputSystemVersion001", 49, "int(__thiscall*)(void*, int, int)")
local native_GetCursorPosition = vtable_bind("inputsystem.dll", "InputSystemVersion001", 56, "int(__thiscall*)(void*, int*, int*)")

local button_info = {
    is_down = function(self) return native_IsButtonDown(self[1]) end,
    pressed = function(self) return native_GetButtonPressedTick(self[1]) end,
    released = function(self) return native_GetButtonReleasedTick(self[1]) end,
    vkey = function(self) return native_ButtonCodeToVirtualKey(self[1])
}

function MT:__index(index)
    return button_info[index](self) or nil
end

function MT:__tostring()
    local str = native_ButtonCodeToString(self[1])
    return ffi_string(str)
end

function MT.__eq(a, b)
    if getmetatable(a) == "inputsystem_key" and getmetatable(b) == "inputsystem_key" then return a[1] == b[1] end
    return false
end

M.bind_key = function(key)
    local k = type(key) == "string" and EButtonCode(key) or key
    return setmetatable({ [1] = k or 0 }, MT)
end

M.post_user_event = function(key, event)
    local e = InputEvent_t(1)

    e[0].m_nType = EInputEventType(event)
    e[0].m_nTick = globals_tickcount()
    e[0].m_nData = key

    native_PostUserEvent(e)
end

M.get_cursor_position = function()
    native_GetCursorPosition(pX, pY)
    return pX[0], pY[0]
end

M.set_cursor_position = native_SetCursorPosition

return M
