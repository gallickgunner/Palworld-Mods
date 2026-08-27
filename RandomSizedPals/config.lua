-- CONFIG FILE
--
-- size_variation values are ADDITIVE offsets from the Pal's native value for
-- DefaultScale3D.
--
-- Example:
--   XS = { min = 0.0, max = 0.5 }
--   native 1.0 -> final 1.0 .. 1.5
--
--   XL = { min = -0.5, max = 0.0 }
--   native 4.0 -> final 3.5 .. 4.0
--
-- These offsets can also be used to downscale Pals belonging to a specific category by setting max < 0.
-- For e.g, setting XL = { min = -0.5, max = -0.2} will scale all Pals in XL category
-- such that they fall in the range 0.5 - 0.8 as the default scale for normal non-boss pals is 1.0.
--
-- Likewise, you can also use the opposite setting to upscale native Pals by setting min > 0
-- You can also set min = max. So values like min = max = -0.2 would make all Pals of that category
-- without any size variation but just smaller.
--
-- In any case, just make sure that "min" <= "max". Both can be negative or positive.
--
-- Alpha/Boss, Raid Boss, Tower Boss and Predator Boss Pals are excluded.
-- Lucky/Rare Pals are intentionally allowed to vary.
return {
	size_variation = {
		XS = {
			min = -0.15,
			max = 0.35
		},
		S = {
			min = -0.2,
			max = 0.4
		},
		M = {
			min = -0.5,
			max = 0.4
		},
		L = {
			min = -0.5,
			max = -0.15
		},
		XL = {
			min = -0.5,
			max = -0.2
		}
	},
	minimum_scale = 0.1,
	debug_logging = false
}
