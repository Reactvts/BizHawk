local rom = {}
rom.name = 'megaman3'


local game = null
local task = null
local stress_test = null

local stress_tests = {
	["gameLoopCat"] = {
		roomNumber = 0x0c,
		file = "./Reactvts/Saves/megaman3-stress-test-1.state",
	},
	["gameLoopSparkJump"] = {
		roomNumber = 0x09,
		file = "./Reactvts/Saves/megaman3-stress-test-2.state",
	},

}

local prev_health = 0
local prev_music_pitch = 0
local prev_music_speed = 0
local true_music_speed = null

local protomode_jump_frames = 0
local protomode_direction = 'left'

-- Progress

local progress = {

}

local progressCount = 0

-- Lag variables

local lag_interval = 60
local lag_timer = 0


-- generic

local prev_secs = null
local game_loop_save_state = null
local frame_count = 0
local fall_frames = 0
local is_jumping = false
local prev_y = 0x00
local next_audio_memory = null



local bg = {
    [0x0] = 0x0,
    [0x1] = 0x0,
    [0x2] = 0x0,
    [0x3] = 0x0,
    [0x4] = 0x0,
    [0x5] = 0x0,
    [0x6] = 0x0,
    [0x7] = 0x0,
    [0x8] = 0x0,
    [0x9] = 0x0,
    [0xa] = 0x0,
    [0xb] = 0x0,
    [0xc] = 0x0,
    [0xd] = 0x0,
    [0xe] = 0x0,
    [0xf] = 0x0,
}

local bulletAddresses = {0x301, 0x302, 0x303}
local bulletModifiers = {
	[1] = {
		x = 0,
		y = 0,
	},
	[2] = {
		x = 0,
		y = 0,
	},
	[3] = {
		x = 0,
		y = 0,
	},
}



local function isInvincible()
	return memory.read_u8(0x030, 'RAM') == 0x6 or memory.read_u8(0x039, 'RAM') > 0x0
end

function reachedGate()
	return memory.read_u8(0x00dc + next_audio_memory, "RAM") == 0x1d;
end	


function rom.setTask(nextGame, nextTask, nextState)
	game = nextGame
	task = nextTask
end

function rom.stopTask()
	game = null
	task = null
	
	prev_health = 0
	prev_music_pitch = 0
	prev_music_speed = 0
	true_music_speed = null

	protomode_jump_frames = 0
	protomode_direction = 'left'

	-- Lag variables

	lag_interval = 60
	lag_timer = 0


	-- generic

	prev_secs = null
	game_loop_save_state = null
	frame_count = 0
	fall_frames = 0
	is_jumping = false
	prev_y = 0x00
	next_audio_memory = null


	client.pause()
end



function rom.frame(frame_count) 
	next_audio_memory = memory.read_u8(0x00db, "RAM")
	nes.setdispbackground(false)

	is_jumping = memory.read_u8(0x0030, 'RAM') == 0x01

	if task == "musicSpeedsUp" then
		if frame_count % 30 == 0 then
			local music_speed_1 = memory.read_u8(0xc9, "RAM")
			local music_speed_2 = memory.read_u8(0xca, "RAM")

			if music_speed_2 < 0xFF then
				memory.write_u8(0xca, music_speed_2 + 0x1, "RAM")
			else
				memory.write_u8(0xca, 0x00, "RAM")
				memory.write_u8(0xc9, music_speed_1 + 0x1, "RAM")
			end
		end
	end

	if task == "musicSlowsDown" then
		if frame_count % 60 == 0 then
			local music_speed_1 = memory.read_u8(0xc9, "RAM")
			local music_speed_2 = memory.read_u8(0xca, "RAM")

			if music_speed_2 > 0x00 then
				memory.write_u8(0xca, music_speed_2 - 0x1, "RAM")
			elseif music_speed_1 > 0x00 then
				memory.write_u8(0xca, 0xFF, "RAM")
				memory.write_u8(0xc9, music_speed_1 - 0x1, "RAM")
			end
		end
	end

	if task == "musicPitchDown" then
		if prev_music_pitch == 0 then
			prev_music_pitch = memory.read_u8(0x00cb, "RAM") - 0x01
		end
		memory.write_u8(0x00cb, prev_music_pitch, "RAM")	
	end

	if task == "musicPitchUp" then
		if prev_music_pitch == 0 then
			prev_music_pitch = memory.read_u8(0x00cb, "RAM") + 0x01
		end
		memory.write_u8(0x00cb, prev_music_pitch, "RAM")	
	end

	if task == "noIframes" then
		if memory.read_u8(0x30, "RAM") == 0x6 then
			memory.write_u8(0x030, 0x00, "RAM")
		end
		if memory.read_u8(0x39, "RAM") > 0x0 then
			memory.write_u8(0x039, 0x00, "RAM")
		end
	end

	if task == "blindJump" then
		for i = 0x0, 0xf do
			if memory.read_u8(0x0600 + i, 'RAM') ~= 0xff then
				bg[i] = memory.read_u8(0x0600 + i, 'RAM')
			end
		end

		if is_jumping then 
			for i = 0, 0xf do
				memory.write_u8(0x0600 + i, 0xff, 'RAM')
			end
		else
			for i = 0, 0xf do
				memory.write_u8(0x0600 + i, bg[i], 'RAM')
			end
		end
	end

	if task == "laggy" then
		if (memory.read_u8(0xc9, "RAM") ~= 0) then
			prev_music_speed = memory.read_u8(0xc9, "RAM")
		end
		lag_interval = lag_interval - 1
		if lag_interval <= 0 then
			lag_interval = math.random(3, 12) * 60
			lag_timer = math.random(1, 3) * 30
		end

		if lag_timer > 0 then
			lag_timer = lag_timer - 1

			memory.write_u8(0x09a, 1, 'RAM')
			memory.write_u8(0x0c9, 0, 'RAM')
		else 
			memory.write_u8(0x09a, 0, 'RAM')
			memory.write_u8(0x0c9, prev_music_speed, 'RAM')
		end
		
	end

	if task == "corruptedGraphics" then
		memory.write_u8(0x09a, 0x91, 'RAM')
	end

	if task == "silhouette" then
		local lockFF = {0x60a, 0x60b, 0x60e, 0x60f, 0x612, 0x613, 0x614, 0x615, 0x616, 0x617, 0x618, 0x61a, 0x61b, 0x61c, 0x61d, 0x61e, 0x61f}
		local lock00 = {0x60c, 0x60d, 0x619}
		local lock0F = {0x610, 0x611}

		for _, address in ipairs(lockFF) do
			memory.write_u8(address, 0xFF, 'RAM') -- Replace 0xFF with the desired value to write
		end

		for _, address in ipairs(lock00) do
			memory.write_u8(address, 0x00, 'RAM') -- Replace 0x00 with the desired value to write
		end

		for _, address in ipairs(lock0F) do
			memory.write_u8(address, 0x0F, 'RAM') -- Replace 0x0F with the desired value to write
		end
		
	end

	if task == "slideForever" then
			memory.write_u8(0x33, 0x13, 'RAM')
	end

	if task == "superLowGravity" then
		memory.write_u8(0x0440, 0xa0, 'RAM')
	end

	

	if task == "fastBullets" or task == "slowBullets" then
		local speed = 3
		if task == "fastBullets" then
			speed = -1
		end



		for index, address in ipairs(bulletAddresses) do
			if memory.read_u8(address, "RAM") ~= 0x0  then
				if bulletModifiers[index].x == nil then
					if memory.read_u8(0x31) == 01 then
						bulletModifiers[index].x = -1 * speed
					elseif memory.read_u8(0x31) == 02 then
						bulletModifiers[index].x = speed				
					end
				end
			else 
				bulletModifiers[index].x = nil
			end


			if bulletModifiers[index].x ~= nil then
				memory.write_u8(address + 0x60, memory.read_u8(address + 0x60, "RAM") + bulletModifiers[index].x, "RAM")
			end
		end
	end

	if task == "momentumBullets"  then
		for index, address in ipairs(bulletAddresses) do
			if memory.read_u8(address, "RAM") ~= 0x0  then
				if bulletModifiers[index].x == nil then
					local speed = -2
					local inputs = memory.read_u8(0x016, "RAM")
					if isBitSet(inputs, 0) or isBitSet(inputs, 1) then
						speed = 1
					end

					if memory.read_u8(0x31) == 0x1 then
						bulletModifiers[index].x = speed	
					elseif memory.read_u8(0x31) == 0x2 then
						bulletModifiers[index].x = -1 * speed
									
					end
				end
			else 
				bulletModifiers[index].x = nil
			end


			if bulletModifiers[index].x ~= nil then
				memory.write_u8(address + 0x60, memory.read_u8(address + 0x60, "RAM") + bulletModifiers[index].x, "RAM")
			end
		end
	end

	if task == "curveBullets" then
		for index, address in ipairs(bulletAddresses) do
			if memory.read_u8(address, "RAM") ~= 0x0  then
				if bulletModifiers[index].y == nil then
					if memory.read_u8(0x460, 'RAM') == 0xff then
						bulletModifiers[index].y = 0
					else
						if memory.read_u8(0x460, 'RAM') <= 0x79 then 
							bulletModifiers[index].y = -1
						else 
							bulletModifiers[index].y = 1
						end
					end
				end
			else
				bulletModifiers[index].y = nil
			end

			if bulletModifiers[index].y ~= nil then
				if math.abs(bulletModifiers[index].y) > 16 then
					bulletModifiers[index].y = nil
				else
					bulletModifiers[index].y = bulletModifiers[index].y * 1.1
					memory.write_u8(address + 0xc0, memory.read_u8(address + 0xc0, "RAM") + math.floor(bulletModifiers[index].y), "RAM")
				end
			end
		end
	end


	if task == "floorIsSticky" then
		if true_music_speed == null then
			true_music_speed = memory.read_u8(0xc9, "RAM")
		end
		if is_jumping == false then
			if true_music_speed == null then
				true_music_speed = memory.read_u8(0xc9, "RAM")
			end
			prev_music_speed = true_music_speed + 1
			
			
			client.speedmode(50, false)
		else 
			client.speedmode(100, false)
			prev_music_speed = true_music_speed
			true_music_speed = null
		end
		-- memory.write_u8(0xc9, prev_music_speed, "RAM")
	end

	if task == "floorIsSpeedy" then
		if is_jumping then
			client.speedmode(100, false)
		else 
			client.speedmode(200, false)
		end
	end

	if task == "airIsGravy" then
		if true_music_speed == null then
			true_music_speed = memory.read_u8(0xc9, "RAM")
		end
		if is_jumping then
			if true_music_speed == null then
				true_music_speed = memory.read_u8(0xc9, "RAM")
			end
			prev_music_speed = true_music_speed + 1
			
			
			client.speedmode(50, false)
		else 
			client.speedmode(100, false)
			prev_music_speed = true_music_speed
			true_music_speed = null
		end
		memory.write_u8(0xc9, prev_music_speed, "RAM")
	end

	if task == "airIsSpeedy" then
		if true_music_speed == null then
			true_music_speed = memory.read_u8(0xc9, "RAM")
		end
		if is_jumping then
			if true_music_speed == null then
				true_music_speed = memory.read_u8(0xc9, "RAM")
			end
			prev_music_speed = true_music_speed - 1
			client.speedmode(200, false)
		else 
			client.speedmode(100, false)
			prev_music_speed = true_music_speed
			true_music_speed = null
			
		end
		memory.write_u8(0xc9, prev_music_speed, "RAM")
	end
	
	if task == "fallDamage" then 
		if is_jumping then 
			if memory.read_u8(0x0460, 'RAM') == 0xf9  then 
				fall_frames = fall_frames + 1
			else 
				fall_frames = 0
			end
		else
			if fall_frames > 5 and isInvincible() == false then 
				
				if prev_health - 2 > 0 then
					memory.write_u8(0x0030, 0x06, "RAM")
					memory.write_u8(0x00a2, 0x80 + prev_health - 2, "RAM")
					memory.write_u8(0x00db + next_audio_memory + 0x1, 0x16  , "RAM")
				else
					memory.write_u8(0x0030, 0x00e, "RAM")
					memory.write_u8(0x00a2, 0x80, "RAM")
					memory.write_u8(0x00a2, 0x80, "RAM")
					memory.write_u8(0x00db + next_audio_memory + 0x1, 0x17  , "RAM")
				end

			end
			fall_frames = 0
		end
	end
	
	if task == "protomode" then
		local A = false
		local B = false
		if memory.read_u8(0x612) ~= 0x50 then
			memory.write_u8(0x612, 0x50, "RAM")
			memory.write_u8(0x613, 0x15, "RAM")
			memory.write_u8(0x18, 0x01, "RAM")
		end

		if memory.read_u8(0x30) == 0x02 then
			memory.write_u8(0x30, 0x00, "RAM")
		end
		-- local inputs = memory.read_u8(0x16, 'RAM')
		
		if memory.read_u8(0x30) == 0x00 then
			protomode_jump_frames = 1
			if memory.read_u8(0x31) == 01 then
				protomode_direction = 'right'
			elseif memory.read_u8(0x31) == 02 then
				protomode_direction = 'left'
			end
			joypad.set({A = true}, 1)
		else
			if memory.read_u8(0x03c0, 'RAM') > prev_y then
				protomode_jump_frames = 0
				prev_y = memory.read_u8(0x03c0, 'RAM')
			end
			if protomode_jump_frames < 19 and protomode_jump_frames > 0 then
				protomode_jump_frames = protomode_jump_frames + 1
				A = true
				if protomode_jump_frames == 8 or protomode_jump_frames == 16 then
					B = true
				else 
					B = false
				end
			else 
				A = false		
			end 
			if protomode_direction == 'right' then
				Right = true
				Left = false
			else
				Left = true
				Right = false
			end

			joypad.set({A = A, B = B}, 1)
			
		end

		if memory.read_u8(0x380) == 0x06 then
			sendCompleted()
		end
	end

	if game ~= "theStressTest" then
		if reachedGate() then
			sendCompleted()
		end
	end


	if game == "theStressTest" then
		client.speedmode(speed, false)
		if game_loop_save_state == null then
			savestate.load(stress_tests[task].file)
			speed = 100
			game_loop_save_state = memorysavestate.savecorestate()
		end
		local roomNumber = memory.read_u8(0x380, "RAM")
		if roomNumber == stress_tests[task].roomNumber then
			sendLoopCompleted()
			memorysavestate.loadcorestate(game_loop_save_state)
		end
		local death = memory.read_u8(0x0030, "RAM") == 0x0e
		if death == true then
			sendDied()
			memorysavestate.loadcorestate(game_loop_save_state)
		end

	end

	prev_health = memory.read_u8(0x00a2, 'RAM') - 0x80
	prev_y = memory.read_u8(0x03c0, 'RAM')

	if memory.read_u8(0x0022, "RAM") > 0 and memory.read_u8(0x0380, "RAM") > 0 then
		local address = memory.read_u8(0x0022, "RAM") .. '|' .. memory.read_u8(0x0380, "RAM")
		if progress[address] == null then
			progress[address] = true
			progressCount = progressCount + 1
			
		end
	end
end

return rom

