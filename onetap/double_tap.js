// Cache frequently used Cheat.* functions for performance
const Cheat_RegisterCallback = Cheat.RegisterCallback

// Cache frequently used Globals.* functions for performance
const Globals_Curtime = Globals.Curtime, Globals_TickInterval = Globals.TickInterval

// Cache frequently used Entity.* functions for performance
const Entity_GetLocalPlayer = Entity.GetLocalPlayer, Entity_GetWeapon = Entity.GetWeapon, Entity_IsValid = Entity.IsValid, Entity_GetProp = Entity.GetProp

// Cache frequently used Exploit.* functions for performance
const Exploit_GetCharge = Exploit.GetCharge, Exploit_EnableRecharge = Exploit.EnableRecharge, Exploit_DisableRecharge = Exploit.DisableRecharge, Exploit_Recharge = Exploit.Recharge, Exploit_OverrideShift = Exploit.OverrideShift, Exploit_OverrideMaxProcessTicks = Exploit.OverrideMaxProcessTicks

// Global variables
const gTicks = 14;

// This will override the cheat's internal cap for amount of shifted ticks to gTicks + 2
Exploit_OverrideMaxProcessTicks(gTicks + 2);

const utils = {
    getCurtime: function(offset){
        return Globals_Curtime() - (offset * Globals_TickInterval());
    },

    weaponReady: function(player){
        const weapon = Entity_GetWeapon(player);

        if (!Entity_IsValid(weapon))return false;

        if (this.getCurtime(16) < Entity_GetProp(player, "CCSPlayer", "m_flNextAttack"))return false;
        if (this.getCurtime(0) < Entity_GetProp(weapon, "CBaseCombatWeapon", "m_flNextPrimaryAttack"))return false;

        return true;
    }
}

const callbacks = {
    onCreateMove: function(){
        const localPlayer = Entity_GetLocalPlayer();
        const isCharged = Exploit_GetCharge();

        if (utils.weaponReady(localPlayer) && isCharged != 1){
            Exploit_DisableRecharge();
            Exploit_OverrideShift(gTicks + 2);
            Exploit_Recharge();
        }

        Exploit_OverrideShift(gTicks);
    },

    onUnload: function(){
        Exploit_OverrideMaxProcessTicks(14); // This will override the cheat's internal cap for amount of shifted ticks to its default value
        Exploit_EnableRecharge(); // This will make the cheat automatically recharge the exploits.
    }
}

// Export callbacks due to Cheat.RegisterCallback behavior
const onCreateMove = callbacks.onCreateMove, onUnload = callbacks.onUnload;

// Register callbacks
Cheat_RegisterCallback("CreateMove", "onCreateMove");
Cheat_RegisterCallback("unload", "onUnload");
