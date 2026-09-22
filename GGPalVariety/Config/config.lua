return {
	randomize_seed_size = "default",
	randomize_seed_color = "default_color",
	randomize_captured_pals = true,

	leader_pal_scale_offset = 0.2,
	display_size_widget = true,
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

	color_variety = {
		enable_color_variation = true,
		apply_color_to_leaders = false,
		apply_color_to_bosses = false,

		saturation_min = -0.7,
		saturation_max = 0.1,

		value_offset_min = -0.3,
		value_offset_max = 0.1,

		color_variation_chance = 0.8,

		colors = {
			{ id = "red",    r = 1.00,  g = 0.18,  b = 0.13, weight = 30 }, -- red
			{ id = "green",  r = 0.50,  g = 0.750, b = 0.45, weight = 30 }, -- green
			{ id = "blue",   r = 0.145, g = 0.45,  b = 0.92, weight = 30 }, -- blue
			{ id = "orange", r = 1.00,  g = 0.55,  b = 0.10, weight = 10 }, -- orange
			--{ id = "yellow",  r = 0.95,  g = 0.90,  b = 0.15, weight = 0 }, -- yellow			
			--{ id = "cyan",    r = 0.15,  g = 0.85,  b = 0.85, weight = 0 }, -- cyan			
			--{ id = "violet",  r = 0.55,  g = 0.20,  b = 1.00, weight = 0 }, -- violet
			--{ id = "magenta", r = 0.95,  g = 0.20,  b = 0.75, weight = 0 }, -- magenta
		},

		color_lerp_factor_min = 0.1,
		color_lerp_factor_max = 0.2,
	},

	rideability = {
		restricted_by_size = true,
		restricted_by_trust = true,
		min_trust_level = 3,
		size_eligiblity_by_trust_progression = 0.4,

		grant_saddles = false,
		grant_saddle_weapons = false,

		min_ride_scales = {
			XS = 1.0,
			S = 0.9,
			M = 0.8,
			L = 0.8,
			XL = 0.55,
		},

	},

	trust = {
		pals_grow_with_trust = true,
		basepals_grow = true,

		modify_trust_gains = true,
		pal_trust_petting = 12000,
		basepal_trust_working = 50,
		basepal_trust_unhealthy = -20,
		partypal_trust_passive = 150,
		partypal_trust_active = 150,
		activepal_trust_on_death = -400,
		activepal_trust_on_kill = 200,

		basepal_trust_gains_maxlvl = 6,
	},

	work_suitability = {
		basepals_gain_worksuit = true,
		gender_based_gains = true,
		wildpal_gender_bonus = 1,

		male = {
			"EmitFlame",
			"GenerateElectricity",
			"Deforest",
			"Mining",
			"OilExtraction",
		},

		female = {
			"Watering",
			"Seeding",
			"Handcraft",
			"Collection",
			"ProductMedicine",
		}
	},

	stats = {
		gender_bonus = true,
		leader_bonus = true,

		male = {
			talent_bonus = {
				enabled = true,
				atk = {
					min = 30,
					max = 100
				},
				def = {
					min = 10,
					max = 70,
				},
				hp = {
					min = 30,
					max = 100
				}
			},

			rank_bonus = {
				enabled = true,
				atk = {
					min = 0,
					max = 3
				},
				def = {
					min = 0,
					max = 0,
				},
				hp = {
					min = 0,
					max = 2
				},
				work_speed = {
					min = 0,
					max = 0,
				}
			},

			workspeed_bonus = 0,
		},

		female = {
			talent_bonus = {
				enabled = true,
				atk = {
					min = 10,
					max = 70
				},
				def = {
					min = 30,
					max = 100,
				},
				hp = {
					min = 30,
					max = 80
				}
			},

			rank_bonus = {
				enabled = true,
				atk = {
					min = 0,
					max = 0
				},
				def = {
					min = 0,
					max = 3,
				},
				hp = {
					min = 0,
					max = 0
				},
				work_speed = {
					min = 0,
					max = 3,
				}
			},

			workspeed_bonus = 100,
		},

		leader = {
			talent_bonus = {
				enabled = true,
				atk = {
					min = 40,
					max = 100
				},
				def = {
					min = 40,
					max = 70,
				},
				hp = {
					min = 40,
					max = 100
				}
			},

			rank_bonus = {
				enabled = true,
				atk = {
					min = 1,
					max = 3
				},
				def = {
					min = 1,
					max = 3,
				},
				hp = {
					min = 1,
					max = 3
				},
				work_speed = {
					min = 0,
					max = 0,
				}
			},

			workspeed_bonus = 0,
		},

	},

	difficulty = {
		partypal_damage_taken = 1.5,
		weakpoint_damage_rate = 1.8,
		strongpoint_damage_rate = 0.35,
		default_atk_skip_timeout = 1,
		skill_reselect_timeout = 1,

		enable_damage_multiplier = true,
		damage_rate_to_boss = 0.4,
		damage_rate_to_leader = 0.6,
		damage_rate_to_normal = 0.8,
		damage_rate_from_boss = 1.6,
		damage_rate_from_leader = 1.4,
		damage_rate_from_normal = 1.2,
	},

	pals_spawn_disordered = true,
	uninstall_mode = false,
	enable_hot_reload = true,
	hot_reload_key = "HOME",
	debug_logging = false,
}
