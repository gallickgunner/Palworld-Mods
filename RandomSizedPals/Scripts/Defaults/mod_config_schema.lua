---@class ModConfigSchema
local ModConfigSchema = {
	__order = {
		"normal_pal_scales",
		"boss_pal_scales",
		"rare_pal_scales",
		"min_ride_scales",
		"grant_saddles",
		"grant_saddle_weapons",
		"enable_hot_reload",
		"hot_reload_key",
		"debug_logging",
	},

	normal_pal_scales = {
		__order = { "XS", "S", "M", "L", "XL" },

		XS = {
			__order = { "min", "max" }
		},
		S = {
			__order = { "min", "max" }
		},
		M = {
			__order = { "min", "max" }
		},
		L = {
			__order = { "min", "max" }
		},
		XL = {
			__order = { "min", "max" }
		}
	},

	boss_pal_scales = {
		__order = { "enabled", "XS", "S", "M", "L", "XL" },

		XS = {
			__order = { "min", "max" }
		},
		S = {
			__order = { "min", "max" }
		},
		M = {
			__order = { "min", "max" }
		},
		L = {
			__order = { "min", "max" }
		},
		XL = {
			__order = { "min", "max" }
		}
	},

	rare_pal_scales = {
		__order = { "enabled", "XS", "S", "M", "L", "XL" },

		XS = {
			__order = { "min", "max" }
		},
		S = {
			__order = { "min", "max" }
		},
		M = {
			__order = { "min", "max" }
		},
		L = {
			__order = { "min", "max" }
		},
		XL = {
			__order = { "min", "max" }
		}
	},

	min_ride_scales = {
		__order = { "XS", "S", "M", "L", "XL" }
	},
}

return ModConfigSchema
