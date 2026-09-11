---@class LeaderStateManager
local LeaderStateManager = {}
local CDO = require("Utils.cdo")
local PalUtils = require("Utils.pal_utils")
local CoreUtils = require("Utils.core_utils")
local Unrealutils = require("Utils.unreal_utils")

local IsValid = Unrealutils.IsValid
local DebugLog = CoreUtils.DebugLog

local leader_pals = {
	--[[
	pal_instance_id_str = PalIndividualId
	--]]
}

local client_temp_leader_ids = {
	-- instance_id = true
}

function LeaderStateManager.Init()

end

function LeaderStateManager.ResetState()
	leader_pals = {}
end

function LeaderStateManager.GetLeader(instance_id)
	local indiv_id = leader_pals[instance_id]

	if not indiv_id or not CDO.pal_utility:IsValidInstanceID(indiv_id) then
		return nil
	end

	return indiv_id
end

function LeaderStateManager.IsLeader(instance_id)
	local indiv_id = leader_pals[instance_id]
	local is_temp_client_leader = client_temp_leader_ids[instance_id] or false

	if not indiv_id and not is_temp_client_leader then
		return false, false
	end

	return true, is_temp_client_leader
end

function LeaderStateManager.AddLeader(indiv_id)
	local instance_id_str = PalUtils.GetPalInstanceIdFromIndivId(indiv_id)
	if instance_id_str then
		leader_pals[instance_id_str] = indiv_id
	end
end

function LeaderStateManager.AddTempLeaderInClient(instance_id)
	if instance_id then
		client_temp_leader_ids[instance_id] = true
	end
end

function LeaderStateManager.RemoveLeader(instance_id)
	leader_pals[instance_id] = nil
end

function LeaderStateManager.RemoveTempLeaderInClient(instance_id)
	if instance_id then
		client_temp_leader_ids[instance_id] = nil
	end
end

return LeaderStateManager
