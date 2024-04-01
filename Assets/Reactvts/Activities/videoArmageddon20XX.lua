local activity = {}
activity.title = "Video Armageddon"
activity.initalized = false


GAMES_FOLDER = '.'
effect_timer = -1

prev_room = null
is_frozen = false
speed = 100
last_song = 0
score = 0
last_score = 0
level_finished = false
time_left = 0
players = {}
player_count = null
player_position = null
kill_count = 0
right_padding = 75
enemyMemory = {
	[0] = false,
	[1] = false,
	[2] = false,
	[3] = false,
	[4] = false,
	[5] = false,
	[6] = false,
	[7] = false,
	[8] = false, 
	[9] = false,
	[10] = false,
	[11] = false,
	[12] = false,
	[13] = false,
	[14] = false,
	[15] = false
}


-- mm3 

progress = {}



-- Item Variables

local itemChoices = {
	{'star',0,0}, 
	{'banana',1,0},
	{'greenShell',2,0},
	{'redShell',0,1},
	{'lightning',1,1},
	{'mushroom',2,1}}

local itemCounter = 1


item_width = 26
item_height = 18
local item_status = 'empty'
local item = null
local item_frame = 0
next_item = null
local select_cooldown = 0
local item_effect = null
local item_effect_frame = 0
local shell_sound = false
local attack_queue = {

}

alive = true

local function isInvincible()
	return (memory.read_u8(0x0552, "RAM") + 
	memory.read_u8(0x0553, "RAM") + 
	memory.read_u8(0x055a, "RAM") +
	memory.read_u8(0x0559, "RAM") +
	memory.read_u8(0x05f3, "RAM")
	
) > 0 
end

local function getItemByName(value)
    for i, item in ipairs(itemChoices) do
        if item[1] == value then
            return item
        end
    end
    return nil
end

local function split (inputstr, sep)
	if sep == nil then
			sep = "%s"
	end
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
			table.insert(t, str)
	end
	return t
end



local function decToBin(dec)
    local bin = ""
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

local function getInputs()
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

function log_console(msg)
	print(msg)
end


local function file_exists(f)
	local p = io.open(f, 'r')
	if p == nil then return false end
	io.close(p)
	return true
end

function is_rom_loaded()
	return emu.getsystemid() ~= 'NULL'
end


log_console('Waking up the video boss')

local function load_game(g)
	log_console('load_game(' ..  g .. ') me')
	-- local filename = GAMES_FOLDER .. '/' .. g
	local filename = g
	if not file_exists(filename) then
		log_console('ROM ' .. filename .. ' not found', g)
		return false
	end

	client.openrom(filename)

	if is_rom_loaded() then
		log_console(string.format('ROM loaded: %s "%s" (%s)', emu.getsystemid(), gameinfo.getromname(), gameinfo.getromhash()))
		client.reboot_core( );
		activity.initalized = true
		client.enablerewind(false)
		client.SetGameExtraPadding(0,0,right_padding,0)
		local sendString = string.format('{"event":"client-message_sent","data":{"id":"%s","clientId":"%s","action":"start"},"channel":"presence-%s"}',
		config.user_id, config.name, config.roomcode)
		comm.ws_send(config.ws_id, sendString , true)
		racing = true
		return true
	else
		log_console(string.format('Failed to open ROM "%s"', g))
		return false
	end

end

local function drawGUI()

	local x = client.bufferwidth() + right_padding 
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

		
		local youFontSize = 22
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

local function init()
	log_console('Initializing the video boss')
	frame_count = 0
	effect_timer = 0
	preHexScore = 0
	players = {}
	player_count = null
	player_position = null
	racing = false
	connected = false
	load_game('./Roms/megaman3.nes')
end

function activity.frame(frame_count, config)
	if prev_room ~= config.roomcode then
		prev_room = config.roomcode
		activity.initalized = false
		client.closerom()
		init()
		return
	end
	if activity.initalized == true and is_rom_loaded() then
		gui.clearGraphics()
		drawGUI()

		if memory.read_u8(0x0022, "RAM") > 0 and memory.read_u8(0x0380, "RAM") > 0 then
			local address = memory.read_u8(0x0022, "RAM") .. '|' .. memory.read_u8(0x0380, "RAM")
			if progress[address] == null then
				progress[address] = true
				score = score + 100
				print('score ' .. score)
			end
		end

	end

	if activity.initalized == true and is_rom_loaded() and racing then
		
		client.speedmode(speed, false)

		local input = memory.readbyte(0x16)
		if select_cooldown > 0 then
			select_cooldown = select_cooldown - 1
		end

		-- if memory.read_u8(0x04e4, "RAM") == 0x01 and alive == true  then
		-- 	alive = false
		-- 	local sendString = string.format('{"event":"client-message_sent","data":{"id":"%s","clientId":"%s","action":"died"},"channel":"presence-%s"}',
		-- 	config.user_id, config.name, config.roomcode)
		-- 	comm.ws_send(config.ws_id, sendString , true)
		-- end

		if alive == false then
			if memory.read_u8(0x04e4, "RAM") ~= 0x01 then
				alive = true
			else 
				alive = false
			end 
			
		end


		if input ~= 0 then
			local inputs = decToBin(input)
			if inputs[3] == 1 then
				if item_status == 'empty' then
				
				elseif item_status == 'hasitem' then
					print(item[1])
					if(item[1] == 'star') then
						-- memory.writebyte(0x03f2, 0x01)
					elseif item[1] == 'mushroom' then
						speed = 150
						item_effect = 'mushroom'
						client.PlaySound('./Reactvts/Activities/assets/boost.wav', config.volume, 1)
						item_effect_frame = 60 * 15
					elseif item[1] == 'banana' and #attack_queue > 0 and (attack_queue[1].name == 'greenShell' or attack_queue[1].name == 'redShell') then
						client.PlaySound('./Reactvts/Activities/assets/shellbounce.wav', config.volume, 1)
						table.remove(attack_queue, 1)
					else
						local sendString = string.format('{"event":"client-message_sent","data":{"id":"%s","clientId":"%s","action":"throw","item":"%s"},"channel":"presence-%s"}',
						config.user_id, config.name, item[1], config.roomcode)
						comm.ws_send(config.ws_id, sendString , true)
						client.PlaySound('./Reactvts/Activities/assets/fire.wav', config.volume, 1)
					end
					item_status = 'empty'
					gui.clearGraphics()
				end
				select_cooldown = 30
			end
		end
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

		



		if item_status == 'gotitem' and next_item ~= null then
			item_status = 'hasitem'
			-- local next_item = itemChoices[math.random(1, 6)]
			-- next_item = itemChoices[(itemCounter % 6) + 1]  
			-- itemCounter = itemCounter + 1
			
			item = getItemByName(next_item)
			next_item = null
			kill_count = 0
			print('reset kill count')
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
				end
				item_effect = null
			end
		end

		if #attack_queue > 0 then
			local attack = attack_queue[1]
			local y = client.bufferheight() / 2 - item_height / 2

			if attack.name == 'lightning' then

			elseif attack.name == 'banana' then
				local x = client.bufferwidth() - item_width
				gui.drawImageRegion('./Activities/assets/items.png', itemChoices[attack.itemIndex][2] * item_width, itemChoices[attack.itemIndex][3] * item_height, item_width, item_height, x, y, item_width, item_height)
				if shell_sound == false then
					client.PlaySound('./Reactvts/Activities/assets/shell.wav', config.volume, 1)
					shell_sound = true
				end
			else 
				local x = 0
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
							local sendString = string.format('{"event":"client-message_sent","data":{"id":"%s","clientId":"%s","action":"throw","item":"%s"},"channel":"presence-%s"}',
							config.user_id, config.name, 'greenShell', config.roomcode)
							comm.ws_send(config.ws_id, sendString , true)
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
							local sendString = string.format('{"event":"client-message_sent","data":{"id":"%s","clientId":"%s","action":"throw","item":"%s"},"channel":"presence-%s"}',
							config.user_id, config.name, 'banana', config.roomcode)
							comm.ws_send(config.ws_id, sendString , true)
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
		
		-- if effect_timer > 0 then
		-- 	effect_timer = effect_timer - 1
		-- 	if is_frozen then
		-- 		memory.write_u8(0x0376, 0x01, "RAM") -- keep pausing the game
		-- 	end
		-- else 
		-- 	if effect_timer == 0 then
		-- 		if(is_frozen) then
		-- 			print('Unfreezing')
		-- 			memory.write_u8(0x04f5, last_song, "RAM")
		-- 			memory.write_u8(0x0376, 0x00, "RAM")
		-- 		end
		-- 		is_frozen = false
				
				
		-- 		effect_timer = -1
		-- 	end
		-- end

	end



	if frame_count % math.floor(2 + (#players)) == 0 and activity.initalized == true and is_rom_loaded() then
		if racing == false then
			-- if memory.read_u8(0x7b51, "System Bus") == 55 and memory.read_u8(0x7b50, "System Bus") == 114 then 
			-- 	racing = true
			-- 	-- print('savestate level')
			-- 	-- savestate.save('./race.state')
			-- 	local sendString = string.format('{"event":"client-message_sent","data":{"id":"%s","clientId":"%s","action":"start"},"channel":"presence-%s"}',
			-- 	config.user_id, config.name, config.roomcode)
			-- 	comm.ws_send(config.ws_id, sendString , true)
			-- end
		else
			
			if(score ~= last_score) then
				print('sending score ' .. score)
				last_score = score
				local sendString = string.format('{"event":"client-message_sent","data":{"id":"%s","clientId":"%s","action":"update","score":"%s"},"channel":"presence-%s"}',
				config.user_id, config.name, score .. '0', config.roomcode)
				comm.ws_send(config.ws_id, sendString , true)
			end	

			-- check for kills
			local enemiesOnScreen = 0
			for i = 0x0,0xf  do
				if memory.read_u8(0x0310 + i, "RAM") == 0x81 then
					enemiesOnScreen = enemiesOnScreen + 1
				end
		

				if memory.read_u8(0x0310 + i, "RAM") == 0x81 and memory.read_u8(0x0330 + i, "RAM") == 0x7a  then
					if enemyMemory[i] == false then
						enemyMemory[i] = true
						
						kill_count = kill_count + 1
						print('kill ' .. kill_count)
						if kill_count == 10 then
							item_status = 'spin'
							print('spin')
							local sendString = string.format('{"event":"client-message_sent","data":{"id":"%s","clientId":"%s","action":"buy"},"channel":"presence-%s"}',
							config.user_id, config.name, config.roomcode)
							comm.ws_send(config.ws_id, sendString , true)

							item_frame = 90
							gui.clearGraphics()
							client.PlaySound('./Reactvts/Activities/assets/itemBox.wav', config.volume, 1)
						end
					end
				else
					enemyMemory[i] = false
				end
			end
			-- if enemiesOnScreen > 0 then
			-- 	print ('enemiesOnScreen ' .. enemiesOnScreen)
			-- end





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

function activity.receive(data, config)
	
	if data.action == "standings" then
		time_left = data.time
		players = split(data.players,'|')
		for key, value in pairs(players) do
			if value == config.name then
				player_position = key
			end
			player_count = key
		end
	return
	end
	if(data.name == 'all' or data.name == config.name) then

		-- if data.action == "memory" then
		-- 	client.pause()
		-- 	for key, value in pairs(data.memory) do
		-- 		print(key, value[1], value[2], tonumber(value[1],16))
		-- 		-- Remove leading '0x' from the values if present
		-- 		value[1] = string.gsub(value[1], "^0x", "")
		-- 		value[2] = string.gsub(value[2], "^0x", "")
		-- 		-- Write to memory
		-- 		memory.write_u8(tonumber(value[1],16), tonumber(value[2],16), value[3])
		-- 		if(value[1] == "0578") then -- If Powerup, play powerup sound
		-- 			print(memory.read_u8(0x00e1, "RAM") .. ' > ' .. tonumber(value[2],16) )
		-- 			if(memory.read_u8(0x00ed, "RAM") + 1 > tonumber(value[2],16) and tonumber(value[2],16) < 3) then
		-- 				memory.write_u8(0x04f1, 0x10, "RAM")
		-- 			else
		-- 				memory.write_u8(0x04f2, 0x20, "RAM") 
		-- 			end
					
		-- 		end
		-- 	end
		-- 	client.unpause()
		-- end
	
		-- if data.action == "kill" then
		-- 	print('Kill')
		-- 	is_frozen = false
		-- 	memory.write_u8(0xb4, 0xC0, 'RAM')
		-- end
		-- if data.action == "pause" then
		-- 	print('Freezing')
		-- 	is_frozen = true
		-- 	last_song = memory.read_u8(0x04e5, "RAM")
		-- 	memory.write_u8(0x04f5, 0x0c, "RAM")
		-- 	effect_timer = tonumber(data.length) * 60
		-- end
		-- if data.action == "slow" then
		-- 	print('Slow')
		-- 	is_frozen = false
		-- 	speed = 50
		-- 	effect_timer = tonumber(data.length) * 60 / 2 -- Game time runs half as long since half the speed
		-- end
		-- if data.action == "fast" then
		-- 	print('Speed')
		-- 	is_frozen = false
		-- 	speed = 150
		-- 	effect_timer = tonumber(data.length) * 60 * 1.5 -- Game time runs 1.5 times as long since 1.5 times the speed
		-- end
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

		-- if data.action == "get" then
		-- 	print('getItem' .. data.item)
		-- 	next_item = data.item
		-- end

		-- if data.action == "item" and (data.name == config.name or data.name == 'all') then
		-- 	if data.item == 'banana' then
		-- 		table.insert(attack_queue, {["name"] = 'banana', ["itemIndex"] = 2 , ["frames"] = 60 * 3})
		-- 	end
		-- 	if data.item == 'greenShell' then
		-- 		table.insert(attack_queue, {["name"] = 'greenShell', ["itemIndex"] = 3 , ["frames"] = 60 * 3})
		-- 	end
		-- 	if data.item == 'redShell' then
		-- 		table.insert(attack_queue, {["name"] = 'redShell', ["itemIndex"] = 4 , ["frames"] = 60 * 3})
		-- 	end
			
		-- 	if data.item == 'lightning' and data.attacker ~= config.name then
		-- 		table.insert(attack_queue, {["name"] = 'lightning', ["itemIndex"] = 5 , ["frames"] = 1})
		-- 	end
		-- end
	end
end




return activity