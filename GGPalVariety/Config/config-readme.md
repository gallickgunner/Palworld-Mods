# Configuration Reference

This file documents every option in `Config/config.lua`.

Most options can be changed independently, but a few systems depend on or interact with other settings; those relationships are called out in the relevant sections below.

> **Important:** Size range values in the current implementation are **absolute final Pal scales**, not additive offsets. For a normal Pal, `1.0` is vanilla native size, `0.5` is half scale, and `2.0` is double scale.

## Quick navigation

- [Randomizer Settings](#randomize_seed_size)
  
- [Size Variation](#leader_pal_scale_offset)  

- [Color Variety](#color_variety)  

- [Rideability](#Rideability)  

- [Trust and growth](#trust)  

- [Work Suitability](#work_suitability)  

- [Stat Variety](#Stats)  

- [Difficulty](#Difficulty)  

- [Wild Pal Spawning](#pals_spawn_disordered)  

- [Maintenance and debugging](#uninstall_mode)


## General conventions

Range options use `min` and `max`. Keep `min <= max`. `min` can be equal to `max` to set that setting to an absolute value instead of rolling for a random value between the range. Both `min` and `max` are inclusive when rolling for a random value.

This mod applies randomization to size and color based on each Pal’s unique ID. So even after getting captured the randomization persists because everything is derived from the Pal ID which remains constant even after capturing and is unique for every Pal.

Size and color variation are deterministic in that sense. The same Pal instance ID plus the same seed produces the same result. Changing a seed rerolls that visual property without changing the Pal’s ID. This means the randomization is consistent for every seed value you use. You can change the seed, get a different result, then change back to the old seed value and get your old results back.

Palworld categorizes its pals into various size categories. These range from small to extra large. This config file presents options to tuen the scale of all the possible categories. To check which pal belongs to which size category, refer [here](https://github.com/gallickgunner/Palworld-Mods/blob/main/allPals.json)


---

# Size and deterministic randomization

### `randomize_seed_size`

A string appended to each Pal’s instance ID before generating its deterministic size. Changing this value rerolls deterministic Pal sizes while keeping everything else unchanged. This might be useful combined with the setting [`randomized_captured_pals`](#randomize_captured_pals). If you are starting from scratch, this doesn’t mean much. It’s main use is to let people reroll size if they don’t like it for their captured pals.

```lua
randomize_seed_size = "default"

```

### `randomize_seed_color`

Same as above but for the color variation. Change this if you don’t like what colors you got for your captured pals.

```lua
randomize_seed_size = "default_color"
```

### `randomize_captured_pals`

Controls whether the mod applies its **size and color randomization** to captured/party Pals. If `false` then only wild pals are randomized.

### `leader_pal_scale_offset`

**Default:** `0.2`

Wild pal groups all have an invisible leader. This mod makes them unique by giving them a unique skill and making them the largest within that group using the `max` value for the size range you provide in pal scales below.

The scales of all other pals in the group are always this value less than the `max` value which is reserved for the leader.

Example:

```lua
M = {
    min = 0.6,
    max = 1.4
}
leader_pal_scale_offset = 0.2
```

A normal non-leader Medium Pal can roll approximately `0.6 .. 1.2`, while its leader is set to `1.4`.

### `display_size_widget`

Controls whether or not a widget to display the current scale/size of the pal is shown on the Pal details menu. The widget shows the current scale in % so `1.6` would show as `160%`. The widget also displays the max size the pal can grow to.
For rideable pals restricted by size, it also displays the minimum scale the pal needs to be eligible for riding.

### `normal_pal_scales`

This table defines the `min`/`max` size range for normal wild pals of each size category.

Current defaults:

```lua
normal_pal_scales = {

    XS = { min = 0.8, max = 1.3 },
    S  = { min = 0.7, max = 1.4 },
    M  = { min = 0.6, max = 1.4 },
    L  = { min = 0.6, max = 1.15 },
    XL = { min = 0.6, max = 0.85 }
}
```

These are **absolute final scale values**. `1.0` is the vanilla native scale for an ordinary Pal. Note that you can set `max` value less than `1.0` to effectively reduce the size of all pals that lie within a category. The opposite is also possible

### `boss_pal_scales`

This table defines the `min`/`max` size range for Alpha/Boss pals of each size category. A good range can be gotten by doubling your `max` value for the normal scales above and use it as the mid point here. This works well for small to medium sized categories.

```lua
boss_pal_scales = {

    enabled = true,

    XS = { min = 2.0, max = 2.8 },
    S  = { min = 2.2, max = 3.0 },
    M  = { min = 2.2, max = 3.0 },
    L  = { min = 1.6, max = 2.0 },
    XL = { min = 1.6, max = 2.0 }
}
```

#### `boss_pal_scales.enabled`

When `false`, size randomization is skipped for boss Pals and they are left to their vanilla size.

Vanilla Boss size vary a lot. Gumoss is set to 4.0 natively while other pals like daedream are a measly 1.5.

### `rare_pal_scales`

This table defines the `min`/`max` size range for Rare/Lucky pals of each size category.

Current defaults intentionally mirror `normal_pal_scales`. Vanilla uses the boss size for lucky/rare pals.

#### `rare_pal_scales.enabled`

When `false`, size randomization is skipped for Lucky/Rare Pals.

---

# Color variety

### `color_variety`

This table contains all settings regarding the body-color variation.

#### `color_variety.enable_color_variation`

Master toggle for Pal color variation. When disabled, color variation is not applied.

#### `color_variety.apply_color_to_leaders`

Controls whether wild leader Pals receive the color-variety treatment.

#### `color_variety.apply_color_to_bosses`

Controls whether boss Pals can receive color variation. Rare pals are not counted as bosses.

#### `color_variety.saturation_min` / `color_variety.saturation_max`

Saturation values used for the Pal material’s `Saturation` parameter.

Vanilla value is `0.0` for the pals I checked. Saturation increases with negative values and decreases with positive. A sane range is between `-1.0 - 0.2`. These are absolute values used directly as the saturation for the pal’s material.

#### `color_variety.value_offset_min` / `color_variety.value_offset_max`

Brightness/Value offset added the Pal material’s `Value` parameter.

Vanilla value is `1.2` or `1.8` for the pals I checked. Negative values darken; positive values brighten.These values are not absolute values but offsets to the native `value` parameter for pal’s material. Sane offsets are `-0.4 - 0.3`. You can tinker further.

#### `color_variety.color_variation_chance`

The chance that an eligible Pal receives color variation. Use a value from `0.0` to `1.0` where `1.0` is `100%`.

#### `color_variety.colors`

Defines the available colors and their relative selection weights.

Example:

```lua
colors = {
    { id = "red",   r = 1.00, g = 0.18, b = 0.13, weight = 30 },

    { id = "green", r = 0.50, g = 0.75, b = 0.45, weight = 30 },

    { id = "blue",  r = 0.145, g = 0.45, b = 0.92, weight = 30 },
}
```

Each entry contains:

- `id` — stable unique string used as part of deterministic color selection. Changing an ID can reroll which Pals select that color.

- `r`, `g`, `b` — RGB components, normally in the `0.0 .. 1.0` range.

- `weight` — relative likelihood of this color being selected.

Weights **do not need to add up to `1`, `100`, or any other specific total**. Only their relative values matter. Although using weights taht sum up to 1 or 100 is intuitive and easy to understand the relative chances of each color.

For example, weights of `30, 30, 30, 10` behave like 30%, 30%, 30%, 10%. The same relative result would be produced by `3, 3, 3, 1`.

A weight of `0` disables that color from selection. Keep at least one color above `0` if color variation is enabled.

The array is loose: colors may be added or removed as desired. 

I recommend adding around `2-3` key colors. Then add their shades, for e.g 2 shades of red, 2 shades of blue, etc. This helps make pals look natural and not an artwork by a 3 year old. Unless ofcourse, you want to burn your eyes :)

Unfortunately, I couldn't find a way to read source color programmatically. Or else we could have targeted shades for based on the source color.

#### `color_variety.color_lerp_factor_min` / `color_variety.color_lerp_factor_max`

Controls how strongly the selected replacement color is blended into the Pal’s original body material.

Lower values preserve more of the original color. Higher values push the material more strongly toward the selected palette color.

Good values are around `0 - 0.4`. `0` means the original color is preserved. Note that a value of `1` would paint the whole Pal model with a uniform color selected above making the model look washed out. It’s recommended to use a value of 0.4 or below.

---

# Rideability

### `rideability`

Controls size/trust restrictions for rideable Pals and optional automatic granting of ride gear. If both size and trust restrictions are enabled, failing either requirement prevents riding.

#### `rideability.restricted_by_size`

Prevents a rideable Pal from being mounted while its current scale is below the configured threshold in [`rideability.min_ride_scales`](#rideability.min_ride_scales).

The Pal menu and partner-skill UI display the restriction when applicable.

#### `rideability.restricted_by_trust`

Prevents a rideable Pal from being mounted until it reaches [`rideability.min_trust_level`](#rideability.min_trust_level).

#### `rideability.min_trust_level`

Minimum friendship/trust rank required for riding when [`rideability.restricted_by_trust`](#rideability.restricted_by_trust) is enabled.

#### `rideability.size_eligiblity_by_trust_progression`

Controls how quickly a growing captured Pal reaches its minimum rideable size. This is a fraction of total trust progression from level `1 to 10` given as `0.0` to `1.0`. For example:

```lua
size_eligiblity_by_trust_progression = 0.4

```

means a Pal that starts below its rideable-size threshold will have its growth curve adjusted so it reaches that threshold at roughly 40% of total trust progression or in this case, trust level 4.

This is not a hard limit. Pals that are a small fraction below their eligible size for riding need not wait till this progression. They can reach it earlier than that.

This only matters when [`trust.pals_grow_with_trust`](#trust.pals_grow_with_trust) is enabled.

**Related:** [`rideability.min_ride_scales`](#rideability.min_ride_scales), [`trust.pals_grow_with_trust`](#trust.pals_grow_with_trust)

#### `rideability.grant_saddles`

Automatically grants ordinary saddle related riding items to players when the world loads.

This is useful when size/trust restrictions are intended to replace normal saddle progression. If Palworld’s built-in randomizer is enabled and already grants the relevant partner-skill items, the mod skips this grant step.

#### `rideability.grant_saddle_weapons`

Automatically grants ride-related items that aren’t saddle but actual weapons. Examples are grizzbolt’s minigun and XYZ pal’s hammer.

#### `rideability.min_ride_scales`

Defines the minimum scale required to ride a Pal in each size category.

```lua
min_ride_scales = {

    XS = 1.0,
    S  = 0.9,
    M  = 0.8,
    L  = 0.8,
    XL = 0.55,
}
```

These values are absolute scales. The size display widget in Pal Details also shows the minimum ride scale needed when size-based ride restrictions are enabled.

---

# Trust and growth

### `trust`

Controls Pal growth through friendship/trust and optional changes to friendship gain/loss rates.

#### `trust.pals_grow_with_trust`

Determines whether Pals can grow in size based on friendship/trust.

When enabled, a captured pal grows from its deterministic starting size toward the `max` value of its configured size range as friendship increases.

**Related:** [`normal_pal_scales`](#normal_pal_scales), [`rideability.size_eligiblity_by_trust_progression`](#rideability.size_eligiblity_by_trust_progression)

#### `trust.basepals_grow`

Determines whether Base Pals can grow as well based on friendship/trust.

Base Pals are checked approximately once per minute for their trust rank and applying size. Since vanilla has no way for base pals to gain trust, this mod provides it’s own settings to change that. See below

#### `trust.modify_trust_gains`

Master toggle for the mod’s custom trust gain/loss settings.

It’s recommended to turn it on if you want base pals to grow or gain work suitability with trust ranks as vanilla palworld doesn’t give trust to base pals. Technically it does but at a very very reduced rate.

#### `trust.pal_trust_petting`

Raw friendship points awarded when you pet a pal

#### `trust.basepal_trust_working`

Friendship points awarded to a healthy Base Pal per minute if it is found in a `working` state. This trust gain stops once the Pal reaches [`trust.basepal_trust_gains_maxlvl`](#trust.basepal_trust_gains_maxlvl). Vanilla value is passive 1 per minute which is non-existant

#### `trust.basepal_trust_unhealthy`

Friendship modifier applied during the base trust update for unhealthy conditions.

The modifier is applied independently for each detected condition:

- Sanity below 60

- Hungry or Starving

- The Pal is sick.

Because these checks stack, a Pal suffering from multiple conditions can receive this penalty multiple times during the same update. For example, with `-20`, three unhealthy conditions can produce `-60` for that update.

If a Pal is found unhealthy, [trust.basepal_trust_working](#trust.basepal_trust_working) is skipped even if that Pal is working. Note that unhealthy Pals can still lose trust even after reaching [`basepal_trust_gains_maxlvl`](#trust.basepal_trust_gains_maxlvl).

#### `trust.partypal_trust_passive`

Passive friendship gain per minute for a Pal in the player’s party. Vanilla value is 100 per minute.

#### `trust.partypal_trust_active`

**Default:** `150`

Friendship gain per minute for the currently active/summoned party Pal. Vanilla value is 100 per minute.

#### `trust.activepal_trust_on_death`

**Default:** `-400`

Friendship points added when the player’s Otomo/Party Pal is defeated. This is a custom feature not present in vanilla.

Use a negative number to make defeat reduce trust. Use `0` to disable the loss while keeping other custom trust settings enabled.

#### `trust.activepal_trust_on_kill`

**Default:** `200`

Friendship points awarded when a Otomo Pal gets the killing blow on a wild Pal. This is a custom feature not present in vanilla.

Use `0` to disable this reward while keeping other trust modifications enabled.

#### `trust.basepal_trust_gains_maxlvl`

**Default:** `6`

Maximum friendship rank till Base Pals can continue gaining the mod’s positive `basepal_trust_working` reward.

Once the Pal’s friendship rank is equal to or above this value, work no longer grants additional custom trust.

Unhealthy penalties can still reduce trust above this level.

---

# Work suitability

### `work_suitability`

Controls gender-based work-suitability differences and permanent work-suitability progression for Base Pals on trust rank-ups.

Only work categories a Pal already possesses are increased. A Pal with `0` suitability in a category does not gain that category from these settings.

#### `work_suitability.basepals_gain_worksuit`

Allows Base Pals to gain work-suitability rank when reaching new trust ranks. The gain is permanent individual Pal data and is capped by the game’s maximum work-suitability rank. This can’t be undone.

When [`work_suitability.gender_based_gains`](#work_suitability.gender_based_gains) is enabled, only categories assigned to that Pal’s gender are eligible for these trust-based gains. 

This setting only truly works if you also enable [`trust.modify_trust_gains`](#trust.modify_trust_gains) combined with [`trust.basepal_trust_working`](#trust.basepal_trust_working). 

> Note: Party pals don't gain work suitability due to trust level ups. This setting only affects base pals. If you deploy a trust level 6 party pal to the base it won't magically gain all the ranks it missed gaining.

#### `work_suitability.gender_based_gains`

Controls whether **trust-rank work-suitability gains** are filtered through the configured male/female category lists.

When `true`, a male Base Pal only gains ranks in categories listed under [`work_suitability.male`](#work_suitability.male), and a female Base Pal only gains ranks in categories listed under [`work_suitability.female`](#work_suitability.female).

When `false`, trust rank-ups may improve any work-suitability category the Pal already has. This setting is only for base pals.

#### `work_suitability.wildpal_gender_bonus`

Work-suitability rank bonus applied to wild Pals according to the male/female category lists.

The bonus only applies to work categories the Pal already has and respects the game’s maximum work-suitability rank.

Set this to `0` to disable the initial wild gender-based work-suitability bonus. If a modified wild Pal is captured, this individual bonus persists with that Pal.

#### `work_suitability.male`

**Default:**

```lua
male = {
    "EmitFlame",
    "GenerateElectricity",
    "Deforest",
    "Mining",
    "OilExtraction",
}
```

List of work-suitability enum names associated with male Pals for the mod’s gender-based systems.

The array is loose; entries may be added or removed. Names must match valid Palworld work-suitability names. For a complete list of all work suitability names, check [here](https://github.com/gallickgunner/Palworld-Mods/blob/main/worksuitability-names.json).

To make a category eligible for both genders, add the same name to both arrays.

#### `work_suitability.female`

**Default:**

```lua
female = {
    "Watering",
    "Seeding",
    "Handcraft",
    "Collection",
    "ProductMedicine",
}
```

Female counterpart to [`work_suitability.male`](#work_suitability.male).

---

# Stat variety

### `stats`

Controls individual stat variation generated for wild Pals.

The male, female, and leader profiles use the same structure:

```lua

profile = {

    talent_bonus = {

        enabled = true,

        atk = { min = ..., max = ... },
        def = { min = ..., max = ... },
        hp  = { min = ..., max = ... },

    },

    rank_bonus = {

        enabled = true,

        atk        = { min = ..., max = ... },
        def        = { min = ..., max = ... },
        hp         = { min = ..., max = ... },
        work_speed = { min = ..., max = ... },

    },

    workspeed_bonus = ...,

}

```

> These values are rolled randomly between min/max and overwrite vanilla value.

Talent should range from `0 - 100` as that is the game's native cap. You can set it to more than `100` but I don't think it's gonna effect anything. Hardcap is `255` as it's a `byte` variable.

Ranks are souls you feed to the pals via the statue of power. I haven't put a cap on this in my mod but native values are between `0-20` so stay within that range. Reason for not putting a cap is to support future changes if Palworld decides to update the limit.

#### `stats.gender_bonus`

Enable/Disable the male/female stat profiles for ordinary wild Pals.

When enabled, wild Pals receive either [`stats.male`](#stats.male) or [`stats.female`](#stats.female) according to their gender. By default, males are set to have better ATK while females have better DEF and workspeed.

#### `stats.leader_bonus`

**Default:** `true`

Enable/Disable applying the dedicated [`stats.leader`](#statsleader) profile for wild leader Pals.

Wild leaders are forced male by the leader system. If `leader_bonus` is disabled while `gender_bonus` remains enabled, leaders use the normal male stat profile instead of the leader profile.

#### `stats.male`

Stat-generation profile for ordinary male wild Pals.

#### `stats.female`

Stat-generation profile for ordinary female wild Pals.

#### `stats.leader`

Stat-generation profile for wild leader Pals when [`stats.leader_bonus`](#stats.leader_bonus) is enabled.


#### `stats.<profile>.talent_bonus.enabled`

Enables custom Talent/IV value for the selected profile.

#### `stats.<profile>.talent_bonus.atk`

Inclusive random range used for `Talent_Shot`, which affects the Pal’s ATK stat. Recommended values should remain within Palworld’s intended Talent range, normally `0 .. 100`.

#### `stats.<profile>.talent_bonus.def`

Inclusive random range used for `Talent_Defense` which affects Pal's DEF stat. Recommended range: `0 .. 100`.

#### `stats.<profile>.talent_bonus.hp`

Inclusive random range used for `Talent_HP` which affects Pal's HP stat. Recommended range: `0 .. 100`.

#### `stats.<profile>.rank_bonus.enabled`

Enable/Disable applying custom Rank value to ATK, DEF, HP and WorkSpeed. Ranks are souls you feed via the statue of power. Enabling this allows wild pals to appear with whatever number of souls you set here. As far as I know, each rank/soul increases that particular stat by 3 or 6%. 

Native cap is 20 so stay within that range.

#### `stats.<profile>.rank_bonus.atk`

Inclusive random range used for giving souls/ranks to ATK stat

#### `stats.<profile>.rank_bonus.def`

Inclusive random range used for giving souls/ranks to DEF stat

#### `stats.<profile>.rank_bonus.hp`

Inclusive random range used for giving souls/ranks to HP stat

#### `stats.<profile>.rank_bonus.work_speed`

Inclusive random range used for giving souls/ranks to Workspeed stat

#### `stats.<profile>.workspeed_bonus`

Percentage bonus applied directly to the Pal’s workspeed stat.

Examples:

```text
0   = no direct CraftSpeed bonus

25  = +25%

100 = +100%, or double CraftSpeed
```

This is separate from `rank_bonus.work_speed`, so both may affect the same Pal if both are configured. It's recommended to use only one setting when giving bonuses to workspeed, either via tha rank or directly using this setting.

---

# Difficulty

### `difficulty`

This part is kinda just cherry on the top. Controls several Palworld difficulty settings plus optional per-category damage multipliers for wild Pals.

#### `difficulty.partypal_damage_taken`

Sets Palworld’s `OtomoDamageRate_Defense` value. This affects damage received by player companion/Otomo Pals. Higher values make party Pals take more damage; lower values make them more durable.

Native value was `0.75` which means Party pals were taking 75% damage for some reason. 

#### `difficulty.weakpoint_damage_rate`

Sets Palworld’s damage rate when a weakness is struck. Native value was `1.5`

#### `difficulty.strongpoint_damage_rate`

Sets Palworld’s damage rate when you use a skill on a Pal that it is strong against or resists. Native value was `0.5`

#### `difficulty.default_atk_skip_timeout`

Sets Palworld’s native `CommonAttackSkipTimeoutSeconds` game setting. I haven't tested this much but still gave an option for users to try out. Apparently this is an AI default attack-selection timing setting measured in seconds. Lower values should allow the relevant AI attack-selection logic to retry sooner instead of waiting long.

Native value was `5` seconds. Note this is for the default attack (the attack when all active skills are on cooldown)

#### `difficulty.skill_reselect_timeout`

Sets Palworld’s native `WazaReselectTimeoutSeconds` game setting. This is the same as above but for active skills. Native value was `5` seconds.

#### `difficulty.enable_damage_multiplier`

Enables the mod’s custom damage multipliers for wild normal Pals, wild leader pals, and bosses. 

The six `damage_rate_to_*` / `damage_rate_from_*` values below are applied only when this feature is enabled. 

This is done by abusing Palworld's native setting for `Damage to/from Pals` and `Damage to/from Player` found in the world setting. Palworld uses those settings for ALL pals apparently (party/wild/boss etc). The feature works by hooking where the damage calculation takes place, and setting the native settings to custom values based on if the wild pal is a boss/leader/normal and whether or not it's the attacker or getting attacked.

For all the `damage_rate_to_*` knobs present below, it doesn't matter what is the source of damage. Likewise for `damage_rate_from_*` knobs, it doesn't matter who the target of their attack is. For wild-Pal-vs-wild-Pal combat, an outgoing multiplier from the attacker and an incoming multiplier from the defender can both participate in the same damage calculation. 

All multiplier values are set in percentages where `1.0` means `100%`. When using these multipliers, it's recommended to set the Pal/Player Damage rates in the world settings to `1.0`.

>**Multiplayer note:** the reflected damage hook used for these per-Pal multipliers has been observed to work in Single Player and listen/Co-op hosting, but not on a dedicated server. The native difficulty settings above are separate from this custom hook.

#### `difficulty.damage_rate_to_boss`

Multiplier applied when a wild boss is the damage target.

#### `difficulty.damage_rate_to_leader`

Multiplier applied when a wild leader is the damage target.

#### `difficulty.damage_rate_to_normal`

Multiplier applied when an ordinary wild Pal is the damage target.

#### `difficulty.damage_rate_from_boss`

Multiplier applied when a wild boss is the attacker. Higher values make bosses deal more damage.

#### `difficulty.damage_rate_from_leader`

Multiplier applied when a wild leader is the attacker.

#### `difficulty.damage_rate_from_normal`

Multiplier applied when an ordinary wild Pal is the attacker.

---

# Wild Pal spawning

### `pals_spawn_disordered`

This changes the initial spatial arrangement of supported wild groups. 

When you increase the number of pals per group using the Randomizer mod, you'll often see pals bunch up and spawn in an arc. I think this is how the native code spawns wild pals.

Enabling this setting makes wild squad/group pals spawn in randomly scattered positions around their leader instead of remaining tightly ordered in an arc at their initial locations.

You can disable this if you don't play with more than 4/5 pal per group.

### `solo_spawn_leader_chance`

Some pals spawn solo and not in groups. Although you can change this with the Randomizer mod, not everybody will have the resources to run it. This setting allows you to control how likely it is for solo spawning wild pals to have the leader skill.

This is a percentage value between `0-1`. Setting it to `0.0` means solo spawns will never have the leader trait. Setting it to `1.0` will make solo spawns always have the leader skill.

---

# Maintenance and debugging

### `uninstall_mode`

Starts the mod in cleanup mode instead of normal gameplay mode. 

Current cleanup only removes the mod’s custom leader passive skill from locations such as the party, Palbox, and loaded Base Camps.

Typical use:

1. Set `uninstall_mode = true`.

2. Start/load the world and allow cleanup to run.

3. Save the game.

4. Exit the game.

5. Remove or disable the mod.

> **Important:** This is not a complete rollback of every persistent individual change the mod may have made. Generated Talent values, stat ranks, CraftSpeed, gender based changes, work-suitability bonuses, and friendship/trust changes may already be part of the Pal’s saved data and are not automatically reconstructable to their original values.

### `enable_hot_reload`

Enable/disable hot reload feature. Currently only the size and color variation are supported by hot reload feature.

Hot reload is useful while tuning visual settings such as size and color. You can change set size ranges to a single absolute value to determine what that number actually means visually. You can also tinker around with colors/saturation easily.

It's not recommended to use hot reload in MP as this will throw everybody out of sync. This feature is only provided to help tinker with the size and color values to get a visual understanding of the numbers involved. You should turn it off after you've decided your settings and not use it afterwards specifically on Multiplayer modes.

### `hot_reload_key`

UE4SS key name used to reload the config when [`enable_hot_reload`](#enable_hot_reload) is enabled.

Example:

```lua
hot_reload_key = "HOME"
```

Use a valid UE4SS `Key` name. If an invalid key is configured, the mod falls back to its built-in default key. Check [here](https://docs.ue4ss.com/lua-api/table-definitions/key.html) for all valid keys: 

### `debug_logging`

Enables verbose mod logging in the UE4SS log.

Keep this enabled when sharing logs and diagnosing crashes or other problems. Disable it for normal play as logging has an overhead as well.
