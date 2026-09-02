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
return {
	min_ride_scale_s = 0.9,
	disable_tiny_ride_pals = true,
	size_variation = {
		XS = {
			min = -0.2,
			max = 0.3,
		},
		S = {
			min = -0.3,
			max = 0.4,
		},
		M = {
			min = -0.4,
			max = 0.4,
		},
		XL = {
			min = -0.4,
			max = -0.15,
		},
		L = {
			min = -0.4,
			max = 0.15,
		},
	},
	min_ride_scale_l = 0.8,
	hot_reload_key = "HOME",
	debug_logging = true,
	enable_hot_reload = false,
	min_ride_scale_m = 0.8,
	min_ride_scale_xl = 0.55,
	disable_saddle_requirement = true,
	minimum_scale = 0.1,
}
