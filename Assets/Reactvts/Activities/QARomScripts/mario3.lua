local rom = {}
rom.name = 'mario3'
rom.version = '1.0'


local game = null
local task = null

-- local stress_tests = {
-- 	["gameLoop"] = {

-- 	},

-- }

-- task variables

local prev_secs = null
local slow_clock_skip = false;
local prev_coins = 0
local clock_jumped = false
local prev_in_air = false
local prev_velocity = 0
local prev_music = 0
local game_loop_save_state = null
local form = null
local death_fanfare = false
local mario_x = 0
local mario_y = 0
local screenX = 0

local fall_frames = 0

local breath_holding_seconds_counter = 0


local enemy_addresses = {
	0x671,
	0x672,
	0x673,
	0x674,
	0x675
}


local enemy_data_addresses = {
	0x7b41,
	0x7b44,
	0x7b47,
	0x7b4a,
	0x7b4d,
	0x7b50,
	0x7b53,
	0x7b56,
	0x7b59,
	0x7b5c,
	0x7b5f,
	0x7b62,
	0x7b65,
	0x7b68,
	-- 0x7b6b,
}
local please_reproduce = {
	["mario3-w1-l1-hide-and-seek"] = {
		state = "mario3-w1-1.state",
		trackers = {
			{
				-- mario has leaf
				label = "marioHasLeaf",
				mem = 0x00ed,
				value = 0x03,
				threshold = 0x0,
				percentage = 0.2

			},
			{
				-- red turtle x
				label = "redTurtleX",
				mem = {
						{
							mem = 0x91,
							conditions = {
								{
									mem = 0x671,
									value = 0x6d,
									threshold = 0x00
								},
								{
									mem = 0x661,
									value = 0x02,
									threshold = 0x00
								}
							}
						},
						{
							mem = 0x92,
							conditions = {
								{
									mem = 0x672,
									value = 0x6d,
									threshold = 0x00
								},
								{
									mem = 0x662,
									value = 0x02,
									threshold = 0x00
								}
							}
						},
						{
							mem = 0x93,
							conditions = {
								{
									mem = 0x673,
									value = 0x6d,
									threshold = 0x00
								},
								{
									mem = 0x663,
									value = 0x02,
									threshold = 0x00
								}
							}
						},
						{
							mem = 0x94,
							conditions = {
								{
									mem = 0x674,
									value = 0x6d,
									threshold = 0x00
								},
								{
									mem = 0x664,
									value = 0x02,
									threshold = 0x00
								}
							}
						},
						{
							mem = 0x95,
							conditions = {
								{
									mem = 0x675,
									value = 0x6d,
									threshold = 0x00
								},
								{
									mem = 0x665,
									value = 0x02,
									threshold = 0x00
								}
							}
						}

				},
				value = 0x20,
				threshold = 0x10,
				percentage = 0.1

			},
			{
				-- red turtle y
				label = "redTurtleY",
				mem = {
						{
							mem = 0xa3,
							conditions = {
								{
									mem = 0x671,
									value = 0x6d,
									threshold = 0x00
								},
								{
									mem = 0x661,
									value = 0x02,
									threshold = 0x00
								}
							}
						},
						{
							mem = 0xa4,
							conditions = {
								{
									mem = 0x672,
									value = 0x6d,
									threshold = 0x00
								},
								{
									mem = 0x662,
									value = 0x02,
									threshold = 0x00
								}
							}
						},
						{
							mem = 0xa5,
							conditions = {
								{
									mem = 0x673,
									value = 0x6d,
									threshold = 0x00
								},
								{
									mem = 0x663,
									value = 0x02,
									threshold = 0x00
								}
							}
						},
						{
							mem = 0xa6,
							conditions = {
								{
									mem = 0x674,
									value = 0x6d,
									threshold = 0x00
								},
								{
									mem = 0x664,
									value = 0x02,
									threshold = 0x00
								}
							}
						},
						{
							mem = 0xa7,
							conditions = {
							{
								mem = 0x675,
								value = 0x6d,
								threshold = 0x00
							},
							{
								mem = 0x665,
								value = 0x02,
								threshold = 0x00
							}
						}
					}

				},
				value = 0x20,
				threshold = 0x00,
				percentage = 0.2

			},
			{
				-- screen x
				label = "screenX",
				mem = 0x24,
				value = 0x1b,
				threshold = 0x05,
				percentage = 0.05
			},
			{
				-- mario x
				label = "mario_x",
				mem = 0x90,
				value = 0x3a,
				threshold = 0x02,
				percentage = 0.05
			},
			{
				-- mario facing
				label = "marioFacing",
				mem = 0xef,
				value = 0x00,
				threshold = 0x00,
				percentage = 0.1
			},
			{
				-- mario y
				label = "mario_y",
				mem = 0xa2,
				value = 0x60,
				threshold = 0x00,
				percentage = 0.1
			},
			{
				-- Behind
				label = "behind",
				mem = 0x587,
				value = 0x01,
				threshold = 0x00,
				percentage = 0.2
			},
		}
	},
	["mario3-w1-l2-pipe-dreams"] = {
		state = "mario3-w1-2.state",
		trackers = {
			{
				label = "flyingGoombaX",
				mem = {
						{
							mem = 0x91,
							conditions = {
								{
									mem = 0x671,
									value = 0x74,
									threshold = 0x00
								},
								{
									mem = 0x661,
									value = 0x02,
									threshold = 0x00
								}
							}
						},
						{
							mem = 0x92,
							conditions = {
								{
									mem = 0x672,
									value = 0x74,
									threshold = 0x00
								},
								{
									mem = 0x662,
									value = 0x02,
									threshold = 0x00
								}
							}
						},
						{
							mem = 0x93,
							conditions = {
								{
									mem = 0x673,
									value = 0x74,
									threshold = 0x00
								},
								{
									mem = 0x663,
									value = 0x02,
									threshold = 0x00
								}
							}
						},
						{
							mem = 0x94,
							conditions = {
								{
									mem = 0x674,
									value = 0x74,
									threshold = 0x00
								},
								{
									mem = 0x664,
									value = 0x02,
									threshold = 0x00
								}
							}
						},
						{
							mem = 0x95,
							conditions = {
								{
									mem = 0x675,
									value = 0x74,
									threshold = 0x00
								},
								{
									mem = 0x665,
									value = 0x02,
									threshold = 0x00
								}
							}
						}

				},
				value = 0x84,
				threshold = 0x10,
				percentage = 0.3

			},
			{
				label = "flyingGoombaY",
				mem = {
						{
							mem = 0xa3,
							conditions = {
								{
									mem = 0x671,
									value = 0x74,
									threshold = 0x00
								},
								{
									mem = 0x661,
									value = 0x02,
									threshold = 0x00
								}
							}
						},
						{
							mem = 0xa4,
							conditions = {
								{
									mem = 0x672,
									value = 0x74,
									threshold = 0x00
								},
								{
									mem = 0x662,
									value = 0x02,
									threshold = 0x00
								}
							}
						},
						{
							mem = 0xa5,
							conditions = {
								{
									mem = 0x673,
									value = 0x74,
									threshold = 0x00
								},
								{
									mem = 0x663,
									value = 0x02,
									threshold = 0x00
								}
							}
						},
						{
							mem = 0xa6,
							conditions = {
								{
									mem = 0x674,
									value = 0x74,
									threshold = 0x00
								},
								{
									mem = 0x664,
									value = 0x02,
									threshold = 0x00
								}
							}
						},
						{
							mem = 0xa7,
							conditions = {
							{
								mem = 0x675,
								value = 0x74,
								threshold = 0x00
							},
							{
								mem = 0x665,
								value = 0x02,
								threshold = 0x00
							}
						}
					}

				},
				value = 0x2E,
				threshold = 0x10,
				percentage = 0.4

			},
			{
				-- screen x
				label = "screenX",
				mem = 0x24,
				value = 0x22,
				threshold = 0x05,
				percentage = 0.1
			},
			{
				-- mario x
				label = "mario_x",
				mem = 0x90,
				value = 0x9c,
				threshold = 0x02,
				percentage = 0.1
			},
			{
				-- mario y
				label = "mario_y",
				mem = 0xa2,
				value = 0x70,
				threshold = 0x00,
				percentage = 0.1
			},
		}
	},
	["mario3-w1-l2-wrong-star-box"] = {
		state = "mario3-w1-2.state",
		trackers = {
			{
				label = "starX",
				mem = {
						{
							-- mem = 0x96,
							mem = 0xb1,
							conditions = {
								{
									mem = 0x676,
									value = 0x0c,
									threshold = 0x00
								},
								{
									mem = 0x666,
									value = 0x02,
									threshold = 0x00
								}
							}
						}
				},
				value = 0x4f,
				threshold = 0x10,
				percentage = 0.3

			},
			{
				label = "starY",
				mem = {
					{
						mem = 0xa8,
						conditions = {
							{
								mem = 0x676,
								value = 0x0c,
								threshold = 0x00
							},
							{
								mem = 0x666,
								value = 0x02,
								threshold = 0x00
							}
						}
					},
				},
				value = 0x25,
				threshold = 0x10,
				percentage = 0.4

			},
			{
				label = "screenX",
				mem = 0x24,
				value = 0x7c,
				threshold = 0x10,
				percentage = 0.3
			},
			-- {
			-- 	-- mario x
			-- 	label = "mario_x",
			-- 	mem = 0x90,
			-- 	value = 0x4e,
			-- 	threshold = 0x10,
			-- 	percentage = 0.02
			-- },
			-- {
			-- 	-- mario y
			-- 	label = "mario_y",
			-- 	mem = 0xa2,
			-- 	value = 0x69,
			-- 	threshold = 0x10,
			-- 	percentage = 0.1
			-- },
		}
	}
	
}


local function isInvincible()
	return (memory.read_u8(0x0552, "RAM") + 
	memory.read_u8(0x0553, "RAM") + 
	memory.read_u8(0x055a, "RAM") +
	memory.read_u8(0x0559, "RAM") +
	memory.read_u8(0x05f3, "RAM")
	
) > 0 
end

local function enemieIsOnScreen(spriteId)
	local enemie_addresses = {
		0x661,
		0x662,
		0x663,
		0x664,
		0x665,
		0x666,
		0x667,
	}

	for i = 1, #enemie_addresses do
		if memory.read_u8(enemie_addresses[i] + 0x10, 'RAM') == spriteId and 
		memory.read_u8(enemie_addresses[i]) == 0x02 then
			return true
		end
	end
	return false
end


local has_moved = false

function rom.setTask(nextGame, nextTask, nextState)
	game = nextGame
	task = nextTask
end

function rom.stopTask()
	game = null
	task = null
	
	-- task variables
	
	prev_secs = null
	slow_clock_skip = false;
	prev_coins = 0
	clock_jumped = false
	prev_in_air = false
	prev_velocity = 0
	game_loop_save_state = null
	form = null
	death_fanfare = false
	


	client.pause()
end

function rom.frame(frame_count) 
	mario_x = memory.read_u8(0x90, 'RAM') + (0xFF * memory.read_u8(0x75, 'RAM'))
	mario_y = memory.read_u8(0xa2, 'RAM') + (0xFF * memory.read_u8(0x87, 'RAM'))
	screenX = memory.read_u8(0x24, 'RAM')

	nes.setdispbackground(false)

	if game == 'pleaseReproduce' then
		 getReproductionScore(please_reproduce[task]["trackers"])
		return
	end

	if game ~= 'theSressTest' then
		if task == 'autoRun' then
			local controller1 = joypad.get(1)
			if(controller1["Left"]) then
				joypad.set( { ["Left"] = false, ["Right"] = true }, 1 );
			else 
				joypad.set( { ["Right"] = true}, 1 );
			end
		end

		if task == 'silhouette' then
			memory.write_u8(0x7c1, 0xff, 'RAM')
			memory.write_u8(0x7c2, 0xff, 'RAM')
			memory.write_u8(0x7c3, 0xff, 'RAM')
			memory.write_u8(0x7c4, 0xff, 'RAM')
			memory.write_u8(0x7c5, 0xff, 'RAM')
			memory.write_u8(0x7c6, 0xff, 'RAM')
			memory.write_u8(0x7c7, 0xff, 'RAM')
			memory.write_u8(0x7c8, 0xff, 'RAM')
			memory.write_u8(0x7c9, 0xff, 'RAM')
			memory.write_u8(0x7ca, 0xff, 'RAM')
			memory.write_u8(0x7cb, 0xff, 'RAM')
			memory.write_u8(0x7cc, 0xff, 'RAM')
			memory.write_u8(0x7cd, 0xff, 'RAM')
			memory.write_u8(0x7ce, 0xff, 'RAM')
			memory.write_u8(0x7cf, 0xff, 'RAM')
			memory.write_u8(0x7d0, 0xff, 'RAM')
			-- memory.write_u8(0x7d1, 0xff, 'RAM')
			memory.write_u8(0x7d2, 0xff, 'RAM')
			memory.write_u8(0x7d3, 0xff, 'RAM')
			memory.write_u8(0x7d4, 0xff, 'RAM')
			memory.write_u8(0x7d5, 0xff, 'RAM')
			memory.write_u8(0x7d6, 0xff, 'RAM')
			memory.write_u8(0x7d7, 0xff, 'RAM')
			memory.write_u8(0x7d8, 0xff, 'RAM')
			memory.write_u8(0x7d9, 0xff, 'RAM')
			memory.write_u8(0x7da, 0xff, 'RAM')
			memory.write_u8(0x7db, 0xff, 'RAM')
			memory.write_u8(0x7dc, 0xff, 'RAM')
			memory.write_u8(0x7dd, 0xff, 'RAM')
			memory.write_u8(0x7de, 0xff, 'RAM')
			memory.write_u8(0x7df, 0xff, 'RAM')
			memory.write_u8(0x7e0, 0xff, 'RAM')
		end

		if task == 'autoJump' then
			local controller1 = joypad.get(1)
			if memory.read_u8(0xd8, 'RAM') == 0x0 then
				memory.write_u8(0xd8, 0x1, 'RAM')
				memory.write_u8(0xcf, 0xc8, 'RAM')
				
			end
		end

		if task == 'lava' then
			local screen_progression = memory.read_u8(0xe9, 'RAM')
			local map_bottom = (memory.read_u8(0x87, 'RAM') == 1)
			local player_y = memory.read_u8(0xa2, 'RAM')
			local player_x = memory.read_u8(0xab, 'RAM')

			if memory.read_u8(0x5ee, 'RAM') == 0x3 then -- set invincible until first jump
				has_moved = false
			end


			if screen_progression + (player_x - 0x70) >= 0x2e and screen_progression + (player_x - 0x70) <= 0x3b and player_y == 0x70 and map_bottom then
				if has_moved then
					memory.write_u8(0xb4, 0xc0, 'RAM')
				end
			elseif player_y == 0x80 and map_bottom then
				if has_moved then
					memory.write_u8(0xb4, 0xc0, 'RAM')
				end
			else 
				has_moved = true
			end				
		end

		if task == 'floorIsSticky' then
			if memory.read_u8(0xd8, 'RAM') == 0 then
				speed = 50
			else 
				speed = 100
			end
		end

		if task == 'floorIsSpeedy' then
			if memory.read_u8(0xd8, 'RAM') == 0 then
				speed = 200
			else 
				speed = 100
			end
		end

		if task == 'airIsGravy' then
			if memory.read_u8(0xd8, 'RAM') == 1 then
				speed = 50
			else 
				speed = 100
			end
		end

		if task == 'airIsSpeedy' then
			if memory.read_u8(0xd8, 'RAM') == 1 then
				speed = 200
			else 
				speed = 100
			end
		end

		if task == 'oopsAllGoombas' then
			for i = 1, #enemy_data_addresses do
				memory.write_u8(enemy_data_addresses[i], 0x73, 'System Bus')
			end
		end

		if task == 'oopsAllBoos' then
			for i = 1, #enemy_data_addresses do
				memory.write_u8(enemy_data_addresses[i], 0x2f, 'System Bus')
			end
		end

		if task == 'hammerTime' then
			for i = 1, #enemy_data_addresses do
				memory.write_u8(enemy_data_addresses[i], 0x81, 'System Bus')
				local y = memory.read_u8(enemy_data_addresses[i] + 0x2, 'System Bus')
				memory.write_u8(enemy_data_addresses[i] + 0x2, y - 0x1, 'System Bus')
			end
		end

		if task == 'timeBomb' then
			for i = 1, #enemy_data_addresses do
				memory.write_u8(enemy_data_addresses[i], 0x4a, 'System Bus')
			end
		end

		if task == 'bigMode' then
			-- 7c == big gomba
			-- 7b == big red koopa
			-- 7a == big green koopa
			-- 7d = pig plant
			-- 7e = big flying green koopa
			local enemieBigSize = 
			{
				[0x6c] = 0x7a,
				[0x6d] = 0x7b,
				[0x72] = 0x7c,
				[0x73] = 0x7c,
				[0xa6] = 0x7d,
				[0xa0] = 0x7d,
				[0xa4] = 0x7d,
				[0x6e] = 0x7e
			}

			for i = 1, #enemy_data_addresses do
				local current_enemy = memory.read_u8(enemy_data_addresses[i], 'System Bus')
				if enemieBigSize[current_enemy] ~= null then
					memory.write_u8(enemy_data_addresses[i], enemieBigSize[current_enemy], 'System Bus')
					if enemieBigSize[current_enemy] ~= 0x7d then
						local y = memory.read_u8(enemy_data_addresses[i] + 0x2, 'System Bus')
						memory.write_u8(enemy_data_addresses[i] + 0x2, y - 0x1, 'System Bus')
					end
					
				end
			end
		end

		if task == 'rudePowerups' then
			if memory.read_u8(0x666, "RAM") == 0x02 then
				local powerup_x = memory.read_u8(0x96, "RAM") + (0xFF * memory.read_u8(0x7b, "RAM"))
				local powerup_y = memory.read_u8(0xa8, "RAM") + (0xFF * memory.read_u8(0x8d, "RAM"))
				
				local diff_x = mario_x - powerup_x
				local diff_y = mario_y - powerup_y

		
				if math.abs(diff_x) < 0x10 and memory.read_u8(0x0c3, "RAM") ~= 0x00 and math.abs(diff_y) < 0x14 then
					if diff_x < 0 then
						memory.write_u8(0x0c3,0x10, "RAM")
						memory.write_u8(0x96, powerup_x + (0x11 + diff_x), "RAM")
					else
						memory.write_u8(0x0c3,0xf0, "RAM") 
						memory.write_u8(0x96, powerup_x - (0x11 - diff_x), "RAM")
						
					end
				end
			end
		end

		if task == 'fallingBlocks' then
			memory.write_u8(0xd6, 40, "RAM")
		end

		if task == 'flyingBlocks' then
			memory.write_u8(0xd6, 80, "RAM")
		end

		if task == 'backstage' then
			if enemieIsOnScreen(0x41) == false then
				memory.write_u8(0x587, 0x01, "RAM")
				memory.write_u8(0x588, 0x01, "RAM")
			end
			if enemieIsOnScreen(0x41) == true then
				memory.write_u8(0x587, 0x00, "RAM")
				memory.write_u8(0x588, 0x00, "RAM")
			end

			
		end

		if task == 'powerupRoulette' then
			-- {
			-- 	mem = 0x676,
			-- 	value = 0x0c, <-- star
			-- 	threshold = 0x00
			-- },
			-- {
			-- 	mem = 0x666,
			-- 	value = 0x02,
			-- 	threshold = 0x00
			-- }
			
		end

		if task == 'fallDamage' then
			if memory.read_u8(0x058c, 'RAM') == 0x0 then  -- player is taking damage or powering up
				local in_air = memory.read_u8(0xd8, 'RAM') == 0x01
				if in_air then 
					if memory.read_u8(0x00cf, 'RAM') == 0x45  then 
						fall_frames = fall_frames + 1
					else 
						fall_frames = 0
					end
				else
					if fall_frames > 5 and isInvincible() == false then 
						local currentPowerup = memory.read_u8(0x00ed, "RAM")
						if currentPowerup > 0 then
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
							memory.write_u8(0xb4, 0xC0, 'RAM') -- Kill
						end
					end
					fall_frames = 0
				end
			end
		end

		if task == 'jumpCollision' then
			if memory.read_u8(0x058c, 'RAM') == 0x0 then  -- player is taking damage or powering up
				if prev_velocity < 0xe0 and prev_velocity > 0xc9 and memory.read_u8(0x00cf, 'RAM') <= 45  then 		
					if isInvincible() == false then 
						local currentPowerup = memory.read_u8(0x00ed, "RAM")
						if currentPowerup > 0 then
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
							memory.write_u8(0xb4, 0xC0, 'RAM') -- Kill
						end
					end
				
				end		
			end
			prev_velocity = memory.read_u8(0x00cf, 'RAM')		
		end
		
		if task == 'fastClock' then
			local secs = memory.read_u8(0x05f0,'RAM')
			if  secs ~= prev_secs then
				if secs > 0x0 then
					memory.write_u8(0x05f0, secs - 0x1,'RAM')
					prev_secs = secs - 1
				else 
					prev_secs = secs
				end
			end
		end

		if task == 'slowClock' then
			local secs = memory.read_u8(0x05f0,'RAM')
			if  secs ~= prev_secs then
				if slow_clock_skip == false then
					if secs ~= 0x09 then
						memory.write_u8(0x05f0, secs + 0x1,'RAM')
						prev_secs = secs + 1
						slow_clock_skip = true
					end
				else 
					prev_secs = secs
					slow_clock_skip = false
				end
			end
		end

		if task == "coinsDown" then
			local coins = memory.read_u8(0x7da2, "System Bus")
			if coins ~= prev_coins and coins > 0 then
				coins = coins - 0x02
				if coins <= 0 then
					coins = 99
				end
				memory.write_u8(0x7da2, coins, "System Bus")
				prev_coins = coins
			end
		end

		if task == 'doubleCoins' then
			local coins = memory.read_u8(0x7da2, "System Bus")
			if coins ~= prev_coins and coins > 0 then
				coins = coins + 0x01
				memory.write_u8(0x7da2, coins, "System Bus")
				prev_coins = coins
			end
		end

		if task == 'whiteBlocked' then
			memory.write_u8(0x0570, 0x00, "RAM")
		end

		if task == 'noStompOneUp' then
			local stomps = memory.read_u8(0x05f4, "RAM")
			if stomps == 8 then
				memory.write_u8(0x05f4, 0x07, "RAM")
			end
		end

		if task == 'clockJump' then
			local secs = memory.read_u8(0x05f0,'RAM')
			if secs == 0x03  then
				if memory.read_u8(0xd8, 'RAM') == 0x0 and clock_jumped == false then
					memory.write_u8(0xd8, 0x1, 'RAM')
					memory.write_u8(0xcf, 0xc8, 'RAM')
					prev_secs = secs
					clock_jumped = true	
					
				end
				
			else 
				clock_jumped = false
			end
		end

		if task == 'jumpSlowCoinFast' then 
			local in_air = memory.read_u8(0xd8, 'RAM') == 0x01
			if in_air then
				if prev_in_air == false then
					speed = speed - 2
					if speed < 50 then
						speed = 50
					end
				end
				prev_in_air = true
			else 
				prev_in_air = false
			end
			local coins = memory.read_u8(0x7da2, "System Bus")
			if coins ~= prev_coins then
				speed = speed + 5
				if speed > 200 then
					speed = 200
				end
			end
			prev_coins = coins
		end

		if task == 'infinitPSpeed' then
			-- 0x3dd
		end

		if task == 'canDrown' then
			local skin_color = { 0x36, 0x35, 0x34, 0x33, 0x32, 0x31, 0x21, 0x22, 0x23 } 
			if prev_music == 0x00 and memory.read_u8(0x7dfd, "System Bus") == 0x27 then
				prev_music = memory.read_u8(0x4e5, "RAM")
			end
			if memory.read_u8(0x7dfc, "System Bus") == 0x16 then
				breath_holding_seconds_counter = 0
			end
		
			
			if memory.read_u8(0x575, "RAM") == 0x00 or memory.read_u8(0xed, "RAM") == 0x04 then
				breath_holding_seconds_counter = 0
			end
			
			if frame_count % 60 == 0 then
				breath_holding_seconds_counter = breath_holding_seconds_counter + 2	
			end

			local skin_index =  math.floor(breath_holding_seconds_counter / 8)

			if skin_index > 3 and skin_index <= 8 and memory.read_u8(0x4e5, "RAM") ~= 0xa0 then
				memory.write_u8(0x4f5, 0xa0, "RAM")
			end 

			if skin_index <= 3 and memory.read_u8(0x4e5, "RAM") ~= prev_music then
				memory.write_u8(0x4f5, prev_music, "RAM")
			end 
		
			if skin_index > 8 then
				memory.write_u8(0x5ee, 0, "RAM")
				memory.write_u8(0x5ef, 0, "RAM")
				memory.write_u8(0x5f0, 0, "RAM")
				memory.write_u8(0x5f1, 0, "RAM")
				prev_music = 0x00
			end

			memory.write_u8(0x7d3, skin_color[skin_index + 1], "RAM")
			-- looking for freeze flag
			
			
		end

		if task == 'fireWater' then
			if memory.read_u8(0x575, "RAM") == 0x01 and memory.read_u8(0xed, "RAM") == 0x02 then
				memory.write_u8(0x578, 0x02, "RAM")
			end
		end

		if task == 'noFireballsUnderWater' then
			if memory.read_u8(0x575, "RAM") == 0x01 and memory.read_u8(0xed, "RAM") == 0x02 then
				memory.write_u8(0x7ce2, 0x1, "System Bus")
				memory.write_u8(0x7ce1, 0x1, "System Bus")
			end
		end

		if task == 'shootBackwards' then
			if memory.read_u8(0xed, "RAM") == 0x02 then
				memory.write_u8(0x7ce9, 0xfc, "System Bus")
				memory.write_u8(0x7cea, 0xfc, "System Bus")
			end
			if memory.read_u8(0xed, "RAM") == 0x06 then
				memory.write_u8(0x7ce9, 0xef, "System Bus")
				memory.write_u8(0x7cea, 0xef, "System Bus")
			end
		end

		if task == 'slowFireball' then
			local fireball_1_x = memory.read_u8(0x7ce5, "System Bus")
			local fireball_2_x = memory.read_u8(0x7ce6, "System Bus")

			local fireball_1_speed = memory.read_u8(0x7ce9, "System Bus")
			local fireball_2_speed = memory.read_u8(0x7cea, "System Bus")

			
			
			if memory.read_u8(0x7ce1, "System Bus") ~= 0x00 then
				if frame_count % 2 == 0 then
					if fireball_1_speed > 0x81 then
						memory.write_u8(0x7ce5, fireball_1_x + 0x01, "System Bus")
						memory.write_u8(0x7ce9, 0xff, "System Bus")
					else 
						memory.write_u8(0x7ce5, fireball_1_x - 0x01, "System Bus")
						memory.write_u8(0x7ce9, 0x01, "System Bus")
					end
				end
			else 
				memory.write_u8(0x7ce9, 0x00, "System Bus")
			end

			if memory.read_u8(0x7ce2, "System Bus") ~= 0x00 then
				if frame_count % 2 == 0 then
					if fireball_2_speed > 0x81 then
						memory.write_u8(0x7ce6, fireball_2_x + 0x01, "System Bus")
						memory.write_u8(0x7cea, 0xff, "System Bus")
					else 
						memory.write_u8(0x7ce6, fireball_2_x - 0x01, "System Bus")
						memory.write_u8(0x7cea, 0x01, "System Bus")
					end
				end
			else 
				memory.write_u8(0x7cea, 0x00, "System Bus")
			end
		end

		if task == 'marioLandFireBall' then
			memory.write_u8(0x7ced, 0x14, "System Bus")
			memory.write_u8(0x7cee, 0x14, "System Bus")
		end

		if task == 'brokenSound' then
			memory.write_u8(0x4f4, 0x80, "RAM")
		end

		if task == 'noGoingBack' then
			-- 55c == 80
			memory.write_u8(0x55c, 0x80, "RAM")

		end
	end

	if game == 'theStressTest' then
		if task == 'gameLoop' then
			if game_loop_save_state == null then
				speed = 100
				game_loop_save_state = memorysavestate.savecorestate()
			end

			local fanfare = memory.read_u8(0x4f4, "RAM")
			if fanfare == 0x04 or fanfare == 0x10 or fanfare == 0x20 then
				sendLoopCompleted()
				memorysavestate.loadcorestate(game_loop_save_state)
			end
	
			if death_fanfare == true and fanfare == 0x00 then
				sendDied()
				memorysavestate.loadcorestate(game_loop_save_state)
			end
	
			death_fanfare = fanfare == 0x01
		end
	else 
		local fanfare = memory.read_u8(0x4f4, "RAM")
		if fanfare == 0x04 or fanfare == 0x10 or fanfare == 0x20 then
			sendCompleted()
		end
	end
end

return rom

