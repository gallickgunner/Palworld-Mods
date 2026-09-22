---@class ModConfigSchema
local ModConfigSchema = {
	__order = {
		"randomize_seed_size",
		"randomize_seed_color",
		"randomize_captured_pals",
		"leader_pal_scale_offset",
		"display_size_widget",
		"normal_pal_scales",
		"boss_pal_scales",
		"rare_pal_scales",
		"color_variety",
		"rideability",
		"trust",
		"work_suitability",
		"stats",
		"difficulty",
		"pals_spawn_disordered",
		"solo_spawn_leader_chance",
		"uninstall_mode",
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
		},
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
		},
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
		},
	},

	color_variety = {
		__order = {
			"enable_color_variation",
			"apply_color_to_leaders",
			"apply_color_to_bosses",
			"saturation_min",
			"saturation_max",
			"value_offset_min",
			"value_offset_max",
			"color_variation_chance",
			"colors",
			"color_lerp_factor_min",
			"color_lerp_factor_max",
		},

		colors = {
			__loose = true,
		},
	},

	rideability = {
		__order = {
			"restricted_by_size",
			"restricted_by_trust",
			"min_trust_level",
			"size_eligiblity_by_trust_progression",
			"grant_saddles",
			"grant_saddle_weapons",
			"min_ride_scales",
		},

		min_ride_scales = {
			__order = { "XS", "S", "M", "L", "XL" },
		},
	},

	trust = {
		__order = {
			"pals_grow_with_trust",
			"basepals_grow",
			"modify_trust_gains",
			"pal_trust_petting",
			"basepal_trust_working",
			"basepal_trust_unhealthy",
			"partypal_trust_passive",
			"partypal_trust_active",
			"activepal_trust_on_death",
			"activepal_trust_on_kill",
			"basepal_trust_gains_maxlvl",
		},
	},

	work_suitability = {
		__order = {
			"basepals_gain_worksuit",
			"gender_based_gains",
			"wildpal_gender_bonus",
			"male",
			"female",
		},

		male = {
			__loose = true,
		},

		female = {
			__loose = true,
		},
	},

	stats = {
		__order = {
			"gender_bonus",
			"leader_bonus",
			"male",
			"female",
			"leader",
		},

		male = {
			__order = {
				"talent_bonus",
				"rank_bonus",
				"workspeed_bonus",
			},

			talent_bonus = {
				__order = {
					"enabled",
					"atk",
					"def",
					"hp",
				},

				atk = {
					__order = { "min", "max" },
				},

				def = {
					__order = { "min", "max" },
				},

				hp = {
					__order = { "min", "max" },
				},
			},

			rank_bonus = {
				__order = {
					"enabled",
					"atk",
					"def",
					"hp",
					"work_speed",
				},

				atk = {
					__order = { "min", "max" },
				},

				def = {
					__order = { "min", "max" },
				},

				hp = {
					__order = { "min", "max" },
				},

				work_speed = {
					__order = { "min", "max" },
				},
			},
		},

		female = {
			__order = {
				"talent_bonus",
				"rank_bonus",
				"workspeed_bonus",
			},

			talent_bonus = {
				__order = {
					"enabled",
					"atk",
					"def",
					"hp",
				},

				atk = {
					__order = { "min", "max" },
				},

				def = {
					__order = { "min", "max" },
				},

				hp = {
					__order = { "min", "max" },
				},
			},

			rank_bonus = {
				__order = {
					"enabled",
					"atk",
					"def",
					"hp",
					"work_speed",
				},

				atk = {
					__order = { "min", "max" },
				},

				def = {
					__order = { "min", "max" },
				},

				hp = {
					__order = { "min", "max" },
				},

				work_speed = {
					__order = { "min", "max" },
				},
			},
		},

		leader = {
			__order = {
				"talent_bonus",
				"rank_bonus",
				"workspeed_bonus",
			},

			talent_bonus = {
				__order = {
					"enabled",
					"atk",
					"def",
					"hp",
				},

				atk = {
					__order = { "min", "max" },
				},

				def = {
					__order = { "min", "max" },
				},

				hp = {
					__order = { "min", "max" },
				},
			},

			rank_bonus = {
				__order = {
					"enabled",
					"atk",
					"def",
					"hp",
					"work_speed",
				},

				atk = {
					__order = { "min", "max" },
				},

				def = {
					__order = { "min", "max" },
				},

				hp = {
					__order = { "min", "max" },
				},

				work_speed = {
					__order = { "min", "max" },
				},
			},
		},
	},

	difficulty = {
		__order = {
			"partypal_damage_taken",
			"weakpoint_damage_rate",
			"strongpoint_damage_rate",
			"default_atk_skip_timeout",
			"skill_reselect_timeout",
			"enable_damage_multiplier",
			"damage_rate_to_boss",
			"damage_rate_to_leader",
			"damage_rate_to_normal",
			"damage_rate_from_boss",
			"damage_rate_from_leader",
			"damage_rate_from_normal",
		},
	},
}

return ModConfigSchema
