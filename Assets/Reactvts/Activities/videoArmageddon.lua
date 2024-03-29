local activity = {}
activity.title = "Video Armageddon"
activity.initalized = false


GAMES_FOLDER = '.'
effectTimer = -1

prevRoom = null
is_frozen = false
speed = 100
last_song = 0
level_finished = false

-- Item Variables

local itemChoices = {
	{'star',0,0}, 
	{'banana',1,0},
	{'greenShell',2,0},
	{'redShell',0,1},
	{'lightning',1,1},
	{'mushroom',2,1}}

local itemCounter = 1


itemWidth = 26
itemHeight = 18
local itemStatus = 'empty'
local item = null
local itemFrame = 0
nextItem = null
local selectCooldown = 0
local itemEffect = null
local itemEffectFrame = 0
local shellSound = false
local attackQueue = {

}

alive = true

function isInvincible()
	return (memory.read_u8(0x0552, "RAM") + 
	memory.read_u8(0x0553, "RAM") + 
	memory.read_u8(0x055a, "RAM") +
	memory.read_u8(0x0559, "RAM") 	
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



function decToBin(dec)
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

function log_console(msg)
	print(msg)
end


function file_exists(f)
	local p = io.open(f, 'r')
	if p == nil then return false end
	io.close(p)
	return true
end

function is_rom_loaded()
	return emu.getsystemid() ~= 'NULL'
end


log_console('Waking up the video boss')

function load_game(g)
	log_console('load_game(' ..  g .. ')')
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

		return true
	else
		log_console(string.format('Failed to open ROM "%s"', g))
		return false
	end

end

function init()
	log_console('Initializing the video boss')
	frame_count = 0
	effectTimer = 0
	preHexScore = 0
	racing = false
	connected = false
	load_game('./Roms/Mario3.nes')
end

function activity.frame(frame_count, config)
	if prevRoom ~= config.roomcode then
		prevRoom = config.roomcode
		activity.initalized = false
		client.closerom()
		init()
		return
	end
	if activity.initalized == true and is_rom_loaded() and racing then
		gui.clearGraphics()

		local input = memory.readbyte(0x17)
		if selectCooldown > 0 then
			selectCooldown = selectCooldown - 1
		end

		if memory.read_u8(0x04e4, "RAM") == 0x01 and alive == true  then
			alive = false
			local sendString = string.format('{"event":"client-message_sent","data":{"id":"%s","clientId":"%s","action":"died"},"channel":"presence-%s"}',
			config.user_id, config.name, config.roomcode)
			comm.ws_send(config.ws_id, sendString , true)
		end

		if alive == false then
			if memory.read_u8(0x04e4, "RAM") ~= 0x01 then
				alive = true
			else 
				return
			end 
			
		end


		if input ~= 0 then
			local inputs = decToBin(input)
			if inputs[3] == 1 and selectCooldown == 0 then
				if itemStatus == 'empty' then
					local coins = memory.read_u8(0x7da2, "System Bus")
					if coins >= 10 then
						coins = coins - 10
						memory.write_u8(0x7da2, coins, "System Bus")
						itemStatus = 'spin'
						
						local sendString = string.format('{"event":"client-message_sent","data":{"id":"%s","clientId":"%s","action":"buy"},"channel":"presence-%s"}',
						config.user_id, config.name, config.roomcode)
						comm.ws_send(config.ws_id, sendString , true)

						itemFrame = 90
						gui.clearGraphics()
						client.PlaySound('./Reactvts/Activities/assets/itemBox.wav', 2, 1)
					end
				elseif itemStatus == 'hasitem' then
					print(item[1])
					if(item[1] == 'star') then
						memory.writebyte(0x03f2, 0x01)
					elseif item[1] == 'mushroom' then
						client.speedmode(150)
						itemEffect = 'mushroom'
						client.PlaySound('./Reactvts/Activities/assets/boost.wav', 2, 1)
						itemEffectFrame = 60 * 15
					elseif item[1] == 'banana' and #attackQueue > 0 and (attackQueue[1].name == 'greenShell' or attackQueue[1].name == 'redShell') then
						client.PlaySound('./Reactvts/Activities/assets/shellbounce.wav', 2, 1)
						table.remove(attackQueue, 1)
					else
						local sendString = string.format('{"event":"client-message_sent","data":{"id":"%s","clientId":"%s","action":"throw","item":"%s"},"channel":"presence-%s"}',
						config.user_id, config.name, item[1], config.roomcode)
						comm.ws_send(config.ws_id, sendString , true)
						client.PlaySound('./Reactvts/Activities/assets/fire.wav', 2, 1)
					end
					itemStatus = 'empty'
					gui.clearGraphics()
				end
				selectCooldown = 30
			end
		end
		
		if itemStatus == 'spin' then
			itemFrame = itemFrame - 1
			
			local x = (frame_count % 3) * itemWidth
			local y = 0
			if(frame_count % 6 >= 4) then
				y = itemHeight
			end
			gui.drawImageRegion('./Activities/assets/items.png', x, y, itemWidth, itemHeight, 0, 0, itemWidth, itemHeight)
			if itemFrame <= 0 then
				itemStatus = 'gotitem'
			end
		end

		if itemStatus == 'gotitem' and nextItem ~= null then
			itemStatus = 'hasitem'
			-- local nextItem = itemChoices[math.random(1, 6)]
			-- nextItem = itemChoices[(itemCounter % 6) + 1]  
			-- itemCounter = itemCounter + 1
			
			item = getItemByName(nextItem)
			nextItem = null
		end
		if itemStatus == 'hasitem' then
			local x = item[2] * itemWidth
			local y = item[3] * itemHeight
			gui.drawImageRegion('./Activities/assets/items.png', x, y, itemWidth, itemHeight, 0, 0, itemWidth, itemHeight)
		end

		if itemEffect ~= null then
			itemEffectFrame = itemEffectFrame - 1
			if itemEffectFrame <= 0 then
				if(itemEffect == 'mushroom') then
					client.speedmode(100)
				end
				if(itemEffect == 'lightning') then
					client.speedmode(100)
				end
				itemEffect = null
			end
		end

		if #attackQueue > 0 then
			local attack = attackQueue[1]
			local y = client.bufferheight() / 2 - itemHeight / 2

			if attack.name == 'lightning' then

			elseif attack.name == 'banana' then
				local x = client.bufferwidth() - itemWidth
				gui.drawImageRegion('./Activities/assets/items.png', itemChoices[attack.itemIndex][2] * itemWidth, itemChoices[attack.itemIndex][3] * itemHeight, itemWidth, itemHeight, x, y, itemWidth, itemHeight)
				if shellSound == false then
					client.PlaySound('./Reactvts/Activities/assets/shell.wav', 1, 1)
					shellSound = true
				end
			else 
				local x = 0
				gui.drawImageRegion('./Activities/assets/items.png', itemChoices[attack.itemIndex][2] * itemWidth, itemChoices[attack.itemIndex][3] * itemHeight, itemWidth, itemHeight, x , y, itemWidth, itemHeight)
				if shellSound == false then
					client.PlaySound('./Reactvts/Activities/assets/shell.wav', 1, 1)
					shellSound = true
				end
			end
			

			if attack.frames == 0 then
				shellSound = false
				if isInvincible() == false then
					if attack.name == 'lightning' then
						itemEffect = 'lightning'
						client.speedmode(50)
						itemEffectFrame = 60 * 2
						client.PlaySound('./Reactvts/Activities/assets/lightning.wav', 2, 1)
					end
					if attack.name == 'redShell' then
						if memory.read_u8(0x00ed, "RAM") > 1 then
							memory.write_u8(0x0578, 01, "RAM") -- Make Small
							client.PlaySound('./Reactvts/Activities/assets/spin.wav', 1, 1)
							memory.write_u8(0x04f1, 0x10, "RAM")
							memory.write_u8(0x0551, 0x26, "RAM") -- shrink animation
							memory.write_u8(0x0552, 0x70, "RAM") --iframes
						else 
							memory.write_u8(0xb4, 0xC0, 'RAM') -- Kill
						end
					end
					if attack.name == 'greenShell' then
						local currentPowerup = memory.read_u8(0x00ed, "RAM")
						if currentPowerup > 0 then
							
							client.PlaySound('./Reactvts/Activities/assets/spin.wav', 1, 1)
							memory.write_u8(0x04f1, 0x10, "RAM")
							print(currentPowerup)
							if currentPowerup == 1 then
								memory.write_u8(0x0551, 0x26, "RAM") -- shrink animation
								memory.write_u8(0x0578, 1, "RAM") -- Make Smaller
							else 
								memory.write_u8(0x0554, 0x10, "RAM") -- poof animation
								memory.write_u8(0x0578, 2, "RAM") -- Make Smaller
							end
							memory.write_u8(0x0552, 0x70, "RAM") --iframes
						else 
							memory.write_u8(0xb4, 0xC0, 'RAM') -- Kill
						end
					end
					if attack.name == 'banana' then
						client.PlaySound('./Reactvts/Activities/assets/spin.wav', 1, 1)
						memory.write_u8(0x0554, 0x50, "RAM") -- poof animation
					end
				end
				table.remove(attackQueue, 1)
			else
				if(memory.read_u8(0x0376, "RAM") == 0) then -- if not paused
					attack.frames = attack.frames - 1
				end
			end
		end
		
		if effectTimer > 0 then
			effectTimer = effectTimer - 1
			if is_frozen then
				memory.write_u8(0x0376, 0x01, "RAM") -- keep pausing the game
			end
		else 
			if effectTimer == 0 then
				if(is_frozen) then
					print('Unfreezing')
					memory.write_u8(0x04f5, last_song, "RAM")
					memory.write_u8(0x0376, 0x00, "RAM")
				end
				is_frozen = false
				
				client.speedmode(speed)
				effectTimer = -1
			end
		end

	end



	if frame_count % 6 == 0 and activity.initalized == true and is_rom_loaded() then
		if racing == false then
			if memory.read_u8(0x7b51, "System Bus") == 55 and memory.read_u8(0x7b50, "System Bus") == 114 then 
				racing = true
				-- print('savestate level')
				-- savestate.save('./race.state')
				local sendString = string.format('{"event":"client-message_sent","data":{"id":"%s","clientId":"%s","action":"start"},"channel":"presence-%s"}',
				config.user_id, config.name, config.roomcode)
				comm.ws_send(config.ws_id, sendString , true)
			end
		else
			hexScore = '0x' .. string.format("%02x", memory.read_u8(0x0715, "RAM")) .. string.format("%02x", memory.read_u8(0x0716, "RAM")) .. string.format("%02x", memory.read_u8(0x0717, "RAM"))		
			if(hexScore ~= preHexScore) then
				preHexScore = hexScore
				score = tonumber(hexScore)
				local sendString = string.format('{"event":"client-message_sent","data":{"id":"%s","clientId":"%s","action":"update","score":"%s"},"channel":"presence-%s"}',
				config.user_id, config.name, score .. '0', config.roomcode)
				comm.ws_send(config.ws_id, sendString , true)
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
			-- 	client.speedmode(speed)
			-- 	client.unpause()
			-- end
		end
    end
	if activity.initalized == false then
			prevRoom = config.roomcode
			init()
	end
end

function activity.receive(data, config)
	if(data.name == 'all' or data.name == config.name) then
		if data.action == "memory" then
			client.pause()
			for key, value in pairs(data.memory) do
				print(key, value[1], value[2], tonumber(value[1],16))
				-- Remove leading '0x' from the values if present
				value[1] = string.gsub(value[1], "^0x", "")
				value[2] = string.gsub(value[2], "^0x", "")
				-- Write to memory
				memory.write_u8(tonumber(value[1],16), tonumber(value[2],16), value[3])
				if(value[1] == "0578") then -- If Powerup, play powerup sound
					print(memory.read_u8(0x00e1, "RAM") .. ' > ' .. tonumber(value[2],16) )
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
			effectTimer = tonumber(data.length) * 60
		end
		if data.action == "slow" then
			print('Slow')
			is_frozen = false
			client.speedmode(speed / 2)
			effectTimer = tonumber(data.length) * 60 / 2 -- Game time runs half as long since half the speed
		end
		if data.action == "fast" then
			print('Speed')
			is_frozen = false
			client.speedmode(speed * 1.5)
			effectTimer = tonumber(data.length) * 60 * 1.5 -- Game time runs 1.5 times as long since 1.5 times the speed
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
			print('getItem' .. data.item)
			nextItem = data.item
		end

		if data.action == "item" and (data.name == config.name or data.name == 'all') then
			if data.item == 'banana' then
				table.insert(attackQueue, {["name"] = 'banana', ["itemIndex"] = 2 , ["frames"] = 60 * 3})
			end
			if data.item == 'greenShell' then
				table.insert(attackQueue, {["name"] = 'greenShell', ["itemIndex"] = 3 , ["frames"] = 60 * 3})
			end
			if data.item == 'redShell' then
				table.insert(attackQueue, {["name"] = 'redShell', ["itemIndex"] = 4 , ["frames"] = 60 * 3})
			end
			
			if data.item == 'lightning' and data.attacker ~= config.name then
				table.insert(attackQueue, {["name"] = 'lightning', ["itemIndex"] = 5 , ["frames"] = 1})
			end
		end
	end
end




return activity