
local activity = {}
-- Rom Specific Instructions
local mario3 = require('Activities/QARomScripts/mario3')
local megaman3 = require('Activities/QARomScripts/megaman3')
local zelda1 = require('Activities/QARomScripts/zelda1')
local kirby2 = require('Activities/QARomScripts/kirby2')

activity.title = "The QA Department"
activity.initalized = false
speed = 100

local initalized = false

local start_countdown = -1
local right_padding = 170 
local prev_room = null
local is_frozen = false

local racing = false
local finished = false
local level_finished = false
local time_left = '00:00:00'
local total_seconds = 0;
local start_time = null	
local countdown_time = null
local current_rom = null
local current_game = null
local current_task = null
local current_state = null
local alive = true
local vdo_text = ''
local onscreen_text = ''
local vdo_input = null
local onscreen_text_input = null
local loop_counter = 0
local guess_form
local guess_picture

highest_reproduction_score = 0
prev_reproduction_score = 0
local highest_reproduction_save_state = null

local vdo_link = "https://vdo.ninja/beta/?push=reactvts_qa_%s_%s&room=the_qa_department_%s&l=%s&as&broadcast&vd=0&noheader"


function buildForm() 
	forms.setsize(setup_window, 340, 440)
	forms.label(setup_window, "VDO.Ninja Link", 20, 290, 260, 20)
	vdo_input = forms.textbox(setup_window, vdo_text, 300, 60, null, 20, 310, true)
	forms.label(setup_window, "Guess the Bug (Will show on your screen):", 20, 380, 260, 20)
	onscreen_text_input = forms.textbox(setup_window, onscreen_text, 300, 20, null, 20, 400)
end

function reloadState() 
	savestate.load('./Saves/' .. current_rom.name .. '-' .. current_state .. '.state')
end


function sendCompleted()
	print("Task Completed")
	local send_string = string.format('{"event":"client-message_sent","data":{"id":"%s","clientId":"%s","version":"%s","action":"completed"},"channel":"presence-%s-game"}',
	config.user_id, config.name, config.version, config.roomcode)
	paused = true;
	racing = false
	finished = true
	client.pause()			
	client.speedmode(100, false)
	comm.ws_send(config.ws_id, send_string, true)
end

function loadRom(rom)
	print("loading")
	print(rom)
	if current_rom == null or current_rom.name ~= rom then
		current_rom = null

		if rom == 'mario3' then
			current_rom = mario3
		end
		if rom == 'megaman3' then
			current_rom = megaman3
		end
		if rom == 'zelda1' then
			current_rom = zelda1
		end

		if rom == 'kirby2' then
			current_rom = kirby2
		end
	end

	if current_rom == null then
		print('No rom loaded')
		return false
	else 
		
		loadGame(config.games[current_rom.name])
		client.unpause()
		savestate.load('./Saves/' .. current_rom.name .. '-intro.state')
		return true
	end
end

function drawSidebox(hex1, hex2, hex3)
    -- Extract RGBA components from hex1
    local r1 = (hex1 >> 24) & 0xFF
    local g1 = (hex1 >> 16) & 0xFF
    local b1 = (hex1 >> 8) & 0xFF
    local o1 = hex1 & 0xFF

    -- Extract RGBA components from hex2
    local r2 = (hex2 >> 24) & 0xFF
    local g2 = (hex2 >> 16) & 0xFF
    local b2 = (hex2 >> 8) & 0xFF
    local o2 = hex2 & 0xFF

    -- Extract RGBA components from hex3 if provided, otherwise use hex2
    local r3, g3, b3, o3
    if hex3 then
        r3 = (hex3 >> 24) & 0xFF
        g3 = (hex3 >> 16) & 0xFF
        b3 = (hex3 >> 8) & 0xFF
        o3 = hex3 & 0xFF
    else
        r3, g3, b3, o3 = r2, g2, b2, o2
    end

    local x = client.bufferwidth()
    local y = 0
    local w = right_padding
    local h = client.bufferheight()

    local current_color = nil
    local half_h = h / 2

    if hex3 then
        for i = 0, half_h - 1 do
            current_color = forms.createcolor(
                r1 + i * ((r2 - r1) / half_h),
                g1 + i * ((g2 - g1) / half_h),
                b1 + i * ((b2 - b1) / half_h),
                o1 + i * ((o2 - o1) / half_h)
            )
            gui.drawRectangle(x, y + i, w, 1, current_color, current_color)
        end

        for i = 0, half_h - 1 do
            current_color = forms.createcolor(
                r2 + i * ((r3 - r2) / half_h),
                g2 + i * ((g3 - g2) / half_h),
                b2 + i * ((b3 - b2) / half_h),
                o2 + i * ((o3 - o2) / half_h)
            )
            gui.drawRectangle(x, y + half_h + i, w, 1, current_color, current_color)
        end
    else
        for i = 0, h, 1 do
            current_color = forms.createcolor(
                r1 + i * ((r2 - r1) / h),
                g1 + i * ((g2 - g1) / h),
                b1 + i * ((b2 - b1) / h),
                o1 + i * ((o2 - o1) / h)
            )
            gui.drawRectangle(x, y + i, w, 1, current_color, current_color)
        end
    end
end


function drawSidebarText(text, x, y, size, align)
    -- local font = "Times New Roman"
    -- local font = "Arial"
    local font = nil
    
    if align then
    else 
        align = "left"
    end
    
    -- gui.drawString(x, y, text, color, 0x00000000, size, "Arial", "bold", "center", "middle" );

    --shadow drawn first
    gui.drawString( client.bufferwidth() + x + 1,  y + 1 + 9, text, 0xFF4d2c13, 0x00000000, size, font, "bold", align , "top" );
    --text drawn on top
    gui.drawString( client.bufferwidth() + x, y + 9, text, 0xFFFFFFFF, 0x00000000, size, font, "bold", align, "top" );
end

function drawSidebarCounter(text, size, position)
	local offset = 0
	if position == "top" then
		offset = 0 - size;
	elseif position == "middle" then
		offset = 0 + size;
	elseif position == "bottom" then
		offset = 0 + size + size;
	end
	gui.drawString( client.bufferwidth() + (right_padding / 2), client.bufferheight() / 2 + offset , text,  0xFF4d2c13, 0x00000000, size, "Arial", "bold", "center", "middle" );
    gui.drawString( client.bufferwidth() + (right_padding / 2) - 1, client.bufferheight() / 2 - 1 +  offset , text, 0xFFFFFFFF, 0x00000000, size, "Arial", "bold", "center", "middle" );
    
end

function drawLogo()
    drawSidebarText("T", 2, client.bufferheight() - 40, 10)
    drawSidebarText("HE", 9, client.bufferheight() - 38, 8)
    drawSidebarText("QA", 17, client.bufferheight() - 44, 20)
    drawSidebarText("D", 2, client.bufferheight() - 31, 18)
    drawSidebarText("EPARTMENT", 15, client.bufferheight() - 26, 11)
end

function activity.drawGUI()
	local x = client.bufferwidth() + right_padding 

	drawSidebox(0xFF000000, 0xFF5b3100, 0xFFD0AD85)
    drawLogo()


	if start_countdown > 0 and racing == false and finished == false then
		drawSidebarCounter(start_countdown, 64)
	end

	if start_countdown == -1 and racing == false then
		drawSidebarText("WAITING", right_padding / 2, 0, 20, "center")
		drawSidebarText("TO START", right_padding / 2, 18, 20, "center")
	end

	if racing == false and finished == true then
		if current_game == 'theStressTest' then
			drawSidebarCounter("Finished!", 32, "top")
			drawSidebarCounter(loop_counter .. " Loops", 32, "middle")
		elseif current_game == 'pleaseReproduce' then
			drawSidebarCounter("Finished!", 32, "top")
			drawSidebarCounter("Accuracy", 16, "middle")
			drawSidebarCounter(math.floor(highest_reproduction_score * 100) .. "%" , 16, "bottom")
		else 
			drawSidebarCounter("Finished!", 32)
		end
	end

	if racing then
		if current_game == 'theStressTest' then
			drawSidebarCounter(time_left, 32, "top")
			drawSidebarCounter(loop_counter .. " Loops", 32, "middle")
		elseif current_game == 'pleaseReproduce' then
			drawSidebarCounter(time_left, 32, "top")
			drawSidebarCounter("Current: " .. math.floor(prev_reproduction_score * 100) .. "%", 16, "middle")
			drawSidebarCounter("Best: " .. math.floor(highest_reproduction_score * 100) .. "%", 16, "bottom")
			
		else 
			drawSidebarCounter(time_left, 32)
		end
	end
	
	-- -- if game_mode == 'theBugReport' then
	-- 	gui.drawString( (client.bufferwidth() / 2) + 2, (client.bufferheight() / 2) + 2, onscreen_text, 0xFF000000, 0x00000000, 18, "Arial", "bold", "center", "middle" );
	-- 	gui.drawString( (client.bufferwidth()) / 2, client.bufferheight() / 2, onscreen_text, 0xFFFFFF00, 0x00000000, 18, "Arial", "bold", "center", "middle" );
	-- -- end 
end

function init()
	if activity.initalized == false then
		log_console('Initializing the debug console - QA Department')
		frame_count = 0
		racing = false
		connected = false
		client.speedmode(100, false)
		buildForm()
		client.SetGameExtraPadding(0,0,right_padding,0)
		activity.initalized = true
	end
end

function activity.reset()
	client.closerom()
	log_console('Reset the debug console')
	frame_count = 0
	-- preHexScore = 0
	racing = false
	connected = false
	start_countdown = 0
	prev_room = null
	is_frozen = false
	speed = 100
	last_score = 0
	level_finished = false
	time_left = '00:00:00'
	total_seconds = 0;
	select_cooldown = 0
	alive = true

end

function activity.frame(frame_count, config)
	onscreen_text = string.upper(forms.gettext(onscreen_text_input))

	if prev_room ~= config.roomcode then
		prev_room = config.roomcode
		activity.initalized = false
		client.closerom()
		init()
		return
	end
	
	if activity.initalized == false then
		prev_room = config.roomcode
		init()
		return
	end	
	
	forms.settext(vdo_input, string.format(vdo_link, config.roomcode, config.name, config.roomcode, config.name))

	if activity.initalized == true then
		gui.clearGraphics()
		activity.drawGUI()
		

		if racing then
			if frame_count % 10 == 0 then
				local temp_seconds =  total_seconds - (os.time() - start_time) -- subtract one second
				h = math.floor(temp_seconds / 3600)
				temp_seconds = temp_seconds - (h * 3600)
				m = math.floor(temp_seconds / 60)
				s = temp_seconds - (m * 60)
				time_left = string.format("%02d:%02d:%02d", h, m, s)     
			end
			
			client.speedmode(speed, false)
			
			if is_rom_loaded() then
				current_rom.frame(frame_count)

				if current_game == 'pleaseReproduce' then
					if frame_count % 60 == 0 then
						sendReproductionScore(highest_reproduction_score)
					end
				end

				if start_countdown == -1 then 
					console.log('stopping task')
					current_rom.stopTask()
				end
			end
		end
	
	end
end


function activity.receive(data, config)
	-- print("receiving data")
	if data.action == "countdown" then
		finished = false
		racing = false
		if current_rom ~= null then
			current_rom.stopTask()
			client.pause()
		end 
		time_left = '00:00:00'
		start_countdown = data.value
		countdown_time = os.time()
		client.speedmode(100, false)
		-- print('Countdown ' .. start_countdown)
		if current_rom == null or current_rom.name ~= data.rom then
			loadRom(data.rom)
		end		
	end

	if data.action == "rom" then
		
		print("got rom")
		loadRom(data.rom)
		finished = false
		client.pause()
	end



	if data.action == "start" then
		if current_rom == null or current_rom.name ~= data.rom then
			loadRom(data.rom)
		end

		current_game = data.game
		current_task = data.task
		current_rom.setTask(data.game, data.task, data.state)	
		current_state = data.state	
	

		if savestate.load('./Saves/' .. current_state) then
			paused = false
			speed = 100
			loop_counter = 0
			start_time = os.time()
			time_left = data.time
			h, m, s = data.time:match('(%d+):(%d+):(%d+)')
			total_seconds = h * 3600 + m * 60 + s
			racing = true
		else 
			print('Failed to load state')
			return
		end
	end
	if data.action == "pause" then
		print('Freezing')
		is_frozen = true
	end
	if data.action == "stop" then
		print("stopping")
		racing = false
		finished = false
		paused = true;
		start_countdown = -1
		start_time = -1
		client.pause()			
		client.speedmode(100, false)
	end
	if data.action == "update" then
		if data.time == '00:00:00' then
			print("finished")
			print(racing)
			print(current_game)
			start_countdown = -1
			if racing then
				finished = true
				if current_game == "pleaseReproduce" then
					memorysavestate.loadcorestate(highest_reproduction_save_state)
					emu.frameadvance()
				end
			end
			racing = false
			paused = true;
			start_time = -1
			client.pause()			
			client.speedmode(100, false)
		end
		time_left = data.time
		h, m, s = data.time:match('(%d+):(%d+):(%d+)')
		total_seconds = h * 3600 + m * 60 + s
		start_time = os.time()
	end
	if data.action == "clear" then
		finished = false
		current_game = null
		current_task = null
		client.speedmode(100, false)
	end
end

function sendDied()
	local send_string = string.format('{"event":"client-message_sent","data":{"id":"%s","clientId":"%s","version":"%s","action":"died"},"channel":"presence-%s-game"}',
	config.user_id, config.name, config.version, config.roomcode)
	comm.ws_send(config.ws_id, send_string, true)
end

function sendLoopCompleted()
	loop_counter = loop_counter + 1
	speed = speed * 1.1

	local send_string = string.format('{"event":"client-message_sent","data":{"id":"%s","clientId":"%s","version":"%s","action":"loopCompleted", "value":"%s"},"channel":"presence-%s-game"}',
	config.user_id, config.name, config.version, loop_counter, config.roomcode)
	comm.ws_send(config.ws_id, send_string, true)
end

function getReproductionScore(conditions)
    -- console.clear()
    local triggered = ""    
    local score = 0
    for i = 1, #conditions do
        if conditions[i] then
            local current_condition = conditions[i]
            if type(current_condition.mem) ~= "table" then
                local mem_value = memory.read_u8(current_condition.mem, "RAM")
                local diff = math.abs(mem_value - current_condition.value)
                if diff == 0 and current_condition.threshold == 0 then
                    score = score + current_condition.percentage
                    
                    triggered = triggered .. " " .. current_condition.label .. " "
                elseif diff <= current_condition.threshold then
                    local ratio = diff / current_condition.threshold
                    local weighted_score = (1 - ratio) * current_condition.percentage
                    score = score + weighted_score
                    triggered = triggered .. " " .. current_condition.label .. " "
                
                end
            else
                for j = 1, #current_condition.mem do
                    local condition_break = false
                    local condition_bool = true
                    local condition_index = nil

                    for k = 1, #current_condition.mem[j].conditions do
                        local mem_value = memory.read_u8(current_condition.mem[j].conditions[k].mem, "RAM")
                        local diff = math.abs(mem_value - current_condition.mem[j].conditions[k].value)
                        if diff > current_condition.mem[j].conditions[k].threshold then
                            condition_bool = false
                            break
                        end
                    end

                    if condition_bool then
                        local mem_value = memory.read_u8(current_condition.mem[j].mem, "RAM")
                        local diff = math.abs(mem_value - current_condition.value)
                        if diff == 0 and current_condition.threshold == 0 then
                            score = score + current_condition.percentage
                            triggered = triggered .. " " .. current_condition.label .. " "
                            condition_break = true
                        elseif diff <= current_condition.threshold then
                            local ratio = diff / current_condition.threshold
                            local weighted_score = (1 - ratio) * current_condition.percentage
                            
                            score = score + weighted_score
                            triggered = triggered .. " " .. current_condition.label .. " "
                            condition_break = true
                        end
                    end
                    if condition_break then
                        break
                    end
                end
            end
        end
    end
    if score ~= prev_reproduction_score then
        prev_reproduction_score = score
        if score > highest_reproduction_score then
            highest_reproduction_score = score
			highest_reproduction_save_state = memorysavestate.savecorestate()
			if highest_reproduction_score == 1 then
				sendReproductionScore(highest_reproduction_score)
				sendCompleted()
			end
        end
    end
    return score
end


function sendReproductionScore(score)
	local send_string = string.format('{"event":"client-message_sent","data":{"id":"%s","clientId":"%s","version":"%s","action":"reproductionScore", "value": "%s"},"channel":"presence-%s-game"}',
	config.user_id, config.name, config.version, score, config.roomcode)
	comm.ws_send(config.ws_id, send_string, true)
end

-- function sendBuzzer()
-- 	local send_string = string.format('{"event":"client-message_sent","data":{"id":"%s","clientId":"%s","version":"%s","action":"buzzer"},"channel":"presence-%s-game"}',
-- 	config.user_id, config.name, config.version, config.roomcode)
-- 	comm.ws_send(config.ws_id, send_string, true)
-- end




return activity