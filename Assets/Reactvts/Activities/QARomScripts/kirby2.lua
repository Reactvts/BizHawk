local rom = {}
rom.name = 'kirby2'


local game = null
local task = null
local state = null
local stress_test = null


local stress_tests = {
	['gameLoopBonus'] = {
		file = "./Reactvts/Saves/kirby2-bonus.state",
	},

}

local state_success = {
    ["kirby2-bonus.state"] = 'two_or_better' 
}



local lives_value = {
	[0] = 0xff,
	[1] = 0x07,
	[2] = 0x0f,
	[3] = 0x17,
	[4] = 0x1f,
	[5] = 0x27,
	[6] = 0x2f
}


local prev_secs = null
local prev_in_air = false
local prev_fast_fall = false
local death_fanfare = false
local prev_health = null
local fall_frames = 0
local has_moved = false



-- generic

-- local prev_secs = null
local game_loop_save_state = null
local frame_count = 0




function isInvincible()
	return (memory.read_u8(0x05f9, "RAM") > 0)
end

function isInAir()
    return memory.read_u8(0x5fb, "RAM") == 0x00
end

function getHealth() 
	local hex_health = memory.read_u8(0x0597, "RAM")
	for index, value in pairs(lives_value) do
        if value == hex_health then
            return index
        end
    end
	return 0
end


function reachedBonus()
    local fanfare = memory.read_u8(0x783, "RAM")
    return fanfare == 0x05
end


function rom.setTask(nextGame, nextTask, nextState)
	game = nextGame
	task = nextTask
    state = nextState
end

function rom.stopTask()
	game = null
	task = null
	
    prev_secs = null
    prev_in_air = false
    prev_fast_fall = false
    death_fanfare = false
    prev_health = null
    fall_frames = 0
    has_moved = false

    
    -- Generic variables
    
    speed = 100
    frame_count = 0
    
    
    
    -- generic
    
    
    game_loop_save_state = null
    frame_count = 0

	client.pause()
end



function rom.frame(frame_count) 
	nes.setdispbackground(false)

    if task == "autoRun" then
        local controller1 = joypad.get(1)
        if(controller1["Left"]) then
            joypad.set( { ["Left"] = false, ["Right"] = true }, 1 );
        else 
            joypad.set( { ["Right"] = true}, 1 );
        end
    end

    if task == "gameboyMode" then
        memory.write_u8(0x036, 0xdb, "RAM")
        if memory.read_u8(0x5e0, "RAM") == 0x01 then
            memory.write_u8(0x5e2, 0xff, "RAM")
        end
    end

    if task == "shiftLevel" then
        memory.write_u8(0x1a3, 0x0f, "RAM")
    end

    if task == "floorIsSpeedy" then
        if isInAir() == false then
            client.speedmode(200, false)
        else 
            client.speedmode(100, false)
        end
    end

    if task == "instantSwallow" then
        if memory.read_u8(0x5e0, "RAM") == 0x01 then
            joypad.set( { ["Down"] = true }, 1 );
        end
    end

    if task == "instantSpit" then
        if memory.read_u8(0x5e0, "RAM") == 0x01 then
            joypad.set( { ["B"] = true }, 1 );
        end
    end

    if task == "alwaysMix" then
        if memory.read_u8(0x5e0, "RAM") == 0x01 then
            memory.write_u8(0x5e7, 0x02, "RAM")
        end
    end

    if task == "eatingHeals" then
        if memory.read_u8(0x5e1, "RAM") == 0x0b then
            local health = getHealth()
            if health < 6 then
                health = health + 1
                memory.write_u8(0x0597, lives_value[health], "RAM")
                memory.write_u8(0x5e1, 0x00, "RAM")
            end
        end
    end

    if task == "singleUse" then
        if prev_using_power and memory.read_u8(0x5e1, "RAM") ~= 0x0c then
            joypad.set( { ["Select"] = true }, 1 );
        end
    end

    if task == "airIsGravy" then
        if isInAir() then
            client.speedmode(50, false)
        else 
            client.speedmode(100, false)
        end
    end

    if task == "airIsSpeedy" then
        if isInAir() then
            client.speedmode(200, false)
        else 
            client.speedmode(100, false)
        end
    end
    

    if task == "fallDamage" then 
        if isInAir() == false and prev_fast_fall == true and isInvincible() == false then  -- player is taking damage or powering up
            local health = getHealth()
            if health > 1 then
                health = health - 1
                memory.write_u8(0x0597, lives_value[health], "RAM")
                memory.write_u8(0x05f9, 0x3f, "RAM")
            else 
                memory.write_u8(0x0597, lives_value[0], "RAM")
            end
        end
    end

    if task == "parallax" then
        memory.write_u8(0x180, 0x05, "RAM")
    end

    if task == "corruptedGraphics" then
        memory.write_u8(0x035, 0xdd, "RAM")
    end

    if task == "invisibleSprites" then
        memory.write_u8(0x36, 0x08, "RAM")
    end

    if task == "invisibleBackground" then
        memory.write_u8(0x36, 0x10, "RAM")
    end

    if task == "blindJump" then
        if isInAir() then
            memory.write_u8(0x36, 0x10, "RAM")
        else
            memory.write_u8(0x36, 0x18, "RAM")
        end
    end

    if task == "noFlyZone" then
        -- add check for if ufo
        local inputs = memory.read_u8(0x03a, "RAM")
        if isBitSet(inputs, 3) then
            memory.write_u8(0x56a, 0x4, "RAM")
        end
    end

    if task == "noJumping" then
        local inputs = memory.read_u8(0x03a, "RAM")			
        if isInAir() and isBitSet(inputs, 7) then
            memory.write_u8(0x56a, 0x4, "RAM")
        end
    end

    if task == "noIframes" then 
        memory.write_u8(0x05f9, 0x00, "RAM")
    end

    if task == "floorIsSticky" then
        if isInAir() == false then
            client.speedmode(50, false)
        else 
            client.speedmode(100, false)
        end
    end

    if task == "floorIsSpeedy" then
        if isInAir() == false then
            client.speedmode(200, false)
        else 
            client.speedmode(100, false)
        end
    end

    if task == "airIsGravy" then
        if isInAir() then
            client.speedmode(50, false)
        else 
            client.speedmode(100, false)
        end
    end

    if task == "airIsSpeedy" then
        if isInAir() then
            client.speedmode(200, false)
        else 
            client.speedmode(100, false)
        end
    end



    prev_in_air = isInAir()
	prev_fast_fall = memory.read_u8(0x201, 'RAM') == 0x0f
    prev_using_power = memory.read_u8(0x5e1, 'RAM') == 0x0c


	if game ~= "theStressTest" then
        if state_success[state] == nil then
            if reachedBonus() then
                sendCompleted()
            end
        end
	end


	if game == "theStressTest" then
        if state_success[state] == 'two_or_better' then
            local bonus_height = memory.read_u16_le(0xe0, "RAM")
            local fanfare = memory.read_u8(0x783, "RAM")
        
            client.speedmode(speed, false)
            if game_loop_save_state == null then
                print("loading state")
                savestate.load(stress_tests[task].file)
                speed = 100
                game_loop_save_state = memorysavestate.savecorestate()
            end
            if fanfare ~= 0x05 then 
                if bonus_height <= 0x121 then
                    sendLoopCompleted()
                    memorysavestate.loadcorestate(game_loop_save_state)
                else 
                    sendDied()
        			memorysavestate.loadcorestate(game_loop_save_state)
                end
            end
        end

	end
end

return rom

