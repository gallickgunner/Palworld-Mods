# Localization Reference

This file documents every option in `Config/localization.lua`.

The localization file contains the text shown when a Pal's riding is restricted either by size or trust. It contains entries for each language that all has the structure below

```
en = {
		pal_menu_size_restr_text = {
			"I don't trust you with my tiny back yet.",
			"My back is tiny, unlike your expectations, Tamer.",
			"Have you considered walking? I highly recommend it.",
			"Please allow several levels for spinal reinforcement.",
			"Can I grow up in peace?"
		},
		pal_menu_trust_restr_text = {
			"I don't trust you with my back yet.",
			"Have you considered walking? I highly recommend it.",
			"You think I'll be that easy to break? Nope.",
			"I'll think about it if we become friends..."
		},
		pal_overlay_size_restr_text = {
			"This pal is still too young. More trust progress is required for it to grow.",
		},
		pal_overlay_trust_restr_text = {
			"You need to build some trust with this pal first. Come back around level %s.",
		},
	},
```

### pal_menu_size_restr_text

This text is show on the main Pal menu and on the Pal details menu when the pal is restricted by size.

### pal_menu_trust_restr_text

This text is show on the main Pal menu and on the Pal details menu when the pal is restricted by trust.

### pal_overlay_size_restr_text

This text is show on the pal partner skill overlay shown when you hover over the locked partner skill in the Pal details menu. This is for when Pals are restricted by size.

### pal_overlay_trust_restr_text

This text is show on the pal partner skill overlay shown when you hover over the locked partner skill in the Pal details menu. This is for when Pals are restricted by trust.