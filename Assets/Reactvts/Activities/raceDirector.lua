local activity = {}
activity.title = "Race Director"
activity.initalized = false


local start_countdown = 0


local effect_timer = -1
-- local right_padding = 125 
local prev_room = null
local is_frozen = false
local speed = 100
-- local last_song = 0z
-- local last_score = 0
-- local level_finished = false
local time_left = '00:00:00'
local total_seconds = 0;
-- local players = {}
-- local player_count = null
-- local player_position = null
local game_mode = 'race-director'
local phase = 'waiting'

local session_init = false


function sendGameHash()
	print('sending game hash')
	if is_rom_loaded() then               
		local send_string = string.format('{"event":"client-message_sent","data":{"id":"%s","clientId":"%s","action":"load_game","hash":"%s"},"channel":"presence-%s-game"}',
		config.user_id, config.name, gameinfo.getromhash(), config.roomcode)
		print(send_string)
		local result = comm.ws_send(config.ws_id, send_string , true)
		print(result)
		session_init = true                
	end
end



function split (inputstr, sep)
	if sep == nil then
			sep = "%s"
	end
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
			table.insert(t, str)
	end
	return t
end

function table.contains(table, element)
	for _, value in pairs(table) do
	  if value == element then
		return true
	  end
	end
	return false
  end







function activity.drawGUI()
	local x = client.bufferwidth() 
	if start_countdown > 0 and racing == false then
		gui.drawString( (client.bufferwidth() / 2) + 2, (client.bufferheight() / 2) + 2, start_countdown, 0xFF000000, 0x00000000, 64, "Arial", "bold", "center", "middle" );
		gui.drawString( (client.bufferwidth()) / 2, client.bufferheight() / 2, start_countdown, 0xFFFFFF00, 0x00000000, 64, "Arial", "bold", "center", "middle" );
	end
	if start_countdown == 0 and racing == true then
		gui.drawString( (client.bufferwidth() / 2) + 2, (client.bufferheight() / 2) + 2, "GO", 0xFF000000, 0x00000000, 64, "Arial", "bold", "center", "middle" );
		gui.drawString( (client.bufferwidth()) / 2, client.bufferheight() / 2, "GO", 0xFFFFFF00, 0x00000000, 64, "Arial", "bold", "center", "middle" );
	end

	if start_countdown == 0 and racing == false then
		gui.drawString( (client.bufferwidth() / 2) + 2, (client.bufferheight() / 2) + 2, 'Waiting to Start...', 0xFF000000, 0x00000000, 18, "Arial", "bold", "center", "middle" );
		gui.drawString( (client.bufferwidth()) / 2, client.bufferheight() / 2, 'Waiting to Start...', 0xFFFFFF00, 0x00000000, 18, "Arial", "bold", "center", "middle" );
	end
end

function init()
	log_console('Initializing the race director')
	frame_count = 0
	effect_timer = 0
	racing = false
	connected = false
	activity.initalized = true
end

function activity.reset()
	activity.initalized = false
	log_console('Reset the Video boss')
	frame_count = 0
	racing = false
	connected = false
	start_countdown = 0
	effect_timer = -1
	prev_room = null
	is_frozen = false
	speed = 100
	time_left = '00:00:00'
	total_seconds = 0;
end

function activity.frame(frame_count)
	if prev_room ~= config.roomcode then
		prev_room = config.roomcode
		activity.initalized = false
		-- client.closerom()
		init()
		return
	end
	if activity.initalized == true and is_rom_loaded() then
		gui.clearGraphics()
		activity.drawGUI()
	end



	if session_init == false and comm.ws_receive(config.ws_id) ~= null and is_rom_loaded() then
		sendGameHash()
	end



	if activity.initalized == true and is_rom_loaded() and racing then

		if frame_count % 60 == 0 then
			total_seconds = total_seconds - 1  -- subtract one second
			h = math.floor(total_seconds / 3600)
			total_seconds = total_seconds - (h * 3600)
			m = math.floor(total_seconds / 60)
			s = total_seconds - (m * 60)
			time_left = string.format("%02d:%02d:%02d", h, m, s)       
			

			if start_countdown >= 0  and frame_count >= 240 then
				start_countdown = -1
			end

			client.speedmode(speed, false)
		end

		if effect_timer > 0 then
			-- if is_frozen then
			-- 	memory.write_u8(0x0376, 0x01, "RAM") -- keep pausing the game
			-- end
			effect_timer = effect_timer - 1
			
		else 
			if effect_timer == 0 then
				if speed ~= 100 then
					speed = 100
				end
				effect_timer = -1
			end
		end
		frame_count = frame_count + 1

	end


	if activity.initalized == false then
			prev_room = config.roomcode
			init()
	end
end

function activity.receive(data)
	if data.action == "countdown" then
		start_countdown = data.value
		-- print('Countdown ' .. start_countdown)
		return
	end
	if data.action == "start" then
		start_countdown = 0
		print('GO')
		-- client.reboot_core()
		racing = true
		frame_count = 1
		return
	end
	
	if data.selectedPlayers ~= null then
		if(table.contains(data.selectedPlayers, config.name)) then
			if data.action == "kill" then
				print('Kill')
				-- is_frozen = false
				-- memory.write_u8(0xb4, 0xC0, 'RAM')
			end
			if data.action == "pause" then
				print('Freezing')
				is_frozen = true
				effect_timer = tonumber(data.length) 
			end
			if data.action == "normal" then
				print('Normal')
				is_frozen = false
				effect_timer = -1
				speed = 100
			end
			if data.action == "pause" then
				print('Freezing')
				is_frozen = true
				effect_timer = tonumber(data.length) * 60
			end
			if data.action == "slow" then
				print('Slow')
				is_frozen = false
				speed = 50
				effect_timer = tonumber(data.length) * 60 / 2 -- Game time runs half as long since half the speed
			end
			if data.action == "fast" then
				print('Speed')
				is_frozen = false
				speed = 150
				effect_timer = tonumber(data.length) * 60 * 1.5 -- Game time runs 1.5 times as long since 1.5 times the speed
			end


			-- if data.action == "lives" then
			-- 	print('lives ' .. data.lives )
			-- 	local lives = memory.read_u8(0x0736, "RAM")
			-- 	if data.lives > 0 then
			-- 		memory.write_u8(0x04f2, 0x40, "RAM") 
			-- 	else 
			-- 		memory.write_u8(0x04f6, 0xd0, "RAM") 
			-- 	end
			-- 	lives = lives + data.lives
			-- 	if lives <= 0 then
			-- 		lives = 0
			-- 		memory.write_u8(0xb4, 0xC0, 'RAM')
			-- 	end
			-- 	memory.write_u8(0x0736, lives, "RAM")
			-- end

		end
	end
		
end




return activity