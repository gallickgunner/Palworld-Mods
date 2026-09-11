-- CONFIG
--
-- size_variation values are ADDITIVE offsets from the Pal's native value for
-- DefaultScale3D/RelativeScale3D. Both are always 1.0 for normal Pals excluding Alphas/Bosses etc
-- which this mod doesn't handle in the first place.
--
-- Alpha/Boss, Raid Boss, Tower Boss and Predator Boss Pals are excluded.
-- Lucky/Rare Pals are intentionally allowed to vary. Luckies have varying values for their native scale as they are bigger sized. Max i saw was 4.0 for gumoss and some other Pals.
--
-- Example:
--	XS = { min = 0.0, max = 0.5 }
--  native 1.0 -> final 1.0 .. 1.5
--
--	XL = { min = -0.5, max = 0.0 }
--	native 4.0 -> final 3.5 .. 4.0
--
--	XL = { min = -0.5, max = -0.2 }
--  native 1.0 -> final 0.5 .. 0.8     -- Note This method of setting values can be used to scale up/down pals of a specific category while also providing variation
--
--	XL = { min = -0.3, max = -0.3 }
--  native 1.0 -> final 0.7 .. 0.7     -- Note This method can be used to disable variation for a specific category. Use 1.0 for vanilla sizes.
--
-- In any case, just make sure that "min" <= "max". Both can be negative or positive.
---@class DefaultModConfig
local DefaultModConfig = {

	normal_pal_scales = {
		XS = {
			min = 0.8,
			max = 1.3
		},
		S = {
			min = 0.7,
			max = 1.4
		},
		M = {
			min = 0.6,
			max = 1.4
		},
		L = {
			min = 0.6,
			max = 1.15
		},
		XL = {
			min = 0.6,
			max = 0.85
		}
	},

	-- Boss pal native scales are not 1.0. They vary, for e.g Daedream Alpha has 1.5 while Gumoss has 4.0. A value of 2.0 here means double the size of normal vanilla pals.
	-- A good range can be gotten by doubling your max value above and use it as the mid point for this range.
	boss_pal_scales = {
		enabled = true,
		XS = {
			min = 2.0,
			max = 2.8
		},
		S = {
			min = 2.2,
			max = 3.0
		},
		M = {
			min = 2.2,
			max = 3.0
		},
		L = {
			min = 1.6,
			max = 2.0
		},
		XL = {
			min = 1.6,
			max = 2.0
		}
	},

	-- I like lucky pals to be the same size as normal so I copied the normal pal values.
	rare_pal_scales = {
		enabled = true,
		XS = {
			min = 0.8,
			max = 1.3
		},
		S = {
			min = 0.7,
			max = 1.4
		},
		M = {
			min = 0.6,
			max = 1.4
		},
		L = {
			min = 0.6,
			max = 1.15
		},
		XL = {
			min = 0.6,
			max = 0.85
		}
	},

	-- If you want to ride tiny pals for the comedic factor, set this to false
	disable_tiny_ride_pals = true,

	-- All scale values below should be greater than zero. 1.0 is considered the default native scale. So add your min and max to 1.0 to get the range
	-- of scales for that pal. Then decide the cutoff point for disabling rides. All values below have been set after testing 5-10 mounts of each category	
	min_ride_scales = {
		XS = 1.0,
		S = 0.9,
		M = 0.8,
		-- 0.7 can also work but they stop feeling like mounts and some specific mounts like Grizzbolt feel off
		L = 0.8,
		-- for xl pals 0.5 works and even 0.4 might work, but they stop feeling like actual mounts and look more like babies.
		XL = 0.55,
	},

	-- enabling this will grant all saddle items required for most rideable pals except ones that have specific weapons as requirement (miniguns, hammer, etc)
	grant_saddles = false,
	-- enable this to grant the weapon for all rideable pals as well
	grant_saddle_weapons = false,


	--enable hot reload feature
	enable_hot_reload = false,

	--Hot reload key. Check this for all default keys you can use: https://docs.ue4ss.com/lua-api/table-definitions/key.html
	hot_reload_key = "HOME",

	-- turn this on when you are facing crashes and send ue4ss logs
	debug_logging = false,
}

return DefaultModConfig
