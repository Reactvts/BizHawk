local activity = {}
activity.title = "Video Armageddon"
activity.initalized = false


local start_countdown = 0


local effect_timer = -1
local right_padding = 125 
local prev_room = null
local is_frozen = false
local speed = 100
local last_song = 0
local last_score = 0
local level_finished = false
local time_left = '00:00:00'
local total_seconds = 0;
local players = {}
local player_count = null
local player_position = null
local game_mode = 'classic'





-- Item Variables

local itemChoices = {
	{'star',0,0}, 
	{'banana',1,0},
	{'greenShell',2,0},
	{'redShell',0,1},
	{'lightning',1,1},
	{'mushroom',2,1}}

local itemCounter = 1


local item_width = 26
local item_height = 18
local item_status = 'empty'
local item = null
local item_frame = 0
local next_item = null
local select_cooldown = 0
local item_effect = null
local item_effect_frame = 0
local shell_sound = false
local attack_queue = {

}

local alive = true

function isInvincible()
	return (memory.read_u8(0x0552, "RAM") + 
	memory.read_u8(0x0553, "RAM") + 
	memory.read_u8(0x055a, "RAM") +
	memory.read_u8(0x0559, "RAM") +
	memory.read_u8(0x05f3, "RAM")
	
) > 0 
end

function getItemByName(value)
    for i, item in ipairs(itemChoices) do
        if item[1] == value then
            return item
        end
    end
    return nil
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






function getInputs()
    local bin = ""
	local dec = memory.readbyte(0x17)
    while dec > 0 do
        bin = tostring(dec % 2) .. bin
        dec = math.floor(dec / 2)
    end
	while #bin < 8 do
        bin = "0" .. bin
    end
	local binArray = {}
    for digit in bin:gmatch(".") do
        table.insert(binArray, tonumber(digit))
    end
    return binArray
end







function activity.drawGUI()

	local x = client.bufferwidth() + right_padding 
	if start_countdown > 0 and racing == false then
		gui.drawString( (client.bufferwidth() / 2) + 2, (client.bufferheight() / 2) + 2, start_countdown, 0xFF000000, 0x00000000, 64, "Arial", "bold", "center", "middle" );
		gui.drawString( (client.bufferwidth()) / 2, client.bufferheight() / 2, start_countdown, 0xFFFFFF00, 0x00000000, 64, "Arial", "bold", "center", "middle" );
	end

	if start_countdown == 0 and racing == false then
		gui.drawString( (client.bufferwidth() / 2) + 2, (client.bufferheight() / 2) + 2, 'Waiting to Start...', 0xFF000000, 0x00000000, 18, "Arial", "bold", "center", "middle" );
		gui.drawString( (client.bufferwidth()) / 2, client.bufferheight() / 2, 'Waiting to Start...', 0xFFFFFF00, 0x00000000, 18, "Arial", "bold", "center", "middle" );
	end
	if start_countdown == -1 and racing == false then
		client.pause()
		local x = (client.bufferwidth() / 2) + 15;
		local y =  (client.bufferheight() / 2) - 10;

		
		gui.drawString( x-8, y+2, player_position, 0xFF000000, 0x00000000, 64, "Arial", "bold", "right", "middle" );
		gui.drawString( x-10, y, player_position, 0xFFFFFF00, 0x00000000, 64, "Arial", "bold", "right", "middle" );
		
		gui.drawString( x-24, y+6, '/', 0xFF000000, 0x00000000, 32, "Arial", "bold", "left", "middle" );
		gui.drawString( x-26, y+4, '/', 0xFFFFFF00, 0x00000000, 32, "Arial", "bold", "left", "middle" );
		
		gui.drawString( x-14, y+6, player_count, 0xFF000000, 0x00000000, 32, "Arial", "bold", "left", "middle" );
		gui.drawString( x-16, y+4, player_count, 0xFFFFFF00, 0x00000000, 32, "Arial", "bold", "left", "middle" );
	end
	if player_position ~= null and player_count > 0 then 
		local startPos = player_position - 5
		local endPos = player_position + 5

		if startPos < 1 then
			startPos = 1
			endPos = startPos + 10
		end
		if endPos > #players then
			endPos = #players
			startPos = endPos - 10
			if startPos < 1 then
				startPos = 1
			end
		end

		
		local youFontSize = 16
		local themFontSize = 11
		local yPos = (client.bufferheight() - (((themFontSize + 2) * (endPos - startPos - 1)) + youFontSize + 2)) / 2
		for i = startPos, endPos do

			local alpha = 0xFF000000
			
			if math.abs(i - player_position) > 3 then
				alpha = 0xAA000000  -- Change this to the desired alpha value
			end
			if math.abs(i - player_position) > 4 then
				alpha = 0x80000000  -- Change this to the desired alpha value
			end
			if math.abs(i - player_position) > 5 then
				alpha = 0x40000000  -- Change this to the desired alpha value
			end

			if startPos == 1 and i < player_position then
				alpha = 0xFF000000
			end

			if endPos == #players and i > player_position then
				alpha = 0xFF000000
			end

			if i == player_position then
				-- gui.drawString( x - 2, yPos + 1, string.upper(players[i]), 0xFFFFFF00, 0x00000000, youFontSize, "Arial", "bold", "right", "top" );
				gui.drawString( x - 3, yPos, string.upper(players[i]), 0xFFFFFF + alpha, 0x00000000, youFontSize, "Arial", "bold", "right", "top" );
				yPos = yPos + youFontSize
			else
				-- gui.drawString( x - 2, yPos + 1, string.upper(players[i]), 0xFFFFFF00, 0x00000000, themFontSize, "Arial", "bold", "right", "top" );
				gui.drawString( x - 3, yPos, string.upper(players[i]), 0xFFFFFF + alpha, 0x00000000, themFontSize, "Arial", "bold", "right", "top" );
				yPos = yPos + themFontSize
			end

		end
		-- gui.drawString( x - 24, 1, player_position, 0xFF000000, 0x00000000, 32, "Arial", "bold", "right", "top" );
		gui.drawString( x - 25, 0, player_position, 0xFFFFFFFF, 0x00000000, 32, "Arial", "bold", "right", "top" );
		-- gui.drawString( x - 32, 5, '/', 0xFF000000, 0x00000000, 16, "Arial", "bold", "left", "top" );
		gui.drawString( x - 33, 4, '/', 0xFFFFFFFF, 0x00000000, 16, "Arial", "bold", "left", "top" );
		-- gui.drawString( x - 27, 5, player_count, 0xFF000000, 0x00000000, 16, "Arial", "bold", "left", "top" );
		gui.drawString( x - 28, 4, player_count, 0xFFFFFFFF, 0x00000000, 16, "Arial", "bold", "left", "top" );

		gui.drawString( x, client.bufferheight() - 13, time_left, 0xFFFFFF00, 0x00000000, 16, "Arial", "bold", "right", "bottom" );
	end
end

function init()
	log_console('Initializing the Video boss')
	frame_count = 0
	effect_timer = 0
	preHexScore = 0
	players = {}
	player_count = null
	player_position = null
	racing = false
	connected = false
	print(config.games.mario3)
	loadGame(config.games.mario3)
end

function activity.reset()
	client.closerom()
	log_console('Reset the Video boss')
	frame_count = 0
	effect_timer = 0
	preHexScore = 0
	players = {}
	player_count = null
	player_position = null
	racing = false
	connected = false

	start_countdown = 0

	effect_timer = -1
	right_padding = 125 
	prev_room = null
	is_frozen = false
	speed = 100
	last_song = 0
	last_score = 0
	level_finished = false
	time_left = '00:00:00'
	total_seconds = 0;
	players = {}
	player_count = null
	player_position = null
	
	itemCounter = 1
	item_status = 'empty'
	item = null
	item_frame = 0
	next_item = null
	select_cooldown = 0
	item_effect = null
	item_effect_frame = 0
	shell_sound = false
	attack_queue = {}
	alive = true

end

function activity.frame(frame_count)
	if prev_room ~= config.roomcode then
		prev_room = config.roomcode
		activity.initalized = false
		client.closerom()
		init()
		return
	end
	if activity.initalized == true and is_rom_loaded() then
		gui.clearGraphics()
		activity.drawGUI()
	end



	if activity.initalized == true and is_rom_loaded() and racing then

		if frame_count % 60 == 0 then
			-- if(total_seconds <= 0) then
			-- 	start_countdown = -1
			-- 	racing = false
				
			-- 	return 
			-- end
			total_seconds = total_seconds - 1  -- subtract one second
			h = math.floor(total_seconds / 3600)
			total_seconds = total_seconds - (h * 3600)
			m = math.floor(total_seconds / 60)
			s = total_seconds - (m * 60)
			time_left = string.format("%02d:%02d:%02d", h, m, s)       
		end
		
		client.speedmode(speed, false)

		local input = memory.readbyte(0x17)
		if select_cooldown > 0 then
			select_cooldown = select_cooldown - 1
		end

		if memory.read_u8(0x04e4, "RAM") == 0x01 and alive == true  then
			alive = false
			local send_string = string.format('{"event":"client-message_sent","data":{"id":"%s","clientId":"%s","version":"%s","action":"died"},"channel":"presence-%s-game"}',
			config.user_id, config.name, config.version, config.roomcode)
			comm.ws_send(config.ws_id, send_string, true)
		end

		if alive == false then
			if memory.read_u8(0x04e4, "RAM") ~= 0x01 then
				alive = true
			else 
				alive = false
			end 
			
		end


		if input ~= 0 and game_mode == '89' then
			local inputs = decToBin(input)
			if inputs[3] == 1 and select_cooldown == 0 then
				if item_status == 'empty' then
					local coins = memory.read_u8(0x7da2, "System Bus")
					if coins >= 10 then
						coins = coins - 10
						memory.write_u8(0x7da2, coins, "System Bus")
						item_status = 'spin'
						
						local send_string = string.format('{"event":"client-message_sent","data":{"id":"%s","clientId":"%s","version":"%s","action":"buy"},"channel":"presence-%s-game"}',
						config.user_id, config.name, config.version, config.roomcode)
						comm.ws_send(config.ws_id, send_string , true)

						item_frame = 90
						gui.clearGraphics()
						client.PlaySound('./Reactvts/Activities/assets/itemBox.wav', config.volume, 1)
					end
				elseif item_status == 'hasitem' then
					-- print(item[1])
					if(item[1] == 'star') then
						memory.writebyte(0x03f2, 0x01)
					elseif item[1] == 'mushroom' then
						speed = 150
						item_effect = 'mushroom'
						client.PlaySound('./Reactvts/Activities/assets/boost.wav', config.volume, 1)
						item_effect_frame = 60 * 15
					elseif item[1] == 'banana' and #attack_queue > 0 and (attack_queue[1].name == 'greenShell' or attack_queue[1].name == 'redShell') then
						client.PlaySound('./Reactvts/Activities/assets/shellbounce.wav', config.volume, 1)
						table.remove(attack_queue, 1)
					else
						local send_string = string.format('{"event":"client-message_sent","data":{"id":"%s","clientId":"%s","version":"%s","action":"throw","item":"%s"},"channel":"presence-%s-game"}',
						config.user_id, config.name, config.version, item[1], config.roomcode)
						comm.ws_send(config.ws_id, send_string , true)
						client.PlaySound('./Reactvts/Activities/assets/fire.wav', config.volume, 1)
					end
					item_status = 'empty'
					gui.clearGraphics()
				end
				select_cooldown = 30
			end
		end
		if game_mode == '89' then
	
			gui.drawImageRegion('./Activities/assets/itemBox.png', 0, 0, item_width, item_height * 2, 1, 1, item_width, item_height * 2)
			if item_status == 'spin' then
				item_frame = item_frame - 1
				
				local x = (frame_count % 3) * item_width
				local y = 0
				if(frame_count % 6 >= 4) then
					y = item_height
				end
				gui.drawImageRegion('./Activities/assets/items.png', x, y, item_width, item_height, 1, 1, item_width, item_height)
				if item_frame <= 0 then
					item_status = 'gotitem'
				end
			end
	
			if item_status == 'gotitem' and next_item == null then
				item_status = 'hasitem'
				item = getItemByName('banana')
				next_item = null
			end

			if item_status == 'gotitem' and next_item ~= null then
				item_status = 'hasitem'
				-- local next_item = itemChoices[math.random(1, 6)]
				-- next_item = itemChoices[(itemCounter % 6) + 1]  
				-- itemCounter = itemCounter + 1
				
				item = getItemByName(next_item)
				next_item = null
			end
			if item_status == 'hasitem' then
				local x = item[2] * item_width
				local y = item[3] * item_height
				gui.drawImageRegion('./Activities/assets/items.png', x, y, item_width, item_height, 1, 1, item_width, item_height)
			end

			if item_effect ~= null then
				item_effect_frame = item_effect_frame - 1

				if item_effect_frame <= 0 then
					if(item_effect == 'mushroom') then
						speed = 100
					end
					if(item_effect == 'lightning') then
						speed = 100
						memory.write_u8(0x0016, 0x00, "RAM")
					end
					item_effect = null
				end
			end

			if #attack_queue > 0 then
				local attack = attack_queue[1]
				local y = client.bufferheight() / 2 - item_height / 2

				local attackers = attack.attacker
				local attacker_font_size = 12

				if #attack_queue > 1 then
					attackers = attackers .. ' +' .. (#attack_queue - 1)
				end
				if attack.name == 'lightning' then

				elseif attack.name == 'banana' then
					local x = client.bufferwidth()
					gui.drawString( x + 2 , y - 1, string.upper(attackers), 0xFF000000, 0x00000000, attacker_font_size, "Arial", "bold", "right", "bottom" );
					gui.drawString( x + 2 , y + 1, string.upper(attackers), 0xFF000000, 0x00000000, attacker_font_size, "Arial", "bold", "right", "bottom" );
					gui.drawString( x + 0 , y + 1, string.upper(attackers), 0xFF000000, 0x00000000, attacker_font_size, "Arial", "bold", "right", "bottom" );
					gui.drawString( x + 0 , y - 1, string.upper(attackers), 0xFF000000, 0x00000000, attacker_font_size, "Arial", "bold", "right", "bottom" );
					gui.drawString( x + 1, y, string.upper(attackers), 0xFFFFFFFF, 0x00000000, attacker_font_size, "Arial", "bold", "right", "bottom" );
					
					local x = client.bufferwidth() - item_width
					gui.drawImageRegion('./Activities/assets/items.png', itemChoices[attack.itemIndex][2] * item_width, itemChoices[attack.itemIndex][3] * item_height, item_width, item_height, x, y, item_width, item_height)
					if shell_sound == false then
						client.PlaySound('./Reactvts/Activities/assets/shell.wav', config.volume, 1)
						shell_sound = true
					end
				else 
					local x = 0
					gui.drawString( x + 2 , y - 1, string.upper(attackers), 0xFF000000, 0x00000000, attacker_font_size, "Arial", "bold", "left", "bottom" );
					gui.drawString( x + 0 , y + 1, string.upper(attackers), 0xFF000000, 0x00000000, attacker_font_size, "Arial", "bold", "left", "bottom" );
					gui.drawString( x + 0 , y - 1, string.upper(attackers), 0xFF000000, 0x00000000, attacker_font_size, "Arial", "bold", "left", "bottom" );
					gui.drawString( x + 2 , y + 1, string.upper(attackers), 0xFF000000, 0x00000000, attacker_font_size, "Arial", "bold", "left", "bottom" );
					gui.drawString( x + 1, y, string.upper(attackers), 0xFFFFFFFF, 0x00000000, attacker_font_size, "Arial", "bold", "left", "bottom" );
					gui.drawImageRegion('./Activities/assets/items.png', itemChoices[attack.itemIndex][2] * item_width, itemChoices[attack.itemIndex][3] * item_height, item_width, item_height, x , y, item_width, item_height)
					if shell_sound == false then
						client.PlaySound('./Reactvts/Activities/assets/shell.wav', config.volume, 1)
						shell_sound = true
					end
				end
				

				if attack.frames == 0 then
					shell_sound = false
					if isInvincible() == false then
						if attack.name == 'lightning' then
							item_effect = 'lightning'
							speed = 50
							item_effect_frame = 60 * 2
							memory.write_u8(0x0016, 0x01, "RAM")
							item_status = 'empty'
							item = null
							client.PlaySound('./Reactvts/Activities/assets/lightning.wav', config.volume, 1)
						end
						-- if attack.name == 'redShell' then
						-- 	if memory.read_u8(0x00ed, "RAM") > 1 then
						-- 		memory.write_u8(0x0578, 01, "RAM") -- Make Small
						-- 		client.PlaySound('./Reactvts/Activities/assets/spin.wav', config.volume, 1)
						-- 		memory.write_u8(0x04f1, 0x10, "RAM")
						-- 		memory.write_u8(0x0551, 0x26, "RAM") -- shrink animation
						-- 		memory.write_u8(0x0552, 0x70, "RAM") --iframes
						-- 	else 
						-- 		memory.write_u8(0xb4, 0xC0, 'RAM') -- Kill
						-- 	end
						-- end
						if attack.name == 'greenShell' or attack.name == 'redShell' then
							local currentPowerup = memory.read_u8(0x00ed, "RAM")

							if attack.name == 'greenShell' and memory.read_u8(0x00d8) ~= 0 then -- jumping over item
								local send_string = string.format('{"event":"client-message_sent","data":{"id":"%s","clientId":"%s","version":"%s","action":"throw","item":"%s"},"channel":"presence-%s-game"}',
								config.user_id, config.name, config.version, 'greenShell', config.roomcode)
								comm.ws_send(config.ws_id, send_string , true)
							else 
								if currentPowerup > 0 then
									client.PlaySound('./Reactvts/Activities/assets/spin.wav', config.volume, 1)
									memory.write_u8(0x04f1, 0x10, "RAM")
									if currentPowerup == 1 then
										memory.write_u8(0x0551, 0x26, "RAM") -- shrink animation
										memory.write_u8(0x0578, 1, "RAM") -- Make Smaller
									else 
										memory.write_u8(0x0554, 0x10, "RAM") -- poof animation
										memory.write_u8(0x0578, 2, "RAM") -- Make Smaller
									end
									memory.write_u8(0x0552, 0x70, "RAM") --iframes
								else 
									-- memory.write_u8(0xb4, 0xC0, 'RAM') -- Kill
									client.PlaySound('./Reactvts/Activities/assets/spin.wav', config.volume, 1)
									memory.write_u8(0x0554, 0x50, "RAM") -- poof animation
								end
							end
						end
						if attack.name == 'banana' then
							if memory.read_u8(0x00d8) ~= 0 then -- jumping over item
								local send_string = string.format('{"event":"client-message_sent","data":{"id":"%s","clientId":"%s","version":"%s","action":"throw","item":"%s"},"channel":"presence-%s-game"}',
								config.user_id, config.name, config.version, 'banana', config.roomcode)
								comm.ws_send(config.ws_id, send_string , true)
							else 
								client.PlaySound('./Reactvts/Activities/assets/spin.wav', config.volume, 1)
								memory.write_u8(0x0554, 0x50, "RAM") -- poof animation
							end
						end
					end
					table.remove(attack_queue, 1)
				else
					if(memory.read_u8(0x0376, "RAM") == 0) then -- if not paused
						attack.frames = attack.frames - 1
					end
				end
			end
			
			if effect_timer > 0 then
				effect_timer = effect_timer - 1
				if is_frozen then
					memory.write_u8(0x0376, 0x01, "RAM") -- keep pausing the game
				end
			else 
				if effect_timer == 0 then
					if(is_frozen) then
						-- print('Unfreezing')
						memory.write_u8(0x04f5, last_song, "RAM")
						memory.write_u8(0x0376, 0x00, "RAM")
					end
					is_frozen = false
					
					
					effect_timer = -1
				end
			end
		end

	end



	if frame_count % clamp(30, #players * 10, 2 * 60) == 0 and activity.initalized == true and is_rom_loaded() then
		if racing == false then

		else
			hexScore = '0x' .. string.format("%02x", memory.read_u8(0x0715, "RAM")) .. string.format("%02x", memory.read_u8(0x0716, "RAM")) .. string.format("%02x", memory.read_u8(0x0717, "RAM"))		
			if(hexScore ~= preHexScore) then
				preHexScore = hexScore
				score = tonumber(hexScore)
				-- if score < last_score then -- loaded savestate
				-- 	memory.write_u8(0x0016, 0x01, "RAM")
				-- 	memory.write_u8(0x04f4, 0xf0, "RAM")
				-- 	memory.write_u8(0x0559, 0xff, "RAM")
				-- 	memory.write_u8(0x0715, 0x00, "RAM")
				-- 	memory.write_u8(0x0716, 0x00, "RAM")
				-- 	memory.write_u8(0x0717, 0x00, "RAM")					
				-- end
				last_score = score
				local send_string = string.format('{"event":"client-message_sent","data":{"id":"%s","clientId":"%s","version":"%s","action":"update","score":"%s"},"channel":"presence-%s-game"}',
				config.user_id, config.name, config.version, score * 10, config.roomcode)
				comm.ws_send(config.ws_id, send_string , true)
			end	


			-- local inputs = getInputs()
			-- if inputs[3] == 1 then

			-- end


			-- if level_finished == false and (memory.read_u8(0x04e4, "RAM") == 0x20 or memory.read_u8(0x04e4, "RAM") == 0x04) then
			-- 	level_finished = true
			-- 	powerup = memory.read_u8(0x00ed, "RAM") + 1
			-- end
			-- if level_finished == true and memory.read_u8(0x7dfc, "System Bus") == 0x16 then
			-- 	print('loading state')
			-- 	client.pause()
			-- 	local score1 = memory.read_u8(0x0715, "RAM")
			-- 	local score2 = memory.read_u8(0x0716, "RAM")
			-- 	local score3 = memory.read_u8(0x0717, "RAM")
			-- 	local coins = memory.read_u8(0x7da2, "System Bus")
			-- 	local lives = memory.read_u8(0x0736, "RAM")
			-- 	level_finished = false
			-- 	savestate.load('./race.state')
			-- 	print('power up ' .. powerup)
			-- 	memory.write_u8(0x0715, score1, "RAM")
			-- 	memory.write_u8(0x0716, score2, "RAM")
			-- 	memory.write_u8(0x0717, score3, "RAM")
			-- 	memory.write_u8(0x7da2, coins, "System Bus")
			-- 	memory.write_u8(0x0736, lives, "RAM")
			-- 	memory.write_u8(0x0578, powerup, "RAM")
			-- 	speed = speed * 1.25
			-- 	client.speedmode(speed, false)
			-- 	client.unpause()
			-- end
		end
    end
	if activity.initalized == false then
			prev_room = config.roomcode
			init()
	end
end

function activity.receive(data)
	if data.action == "standings" then
		print(data)
		game_mode = data.mode
		time_left = data.time
		h, m, s = data.time:match('(%d+):(%d+):(%d+)')
		total_seconds = h * 3600 + m * 60 + s
		players = split(data.players,'|')
		for key, value in pairs(players) do
			if value == config.name then
				player_position = key
			end
			player_count = key
		end
		

		if data.final == true then
			racing = false
			start_countdown = -1
		end
	return
	end
	if data.action == "countdown" then
		start_countdown = data.value
		print('Countdown ' .. start_countdown)
	end
	if data.action == "start" then
		if savestate.load('./Saves/Mario3.state') then
			racing = true
		else 
			print('Failed to load state')
		end
		return

	end
	if game_mode == '89' then

	
		if(data.name == 'all' or data.name == config.name) then
			if data.action == "memory" then
				client.pause()
				for key, value in pairs(data.memory) do
					-- print(key, value[1], value[2], tonumber(value[1],16))
					-- Remove leading '0x' from the values if present
					value[1] = string.gsub(value[1], "^0x", "")
					value[2] = string.gsub(value[2], "^0x", "")
					-- Write to memory
					memory.write_u8(tonumber(value[1],16), tonumber(value[2],16), value[3])
					if(value[1] == "0578") then -- If Powerup, play powerup sound
						-- print(memory.read_u8(0x00e1, "RAM") .. ' > ' .. tonumber(value[2],16) )
						if(memory.read_u8(0x00ed, "RAM") + 1 > tonumber(value[2],16) and tonumber(value[2],16) < 3) then
							memory.write_u8(0x04f1, 0x10, "RAM")
						else
							memory.write_u8(0x04f2, 0x20, "RAM") 
						end
						
					end
				end
				client.unpause()
			end
		
			if data.action == "kill" then
				print('Kill')
				is_frozen = false
				memory.write_u8(0xb4, 0xC0, 'RAM')
			end
			if data.action == "pause" then
				print('Freezing')
				is_frozen = true
				last_song = memory.read_u8(0x04e5, "RAM")
				memory.write_u8(0x04f5, 0x0c, "RAM")
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
			if data.action == "lives" then
				print('lives ' .. data.lives )
				local lives = memory.read_u8(0x0736, "RAM")
				if data.lives > 0 then
					memory.write_u8(0x04f2, 0x40, "RAM") 
				else 
					memory.write_u8(0x04f6, 0xd0, "RAM") 
				end
				lives = lives + data.lives
				if lives <= 0 then
					lives = 0
					memory.write_u8(0xb4, 0xC0, 'RAM')
				end
				memory.write_u8(0x0736, lives, "RAM")
			end

			if data.action == "get" then
				-- print('getItem' .. data.item)
				next_item = data.item
			end

			if data.action == "item" and (data.name == config.name or data.name == 'all') then

				for i, attack in ipairs(attack_queue) do
					if attack['uid'] == data.uid then
						print('Already in queue')
						return
					end
				end
								
				if data.item == 'banana' then
					table.insert(attack_queue, {["name"] = 'banana', ['attacker'] = data.attacker, ['uid'] = data.uid, ["itemIndex"] = 2 , ["frames"] = 60 * 3})
				end
				if data.item == 'greenShell' then
					table.insert(attack_queue, {["name"] = 'greenShell', ['attacker'] = data.attacker, ['uid'] = data.uid, ["itemIndex"] = 3 , ["frames"] = 60 * 3})
				end
				if data.item == 'redShell' then
					table.insert(attack_queue, {["name"] = 'redShell', ['attacker'] = data.attacker, ['uid'] = data.uid, ["itemIndex"] = 4 , ["frames"] = 60 * 3})
				end
				
				if data.item == 'lightning' and data.attacker ~= config.name then
					table.insert(attack_queue, {["name"] = 'lightning', ['attacker'] = data.attacker, ['uid'] = data.uid, ["itemIndex"] = 5 , ["frames"] = 1})
				end
			end
		end
	end
end




return activity