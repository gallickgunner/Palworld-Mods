-- PalFollowerTweaks
--
-- Values are Unreal centimeters:
--   Forward: positive = in front, negative = behind
--   Right:   positive = right,    negative = left
--
-- Palworld has five Funnel formation slots. It selects one based on
-- GetIndexOfFunnelsWithinSameTrainer() and wraps after five.
--
-- Press F4 for hot reload.
return {		
		-- Vanilla defaults are [300, 150, 0, -150, 300]
    Forward = {
        -600,
        -450,
        -450,
        -450,
        -600
    },
		
		-- Vanilla defaults are [-100, -150, -200, -150, -100]
    Right = {
        -500,
        -300,
        0,
        300,
        500
    },
		
		--number of elements in the forward and right list. NO NEED TO CHANGE THIS NOW.
		--This is given for forward compatiblity incase Palworld officially increases party slots and formation slots.
		NUM_ELEMENTS = 5,
		
		-- scale of the following pals, 1.0 = 100%
		Scale = 0.6
}
