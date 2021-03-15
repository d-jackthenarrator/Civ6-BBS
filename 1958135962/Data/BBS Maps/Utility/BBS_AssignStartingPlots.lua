------------------------------------------------------------------------------
--	FILE:	BBS_AssignStartingPlot.lua    -- 1.6.0
--	AUTHOR:  D. / Jack The Narrator, Kilua
--	PURPOSE: Custom Spawn Placement Script
------------------------------------------------------------------------------
--	Copyright (c) 2014 Firaxis Games, Inc. All rights reserved.
------------------------------------------------------------------------------
include( "MapEnums" );
include( "MapUtilities" );
include( "FeatureGenerator" );
include( "TerrainGenerator" );
include( "NaturalWonderGenerator" );
include( "ResourceGenerator" );
include ( "AssignStartingPlots" );

local bError_major = false;
local bError_minor = false;
local bError_proximity = false;
local bError_shit_settle = false;
local bRepeatPlacement = false;
local b_debug_region = false
local b_north_biased = false
local Teamers_Config = 0
local Teamers_Ref_team = nil
local g_negative_bias = {}
local g_custom_bias = {}

------------------------------------------------------------------------------
BBS_AssignStartingPlots = {};


------------------------------------------------------------------------------
function __Debug(...)
    --print (...);
end

------------------------------------------------------------------------------
function BBS_AssignStartingPlots.Create(args)
	if (GameConfiguration.GetValue("SpawnRecalculation") == nil) then
		__Debug("BBS_AssignStartingPlots:",GameConfiguration.GetValue("SpawnRecalculation"))
		Game:SetProperty("BBS_RESPAWN",false)
		return AssignStartingPlots.Create(args)
	end
	__Debug("BBS_AssignStartingPlots: BBS Settings:", GameConfiguration.GetValue("SpawnRecalculation"));
	if (GameConfiguration.GetValue("SpawnRecalculation") == false) then 
		__Debug("BBS_AssignStartingPlots:",GameConfiguration.GetValue("SpawnRecalculation"))
		Game:SetProperty("BBS_RESPAWN",false)
		return AssignStartingPlots.Create(args)
	end
	
	if MapConfiguration.GetValue("BBS_Team_Spawn") ~= nil then
		Teamers_Config = MapConfiguration.GetValue("BBS_Team_Spawn")
	end
	
	g_negative_bias = {}
	
	local info_query = "SELECT * from StartBiasNegatives";
	local info_results = DB.Query(info_query);
	for k , v in pairs(info_results) do
		local tmp = { CivilizationType = v.CivilizationType, TerrainType = v.TerrainType, FeatureType = v.FeatureType, Tier = v.Tier, Extra = v.Extra}
		if tmp.CivilizationType ~= nil then
			table.insert(g_negative_bias, tmp)
		end
	end
	g_custom_bias = {}
	
	local info_query = "SELECT * from StartBiasCustom";
	local info_results = DB.Query(info_query);
	for k , v in pairs(info_results) do
		local tmp = { CivilizationType = v.CivilizationType, CustomPlacement = v.CustomPlacement}
		__Debug("g_custom_bias",v.CivilizationType,v.CustomPlacement)
		if tmp.CivilizationType ~= nil then
			table.insert(g_custom_bias, tmp)
		end
	end

	local Major_Distance_Target = 19
	local instance = {}
	--if MapConfiguration.GetValue("MAP_SCRIPT") == "Pangaea.lua" then
	--	Major_Distance_Target = 20
	--end	
	if MapConfiguration.GetValue("MAP_SCRIPT") == "Terra.lua" then
		Major_Distance_Target = 17
	end
	if Teamers_Config == 0 then
		Major_Distance_Target = Major_Distance_Target - 3 
	end
	
	if Map.GetMapSize() == 5 and  PlayerManager.GetAliveMajorsCount() > 10 then
		Major_Distance_Target = Major_Distance_Target - 2
	end
	if Map.GetMapSize() == 5 and  PlayerManager.GetAliveMajorsCount() < 8 then
		Major_Distance_Target = Major_Distance_Target + 2
	end	
	
	if Map.GetMapSize() == 4 and  PlayerManager.GetAliveMajorsCount() > 10 then
		Major_Distance_Target = Major_Distance_Target - 2
	end
	if Map.GetMapSize() == 4 and  PlayerManager.GetAliveMajorsCount() < 8 then
		Major_Distance_Target = Major_Distance_Target + 2
	end	
	
	if Map.GetMapSize() == 3 and  PlayerManager.GetAliveMajorsCount() > 7 then
		Major_Distance_Target = Major_Distance_Target - 3
	end
	if Map.GetMapSize() == 3 and  PlayerManager.GetAliveMajorsCount() < 8 then
		Major_Distance_Target = Major_Distance_Target 
	end	
	
	if Map.GetMapSize() == 2 and  PlayerManager.GetAliveMajorsCount() > 5 then
		Major_Distance_Target = Major_Distance_Target - 4
	end
	if Map.GetMapSize() == 2 and  PlayerManager.GetAliveMajorsCount() < 6 then
		Major_Distance_Target = Major_Distance_Target - 2
	end	
	
	if Map.GetMapSize() == 1 and  PlayerManager.GetAliveMajorsCount() > 5 then
		Major_Distance_Target = Major_Distance_Target - 5
	end
	if Map.GetMapSize() == 1 and  PlayerManager.GetAliveMajorsCount() < 6 then
		Major_Distance_Target = Major_Distance_Target - 3
	end	
	
	if Map.GetMapSize() == 0 and  PlayerManager.GetAliveMajorsCount() > 2  then
		Major_Distance_Target = 15
	end	
	
	if Map.GetMapSize() == 0 and  PlayerManager.GetAliveMajorsCount() == 2  then
		Major_Distance_Target = 18
	end	
	
	
	for i = 1,12 do
		instance = {}
		bError_shit_settle = false
		bError_major = false;
		bError_proximity = false;
		bError_minor = false;
		print("Attempt #",i,"Distance",Major_Distance_Target)
	instance  = {
        -- Core Process member methods
        __InitStartingData					= BBS_AssignStartingPlots.__InitStartingData,
        __FilterStart                       = BBS_AssignStartingPlots.__FilterStart,
        __SetStartBias                      = BBS_AssignStartingPlots.__SetStartBias,
        __BiasRoutine                       = BBS_AssignStartingPlots.__BiasRoutine,
        __FindBias                          = BBS_AssignStartingPlots.__FindBias,
        __RateBiasPlots                     = BBS_AssignStartingPlots.__RateBiasPlots,
        __SettlePlot                   		= BBS_AssignStartingPlots.__SettlePlot,
        __CountAdjacentTerrainsInRange      = BBS_AssignStartingPlots.__CountAdjacentTerrainsInRange,
        __ScoreAdjacent   					= BBS_AssignStartingPlots.__ScoreAdjacent,
        __CountAdjacentFeaturesInRange      = BBS_AssignStartingPlots.__CountAdjacentFeaturesInRange,
        __CountAdjacentResourcesInRange     = BBS_AssignStartingPlots.__CountAdjacentResourcesInRange,
        __CountAdjacentYieldsInRange        = BBS_AssignStartingPlots.__CountAdjacentYieldsInRange,
        __GetTerrainIndex                   = BBS_AssignStartingPlots.__GetTerrainIndex,
        __GetFeatureIndex                   = BBS_AssignStartingPlots.__GetFeatureIndex,
        __GetResourceIndex                  = BBS_AssignStartingPlots.__GetResourceIndex,
		__LuxuryCount						= BBS_AssignStartingPlots.__LuxuryCount,
        __TryToRemoveBonusResource			= BBS_AssignStartingPlots.__TryToRemoveBonusResource,
		__NaturalWonderBufferCheck			= BBS_AssignStartingPlots.__NaturalWonderBufferCheck,
        __LuxuryBufferCheck					= BBS_AssignStartingPlots.__LuxuryBufferCheck,
        __MajorMajorCivBufferCheck			= BBS_AssignStartingPlots.__MajorMajorCivBufferCheck,
        __MinorMajorCivBufferCheck			= BBS_AssignStartingPlots.__MinorMajorCivBufferCheck,
        __MinorMinorCivBufferCheck			= BBS_AssignStartingPlots.__MinorMinorCivBufferCheck,
        __BaseFertility						= BBS_AssignStartingPlots.__BaseFertility,
        __AddBonusFoodProduction			= BBS_AssignStartingPlots.__AddBonusFoodProduction,
        __AddFood							= BBS_AssignStartingPlots.__AddFood,
        __AddProduction						= BBS_AssignStartingPlots.__AddProduction,
        __AddResourcesBalanced				= BBS_AssignStartingPlots.__AddResourcesBalanced,
        __AddResourcesLegendary				= BBS_AssignStartingPlots.__AddResourcesLegendary,
        __BalancedStrategic					= BBS_AssignStartingPlots.__BalancedStrategic,
        __FindSpecificStrategic				= BBS_AssignStartingPlots.__FindSpecificStrategic,
        __AddStrategic						= BBS_AssignStartingPlots.__AddStrategic,
        __AddLuxury							= BBS_AssignStartingPlots.__AddLuxury,
		__AddLeyLine						= BBS_AssignStartingPlots.__AddLeyLine,
        __AddBonus							= BBS_AssignStartingPlots.__AddBonus,
        __IsContinentalDivide				= BBS_AssignStartingPlots.__IsContinentalDivide,
        __RemoveBonus						= BBS_AssignStartingPlots.__RemoveBonus,
        __TableSize						    = BBS_AssignStartingPlots.__TableSize,
        __GetValidAdjacent					= BBS_AssignStartingPlots.__GetValidAdjacent,
		__GetShuffledCiv					= BBS_AssignStartingPlots.__GetShuffledCiv,
		__CountAdjacentContinentsInRange	= BBS_AssignStartingPlots.__CountAdjacentContinentsInRange,
		__CountAdjacentRiverInRange			= BBS_AssignStartingPlots.__CountAdjacentRiverInRange,

        iNumMajorCivs = 0,
		iNumSpecMajorCivs = 0,
        iNumWaterMajorCivs = 0,
        iNumMinorCivs = 0,
        iNumRegions		= 0,
        iDefaultNumberMajor = 0,
        iDefaultNumberMinor = 0,
		iTeamPlacement = Teamers_Config,
        uiMinMajorCivFertility = args.MIN_MAJOR_CIV_FERTILITY or 0,
        uiMinMinorCivFertility = args.MIN_MINOR_CIV_FERTILITY or 0,
        uiStartMinY = args.START_MIN_Y or 0,
        uiStartMaxY = args.START_MAX_Y or 0,
        uiStartConfig = args.START_CONFIG or 2,
        waterMap  = args.WATER or false,
        landMap  = args.LAND or false,
        noStartBiases = args.IGNORESTARTBIAS or false,
        startAllOnLand = args.STARTALLONLAND or false,
        startLargestLandmassOnly = args.START_LARGEST_LANDMASS_ONLY or false,
        majorStartPlots = {},
		majorStartPlotsTeam = {},
        minorStartPlots = {},
		minorStartPlotsID = {},
        majorList = {},
        minorList = {},
        playerStarts = {},
		regionTracker = {},
        aBonusFood = {},
        aBonusProd = {},
        rBonus = {},
        rLuxury = {},
        rStrategic = {},
        aMajorStartPlotIndices = {},
        fallbackPlots = {},
        tierMax = 0,
		iHard_Major = Major_Distance_Target,
		iDistance = 0,
		iDistance_minor = 0,
		iDistance_minor_minor = 5,
		iMinorAttempts = 0,
        -- Team info variables (not used in the core process, but necessary to many Multiplayer map scripts)
    }

		instance:__InitStartingData()
	
		if bError_major == false and bError_proximity == false and bError_shit_settle == false then
			__Debug("BBS_AssignStartingPlots: Successfully ran!")
			if  (bError_minor == true) then
				__Debug("BBS_AssignStartingPlots: An error has occured: A city-state is missing.")
			end
			Game:SetProperty("BBS_RESPAWN",true)
			return instance
			else
			Major_Distance_Target = Major_Distance_Target - 2
			bRepeatPlacement = true			  
			if Major_Distance_Target < 9 then
				Major_Distance_Target = 9

			end
		end
	end
	
	
	__Debug("BBS_AssignStartingPlots: To Many Attempts Failed - Go to Firaxis Placement")
	Game:SetProperty("BBS_RESPAWN",false)
	return AssignStartingPlots.Create(args)

end

------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__InitStartingData()
   	__Debug("BBS_AssignStartingPlots: Start:", os.date("%c"));
    if(self.uiMinMajorCivFertility <= 0) then
        self.uiMinMajorCivFertility = 110;
    end
    if(self.uiMinMinorCivFertility <= 0) then
        self.uiMinMinorCivFertility = 25;
    end
	local rng = 0
	rng = TerrainBuilder.GetRandomNumber(100,"North Test")/100;
	if rng > 0.5 then
		b_north_biased = true
	end
    --Find Default Number
    local MapSizeTypes = {};
    for row in GameInfo.Maps() do
        MapSizeTypes[row.RowId] = row.DefaultPlayers;
    end
    local sizekey = Map.GetMapSize() + 1;
    local iDefaultNumberPlayers = MapSizeTypes[sizekey] or 8;
    self.iDefaultNumberMajor = iDefaultNumberPlayers ;
    self.iDefaultNumberMinor = math.floor(iDefaultNumberPlayers * 1.5);

    --Init Resources List
    for row in GameInfo.Resources() do
        if (row.ResourceClassType  == "RESOURCECLASS_BONUS") then
            table.insert(self.rBonus, row);
            for row2 in GameInfo.TypeTags() do
                if(GameInfo.Resources[row2.Type] ~= nil and GameInfo.Resources[row2.Type].Hash == row.Hash) then
                    if(row2.Tag=="CLASS_FOOD" and row.Name ~= "LOC_RESOURCE_CRABS_NAME") then
                        table.insert(self.aBonusFood, row);
                    elseif(row2.Tag=="CLASS_PRODUCTION" and row.Name ~= "LOC_RESOURCE_COPPER_NAME") then
                        table.insert(self.aBonusProd, row);
                    end
                end
            end
        elseif (row.ResourceClassType == "RESOURCECLASS_LUXURY") then
            table.insert(self.rLuxury, row);
        elseif (row.ResourceClassType  == "RESOURCECLASS_STRATEGIC") then
            table.insert(self.rStrategic, row);
        end
    end

    for row in GameInfo.StartBiasResources() do
        if(row.Tier > self.tierMax) then
            self.tierMax = row.Tier;
        end
    end
    for row in GameInfo.StartBiasFeatures() do
        if(row.Tier > self.tierMax) then
            self.tierMax = row.Tier;
        end
    end
    for row in GameInfo.StartBiasTerrains() do
        if(row.Tier > self.tierMax) then
            self.tierMax = row.Tier;
        end
    end
    for row in GameInfo.StartBiasRivers() do
        if(row.Tier > self.tierMax) then
            self.tierMax = row.Tier;
        end
    end
	
	if b_debug_region == true then
		for iPlotIndex = 0, Map.GetPlotCount()-1, 1 do
			local pPlot = Map.GetPlotByIndex(iPlotIndex)
			if (pPlot ~= nil) then
				TerrainBuilder.SetFeatureType(pPlot,-1);
			end
		end		
	end

    -- See if there are any civs starting out in the water
    local tempMajorList = {};
    self.majorList = {};
    self.waterMajorList = {};
    self.specMajorList = {};
    self.iNumMajorCivs = 0;
    self.iNumSpecMajorCivs = 0;
    self.iNumWaterMajorCivs = 0;

    tempMajorList = PlayerManager.GetAliveMajorIDs();
	
    
    for i = 1, PlayerManager.GetAliveMajorsCount() do
        local leaderType = PlayerConfigurations[tempMajorList[i]]:GetLeaderTypeName();
        if (not self.startAllOnLand and GameInfo.Leaders_XP2[leaderType] ~= nil and GameInfo.Leaders_XP2[leaderType].OceanStart) then
            table.insert(self.waterMajorList, tempMajorList[i]);
            self.iNumWaterMajorCivs = self.iNumWaterMajorCivs + 1;
            __Debug ("Found the Maori");
        elseif ( PlayerConfigurations[tempMajorList[i]]:GetLeaderTypeName() == "LEADER_SPECTATOR" or PlayerConfigurations[tempMajorList[i]]:GetHandicapTypeID() == 2021024770) then
		table.insert(self.specMajorList, tempMajorList[i]);
		self.iNumSpecMajorCivs = self.iNumSpecMajorCivs + 1;
		__Debug ("Found a Spectator");
	else
            table.insert(self.majorList, tempMajorList[i]);
            self.iNumMajorCivs = self.iNumMajorCivs + 1;
        end
    end

    -- Do we have enough water on this map for the number of water civs specified?
    local TILES_NEEDED_FOR_WATER_START = 8;
    if (self.waterMap) then
        TILES_NEEDED_FOR_WATER_START = 1;
    end
    local iCandidateWaterTiles = StartPositioner.GetTotalOceanStartCandidates(self.waterMap);
    if (iCandidateWaterTiles < (TILES_NEEDED_FOR_WATER_START * self.iNumWaterMajorCivs)) then
        -- Not enough so reset so all civs start on land
        self.iNumMajorCivs = 0;
        self.majorList = {};
        for i = 1, PlayerManager.GetAliveMajorsCount() do
            table.insert(self.majorList, tempMajorList[i]);
            self.iNumMajorCivs = self.iNumMajorCivs + 1;
        end
    end

    self.iNumMinorCivs = PlayerManager.GetAliveMinorsCount();
    self.minorList = PlayerManager.GetAliveMinorIDs();
    self.iNumRegions = self.iNumMajorCivs + self.iNumMinorCivs;

    StartPositioner.DivideMapIntoMajorRegions(self.iNumMajorCivs, self.uiMinMajorCivFertility, self.uiMinMinorCivFertility, self.startLargestLandmassOnly);
    local majorStartPlots = {};
    for i = self.iNumMajorCivs - 1, 0, - 1 do
        local plots = StartPositioner.GetMajorCivStartPlots(i);
		table.insert(majorStartPlots, self:__FilterStart(plots, i, true));
    end

    self.playerStarts = {};
    self.aMajorStartPlotIndices = {};
    self:__SetStartBias(majorStartPlots, self.iNumMajorCivs, self.majorList,true);

    if(self.uiStartConfig == 1 ) then
        self:__AddResourcesBalanced();
    elseif(self.uiStartConfig == 3 ) then
        self:__AddResourcesLegendary();
    end


    StartPositioner.DivideMapIntoMinorRegions(self.iNumMinorCivs);
    local minorStartPlots = {};
    for i = self.iNumMinorCivs - 1, 0, - 1 do
        local plots = StartPositioner.GetMinorCivStartPlots(i);
        table.insert(minorStartPlots, self:__FilterStart(plots, i, false));
    end

    self:__SetStartBias(minorStartPlots, self.iNumMinorCivs, self.minorList,false);

    -- Finally place the ocean civs
    if (self.iNumWaterMajorCivs > 0) then
        local iWaterCivs = StartPositioner.PlaceOceanStartCivs(self.waterMap, self.iNumWaterMajorCivs, self.aMajorStartPlotIndices);
        for i = 1, iWaterCivs do
            local waterPlayer = Players[self.waterMajorList[i]]
            local iStartIndex = StartPositioner.GetOceanStartTile(i - 1);  -- Indices start at 0 here
            local pStartPlot = Map.GetPlotByIndex(iStartIndex);
            waterPlayer:SetStartingPlot(pStartPlot);
            __Debug("Water Start X: ", pStartPlot:GetX(), "Water Start Y: ", pStartPlot:GetY());
        end
        if (iWaterCivs < self.iNumWaterMajorCivs) then
            __Debug("FAILURE PLACING WATER CIVS - Missing civs: " .. tostring(self.iNumWaterMajorCivs - iWaterCivs));
        end
    end

	-- Place the spectator
    if (self.iNumSpecMajorCivs > 0) then
        for i = 1, self.iNumSpecMajorCivs do
            local specPlayer = Players[self.specMajorList[i]]
            local pStartPlot = Map.GetPlotByIndex(0+self.iNumSpecMajorCivs);
            specPlayer:SetStartingPlot(pStartPlot);
            __Debug("Spec Start X: ", pStartPlot:GetX(), "Spec Start Y: ", pStartPlot:GetY());
        end
    end

	-- Sanity check

	for i = 1, PlayerManager.GetAliveMajorsCount() do
		local startPlot = Players[tempMajorList[i]]:GetStartingPlot();
		if (startPlot == nil) then
			bError_major = true
			--__Debug("Error Major Player is missing:", tempMajorList[i]);
			__Debug("Error Major Player is missing:", tempMajorList[i]);
			else
			__Debug("Major Start X: ", startPlot:GetX(), "Major Start Y: ", startPlot:GetY(), "ID:",tempMajorList[i]);
		end
	end

	if (Game:GetProperty("BBS_MINOR_FAILING_TOTAL") == nil) then
		local count = 0
		for i = 1, PlayerManager.GetAliveMinorsCount() do
		
			local startPlot = Players[self.minorList[i]]:GetStartingPlot();
			print(i, count)
			if (startPlot == nil) then
				__Debug("Error Minor Player is missing:", self.minorList[i]);
				count = count + 1
				Game:SetProperty("BBS_MINOR_FAILING_ID_"..count,self.minorList[i])
				startPlot = Map.GetPlotByIndex(PlayerManager.GetAliveMajorsCount()+PlayerManager.GetAliveMinorsCount()+count);
				local minPlayer = Players[self.minorList[i]]
				minPlayer:SetStartingPlot(startPlot);
				__Debug("Minor Temp Start X: ", startPlot:GetX(), "Y: ", startPlot:GetY());
				else
				__Debug("Minor", PlayerConfigurations[self.minorList[i]]:GetCivilizationTypeName(), "Start X: ", startPlot:GetX(), "Y: ", startPlot:GetY());
			end
		end

		Game:SetProperty("BBS_MINOR_FAILING_TOTAL",count)
	end

	__Debug(Game:GetProperty("BBS_MINOR_FAILING_TOTAL"),"Minor Players are missing");

	if (Game:GetProperty("BBS_MINOR_FAILING_TOTAL") > 0) then
		bError_minor = true
		else
		bError_minor = false
	end
	local count = 0
	if Game:GetProperty("BBS_MINOR_FAILING_TOTAL") ~= nil then
		count = Game:GetProperty("BBS_MINOR_FAILING_TOTAL")
	end
	if (bError_major ~= true) then
		for i = 1, PlayerManager.GetAliveMajorsCount() do
			if (PlayerConfigurations[tempMajorList[i]]:GetLeaderTypeName() ~= "LEADER_SPECTATOR" and PlayerConfigurations[tempMajorList[i]]:GetHandicapTypeID() ~= 2021024770 and PlayerConfigurations[tempMajorList[i]]:GetLeaderTypeName() ~= "LEADER_KUPE") then
				local pStartPlot_i = Players[tempMajorList[i]]:GetStartingPlot()
				for j = 1, PlayerManager.GetAliveMajorsCount() do
					if (PlayerConfigurations[tempMajorList[j]]:GetLeaderTypeName() ~= "LEADER_SPECTATOR" and PlayerConfigurations[tempMajorList[j]]:GetHandicapTypeID() ~= 2021024770 and PlayerConfigurations[tempMajorList[j]]:GetLeaderTypeName() ~= "LEADER_KUPE" and tempMajorList[j] ~= tempMajorList[i]) then
						local pStartPlot_j = Players[tempMajorList[j]]:GetStartingPlot()
						if (pStartPlot_j ~= nil) then
							local distance = Map.GetPlotDistance(pStartPlot_i:GetIndex(),pStartPlot_j:GetIndex())
							__Debug("I:", tempMajorList[i],"J:", tempMajorList[j],"Distance:",distance)
							if (distance < 9 ) then
								bError_proximity = true;
								__Debug("Proximity Error:",distance)
							end
						end
					end
				end
				for k = 1, PlayerManager.GetAliveMinorsCount() do
					if (Players[self.minorList[k]] ~= nil ) then
						local pStartPlot_k = Players[self.minorList[k]]:GetStartingPlot()
						if (pStartPlot_k ~= nil) then
							local distance = Map.GetPlotDistance(pStartPlot_i:GetIndex(),pStartPlot_k:GetIndex())
							__Debug("I:", tempMajorList[i],"K:", self.minorList[k],"Distance:",distance)
							if (distance < 6 or pStartPlot_i:GetIndex() == pStartPlot_k:GetIndex()) then
								__Debug("Error Minor Player is missing:", self.minorList[k]);
								count = count + 1
								Game:SetProperty("BBS_MINOR_FAILING_ID_"..count,self.minorList[k])
								startPlot = Map.GetPlotByIndex(PlayerManager.GetAliveMajorsCount()+PlayerManager.GetAliveMinorsCount()+count);
								local minPlayer = Players[self.minorList[k]]
								minPlayer:SetStartingPlot(startPlot);
								__Debug("Minor Temp Start X: ", startPlot:GetX(), "Y: ", startPlot:GetY());
							end
						end
					end					
				end
			end
		end
	end
	Game:SetProperty("BBS_MINOR_FAILING_TOTAL",count)

    __Debug("BBS_AssignStartingPlots: Completed", os.date("%c"));
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__FilterStart(plots, index, major)
    local sortedPlots = {};
    local atLeastOneValidPlot = false;
    for i, row in ipairs(plots) do
        local plot = Map.GetPlotByIndex(row);
        if (plot:IsImpassable() == false and plot:IsWater() == false and self:__GetValidAdjacent(plot, major)) or b_debug_region == true then
            atLeastOneValidPlot = true;
            table.insert(sortedPlots, plot);
        end
    end
    if (atLeastOneValidPlot == true) then
        if (major == true) then
            StartPositioner.MarkMajorRegionUsed(index);
        end
    end
    return sortedPlots;
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__SetStartBias(startPlots, iNumberCiv, playersList, major)
    local civs = {};
	local tierOrder = {};
	self.regionTracker = {};
	local count = 0;
	for i, region in ipairs(startPlots) do
		count = count + 1;
		self.regionTracker[i] = i;
	end
	__Debug("Set Start Bias: Total Region", count);
    for i = 1, iNumberCiv do
        local civ = {};
        civ.Type = PlayerConfigurations[playersList[i]]:GetCivilizationTypeName();

        civ.Index = i;
        local biases = self:__FindBias(civ.Type);
        if (self:__TableSize(biases) > 0) then
            civ.Tier = biases[1].Tier;
        else
            civ.Tier = self.tierMax + 1;
        end
        table.insert(civs, civ);
    end
		
	local shuffledCiv = GetShuffledCopyOfTable(civs);
	
	if bRepeatPlacement == true then
		if self.iHard_Major ~= nil then
			__Debug("Reshuffling Civ Order")
			shuffledCiv = self:__GetShuffledCiv(civs,self.iHard_Major);
			else
			__Debug("Error: Hard Major Limit ")
	  
		end
	end
	
	
    for k, civ in ipairs(shuffledCiv) do
		__Debug("SetStartBias for", k, civ.Type,playersList[civ.Index]);
        self:__BiasRoutine(civ.Type, startPlots, civ.Index, playersList, major);
		__Debug("SetStartBias for", k, civ.Type, "Completed");
    end
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__BiasRoutine(civilizationType, startPlots, index, playersList, major)
    	local biases = self:__FindBias(civilizationType);
    	local ratedBiases = nil;
    	local regionIndex = 0;
    	local settled = false;

    	for i, region in ipairs(startPlots) do
			__Debug("Bias Routine: Analysing Region index", i, "Tracker",self.regionTracker[i]);
			if (self.regionTracker[i] ~= -1) then
       			if (region ~= nil and self:__TableSize(region) > 0) then
            		local tempBiases = self:__RateBiasPlots(biases, region, major, i,civilizationType,playersList[index]);

            		if ( 	(ratedBiases == nil or ratedBiases[1].Score < tempBiases[1].Score) and 
							(tempBiases[1].Score > 0 or major == false or (bRepeatPlacement == true and tempBiases[1].Score > -200) ) ) then
                		ratedBiases = tempBiases;
                		regionIndex = i;
            		end
					else
					regionIndex = i;
					self.regionTracker[regionIndex] = -1;
					__Debug("Bias Routine: Remove Region index: Empty Region", regionIndex);
        		end

			end

		end

    	if (ratedBiases ~= nil and regionIndex > 0) then
        	settled = self:__SettlePlot(ratedBiases, index, Players[playersList[index]], major, regionIndex, civilizationType);


    		if (settled == false) then

        		__Debug("Failed to settled in assigned region, reduce the distance by one and retry.",playersList[index],civilizationType);

				if (major == true) then
					if (self.iDistance_minor == 0) then
						self.iDistance_minor = -1;
						__Debug("BBS_AssignStartingPlots: Reducing Minor Distance by 1");
					end
				
					else

					if (self.iDistance_minor == 0) then
						self.iDistance_minor = -1;
						__Debug("BBS_AssignStartingPlots: Reducing Minor Distance by 1");
					end
					__Debug("BBS_AssignStartingPlots: Minor-Minor Distance Buffer is ",self.iDistance_minor_minor);
					if (self.iDistance_minor_minor > -1) then
						self.iDistance_minor_minor = self.iDistance_minor_minor -1;
						__Debug("BBS_AssignStartingPlots: Reducing Minor-Minor Distance Buffer to ", self.iDistance_minor_minor);
					end
				end

				settled = self:__SettlePlot(ratedBiases, index, Players[playersList[index]], major, regionIndex,civilizationType);

    			if (settled == false) then
        			__Debug("Failed to settled in assigned region, use fallbacks.",Players[playersList[index]],civilizationType);
					if (self:__TableSize(self.fallbackPlots) > 0) then
        				ratedBiases = self:__RateBiasPlots(biases, self.fallbackPlots, major);
        				settled = self:__SettlePlot(ratedBiases, index, Players[playersList[index]], major, -1,civilizationType);
						if (settled == false) then
							__Debug("Failed to place",playersList[index],civilizationType)
						end
						else
						__Debug("Failed to place",Players[playersList[index]],civilizationType)
						return
					end

					else -- Placement successful

					self.regionTracker[regionIndex] = -1;
					__Debug("Bias Routine: Remove Region index: Successful Placement post distance reduction", regionIndex);
				end		
			
				else -- Placement successful

				self.regionTracker[regionIndex] = -1;
				__Debug("Bias Routine: Remove Region index: Successful Placement", regionIndex);

    		end
			
			elseif (major == true) and (self:__TableSize(self.fallbackPlots) > 0) then
			__Debug("Attempt to place using fallback",playersList[index],civilizationType)	
	        ratedBiases = self:__RateBiasPlots(biases, self.fallbackPlots, major);
        	settled = self:__SettlePlot(ratedBiases, index, Players[playersList[index]], major, -1,civilizationType);
				
			if (settled == false) then
				__Debug("Failed to place",playersList[index],civilizationType)
			end	

		end
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__FindBias(civilizationType)
    local biases = {};
    for row in GameInfo.StartBiasResources() do
        if(row.CivilizationType == civilizationType) then
            local bias = {};
            bias.Tier = row.Tier;
            bias.Type = "RESOURCES";
            bias.Value = self:__GetResourceIndex(row.ResourceType);
            __Debug("BBS_AssignStartingPlots: Add Bias : Civilization",civilizationType,"Bias Type:", bias.Type, "Tier :", bias.Tier, "Type :", bias.Value);
            table.insert(biases, bias);
        end
    end
    for row in GameInfo.StartBiasFeatures() do
        if(row.CivilizationType == civilizationType) then
            local bias = {};
            bias.Tier = row.Tier;
            bias.Type = "FEATURES";
            bias.Value = self:__GetFeatureIndex(row.FeatureType);
            __Debug("BBS_AssignStartingPlots: Add Bias : Civilization",civilizationType,"Bias Type:", bias.Type, "Tier :", bias.Tier, "Type :", bias.Value);
            table.insert(biases, bias);
        end
    end
    for row in GameInfo.StartBiasTerrains() do
        if(row.CivilizationType == civilizationType) then
            local bias = {};
            bias.Tier = row.Tier;
            bias.Type = "TERRAINS";
            bias.Value = self:__GetTerrainIndex(row.TerrainType);
            __Debug("BBS_AssignStartingPlots: Add Bias : Civilization",civilizationType,"Bias Type:", bias.Type, "Tier :", bias.Tier, "Type :", bias.Value);
            table.insert(biases, bias);
        end
    end
    for row in GameInfo.StartBiasRivers() do
        if(row.CivilizationType == civilizationType) then
            local bias = {};
            bias.Tier = row.Tier;
            bias.Type = "RIVERS";
            bias.Value = nil;
            __Debug("BBS_AssignStartingPlots: Add Bias : Civilization",civilizationType,"Bias Type:", bias.Type, "Tier :", bias.Tier, "Type :", bias.Value);
            table.insert(biases, bias);
        end
    end
	for _, row in ipairs(g_negative_bias) do
        if(row.CivilizationType == civilizationType) then
            local bias = {};
			if row.TerrainType ~= nil then
				bias.Value = self:__GetTerrainIndex(row.TerrainType);
				bias.Type = "NEGATIVE_TERRAINS";
				bias.Tier = row.Tier;
				__Debug("BBS_AssignStartingPlots: Add Bias : Civilization",civilizationType,"Bias Type:", bias.Type, "Tier :", bias.Tier, "Type :", bias.Value);
				table.insert(biases, bias);
				elseif row.FeatureType ~= nil then
				bias.Value = self:__GetFeatureIndex(row.FeatureType);
				bias.Type = "NEGATIVE_FEATURES";
				bias.Tier = row.Tier;
				__Debug("BBS_AssignStartingPlots: Add Bias : Civilization",civilizationType,"Bias Type:", bias.Type, "Tier :", bias.Tier, "Type :", bias.Value);
				table.insert(biases, bias);
				elseif row.ResourceType ~= nil then
				bias.Value = self:__GetResourceIndex(row.ResourceType);
				bias.Type = "NEGATIVE_RESOURCES";
				bias.Tier = row.Tier;
				__Debug("BBS_AssignStartingPlots: Add Bias : Civilization",civilizationType,"Bias Type:", bias.Type, "Tier :", bias.Tier, "Type :", bias.Value);
				table.insert(biases, bias);
			end	
        end
    end
	for _, row in ipairs(g_custom_bias) do
        if(row.CivilizationType == civilizationType) then
            local bias = {};
			if row.CustomPlacement ~= nil then
				bias.Type = row.CustomPlacement;
				bias.Tier = 1;
				bias.Value = -1;
				__Debug("BBS_AssignStartingPlots: Add Bias : Civilization",civilizationType,"Bias Type:", bias.Type, "Tier :", bias.Tier, "Type :", bias.Value);
				__Debug("BBS_AssignStartingPlots: Add Bias : Civilization",civilizationType,"Bias Type:", bias.Type, "Tier :", bias.Tier, "Type :", bias.Value);
				table.insert(biases, bias);				
			end			
        end
    end
    table.sort(biases, function(a, b) return a.Tier < b.Tier; end);
    return biases;
end


function BBS_AssignStartingPlots:__SettlePlot(ratedBiases, index, player, major, regionIndex, civilizationType)
    local settled = false;
	if (regionIndex == -1) then
		__Debug("BBS_AssignStartingPlots: Attempt to place a Player using the Fallback plots.");
		else
		__Debug("BBS_AssignStartingPlots: Attempt to place a Player using region ", regionIndex)
	end

    for j, ratedBias in ipairs(ratedBiases) do
        if (not settled) then
            --__Debug("Rated Bias Plot:", ratedBias.Plot:GetX(), ":", ratedBias.Plot:GetY(), "Score :", ratedBias.Score);
            if (major) then
                self.playerStarts[index] = {};
                if (self:__MajorMajorCivBufferCheck(ratedBias.Plot,player:GetTeam())) then
                    __Debug("Settled plot :", ratedBias.Plot:GetX(), ":", ratedBias.Plot:GetY(), "Score :", ratedBias.Score, "Player:",player:GetID(),"Region:",regionIndex);
					print("Settled Score :", ratedBias.Score, "Player:",player:GetID(),"Region:",regionIndex)
					if ratedBias.Score < - 500 then
						bError_shit_settle = true
					end
                    settled = true;
                    table.insert(self.playerStarts[index], ratedBias.Plot);
                    table.insert(self.majorStartPlots, ratedBias.Plot);
					table.insert(self.majorStartPlotsTeam, player:GetTeam());
                    table.insert(self.aMajorStartPlotIndices, ratedBias.Plot:GetIndex());
                    self:__TryToRemoveBonusResource(ratedBias.Plot);
                    player:SetStartingPlot(ratedBias.Plot);
					self:__AddLeyLine(ratedBias.Plot); 
					-- Tundra Sharing
					if ratedBias.Plot:GetTerrainType() > 8 and major == true then
						__Debug("BBS Placement: Flip the North Switch",b_north_biased,"to",not b_north_biased);
						b_north_biased = not b_north_biased
					end
                else
                    __Debug("Bias plot :", ratedBias.Plot:GetX(), ":", ratedBias.Plot:GetY(), "score :", ratedBias.Score, "Region :", regionIndex, "too near other Civ");
                end
            else
                self.playerStarts[index + self.iNumMajorCivs] = {};
                if ( self:__MinorMajorCivBufferCheck(ratedBias.Plot) and self:__MinorMinorCivBufferCheck(ratedBias.Plot,player:GetID()) ) then
                    __Debug("Settled plot :", ratedBias.Plot:GetX(), ":", ratedBias.Plot:GetY(), "Score :", ratedBias.Score, "Player:",player:GetID(),"Region:",regionIndex);
                    settled = true;
                    table.insert(self.playerStarts[index + self.iNumMajorCivs], ratedBias.Plot);
                    table.insert(self.minorStartPlots, ratedBias.Plot)
					local tmp = {}
					tmp = {ID = player:GetID(), Plot = ratedBias.Plot}
					table.insert(self.minorStartPlotsID, tmp)
                    player:SetStartingPlot(ratedBias.Plot);

                else
                    __Debug("Bias plot :", ratedBias.Plot:GetX(), ":", ratedBias.Plot:GetY(), "score :", ratedBias.Score, "Region :", regionIndex, "too near other Civ");
                end
            end
            if (regionIndex == -1 and settled) then
                table.remove(self.fallbackPlots, ratedBias.Index)
            end
        elseif (regionIndex ~= -1) then
            table.insert(self.fallbackPlots, ratedBias.Plot);
        end
    end

    return settled;

end

------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__RateBiasPlots(biases, startPlots, major, region_index, civilizationType,iPlayer)
    local ratedPlots = {};
	local region_bonus = 0
	local gridWidth, gridHeight = Map.GetGridSize();

	
    for i, plot in ipairs(startPlots) do
        local ratedPlot = {};
        local foundBiasDesert = false;
        local foundBiasToundra = false;
		local foundBiasNordic = false;
		local foundBiasFloodPlains = false;
		local foundBiasCoast = false;
		local bskip = false
        ratedPlot.Plot = plot;
        ratedPlot.Score = 0 + region_bonus;
        ratedPlot.Index = i;
		----------------------
		-- Shortcut let's not waste checking if they player would be too close anyway...
		----------------------
		if (major == true) then
			if Players[iPlayer] ~= nil then
				if self:__MajorMajorCivBufferCheck(plot,Players[iPlayer]:GetTeam()) == false then
					ratedPlot.Score = ratedPlot.Score - 2000;
					bskip = true
				end
			end	
		end
		
		if 	bskip == false then
		
        if (biases ~= nil) then
            for j, bias in ipairs(biases) do
                __Debug("Rate Plot:", plot:GetX(), ":", plot:GetY(), "For Bias :", bias.Type, "value :", bias.Value,"Civ",civilizationType, "Base", ratedPlot.Score);
				
				-- Positive Biases
                if (bias.Type == "TERRAINS") then
					if bias.Value == g_TERRAIN_TYPE_COAST then
						foundBiasCoast = true;
						if self:__CountAdjacentTerrainsInRange(ratedPlot.Plot, bias.Value, major) > 0 then
							if bias.Tier < 3 then
								ratedPlot.Score = ratedPlot.Score + 400;
								else
								ratedPlot.Score = ratedPlot.Score + 250;
							end	
							__Debug("Terrain+ Coast:", ratedPlot.Score,bias.Value,bias.Tier);
						end
						else
						ratedPlot.Score = ratedPlot.Score + self:__ScoreAdjacent(self:__CountAdjacentTerrainsInRange(ratedPlot.Plot, bias.Value, major), bias.Tier,bias.Type);
						__Debug("Terrain+ Non Coast:", ratedPlot.Score,bias.Value);
					end
                    if (bias.Value == g_TERRAIN_TYPE_DESERT) then
                        foundBiasDesert = true;
                    end
                    if (bias.Value == g_TERRAIN_TYPE_TUNDRA or bias.Value == g_TERRAIN_TYPE_SNOW) then
                        foundBiasToundra = true;
                    end
                elseif (bias.Type == "FEATURES") then
                    ratedPlot.Score = ratedPlot.Score + self:__ScoreAdjacent(self:__CountAdjacentFeaturesInRange(ratedPlot.Plot, bias.Value, major), bias.Tier,bias.Type);
					__Debug("Terrain+ Feature:", ratedPlot.Score,bias.Value);
					if (bias.Value == g_FEATURE_FLOODPLAINS or bias.Value == g_FEATURE_FLOODPLAINS_PLAINS or bias.Value == g_FEATURE_FLOODPLAINS_GRASSLAND) then
                        foundBiasFloodPlains = true;
                    end
                elseif (bias.Type == "RIVERS") then
					local number_river_tiles = 0
					if ratedPlot.Plot:IsRiver() == true then
						ratedPlot.Score = ratedPlot.Score + 100;
						number_river_tiles = self:__CountAdjacentRiverInRange(ratedPlot.Plot,major)
						if number_river_tiles ~= nil then
							ratedPlot.Score = ratedPlot.Score + math.min(tonumber(number_river_tiles) * 50,500);
						end
						else
						ratedPlot.Score = ratedPlot.Score - 150;
					end
					__Debug("Terrain+ River:", ratedPlot.Score,number_river_tiles);
                elseif (bias.Type == "RIVERS" and ratedPlot.Plot:IsRiver()) then
                    ratedPlot.Score = ratedPlot.Score + 100 + self:__ScoreAdjacent(1, bias.Tier);
					__Debug("Terrain+ River:", ratedPlot.Score,bias.Value);
                elseif (bias.Type == "RESOURCES") then
					local tmp = self:__ScoreAdjacent(self:__CountAdjacentResourcesInRange(ratedPlot.Plot, bias.Value, major, 1), bias.Tier,bias.Type)
					local tmp_2 = self:__ScoreAdjacent(self:__CountAdjacentResourcesInRange(ratedPlot.Plot, bias.Value, major, 2), bias.Tier,bias.Type)
					if tmp ~= nil then
						ratedPlot.Score = ratedPlot.Score + tmp;
					end
					if tmp_2 ~= nil then
						ratedPlot.Score = ratedPlot.Score + tmp_2 * 0.5;
					end
					__Debug("Resources+:", ratedPlot.Score,bias.Value);
					
				-- Negative Biases are optionnal and act as repellents 	
				elseif (bias.Type == "NEGATIVE_TERRAINS") then
					ratedPlot.Score = ratedPlot.Score - self:__ScoreAdjacent(self:__CountAdjacentTerrainsInRange(ratedPlot.Plot, bias.Value, major,false,17), bias.Tier,bias.Type);
					__Debug("Terrain-:", ratedPlot.Score,bias.Value);
				elseif (bias.Type == "NEGATIVE_FEATURES") then
					ratedPlot.Score = ratedPlot.Score - self:__ScoreAdjacent(self:__CountAdjacentFeaturesInRange(ratedPlot.Plot, bias.Value, major), bias.Tier,bias.Type);
					__Debug("Feature-:", ratedPlot.Score,bias.Value);
				elseif (bias.Type == "NEGATIVE_RESOURCES") then
					local tmp = self:__ScoreAdjacent(self:__CountAdjacentResourcesInRange(ratedPlot.Plot, bias.Value, major, 1), bias.Tier,bias.Type)
					local tmp_2 = self:__ScoreAdjacent(self:__CountAdjacentResourcesInRange(ratedPlot.Plot, bias.Value, major, 2), bias.Tier,bias.Type)
					if tmp ~= nil then
						ratedPlot.Score = ratedPlot.Score - tmp ;
					end
					if tmp_2 ~= nil then
						ratedPlot.Score = ratedPlot.Score - tmp_2 * 0.5;
					end	
					__Debug("Resource-:", ratedPlot.Score,bias.Value);
					
				-- Custom Biases 				
				elseif (bias.Type == "CUSTOM_NO_FRESH_WATER") then
					if plot:IsFreshWater() == false then
						ratedPlot.Score = ratedPlot.Score + 500;
					end	
					__Debug("Custom No Fresh Water", ratedPlot.Score);
				elseif (bias.Type == "CUSTOM_CONTINENT_SPLIT") then
					local continent = self:__CountAdjacentContinentsInRange(ratedPlot.Plot, major)
					if continent ~= nil and continent > 1 then
						ratedPlot.Score = ratedPlot.Score + 250
					end
					__Debug("Custom Continent Split", ratedPlot.Score,continent);
				elseif (bias.Type == "CUSTOM_NO_LUXURY_LIMIT") then
					local luxcount =  self:__LuxuryCount(ratedPlot.Plot)
					if luxcount > 1 then
						ratedPlot.Score = ratedPlot.Score + 100 * luxcount	
					end
					__Debug("Custom no lux limit", ratedPlot.Score);
				elseif (bias.Type == "CUSTOM_MOUNTAIN_LOVER") then
					local impassable = 0
					for direction = 0, 5, 1 do
						local adjacentPlot = Map.GetAdjacentPlot(ratedPlot.Plot:GetX(), ratedPlot.Plot:GetY(), direction);
						if (adjacentPlot ~= nil) then
							if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
							-- Checks to see if the plot is impassable
								if(adjacentPlot:IsImpassable()) then
									impassable = impassable + 1;
								end
								else
								impassable = impassable + 1;
							end
						end
					end
					if impassable > 2 then
						ratedPlot.Score = ratedPlot.Score + 250 * impassable
					end
					local Mountain_plains = self:__CountAdjacentTerrainsInRange(ratedPlot.Plot, 5, false);
					local Mountain_grass = self:__CountAdjacentTerrainsInRange(ratedPlot.Plot, 2, false);
					if Mountain_plains ~= nil and Mountain_grass ~= nil then
						if (Mountain_plains + Mountain_grass) > 2 and (Mountain_plains + Mountain_grass) < 12 then
							ratedPlot.Score = ratedPlot.Score + 250
							elseif (Mountain_plains + Mountain_grass) < 1 then
							ratedPlot.Score = ratedPlot.Score - 250
						end
						else
						ratedPlot.Score = ratedPlot.Score - 250
					end	
					__Debug("Custom Mountain Lover", ratedPlot.Score,Mountain_plains,Mountain_grass,impassable);
					
				elseif (bias.Type == "CUSTOM_KING_OF_THE_NORTH") then	
					foundBiasNordic = true;
					if MapConfiguration.GetValue("MAP_SCRIPT") ~= "Tilted_Axis.lua"  then
						local max = 17;
						local min = 17;
						if Map.GetMapSize() ~= nil then
							local inc = tonumber(Map.GetMapSize())
							max = max + inc - 2
							min = min + inc - 2
						end	

						if(plot:GetY() <= min or plot:GetY() > gridHeight - max) then
							ratedPlot.Score = ratedPlot.Score + 500;
							elseif(plot:GetY() <= min + 1 or plot:GetY() > gridHeight - max - 1) then 
							ratedPlot.Score = ratedPlot.Score + 200;
							elseif(plot:GetY() <= min + 2 or plot:GetY() > gridHeight - max - 2) then 
							ratedPlot.Score = ratedPlot.Score + 100;
							else
							ratedPlot.Score = ratedPlot.Score - 100;
						end	
						__Debug("Custom King of the North", ratedPlot.Score);
					end
					
					elseif (bias.Type == "CUSTOM_I_AM_SALTY")  then	
						if(plot:IsCoastalLand() == true and plot:IsFreshWater() == false) then
							ratedPlot.Score = ratedPlot.Score + 250;
							__Debug("Custom I am Salty", ratedPlot.Score);
						end
						
					elseif (bias.Type == "CUSTOM_HYDROPHOBIC") and waterMap == false then	
						local close_to_coast = false
						for dx = -3, 3, 1 do
							for dy = -3, 3, 1 do
								local adjacentPlot = Map.GetPlotXYWithRangeCheck(plot:GetX(), plot:GetY(), dx, dy, 3);
								if(adjacentPlot ~= nil and adjacentPlot:IsCoastalLand() == true and adjacentPlot:IsFreshWater() == false) then
									close_to_coast = true
								end
							end
						end
						if close_to_coast == true then
							ratedPlot.Score = ratedPlot.Score - 500;
							__Debug("Custom Hydrophobic", ratedPlot.Score);
						end
					
					
					elseif (foundBiasCoast == true) then	
						local close_to_coast = false
						for dx = -2, 2, 1 do
							for dy = -2, 2, 1 do
								local adjacentPlot = Map.GetPlotXYWithRangeCheck(plot:GetX(), plot:GetY(), dx, dy, 3);
								if( adjacentPlot ~= nil and adjacentPlot:IsCoastalLand() == true and ( (adjacentPlot:IsLake() == false) or (MapConfiguration.GetValue("MAP_SCRIPT") == "Lakes.lua")) ) then
									close_to_coast = true
								end
							end
						end
						if close_to_coast == true then
							ratedPlot.Score = ratedPlot.Score + 1000;
							else
							ratedPlot.Score = ratedPlot.Score - 2500;
						end
						if plot:IsCoastalLand() == true and plot:IsLake() == false and MapConfiguration.GetValue("MAP_SCRIPT") ~= "Lakes.lua" then
							ratedPlot.Score = ratedPlot.Score + 1250;
							elseif plot:IsCoastalLand() == true and plot:IsLake() == true and MapConfiguration.GetValue("MAP_SCRIPT") ~= "Lakes.lua" then
							ratedPlot.Score = ratedPlot.Score - 50;
							elseif plot:IsCoastalLand() == true then
							ratedPlot.Score = ratedPlot.Score + 250;
							else
							ratedPlot.Score = ratedPlot.Score - 1000;
						end
						__Debug("Coastal", ratedPlot.Score);
                end
            end
        end


        if (major) then
			if self.uiStartConfig ~= 3 then
				-- Try to spawn close to 1 luxury
				local luxcount =  self:__LuxuryCount(ratedPlot.Plot)
				if luxcount == 1 then
					ratedPlot.Score = ratedPlot.Score + 50
					elseif luxcount == 2 then
					ratedPlot.Score = ratedPlot.Score - 25
					elseif luxcount > 2 then
					ratedPlot.Score = ratedPlot.Score - 100 * luxcount					
				end	
				__Debug("Lux Check", ratedPlot.Score);	
			end

            if (not foundBiasDesert) then
                local tempDesert = self:__CountAdjacentTerrainsInRange(ratedPlot.Plot, g_TERRAIN_TYPE_DESERT, false);
                local tempDesertHill = self:__CountAdjacentTerrainsInRange(ratedPlot.Plot, g_TERRAIN_TYPE_DESERT_HILLS, false);
                if (tempDesert > 0 or tempDesertHill > 0) then
                    --__Debug("No Desert Bias found, reduce adjacent Desert Terrain for Plot :", ratedPlot.Plot:GetX(), ratedPlot.Plot:GetY());
                    ratedPlot.Score = ratedPlot.Score - (tempDesert + tempDesertHill) * 100;
                end
				__Debug("Desert Check", ratedPlot.Score);	
            end
			if (not foundBiasFloodPlains) then
				if plot:GetFeatureType() == g_FEATURE_FLOODPLAINS or plot:GetFeatureType() == g_FEATURE_FLOODPLAINS_PLAINS or plot:GetFeatureType() == g_FEATURE_FLOODPLAINS_GRASSLAND then
					ratedPlot.Score = ratedPlot.Score - 250;
				end
				__Debug("Flood Check", ratedPlot.Score);	
			end
			

            if (not foundBiasToundra) then
				local tempTundra = self:__CountAdjacentTerrainsInRange(ratedPlot.Plot, g_TERRAIN_TYPE_TUNDRA, false);
				local tempTundraHill = self:__CountAdjacentTerrainsInRange(ratedPlot.Plot, g_TERRAIN_TYPE_TUNDRA_HILLS, false);	
                if (tempTundra > 0 or tempTundraHill > 0) then
                    --__Debug("No Toundra Bias found, reduce adjacent Toundra and Snow Terrain for Plot :", ratedPlot.Plot:GetX(), ratedPlot.Plot:GetY());
                    ratedPlot.Score = ratedPlot.Score - (tempTundra + tempTundraHill) * 100;
                end
				else
				if (ratedPlot.Plot:GetTerrainType() == g_TERRAIN_TYPE_TUNDRA or ratedPlot.Plot:GetTerrainType() == g_TERRAIN_TYPE_TUNDRA_HILLS) then
					ratedPlot.Score = ratedPlot.Score + 250;
					else
					ratedPlot.Score = ratedPlot.Score - 250;
				end
				
				
				if ratedPlot.Plot:GetIndex() > Map.GetPlotCount() / 2 then
							--__Debug("Rate Plot:", plot:GetX(), ":", plot:GetY(), "Polarity Bias b_north_biased",b_north_biased,"We are North");
					if b_north_biased == true then
						ratedPlot.Score = ratedPlot.Score + 500
						else
						ratedPlot.Score = ratedPlot.Score - 500
					end
					else
							--__Debug("Rate Plot:", plot:GetX(), ":", plot:GetY(), "Polarity Bias b_north_biased",b_north_biased,"We are South");
					if b_north_biased == false then
						ratedPlot.Score = ratedPlot.Score + 500
						else
						ratedPlot.Score = ratedPlot.Score - 500
					end
				end
            end

			__Debug("tundra Check", ratedPlot.Score,tempTundra,tempTundraHill,ratedPlot.Plot:GetX(),ratedPlot.Plot:GetY());	
			-- Placement
			if MapConfiguration.GetValue("MAP_SCRIPT") ~= "Tilted_Axis.lua"  then
			    local max = 0;
				local min = 0;
				if Map.GetMapSize() == 4 then
					max = 12 -- math.ceil(0.5*gridHeight * self.uiStartMaxY / 100);
					min = 12 -- math.ceil(0.5*gridHeight * self.uiStartMinY / 100);
					elseif Map.GetMapSize() == 5 then
					max = 14
					min = 14
					elseif Map.GetMapSize() == 3 then
					max = 10
					min = 10	
					else
					max = 8
					min = 8
				end	

				if foundBiasNordic == true then
					max = 6
					min = 6
				end
				
				if(plot:GetY() <= min or plot:GetY() > gridHeight - max) then
					ratedPlot.Score = ratedPlot.Score - 2000
					elseif(plot:GetY() <= min + 1 or plot:GetY() > gridHeight - max - 1) then 
					ratedPlot.Score = ratedPlot.Score - 500
					elseif(plot:GetY() <= min + 2 or plot:GetY() > gridHeight - max - 2) then 
					ratedPlot.Score = ratedPlot.Score - 250
				end	
			end
			

			__Debug("Placement Check", ratedPlot.Score);	
			if self.iTeamPlacement == 1 then
				-- East vs. West
				if Players[iPlayer] ~= nil then
					if Teamers_Ref_team == nil then
						Teamers_Ref_team = Players[iPlayer]:GetTeam()
					end
					if Players[iPlayer]:GetTeam() == Teamers_Ref_team  then
						if plot:GetX() > 2*(gridWidth / 3) then
							ratedPlot.Score = ratedPlot.Score + 500
							elseif plot:GetX() > (gridWidth / 2) then
							ratedPlot.Score = ratedPlot.Score + 250
							elseif plot:GetX() > ((gridWidth / 2) - 3) then
							ratedPlot.Score = ratedPlot.Score + 50
							elseif plot:GetX() > ( (gridWidth / 2) - 5) then
							ratedPlot.Score = ratedPlot.Score + 25
							elseif plot:GetX() > (gridWidth / 3) then
							ratedPlot.Score = ratedPlot.Score
							else
							ratedPlot.Score = ratedPlot.Score - 2000
						end
						else
						if plot:GetX() < gridWidth / 3 then
							ratedPlot.Score = ratedPlot.Score + 500
							elseif plot:GetX() < (gridWidth / 2) then
							ratedPlot.Score = ratedPlot.Score + 250
							elseif plot:GetX() < ((gridWidth / 2) + 3) then
							ratedPlot.Score = ratedPlot.Score + 50
							elseif plot:GetX() < ((gridWidth / 2) + 5) then
							ratedPlot.Score = ratedPlot.Score + 25
							elseif plot:GetX() < (2*(gridWidth / 3) ) then
							ratedPlot.Score = ratedPlot.Score
							else
							ratedPlot.Score = ratedPlot.Score - 2000
						end						
					end
				end	
				
				-- North vs. South
				elseif self.iTeamPlacement == 2 then
				if Players[iPlayer] ~= nil then
					if Teamers_Ref_team == nil then
						Teamers_Ref_team = Players[iPlayer]:GetTeam()
					end
					if Players[iPlayer]:GetTeam() == Teamers_Ref_team then
						if plot:GetY() > 2*gridHeight / 3 then
							ratedPlot.Score = ratedPlot.Score + 500
							elseif plot:GetY() > (gridHeight / 2) then
							ratedPlot.Score = ratedPlot.Score + 250
							elseif plot:GetY() > ((gridHeight / 2) - 3) then
							ratedPlot.Score = ratedPlot.Score + 50
							elseif plot:GetY() > ((gridHeight / 2) - 5) then
							ratedPlot.Score = ratedPlot.Score + 25
							elseif plot:GetY() > (gridHeight / 3) then
							ratedPlot.Score = ratedPlot.Score
							else
							ratedPlot.Score = ratedPlot.Score - 2000
						end
						else
						if plot:GetY() < gridHeight / 3 then
							ratedPlot.Score = ratedPlot.Score + 500
							elseif plot:GetY() < ((gridHeight / 2)) then
							ratedPlot.Score = ratedPlot.Score + 250
							elseif plot:GetY() < ((gridHeight / 2) + 3) then
							ratedPlot.Score = ratedPlot.Score + 50
							elseif plot:GetY() < ((gridHeight / 2) + 5) then
							ratedPlot.Score = ratedPlot.Score + 25
							elseif plot:GetY() < (2*(gridHeight / 3) ) then
							ratedPlot.Score = ratedPlot.Score
							else
							ratedPlot.Score = ratedPlot.Score - 2000
						end						
					end
				end	
				
			end
			
			
		local impassable = 0
		for direction = 0, 5, 1 do
			local adjacentPlot = Map.GetAdjacentPlot(ratedPlot.Plot:GetX(), ratedPlot.Plot:GetY(), direction);
			if (adjacentPlot ~= nil) then
				if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
							-- Checks to see if the plot is impassable
					if(adjacentPlot:IsImpassable()) then
						impassable = impassable + 1;
					end
				else
					impassable = impassable + 1;
				end
			end
		end
		if impassable > 2 then
			ratedPlot.Score = ratedPlot.Score - ( 250 * impassable )
			__Debug("Impassable Check", ratedPlot.Score, impassable);	
		end
	
			
		if Players[iPlayer] ~= nil then
			if self:__MajorMajorCivBufferCheck(plot,Players[iPlayer]:GetTeam()) == false then
				ratedPlot.Score = ratedPlot.Score - 2000;
			end
		end	
			
		if (plot:GetFeatureType() == g_FEATURE_OASIS) then
			ratedPlot.Score = ratedPlot.Score - 250;
		end
        ratedPlot.Score = ratedPlot.Score + self:__CountAdjacentYieldsInRange(plot, major);
		
		if (plot:IsFreshWater() == false and foundBiasCoast == false) then
			ratedPlot.Score = ratedPlot.Score - 500;
		end
		__Debug("Fresh WAter Check", ratedPlot.Score);	
		
		end

		if ratedPlot.Plot:IsRiver() then
			ratedPlot.Score = ratedPlot.Score + 25
		end
		__Debug("River Check", ratedPlot.Score);	

		-- Region check

		if ratedPlot.Score > 0 then
			region_bonus = 0
			local count_water = 0
			local count_22 = 0
			for k = 1, 90 do
				local scanPlot = GetAdjacentTiles(ratedPlot.Plot, k)
				if scanPlot ~= nil then
				
					if scanPlot:IsNaturalWonder() then
						region_bonus = region_bonus + 100
					end

					if (scanPlot:GetTerrainType() == g_TERRAIN_TYPE_TUNDRA or scanPlot:GetTerrainType() == g_TERRAIN_TYPE_TUNDRA_HILLS) then
					
						if foundBiasToundra == true then
						
							region_bonus = region_bonus + 50
							
							else
							
							region_bonus = region_bonus - 50
							
						end
					
					end
					
					if (scanPlot:GetTerrainType() ==  g_TERRAIN_TYPE_DESERT or scanPlot:GetTerrainType() ==  g_TERRAIN_TYPE_DESERT_HILLS) then
					
						if foundBiasDesert == true then
						
							region_bonus = region_bonus + 50
							
							else
							
							region_bonus = region_bonus - 50
							
						end
					
					end
					
					if (scanPlot:IsWater() == true and scanPlot:IsFreshWater() == false and landMap == true) then
						count_water = count_water + 1
						
						if foundBiasCoast == false then
						
							region_bonus = region_bonus - 50
														
						end
										
					end
					
					if ( (scanPlot:GetTerrainType() ==  g_TERRAIN_TYPE_GRASS_HILLS and scanPlot:GetFeatureType() ==  3 ) or (scanPlot:GetTerrainType() ==  g_TERRAIN_TYPE_PLAINS_HILLS and scanPlot:GetFeatureType() ==  2 ) ) then
							
						count_22 = count_22 + 1	
					
					end
					
				end

			end	
			
			if count_22 > 4 then
				region_bonus = region_bonus + 250
				
				elseif foundBiasDesert or foundBiasToundra then
				region_bonus = region_bonus
				elseif count_22 < 2 then
				region_bonus = region_bonus - 250
			end
			
			if count_water > 20 and landMap == true and foundBiasCoast == false then
				region_bonus = region_bonus - 250
				elseif count_water > 45 and landMap == true and foundBiasCoast == true then
				region_bonus = region_bonus - 250
			end
		
		end
		
		ratedPlot.Score = ratedPlot.Score + region_bonus

		ratedPlot.Score = math.floor(ratedPlot.Score);
        __Debug("Plot :", plot:GetX(), ":", plot:GetY(), "Score :", ratedPlot.Score, "North Biased:",b_north_biased, "Type:",plot:GetTerrainType(),"Region",region_bonus);
		if Players[iPlayer] ~= nil then
			__Debug("Plot :", plot:GetX(), ":", plot:GetY(), "Region:",region_index,"Score :", ratedPlot.Score, "Civilization:",civilizationType, "Team",Players[iPlayer]:GetTeam(),"Type:",plot:GetTerrainType());
		end
		
		end
		
		-- Shortcut end
		
		table.insert(ratedPlots, ratedPlot);

    end
    table.sort(ratedPlots, function(a, b) return a.Score > b.Score; end);
    return ratedPlots;
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__GetValidAdjacent(plot, major)
    local impassable = 0;
    local water = 0;
    local desert = 0;
    local snow = 0;
    local toundra = 0;
    local gridWidth, gridHeight = Map.GetGridSize();
    local terrainType = plot:GetTerrainType();

	if (self:__NaturalWonderBufferCheck(plot, major) == false) then
		return false;
	end

	if(plot:IsFreshWater() == false and plot:IsCoastalLand() == false and major == true) then
		return false;
	end


    	local max = 0;
    	local min = 0;
    	if(major == true) then
			if Map.GetMapSize() == 4 then
				max = 7 -- math.ceil(0.5*gridHeight * self.uiStartMaxY / 100);
				min = 7 -- math.ceil(0.5*gridHeight * self.uiStartMinY / 100);
				elseif Map.GetMapSize() == 5 then
				max = 8
				min = 8
				elseif Map.GetMapSize() == 3 then
				max = 6
				min = 6	
				else
				max = 5
				min = 5
			end	
    	end

    	if(plot:GetY() <= min or plot:GetY() > gridHeight - max) then
        	return false;
    	end
		
		if(plot:GetX() <= min or plot:GetX() > gridWidth - max) then
        	return false;
    	end

	if (major == true and plot:IsFreshWater() == false and plot:IsCoastalLand() == false) then
		return false;
	end


    for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
        local adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), direction);
        if (adjacentPlot ~= nil) then
            terrainType = adjacentPlot:GetTerrainType();
            if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
                -- Checks to see if the plot is impassable
                if(adjacentPlot:IsImpassable()) then
                    impassable = impassable + 1;
                end
                -- Checks to see if the plot is water
                if(adjacentPlot:IsWater()) then
                    water = water + 1;
                end
		if(adjacentPlot:GetFeatureType() == g_FEATURE_VOLCANO and major == true) then
			return false
		end 
            else
                impassable = impassable + 1;
            end
        end
    end
	
	if major == true then
		if self:__CountAdjacentResourcesInRange(plot, 27, major) > 0 then
		return false
		end
		if self:__CountAdjacentResourcesInRange(plot, 11, major) > 0 then
		return false
		end
		if self:__CountAdjacentResourcesInRange(plot, 28, major) > 0 then
		return false
	end
	end

    if(impassable >= 4 and not self.waterMap and major == true) then
        return false;
    elseif(impassable >= 4 and not self.waterMap) then
        return false;
    elseif(water + impassable  >= 4 and not self.waterMap and major == true) then
        return false;
    elseif(water >= 3 and major == true) then
        return false;
    elseif(water >= 4 and self.waterMap and major == true) then
        return false;
    else
        return true;
    end
end


------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__AddLeyLine(plot)
	local iResourcesInDB = 0;
	eResourceType	= {};
	eResourceClassType = {};
	aBonus = {};

	for row in GameInfo.Resources() do
		eResourceType[iResourcesInDB] = row.Hash;
		eResourceClassType[iResourcesInDB] = row.ResourceClassType;
	    iResourcesInDB = iResourcesInDB + 1;
	end

	for row = 0, iResourcesInDB do
		if (eResourceClassType[row] == "RESOURCECLASS_LEY_LINE") then
			if(eResourceType[row] ~= nil) then
				table.insert(aBonus, eResourceType[row]);
			end
		end
	end

	local plotX = plot:GetX();
	local plotY = plot:GetY();
	
	aShuffledBonus =  GetShuffledCopyOfTable(aBonus);
	for i, resource in ipairs(aShuffledBonus) do
		for dx = -2, 2, 1 do
			for dy = -2,2, 1 do
				local otherPlot = Map.GetPlotXY(plotX, plotY, dx, dy, 2);
				if(otherPlot) then
					if(ResourceBuilder.CanHaveResource(otherPlot, resource) and otherPlot:GetIndex() ~= plot:GetIndex()) then
						ResourceBuilder.SetResourceType(otherPlot, resource, 1);
						return;
					end
				end
			end
		end 
	end
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__CountAdjacentTerrainsInRange(plot, terrainType, major,watercheck:boolean,index)
    local count = 0;
    local plotX = plot:GetX();
    local plotY = plot:GetY();
	local range = 35
	if index ~= nil then
		range = index
	end
	if (not watercheck) then
		if major == false then
			for dir = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
				local adjacentPlot = Map.GetAdjacentPlot(plotX, plotY, dir);
				if(adjacentPlot ~= nil and adjacentPlot:GetTerrainType() == terrainType) then
                count = count + 1;
				end
			end
			elseif (terrainType == g_TERRAIN_TYPE_COAST) and (major == false or major == true)  then
			-- At least one adjacent coast but that is not a lake and not more than one
			for dir = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
            local adjacentPlot = Map.GetAdjacentPlot(plotX, plotY, dir);
				if(adjacentPlot ~= nil and adjacentPlot:GetTerrainType() == terrainType) then
					if (not adjacentPlot:IsLake() and count < 1) then
                    count = count + 1;
					end
				end
			end
			elseif major == true then
			for i = 1, range do
				local adjacentPlot = GetAdjacentTiles(plot, i)
				if(adjacentPlot ~= nil and adjacentPlot:GetTerrainType() == terrainType) then
                    count = count + 1;
				end
			end
		end
		return count;
		
		else
		
		for i = 1, 35 do
			local adjacentPlot = GetAdjacentTiles(plot, i)
            if(adjacentPlot ~= nil and adjacentPlot:IsWater() == true) then
                count = count + 1;
            end

        end

		return count
	end

end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__ScoreAdjacent(count, tier, bias_type)
    local score = 0;
	if bias_type == nil then
		if count ~= nil and tier ~= nil and tier ~= 0 then
			score = math.min(50 * count ^ (3/tier),500);
		end
		return score;
	end
	if bias_type == "RESOURCES" or bias_type == "NEGATIVE_RESOURCES" then
		if count ~= nil and tier ~= nil and tier ~= 0 then
			score = math.min(50 * count ^ (4/tier),1000);
		end
		return score;
	end
	if bias_type == "FEATURES" or bias_type == "NEGATIVE_FEATURES" then
		if count ~= nil and tier ~= nil and tier ~= 0 then
			score = math.min(50 * count ^ (3/tier),1000);
		end
		return score;
	end
	if bias_type == "TERRAINS" or bias_type == "NEGATIVE_TERRAINS" then
		if count ~= nil and tier ~= nil and tier ~= 0 then
			score = math.min(50 * count ^ (3/tier),1000);
		end
		return score;
	end
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__CountAdjacentFeaturesInRange(plot, featureType, major)
    local count = 0;
    local plotX = plot:GetX();
    local plotY = plot:GetY();
    if(not major) then
        for dir = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
            local adjacentPlot = Map.GetAdjacentPlot(plotX, plotY, dir);
            if(adjacentPlot ~= nil and adjacentPlot:GetFeatureType() == featureType) then
                count = count + 1;
            end
        end
    else
      	for i = 1, 17 do
			local adjacentPlot = GetAdjacentTiles(plot, i)
               if(adjacentPlot ~= nil and adjacentPlot:GetFeatureType() == featureType) then
                    count = count + 1;
               end
        end
    end
    return count;
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__CountAdjacentContinentsInRange(plot, major)
    local count = 0;
    local plotX = plot:GetX();
    local plotY = plot:GetY();
	local continent = plot:GetContinentType()
    if(not major) then
        for dir = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
            local adjacentPlot = Map.GetAdjacentPlot(plotX, plotY, dir);
            if(adjacentPlot ~= nil and adjacentPlot:GetContinentType() ~= continent) then
                count = count + 1;
            end
        end
    else
      	for i = 1, 17 do
			local adjacentPlot = GetAdjacentTiles(plot, i)
                if(adjacentPlot ~= nil and adjacentPlot:GetContinentType() ~= continent) then
                    count = count + 1;
                end
        end

    end
    return count;
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__CountAdjacentRiverInRange(plot, major)
    local count = 0;
    local plotX = plot:GetX();
    local plotY = plot:GetY();
    if(not major) then
        for dir = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
            local adjacentPlot = Map.GetAdjacentPlot(plotX, plotY, dir);
            if(adjacentPlot ~= nil and adjacentPlot:IsRiver() == true) then
                count = count + 1;
            end
        end
    else
      	for i = 1, 17 do
			local adjacentPlot = GetAdjacentTiles(plot, i)
                if(adjacentPlot ~= nil and adjacentPlot:IsRiver() == true) then
                    count = count + 1;
                end

        end
    end
    return count;
end
------------------------------------------------------------------------------
-----------------------------------------------------------------------------
function BBS_AssignStartingPlots:__CountAdjacentResourcesInRange(plot, resourceType, major, range)
    local count = 0;
    local plotX = plot:GetX();
    local plotY = plot:GetY();
	if range == nil then
		range = 2
	end
    if(not major) then
        for dir = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
            local adjacentPlot = Map.GetAdjacentPlot(plotX, plotY, dir);
            if(adjacentPlot ~= nil and adjacentPlot:GetResourceType() == resourceType) then
                count = count + 1;
            end
        end
    else
      	for i = 1, 17 do
			local adjacentPlot = GetAdjacentTiles(plot, i)
                if(adjacentPlot ~= nil and adjacentPlot:GetResourceType() == resourceType) then
                    count = count + 1;
                end

        end
    end
    return count;
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__CountAdjacentYieldsInRange(plot)
    local score = 0;
    local food = 0;
    local prod = 0;
    local plotX = plot:GetX();
    local plotY = plot:GetY();
    for dir = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
        local adjacentPlot = Map.GetAdjacentPlot(plotX, plotY, dir);
        if(adjacentPlot ~= nil) then
            local foodTemp = 0;
            local prodTemp = 0;
            if (adjacentPlot:GetResourceType() ~= nil) then
                -- Coal or Uranium
                if (adjacentPlot:GetResourceType() == 41 or adjacentPlot:GetResourceType() == 46) then
                    prod = prod - 2;
                -- Horses or Niter
                elseif (adjacentPlot:GetResourceType() == 42 or adjacentPlot:GetResourceType() == 44) then
                    food = food - 1;
                    prod = prod - 1;
                -- Oil
                elseif (adjacentPlot:GetResourceType() == 45) then
                    prod = prod - 3;
                end
            end
            foodTemp = adjacentPlot:GetYield(g_YIELD_FOOD);
            prodTemp = adjacentPlot:GetYield(g_YIELD_PRODUCTION);
            if (foodTemp >= 2 and prodTemp >= 2) then
                score = score + 5;
            end
            food = food + foodTemp;
            prod = prod + prodTemp;
        end
    end
    score = score + food + prod;
    --if (prod == 0) then
    --    score = score - 5;
    --end
    return score;
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__GetTerrainIndex(terrainType)
    if (terrainType == "TERRAIN_COAST") then
        return g_TERRAIN_TYPE_COAST;
    elseif (terrainType == "TERRAIN_DESERT") then
        return g_TERRAIN_TYPE_DESERT;
    elseif (terrainType == "TERRAIN_TUNDRA") then
        return g_TERRAIN_TYPE_TUNDRA;
    elseif (terrainType == "TERRAIN_SNOW") then
        return g_TERRAIN_TYPE_SNOW;
    elseif (terrainType == "TERRAIN_PLAINS") then
        return g_TERRAIN_TYPE_PLAINS;
    elseif (terrainType == "TERRAIN_GRASS") then
        return g_TERRAIN_TYPE_GRASS;
    elseif (terrainType == "TERRAIN_DESERT_HILLS") then
        return g_TERRAIN_TYPE_DESERT_HILLS;
    elseif (terrainType == "TERRAIN_TUNDRA_HILLS") then
        return g_TERRAIN_TYPE_TUNDRA_HILLS;
	elseif (terrainType == "TERRAIN_TUNDRA_MOUNTAIN") then
        return g_TERRAIN_TYPE_TUNDRA_MOUNTAIN;
    elseif (terrainType == "TERRAIN_SNOW_HILLS") then
        return g_TERRAIN_TYPE_SNOW_HILLS;
    elseif (terrainType == "TERRAIN_PLAINS_HILLS") then
        return g_TERRAIN_TYPE_PLAINS_HILLS;
    elseif (terrainType == "TERRAIN_GRASS_HILLS") then
        return g_TERRAIN_TYPE_GRASS_HILLS;
    elseif (terrainType == "TERRAIN_GRASS_MOUNTAIN") then
        return g_TERRAIN_TYPE_GRASS_MOUNTAIN;
    elseif (terrainType == "TERRAIN_PLAINS_MOUNTAIN") then
        return g_TERRAIN_TYPE_PLAINS_MOUNTAIN;
    elseif (terrainType == "TERRAIN_DESERT_MOUNTAIN") then
        return g_TERRAIN_TYPE_DESERT_MOUNTAIN;
    end
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__GetFeatureIndex(featureType)
    if (featureType == "FEATURE_VOLCANO") then
        return g_FEATURE_VOLCANO;
    elseif (featureType == "FEATURE_JUNGLE") then
        return g_FEATURE_JUNGLE;
    elseif (featureType == "FEATURE_FOREST") then
        return g_FEATURE_FOREST;
    elseif (featureType == "FEATURE_FLOODPLAINS") then
        return g_FEATURE_FLOODPLAINS;
    elseif (featureType == "FEATURE_FLOODPLAINS_PLAINS") then
        return g_FEATURE_FLOODPLAINS_PLAINS;
    elseif (featureType == "FEATURE_FLOODPLAINS_GRASSLAND") then
        return g_FEATURE_FLOODPLAINS_GRASSLAND;
    elseif (featureType == "FEATURE_GEOTHERMAL_FISSURE") then
        return g_FEATURE_GEOTHERMAL_FISSURE;
    end
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__GetResourceIndex(resourceType)
    local resourceTypeName = "LOC_" .. resourceType .. "_NAME";
    for row in GameInfo.Resources() do
        if (row.Name == resourceTypeName) then
            return row.Index;
        end
    end
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__BaseFertility(plot)
    -- Calculate the fertility of the starting plot
    local pPlot = Map.GetPlotByIndex(plot);
    local iFertility = StartPositioner.GetPlotFertility(pPlot:GetIndex(), -1);
    return iFertility;
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__NaturalWonderBufferCheck(plot, major)
    -- Returns false if the player can start because there is a natural wonder too close.
    -- If Start position config equals legendary you can start near Natural wonders
    if(self.uiStartConfig == 3) then
        return true;
    end

    local iMaxNW = 4;

    if(major == false) then
        iMaxNW = GlobalParameters.START_DISTANCE_MINOR_NATURAL_WONDER or 3;
    else
        iMaxNW = GlobalParameters.START_DISTANCE_MAJOR_NATURAL_WONDER or 4;
    end

    local plotX = plot:GetX();
    local plotY = plot:GetY();
    for dx = -iMaxNW, iMaxNW do
        for dy = -iMaxNW, iMaxNW do
            local otherPlot = Map.GetPlotXYWithRangeCheck(plotX, plotY, dx, dy, iMaxNW);
            if(otherPlot and otherPlot:IsNaturalWonder()) then
                return false;
            end
        end
    end
    return true;
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__LuxuryBufferCheck(plot, major)
    -- Checks to see if there are luxuries in the given distance
    if (major and math.ceil(self.iDefaultNumberMajor * 1.25) + self.iDefaultNumberMinor > self.iNumMinorCivs + self.iNumMajorCivs) then
        local plotX = plot:GetX();
        local plotY = plot:GetY();
        for dx = -2, 2 do
            for dy = -2, 2 do
                local otherPlot = Map.GetPlotXYWithRangeCheck(plotX, plotY, dx, dy, 2);
                if(otherPlot) then
                    if(otherPlot:GetResourceCount() > 0) then
                        for _, row in ipairs(self.rLuxury) do 
                            if(row.Index == otherPlot:GetResourceType()) then
                                return true;
                            end
                        end
                    end
                end
            end
        end
        return false;
    end
    return true;
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__LuxuryCount(plot)
    -- Checks to see if there are luxuries in the given distance
		local count = 0
        local plotX = plot:GetX();
        local plotY = plot:GetY();
        for dx = -2, 2 do
            for dy = -2, 2 do
                local otherPlot = Map.GetPlotXYWithRangeCheck(plotX, plotY, dx, dy, 2);
                if(otherPlot) then
                    if(otherPlot:GetResourceCount() > 0) then
                        for _, row in ipairs(self.rLuxury) do 
                            if(row.Index == otherPlot:GetResourceType()) then
                                count = count + 1
                            end
                        end
                    end
                end
            end
        end
		return count

end

------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__TryToRemoveBonusResource(plot)
    --Removes Bonus Resources underneath starting players
    for row in GameInfo.Resources() do
        if (row.ResourceClassType == "RESOURCECLASS_BONUS") then
            if(row.Index == plot:GetResourceType()) then
                ResourceBuilder.SetResourceType(plot, -1);
            end
        end
    end
end

------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__MinorMinorCivBufferCheck(plot,playerID)
    -- Checks to see if there are minors in the given distance for this minor civ
    local iMaxStart = GlobalParameters.START_DISTANCE_MINOR_CIVILIZATION_START or 7;
    --iMaxStart = iMaxStart - GlobalParameters.START_DISTANCE_RANGE_MINOR or 2;
	--local iMaxStart = 7;
	local leader	:string = PlayerConfigurations[playerID]:GetLeaderTypeName();
	local leaderInfo:table	= GameInfo.Leaders[leader];

    local iSourceIndex = plot:GetIndex();
    for i, minorPlotandID in ipairs(self.minorStartPlotsID) do
		if minorPlotandID.Plot == plot then
			return false;
		end
        if(Map.GetPlotDistance(iSourceIndex, minorPlotandID.Plot:GetIndex()) <= iMaxStart or Map.GetPlotDistance(iSourceIndex, minorPlotandID.Plot:GetIndex()) < 7) then
            return false;
        end
		if minorPlotandID.ID ~= nil and PlayerConfigurations[minorPlotandID.ID] ~= nil then
			local min_leader	:string = PlayerConfigurations[minorPlotandID.ID]:GetLeaderTypeName();
			local min_leaderInfo:table	= GameInfo.Leaders[min_leader];
			if leaderInfo.InheritFrom == min_leaderInfo.InheritFrom and Map.GetPlotDistance(iSourceIndex, minorPlotandID.Plot:GetIndex()) < 21 then
				if self.iMinorAttempts < 20 then
					__Debug("Too close to same CS type")
					self.iMinorAttempts = self.iMinorAttempts + 1
					return false;
				end
			end
		end
    end
    return true;
end

------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__MinorMajorCivBufferCheck(plot)
    -- Checks to see if there are majors in the given distance for this minor civ
    local iMaxStart = GlobalParameters.START_DISTANCE_MINOR_MAJOR_CIVILIZATION or 8;
    --local iMaxStart = 8;
    local iSourceIndex = plot:GetIndex();
    if(self.waterMap) then
        iMaxStart = iMaxStart - 1;
    end
    for i, majorPlot in ipairs(self.majorStartPlots) do
		if majorPlot == plot then
			return false;
		end
        if(Map.GetPlotDistance(iSourceIndex, majorPlot:GetIndex()) <= iMaxStart + self.iDistance_minor or Map.GetPlotDistance(iSourceIndex, majorPlot:GetIndex()) < 11 + self.iDistance_minor or Map.GetPlotDistance(iSourceIndex, majorPlot:GetIndex()) < 5) then
            return false;
        end
    end
    return true;
end

------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__MajorMajorCivBufferCheck(plot,team)
    -- Checks to see if there are major civs in the given distance for this major civ
    local iMaxStart = GlobalParameters.START_DISTANCE_MAJOR_CIVILIZATION or 12;
    if(self.waterMap) then
        iMaxStart = iMaxStart - 3;
    end
    iMaxStart = iMaxStart - GlobalParameters.START_DISTANCE_RANGE_MAJOR or 2;
    --local iMaxStart = 10;
    local iSourceIndex = plot:GetIndex();
    for i, majorPlot in ipairs(self.majorStartPlots) do
		if majorPlot == plot then
			return false;
		end
		if team ~= nil and self.majorStartPlotsTeam[i] ~= nil then
			if self.majorStartPlotsTeam[i] == team  then

				if(Map.GetPlotDistance(iSourceIndex, majorPlot:GetIndex()) <= iMaxStart + self.iDistance or Map.GetPlotDistance(iSourceIndex, majorPlot:GetIndex()) < self.iHard_Major + self.iDistance) then
					return false;
				end			
				else
				if(Map.GetPlotDistance(iSourceIndex, majorPlot:GetIndex()) <= iMaxStart + self.iDistance or Map.GetPlotDistance(iSourceIndex, majorPlot:GetIndex()) < self.iHard_Major + self.iDistance) then
					return false;
				end	
			end
			
			else
		    if(Map.GetPlotDistance(iSourceIndex, majorPlot:GetIndex()) <= iMaxStart + self.iDistance or Map.GetPlotDistance(iSourceIndex, majorPlot:GetIndex()) < self.iHard_Major + self.iDistance) then
				return false;
			end
		end
    end
    return true;
end

------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__AddBonusFoodProduction(plot)
    local food = 0;
    local production = 0;
    local maxFood = 0;
    local maxProduction = 0;
    local gridHeight = Map.GetGridSize();
    local terrainType = plot:GetTerrainType();

    for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
        local adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), direction);
        if (adjacentPlot ~= nil) then
            terrainType = adjacentPlot:GetTerrainType();
            if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
                -- Gets the food and productions
                food = food + adjacentPlot:GetYield(g_YIELD_FOOD);
                production = production + adjacentPlot:GetYield(g_YIELD_PRODUCTION);

                --Checks the maxFood
                if(maxFood <=  adjacentPlot:GetYield(g_YIELD_FOOD)) then
                    maxFood = adjacentPlot:GetYield(g_YIELD_FOOD);
                end

                --Checks the maxProduction
                if(maxProduction <=  adjacentPlot:GetYield(g_YIELD_PRODUCTION)) then
                    maxProduction = adjacentPlot:GetYield(g_YIELD_PRODUCTION);
                end
            end
        end
    end

    if(food < 7 or maxFood < 3) then
        local retry = 0;
        while (food < 7 and retry < 2) do
            food = food + self:__AddFood(plot);
            retry = retry + 1;
        end
    end

    if(production < 5 or maxProduction < 2) then
        local retry = 0;
        while (production < 5 and retry < 2) do
            production = production + self:__AddProduction(plot);
            retry = retry + 1;
        end
    end
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__AddFood(plot)
    local foodAdded = 0;
    local dir = TerrainBuilder.GetRandomNumber(DirectionTypes.NUM_DIRECTION_TYPES, "Random Direction");
    for i = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
        local adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), dir);
        if (adjacentPlot ~= nil) then
            local foodBefore = adjacentPlot:GetYield(g_YIELD_FOOD);
            local aShuffledBonus =  GetShuffledCopyOfTable(self.aBonusFood);
            for _, bonus in ipairs(aShuffledBonus) do
                if(ResourceBuilder.CanHaveResource(adjacentPlot, bonus.Index)) then
                    ResourceBuilder.SetResourceType(adjacentPlot, bonus.Index, 1);
                    foodAdded = adjacentPlot:GetYield(g_YIELD_FOOD) - foodBefore;
                    return foodAdded;
                end
            end
        end

        if(dir == DirectionTypes.NUM_DIRECTION_TYPES - 1) then
            dir = 0;
        else
            dir = dir + 1;
        end
    end
    return foodAdded;
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__AddProduction(plot)
    local prodAdded = 0;
    local dir = TerrainBuilder.GetRandomNumber(DirectionTypes.NUM_DIRECTION_TYPES, "Random Direction");
    for i = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
        local adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), dir);
        if (adjacentPlot ~= nil) then
            local prodBefore = adjacentPlot:GetYield(g_YIELD_PRODUCTION);
            local aShuffledBonus = GetShuffledCopyOfTable(self.aBonusProd);
            for _, bonus in ipairs(aShuffledBonus) do
                if(ResourceBuilder.CanHaveResource(adjacentPlot, bonus.Index)) then
                    ResourceBuilder.SetResourceType(adjacentPlot, bonus.Index, 1);
                    prodAdded = adjacentPlot:GetYield(g_YIELD_PRODUCTION) - prodBefore;
                    return prodAdded;
                end
            end
        end

        if(dir == DirectionTypes.NUM_DIRECTION_TYPES - 1) then
            dir = 0;
        else
            dir = dir + 1;
        end
    end
    return prodAdded;
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__AddResourcesBalanced()
    local iStartEra = GameInfo.Eras[ GameConfiguration.GetStartEra() ];
    local iStartIndex = 1;
    if iStartEra ~= nil then
        iStartIndex = iStartEra.ChronologyIndex;
    end

    local iHighestFertility = 0;
    for _, plot in ipairs(self.majorStartPlots) do
        self:__RemoveBonus(plot);
        self:__BalancedStrategic(plot, iStartIndex);

        if(self:__BaseFertility(plot:GetIndex()) > iHighestFertility) then
            iHighestFertility = self:__BaseFertility(plot:GetIndex());
        end
    end

    for _, plot in ipairs(self.majorStartPlots) do
        local iFertilityLeft = iHighestFertility - self:__BaseFertility(plot:GetIndex());

        if(iFertilityLeft > 0) then
            if(self:__IsContinentalDivide(plot)) then
                --__Debug("START_FERTILITY_WEIGHT_CONTINENTAL_DIVIDE", GlobalParameters.START_FERTILITY_WEIGHT_CONTINENTAL_DIVIDE);
                local iContinentalWeight = math.floor((GlobalParameters.START_FERTILITY_WEIGHT_CONTINENTAL_DIVIDE or 250) / 10);
                iFertilityLeft = iFertilityLeft - iContinentalWeight
            else
                local bAddLuxury = true;
                --__Debug("START_FERTILITY_WEIGHT_LUXURY", GlobalParameters.START_FERTILITY_WEIGHT_LUXURY);
                local iLuxWeight = math.floor((GlobalParameters.START_FERTILITY_WEIGHT_LUXURY or 250) / 10);
                while iFertilityLeft >= iLuxWeight and bAddLuxury do
                    bAddLuxury = self:__AddLuxury(plot);
                    if(bAddLuxury) then
                        iFertilityLeft = iFertilityLeft - iLuxWeight;
                    end
                end
            end
            local bAddBonus = true;
            --__Debug("START_FERTILITY_WEIGHT_BONUS", GlobalParameters.START_FERTILITY_WEIGHT_BONUS);
            local iBonusWeight = math.floor((GlobalParameters.START_FERTILITY_WEIGHT_BONUS or 75) / 10);
            while iFertilityLeft >= iBonusWeight and bAddBonus do
                bAddBonus = self:__AddBonus(plot);
                if(bAddBonus) then
                    iFertilityLeft = iFertilityLeft - iBonusWeight;
                end
            end
        end
    end
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__AddResourcesLegendary()
    local iStartEra = GameInfo.Eras[ GameConfiguration.GetStartEra() ];
    local iStartIndex = 1;
    if iStartEra ~= nil then
        iStartIndex = iStartEra.ChronologyIndex;
    end

    local iLegendaryBonusResources = GlobalParameters.START_LEGENDARY_BONUS_QUANTITY or 2;
    local iLegendaryLuxuryResources = GlobalParameters.START_LEGENDARY_LUXURY_QUANTITY or 1;
    for i, plot in ipairs(self.majorStartPlots) do
        self:__BalancedStrategic(plot, iStartIndex);

        if(self:__IsContinentalDivide(plot)) then
            iLegendaryLuxuryResources = iLegendaryLuxuryResources - 1;
        else
            local bAddLuxury = true;
            while iLegendaryLuxuryResources > 0 and bAddLuxury do
                bAddLuxury = self:__AddLuxury(plot);
                if(bAddLuxury) then
                    iLegendaryLuxuryResources = iLegendaryLuxuryResources - 1;
                end
            end
        end

        local bAddBonus = true;
        iLegendaryBonusResources = iLegendaryBonusResources + 2 * iLegendaryLuxuryResources;
        while iLegendaryBonusResources > 0 and bAddBonus do
            bAddBonus = self:__AddBonus(plot);
            if(bAddBonus) then
                iLegendaryBonusResources = iLegendaryBonusResources - 1;
            end
        end
    end
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__BalancedStrategic(plot, iStartIndex)
    local iRange = STRATEGIC_RESOURCE_FERTILITY_STARTING_ERA_RANGE or 1;
    for _, row in ipairs(self.rStrategic) do
        if(iStartIndex - iRange <= row.RevealedEra and iStartIndex + iRange >= row.RevealedEra) then
            local bHasResource = false;
            bHasResource = self:__FindSpecificStrategic(row.Index, plot);
            if(not bHasResource) then
                self:__AddStrategic(row.Index, plot)
                __Debug("Strategic Resource Placed :", row.Name);
            end
        end
    end
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__FindSpecificStrategic(eResourceType, plot)
    -- Checks to see if there is a specific strategic in a given distance
    local plotX = plot:GetX();
    local plotY = plot:GetY();
    for dx = -3, 3 do
        for dy = -3,3 do
            local otherPlot = Map.GetPlotXYWithRangeCheck(plotX, plotY, dx, dy, 3);
            if(otherPlot) then
                if(otherPlot:GetResourceCount() > 0) then
                    if(eResourceType == otherPlot:GetResourceType()) then
                        return true;
                    end
                end
            end
        end
    end
    return false;
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__AddStrategic(eResourceType, plot)
    -- Checks to see if it can place a specific strategic
    local plotX = plot:GetX();
    local plotY = plot:GetY();
    for dx = -2, 2 do
        for dy = -2, 2 do
            local otherPlot = Map.GetPlotXYWithRangeCheck(plotX, plotY, dx, dy, 2);
            if(otherPlot) then
                if(ResourceBuilder.CanHaveResource(otherPlot, eResourceType) and otherPlot:GetIndex() ~= plot:GetIndex()) then
                    ResourceBuilder.SetResourceType(otherPlot, eResourceType, 1);
                    return;
                end
            end
        end
    end
    for dx = -3, 3 do
        for dy = -3, 3 do
            local otherPlot = Map.GetPlotXYWithRangeCheck(plotX, plotY, dx, dy, 3);
            if(otherPlot) then
                if(ResourceBuilder.CanHaveResource(otherPlot, eResourceType) and otherPlot:GetIndex() ~= plot:GetIndex()) then
                    ResourceBuilder.SetResourceType(otherPlot, eResourceType, 1);
                    return;
                end
            end
        end
    end
    __Debug("Failed to add Strategic.");
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__AddLuxury(plot)
    local plotX = plot:GetX();
    local plotY = plot:GetY();
    local eAddLux = {};
    for dx = -4, 4 do
        for dy = -4, 4 do
            local otherPlot = Map.GetPlotXYWithRangeCheck(plotX, plotY, dx, dy, 4);
            if(otherPlot) then
                if(otherPlot:GetResourceCount() > 0) then
                    for _, row in ipairs(self.rLuxury) do
                        if(otherPlot:GetResourceType() == row.Index) then
                            table.insert(eAddLux, row);
                        end
                    end
                end
            end
        end
    end

    for dx = -2, 2 do
        for dy = -2, 2 do
            local otherPlot = Map.GetPlotXYWithRangeCheck(plotX, plotY, dx, dy, 2);
            if(otherPlot) then
                eAddLux = GetShuffledCopyOfTable(eAddLux);
                for _, resource in ipairs(eAddLux) do
                    if(ResourceBuilder.CanHaveResource(otherPlot, resource.Index) and otherPlot:GetIndex() ~= plot:GetIndex()) then
                        ResourceBuilder.SetResourceType(otherPlot, resource.Index, 1);
                        __Debug("Yeah Lux");
                        return true;
                    end
                end
            end
        end
    end

    __Debug("Failed Lux");
    return false;
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__AddBonus(plot)
    local plotX = plot:GetX();
    local plotY = plot:GetY();
    local aBonus =  GetShuffledCopyOfTable(self.rBonus);
    for _, resource in ipairs(aBonus) do
        for dx = -2, 2 do
            for dy = -2, 2 do
                local otherPlot = Map.GetPlotXYWithRangeCheck(plotX, plotY, dx, dy, 2);
                if(otherPlot) then
                    --__Debug(otherPlot:GetX(), otherPlot:GetY(), "Resource Index :", resource.Index);
                    if(ResourceBuilder.CanHaveResource(otherPlot, resource.Index) and otherPlot:GetIndex() ~= plot:GetIndex()) then
                        ResourceBuilder.SetResourceType(otherPlot, resource.Index, 1);
                        __Debug("Yeah Bonus");
                        return true;
                    end
                end
            end
        end
    end

    __Debug("Failed Bonus");
    return false
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__IsContinentalDivide(plot)
    local plotX = plot:GetX();
    local plotY = plot:GetY();

    local eContinents = {};

    for dx = -4, 4 do
        for dy = -4, 4 do
            local otherPlot = Map.GetPlotXYWithRangeCheck(plotX, plotY, dx, dy, 4);
            if(otherPlot) then
                if(otherPlot:GetContinentType() ~= nil) then
                    if(#eContinents == 0) then
                        table.insert(eContinents, otherPlot:GetContinentType());
                    else
                        if(eContinents[1] ~= otherPlot:GetContinentType()) then
                            return true;
                        end
                    end
                end
            end
        end
    end

    return false;
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__RemoveBonus(plot)
    local plotX = plot:GetX();
    local plotY = plot:GetY();
    for _, resource in ipairs(self.rBonus) do
        for dx = -3, 3 do
            for dy = -3,3 do
                local otherPlot = Map.GetPlotXYWithRangeCheck(plotX, plotY, dx, dy, 3);
                if(otherPlot) then
                    if(resource.Index == otherPlot:GetResourceType()) then
                        ResourceBuilder.SetResourceType(otherPlot, resource.Index, -1);
                        return;
                    end
                end
            end
        end
    end
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__TableSize(table)
    local count = 0;
    for _ in pairs(table) do
        count = count + 1;
    end
    return count;
end
------------------------------------------------------------------------------
function BBS_AssignStartingPlots:__GetShuffledCiv(incoming_table,param)
	-- Designed to operate on tables with no gaps. Does not affect original table.
	local len = table.maxn(incoming_table);
	local copy = {};
	local shuffledVersion = {};
	-- Make copy of table.
	for loop = 1, len do
		copy[loop] = incoming_table[loop];
	end
	-- One at a time, choose a random index from Copy to insert in to final table, then remove it from the copy.
	local left_to_do = table.maxn(copy);
	for loop = 1, len do
		local random_index = 0
		for n = 1, param do
			random_index = 1 + TerrainBuilder.GetRandomNumber(left_to_do, "Shuffling table entry - Lua");
		end
		table.insert(shuffledVersion, copy[random_index]);
		table.remove(copy, random_index);
		left_to_do = left_to_do - 1;
	end
	return shuffledVersion
end

---------------------------------------
function GetAdjacentTiles(plot, index)
	-- This is an extended version of Firaxis, moving like a clockwise snail on the hexagon grids
	local gridWidth, gridHeight = Map.GetGridSize();
	local count = 0;
	local k = 0;
	local adjacentPlot = nil;
	local adjacentPlot2 = nil;
	local adjacentPlot3 = nil;
	local adjacentPlot4 = nil;
	local adjacentPlot5 = nil;


	-- Return Spawn if index < 0
	if(plot ~= nil and index ~= nil) then
		if (index < 0) then
			return plot;
		end

		else

		__Debug("GetAdjacentTiles: Invalid Arguments");
		return nil;
	end

	

	-- Return Starting City Circle if index between #0 to #5 (like Firaxis' GetAdjacentPlot) 
	for i = 0, 5 do
		if(plot:GetX() >= 0 and plot:GetY() < gridHeight) then
			adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), i);
			if (adjacentPlot ~= nil and index == i) then
				return adjacentPlot
			end
		end
	end

	-- Return Inner City Circle if index between #6 to #17

	count = 5;
	for i = 0, 5 do
		if(plot:GetX() >= 0 and plot:GetY() < gridHeight) then
			adjacentPlot2 = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), i);
		end

		for j = i, i+1 do
			--__Debug(i, j)
			k = j;
			count = count + 1;

			if (k == 6) then
				k = 0;
			end

			if (adjacentPlot2 ~= nil) then
				if(adjacentPlot2:GetX() >= 0 and adjacentPlot2:GetY() < gridHeight) then
					adjacentPlot = Map.GetAdjacentPlot(adjacentPlot2:GetX(), adjacentPlot2:GetY(), k);

					else

					adjacentPlot = nil;
				end
			end
		

			if (adjacentPlot ~=nil) then
				if(index == count) then
					return adjacentPlot
				end
			end

		end
	end

	-- #18 to #35 Outer city circle
	count = 0;
	for i = 0, 5 do
		if(plot:GetX() >= 0 and plot:GetY() < gridHeight) then
			adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), i);
			adjacentPlot2 = nil;
			adjacentPlot3 = nil;
			else
			adjacentPlot = nil;
			adjacentPlot2 = nil;
			adjacentPlot3 = nil;
		end
		if (adjacentPlot ~=nil) then
			if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
				adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i);
			end
			if (adjacentPlot3 ~= nil) then
				if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
					adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i);
				end
			end
		end

		if (adjacentPlot2 ~= nil) then
			count = 18 + i * 3;
			if(index == count) then
				return adjacentPlot2
			end
		end

		adjacentPlot2 = nil;

		if (adjacentPlot3 ~= nil) then
			if (i + 1) == 6 then
				if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
					adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), 0);
				end
				else
				if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
					adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i +1);
				end
			end
		end

		if (adjacentPlot2 ~= nil) then
			count = 18 + i * 3 + 1;
			if(index == count) then
				return adjacentPlot2
			end
		end

		adjacentPlot2 = nil;

		if (adjacentPlot ~= nil) then
			if (i+1 == 6) then
				if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
					adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), 0);
				end
				if (adjacentPlot3 ~= nil) then
					if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
						adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), 0);
					end
				end
				else
				if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
					adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i+1);
				end
				if (adjacentPlot3 ~= nil) then
					if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
						adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i+1);
					end
				end
			end
		end

		if (adjacentPlot2 ~= nil) then
			count = 18 + i * 3 + 2;
			if(index == count) then
				return adjacentPlot2;
			end
		end

	end

	--  #35 #59 These tiles are outside the workable radius of the city
	local count = 0
	for i = 0, 5 do
		if(plot:GetX() >= 0 and plot:GetY() < gridHeight) then
			adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), i);
			adjacentPlot2 = nil;
			adjacentPlot3 = nil;
			adjacentPlot4 = nil;
			else
			adjacentPlot = nil;
			adjacentPlot2 = nil;
			adjacentPlot3 = nil;
			adjacentPlot4 = nil;
		end
		if (adjacentPlot ~=nil) then
			if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
				adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i);
			end
			if (adjacentPlot3 ~= nil) then
				if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
					adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i);
					if (adjacentPlot4 ~= nil) then
						if(adjacentPlot4:GetX() >= 0 and adjacentPlot4:GetY() < gridHeight) then
							adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), i);
						end
					end
				end
			end
		end

		if (adjacentPlot2 ~= nil) then
			terrainType = adjacentPlot2:GetTerrainType();
			if (adjacentPlot2 ~=nil) then
				count = 36 + i * 4;
				if(index == count) then
					return adjacentPlot2;
				end
			end

		end

		if (adjacentPlot3 ~= nil) then
			if (i + 1) == 6 then
				if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
					adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), 0);
				end
				else
				if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
					adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i +1);
				end
			end
		end

		if (adjacentPlot4 ~= nil) then
			if(adjacentPlot4:GetX() >= 0 and adjacentPlot4:GetY() < gridHeight) then
				adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), i);
				if (adjacentPlot2 ~= nil) then
					count = 36 + i * 4 + 1;
					if(index == count) then
						return adjacentPlot2;
					end
				end
			end


		end

		adjacentPlot4 = nil;

		if (adjacentPlot ~= nil) then
			if (i+1 == 6) then
				if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
					adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), 0);
				end
				if (adjacentPlot3 ~= nil) then
					if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
						adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), 0);
					end
				end
				else
				if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
					adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i+1);
				end
				if (adjacentPlot3 ~= nil) then
					if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
						adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i+1);
					end
				end
			end
		end

		if (adjacentPlot4 ~= nil) then
			if (adjacentPlot4:GetX() >= 0 and adjacentPlot4:GetY() < gridHeight) then
				adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), i);
				if (adjacentPlot2 ~= nil) then
					count = 36 + i * 4 + 2;
					if(index == count) then
						return adjacentPlot2;
					end

				end
			end

		end

		adjacentPlot4 = nil;

		if (adjacentPlot ~= nil) then
			if (i+1 == 6) then
				if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
					adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), 0);
				end
				if (adjacentPlot3 ~= nil) then
					if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
						adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), 0);
					end
				end
				else
				if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
					adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i+1);
				end
				if (adjacentPlot3 ~= nil) then
					if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
						adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i+1);
					end
				end
			end
		end

		if (adjacentPlot4 ~= nil) then
			if (adjacentPlot4:GetX() >= 0 and adjacentPlot4:GetY() < gridHeight) then
				if (i+1 == 6) then
					adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), 0);
					else
					adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), i+1);
				end
				if (adjacentPlot2 ~= nil) then
					count = 36 + i * 4 + 3;
					if(index == count) then
						return adjacentPlot2;
					end

				end
			end

		end

	end

	--  > #60 to #90

local count = 0
	for i = 0, 5 do
		if(plot:GetX() >= 0 and plot:GetY() < gridHeight) then
			adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), i); --first ring
			adjacentPlot2 = nil;
			adjacentPlot3 = nil;
			adjacentPlot4 = nil;
			adjacentPlot5 = nil;
			else
			adjacentPlot = nil;
			adjacentPlot2 = nil;
			adjacentPlot3 = nil;
			adjacentPlot4 = nil;
			adjacentPlot5 = nil;
		end
		if (adjacentPlot ~=nil) then
			if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
				adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i); --2nd ring
			end
			if (adjacentPlot3 ~= nil) then
				if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
					adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i); --3rd ring
					if (adjacentPlot4 ~= nil) then
						if(adjacentPlot4:GetX() >= 0 and adjacentPlot4:GetY() < gridHeight) then
							adjacentPlot5 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), i); --4th ring
							if (adjacentPlot5 ~= nil) then
								if(adjacentPlot5:GetX() >= 0 and adjacentPlot5:GetY() < gridHeight) then
									adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot5:GetX(), adjacentPlot5:GetY(), i); --5th ring
								end
							end
						end
					end
				end
			end
		end

		if (adjacentPlot2 ~= nil) then
			count = 60 + i * 5;
			if(index == count) then
				return adjacentPlot2; --5th ring
			end
		end

		adjacentPlot2 = nil;

		if (adjacentPlot5 ~= nil) then
			if (i + 1) == 6 then
				if(adjacentPlot5:GetX() >= 0 and adjacentPlot5:GetY() < gridHeight) then
					adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot5:GetX(), adjacentPlot5:GetY(), 0);
				end
				else
				if(adjacentPlot5:GetX() >= 0 and adjacentPlot5:GetY() < gridHeight) then
					adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot5:GetX(), adjacentPlot5:GetY(), i +1);
				end
			end
		end


		if (adjacentPlot2 ~= nil) then
			count = 60 + i * 5 + 1;
			if(index == count) then
				return adjacentPlot2;
			end

		end

		adjacentPlot2 = nil;

		if (adjacentPlot ~=nil) then
			if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
				adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i);
			end
			if (adjacentPlot3 ~= nil) then
				if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
					adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i);
					if (adjacentPlot4 ~= nil) then
						if(adjacentPlot4:GetX() >= 0 and adjacentPlot4:GetY() < gridHeight) then
							if (i+1 == 6) then
								adjacentPlot5 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), 0);
								else
								adjacentPlot5 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), i+1);
							end
							if (adjacentPlot5 ~= nil) then
								if(adjacentPlot5:GetX() >= 0 and adjacentPlot5:GetY() < gridHeight) then
									if (i+1 == 6) then
										adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot5:GetX(), adjacentPlot5:GetY(), 0);
										else
										adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot5:GetX(), adjacentPlot5:GetY(), i+1);
									end
								end
							end
						end
					end
				end
			end
		end

		if (adjacentPlot2 ~= nil) then
			count = 60 + i * 5 + 2;
			if(index == count) then
				return adjacentPlot2;
			end

		end

		if (adjacentPlot ~=nil) then
			if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
				if (i+1 == 6) then
					adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), 0); -- 2 ring
					else
					adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i+1); -- 2 ring
				end
			end
			if (adjacentPlot3 ~= nil) then
				if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
					if (i+1 == 6) then
						adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), 0); -- 3ring
						else
						adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i+1); -- 3ring

					end
					if (adjacentPlot4 ~= nil) then
						if(adjacentPlot4:GetX() >= 0 and adjacentPlot4:GetY() < gridHeight) then
							if (i+1 == 6) then
								adjacentPlot5 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), 0); --4th ring
								else
								adjacentPlot5 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), i+1); --4th ring
							end
							if (adjacentPlot5 ~= nil) then
								if(adjacentPlot5:GetX() >= 0 and adjacentPlot5:GetY() < gridHeight) then
									adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot5:GetX(), adjacentPlot5:GetY(), i); --5th ring
								end
							end
						end
					end
				end
			end
		end

		if (adjacentPlot2 ~= nil) then
			count = 60 + i * 5 + 3;
			if(index == count) then
				return adjacentPlot2;
			end

		end
		
		adjacentPlot2 = nil

		if (adjacentPlot ~=nil) then
			if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
				if (i+1 == 6) then
					adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), 0); -- 2 ring
					else
					adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i+1); -- 2 ring
				end
			end
			if (adjacentPlot3 ~= nil) then
				if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
					if (i+1 == 6) then
						adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), 0); -- 3ring
						else
						adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i+1); -- 3ring

					end
					if (adjacentPlot4 ~= nil) then
						if(adjacentPlot4:GetX() >= 0 and adjacentPlot4:GetY() < gridHeight) then
							if (i+1 == 6) then
								adjacentPlot5 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), 0); --4th ring
								else
								adjacentPlot5 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), i+1); --4th ring
							end
							if (adjacentPlot5 ~= nil) then
								if(adjacentPlot5:GetX() >= 0 and adjacentPlot5:GetY() < gridHeight) then
									if (i+1 == 6) then
										adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot5:GetX(), adjacentPlot5:GetY(), 0); --5th ring
										else
										adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot5:GetX(), adjacentPlot5:GetY(), i+1); --5th ring
									end
								end
							end
						end
					end
				end
			end
		end

		if (adjacentPlot2 ~= nil) then
			count = 60 + i * 5 + 4;
			if(index == count) then
				return adjacentPlot2;
			end

		end

	end

end