local json = require('Utils/json')
local videoArmageddon = require('Activities/videoArmageddon')
-- local videoArmageddonXX = require('Activities/videoArmageddon20XX') 

local currentActivity = null

version = '2.9.1.4'



config = {
    ["name"] = "",
    ["roomcode"] = "",
    ['game'] = "mario3",
    ["volume"] = 7,
    ["ws_id"] = null,
    ["socket_id"] = null,
    ["auth"] = null,
    ["user_id"] = null,
    ["version"] = version,
    ["connectionStatus"] = "Not Connected",
    ['auth'] = null
}


-- Functions

print_log = function(msg)
    print(msg)
    console_log = os.date('%Y-%m-%d %I:%M:%S%p') .. ": " .. msg ..  "\r\n\z" .. console_log
    forms.settext(console_window, console_log)

end



local function setConnectionStatus(status)
    connectionStatus = status
end

local function connectToWSS()
    forms.settext(connect_btn, "Connecting...")
    if forms.gettext(name_text) == "" or string.len(forms.gettext(name_text)) > 9 or string.len(forms.gettext(roomcode_text)) ~= 4 then
        
        forms.settext(connect_btn, "Connect")
        print_log('Please enter a name (max 9 characters) and a 4 letter room code')
        return
    end
    config.name = forms.gettext(name_text)
    config.roomcode = forms.gettext(roomcode_text)
    local temp_ws_id = comm.ws_open('wss://reactvts.com:6001/app/jtcGSRD9za4QHWhTa3YTdQ9pFVRF9SH6brc7QvShUkxmP52Fsd?protocol=7&client=js&version=8.3.0&flash=false')
    local ws = comm.ws_receive(temp_ws_id);
    local response = json.parse(ws)
    config.socket_id = json.parse(response.data).socket_id
    config.ws_id = temp_ws_id
    comm.httpSetPostUrl("https://reactvts.com:3030/pusher/auth")
    local authJson = comm.httpPost("https://reactvts.com:3030/pusher/auth", "?socket_id=" .. config.socket_id .. "&channel_name=presence-" .. string.upper(config.roomcode) .. "&userType=client&name=" .. config.name)
    local authResponse = json.parse(authJson)
    config.auth = authResponse.auth
    config.user_id = json.parse(authResponse.channel_data).user_id


    local subTable = {
        ["event"] = "pusher:subscribe",
        ["data"] = {
            ["auth"] = config.auth,
            ["channel_data"] = "{\"user_id\":\"" .. config.user_id .. "\",\"user_info\":{\"type\":\"client\",\"name\":\"" .. config.name .. "\":\"version\":\"" .. config.version .. "\"}}",
            ["channel"] = "presence-" .. string.upper(config.roomcode),
            
        }
    }
    setConnectionStatus("connected")
    comm.ws_send(config.ws_id, json.stringify(subTable) , true)  
    print_log("Server Connection Established. Attempting to connect to room " .. config.roomcode)
end

local function ws_watch (ws_id, frame_count)
    if frame_count % 15 == 0 then
        if connectionStatus == "connected" then
            local fullResponse = ""
            local ws = comm.ws_receive(ws_id)
           
            while ws ~= "" do 
                fullResponse = fullResponse .. ws
                if(string.len(ws) < 1024) then
                    break
                end
                ws = comm.ws_receive(ws_id)
            end
    
            if fullResponse ~= "" then       
                local response = json.parse(fullResponse)
                if response.event == "pusher_internal:subscription_succeeded" then
                    print_log("Attempting to connect to channel " .. response.channel)
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
                                print_log("Connected")
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
                    print_log("Room not found. Please try again.")
                    forms.settext(connect_btn, "Connect")
                    return
                end

            end
            
        end
        if connectionStatus == "subscribed" then
            local fullResponse = ""
            local ws = comm.ws_receive(ws_id)           
            while ws ~= "" do 
                fullResponse = fullResponse .. ws
                if(string.len(ws) < 1024) then
                    break
                end
                ws = comm.ws_receive(ws_id)
            end
            
            if fullResponse ~= "" then
                local response = json.parse(fullResponse)
                if response.event == "client-message_full" then
                    if(response.data.name == config.name) then
                        setConnectionStatus("Not Connected")
                        print_log("Room is full")
                        config.ws_id = null
                        forms.settext(connect_btn, "Connect")
                        gui.drawString(client.bufferwidth / 2, client.bufferheight / 2, "Sorry: Room is full or locked", 0xFFFFFF00, 0x00000000, 16, "Arial", "bold", "center", "bottom" );
                        client.pause()
                        return
                    end
                end
                if response.event == "client-message_mismatch" then
                    if(response.data.name == config.name) then
                        setConnectionStatus("Not Connected")
                        print_log("Wrong version of Bizhawk. Please visit reactvts.com/join-va to get latest version of bizhawk")
                        config.ws_id = null
                        forms.settext(connect_btn, "Connect")
                        gui.drawString(client.bufferwidth / 2, client.bufferheight / 2, "reactvts.com/join-va to get latest version of bizhawk ", 0xFFFFFF00, 0x00000000, 16, "Arial", "bold", "center", "bottom" );
                        client.pause()
                        return
                    end
                end

                if response.event == "client-message_sent" then
                    currentActivity.receive(response.data, config)
                end
            end
            if frame_count % (60 * 30) == 0 then
                comm.ws_send(ws_id, '{"event":"pusher:ping","data":{}}', true)
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
local picture = forms.pictureBox( setup_window, 0, 0, 340, 50 );
y = y + 40 
forms.drawRectangle( picture, 0, 0, 600, 50, "#F6E05E", "#F6E05E");
forms.drawText( picture, 225, 25, "Reactvts v" .. version, "black", "#F6E05E", 40, "Inter", "600", "center", "middle" );

forms.label(setup_window, "Name:", 45, y+3, 40, 20)
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
forms.settext(volume_drop, " 7")
y = y + 20
connect_btn = forms.button(setup_window, button_text, connectToWSS, 20, y + 3, 300, 20)
y = y + 25

-- //forms.textbox(long formhandle, [string caption = nil], [int? width = nil], [int? height = nil], [string boxtype = nil], [int? x = nil], [int? y = nil], [bool multiline = False], [bool fixedwidth = False], [string scrollbars = nil])
console_window = forms.textbox( setup_window, "", 300, 80, null, 20, y, true, false, "Vertical" );

-- local function sendShell()
--     print("Sending Shell")
--     currentActivity.receive(
--         {["item"] = 'greenShell', ['action'] = 'item', ["name"] = "all"}, config)
-- end
-- local function sendBanana()
--     print("Sending Banana")
--     currentActivity.receive(
--         {["item"] = 'banana', ['action'] = 'item', ["name"] = "all"}, config)
-- end
-- local function sendLighting()
--     print("Sending lighting")
--     currentActivity.receive(
--         {["item"] = 'lightning', ['action'] = 'item', ["name"] = "all"}, config)
-- end

-- shell_btn = forms.button(setup_window, "Send Shell", sendShell, 20, y + 90, 300, 20)
-- y = y + 25
-- banana_btn = forms.button(setup_window, "Send Banana", sendBanana, 20, y + 90, 300, 20)
-- y = y + 25
-- banana_btn = forms.button(setup_window, "Send LIghthing", sendLighting, 20, y + 90, 300, 20)



event.onexit(function()
    forms.destroy(setup_window)
end)

-- END FORM




local frame_count = 0

if config.name ~= "" and config.roomcode ~= "" then
    connectToWSS()
end

currentActivity = videoArmageddon

while true do

    
    
    frame_count = frame_count + 1
    config.volume= forms.gettext(volume_drop) / 10 
    if config.ws_id ~= null then
        ws_watch(config.ws_id, frame_count)
        if connectionStatus == "subscribed" then
           currentActivity.frame(frame_count, config)
        end
    end
    
	emu.frameadvance()
end


