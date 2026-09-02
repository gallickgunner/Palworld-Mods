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

	size_variation = {
		XS = {
			min = -0.2,
			max = 0.3
		},
		S = {
			min = -0.3,
			max = 0.4
		},
		M = {
			min = -0.4,
			max = 0.4
		},
		L = {
			min = -0.4,
			max = 0.15
		},
		XL = {
			min = -0.4,
			max = -0.15
		}
	},

	-- Should be greater than zero
	minimum_scale = 0.1,

	disable_tiny_ride_pals = true,

	-- All scale values below should be greater than zero. 1.0 is considered the default native scale. So add your min and max to 1.0 to get the range
	-- of scales for that pal. Then decide the cutoff point for disabling rides. All values below have been set after testing 5-10 mounts of each category	
	min_ride_scale_s = 0.9,

	min_ride_scale_m = 0.8,

	-- 0.7 can also work but they stop feeling like mounts and some specific mounts like Grizzbolt feel off
	min_ride_scale_l = 0.8,

	-- for xl pals 0.5 works and even 0.4 might work, but they stop feeling like actual mounts and look more like babies.
	min_ride_scale_xl = 0.55,

	-- enabling this will disable saddle requirements entirely for all rideable pals.
	disable_saddle_requirement = false,

	--enable hot reload feature
	enable_hot_reload = false,

	--Hot reload key. Check this for all default keys you can use: https://docs.ue4ss.com/lua-api/table-definitions/key.html
	hot_reload_key = "HOME",

	-- turn this on when you are facing crashes and send ue4ss logs
	debug_logging = false
}

return DefaultModConfig
