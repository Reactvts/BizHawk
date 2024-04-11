local json = require('Utils/json')
require('Utils/dump')
local video_armageddon = require('Activities/videoArmageddon')
-- local videoArmageddonXX = require('Activities/videoArmageddon20XX') 

apiUrl = "https://reactvts.com:3030"
-- apiUrl = "http://localhost:3030"

local current_activity = null
local right_padding = 125
local last_connected_name = ""
local last_room_code = ""


version = '2.9.1.6'

GAMES_FOLDER = './Roms'



config = {
    ["name"] = "",
    ["roomcode"] = "",
    ["games"] = {},
    ["current_game"] = null,
    ["volume"] = 0.7,
    ["ws_id"] = null,
    ['ws_lobby_id'] = null,
    ["socket_id"] = null,
    ["auth"] = null,
    ["user_id"] = null,
    ["version"] = version,
    ["connection_status"] = "Not Connected",
    ['auth'] = null
}

console_log = ""





-- Functions

function writeData(filename, data, mode)
	local handle, err = io.open(filename, mode or 'w')
	if handle == nil then
		log_message(string.format("Couldn't write to file: %s", filename))
		log_message(err)
		return
	end
	handle:write(data)
	handle:close()
end

-- saves primary config file
function saveConfig()
    local saveConfig = {
        ["name"] = config.name,
        ["games"] = config.games,
        ["volume"] = config.volume,
    }
	write_data('./config.lua', 'configFile=\n'..dump(saveConfig))
end

-- loads primary config file
function loadConfig()
	local fn = loadfile('./config.lua')
	if fn ~= nil then 
        fn() 
        forms.settext(name_text, configFile.name)
        config.name = configFile.name
        config.volume = configFile.volume
        config.games = configFile.games
        
        
    end
    
	return fn ~= nil
end

--  function printLog(msg)
--     print(msg)
--     console_log = os.date('%Y-%m-%d %I:%M:%S%p') .. ": " .. msg ..  "\r\n\z" .. console_log
--     forms.settext(console_window, console_log)

-- end

printLog = function(msg)
    print(msg)
    console_log = os.date('%Y-%m-%d %I:%M:%S%p') .. ": " .. msg ..  "\r\n\z"
    forms.settext(console_window, console_log)
end

function clamp(lower, val, upper)
    if lower > upper then lower, upper = upper, lower end
    return math.max(lower, math.min(upper, val))
end

function log_console(msg)
	print(msg)
end

function drawStatus(color, text)
    status_color = "#F6E05E"
    if color == "red" then 
        status_color = "#EF4444"
    end
    if color == 'green' then
        status_color = "#34D399"
    end
    -- error_picture = forms.pictureBox( setup_window, 0, 0, 340, 45 );
    forms.drawRectangle( picture, 0, 50, 600, 100, status_color, status_color);
    forms.drawText( picture, 225, 80, text, "black", status_color, 24, "Inter", "600", "center", "middle" );
    forms.refresh(picture)
end

local function setConnectionStatus(status)
    config.connection_status = status
end

local function disconnect()
    gui.clearGraphics()
    forms.settext(connect_btn, "Connect")
    client.closerom()
    last_connected_name = ""
    last_room_code = ""
    config.ws_id = null
    config.ws_lobby_id = null
    config.socket_id = null
    config.auth = null
    config.user_id = null
    config.connection_status = "Not Connected"
    current_activity.reset()
end



local function connectToLobbyWSS()
    
    forms.settext(connect_btn, "Connecting...")
    if forms.gettext(name_text) == "" or string.len(forms.gettext(name_text)) > 9 or string.len(forms.gettext(roomcode_text)) ~= 4 then
        forms.settext(connect_btn, "Connect")
        printLog('Please enter a name (max 9 characters) and a 4 letter room code')
        drawStatus("red", "Missing Name or Room Code")
        return
    end
    config.name = forms.gettext(name_text)
    config.roomcode = forms.gettext(roomcode_text)
    last_connected_name = config.name
    last_room_code = config.roomcode
    local temp_ws_id = comm.ws_open('wss://reactvts.com:6001/app/jtcGSRD9za4QHWhTa3YTdQ9pFVRF9SH6brc7QvShUkxmP52Fsd?protocol=7&client=js&version=8.3.0&flash=false')
    local ws = comm.ws_receive(temp_ws_id);
    local response = json.parse(ws)
    config.socket_id = json.parse(response.data).socket_id
    config.ws_lobby_id = temp_ws_id
    comm.httpSetPostUrl(apiUrl .. "/pusher/auth")
    local authJson = comm.httpPost(apiUrl .. "/pusher/auth", "?socket_id=" .. config.socket_id .. "&channel_name=presence-" .. string.upper(config.roomcode) .. "-lobby&userType=client&name=" .. config.name)

    local auth_response = json.parse(authJson)
    
    if auth_response.error == true then
        printLog(" ")
        printLog("----------------------------------")
        printLog(auth_response.message)
        printLog("------------Error------------------")
        printLog(" ")
        drawStatus("red", auth_response.message) 
        disconnect()
        return
    end
    config.auth = auth_response.auth
    config.user_id = json.parse(auth_response.channel_data).user_id


    local sub_table = {
        ["event"] = "pusher:subscribe",
        ["data"] = {
            ["auth"] = config.auth,
            ["channel_data"] = "{\"user_id\":\"" .. config.user_id .. "\",\"user_info\":{\"type\":\"client\",\"name\":\"" .. config.name .. "\"}}",
            ["channel"] = "presence-" .. string.upper(config.roomcode) .. "-lobby",
            
        }
    }
    setConnectionStatus("connected")
    print('subscribing to lobby')
    comm.ws_send(config.ws_lobby_id, json.stringify(sub_table) , true)  
    printLog("Lobby Server Connection Established. Attempting to connect to game room " .. config.roomcode)
end

local function connectToWSS()
    forms.settext(connect_btn, "Connecting...")
    if(config.ws_id == null) then
        config.ws_id = config.ws_lobby_id
    end
    
    local authJson = comm.httpPost(apiUrl .. "/pusher/auth", "?socket_id=" .. config.socket_id .. "&channel_name=presence-" .. string.upper(config.roomcode) .. "-game&userType=client&name=" .. config.name)

    local auth_response = json.parse(authJson)
    
    if auth_response.error == true then
        printLog(" ")
        printLog("-----------------------------------")
        printLog(auth_response.message)
        printLog("------------Error------------------")
        printLog(" ")
        drawStatus("red", auth_response.message) 
        disconnect()
        return
    end
    config.auth = auth_response.auth
    config.user_id = json.parse(auth_response.channel_data).user_id


    local sub_table = {
        ["event"] = "pusher:subscribe",
        ["data"] = {
            ["auth"] = config.auth,
            ["channel_data"] = "{\"user_id\":\"" .. config.user_id .. "\",\"user_info\":{\"type\":\"client\",\"name\":\"" .. config.name .. "\"}}",
            ["channel"] = "presence-" .. string.upper(config.roomcode).. "-game",
            
        }
    }
    setConnectionStatus("subscribed")
    comm.ws_send(config.ws_id, json.stringify(sub_table) , true)  
    drawStatus("green", "Connected", picture)
    printLog("Server Connection Established. Attempting to connect to room " .. config.roomcode)

    local unsub_table = {
        ["event"] = "pusher:unsubscribe",
        ["data"] = {
            ["channel"] = "presence-" .. string.upper(config.roomcode) .. "-lobby"
        }
    }
    setConnectionStatus("subscribed")
    comm.ws_send(config.ws_id, json.stringify(sub_table) , true)  
    config.ws_lobby_id = null
    forms.settext(connect_btn, "Connected (Click to Refresh)")
end

local function connectTo()
    config.roomcode = forms.gettext(roomcode_text)
    drawStatus("yellow", "Connecting...", picture)

    if last_connected_name == config.name and last_room_code == config.roomcode and config.ws_id ~= null then
        connectToWSS()
        return
    else 
        disconnect();
        client.unpause()
        connectToLobbyWSS()
    end
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

function file_exists(f)
	local p = io.open(f, 'r')
	if p == nil then return false end
	io.close(p)
	return true
end

function is_rom_loaded()
	return emu.getsystemid() ~= 'NULL'
end

function loadGame(g)
	log_console('loadGame(' ..  g .. ')')
	local filename = g
	if not file_exists(filename) then
		log_console('ROM ' .. filename .. ' not found', g)
        config.ws_id = null
        printLog(" ")
        printLog("----------------------------------")
        printLog("ROM " .. filename .. " not found Please try again.")
        printLog("------------Error------------------")
        printLog(" ")
        drawStatus("red", filename .. " not found")

		return false
	end

	client.openrom(filename)

	if is_rom_loaded() then
		log_console(string.format('ROM loaded: %s "%s" (%s)', emu.getsystemid(), gameinfo.getromname(), gameinfo.getromhash()))
		client.reboot_core( );
		current_activity.initalized = true
		client.enablerewind(false)
		client.SetGameExtraPadding(0,0,right_padding,0)
		return true
	else
		log_console(string.format('Failed to open ROM "%s"', g))
        drawStatus("red", string.format('Failed to open ROM "%s"', g))
		return false
	end

end

function is_rom_loaded()
	return emu.getsystemid() ~= 'NULL'
end

function scanGames()
    drawStatus("yellow", string.format('Scanning Games', g))
    print('start scan')
    local games = get_dir_contents(GAMES_FOLDER)
    print('prepause')
    -- client.pause()
    for _, file in ipairs(games) do
        local fullPath = GAMES_FOLDER .. '/' .. file
        print('Scanning ' .. fullPath)
        client.pause()
        if file ~= '.' and file ~= '..' and file ~= '.gitignore' then
            print('opening ' .. fullPath)
            client.openrom(fullPath)
            if is_rom_loaded() then
                -- mario3hash
                print('hash: ' .. gameinfo.getromhash())
                if gameinfo.getromhash() == "6BD518E85EB46A4252AF07910F61036E84B020D1" then
                    config.games['mario3'] = fullPath
                end
            end
            client.closerom()
        end
    end
    client.unpause()
    drawStatus("Green", string.format('Scan Complete', g))
    saveConfig()
end

local function WSLobbyWatch (frame_count)
    if frame_count % 60 == 0 then
        printLog("Checking for messages " .. config.connection_status)
        if config.connection_status == "connected" or config.connection_status == "lobby"  then
            local fullResponse = ""
            local ws = comm.ws_receive(config.ws_lobby_id)
        
            while ws ~= "" do 
                fullResponse = fullResponse .. ws
                if(string.len(ws) < 1024) then
                    break
                end
                ws = comm.ws_receive(config.ws_lobby_id)
            end
    
            if fullResponse ~= "" then       
                print(fullResponse)
                local response = json.parse(fullResponse)
                if response.event == "pusher_internal:subscription_succeeded" then
                    printLog("Attempting to connect to channel " .. response.channel)
                    if response.channel == "presence-" .. string.upper(config.roomcode) .. '-lobby' then
                        local data = json.parse(response.data)
                        if data.presence.count > 1 then
                            local isRoom = false
                            for i, v in pairs(data.presence.ids) do
                                if string.sub(v, 1, 5) == "room-" then
                                    isRoom = true
                                    break
                                end
                            end
                            if isRoom then 
                                setConnectionStatus("lobby")
                                printLog("Connected to lobby")
                                return
                            end               
                        end
                    end
                    setConnectionStatus("Not Connected")
                    printLog(" ")
                    printLog("----------------------------------")
                    printLog("Room not found. Please try again.")
                    printLog("------------Error------------------")
                    printLog(" ")
                    drawStatus("red", "Room not found")
                    disconnect()
                    return
                end

                if response.event == "client-message_full" then
                    if(response.data.clientId == config.name) then
                        setConnectionStatus("Not Connected")
                        printLog(" ")
                        printLog("----------------------------------")
                        printLog("Room is full")
                        printLog("------------Error------------------")
                        printLog(" ")
                        drawStatus("red", "Room is full or locked")


                        gui.drawString(client.bufferwidth() / 2, client.bufferheight() / 2, "Sorry: Room is full or locked", 0xFFFFFF00, 0x00000000, 16, "Arial", "bold", "center", "bottom" );
                        disconnect()
                        return
                    end
                end

                if response.event == "client-message_let_in" and response.data.clientId == config.name then
                    connectToWSS()
                end
            end
            
        end
    end
    
end


local function WSWatch (frame_count)
    if frame_count % 10 == 0 then
        if config.connection_status == "connected" then
            local fullResponse = ""
            local ws = comm.ws_receive(config.ws_id)          

           
            while ws ~= "" do 
                fullResponse = fullResponse .. ws
                if(string.len(ws) < 1024) then
                    break
                end
                ws = comm.ws_receive(config.ws_id)
            end
    
            if fullResponse ~= "" then       
                local response = json.parse(fullResponse)
                if response.event == "pusher_internal:subscription_succeeded" then
                    printLog("Attempting to connect to channel " .. response.channel)
                    if response.channel == "presence-" .. string.upper(config.roomcode) then
                        local data = json.parse(response.data)
                        if data.presence.count > 1 then
                            local isRoom = false
                            for i, v in pairs(data.presence.ids) do
                                if string.sub(v, 1, 5) == "room-" then
                                    isRoom = true
                                    break
                                end
                            end
                            if isRoom then 
                                setConnectionStatus("subscribed")
                                printLog("Connected")
                                drawStatus("green", "Connected")
                                forms.settext(connect_btn, "Connected (Click to Refresh)")
                                return
                            end               
                        end
                    end
                    config.ws_id = null
                    config.socket_id = null
                    config.auth = null
                    config.user_id = null
                    setConnectionStatus("Not Connected")
                    printLog(" ")
                    printLog("----------------------------------")
                    printLog("Room not found. Please try again.")
                    printLog("------------Error------------------")
                    printLog(" ")
                    drawStatus("red", "Room not found or Wrong Version")
                    forms.settext(connect_btn, "Connect")
                    return
                end

            end
            
        end
        if config.connection_status == "subscribed" then

            if frame_count % (60 * 30) == 0 then
                comm.ws_send(config.ws_id, '{"event":"pusher:ping","data":{}}', true)
            end

            local fullResponse = ""
            local ws = comm.ws_receive(config.ws_id)  
            
            if ws == "" then
                return
            end

            while ws ~= "" do 
                while ws ~= "" do 
                    fullResponse = fullResponse .. ws
                    if(string.len(ws) < 1024) then
                        break
                    end
                    ws = comm.ws_receive(config.ws_id)
                end
                if fullResponse ~= "" then
                    local response = json.parse(fullResponse)
                    -- printLog("Received: " .. fullResponse)
                    if response.event == "client-message_full" then
                        if(response.data.clientId == config.name) then
                            setConnectionStatus("Not Connected")
                            printLog(" ")
                            printLog("----------------------------------")
                            printLog("Room is full")
                            printLog("------------Error------------------")
                            printLog(" ")
                            drawStatus("red", "Room is full or locked")
                            forms.settext(connect_btn, "Connect")
                            gui.drawString(client.bufferwidth() / 2, client.bufferheight() / 2, "Sorry: Room is full or locked", 0xFFFFFF00, 0x00000000, 16, "Arial", "bold", "center", "bottom" );
                            disconnect()
                            return
                        end
                    end
                    if response.event == "client-message_sent" then

                        current_activity.receive(response.data, config)
                    end
                end
                ws = ""
                ws = comm.ws_receive(config.ws_id)
            end
   
        end 
    end
    
end



-- FORM SETUP


forms.destroyall()
setup_window = null
connect_btn = null
button_text = "Connect"
console_log = ""
console_window = null 



local y = 10


-- 260
setup_window = forms.newform(340, 340 , "Reactvts.com | Join Room", main_cleanup)
picture = forms.pictureBox( setup_window, 0, 0, 340, 90 );
y = y + 90
forms.drawRectangle( picture, 0, 0, 600, 50, "#F6E05E", "#F6E05E");
forms.drawText( picture, 225, 25, "Reactvts v" .. version, "black", "#F6E05E", 40, "Inter", "600", "center", "middle" );
drawStatus("yellow", "Waiting to Connect...", picture)
forms.label(setup_window, "Name:", 45, y+3, 40, 20)
forms.label(setup_window, "(9 Letter Max)", 200, y+3, 120, 20)
name_text = forms.textbox(setup_window, 0, 100, 20, null, 90, y)
forms.settext(name_text, config.name)
y = y + 20
forms.label(setup_window, "Room Code:", 18, y+3, 70, 20)
forms.label(setup_window, "(4 Letter Room Code)", 200, y+3, 120, 20)
roomcode_text = forms.textbox(setup_window, 0, 100, 20, null, 90, y)
forms.settext(roomcode_text, config.roomcode)
y = y + 20
forms.label(setup_window, "Volume:", 37, y+3, 52, 20)
forms.label(setup_window, "(Item Sounds Only)", 200, y+3, 120, 20)
local volume_drop = forms.dropdown(setup_window, {   
    " 0", 
    " 1", 
    " 2",
    " 3",
    " 4",
    " 5", 
    " 6",
    " 7",
    " 8",
    " 9",
    "10"
}, 90, y, 100, 20);

y = y + 20
connect_btn = forms.button(setup_window, button_text, connectTo, 20, y + 3, 300, 20)
y = y + 25

-- //forms.textbox(long formhandle, [string caption = nil], [int? width = nil], [int? height = nil], [string boxtype = nil], [int? x = nil], [int? y = nil], [bool multiline = False], [bool fixedwidth = False], [string scrollbars = nil])
console_window = forms.textbox( setup_window, "", 300, 80, null, 20, y, true, false, "Vertical" );

local function sendShell()
    print("Sending Shell")
    current_activity.receive(
        {["item"] = 'greenShell', ['attacker'] = 'director', ['action'] = 'item', ["name"] = "all"}, config)
end
local function sendBanana()
    print("Sending Banana")
    current_activity.receive(
        {["item"] = 'banana', ['attacker'] = 'director', ['action'] = 'item', ["name"] = "all"}, config)
end
local function sendLighting()
    print("Sending lighting")
    current_activity.receive(
        {["item"] = 'lightning', ['attacker'] = 'director', ['action'] = 'item', ["name"] = "all"}, config)
end

-- shell_btn = forms.button(setup_window, "Send Shell", sendShell, 20, y + 90, 300, 20)
-- y = y + 25
-- banana_btn = forms.button(setup_window, "Send Banana", sendBanana, 20, y + 90, 300, 20)
-- y = y + 25
-- banana_btn = forms.button(setup_window, "Send LIghthing", sendLighting, 20, y + 90, 300, 20)



event.onexit(function()
    forms.destroy(setup_window)
end)

-- END FORM

if(loadConfig()) then
    printLog("Config Loaded")
    scanGames()
else
    printLog("Config Not Loaded, Creating New Config")
    config.name = ""
    config.volume = 0.7
    config.games = {
        ['mario3'] = null,
        ['megaman3'] = null
    }
    scanGames()
    saveConfig()
    loadConfig()    
end

if(config.volume == nil) then
    forms.settext(volume_drop, " 7")
else
    forms.settext(volume_drop, string.format("%2d",config.volume * 10))
end



local frame_count = 0

if config.name ~= "" and config.roomcode ~= "" then
    connectToLobbyWSS()
end

current_activity = video_armageddon
config.current_game = "mario3"


while true do
    frame_count = frame_count + 1
    if(forms.gettext(volume_drop) / 10 ~= config.volume) then
        config.volume = forms.gettext(volume_drop) / 10
        saveConfig()
    end

    if(forms.gettext(name_text) ~= config.name) then
        config.name = forms.gettext(name_text)
        saveConfig()
    end
    

    if config.ws_id ~= null then
        WSWatch(frame_count)
        if config.connection_status == "subscribed" then
           current_activity.frame(frame_count, config)
        end
    elseif config.ws_lobby_id ~= null and config.ws_id == null then
        WSLobbyWatch(frame_count)
    end 
        
    
	emu.frameadvance()
end




