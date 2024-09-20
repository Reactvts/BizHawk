local rom = {}
rom.name = 'zelda1'


local game = null
local task = null
local state = null
local stress_test = null

-- memory addresses

local mem_iframes = 0x4f0
local mem_bomb_count = 0x658
local mem_current_item = 0x656

local stress_tests = {
	["gameLoopDodongo"] = {
		roomNumber = 0x0D,
		file = "./Reactvts/Saves/zelda1-d2-boss.state",
	},

}

local state_success = {
    ["zelda1-start.state"] = 'enter_d1' 
}




local prev_link_x = 0
local prev_link_y = 0
local prev_link_direction = 0
local prev_arrow_x = 0
local prev_arrow_y = 0
local prev_arrow_direction = 0
local arrow_is_flying = false
local idle_counter = 0
local bad_shot_offset = 0

local prev_hearts = 0
local prev_coins = 0
local prev_keys = 0
local prev_bombs = 0
local prev_room_kill = 0
local kill_combo = 0
local prev_bomb_status = 0
local prev_arrow_status = 0
local bomb_arrow_status = 0
local bomb_mask_timer = 0

local bow_strength = 0

-- Generic variables

local frame_count = 0



-- generic

-- local prev_secs = null
local game_loop_save_state = null
local frame_count = 0



function getB() 
    return isBitSet(memory.read_u8(0xfa, "RAM"), 6)
end

function getHearts()
    return math.floor(memory.read_u8(0x66f, "RAM") % 0x10) + (memory.read_u8(0x670, "RAM") / 0xff)
end

function updateHearts(amount)
    total_hearts = math.floor(memory.read_u8(0x66f, "RAM") / 0x16) + 1
    
    new_hearts = prev_hearts + amount
    half_hearts = new_hearts - math.floor(new_hearts)
    if new_hearts - 1 > total_hearts then
        new_hearts = total_hearts
        new_half_hearts = 0xff
    elseif new_hearts <= 0 then
        new_hearts = 0
        new_half_hearts = 0
    else
        -- print(half_hearts)
        new_half_hearts = tonumber(string.format("%x",math.floor(half_hearts * 255)),16)
    end
    
    -- print(total_hearts .. " " .. prev_hearts .. " " .. new_hearts .. " " .. new_half_hearts .. " " .. amount)
    new_hearts = tonumber(string.format("%x",(total_hearts * 0x10)),16) + math.floor(new_hearts)
    
    memory.write_u8(0x66f, new_hearts , "RAM")
    memory.write_u8(0x670, new_half_hearts, "RAM")
end

function reachedDungeon()
    return memory.read_u8(0x609, "RAM") == 0x40
end

function completedDungeon()
    return memory.read_u8(0x609, "RAM") == 0x04
end


function rom.setTask(nextGame, nextTask, nextState)
	game = nextGame
	task = nextTask
    state = nextState
end

function rom.stopTask()
	game = null
	task = null
	
    prev_link_x = 0
    prev_link_y = 0
    prev_link_direction = 0
    prev_arrow_x = 0
    prev_arrow_y = 0
    prev_arrow_direction = 0
    prev_room_kill = 0
    arrow_is_flying = false
    idle_counter = 0
    bad_shot_offset = 0
    
    prev_hearts = 0
    prev_coins = 0
    prev_keys = 0
    prev_bombs = 0
    kill_combo = 0
    prev_bomb_status = 0
    prev_arrow_status = 0
    bomb_arrow_status = 0
    bomb_mask_timer = 0
    
    bow_strength = 0
    
    -- Generic variables
    
    speed = 100
    frame_count = 0
    
    
    
    -- generic
    
    -- local prev_secs = null
    local game_loop_save_state = null
    local frame_count = 0

	client.pause()
end



function rom.frame(frame_count) 
	nes.setdispbackground(false)

    if task == "moneyKills" then
        if prev_coins < memory.read_u8(0x66d, "RAM") then
            memory.write_u8(0x12, 0x11, "RAM")
        end
    end

    if task == "swordKillUpgrades" then
        if kill_combo >= 20 then
            memory.write_u8(0x657, 0x03, "RAM")
        elseif kill_combo >= 10 then
            memory.write_u8(0x657, 0x02, "RAM")
        else 
            memory.write_u8(0x657, 0x01, "RAM")
        end
    end

    if task == "musicResetOnDamage" then
        if memory.read_u8(mem_iframes, "RAM") == 0x18 then
            memory.write_u8(0x600, 0x01, "RAM")
        end
    end

    if task == "loseMoneyOnDamage" then
        if memory.read_u8(mem_iframes, "RAM") == 0x18 then
            memory.write_u8(0x67e, 0x01, "RAM")
        end
    end

    if task == "moneyShowoff" then
        if prev_coins < memory.read_u8(0x66d, "RAM") then
            memory.write_u8(0x505, 0x0f, "RAM")
            memory.write_u8(0x506, 0x40, "RAM")
            memory.write_u8(0x602, 0x0c, "RAM")
        end
    end

    if task == "keyShowoff" then
        if prev_keys < memory.read_u8(0x66e, "RAM") then
            memory.write_u8(0x505, 0x19, "RAM")
            memory.write_u8(0x506, 0x40, "RAM")
            memory.write_u8(0x602, 0x0c, "RAM")
        end
    end

    if task == "bombShowoff" then
        if prev_bombs < memory.read_u8(mem_bomb_count, "RAM") then
            memory.write_u8(0x505, 0x28, "RAM")
            memory.write_u8(0x506, 0x40, "RAM")
            memory.write_u8(0x602, 0x0c, "RAM")
        end
    end

    if task == "triforceShop" then
        memory.write_u8(0x422, 0x1b, "RAM")
        memory.write_u8(0x423, 0x1b, "RAM")
        memory.write_u8(0x424, 0x1b, "RAM")
        memory.write_u8(0x430, 0xff, "RAM")
        memory.write_u8(0x431, 0xff, "RAM")
        memory.write_u8(0x432, 0xff, "RAM")     
    end

    if task == "infiniteBombs" then
        memory.write_u8(mem_bomb_count, 0x63, "RAM")
    end

    if task == "shortFuse" then
        if memory.read_u8(0x038, "RAM") > 0x14 then
            memory.write_u8(0x038, 0x14, "RAM")
        end
    end
    
    if task == "bombMask" then
        if prev_bombs > 0 and bomb_mask_timer > 0 then
            memory.write_u8(mem_bomb_count, 0x0, "RAM")
        end

        if prev_bombs > 2 and bomb_mask_timer == 0 then
            memory.write_u8(mem_bomb_count, 0x01, "RAM")
        end

        if bomb_mask_timer > 0 then
            bomb_mask_timer = bomb_mask_timer - 1
        end
        if bomb_mask_timer == 0 and prev_bombs == 0 then
            memory.write_u8(mem_bomb_count, 0x01, "RAM")
        end

        if memory.read_u8(0x038, "RAM") > 0x00 then
            bomb_mask_timer = 3 * 60
            memory.write_u8(0x038, 0x00, "RAM")
        end
    end

    if task == "dudBomb" then
        if memory.read_u8(0x038, "RAM") <= 0x01 then
            memory.write_u8(0x038, 0x10, "RAM")
        end
    end

    if task == "remoteBomb" then
        if memory.read_u8(0x0bc, "RAM") == 0x12 and memory.read_u8(mem_current_item, "RAM") == 0x1 and isBitSet(memory.read_u8(0xfa, "RAM"), 6) and memory.read_u8(0x038, "RAM") < 0x25  then
            memory.write_u8(0x038, 0x00, "RAM")
        else
            if memory.read_u8(0x0bc, "RAM") == 0x12 and memory.read_u8(0x038, "RAM") == 0x02 then
                memory.write_u8(0x038, 0x3, "RAM")
            end
        end
    end

    if task == "triggerBomb" then
        if memory.read_u8(0x0bc, "RAM") == 0x12 and memory.read_u8(0x0be, "RAM") == 0x10 then
            bomb_x = memory.read_u8(0x080, "RAM")
            bomb_y = memory.read_u8(0x094, "RAM")
            arrow_x = memory.read_u8(0x082, "RAM")
            arrow_y = memory.read_u8(0x096, "RAM")
            dx = bomb_x - arrow_x
            dy = bomb_y - arrow_y
            distance = math.sqrt(dx * dx + dy * dy)
            if distance < 0x10 then
                memory.write_u8(0x038, 0x00, "RAM")
                memory.write_u8(0x0be, 0x00, "RAM")

            end
        end
        if memory.read_u8(0x0bc, "RAM") == 0x12 and memory.read_u8(0x038, "RAM") == 0x02 then
            memory.write_u8(0x038, 0x3, "RAM")
        end
    end

    if task == "bombArrow" then
        if memory.read_u8(0x0be, "RAM") == 0x10 then
            if prev_arrow_status == 0 and prev_bombs > 0 then
                bomb_arrow_status = 1
                memory.write_u8(0x0bc, 0x12, "RAM")
                memory.write_u8(mem_bomb_count, prev_bombs - 1, "RAM")
            end
            if bomb_arrow_status == 1 then
                arrow_x = memory.read_u8(0x082, "RAM")
                arrow_y = memory.read_u8(0x096, "RAM")
                arrow_direction = memory.read_u8(0x0aa, "RAM")
                if arrow_direction == 0x01 then
                    arrow_x = arrow_x + 0x08
                elseif arrow_direction == 0x02 then
                    arrow_x = arrow_x - 0x08
                elseif arrow_direction == 0x04 then
                    arrow_y = arrow_y + 0x08
                    arrow_x = arrow_x - 0x04
                elseif arrow_direction == 0x08 then
                    arrow_y = arrow_y - 0x08
                    arrow_x = arrow_x - 0x04
                end
                memory.write_u8(0x080, arrow_x, "RAM")
                memory.write_u8(0x094, arrow_y, "RAM")
                memory.write_u8(0x038, 0xff, "RAM")
                
            end

            
        elseif bomb_arrow_status == 1 then
            bomb_arrow_status = 0
            memory.write_u8(0x038, 0x00, "RAM")
            
        end
    end

    if task == "bombsHurt" then
        if prev_bomb_status == 0x12 and memory.read_u8(0xbc, "RAM") == 0x13 then
            link_x = memory.read_u8(0x70, "RAM")
            link_y = memory.read_u8(0x84, "RAM")
            bomb_x = memory.read_u8(0x080, "RAM")
            bomb_y = memory.read_u8(0x094, "RAM")
            dx = link_x - bomb_x
            dy = link_y - bomb_y
            distance = math.sqrt(dx * dx + dy * dy)
            if distance < 0x20 then
                if math.abs(dx) > math.abs(dy) then
                    if dx > 0 then
                        direction = 0x1
                    else
                        direction = 0x2
                    end
                else
                    if dy > 0 then
                        direction = 0x4
                    else
                        direction = 0x8
                    end
                end
                memory.write_u8(0xd3, 0x20, "RAM")
                memory.write_u8(0xc0, direction, "RAM")
                memory.write_u8(mem_iframes, 0x20, "RAM")
                memory.write_u8(0x601, 0x08, "RAM")
                updateHearts(-0.5)
                if getHearts() <= 0 and memory.read_u8(0x12) ~= 0x11 then
                    memory.write_u8(0xe5, 0x4, "RAM")
                    memory.write_u8(0x12, 0x11, "RAM")
                end
            end
            
        end

    end

    if task == "arrowRecoil" then 
        memory.write_u8(0x65a, 0x01, "RAM")
        memory.write_u8(0x659, 0x01, "RAM")
        if memory.read_u8(0xbe, "RAM") == 0x10 then
            memory.write_u8(0xd3, 0x20, "RAM")
            link_direction = memory.read_u8(0x098, "RAM")
            if link_direction == 0x01 then
                link_direction = 0x02
            elseif link_direction == 0x02 then
                link_direction = 0x01
            elseif link_direction == 0x04 then
                link_direction = 0x08
            elseif link_direction == 0x08 then
                link_direction = 0x04
            end


            memory.write_u8(0xc0, link_direction, "RAM")
        end       
    end

    if task == "hylianArrow" then 
        if memory.read_u8(0xbe, "RAM") == 0x10 and getB() then
            arrow_x = memory.read_u8(0x082, "RAM")
            arrow_y = memory.read_u8(0x096, "RAM")
            arrow_direction = memory.read_u8(0x0aa, "RAM")
            if arrow_direction == 0x01 then
                arrow_x = arrow_x - 0x10
            elseif arrow_direction == 0x02 then
                arrow_x = arrow_x + 0x10
            elseif arrow_direction == 0x04 then
                arrow_y = arrow_y - 0x10
                -- arrow_x = arrow_x - 0x04
            elseif arrow_direction == 0x08 then
                arrow_y = arrow_y + 0x10
                -- arrow_x = arrow_x - 0x04
            end

        
            memory.write_u8(0x098, arrow_direction, "RAM")
            memory.write_u8(0x070, arrow_x, "RAM")
            memory.write_u8(0x084, arrow_y, "RAM")
        else 
            memory.write_u8(0x0be, 0x00, "RAM")
        end     
    end

    if task == "drawBow" then
        if memory.read_u8(mem_current_item) == 2 and getB() and arrow_is_flying == false then                
                memory.write_u8(0x0aa, prev_link_direction, "RAM")
                arrow_offset = math.floor(bow_strength / 6)
                if arrow_offset > 15 then
                    arrow_offset = 15
                end

                if prev_link_direction == 0x01 then
                    memory.write_u8(0x082, prev_link_x + 16 - arrow_offset, "RAM")
                    memory.write_u8(0x096, prev_link_y, "RAM")
                elseif prev_link_direction == 0x02 then
                    memory.write_u8(0x082, prev_link_x - 16 + arrow_offset, "RAM")
                    memory.write_u8(0x096, prev_link_y, "RAM")
                elseif prev_link_direction == 0x04 then
                    memory.write_u8(0x096, prev_link_y + 16 - arrow_offset, "RAM")
                    memory.write_u8(0x082, prev_link_x, "RAM")
                elseif prev_link_direction == 0x08 then
                    memory.write_u8(0x096, prev_link_y - 16 + arrow_offset, "RAM")
                    memory.write_u8(0x082, prev_link_x, "RAM")
                end
            

            bow_strength = bow_strength + 10
            if bow_strength >= 180 then
                bow_strength = 180
            end
        else
            arrow_is_flying = true
            bow_strength = bow_strength - 3
            if bow_strength < 0 then
                bow_strength = 0
                memory.write_u8(0x0be, 0x0, "RAM")
            end
        end
        if memory.read_u8(0x0be, "RAM") == 0x0 and arrow_is_flying == true then
            arrow_is_flying = getB()
        end 
    end

    if task == "fastArrow" or task == "slowArrow" then
        if memory.read_u8(0x0be, "RAM") == 0x10 then
            if arrow_is_flying then
                if memory.read_u8(0x0aa, "RAM") == 0x01 then
                    delta_arrow_x = 1
                    delta_arrow_y = 0
                elseif memory.read_u8(0x0aa, "RAM") == 0x02 then
                    delta_arrow_x = -1
                    delta_arrow_y = 0
                elseif memory.read_u8(0x0aa, "RAM") == 0x04 then
                    delta_arrow_x = 0
                    delta_arrow_y = 1
                elseif memory.read_u8(0x0aa, "RAM") == 0x08 then
                    delta_arrow_x = 0
                    delta_arrow_y = -1
                end
                
                
                if task == "fastArrow" then
                    delta_arrow_x = delta_arrow_x * 20
                    delta_arrow_y = delta_arrow_y * 20
                else
                    delta_arrow_x = delta_arrow_x * 1
                    delta_arrow_y = delta_arrow_y * 1
                end

                memory.write_u8(0x082, prev_arrow_x + delta_arrow_x, "RAM")
                memory.write_u8(0x096, prev_arrow_y + delta_arrow_y, "RAM")
            else 
                arrow_is_flying = true
            end
        else
            arrow_is_flying = false
        end
    end

    if task == "moveAndShoot" then
        if memory.read_u8(0x0be, "RAM") == 0x10 then
            if arrow_is_flying then
                if memory.read_u8(0x0aa, "RAM") == 0x01 then
                    delta_arrow_x = 5
                    delta_arrow_y = bad_shot_offset
                elseif memory.read_u8(0x0aa, "RAM") == 0x02 then
                    delta_arrow_x = -5
                    delta_arrow_y = bad_shot_offset
                elseif memory.read_u8(0x0aa, "RAM") == 0x04 then
                    delta_arrow_x = bad_shot_offset
                    delta_arrow_y = 5
                elseif memory.read_u8(0x0aa, "RAM") == 0x08 then
                    delta_arrow_x = bad_shot_offset
                    delta_arrow_y = -5
                end
                
                memory.write_u8(0x082, prev_arrow_x + delta_arrow_x, "RAM")
                memory.write_u8(0x096, prev_arrow_y + delta_arrow_y, "RAM")
            else 
                arrow_is_flying = true
                if idle_counter < 5 then
                    bad_shot_offset = math.random(1, 3) 
                    if math.random(1, 2) == 1 then
                        bad_shot_offset = -bad_shot_offset
                    end
                else 
                    bad_shot_offset = 0
                end
            end
        else
            arrow_is_flying = false

        end
    end


    if memory.read_u8(0x70, "RAM") ~= prev_link_x or memory.read_u8(0x84, "RAM") ~= prev_link_y then
        idle_counter = 0
    else
        idle_counter = idle_counter + 1
    end

    if (prev_room_kill < memory.read_u8(0x034f, "RAM")) then
        kill_combo = kill_combo + 1
    end

    if prev_hearts > getHearts() then
        kill_combo = 0
    end

    prev_link_x = memory.read_u8(0x70, "RAM")
    prev_link_y = memory.read_u8(0x84, "RAM")
    prev_link_direction = memory.read_u8(0x098, "RAM")

    
    prev_arrow_x = memory.read_u8(0x082, "RAM")
    prev_arrow_y = memory.read_u8(0x096, "RAM")
    prev_arrow_direction = memory.read_u8(0x0aa, "RAM")
    prev_bomb_status = memory.read_u8(0x0bc, "RAM")
    prev_arrow_status = memory.read_u8(0x0be, "RAM")
    prev_coins = memory.read_u8(0x66d, "RAM")
    prev_keys = memory.read_u8(0x66e, "RAM")
    prev_bombs = memory.read_u8(mem_bomb_count, "RAM")
    
    


    prev_hearts = getHearts()
    prev_room_kill = memory.read_u8(0x034f, "RAM")



	if game ~= "theStressTest" then
        if state_success[state] == "enter_d1" then
            if reachedDungeon() then
                sendCompleted()
            end
        else 
            if completedDungeon() then
                sendCompleted()
            end
        end
	end


	if game == "theStressTest" then
        local roomNumber = memory.read_u8(0xec, "RAM")
        local death = getHearts() <= 0
        
		client.speedmode(speed, false)
		if game_loop_save_state == null then
			savestate.load(stress_tests[task].file)
			speed = 100
			game_loop_save_state = memorysavestate.savecorestate()
		end
		
		if roomNumber == stress_tests[task].roomNumber then
			sendLoopCompleted()
			memorysavestate.loadcorestate(game_loop_save_state)
		end
		
		if death == true then
			sendDied()
			memorysavestate.loadcorestate(game_loop_save_state)
        end
	end
end

return rom

