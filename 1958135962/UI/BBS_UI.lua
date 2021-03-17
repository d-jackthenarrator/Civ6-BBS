local g_version = "1.6"

-------------------------------------------------------------------------------
print("-------------- BBS UI v"..g_version.." -D- Init --------------")
-------------------------------------------------------------------------------



function OnLoadScreenClose()
	if (Game:GetProperty("BBS_INIT_COUNT") ~= nil) then
		print(Game:GetProperty("BBS_INIT_COUNT"))
		if Game:GetProperty("BBS_INIT_COUNT") > 1 then
			if GameConfiguration.IsPlayByCloud() == false and GameConfiguration.IsHotseat() == false then
				--OnStatusMessage( "BBS reloaded succesfully! ("..g_version..")", 10, ReportingStatusTypes.DEFAULT )
				NotificationManager.SendNotification(Players[Game.GetLocalPlayer()], NotificationTypes.USER_DEFINED_1, "BBS reloaded succesfully! ("..g_version..")")
			end
			else
			if (Game:GetProperty("BBS_DISTANCE_ERROR") ~= nil) then
				--OnStatusMessage( Game:GetProperty("BBS_DISTANCE_ERROR"), 600, ReportingStatusTypes.DEFAULT )
				NotificationManager.SendNotification(Players[Game.GetLocalPlayer()], NotificationTypes.USER_DEFINED_2, Game:GetProperty("BBS_DISTANCE_ERROR"))
			end
			if (Game:GetProperty("BBS_SAFE_MODE") ~= nil) then
				print(Game:GetProperty("BBS_SAFE_MODE"))
				if (Game:GetProperty("BBS_SAFE_MODE") == true) then
				--OnStatusMessage( "BBS "..g_version.." Loaded succesfully! (Firaxis Placement)", 180, ReportingStatusTypes.DEFAULT )
				NotificationManager.SendNotification(Players[Game.GetLocalPlayer()], NotificationTypes.USER_DEFINED_1,  "BBS "..g_version.." Loaded succesfully!")
				else
				--OnStatusMessage( "BBS "..g_version.." Loaded succesfully! (BBS Placement)", 180, ReportingStatusTypes.DEFAULT )
				NotificationManager.SendNotification(Players[Game.GetLocalPlayer()], NotificationTypes.USER_DEFINED_1, "BBS "..g_version.." Loaded succesfully!")
				end
			end
			if (Game:GetProperty("BBS_MINOR_FAILING_TOTAL") ~= nil) then
				if Game:GetProperty("BBS_MINOR_FAILING_TOTAL") > 0 then
					--OnStatusMessage( Game:GetProperty("BBS_MINOR_FAILING_TOTAL").." City-State(s) couldn't be placed on the map.", 120, ReportingStatusTypes.DEFAULT )
				end
			end
		end
	end
	
	
end


Events.LoadScreenClose.Add( OnLoadScreenClose );


