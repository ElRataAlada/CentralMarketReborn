script_name('Central Market Reborn')
script_version('1.1.2')

script_authors('Revinci')
script_description('Автоматическое Выставление товаров на скупку и продажу')

local imgui = require 'imgui'
local encoding = require 'encoding'
local sampev = require 'lib.samp.events'
local inicfg = require 'inicfg'
local key = require('vkeys')

encoding.default = 'CP1251'
u8 = encoding.UTF8

local json_file_BuyList = getWorkingDirectory()..'\\config\\Central Market\\buyitems.json'
local json_file_mySellList = getWorkingDirectory()..'\\config\\Central Market\\sellitems.json'
local json_file_myBuyList = getWorkingDirectory()..'\\config\\Central Market\\mybuyitems.json'
local avg_prices = nil

local itemsBuy, myitemsBuy, itemsSell, myItemsSell, itemsSellPosition = {}, {}, {}, {}, {}

local removeSell = false

local settings = inicfg.load({
    main = {
        useAvgPrice = false,
        delayParse = 50,
        delayVist = 200,
        color = 'B22222',
        colormsg = 0xFFB22222,
        stylemode = 7,
        smoothscroll = true,
        smoothhigh = 80,
        smoothdelay = 150,
        classiccount = 1,
        classicprice = 10,
        imgui = false
    }
}, 'Central Market\\ARZCentral-settings')

local allWindow = imgui.ImBool(false)
local last_list = nil
local mainWindowState, buyWindowState, sellWindowState , settingWindowState, secondarybuyWindowState, secondaryWindowState, presetWindowState, delprod, infoWindowState, sellWindow2State = true, false, false, false, false, false, false, false, false, false
local rbut, findBuf, findBufInt, parserBuf, delayInt, afilename, selectPresetMode, selectStyle, smooth, smoothInt1, smoothInt2, findMyItem, ccount, cprice, useAvgPrice = imgui.ImInt(1), imgui.ImBuffer(124), imgui.ImInt(0), imgui.ImInt(settings.main.delayParse), imgui.ImInt(settings.main.delayVist), imgui.ImBuffer(200), imgui.ImInt(1), imgui.ImInt(-1), imgui.ImBool(settings.main.smoothscroll), imgui.ImInt(settings.main.smoothhigh), imgui.ImInt(settings.main.smoothdelay), imgui.ImBuffer(124), imgui.ImInt(settings.main.classiccount), imgui.ImInt(settings.main.classicprice), imgui.ImBool(settings.main.useAvgPrice)

STATES = {
    buyWindowState = "0",
    sellWindowState = "1",
    settingWindowState = "2",
    infoWindowState = "3",
    mainWindowState = "4",
    secondarybuyWindowState = "5",
    secondaryWindowState = "6",
    presetWindowState = "7",
    delprod = "8",
    sellWindow2State = "9"
}

function setState(STATE)
    if STATE == STATES.mainWindowState then  buyWindowState = false sellWindowState = false settingWindowState = false secondarybuyWindowState = false secondaryWindowState = false presetWindowState = false delprod = false infoWindowState = false sellWindow2State = false mainWindowState = true end
    if STATE == STATES.buyWindowState then  mainWindowState = false sellWindowState = false settingWindowState = false secondarybuyWindowState = false secondaryWindowState = false presetWindowState = false delprod = false infoWindowState = false sellWindow2State = false buyWindowState = true end
    if STATE == STATES.sellWindowState then  mainWindowState = false buyWindowState = false settingWindowState = false secondarybuyWindowState = false secondaryWindowState = false presetWindowState = false delprod = false infoWindowState = false sellWindow2State = false sellWindowState = true end
    if STATE == STATES.sellWindow2State then  mainWindowState = false buyWindowState = false settingWindowState = false secondarybuyWindowState = false secondaryWindowState = false presetWindowState = false delprod = false infoWindowState = false sellWindowState = false sellWindow2State = true end
    if STATE == STATES.infoWindowState then  mainWindowState = false buyWindowState = false sellWindowState = false settingWindowState = false secondarybuyWindowState = false secondaryWindowState = false presetWindowState = false delprod = false  sellWindow2State = false infoWindowState = true end
    if STATE == STATES.settingWindowState then  mainWindowState = false buyWindowState = false sellWindowState = false secondarybuyWindowState = false secondaryWindowState = false presetWindowState = false delprod = false infoWindowState = false  sellWindow2State = false settingWindowState = true end
    if STATE == STATES.secondarybuyWindowState then  mainWindowState = false buyWindowState = false sellWindowState = false settingWindowState = false secondaryWindowState = false presetWindowState = false delprod = false infoWindowState = false  sellWindow2State = false secondarybuyWindowState = true end
    if STATE == STATES.secondaryWindowState then  mainWindowState = false buyWindowState = false sellWindowState = false settingWindowState = false secondarybuyWindowState = false presetWindowState = false delprod = false infoWindowState = false  sellWindow2State = false secondaryWindowState = true end
    if STATE == STATES.presetWindowState then  mainWindowState = false buyWindowState = false sellWindowState = false settingWindowState = false secondarybuyWindowState = false secondaryWindowState = false delprod = false infoWindowState = false  sellWindow2State = false presetWindowState = true end
    if STATE == STATES.delprod then  mainWindowState = false buyWindowState = false sellWindowState = false settingWindowState = false secondarybuyWindowState = false secondaryWindowState = false presetWindowState = false infoWindowState = false  sellWindow2State = false delprod = true end
end

function autoupdate(json_url, prefix, url)
  local dlstatus = require('moonloader').download_status
  local json = getWorkingDirectory() .. '\\'..thisScript().name..'-version.json'
  if doesFileExist(json) then os.remove(json) end
  downloadUrlToFile(json_url, json,
    function(id, status, p1, p2)
      if status == dlstatus.STATUSEX_ENDDOWNLOAD then
        if doesFileExist(json) then
          local f = io.open(json, 'r')
          if f then
            local info = decodeJson(f:read('*a'))
            updatelink = info.updateurl
            updateversion = info.latest
            f:close()
            os.remove(json)
            if updateversion ~= thisScript().version then
              lua_thread.create(function(prefix)
                local dlstatus = require('moonloader').download_status
                local color = -1
                sampAddChatMessage((prefix..'Обнаружено обновление. Пытаюсь обновиться c '..thisScript().version..' на '..updateversion), color)
                wait(250)
                downloadUrlToFile(updatelink, thisScript().path,
                  function(id3, status1, p13, p23)
                    if status1 == dlstatus.STATUS_DOWNLOADINGDATA then
                      print(string.format('Загружено %d из %d.', p13, p23))
                    elseif status1 == dlstatus.STATUS_ENDDOWNLOADDATA then
                      print('Загрузка обновления завершена.')
                      sampAddChatMessage((prefix..'Обновление завершено!'), color)
                      goupdatestatus = true
                      lua_thread.create(function() wait(500) thisScript():reload() end)
                    end
                    if status1 == dlstatus.STATUSEX_ENDDOWNLOAD then
                      if goupdatestatus == nil then
                        sampAddChatMessage((prefix..'Обновление прошло неудачно. Запускаю устаревшую версию..'), color)
                        update = false
                      end
                    end
                  end
                )
                end, prefix
              )
            else
              update = false
              print('v'..thisScript().version..': Обновление не требуется.')
            end
          end
        else
          print('v'..thisScript().version..': Не могу проверить обновление. Смиритесь или проверьте самостоятельно на '..url)
          update = false
        end
      end
    end
  )
  while update ~= false do wait(100) end
end

function parseAvgPrices()
    avg_prices = jsonRead(getWorkingDirectory()..'\\config\\prices.json')

    if avg_prices == nil then
        sampAddChatMessage('[ Central Market Reborn ]: {FFFFFF}Файл с средними ценами не найден. Установите cr.lua или скачайте файл prices.json', settings.main.colormsg)
        sampAddChatMessage('[ Central Market Reborn ]: {FFFFFF}Ccылка на тему находится во вкладке {ff0000} Инфо', settings.main.colormsg)
    else
        if avg_prices.last_update == -1 then
            avg_prices = nil
            sampAddChatMessage('[ Central Market Reborn ]: {FFFFFF}Загрузите цены на центральном рынке или скачайте файл prices.json', settings.main.colormsg)
            return
        end
        
        sampAddChatMessage('[ Central Market Reborn ]: {FFFFFF}Средние цены успешно загружены.', settings.main.colormsg)
    end
end

function main()
    while not isSampAvailable() do
        wait(100)
    end

	samp = getModuleHandle('samp.dll')
	if samp <= 0x0 then return end

    autoupdate("https://github.com/ElRataAlada/CentralMarketReborn/raw/main/version.json", '['..string.upper(thisScript().name)..']: ', "https://github.com/ElRataAlada/CentralMarketReborn")

    if not doesFileExist(json_file_BuyList) then jsonSave(json_file_BuyList, {}) end
    if not doesFileExist(json_file_myBuyList) then jsonSave(json_file_myBuyList, {}) end
    if not doesFileExist(json_file_mySellList) then jsonSave(json_file_mySellList, {}) end

    itemsBuy = jsonRead(json_file_BuyList)
    myitemsBuy = jsonRead(json_file_myBuyList)
    myItemsSell = jsonRead(json_file_mySellList)

    if not doesDirectoryExist(getWorkingDirectory()..'/config/Central Market/preset-buy') then createDirectory('moonloader\\config\\Central Market\\preset-buy') end
    if doesFileExist('moonloader/config/Central Market/ARZCentral-settings.ini') then inicfg.save(settings, 'Central Market\\ARZCentral-settings') end


    parseAvgPrices()
    
    if not settings.main.imgui then sampAddChatMessage('[ Central Market Reborn ]: {FFFFFF}Скрипт загружен. Команда активации: {'..settings.main.color..'}/cmr{FFFFFF}.', settings.main.colormsg) end
 
    sampRegisterChatCommand('cmr', function( )
        allWindow.v = not allWindow.v imgui.Process = allWindow.v
    end)
    if settings.main.imgui then
        lua_thread.create(function()
            wait(200)
        sampAddChatMessage('[ Central Market Reborn ]: {FFFFFF}Скрипт перезагружен.', settings.main.colormsg)
        allWindow.v = true
        imgui.Process = allWindow.v
        settings.main.imgui = false
        inicfg.save(settings, 'Central Market\\ARZCentral-settings')
        end)
    end
    while true do
    wait(-1)
    if (wasKeyPressed(key.VK_ESC) and not sampIsChatInputActive() and not isSampfuncsConsoleActive() and not sampIsDialogActive()) and allWindow.v then
        allWindow.v = false
        imgui.Process = allWindow.v
    end
    end
end

function sampev.onServerMessage(color, text)
    if delprod and text:find('У вас нет выставленного товара') then
        sampAddChatMessage('[ Central Market Reborn ]: {FFFFFF}Товары сняты. Можете просканировать заново или выставить товар.', settings.main.colormsg)   
        delprod = not delprod
    end

    if removeSell and text:find("У вас есть 3 минуты, чтобы настроить товар, иначе аренда ларька будет отменена.") then
       removeSell = false
    end
    
    if removeSell and text:find("[Ошибка]") then
        return false
    end
    
    if sellProc and text:find("[Ошибка]") then
        return false
    end
    
    if sellProc and text:find("Выставлено") then
        return false
    end

end

function getPageFromPosition(position)
    pagesize = 36

    local i = 1

    while position >= pagesize do
        position = position - pagesize
        i = i + 1
    end

    return i, position
end

function fixDialogBug() 
    sampSendChat('/mm')
    wait(delayInt.v)
    sampCloseCurrentDialogWithButton(0)
end

local td = {
    {325, 164},
    {351, 164},
    {378, 164},
    {404, 164},
    {431, 164},
    {457, 164},
    {325, 195},
    {351, 195},
    {378, 195},
    {404, 195},
    {431, 195},
    {457, 195},
    {325, 225},
    {351, 225},
    {378, 225},
    {404, 225},
    {431, 225},
    {457, 225},
    {325, 256},
    {351, 256},
    {378, 256},
    {404, 256},
    {431, 256},
    {457, 256},
    {325, 286},
    {351, 286},
    {378, 286},
    {404, 286},
    {431, 286},
    {457, 286},
    {325, 317},
    {351, 317},
    {378, 317},
    {404, 317},
    {431, 317},
    {457, 317}
}



local td_left = {
    {184, 164},
    {211, 164},
    {237, 164},
    {264, 164},
    {290, 164},
    
    {184, 195},
    {211, 195},
    {237, 195},
    {264, 195},
    {290, 195},
    
    {184, 225},
    {211, 225},
    {237, 225},
    {264, 225},
    {290, 225},
    
    {184, 256},
    {211, 256},
    {237, 256},
    {264, 256},
    {290, 256},
    
    {184, 286},
    {211, 286},
    {237, 286},
    {264, 286},
    {290, 286},
    
    {184, 317},
    {211, 317},
    {237, 317},
    {264, 317},
    {290, 317},
}

function sellProcess()

    if sellProc then
        sampAddChatMessage('[ Central Market Reborn ]: {FFFFFF}Выставляю товары на продажу! Подождите', settings.main.colormsg)
        
        inventoryPages = {2075, 2076, 2077, 2078, 2079}
        sampCloseCurrentDialogWithButton(0)

        wait(delayInt.v*2)
        local prevPage = 1

        for name = 1, #myItemsSell do
            local toSell = myItemsSell[name][2]

            local total = 0

            for i, f in ipairs(itemsSell) do
                if myItemsSell[name][1] == itemsSell[i][1] then
                    total = itemsSell[i][2]
                    break
                end
            end

            if myItemsSell[name][4] == true then
                toSell = total
            end

            if toSell <= 0 then
                goto continue
            end

            local positions = {}
            
            -- item, amount, position
            for i, f in ipairs(itemsSellPosition) do
                if myItemsSell[name][1] == itemsSellPosition[i][1] then
                    table.insert(positions, {itemsSellPosition[i][2], itemsSellPosition[i][3]})
                end
            end

            for pos = 1,  #positions do
                local page, position = getPageFromPosition(positions[pos][2])
                
                local price = myItemsSell[name][3]
                local amount = positions[pos][1]
                
                local textDrawsPositions = {}

                for i = 0, 4096 do
                    if sampTextdrawIsExists(i) then
                        posX, posY = sampTextdrawGetPos(i)
                        table.insert(textDrawsPositions, {i, math.modf(posX), math.modf(posY)})
                    end
                end
                
                if sampTextdrawIsExists(inventoryPages[page]) then

                    if prevPage ~= page then
                        sampSendClickTextdraw(inventoryPages[page])
                        prevPage = page
                        wait(delayInt.v*3)
                    end

                    position = td[position + 1]

                    for td_positions = 1, #textDrawsPositions do
                        td_x = textDrawsPositions[td_positions][2]
                        td_y = textDrawsPositions[td_positions][3]

                        if td_x == position[1] and td_y == position[2] then
                            sampSendClickTextdraw(textDrawsPositions[td_positions][1])
                            wait(delayInt.v)

                            if avg_prices ~= nil and myItemsSell[name][3] == 10 and settings.main.useAvgPrice then
                                if avg_prices.list[myItemsSell[name][1]] ~= nil then
                                    price = avg_prices.list[myItemsSell[name][1]].sa.price
                                    
                                    if type(price) == "table" then
                                        price = price[1]
                                    end
                                end
                            end 

                            if sampGetCurrentDialogId() ~= 26540 then
                                fixDialogBug()
                                wait(delayInt.v)
                                sampSendClickTextdraw(textDrawsPositions[td_positions][1])
                                wait(delayInt.v)
                            end

                            if sampGetCurrentDialogId() == 26540 then
                                print("SELLING: " .. myItemsSell[name][1] .. " amount: " .. amount .. " total: " .. total)
                                
                                if total == 1 and toSell == 1 then
                                    print("SELL1")
                                    sampSendDialogResponse(26540, 1, nil, price)
                                    toSell = 0
                                    
                                elseif amount >= toSell then
                                    print("SELL2")
                                    sampSendDialogResponse(26540, 1, nil, toSell .. ", " .. price)
                                    toSell = 0
                                    
                                elseif amount < toSell then
                                    print("SELL3")
                                    sampSendDialogResponse(26540, 1, nil, amount .. ", " .. price)
                                    toSell = toSell - amount
                                end
                            end

                            break
                        end
                    end
                end

                
            end

            ::continue::
        end
    end

    sampCloseCurrentDialogWithButton(0)

    for i = 1, 4096 do
        if sampTextdrawIsExists(i) then
            x , y = sampTextdrawGetPos(i)

            if math.modf(x) == 440 and math.modf(y) == 364 then
                sampCloseCurrentDialogWithButton(0)
                sampAddChatMessage('[ Central Market Reborn ]: {FFFFFF}Товары успешно выставлены! Удачи', settings.main.colormsg)
                sampSendClickTextdraw(i)
                setState(STATES.sellWindowState)
                break
            end
        end
    end


    sellProc = false
end

function rgbaToHex(r, g, b, a)
    return string.format("%02x%02x%02x%02x", 
        math.floor(a*255),
        math.floor(r*255),
        math.floor(g*255),
        math.floor(b*255))
end

function yellowText(text)
    return '{dfdf00}'..text..'{e8e8e8}'
end

function greenText(text)
    return '{109f10}'..text..'{e8e8e8}'
end

function removeSellProcess()
    if removeSell then
        sampAddChatMessage('[ Central Market Reborn ]: {FFFFFF}Удаляю товары. Подождите', settings.main.colormsg)

        wait(delayInt.v*3)

        for i = 1, 10 do
            local textdraws = {}
            for textdraw = 1, 4096 do
                if sampTextdrawIsExists(textdraw) then
                    x , y = sampTextdrawGetPos(textdraw)
                    table.insert(textdraws, {textdraw, math.modf(x), math.modf(y)})
                end
            end
            
            for t = 1, #textdraws do
                t_x, t_y = textdraws[t][2], textdraws[t][3]
                
                if t_x == 264 and t_y == 357 then
                    nextButton = textdraws[t][1]
                    break
                end
            end
            
            for t = 1, #textdraws do
                t_x, t_y = textdraws[t][2], textdraws[t][3]
                
                for tdl = 1, #td_left do
                    t_left_x, t_left_y = td_left[tdl][1], td_left[tdl][2]
                    
                    if t_x == t_left_x and t_y == t_left_y then
                        sampSendClickTextdraw(textdraws[t][1])
                        wait(delayInt.v)
                        
                        if sampGetCurrentDialogId() == 26541 then
                            sampSendDialogResponse(26541, 1)
                            wait(delayInt.v)
                        end
                        
                        break
                    end
                end

                if not removeSell then
                    return false
                end
            end

            wait(delayInt.v)
            sampSendClickTextdraw(nextButton)
            wait(delayInt.v)
        end
        
        removeSell = false
    end 

    for i = 1, 4096 do
        if sampTextdrawIsExists(i) then
            x , y = sampTextdrawGetPos(i)

            if math.modf(x) == 440 and math.modf(y) == 364 then
                sampCloseCurrentDialogWithButton(0)
                sampAddChatMessage('[ Central Market Reborn ]: {FFFFFF}Товары успешно сняты. Можете просканировать заново или выставить товар.', settings.main.colormsg)
                sampSendClickTextdraw(i)
                break
            end
        end
    end
end


function sampev.onShowDialog(id, style, title, button1, button2, text) -- хук диалога
    lua_thread.create(function()
    if title:find('Выберите действие') and buyProc then
        wait(parserBuf.v)
        sampSendDialogResponse(id, 1, 0)
    end
end)
    if id == 3050 and check then -- тут мы парсим список товаров на скуп
        lua_thread.create(parserPage, text, title)
    end

    if id == 25493 and check then -- тут мы парсим список товаров на продажу
        lua_thread.create(parseInventoryItems, text, title)
    end

    if id == 3040 then

        if check then
            if checkmode == 1 then
                sampSendDialogResponse(id, 1, 1)
            end
        end

        if delprod then
            sampSendDialogResponse(id, 1, 3)
        end

        if buyProc then
            lua_thread.create(function()
                wait(parserBuf.v)
                sampSendDialogResponse(id, 1, 2)
            end)
        end

        if sellProc then
            sampSendDialogResponse(id, 1, 0)
            lua_thread.create(sellProcess)
        end

        if removeSell then
            sampSendDialogResponse(id, 1, 0)
            lua_thread.create(removeSellProcess)
        end

        text = text .. '\n \n{'.. settings.main.color .. "}7. Central Market Reborn - Menu"
        last_list = select(2, string.gsub(text, "\n", "\n")) -- get lines count
        return {id, style, title, button1, button2, text}
    end

    if id == 3050 and delprod then
        local i = 0
        for n in text:gmatch('[^\r\n]+') do
            if n:match('%{FFFFFF%}(.+)') then
                lua_thread.create(function()
                    while pause do wait(0) end
                    sampSendDialogResponse(3050, 1, i-1)
                end)
                break
            end
            if n:find(">>>") then 
                lua_thread.create(function()
                    while pause do wait(0) end
                    wait(parserBuf.v) 
                    sampSendDialogResponse(3050, 1, i-1) 
                end)
                break
            end
            i = i + 1
        end
    end
    
    if title:find('Поиск товара') and text:find('Введите наименование товара') and buyProc then
        lua_thread.create(function()
            wait(parserBuf.v)
            sampSendDialogResponse(id, 1, 1, myitemsBuy[idt][1])
        end)
    end
    
    if title:find('Поиск товара') and not text:find('Введите наименование товара') and buyProc then
        lua_thread.create(function()
            local ditem = 0
            for n in text:gmatch('[^\r\n]+') do
                if n:find(myitemsBuy[idt][1], 0, true) then
                    wait(delayInt.v)
                    sampSendDialogResponse(id, 1, ditem)
                    break
                end
            end
        end)
    end

    if id == 3050 and buyProc then
        lua_thread.create(function()
            local skip, isFound, i = true, false, 0
            for n in text:gmatch('[^\r\n]+') do
                if shopMode == 2 then
                    for t, a in pairs(inputsSell) do if n:find('{777777}'..itemsBuy[inputsSell[t][3]][1], 0, true) and inputsSell[t][4] == false then wait(delayInt.v) bName = t sampSendDialogResponse(3050, 1, i - 1) isFound = true break end end
                end
                if n:find(">>>") then wait(parserBuf.v) sampSendDialogResponse(3050, 1, i - 1) end
                if isFound then break end
                i = i + 1
            end
        end)
    end

    if buyProc then
        if text:find('Введите цену за товар') then
            lua_thread.create(function()
                wait(parserBuf.v)
                sampSendDialogResponse(id, 1, 0, myitemsBuy[idt][3])
                
                if tonumber(idt) == tonumber(#myitemsBuy) then
                    local isEndBuy = true
                    sampAddChatMessage('[ Central Market Reborn ]: {FFFFFF}Товары успешно выставлены! Удачи', settings.main.colormsg) skip = false buyProc = false
                else
                    idt = idt + 1
                end
            end)
        elseif text:find('Введите количество и цену за один товар') then
            lua_thread.create(function()
                wait(parserBuf.v)
                sampSendDialogResponse(id, 1, 0, myitemsBuy[idt][2]..", "..myitemsBuy[idt][3]) 
           
                if tonumber(idt) == tonumber(#myitemsBuy) then
                    local isEndBuy = true
                    sampAddChatMessage('[ Central Market Reborn ]: {FFFFFF}Товары успешно выставлены! Удачи', settings.main.colormsg) skip = false buyProc = false
                else
                    idt = idt + 1
                end
            end)
        end
    end


end

function samp_create_sync_data(sync_type, copy_from_player)
    local ffi = require 'ffi'
    local sampfuncs = require 'sampfuncs'
    local raknet = require 'samp.raknet'
    require 'samp.synchronization'

    copy_from_player = copy_from_player or true
    local sync_traits = {
        player = {'PlayerSyncData', raknet.PACKET.PLAYER_SYNC, sampStorePlayerOnfootData},
        vehicle = {'VehicleSyncData', raknet.PACKET.VEHICLE_SYNC, sampStorePlayerIncarData},
        passenger = {'PassengerSyncData', raknet.PACKET.PASSENGER_SYNC, sampStorePlayerPassengerData},
        aim = {'AimSyncData', raknet.PACKET.AIM_SYNC, sampStorePlayerAimData},
        trailer = {'TrailerSyncData', raknet.PACKET.TRAILER_SYNC, sampStorePlayerTrailerData},
        unoccupied = {'UnoccupiedSyncData', raknet.PACKET.UNOCCUPIED_SYNC, nil},
        bullet = {'BulletSyncData', raknet.PACKET.BULLET_SYNC, nil},
        spectator = {'SpectatorSyncData', raknet.PACKET.SPECTATOR_SYNC, nil}
    }
    local sync_info = sync_traits[sync_type]
    local data_type = 'struct ' .. sync_info[1]
    local data = ffi.new(data_type, {})
    local raw_data_ptr = tonumber(ffi.cast('uintptr_t', ffi.new(data_type .. '*', data)))
    -- copy player's sync data to the allocated memory
    if copy_from_player then
        local copy_func = sync_info[3]
        if copy_func then
            local _, player_id
            if copy_from_player == true then
                _, player_id = sampGetPlayerIdByCharHandle(PLAYER_PED)
            else
                player_id = tonumber(copy_from_player)
            end
            copy_func(player_id, raw_data_ptr)
        end
    end
    -- function to send packet
    local func_send = function()
        local bs = raknetNewBitStream()
        raknetBitStreamWriteInt8(bs, sync_info[2])
        raknetBitStreamWriteBuffer(bs, raw_data_ptr, ffi.sizeof(data))
        raknetSendBitStreamEx(bs, sampfuncs.HIGH_PRIORITY, sampfuncs.UNRELIABLE_SEQUENCED, 1)
        raknetDeleteBitStream(bs)
    end
    -- metatable to access sync data and 'send' function
    local mt = {
        __index = function(t, index)
            return data[index]
        end,
        __newindex = function(t, index, value)
            data[index] = value
        end
    }
    return setmetatable({send = func_send}, mt)
end

function press_alt()
    local data = samp_create_sync_data('player')
    data.keysData = data.keysData + 1024
    data.send()
end


function sampev.onSendDialogResponse(id, but, list, input)
    if id == 3040 and but == 1 and list == last_list then
        allWindow.v = not allWindow.v imgui.Process = allWindow.v
    end
end

function parseInventoryItems(text, title)
    skip = false
    local isNext,i = false, 0

    for n in text:gmatch('[^\r\n]+') do -- чек построчно 
        if not n:find("Название") and not n:find(">>") then      
            
            local amount = tonumber(n:match("%[(%d+) шт%]")) or 0
            local item = n:match("%] (.+)\t%{......%}(.+)")
            local position = n:match("%[(%d+)%]")
            
            if item ~= "[слот] Название" and item ~= nil and not n:find("Инвентарь") then
                local isFound = false
                
                for g, f in pairs(itemsSell) do
                    if item == itemsSell[g][1] then
                        itemsSell[g][2] = itemsSell[g][2] + amount
                        isFound = true
                        break
                    end
                end

                skip = true

                for g, f in pairs(itemsBuy) do 
                    if item == itemsBuy[g][1] then
                        skip = false
                    end
                end

                if not isFound and not skip then
                     table.insert(itemsSell, {item, amount})
                end

                table.insert(itemsSellPosition, {item, amount, tonumber(position)})
            end    
        end

        
        if n:find(">>") then wait(parserBuf.v) sampSendDialogResponse(25493, 1, i-1) isNext = true end -- следующая страничка
        i = i + 1
    end

    if not isNext then 
        check = false

        local newMyItemsSell = {}

        for g, f in pairs(itemsSell) do
            name = itemsSell[g][1]

            for i, _ in ipairs(myItemsSell) do
                if name == myItemsSell[i][1] then
                    table.insert(newMyItemsSell, {name, myItemsSell[i][2], myItemsSell[i][3], myItemsSell[i][4]})
                    break
                end
            end
        end

        myItemsSell = newMyItemsSell

        jsonSave(json_file_mySellList, myItemsSell)

        fixDialogBug()

        skip = false
    end
end

function parserPage(text, title) -- переделал функу Devilov'a
    skip = true
	local isNext,i = false, 0
    local cur, max = title:match('(%d+)/(%d+)')

    for n in text:gmatch('[^\r\n]+') do -- чек построчно 
            local item = n:match("%{777777%}(.+)%s%{B6B425%}")
            if item ~= "Название" and item ~= nil then
                local isFound = false
                for g, f in pairs(itemsBuy) do 
                    if item == itemsBuy[g][1] then
                        isFound = true
                    end
                end
                if not isFound then table.insert(itemsBuy, {item}) end
            end
		if n:find(">>>") and (cur ~= max) then wait(parserBuf.v) sampSendDialogResponse(3050, 1, i-1) isNext = true end -- следующая страничка
        i = i + 1
	end
    
    if not isNext then check = false sampAddChatMessage('[ Central Market Reborn ]: {FFFFFF}Проверка списков прошла успешно! Откройте меню по команде: {'..settings.main.color..'}/cmr', settings.main.colormsg) jsonSave(json_file_BuyList, itemsBuy) sampSendDialogResponse(3050, 0) skip = false end
end
imgui.Scroller = {
	_ids = {},
	_version = 1,
	_author = "Double Tap Inside"
}
setmetatable(imgui.Scroller, {__call = function(self, id, step, duration, HoveredFlags)
	if not HoveredFlags then
		HoveredFlags = imgui.HoveredFlags.AllowWhenBlockedByActiveItem
	end
	
	if not imgui.Scroller._ids[id] then
		imgui.Scroller._ids[id] = {}
	end
	
	local current_position = imgui.GetScrollY()
	
	if (imgui.IsWindowHovered(HoveredFlags) and imgui.IsMouseDown(0)) then
		imgui.Scroller._ids[id].start_clock = nil
	end
	
	if imgui.Scroller._ids[id].start_clock then
		if (os.clock() - imgui.Scroller._ids[id].start_clock) * 1000 <= duration then		
			local progress = (os.clock() - imgui.Scroller._ids[id].start_clock) * 1000 / duration			
			local fading_progress = progress * (2 - progress)
			local distance = (imgui.Scroller._ids[id].target_position - imgui.Scroller._ids[id].start_position)
			local new_position = imgui.Scroller._ids[id].start_position + distance * fading_progress
			
			if new_position < 0 then
				new_position = 0
				imgui.Scroller._ids[id].start_clock = nil
				
			elseif new_position > imgui.GetScrollMaxY() then
				new_position = imgui.GetScrollMaxY()
				imgui.Scroller._ids[id].start_clock = nil
			end
			
			imgui.SetScrollY(math.floor(new_position))
			
		else
			imgui.Scroller._ids[id].start_clock = nil
			imgui.SetScrollY(imgui.Scroller._ids[id].target_position)
		end
	end
	
	---
	
	local wheel_delta = imgui.GetIO().MouseWheel
	
	if wheel_delta ~= 0 and imgui.IsWindowHovered(HoveredFlags) then
		local offset = -wheel_delta * step		
		
		if not imgui.Scroller._ids[id].start_clock then
			imgui.Scroller._ids[id].start_clock = os.clock()
			imgui.Scroller._ids[id].start_position = current_position
			imgui.Scroller._ids[id].target_position = current_position + offset
			
		else
			imgui.Scroller._ids[id].start_clock = os.clock()
			imgui.Scroller._ids[id].start_position = current_position
			
			if imgui.Scroller._ids[id].start_position < imgui.Scroller._ids[id].target_position and offset > 0 then
				imgui.Scroller._ids[id].target_position = imgui.Scroller._ids[id].target_position + offset
				
			elseif imgui.Scroller._ids[id].start_position > imgui.Scroller._ids[id].target_position and offset < 0 then
				imgui.Scroller._ids[id].target_position = imgui.Scroller._ids[id].target_position + offset
			
			else
				imgui.Scroller._ids[id].target_position = current_position + offset
			end
		end
	end
end})

local fontsize = nil
local fa = require 'fAwesome5'

local fa_font = nil
local fa_glyph_ranges = imgui.ImGlyphRanges({ fa.min_range, fa.max_range })
function imgui.BeforeDrawFrame()
    if fa_font == nil then
        local font_config = imgui.ImFontConfig()
        font_config.MergeMode = true

        fa_font = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/resource/fonts/fa-solid-900.ttf', 13.0, font_config, fa_glyph_ranges)
    end
    if fontsize == nil then
        fontsize = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 20.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
        logosize = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 25.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    end
end

function menu(imgui)
    imgui.BeginMenuBar()
    if imgui.MenuItem(u8'Скупка') then setState(STATES.mainWindowState) end 
    if imgui.MenuItem(u8'Продажа') then setState(STATES.sellWindowState) end
    if imgui.MenuItem(u8'Настройки') then setState(STATES.settingWindowState) end
    if imgui.MenuItem(u8'Инфо') then setState(STATES.infoWindowState) end
    if imgui.MenuItem(u8'Перезагрузить скрипт') then reloadscript() end
    imgui.EndMenuBar()
end

function imgui.OnDrawFrame()
    
    local cx, cy = select(1, getScreenResolution()), select(2, getScreenResolution())
    local sw, sh = getScreenResolution()
	if allWindow.v then
        imgui.SetNextWindowPos(imgui.ImVec2(cx/1.7, cy / 1.55), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(sw / 1.6, sh / 1.5), imgui.Cond.FirstUseEver)
        imgui.Begin(u8'Central Market Reborn', allWindow, 64+imgui.WindowFlags.MenuBar+imgui.WindowFlags.NoCollapse)




        if mainWindowState then
            menu(imgui)
            if #itemsBuy ~= 0 then
                imgui.Text(u8"Все загруженные предметы:", imgui.SetCursorPosX(170))
                imgui.SameLine()
                imgui.Text(u8"Выбранные предметы:", imgui.SetCursorPosX(565))
                imgui.BeginChild('#dfgdfg', imgui.ImVec2(500, 500))
                imgui.InputText(u8'Поиск по названию', findBuf)
                imgui.Separator()
                if settings.main.smoothscroll then
                imgui.BeginChild("##1", imgui.ImVec2(500, 470), false, imgui.WindowFlags.NoScrollWithMouse)
                imgui.Scroller("scroll1", settings.main.smoothhigh, settings.main.smoothdelay, imgui.HoveredFlags.AllowWhenBlockedByActiveItem)
                else
                    imgui.BeginChild("##1", imgui.ImVec2(500, 470), false)
                end
                if findBuf.v == '' then
                local clipper = imgui.ImGuiListClipper(#itemsBuy)
                    while clipper:Step() do            
                for i = clipper.DisplayStart + 1, clipper.DisplayEnd do
                    local f = itemsBuy[i]
                        
                    local incart = check_table(itemsBuy[i][1], myitemsBuy)

                        if incart then                     
                            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.2, 0.2, 0.2, 1))
                            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.25, 0.25, 0.25, 1))
                            imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.3, 0.3, 0.3, 1))
                        end

                        if imgui.Button(u8(itemsBuy[i][1])) then
                           

                            if not check_table(itemsBuy[i][1], myitemsBuy) then
                            table.insert(myitemsBuy, {itemsBuy[i][1], (settings.main.classiccount), (settings.main.classicprice), true})
                            jsonSave(json_file_myBuyList, myitemsBuy)
                            else
                                local name = itemsBuy[i][1]
                                table.remove(myitemsBuy, check_index(name, myitemsBuy))
                                jsonSave(json_file_myBuyList, myitemsBuy)
                        end
                        end

                        if incart then
                            imgui.PopStyleColor(3)
                        end
                    end
                end
            end
                for i, _ in ipairs(itemsBuy) do
                    if findBuf.v ~= '' then
                        local isFounded = false
                            local pat1 = string.rlower(itemsBuy[i][1])
                            local pat2 = string.rlower(u8:decode(findBuf.v))                  
                            if pat1:find(pat2, 0, true) then
                                local incart = check_table(itemsBuy[i][1], myitemsBuy)

                                if incart then                     
                                    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.2, 0.2, 0.2, 1))
                                    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.25, 0.25, 0.25, 1))
                                    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.3, 0.3, 0.3, 1))
                                end

                                if imgui.Button(u8(itemsBuy[i][1])) then
                                   
                                    if not check_table(itemsBuy[i][1], myitemsBuy) then
                                    table.insert(myitemsBuy, {itemsBuy[i][1], 1, 10, true})
                                    jsonSave(json_file_myBuyList, myitemsBuy)
                                    else
                                        local name = itemsBuy[i][1]
                                        table.remove(myitemsBuy, check_index(name, myitemsBuy))
                                        jsonSave(json_file_myBuyList, myitemsBuy)
                                end

                            end
                            if incart then
                                imgui.PopStyleColor(3)
                            end
                                isFounded = true
                            end
                        end
                    end
                imgui.EndChild()
                imgui.EndChild()
                imgui.SameLine()
                imgui.BeginChild("##234", imgui.ImVec2(250, 500))
                if imgui.Button(u8'Сканер', imgui.ImVec2(120, 20)) then
                    
                        check, checkmode = true, 1
                        press_alt()
                        sampAddChatMessage('[ Central Market Reborn ]: {FFFFFF}Проверка товаров.', settings.main.colormsg)

                end
                if imgui.Button(u8"Очистить", imgui.ImVec2(120, 20), imgui.SameLine()) then myitemsBuy = {} jsonSave(json_file_myBuyList, myitemsBuy) end
                imgui.Separator()
                if settings.main.smoothscroll then
                    imgui.BeginChild("##scroll2", imgui.ImVec2(249, 470), false, imgui.WindowFlags.NoScrollWithMouse)
                    imgui.Scroller("scroll2", settings.main.smoothhigh, settings.main.smoothdelay, imgui.HoveredFlags.AllowWhenBlockedByActiveItem)
                    else
                        imgui.BeginChild("##scroll2", imgui.ImVec2(240, 400))
                    end
                    if myitemsBuy ~= nil then
                    for i, _ in ipairs(myitemsBuy) do
                            if imgui.Button(u8(myitemsBuy[i][1])) then
                               

                                table.remove(myitemsBuy, i)
                                jsonSave(json_file_myBuyList, myitemsBuy)
                                break
                            end
                    end
                end
                    imgui.EndChild()
                    imgui.EndChild()
                if imgui.Button(u8"Продолжить", imgui.ImVec2(500, 40)) then
                   
                    mainWindowState = false secondaryWindowState = true inputs = {}

                    for i=1, #itemsBuy do
                        if itemsBuy[i][4] then table.insert(inputs, {imgui.ImInt(itemsBuy[i][2]), imgui.ImInt(itemsBuy[i][3]), i, false, imgui.ImBool(itemsBuy[i][5])}) end
                    end
                end
                imgui.SameLine()
                if imgui.Button(u8'Снять Скупку', imgui.ImVec2(250, 40)) then
                    delprod, delprodc = not delprod, 4
                    press_alt()
                    sampAddChatMessage(delprod and '[ Central Market Reborn ]: {FFFFFF}Cнятия с скупки. Подождите' or '[ Central Market Reborn ]: {FFFFFF}Отмена снятия с скупки', settings.main.colormsg)
                end
            else    
                imgui.Text(u8"К сожалению, у вас не загружены предметы\nЧто-бы загрузить нажмите на кнопку ниже! \nЗатем нажмите в лавке 'Выставить товар на покупку'!")
                if imgui.Button(u8'Сканер', imgui.ImVec2(330, 25)) then 
                    
                        check, checkmode = true, 1
                        press_alt()
                        sampAddChatMessage(check and '[ Central Market Reborn ]: {FFFFFF}Режим проверки товаров активирован.' or '[ Central Market Reborn ]: {FFFFFF}Режим проверки товаров деактивирован.', settings.main.colormsg)

                end
            end
        end




        if sellWindowState then
            menu(imgui)
            
            if #itemsSell ~= 0 then
                imgui.Text(u8"Все загруженные предметы:", imgui.SetCursorPosX(170))
                imgui.SameLine()
                imgui.Text(u8"Выбранные предметы:", imgui.SetCursorPosX(565))
                imgui.BeginChild('#fdghs', imgui.ImVec2(500, 500))
                imgui.InputText(u8'Поиск по названию', findBuf)
                imgui.Separator()
                if settings.main.smoothscroll then
                imgui.BeginChild("##1", imgui.ImVec2(500, 470), false, imgui.WindowFlags.NoScrollWithMouse)
                imgui.Scroller("scroll1", settings.main.smoothhigh, settings.main.smoothdelay, imgui.HoveredFlags.AllowWhenBlockedByActiveItem)
                else
                    imgui.BeginChild("##1", imgui.ImVec2(500, 470), false)
                end
                if findBuf.v == '' then
                local clipper = imgui.ImGuiListClipper(#itemsSell)
                    while clipper:Step() do                       
                for i = clipper.DisplayStart + 1, clipper.DisplayEnd do
                    local f = itemsSell[i]

                    local incart = check_table(itemsSell[i][1], myItemsSell)

                    if incart then                        
                        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.2, 0.2, 0.2, 1))
                        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.25, 0.25, 0.25, 1))
                        imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.3, 0.3, 0.3, 1))
                    end

                    if imgui.Button(u8(itemsSell[i][1])) then
                       

                        if not check_table(itemsSell[i][1], myItemsSell) then
                            table.insert(myItemsSell, {itemsSell[i][1], itemsSell[i][2], (settings.main.classicprice), true})
                            jsonSave(json_file_mySellList, myItemsSell)
                        else
                            local name = itemsSell[i][1]
                            table.remove(myItemsSell, check_index(name, myItemsSell))
                            jsonSave(json_file_mySellList, myItemsSell)
                        end
                    end

                    if incart then
                        imgui.PopStyleColor(3)
                    end
                end
            end

            end
                for i, _ in ipairs(itemsSell) do
                    if findBuf.v ~= '' then
                        local isFounded = false
                            local pat1 = string.rlower(itemsSell[i][1])
                            local pat2 = string.rlower(u8:decode(findBuf.v))                  

                            if pat1:find(pat2, 0, true) then
                                local incart = check_table(itemsSell[i][1], myItemsSell)

                                if incart then                        
                                    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.2, 0.2, 0.2, 1))
                                    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.25, 0.25, 0.25, 1))
                                    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.3, 0.3, 0.3, 1))
                                end

                                if imgui.Button(u8(itemsSell[i][1])) then
                                  
                                    if not check_table(itemsSell[i][1], myItemsSell) then
                                    table.insert(myItemsSell, {itemsSell[i][1], 1, 10, true})
                                    jsonSave(json_file_mySellList, myItemsSell)
                                else
                                    local name = itemsSell[i][1]
                                    table.remove(myItemsSell, check_index(name, myItemsSell))
                                    jsonSave(json_file_mySellList, myItemsSell)
                                end

                            end
                            if incart then
                                imgui.PopStyleColor(3)
                            end
                                
                                isFounded = true
                            end
                        end
                    end
                imgui.EndChild()
                imgui.EndChild()
                imgui.SameLine()
                imgui.BeginChild("##234", imgui.ImVec2(300, 500))
                if imgui.Button(u8'Сканер', imgui.ImVec2(140, 20)) then
                    if #itemsBuy == 0 then
                        sampAddChatMessage('[ Central Market Reborn ]: {FFFFFF}Сначала просканируйте предметы для скупки!', settings.main.colormsg)
                    else
                        
                            sampSendChat('/stats')
                            sampSendDialogResponse(235, 1, -1, nil)
                            itemsSell = {}
                            itemsSellPosition = {}
                            myItemsSell = jsonRead(json_file_mySellList)
                            check = true
                       
                    end
                end
                if imgui.Button(u8"Очистить", imgui.ImVec2(140, 20), imgui.SameLine()) then myItemsSell = {} jsonSave(json_file_mySellList, myItemsSell) end
                imgui.Separator()
                if settings.main.smoothscroll then
                    imgui.BeginChild("##scroll2", imgui.ImVec2(295, 470), false, imgui.WindowFlags.NoScrollWithMouse)
                    imgui.Scroller("scroll2", settings.main.smoothhigh, settings.main.smoothdelay, imgui.HoveredFlags.AllowWhenBlockedByActiveItem)
                    else
                        imgui.BeginChild("##scroll2", imgui.ImVec2(290, 500))
                    end
                    if myItemsSell ~= nil then
                    for i, _ in ipairs(myItemsSell) do
                            if imgui.Button(u8(myItemsSell[i][1])) then
                                

                                table.remove(myItemsSell, i)
                                jsonSave(json_file_mySellList, myItemsSell)
                                break
                            end
                    end
                end
                    imgui.EndChild()
                    imgui.EndChild()
                if imgui.Button(u8"Продолжить", imgui.ImVec2(500, 40)) then setState(STATES.sellWindow2State) inputs = {}
                    
                    for i=1, #myItemsSell do
                        if itemsSell[i][4] then table.insert(inputs, {imgui.ImInt(itemsSell[i][2]), imgui.ImInt(itemsSell[i][3]), i, false, imgui.ImBool(itemsSell[i][5])}) end
                    end
                end
                imgui.SameLine()
                if imgui.Button(u8"Снять продажу", imgui.ImVec2(300, 40)) then
                    
                    removeSell = true
                    press_alt()
                end
            else
                imgui.Text(u8"К сожалению, у вас не загружены предметы\nЧто-бы загрузить нажмите на кнопку ниже!")
                if imgui.Button(u8'Сканер', imgui.ImVec2(330, 25)) then
                    

                    if #itemsBuy == 0 then
                        sampAddChatMessage('[ Central Market Reborn ]: {FFFFFF}Сначала просканируйте предметы для скупки!', settings.main.colormsg)
                    else
                        sampSendChat('/stats')
                        sampSendDialogResponse(235, 1, -1, nil)
                        itemsSell = {}
                        itemsSellPosition = {}
                        myItemsSell = jsonRead(json_file_mySellList)
                        check = true
                    end
                end
            end
        end




        if buyWindowState then
            menu(imgui)

            if #itemsBuy ~= 0 then
                imgui.Text(u8"Все загруженные предметы:", imgui.SetCursorPosX(100))
                imgui.SameLine()
                imgui.Text(u8"Выбранные предметы:", imgui.SetCursorPosX(500))
                imgui.BeginChild("##11", imgui.ImVec2(500, 470))
                    imgui.RadioButton(u8"Искать по названию предмета", rbut, 1)
                    imgui.RadioButton(u8"Искать по номеру предмета", rbut, 2)
                    if rbut.v == 1 then imgui.InputText(u8'Поиск по названию', findBuf) end
                    if rbut.v == 2 then imgui.InputInt(u8'Поиск по номеру', findBufInt) end
                    for i, f in pairs(itemsBuy) do
                        local isFounded = false
                        if rbut.v == 1 then
                            local pat1 = string.rlower(itemsBuy[i][1])
                            local pat2 = string.rlower(u8:decode(findBuf.v))
                            if pat1:find(pat2, 0, true) then

                                if imgui.Button(u8(tostring(i))) then 
                                   

                                    if not itemsBuy[i][4] then itemsBuy[i][4] = true else itemsBuy[i][4] = false end
                                end
                                
                                imgui.Text(u8(itemsBuy[i][1]), imgui.SameLine())
                                if itemsBuy[i][2] ~= 1 then imgui.Text(u8(' - '..itemsBuy[i][2]..' шт.'), imgui.SameLine()) end
                                isFounded = true
                            end
                        end
                        if rbut.v == 2 then
                            if tostring(i):match(findBufInt.v, 0, true) then
                                if imgui.Button(tostring(i)) then stable(i) end
                                if itemsBuy[i][2] ~= 1 then  imgui.Text(u8(itemsBuy[i][2]..' шт.'), imgui.SameLine()) end
                                imgui.Text(u8(itemsBuy[i][1]), imgui.SameLine())
                                isFounded = true
                            end
                        end
                    end
                    imgui.EndChild()
                    imgui.BeginChild("##21", imgui.ImVec2(250, 470), imgui.SameLine())
                    if imgui.Button(u8'Сканер', imgui.ImVec2(120, 25)) then
                        

                        check, checkmode, itemsBuy = not check, 2, ({})
                        sampAddChatMessage(check and '[ Central Market Reborn ]: {FFFFFF}Режим проверки товаров активирован.' or '[ Central Market Reborn ]: {FFFFFF}Режим проверки товаров деактивирован.', settings.main.colormsg)
                    end
                    if imgui.Button(u8"Очистить", imgui.ImVec2(120, 25), imgui.SameLine()) then for i=1, #itemsBuy do itemsBuy[i][4] = false end end
                    for i=1, #itemsBuy do
                        if itemsBuy[i][4] then
                            if imgui.Button("#"..i) then itemsBuy[i][4] = false end
                            imgui.Text(u8(" "..itemsBuy[i][1]), imgui.SameLine())
                            if itemsBuy[i][2] ~= 1 then imgui.Text(u8(' - '..itemsBuy[i][2]..' шт.'), imgui.SameLine()) end
                        end
                    end
                imgui.EndChild()
                if imgui.Button(u8"Продолжить", imgui.ImVec2(500, 40)) then
                    
                    
                    inputsSell = {} secondarybuyWindowState = true buyWindowState = false

                    for i=1, #itemsBuy do 
                        if itemsBuy[i][4] then
                            local isFound = false 
                            for f, d in pairs(cfgsell.itemsBuym) do 
                                if f == itemsBuy[i][1] then isFound = true end 
                            end
                            if not isFound then cena = itemsBuy[i][3] else cena = cfgsell.itemsBuym[itemsBuy[i][1]] end
                            table.insert(inputsSell, {imgui.ImInt(itemsBuy[i][2]), imgui.ImInt(cena), i, false, imgui.ImBool(itemsBuy[i][5])})  
                        end 
                    end
                end
                imgui.SameLine()
                if imgui.Button(u8'Снять Продажу', imgui.ImVec2(250, 40)) then
                    
                    delprod, delprodc = not delprod, 1
                    sampAddChatMessage(delprod and '[ Central Market Reborn ]: {FFFFFF}Нажмите на кнопку {'..settings.main.color..'}«Удалить товар с продажи»' or '[ Central Market Reborn ]: {FFFFFF}Отмена снятия с продажи', settings.main.colormsg)
                end
            else    
                imgui.Text(u8"К сожалению, у вас не загружены предметы\nЧто-бы загрузить нажмите на кнопку ниже! \nЗатем нажмите в лавке 'Выставить товар на продажу'!")
                if imgui.Button(u8'Сканер', imgui.ImVec2(330, 25)) then 
                    
                        check, checkmode, itemsBuy = not check, 2, ({})
                        sampAddChatMessage(check and '[ Central Market Reborn ]: {FFFFFF}Режим проверки товаров активирован.' or '[ Central Market Reborn ]: {FFFFFF}Режим проверки товаров деактивирован.', settings.main.colormsg)
                end
            end
        end




        if secondarybuyWindowState then
            local isWarning = false
                imgui.BeginChild("##31", imgui.ImVec2(460, 450))
                    for i, n in pairs(inputsSell) do 
                        if itemsBuy[inputsSell[i][3]][4] then
                            imgui.Text(u8(" Предмет: "..itemsBuy[inputsSell[i][3]][1]), imgui.Separator())
                            if not inputsSell[i][5].v then imgui.InputInt(u8("##sellc"..i), inputsSell[i][1]) imgui.SameLine() imgui.Text(u8("- "..inputsSell[i][1].v..' шт. / '..itemsBuy[inputsSell[i][3]][2].." шт.")) end
                            imgui.InputInt(u8("##sell"..i), inputsSell[i][2])
                            imgui.SameLine()
                            imgui.Text(u8("- "..comma_value(inputsSell[i][2].v).."$"))
                            if inputsSell[i][2].v < 10 then imgui.TextColoredRGB("{FF2400}Минимальная цена товара 10$!") isWarning = true end
                            if inputsSell[i][1].v * inputsSell[i][2].v > 300000000 then imgui.TextColoredRGB("{FF2400}Максимальная цена товара 300.000.000$!") isWarning = true end
                            if inputsSell[i][1].v > itemsBuy[inputsSell[i][3]][2] then imgui.TextColoredRGB("{FF2400}У вас нету столько товаров на продажу.") isWarning = true end
                            imgui.Separator()
                        end
                    end
                    imgui.EndChild()
                    imgui.BeginGroup(imgui.SameLine())
                    if imgui.Button(u8"Вернуться к выбору", imgui.ImVec2(240, 75)) then secondarybuyWindowState = false buyWindowState = true end
                    if imgui.Button(u8"Начать Продажу", imgui.ImVec2(240, 75)) then 
                        sellP, shopMode = not buyProc, 2 press_alt() for i=1, #inputsSell do itemsBuy[inputsSell[i][3]][2] = inputsSell[i][1].v itemsBuy[inputsSell[i][3]][3] = inputsSell[i][2].v itemsBuy[inputsSell[i][3]][5] = inputsSell[i][5].v cfgsell.itemsBuym[itemsBuy[inputsSell[i][3]][1]]=inputsSell[i][2].v inicfg.save(cfgsell, 'Central Market\\ARZCentral-sell.ini') end 
                    end
                    if imgui.Button(u8"Сохранить Конфиг", imgui.ImVec2(240, 75)) then for i=1, #inputsSell do cfgsell.itemsBuym[itemsBuy[inputsSell[i][3]][1]]=inputsSell[i][2].v inicfg.save(cfgsell, 'Central Market\\ARZCentral-sell.ini') end end
                imgui.EndGroup()
            local mon = 0
            for i, n in pairs(inputsSell) do 
                if inputsSell[i][5].v then mon = mon + inputsSell[i][2].v else
                mon = mon + (inputsSell[i][1].v * inputsSell[i][2].v) end
            end
            imgui.Text(u8("Вы можете выставить товара на: "..comma_value(mon).." $"))
        end




        if secondaryWindowState then
            local isWarning = false
            imgui.BeginChild("##3", imgui.ImVec2(460, 450), false)
                imgui.InputText('##findmy', findMyItem)
                imgui.SameLine()
                imgui.Text(u8'Поиск по названию')
                imgui.Separator()
                if settings.main.smoothscroll then
                    imgui.BeginChild("##2", imgui.ImVec2(460, 400), false, imgui.WindowFlags.NoScrollWithMouse)
                    imgui.Scroller("scroll2", settings.main.smoothhigh - 20, settings.main.smoothdelay, imgui.HoveredFlags.AllowWhenBlockedByActiveItem)
                else
                    imgui.BeginChild("##3", imgui.ImVec2(460, 450))
                end
                if findMyItem ~= nil then
                    for i, _ in ipairs(myitemsBuy) do
                        local pat1 = string.rlower(myitemsBuy[i][1])
                            local pat2 = string.rlower(u8:decode(findMyItem.v))                  
                            if pat1:find(pat2, 0, true) then

                        local text = ""

                        local is_in_list = false

                        if avg_prices ~= nil then
                            if avg_prices.list[myitemsBuy[i][1]] ~= nil then
                                is_in_list = true
                            end
                        end

                        if avg_prices ~= nil and is_in_list then
                            text = " | Средняя цена: " .. comma_value(avg_prices.list[myitemsBuy[i][1]].sa.price).." $"
                        end

                        imgui.TextColoredRGB(i .. ' - ' .. myitemsBuy[i][1]..text)

                        local bcount = imgui.ImInt(myitemsBuy[i][2])
                        local bprice = imgui.ImInt(myitemsBuy[i][3])
                        
                        imgui.Text(u8('Кол-во.'))
                        imgui.SameLine()
                        imgui.InputInt(('##count' .. i), bcount)
                        imgui.Text(u8('Цена.   '))
                        imgui.SameLine()
                        imgui.InputInt(('##price' .. i), bprice)

                        
                        if myitemsBuy[i][2] ~= bcount.v then
                            myitemsBuy[i][2] = bcount.v
                            jsonSave(json_file_myBuyList, myitemsBuy)
                        end
                        
                        if myitemsBuy[i][3] ~= bprice.v then
                            myitemsBuy[i][3] = bprice.v
                            jsonSave(json_file_myBuyList, myitemsBuy)
                        end
                        imgui.SameLine()
                        imgui.Dummy(imgui.ImVec2(20,0))
                        imgui.SameLine()
                        
                        
                        if imgui.ButtonClickable(i ~= 1, fa.ICON_FA_ARROW_UP .. '##1' .. i) then
                            myitemsBuy[i][1], myitemsBuy[i-1][1] = myitemsBuy[i-1][1], myitemsBuy[i][1]
                            myitemsBuy[i][2], myitemsBuy[i-1][2] = myitemsBuy[i-1][2], myitemsBuy[i][2]
                            myitemsBuy[i][3], myitemsBuy[i-1][3] = myitemsBuy[i-1][3], myitemsBuy[i][3]
                            jsonSave(json_file_myBuyList, myitemsBuy)
                        end
                        
                        imgui.SameLine()
                        imgui.Dummy(imgui.ImVec2(1,0))
                        imgui.SameLine()
                        
                        if imgui.ButtonClickable(i ~= tonumber(#myitemsBuy), fa.ICON_FA_ARROW_DOWN .. '##2' .. i) then
                            myitemsBuy[i][1], myitemsBuy[i+1][1] = myitemsBuy[i+1][1], myitemsBuy[i][1]
                            myitemsBuy[i][2], myitemsBuy[i+1][2] = myitemsBuy[i+1][2], myitemsBuy[i][2]
                            myitemsBuy[i][3], myitemsBuy[i+1][3] = myitemsBuy[i+1][3], myitemsBuy[i][3]
                            jsonSave(json_file_myBuyList, myitemsBuy)
                        end
                        imgui.TextColoredRGB('Всего: ' .. yellowText(comma_value(bcount.v * bprice.v)) .. ' $')
                        imgui.Separator()
                    end
                end
                end
                
                if findMyItem.v == nil then
                    local clipper = imgui.ImGuiListClipper(#myitemsBuy)
                    while clipper:Step() do                       
                        for i = clipper.DisplayStart + 1, clipper.DisplayEnd do
                            imgui.Text(u8(i .. ' - ' .. myitemsBuy[i][1]))
                            
                            local bcount = imgui.ImInt(myitemsBuy[i][2])
                            local bprice = imgui.ImInt(myitemsBuy[i][3])
                            imgui.InputInt(('##count' .. i), bcount)
                            imgui.InputInt(('##price' .. i), bprice)
                            
                        if myitemsBuy[i][2] ~= bcount.v then
                            myitemsBuy[i][2] = bcount.v
                            jsonSave(json_file_myBuyList, myitemsBuy)
                        end

                        if myitemsBuy[i][3] ~= bprice.v then
                            myitemsBuy[i][3] = bprice.v
                            jsonSave(json_file_myBuyList, myitemsBuy)
                        end
                        imgui.SameLine()
                        imgui.Dummy(imgui.ImVec2(20,0))
                        imgui.SameLine()
                        if imgui.ButtonClickable(i ~= 1, fa.ICON_FA_ARROW_UP .. '##1' .. i) then
                            myitemsBuy[i][1], myitemsBuy[i-1][1] = myitemsBuy[i-1][1], myitemsBuy[i][1]
                            myitemsBuy[i][2], myitemsBuy[i-1][2] = myitemsBuy[i-1][2], myitemsBuy[i][2]
                            myitemsBuy[i][3], myitemsBuy[i-1][3] = myitemsBuy[i-1][3], myitemsBuy[i][3]
                            jsonSave(json_file_myBuyList, myitemsBuy)
                        end
                        imgui.SameLine()
                        imgui.Dummy(imgui.ImVec2(1,0))
                        imgui.SameLine()
                        if imgui.ButtonClickable(i ~= tonumber(#myitemsBuy), fa.ICON_FA_ARROW_DOWN .. '##2' .. i) then
                            myitemsBuy[i][1], myitemsBuy[i+1][1] = myitemsBuy[i+1][1], myitemsBuy[i][1]
                            myitemsBuy[i][2], myitemsBuy[i+1][2] = myitemsBuy[i+1][2], myitemsBuy[i][2]
                            myitemsBuy[i][3], myitemsBuy[i+1][3] = myitemsBuy[i+1][3], myitemsBuy[i][3]
                            jsonSave(json_file_myBuyList, myitemsBuy)
                        end
                        imgui.Separator()
                end
            end
                end
                imgui.EndChild()
                imgui.EndChild()
                imgui.BeginGroup(imgui.SameLine())
                    if imgui.Button(u8"Вернуться к выбору", imgui.ImVec2(240, 75)) then secondaryWindowState = false mainWindowState = true end
                    if imgui.Button(u8"Начать скупку", imgui.ImVec2(240, 75)) then 
                        idt = 1
                        buyProc, isEndBuy = not buyProc, false

                        press_alt()

                        for i=1, #inputs do itemsBuy[inputs[i][3]][2] = inputs[i][1].v itemsBuy[inputs[i][3]][3] = inputs[i][2].v itemsBuy[inputs[i][3]][5] = inputs[i][5].v inicfg.save(itemsBuy, 'Central Market\\ARZCentral.ini') end 
                    end
                    if imgui.Button(u8"Снять скупку", imgui.ImVec2(240, 75)) then 
                        delprod, delprodc = not delprod, 4
                        press_alt()
                        sampAddChatMessage(delprod and '[ Central Market Reborn ]: {FFFFFF}Нажмите на кнопку {'..settings.main.color..'}«Прекратить покупку товара»' or '[ Central Market Reborn ]: {FFFFFF}Отмена снятия с скупки', settings.main.colormsg) end
                imgui.EndGroup()
            local mon = 0
            for i, n in pairs(myitemsBuy) do 
                mon = mon + (myitemsBuy[i][2] * myitemsBuy[i][3])
            end
            if getPlayerMoney() < mon then color = "{ff2400}" else color = "{178f2b}" end
            imgui.Text(u8("Всего будет потрачено: "..comma_value(mon).." $"))
            imgui.TextColoredRGB("Ваши вирты: "..color..comma_value(getPlayerMoney()).." $")
        end



        
        if sellWindow2State then
            local isWarning = false
            imgui.BeginChild("##3", imgui.ImVec2(700, 650), false)
                imgui.InputText('##findmy', findMyItem)
                imgui.SameLine()
                imgui.Text(u8'Поиск по названию')
                imgui.Separator()

                if settings.main.smoothscroll then
                    imgui.BeginChild("##2", imgui.ImVec2(700, 620), false, imgui.WindowFlags.NoScrollWithMouse)
                    imgui.Scroller("scroll2", settings.main.smoothhigh - 20, settings.main.smoothdelay, imgui.HoveredFlags.AllowWhenBlockedByActiveItem)
                else
                    imgui.BeginChild("##3", imgui.ImVec2(700, 620))
                    imgui.Dummy(imgui.ImVec2(1,0))
                end
                    for i, _ in ipairs(myItemsSell) do
                        local pat1 = string.rlower(myItemsSell[i][1])
                            local pat2 = string.rlower(u8:decode(findMyItem.v))                  
                            if pat1:find(pat2, 0, true) then

                        local global_item = nil

                        for ddf = 1, #itemsSell do
                            if itemsSell[ddf][1] == myItemsSell[i][1] then
                                global_item = ddf
                                break
                            end
                        end 

                        local total_amount = global_item and itemsSell[global_item][2] or 0

                        local text = ""

                        local is_in_list = false

                        if avg_prices ~= nil then
                            if avg_prices.list[myItemsSell[i][1]] ~= nil then
                                is_in_list = true
                            end
                        end

                        if avg_prices ~= nil and is_in_list then
                            local price = avg_prices.list[myItemsSell[i][1]].sa.price

                            if type(price) == "table" then
                                text = " | Средняя цена: " .. comma_value(price[1]).." $ - "..comma_value(price[2]).." $"
                            else
                                text = " | Средняя цена: " .. comma_value(price).." $"
                            end

                        end

                        color = "{178f2b}"
                        imgui.Dummy(imgui.ImVec2(1,0))
                        imgui.TextColoredRGB(i .. ' - ' .. myItemsSell[i][1] .. ' | всего ' ..yellowText(comma_value(total_amount)).. ' шт.'..text)
                        imgui.Dummy(imgui.ImVec2(1,0))

                        local sellAll = imgui.ImBool(myItemsSell[i][4])
                        
                        local price = myItemsSell[i][3]

                        if avg_prices ~= nil then
                            if myItemsSell[i][3] == 10 and avg_prices.list[myItemsSell[i][1]] ~= nil and settings.main.useAvgPrice then
                                price = avg_prices.list[myItemsSell[i][1]].sa.price
                                
                                if type(price) == "table" then
                                    price = price[1]
                                end
                            else 
                                price = myItemsSell[i][3]
                            end
                        end 
                        
                        local bprice = imgui.ImInt(price)
                        local bcount = imgui.ImInt(sellAll.v and total_amount or myItemsSell[i][2])
                        
                        imgui.PushItemWidth(200)
                        imgui.Text(u8('Кол-во.'))
                        imgui.SameLine()
                        if imgui.InputInt(('##count' .. i), bcount) then
                            if bcount.v < 0 then
                                bcount.v = 0
                            elseif bcount.v > total_amount then
                                bcount.v = total_amount
                            end

                            if sellAll.v then
                                bcount.v = total_amount
                            end

                        end
                        
                        imgui.SameLine()
                        imgui.Dummy(imgui.ImVec2(20,0))
                        imgui.SameLine()            
                        if imgui.Checkbox(u8'Продать все'.."##"..i, sellAll) then
                            myItemsSell[i][4] = sellAll.v
                            jsonSave(json_file_mySellList, myItemsSell)

                            if sellAll.v then
                                bcount.v = total_amount
                            else
                                bcount.v = myItemsSell[i][2]
                            end
                        end           
                           
                        imgui.Text(u8('Цена.   '))
                        imgui.SameLine()
                        if imgui.InputInt(('##price' .. i), bprice) then
                            if bprice.v < 10 then
                                bprice.v = 10
                            end
                        end

                        imgui.SameLine()
                        imgui.Dummy(imgui.ImVec2(350,0))
                        imgui.SameLine()
                        if imgui.ButtonClickable(i ~= 1, fa.ICON_FA_ARROW_UP .. '##1' .. i) then
                            myItemsSell[i][1], myItemsSell[i-1][1] = myItemsSell[i-1][1], myItemsSell[i][1]
                            myItemsSell[i][2], myItemsSell[i-1][2] = myItemsSell[i-1][2], myItemsSell[i][2]
                            myItemsSell[i][3], myItemsSell[i-1][3] = myItemsSell[i-1][3], myItemsSell[i][3]
                            jsonSave(json_file_mySellList, myItemsSell)
                        end
                        imgui.SameLine()
                        imgui.Dummy(imgui.ImVec2(1,0))
                        imgui.SameLine()
                        if imgui.ButtonClickable(i ~= tonumber(#myItemsSell), fa.ICON_FA_ARROW_DOWN .. '##2' .. i) then
                            myItemsSell[i][1], myItemsSell[i+1][1] = myItemsSell[i+1][1], myItemsSell[i][1]
                            myItemsSell[i][2], myItemsSell[i+1][2] = myItemsSell[i+1][2], myItemsSell[i][2]
                            myItemsSell[i][3], myItemsSell[i+1][3] = myItemsSell[i+1][3], myItemsSell[i][3]
                            jsonSave(json_file_mySellList, myItemsSell)
                        end
                        
                        if not sellAll.v and myItemsSell[i][2] ~= bcount.v then
                            myItemsSell[i][2] = bcount.v
                            jsonSave(json_file_mySellList, myItemsSell)
                        end

                        if myItemsSell[i][3] ~= bprice.v and  not settings.main.useAvgPrice then
                            myItemsSell[i][3] = bprice.v
                            jsonSave(json_file_mySellList, myItemsSell)
                        end   

                        imgui.Dummy(imgui.ImVec2(1,0))
                        imgui.TextColoredRGB('Всего: ' .. greenText(comma_value(bcount.v * bprice.v)) .. ' $')
                        imgui.Dummy(imgui.ImVec2(1,0))
                        imgui.Separator()
                    end
                    
                end

                imgui.EndChild()
                imgui.EndChild()
                imgui.BeginGroup(imgui.SameLine())
                    if imgui.Button(u8"Вернуться к выбору", imgui.ImVec2(240, 75)) then setState(STATES.sellWindowState) end
                    imgui.Dummy(imgui.ImVec2(1,460))
                    imgui.Dummy(imgui.ImVec2(15,0))
                    imgui.SameLine()
                    if imgui.Checkbox(u8'Заполнять средними ценами', useAvgPrice) then
                        settings.main.useAvgPrice = useAvgPrice.v
                        inicfg.save(settings, 'Central Market\\ARZCentral-settings')
                    end
                    
                    imgui.Dummy(imgui.ImVec2(0,5))
                    if imgui.Button(u8"Начать продажу", imgui.ImVec2(240, 75)) then 
                        idt = 1
                        sellProc = true
                        press_alt()
                    end
                    
                imgui.EndGroup()
            local mon = 0
            for i, n in pairs(myItemsSell) do 
                mon = mon + (myItemsSell[i][2] * myItemsSell[i][3])
            end
            color = "{178f2b}"
            imgui.TextColoredRGB("Всего будет заработано: "..color..comma_value(mon).." $")
        end





        if settingWindowState then
            menu(imgui)

            imgui.PushItemWidth(290)
            imgui.Text(u8'Задержка на парсер товаров ( смена странички )')
            if imgui.SliderInt('##delay2', parserBuf, 50, 200) then settings.main.delayParse = parserBuf.v inicfg.save(settings, 'Central Market\\ARZCentral-settings') end 
            imgui.Text(u8'Задержка на выставление товаров')
            if imgui.SliderInt('##delay', delayInt, 50, 1000) then settings.main.delayVist = delayInt.v inicfg.save(settings, 'Central Market\\ARZCentral-settings') end 
            if imgui.ListBox('##styleBox', selectStyle, {'Dark Style', 'Purple Style', 'Blue-Gray Style', 'Orange Style', 'Blue-Black', 'Green Style', 'Purpur Style', 'Red Style', 'Yellow Style'}, 9) then
                if selectStyle.v == 0 then setDarkStyle() elseif selectStyle.v == 1 then setPurpleStyle() elseif selectStyle.v == 2 then  setBlueGraytheme() elseif selectStyle.v == 3 then setOrangeStyle() elseif selectStyle.v == 4 then setBlueBlackStyle() elseif selectStyle.v == 5 then setGreenStyle() elseif selectStyle.v == 6 then setPurpurStyle() elseif selectStyle.v == 7 then setRedStyle() elseif selectStyle.v == 8 then setYellowStyle() end
            end
            if imgui.InputInt(u8'Количество при добавлении', ccount) then
                settings.main.classiccount = ccount.v
                inicfg.save(settings, 'Central Market\\ARZCentral-settings')
            end

            if imgui.InputInt(u8'Цена при добавлении', cprice) then
                settings.main.classicprice = cprice.v
                inicfg.save(settings, 'Central Market\\ARZCentral-settings')
            end

                if imgui.Checkbox(u8'Плавная прокрутка списков', smooth) then
                settings.main.smoothscroll = smooth.v
                inicfg.save(settings, 'Central Market\\ARZCentral-settings')
            end
            if smooth.v then
                if imgui.InputInt(u8'Строк за одно деление прокрутки', smoothInt1) then
                    settings.main.smoothhigh = smoothInt1.v
                    inicfg.save(settings, 'Central Market\\ARZCentral-settings')
                end

                if imgui.InputInt(u8'Время анимации прокрутки', smoothInt2) then
                    settings.main.smoothdelay = smoothInt2.v
                    inicfg.save(settings, 'Central Market\\ARZCentral-settings')
                end
            end
            imgui.PopItemWidth()
        end






        if infoWindowState then
            menu(imgui)

            imgui.PushFont(logosize)
            imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(u8("Основные ссылочки")).x) / 2)
            imgui.TextColoredRGB('{'..settings.main.color..'}Основные ссылочки')
            imgui.PopFont()
            imgui.Separator()
            imgui.PushFont(fontsize)
            
            
            imgui.Dummy(imgui.ImVec2(1,0))
            imgui.Text(u8'Это доработаный скрипт от Yondime')
            imgui.Dummy(imgui.ImVec2(1,0))
            imgui.Separator()
            
            imgui.Dummy(imgui.ImVec2(1,0))
            imgui.Text(u8'Тема на BlastHack: ') imgui.SameLine()
            imgui.Link('https://www.blast.hk/threads/216930/', u8'https://www.blast.hk/threads/216930/')
            imgui.Dummy(imgui.ImVec2(1,0))
            
            imgui.Text(u8'По всем вопросам сюда: ') imgui.SameLine()
            imgui.Link('https://t.me/criceta0', u8'@criceta0')
            imgui.Dummy(imgui.ImVec2(1,0))
            imgui.Separator()
            
            
            imgui.Dummy(imgui.ImVec2(1,0))
            imgui.Text(u8'Для средних цен установите: ') imgui.SameLine()
            imgui.Link('https://www.blast.hk/threads/88005/', u8'https://www.blast.hk/threads/88005/')
            imgui.Dummy(imgui.ImVec2(1,0))
            

            imgui.PopFont()
            imgui.Separator()
        end

        imgui.End()
    end

    if not allWindow.v then
        imgui.Process = false
    end
end

function reloadscript()
    lua_thread.create(function()
    settings.main.imgui = true
    inicfg.save(settings, 'Central Market\\ARZCentral-settings')
    wait(100)
    thisScript():reload()
    end)
end

function comma_value(n)
	local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end

function imgui.Link(link,name,myfunc)
	local ImVec2 = imgui.ImVec2
	local ImVec4 = imgui.ImVec4
    myfunc = type(name) == 'boolean' and name or myfunc or false
    name = type(name) == 'string' and name or type(name) == 'boolean' and link or link
    local size = imgui.CalcTextSize(name)
    local p = imgui.GetCursorScreenPos()
    local p2 = imgui.GetCursorPos()
    local resultBtn = imgui.InvisibleButton('##'..link..name, size)
    if resultBtn then
        if not myfunc then
            os.execute('explorer '..link)
        end
    end
    imgui.SetCursorPos(p2)
    if imgui.IsItemHovered() then
        imgui.TextColored(imgui.ImVec4(0.916, 0.113, 0.863, 1), name)
        imgui.GetWindowDrawList():AddLine(imgui.ImVec2(p.x, p.y + size.y), imgui.ImVec2(p.x + size.x, p.y + size.y), imgui.GetColorU32(imgui.GetStyle().Colors[imgui.Col.ButtonHovered]))
    else
        imgui.TextColored(imgui.ImVec4(0.129, 0.710, 0.282, 1), name)
    end
    return resultBtn
end

function imgui.TextColoredRGB(text)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImColor(r, g, b, a):GetVec4()
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else imgui.Text(u8(w)) end
        end
    end
    render_text(text)
end

function setDarkStyle()
    settings.main.color, settings.main.colormsg, settings.main.stylemode = 'bdb7b7', 0xFFbdb7b7, 0
    inicfg.save(settings, 'Central Market\\ARZCentral-settings')
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    style.WindowPadding = imgui.ImVec2(8, 8)
    style.WindowRounding = 6
    style.ChildWindowRounding = 5
    style.FramePadding = imgui.ImVec2(5, 3)
    style.FrameRounding = 3.0
    style.ItemSpacing = imgui.ImVec2(5, 4)
    style.ItemInnerSpacing = imgui.ImVec2(4, 4)
    style.IndentSpacing = 21
    style.ScrollbarSize = 15.0
    style.ScrollbarRounding = 13
    style.GrabMinSize = 8
    style.GrabRounding = 1
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
    colors[clr.Text]                   = ImVec4(0.90, 0.90, 0.90, 1.00)
    colors[clr.TextDisabled]           = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.WindowBg]               = ImVec4(0.00, 0.00, 0.00, 1.00)
    colors[clr.ChildWindowBg]          = ImVec4(0.00, 0.00, 0.00, 1.00)
    colors[clr.PopupBg]                = ImVec4(0.00, 0.00, 0.00, 1.00)
    colors[clr.Border]                 = ImVec4(0.82, 0.77, 0.78, 1.00)
    colors[clr.BorderShadow]           = ImVec4(0.35, 0.35, 0.35, 0.66)
    colors[clr.FrameBg]                = ImVec4(1.00, 1.00, 1.00, 0.28)
    colors[clr.FrameBgHovered]         = ImVec4(0.68, 0.68, 0.68, 0.67)
    colors[clr.FrameBgActive]          = ImVec4(0.79, 0.73, 0.73, 0.62)
    colors[clr.TitleBg]                = ImVec4(0.00, 0.00, 0.00, 1.00)
    colors[clr.TitleBgActive]          = ImVec4(0.46, 0.46, 0.46, 1.00)
    colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 1.00)
    colors[clr.MenuBarBg]              = ImVec4(0.00, 0.00, 0.00, 0.80)
    colors[clr.ScrollbarBg]            = ImVec4(0.00, 0.00, 0.00, 0.60)
    colors[clr.ScrollbarGrab]          = ImVec4(1.00, 1.00, 1.00, 0.87)
    colors[clr.ScrollbarGrabHovered]   = ImVec4(1.00, 1.00, 1.00, 0.79)
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.80, 0.50, 0.50, 0.40)
    colors[clr.ComboBg]                = ImVec4(0.24, 0.24, 0.24, 0.99)
    colors[clr.CheckMark]              = ImVec4(0.99, 0.99, 0.99, 0.52)
    colors[clr.SliderGrab]             = ImVec4(1.00, 1.00, 1.00, 0.42)
    colors[clr.SliderGrabActive]       = ImVec4(0.76, 0.76, 0.76, 1.00)
    colors[clr.Button]                 = ImVec4(0.51, 0.51, 0.51, 0.60)
    colors[clr.ButtonHovered]          = ImVec4(0.68, 0.68, 0.68, 1.00)
    colors[clr.ButtonActive]           = ImVec4(0.67, 0.67, 0.67, 1.00)
    colors[clr.Header]                 = ImVec4(0.72, 0.72, 0.72, 0.54)
    colors[clr.HeaderHovered]          = ImVec4(0.92, 0.92, 0.95, 0.77)
    colors[clr.HeaderActive]           = ImVec4(0.82, 0.82, 0.82, 0.80)
    colors[clr.Separator]              = ImVec4(0.73, 0.73, 0.73, 1.00)
    colors[clr.SeparatorHovered]       = ImVec4(0.81, 0.81, 0.81, 1.00)
    colors[clr.SeparatorActive]        = ImVec4(0.74, 0.74, 0.74, 1.00)
    colors[clr.ResizeGrip]             = ImVec4(0.80, 0.80, 0.80, 0.30)
    colors[clr.ResizeGripHovered]      = ImVec4(0.95, 0.95, 0.95, 0.60)
    colors[clr.ResizeGripActive]       = ImVec4(1.00, 1.00, 1.00, 0.90)
    colors[clr.CloseButton]            = ImVec4(0.45, 0.45, 0.45, 0.50)
    colors[clr.CloseButtonHovered]     = ImVec4(0.70, 0.70, 0.90, 0.60)
    colors[clr.CloseButtonActive]      = ImVec4(0.70, 0.70, 0.70, 1.00)
    colors[clr.PlotLines]              = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.PlotLinesHovered]       = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.PlotHistogram]          = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.TextSelectedBg]         = ImVec4(1.00, 1.00, 1.00, 0.35)
    colors[clr.ModalWindowDarkening]   = ImVec4(0.88, 0.88, 0.88, 0.35)
end
function setPurpleStyle()
    settings.main.color, settings.main.colormsg,settings.main.stylemode = '9720e6', 0xFF9720e6, 1
    inicfg.save(settings, 'Central Market\\ARZCentral-settings')
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    style.WindowPadding = imgui.ImVec2(8, 8)
    style.WindowRounding = 6
    style.ChildWindowRounding = 5
    style.FramePadding = imgui.ImVec2(5, 3)
    style.FrameRounding = 3.0
    style.ItemSpacing = imgui.ImVec2(5, 4)
    style.ItemInnerSpacing = imgui.ImVec2(4, 4)
    style.IndentSpacing = 21
    style.ScrollbarSize = 15.0
    style.ScrollbarRounding = 13
    style.GrabMinSize = 8
    style.GrabRounding = 1
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
    colors[clr.Text]                   = ImVec4(0.90, 0.90, 0.90, 1.00)
    colors[clr.WindowBg]              = ImVec4(0.14, 0.12, 0.16, 1.00);
    colors[clr.ChildWindowBg]         = ImVec4(0.30, 0.20, 0.39, 0.00);
    colors[clr.PopupBg]               = ImVec4(0.05, 0.05, 0.10, 0.90);
    colors[clr.Border]                = ImVec4(0.89, 0.85, 0.92, 0.30);
    colors[clr.BorderShadow]          = ImVec4(0.00, 0.00, 0.00, 0.00);
    colors[clr.FrameBg]               = ImVec4(0.30, 0.20, 0.39, 1.00);
    colors[clr.FrameBgHovered]        = ImVec4(0.41, 0.19, 0.63, 0.68);
    colors[clr.FrameBgActive]         = ImVec4(0.41, 0.19, 0.63, 1.00);
    colors[clr.TitleBg]               = ImVec4(0.41, 0.19, 0.63, 0.45);
    colors[clr.TitleBgCollapsed]      = ImVec4(0.41, 0.19, 0.63, 0.35);
    colors[clr.TitleBgActive]         = ImVec4(0.41, 0.19, 0.63, 0.78);
    colors[clr.MenuBarBg]             = ImVec4(0.30, 0.20, 0.39, 0.57);
    colors[clr.ScrollbarBg]           = ImVec4(0.30, 0.20, 0.39, 1.00);
    colors[clr.ScrollbarGrab]         = ImVec4(0.41, 0.19, 0.63, 0.31);
    colors[clr.ScrollbarGrabHovered]  = ImVec4(0.41, 0.19, 0.63, 0.78);
    colors[clr.ScrollbarGrabActive]   = ImVec4(0.41, 0.19, 0.63, 1.00);
    colors[clr.ComboBg]               = ImVec4(0.30, 0.20, 0.39, 1.00);
    colors[clr.CheckMark]             = ImVec4(0.56, 0.61, 1.00, 1.00);
    colors[clr.SliderGrab]            = ImVec4(0.41, 0.19, 0.63, 0.24);
    colors[clr.SliderGrabActive]      = ImVec4(0.41, 0.19, 0.63, 1.00);
    colors[clr.Button]                = ImVec4(0.41, 0.19, 0.63, 0.44);
    colors[clr.ButtonHovered]         = ImVec4(0.41, 0.19, 0.63, 0.86);
    colors[clr.ButtonActive]          = ImVec4(0.64, 0.33, 0.94, 1.00);
    colors[clr.Header]                = ImVec4(0.41, 0.19, 0.63, 0.76);
    colors[clr.HeaderHovered]         = ImVec4(0.41, 0.19, 0.63, 0.86);
    colors[clr.HeaderActive]          = ImVec4(0.41, 0.19, 0.63, 1.00);
    colors[clr.ResizeGrip]            = ImVec4(0.41, 0.19, 0.63, 0.20);
    colors[clr.ResizeGripHovered]     = ImVec4(0.41, 0.19, 0.63, 0.78);
    colors[clr.ResizeGripActive]      = ImVec4(0.41, 0.19, 0.63, 1.00);
    colors[clr.CloseButton]           = ImVec4(1.00, 1.00, 1.00, 0.75);
    colors[clr.CloseButtonHovered]    = ImVec4(0.88, 0.74, 1.00, 0.59);
    colors[clr.CloseButtonActive]     = ImVec4(0.88, 0.85, 0.92, 1.00);
    colors[clr.PlotLines]             = ImVec4(0.89, 0.85, 0.92, 0.63);
    colors[clr.PlotLinesHovered]      = ImVec4(0.41, 0.19, 0.63, 1.00);
    colors[clr.PlotHistogram]         = ImVec4(0.89, 0.85, 0.92, 0.63);
    colors[clr.PlotHistogramHovered]  = ImVec4(0.41, 0.19, 0.63, 1.00);
    colors[clr.TextSelectedBg]        = ImVec4(0.41, 0.19, 0.63, 0.43);
    colors[clr.ModalWindowDarkening]  = ImVec4(0.20, 0.20, 0.20, 0.35);
end
function setBlueGraytheme()
    settings.main.color, settings.main.colormsg,settings.main.stylemode = '00BFFF', 0xFF00BFFF, 2
    inicfg.save(settings, 'Central Market\\ARZCentral-settings')
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    style.WindowPadding = imgui.ImVec2(8, 8)
    style.WindowRounding = 6
    style.ChildWindowRounding = 5
    style.FramePadding = imgui.ImVec2(5, 3)
    style.FrameRounding = 3.0
    style.ItemSpacing = imgui.ImVec2(5, 4)
    style.ItemInnerSpacing = imgui.ImVec2(4, 4)
    style.IndentSpacing = 21
    style.ScrollbarSize = 15.0
    style.ScrollbarRounding = 13
    style.GrabMinSize = 8
    style.GrabRounding = 1
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

    imgui.GetStyle().WindowPadding = imgui.ImVec2(8, 8)
    imgui.GetStyle().WindowRounding = 16.0
    imgui.GetStyle().FramePadding = imgui.ImVec2(5, 3)
    imgui.GetStyle().ItemSpacing = imgui.ImVec2(4, 4)
    imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(5, 5)
    imgui.GetStyle().IndentSpacing = 9.0
    imgui.GetStyle().ScrollbarSize = 17.0
    imgui.GetStyle().ScrollbarRounding = 16.0
    imgui.GetStyle().GrabMinSize = 7.0
    imgui.GetStyle().GrabRounding = 6.0
    imgui.GetStyle().ChildWindowRounding = 6.0
    imgui.GetStyle().FrameRounding = 6.0

    colors[clr.Text]                   = ImVec4(0.90, 0.90, 0.90, 1.00);
    colors[clr.TextDisabled]           = ImVec4(0.60, 0.60, 0.60, 1.00);
    colors[clr.WindowBg]               = ImVec4(0.11, 0.11, 0.11, 1.00);
    colors[clr.ChildWindowBg]          = ImVec4(0.13, 0.13, 0.13, 1.00);
    colors[clr.PopupBg]                = ImVec4(0.11, 0.11, 0.11, 1.00);
    colors[clr.Border]                 = ImVec4(0.26, 0.46, 0.82, 1.00);
    colors[clr.BorderShadow]           = ImVec4(0.26, 0.46, 0.82, 1.00);
    colors[clr.FrameBg]                = ImVec4(0.26, 0.46, 0.82, 0.59);
    colors[clr.FrameBgHovered]         = ImVec4(0.26, 0.46, 0.82, 0.88);
    colors[clr.FrameBgActive]          = ImVec4(0.28, 0.53, 1.00, 1.00);
    colors[clr.TitleBg]                = ImVec4(0.26, 0.46, 0.82, 1.00);
    colors[clr.TitleBgActive]          = ImVec4(0.26, 0.46, 0.82, 1.00);
    colors[clr.TitleBgCollapsed]       = ImVec4(0.26, 0.46, 0.82, 1.00);
    colors[clr.MenuBarBg]              = ImVec4(0.26, 0.46, 0.82, 0.75);
    colors[clr.ScrollbarBg]            = ImVec4(0.11, 0.11, 0.11, 1.00);
    colors[clr.ScrollbarGrab]          = ImVec4(0.26, 0.46, 0.82, 0.68);
    colors[clr.ScrollbarGrabHovered]   = ImVec4(0.26, 0.46, 0.82, 1.00);
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.26, 0.46, 0.82, 1.00);
    colors[clr.ComboBg]                = ImVec4(0.26, 0.46, 0.82, 0.79);
    colors[clr.CheckMark]              = ImVec4(1.000, 0.000, 0.000, 1.000)
    colors[clr.SliderGrab]             = ImVec4(0.263, 0.459, 0.824, 1.000)
    colors[clr.SliderGrabActive]       = ImVec4(0.66, 0.66, 0.66, 1.00);
    colors[clr.Button]                 = ImVec4(0.26, 0.46, 0.82, 1.00);
    colors[clr.ButtonHovered]          = ImVec4(0.26, 0.46, 0.82, 0.59);
    colors[clr.ButtonActive]           = ImVec4(0.26, 0.46, 0.82, 1.00);
    colors[clr.Header]                 = ImVec4(0.26, 0.46, 0.82, 1.00);
    colors[clr.HeaderHovered]          = ImVec4(0.26, 0.46, 0.82, 0.74);
    colors[clr.HeaderActive]           = ImVec4(0.26, 0.46, 0.82, 1.00);
    colors[clr.Separator]              = ImVec4(0.37, 0.37, 0.37, 1.00);
    colors[clr.SeparatorHovered]       = ImVec4(0.60, 0.60, 0.70, 1.00);
    colors[clr.SeparatorActive]        = ImVec4(0.70, 0.70, 0.90, 1.00);
    colors[clr.ResizeGrip]             = ImVec4(1.00, 1.00, 1.00, 0.30);
    colors[clr.ResizeGripHovered]      = ImVec4(1.00, 1.00, 1.00, 0.60);
    colors[clr.ResizeGripActive]       = ImVec4(1.00, 1.00, 1.00, 0.90);
    colors[clr.CloseButton]            = ImVec4(0.00, 0.00, 0.00, 1.00);
    colors[clr.CloseButtonHovered]     = ImVec4(0.00, 0.00, 0.00, 0.60);
    colors[clr.CloseButtonActive]      = ImVec4(0.35, 0.35, 0.35, 1.00);
    colors[clr.PlotLines]              = ImVec4(1.00, 1.00, 1.00, 1.00);
    colors[clr.PlotLinesHovered]       = ImVec4(0.90, 0.70, 0.00, 1.00);
    colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00);
    colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00);
    colors[clr.TextSelectedBg]         = ImVec4(0.00, 0.00, 1.00, 0.35);
    colors[clr.ModalWindowDarkening]   = ImVec4(0.20, 0.20, 0.20, 0.35);
end

function setOrangeStyle()
    settings.main.color, settings.main.colormsg,settings.main.stylemode = 'FF8C00', 0xFFFF8C00, 3
    inicfg.save(settings, 'Central Market\\ARZCentral-settings')
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    style.WindowPadding = imgui.ImVec2(8, 8)
    style.WindowRounding = 6
    style.ChildWindowRounding = 5
    style.FramePadding = imgui.ImVec2(5, 3)
    style.FrameRounding = 3.0
    style.ItemSpacing = imgui.ImVec2(5, 4)
    style.ItemInnerSpacing = imgui.ImVec2(4, 4)
    style.IndentSpacing = 21
    style.ScrollbarSize = 15.0
    style.ScrollbarRounding = 13
    style.GrabMinSize = 8
    style.GrabRounding = 1
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

    imgui.GetStyle().WindowPadding = imgui.ImVec2(8, 8)
    imgui.GetStyle().WindowRounding = 16.0
    imgui.GetStyle().FramePadding = imgui.ImVec2(5, 3)
    imgui.GetStyle().ItemSpacing = imgui.ImVec2(4, 4)
    imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(5, 5)
    imgui.GetStyle().IndentSpacing = 9.0
    imgui.GetStyle().ScrollbarSize = 17.0
    imgui.GetStyle().ScrollbarRounding = 16.0
    imgui.GetStyle().GrabMinSize = 7.0
    imgui.GetStyle().GrabRounding = 6.0
    imgui.GetStyle().ChildWindowRounding = 6.0
    imgui.GetStyle().FrameRounding = 6.0
    colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 1.00)
    colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.96)
    colors[clr.Border]                 = ImVec4(0.73, 0.36, 0.00, 0.00)
    colors[clr.FrameBg]                = ImVec4(0.49, 0.24, 0.00, 1.00)
    colors[clr.FrameBgHovered]         = ImVec4(0.65, 0.32, 0.00, 1.00)
    colors[clr.FrameBgActive]          = ImVec4(0.73, 0.36, 0.00, 1.00)
    colors[clr.TitleBg]                = ImVec4(0.15, 0.11, 0.09, 1.00)
    colors[clr.TitleBgActive]          = ImVec4(0.73, 0.36, 0.00, 1.00)
    colors[clr.TitleBgCollapsed]       = ImVec4(0.15, 0.11, 0.09, 0.51)
    colors[clr.MenuBarBg]              = ImVec4(0.62, 0.31, 0.00, 1.00)
    colors[clr.CheckMark]              = ImVec4(1.00, 0.49, 0.00, 1.00)
    colors[clr.SliderGrab]             = ImVec4(0.84, 0.41, 0.00, 1.00)
    colors[clr.SliderGrabActive]       = ImVec4(0.98, 0.49, 0.00, 1.00)
    colors[clr.Button]                 = ImVec4(0.73, 0.36, 0.00, 0.40)
    colors[clr.ButtonHovered]          = ImVec4(0.73, 0.36, 0.00, 1.00)
    colors[clr.ButtonActive]           = ImVec4(1.00, 0.50, 0.00, 1.00)
    colors[clr.Header]                 = ImVec4(0.49, 0.24, 0.00, 1.00)
    colors[clr.HeaderHovered]          = ImVec4(0.70, 0.35, 0.01, 1.00)
    colors[clr.HeaderActive]           = ImVec4(1.00, 0.49, 0.00, 1.00)
    colors[clr.SeparatorHovered]       = ImVec4(0.49, 0.24, 0.00, 0.78)
    colors[clr.SeparatorActive]        = ImVec4(0.49, 0.24, 0.00, 1.00)
    colors[clr.ResizeGrip]             = ImVec4(0.48, 0.23, 0.00, 1.00)
    colors[clr.ResizeGripHovered]      = ImVec4(0.78, 0.38, 0.00, 1.00)
    colors[clr.ResizeGripActive]       = ImVec4(1.00, 0.49, 0.00, 1.00)
    colors[clr.PlotLines]              = ImVec4(0.83, 0.41, 0.00, 1.00)
    colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.99, 0.00, 1.00)
    colors[clr.PlotHistogram]          = ImVec4(0.93, 0.46, 0.00, 1.00)
    colors[clr.TextSelectedBg]         = ImVec4(0.26, 0.59, 0.98, 0.00)
    colors[clr.ScrollbarBg]            = ImVec4(0.00, 0.00, 0.00, 0.53)
    colors[clr.ScrollbarGrab]          = ImVec4(0.33, 0.33, 0.33, 1.00)
    colors[clr.ScrollbarGrabHovered]   = ImVec4(0.39, 0.39, 0.39, 1.00)
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.48, 0.48, 0.48, 1.00)
    colors[clr.CloseButton]            = colors[clr.FrameBg]
    colors[clr.CloseButtonHovered]     = colors[clr.FrameBgHovered]
    colors[clr.CloseButtonActive]      = colors[clr.FrameBgActive]
end

function setBlueBlackStyle()
    settings.main.color, settings.main.colormsg,settings.main.stylemode = '0000FF', 0xFF0000FF, 4
    inicfg.save(settings, 'Central Market\\ARZCentral-settings')
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    style.WindowPadding = imgui.ImVec2(8, 8)
    style.WindowRounding = 6
    style.ChildWindowRounding = 5
    style.FramePadding = imgui.ImVec2(5, 3)
    style.FrameRounding = 3.0
    style.ItemSpacing = imgui.ImVec2(5, 4)
    style.ItemInnerSpacing = imgui.ImVec2(4, 4)
    style.IndentSpacing = 21
    style.ScrollbarSize = 15.0
    style.ScrollbarRounding = 13
    style.GrabMinSize = 8
    style.GrabRounding = 1
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

    imgui.GetStyle().WindowPadding = imgui.ImVec2(8, 8)
    imgui.GetStyle().WindowRounding = 16.0
    imgui.GetStyle().FramePadding = imgui.ImVec2(5, 3)
    imgui.GetStyle().ItemSpacing = imgui.ImVec2(4, 4)
    imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(5, 5)
    imgui.GetStyle().IndentSpacing = 9.0
    imgui.GetStyle().ScrollbarSize = 17.0
    imgui.GetStyle().ScrollbarRounding = 16.0
    imgui.GetStyle().GrabMinSize = 7.0
    imgui.GetStyle().GrabRounding = 6.0
    imgui.GetStyle().ChildWindowRounding = 6.0
    imgui.GetStyle().FrameRounding = 6.0
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    local ImVec2 = imgui.ImVec2
    colors[clr.Text]                 = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.TextDisabled]         = ImVec4(0.73, 0.75, 0.74, 1.00)
    colors[clr.WindowBg]             = ImVec4(0.00, 0.00, 0.00, 0.94)
    colors[clr.ChildWindowBg]        = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.PopupBg]              = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.Border]               = ImVec4(0.20, 0.20, 0.20, 0.50)
    colors[clr.BorderShadow]         = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.FrameBg]              = ImVec4(0.26, 0.37, 0.98, 0.54)
    colors[clr.FrameBgHovered]       = ImVec4(0.33, 0.33, 0.93, 0.40)
    colors[clr.FrameBgActive]        = ImVec4(0.44, 0.44, 0.99, 0.67)
    colors[clr.TitleBg]              = ImVec4(0.30, 0.33, 0.95, 0.67)
    colors[clr.TitleBgActive]        = ImVec4(0.00, 0.16, 1.00, 1.00)
    colors[clr.TitleBgCollapsed]     = ImVec4(0.22, 0.19, 1.00, 0.67)
    colors[clr.MenuBarBg]            = ImVec4(0.39, 0.56, 1.00, 1.00)
    colors[clr.ScrollbarBg]          = ImVec4(0.02, 0.02, 0.02, 0.53)
    colors[clr.ScrollbarGrab]        = ImVec4(0.31, 0.31, 0.31, 1.00)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.41, 0.41, 0.41, 1.00)
    colors[clr.ScrollbarGrabActive]  = ImVec4(0.51, 0.51, 0.51, 1.00)
    colors[clr.ComboBg]              = ImVec4(0.20, 0.20, 0.20, 0.99)
    colors[clr.CheckMark]            = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.SliderGrab]           = ImVec4(0.30, 0.41, 0.99, 1.00)
    colors[clr.SliderGrabActive]     = ImVec4(0.52, 0.52, 0.97, 1.00)
    colors[clr.Button]               = ImVec4(0.11, 0.13, 0.93, 0.65)
    colors[clr.ButtonHovered]        = ImVec4(0.41, 0.57, 1.00, 0.65)
    colors[clr.ButtonActive]         = ImVec4(0.20, 0.20, 0.20, 0.50)
    colors[clr.Header]               = ImVec4(0.15, 0.19, 1.00, 0.54)
    colors[clr.HeaderHovered]        = ImVec4(0.03, 0.24, 0.57, 0.65)
    colors[clr.HeaderActive]         = ImVec4(0.36, 0.40, 0.95, 0.00)
    colors[clr.Separator]            = ImVec4(0.43, 0.43, 0.50, 0.50)
    colors[clr.SeparatorHovered]     = ImVec4(0.20, 0.42, 0.98, 0.54)
    colors[clr.SeparatorActive]      = ImVec4(0.20, 0.40, 0.93, 0.54)
    colors[clr.ResizeGrip]           = ImVec4(0.01, 0.17, 1.00, 0.54)
    colors[clr.ResizeGripHovered]    = ImVec4(0.21, 0.51, 0.98, 0.45)
    colors[clr.ResizeGripActive]     = ImVec4(0.04, 0.55, 0.95, 0.66)
    colors[clr.CloseButton]          = ImVec4(0.41, 0.41, 0.41, 1.00)
    colors[clr.CloseButtonHovered]   = ImVec4(0.10, 0.21, 0.98, 1.00)
    colors[clr.CloseButtonActive]    = ImVec4(0.02, 0.26, 1.00, 1.00)
    colors[clr.PlotLines]            = ImVec4(0.61, 0.61, 0.61, 1.00)
    colors[clr.PlotLinesHovered]     = ImVec4(0.18, 0.15, 1.00, 1.00)
    colors[clr.PlotHistogram]        = ImVec4(0.90, 0.70, 0.00, 1.00)
    colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00)
    colors[clr.TextSelectedBg]       = ImVec4(0.26, 0.59, 0.98, 0.35)
    colors[clr.ModalWindowDarkening] = ImVec4(0.80, 0.80, 0.80, 0.35)
end

function setGreenStyle()
    settings.main.color, settings.main.colormsg,settings.main.stylemode = 'ADFF2F', 0xFFADFF2F, 5
    inicfg.save(settings, 'Central Market\\ARZCentral-settings')
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    style.WindowPadding = imgui.ImVec2(8, 8)
    style.WindowRounding = 6
    style.ChildWindowRounding = 5
    style.FramePadding = imgui.ImVec2(5, 3)
    style.FrameRounding = 3.0
    style.ItemSpacing = imgui.ImVec2(5, 4)
    style.ItemInnerSpacing = imgui.ImVec2(4, 4)
    style.IndentSpacing = 21
    style.ScrollbarSize = 15.0
    style.ScrollbarRounding = 13
    style.GrabMinSize = 8
    style.GrabRounding = 1
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

    imgui.GetStyle().WindowPadding = imgui.ImVec2(8, 8)
    imgui.GetStyle().WindowRounding = 16.0
    imgui.GetStyle().FramePadding = imgui.ImVec2(5, 3)
    imgui.GetStyle().ItemSpacing = imgui.ImVec2(4, 4)
    imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(5, 5)
    imgui.GetStyle().IndentSpacing = 9.0
    imgui.GetStyle().ScrollbarSize = 17.0
    imgui.GetStyle().ScrollbarRounding = 16.0
    imgui.GetStyle().GrabMinSize = 7.0
    imgui.GetStyle().GrabRounding = 6.0
    imgui.GetStyle().ChildWindowRounding = 6.0
    imgui.GetStyle().FrameRounding = 6.0
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    local ImVec2 = imgui.ImVec2
    colors[clr.Text]                 = ImVec4(1.00, 1.00, 1.00, 0.78)
            colors[clr.TextDisabled]         = ImVec4(0.36, 0.42, 0.47, 1.00)
            colors[clr.WindowBg]             = ImVec4(0.11, 0.15, 0.17, 1.00)
            colors[clr.ChildWindowBg]        = ImVec4(0.15, 0.18, 0.22, 1.00)
            colors[clr.PopupBg]              = ImVec4(0.08, 0.08, 0.08, 0.94)
            colors[clr.Border]               = ImVec4(0.43, 0.43, 0.50, 0.50)
            colors[clr.BorderShadow]         = ImVec4(0.00, 0.00, 0.00, 0.00)
            colors[clr.FrameBg]              = ImVec4(0.25, 0.29, 0.20, 1.00)
            colors[clr.FrameBgHovered]       = ImVec4(0.12, 0.20, 0.28, 1.00)
            colors[clr.FrameBgActive]        = ImVec4(0.09, 0.12, 0.14, 1.00)
            colors[clr.TitleBg]              = ImVec4(0.09, 0.12, 0.14, 0.65)
            colors[clr.TitleBgActive]        = ImVec4(0.35, 0.58, 0.06, 1.00)
            colors[clr.TitleBgCollapsed]     = ImVec4(0.00, 0.00, 0.00, 0.51)
            colors[clr.MenuBarBg]            = ImVec4(0.15, 0.18, 0.22, 1.00)
            colors[clr.ScrollbarBg]          = ImVec4(0.02, 0.02, 0.02, 0.39)
            colors[clr.ScrollbarGrab]        = ImVec4(0.20, 0.25, 0.29, 1.00)
            colors[clr.ScrollbarGrabHovered] = ImVec4(0.18, 0.22, 0.25, 1.00)
            colors[clr.ScrollbarGrabActive]  = ImVec4(0.09, 0.21, 0.31, 1.00)
            colors[clr.ComboBg]              = ImVec4(0.20, 0.25, 0.29, 1.00)
            colors[clr.CheckMark]            = ImVec4(0.72, 1.00, 0.28, 1.00)
            colors[clr.SliderGrab]           = ImVec4(0.43, 0.57, 0.05, 1.00)
            colors[clr.SliderGrabActive]     = ImVec4(0.55, 0.67, 0.15, 1.00)
            colors[clr.Button]               = ImVec4(0.40, 0.57, 0.01, 1.00)
            colors[clr.ButtonHovered]        = ImVec4(0.45, 0.69, 0.07, 1.00)
            colors[clr.ButtonActive]         = ImVec4(0.27, 0.50, 0.00, 1.00)
            colors[clr.Header]               = ImVec4(0.20, 0.25, 0.29, 0.55)
            colors[clr.HeaderHovered]        = ImVec4(0.72, 0.98, 0.26, 0.80)
            colors[clr.HeaderActive]         = ImVec4(0.74, 0.98, 0.26, 1.00)
            colors[clr.Separator]            = ImVec4(0.50, 0.50, 0.50, 1.00)
            colors[clr.SeparatorHovered]     = ImVec4(0.60, 0.60, 0.70, 1.00)
            colors[clr.SeparatorActive]      = ImVec4(0.70, 0.70, 0.90, 1.00)
            colors[clr.ResizeGrip]           = ImVec4(0.68, 0.98, 0.26, 0.25)
            colors[clr.ResizeGripHovered]    = ImVec4(0.72, 0.98, 0.26, 0.67)
            colors[clr.ResizeGripActive]     = ImVec4(0.06, 0.05, 0.07, 1.00)
            colors[clr.CloseButton]          = ImVec4(0.40, 0.39, 0.38, 0.16)
            colors[clr.CloseButtonHovered]   = ImVec4(0.40, 0.39, 0.38, 0.39)
            colors[clr.CloseButtonActive]    = ImVec4(0.40, 0.39, 0.38, 1.00)
            colors[clr.PlotLines]            = ImVec4(0.61, 0.61, 0.61, 1.00)
            colors[clr.PlotLinesHovered]     = ImVec4(1.00, 0.43, 0.35, 1.00)
            colors[clr.PlotHistogram]        = ImVec4(0.90, 0.70, 0.00, 1.00)
            colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00)
            colors[clr.TextSelectedBg]       = ImVec4(0.25, 1.00, 0.00, 0.43)
            colors[clr.ModalWindowDarkening] = ImVec4(1.00, 0.98, 0.95, 0.73)
end

function setPurpurStyle()
    settings.main.color, settings.main.colormsg,settings.main.stylemode = 'C71585', 0xFFC71585, 6
    inicfg.save(settings, 'Central Market\\ARZCentral-settings')
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    style.WindowPadding = imgui.ImVec2(8, 8)
    style.WindowRounding = 6
    style.ChildWindowRounding = 5
    style.FramePadding = imgui.ImVec2(5, 3)
    style.FrameRounding = 3.0
    style.ItemSpacing = imgui.ImVec2(5, 4)
    style.ItemInnerSpacing = imgui.ImVec2(4, 4)
    style.IndentSpacing = 21
    style.ScrollbarSize = 15.0
    style.ScrollbarRounding = 13
    style.GrabMinSize = 8
    style.GrabRounding = 1
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

    imgui.GetStyle().WindowPadding = imgui.ImVec2(8, 8)
    imgui.GetStyle().WindowRounding = 16.0
    imgui.GetStyle().FramePadding = imgui.ImVec2(5, 3)
    imgui.GetStyle().ItemSpacing = imgui.ImVec2(4, 4)
    imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(5, 5)
    imgui.GetStyle().IndentSpacing = 9.0
    imgui.GetStyle().ScrollbarSize = 17.0
    imgui.GetStyle().ScrollbarRounding = 16.0
    imgui.GetStyle().GrabMinSize = 7.0
    imgui.GetStyle().GrabRounding = 6.0
    imgui.GetStyle().ChildWindowRounding = 6.0
    imgui.GetStyle().FrameRounding = 6.0
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    local ImVec2 = imgui.ImVec2
    colors[clr.FrameBg]                = ImVec4(0.46, 0.11, 0.29, 1.00)
    colors[clr.FrameBgHovered]         = ImVec4(0.69, 0.16, 0.43, 1.00)
    colors[clr.FrameBgActive]          = ImVec4(0.58, 0.10, 0.35, 1.00)
    colors[clr.TitleBg]                = ImVec4(0.00, 0.00, 0.00, 1.00)
    colors[clr.TitleBgActive]          = ImVec4(0.61, 0.16, 0.39, 1.00)
    colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
    colors[clr.CheckMark]              = ImVec4(0.94, 0.30, 0.63, 1.00)
    colors[clr.SliderGrab]             = ImVec4(0.85, 0.11, 0.49, 1.00)
    colors[clr.SliderGrabActive]       = ImVec4(0.89, 0.24, 0.58, 1.00)
    colors[clr.Button]                 = ImVec4(0.46, 0.11, 0.29, 1.00)
    colors[clr.ButtonHovered]          = ImVec4(0.69, 0.17, 0.43, 1.00)
    colors[clr.ButtonActive]           = ImVec4(0.59, 0.10, 0.35, 1.00)
    colors[clr.Header]                 = ImVec4(0.46, 0.11, 0.29, 1.00)
    colors[clr.HeaderHovered]          = ImVec4(0.69, 0.16, 0.43, 1.00)
    colors[clr.HeaderActive]           = ImVec4(0.58, 0.10, 0.35, 1.00)
    colors[clr.Separator]              = ImVec4(0.69, 0.16, 0.43, 1.00)
    colors[clr.SeparatorHovered]       = ImVec4(0.58, 0.10, 0.35, 1.00)
    colors[clr.SeparatorActive]        = ImVec4(0.58, 0.10, 0.35, 1.00)
    colors[clr.ResizeGrip]             = ImVec4(0.46, 0.11, 0.29, 0.70)
    colors[clr.ResizeGripHovered]      = ImVec4(0.69, 0.16, 0.43, 0.67)
    colors[clr.ResizeGripActive]       = ImVec4(0.70, 0.13, 0.42, 1.00)
    colors[clr.TextSelectedBg]         = ImVec4(1.00, 0.78, 0.90, 0.35)
    colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.TextDisabled]           = ImVec4(0.60, 0.19, 0.40, 1.00)
    colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 0.94)
    colors[clr.ChildWindowBg]          = ImVec4(1.00, 1.00, 1.00, 0.00)
    colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.ComboBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.Border]                 = ImVec4(0.49, 0.14, 0.31, 1.00)
    colors[clr.BorderShadow]           = ImVec4(0.49, 0.14, 0.31, 0.00)
    colors[clr.MenuBarBg]              = ImVec4(0.15, 0.15, 0.15, 1.00)
    colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
    colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
    colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
    colors[clr.CloseButton]            = ImVec4(0.41, 0.41, 0.41, 0.50)
    colors[clr.CloseButtonHovered]     = ImVec4(0.98, 0.39, 0.36, 1.00)
    colors[clr.CloseButtonActive]      = ImVec4(0.98, 0.39, 0.36, 1.00)
    colors[clr.ModalWindowDarkening]   = ImVec4(0.80, 0.80, 0.80, 0.35)
end

function setRedStyle()
    settings.main.color, settings.main.colormsg,settings.main.stylemode = 'B22222', 0xFFB22222,7
    inicfg.save(settings, 'Central Market\\ARZCentral-settings')
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    style.WindowPadding = imgui.ImVec2(8, 8)
    style.WindowRounding = 6
    style.ChildWindowRounding = 5
    style.FramePadding = imgui.ImVec2(5, 3)
    style.FrameRounding = 3.0
    style.ItemSpacing = imgui.ImVec2(5, 4)
    style.ItemInnerSpacing = imgui.ImVec2(4, 4)
    style.IndentSpacing = 21
    style.ScrollbarSize = 15.0
    style.ScrollbarRounding = 13
    style.GrabMinSize = 8
    style.GrabRounding = 1
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

    imgui.GetStyle().WindowPadding = imgui.ImVec2(8, 8)
    imgui.GetStyle().WindowRounding = 16.0
    imgui.GetStyle().FramePadding = imgui.ImVec2(5, 3)
    imgui.GetStyle().ItemSpacing = imgui.ImVec2(4, 4)
    imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(5, 5)
    imgui.GetStyle().IndentSpacing = 9.0
    imgui.GetStyle().ScrollbarSize = 17.0
    imgui.GetStyle().ScrollbarRounding = 16.0
    imgui.GetStyle().GrabMinSize = 7.0
    imgui.GetStyle().GrabRounding = 6.0
    imgui.GetStyle().ChildWindowRounding = 6.0
    imgui.GetStyle().FrameRounding = 6.0
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    local ImVec2 = imgui.ImVec2
    colors[clr.Text]                 = ImVec4(1.00, 1.00, 1.00, 0.78)
            colors[clr.TextDisabled]         = ImVec4(1.00, 1.00, 1.00, 1.00)
            colors[clr.WindowBg]             = ImVec4(0.11, 0.15, 0.17, 1.00)
            colors[clr.ChildWindowBg]        = ImVec4(0.15, 0.18, 0.22, 1.00)
            colors[clr.PopupBg]              = ImVec4(0.08, 0.08, 0.08, 0.94)
            colors[clr.Border]               = ImVec4(0.43, 0.43, 0.50, 0.50)
            colors[clr.BorderShadow]         = ImVec4(0.00, 0.00, 0.00, 0.00)
            colors[clr.FrameBg]              = ImVec4(0.20, 0.25, 0.29, 1.00)
            colors[clr.FrameBgHovered]       = ImVec4(0.12, 0.20, 0.28, 1.00)
            colors[clr.FrameBgActive]        = ImVec4(0.09, 0.12, 0.14, 1.00)
            colors[clr.TitleBg]              = ImVec4(0.53, 0.20, 0.16, 0.65)
            colors[clr.TitleBgActive]        = ImVec4(0.56, 0.14, 0.14, 1.00)
            colors[clr.TitleBgCollapsed]     = ImVec4(0.00, 0.00, 0.00, 0.51)
            colors[clr.MenuBarBg]            = ImVec4(0.15, 0.18, 0.22, 1.00)
            colors[clr.ScrollbarBg]          = ImVec4(0.02, 0.02, 0.02, 0.39)
            colors[clr.ScrollbarGrab]        = ImVec4(0.20, 0.25, 0.29, 1.00)
            colors[clr.ScrollbarGrabHovered] = ImVec4(0.18, 0.22, 0.25, 1.00)
            colors[clr.ScrollbarGrabActive]  = ImVec4(0.09, 0.21, 0.31, 1.00)
            colors[clr.ComboBg]              = ImVec4(0.20, 0.25, 0.29, 1.00)
            colors[clr.CheckMark]            = ImVec4(1.00, 0.28, 0.28, 1.00)
            colors[clr.SliderGrab]           = ImVec4(0.64, 0.14, 0.14, 1.00)
            colors[clr.SliderGrabActive]     = ImVec4(1.00, 0.37, 0.37, 1.00)
            colors[clr.Button]               = ImVec4(0.59, 0.13, 0.13, 1.00)
            colors[clr.ButtonHovered]        = ImVec4(0.69, 0.15, 0.15, 1.00)
            colors[clr.ButtonActive]         = ImVec4(0.67, 0.13, 0.07, 1.00)
            colors[clr.Header]               = ImVec4(0.20, 0.25, 0.29, 0.55)
            colors[clr.HeaderHovered]        = ImVec4(0.98, 0.38, 0.26, 0.80)
            colors[clr.HeaderActive]         = ImVec4(0.98, 0.26, 0.26, 1.00)
            colors[clr.Separator]            = ImVec4(0.50, 0.50, 0.50, 1.00)
            colors[clr.SeparatorHovered]     = ImVec4(0.60, 0.60, 0.70, 1.00)
            colors[clr.SeparatorActive]      = ImVec4(0.70, 0.70, 0.90, 1.00)
            colors[clr.ResizeGrip]           = ImVec4(0.26, 0.59, 0.98, 0.25)
            colors[clr.ResizeGripHovered]    = ImVec4(0.26, 0.59, 0.98, 0.67)
            colors[clr.ResizeGripActive]     = ImVec4(0.06, 0.05, 0.07, 1.00)
            colors[clr.CloseButton]          = ImVec4(0.40, 0.39, 0.38, 0.16)
            colors[clr.CloseButtonHovered]   = ImVec4(0.40, 0.39, 0.38, 0.39)
            colors[clr.CloseButtonActive]    = ImVec4(0.40, 0.39, 0.38, 1.00)
            colors[clr.PlotLines]            = ImVec4(0.61, 0.61, 0.61, 1.00)
            colors[clr.PlotLinesHovered]     = ImVec4(1.00, 0.43, 0.35, 1.00)
            colors[clr.PlotHistogram]        = ImVec4(0.90, 0.70, 0.00, 1.00)
            colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00)
            colors[clr.TextSelectedBg]       = ImVec4(0.25, 1.00, 0.00, 0.43)
            colors[clr.ModalWindowDarkening] = ImVec4(1.00, 0.98, 0.95, 0.73)
end

function setYellowStyle()
    settings.main.color, settings.main.colormsg,settings.main.stylemode = 'FFFF00', 0xFFFFFF00, 8
    inicfg.save(settings, 'Central Market\\ARZCentral-settings')
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    style.WindowPadding = imgui.ImVec2(8, 8)
    style.WindowRounding = 6
    style.ChildWindowRounding = 5
    style.FramePadding = imgui.ImVec2(5, 3)
    style.FrameRounding = 3.0
    style.ItemSpacing = imgui.ImVec2(5, 4)
    style.ItemInnerSpacing = imgui.ImVec2(4, 4)
    style.IndentSpacing = 21
    style.ScrollbarSize = 15.0
    style.ScrollbarRounding = 13
    style.GrabMinSize = 8
    style.GrabRounding = 1
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

    imgui.GetStyle().WindowPadding = imgui.ImVec2(8, 8)
    imgui.GetStyle().WindowRounding = 16.0
    imgui.GetStyle().FramePadding = imgui.ImVec2(5, 3)
    imgui.GetStyle().ItemSpacing = imgui.ImVec2(4, 4)
    imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(5, 5)
    imgui.GetStyle().IndentSpacing = 9.0
    imgui.GetStyle().ScrollbarSize = 17.0
    imgui.GetStyle().ScrollbarRounding = 16.0
    imgui.GetStyle().GrabMinSize = 7.0
    imgui.GetStyle().GrabRounding = 6.0
    imgui.GetStyle().ChildWindowRounding = 6.0
    imgui.GetStyle().FrameRounding = 6.0
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    local ImVec2 = imgui.ImVec2
    colors[clr.FrameBg]                = ImVec4(0.76, 0.6, 0, 0.74)--
    colors[clr.FrameBgHovered]         = ImVec4(0.84, 0.68, 0, 0.83)--
    colors[clr.FrameBgActive]          = ImVec4(0.92, 0.77, 0, 0.87)--
    colors[clr.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)--
    colors[clr.TitleBgActive]          = ImVec4(0.92, 0.77, 0, 0.85)--
    colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)--
    colors[clr.CheckMark]              = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.SliderGrab]             = ImVec4(0.84, 0.68, 0, 1.00)
    colors[clr.SliderGrabActive]       = ImVec4(0.92, 0.77, 0, 1.00)
    colors[clr.Button]                 = ImVec4(0.76, 0.6, 0, 0.85)
    colors[clr.ButtonHovered]          = ImVec4(0.84, 0.68, 0, 1.00)
    colors[clr.ButtonActive]           = ImVec4(0.92, 0.77, 0, 1.00)
    colors[clr.Header]                 = ImVec4(0.84, 0.68, 0, 0.75)
    colors[clr.HeaderHovered]          = ImVec4(0.84, 0.68, 0, 0.90)
    colors[clr.HeaderActive]           = ImVec4(0.92, 0.77, 0, 1.00)
    colors[clr.Separator]              = colors[clr.Border]
    colors[clr.SeparatorHovered]       = ImVec4(0.84, 0.68, 0, 0.78)
    colors[clr.SeparatorActive]        = ImVec4(0.84, 0.68, 0, 1.00)
    colors[clr.ResizeGrip]             = ImVec4(0.76, 0.6, 0, 0.25)
    colors[clr.ResizeGripHovered]      = ImVec4(0.84, 0.68, 0, 0.67)
    colors[clr.ResizeGripActive]       = ImVec4(0.92, 0.77, 0, 0.95)
    colors[clr.TextSelectedBg]         = ImVec4(0.52, 0.34, 0, 0.85)
    colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
    colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 0.94)
    colors[clr.ChildWindowBg]          = ImVec4(1.00, 1.00, 1.00, 0.00)
    colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.ComboBg]                = colors[clr.PopupBg]
    colors[clr.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.50)
    colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
    colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
    colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
    colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
    colors[clr.CloseButton]            = ImVec4(0.41, 0.41, 0.41, 0.50)
    colors[clr.CloseButtonHovered]     = ImVec4(0.98, 0.39, 0.36, 1.00)
    colors[clr.CloseButtonActive]      = ImVec4(0.98, 0.39, 0.36, 1.00)
    colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
    colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
    colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
    colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
    colors[clr.ModalWindowDarkening]   = ImVec4(0.80, 0.80, 0.80, 0.35)
end

if settings.main.stylemode == 0 then
    setDarkStyle()
elseif settings.main.stylemode == 1 then 
    setPurpleStyle()
elseif settings.main.stylemode == 2 then
    setBlueGraytheme()
elseif settings.main.stylemode == 3 then
    setOrangeStyle()
elseif settings.main.stylemode == 4 then
    setBlueBlackStyle()
elseif settings.main.stylemode == 5 then
    setGreenStyle()
elseif settings.main.stylemode == 6 then
    setPurpurStyle()
elseif settings.main.stylemode == 7 then
    setRedStyle()
elseif settings.main.stylemode == 8 then
    setYellowStyle()
end 

local russian_characters = {
    [168] = 'Ё', [184] = 'ё', [192] = 'А', [193] = 'Б', [194] = 'В', [195] = 'Г', [196] = 'Д', [197] = 'Е', [198] = 'Ж', [199] = 'З', [200] = 'И', [201] = 'Й', [202] = 'К', [203] = 'Л', [204] = 'М', [205] = 'Н', [206] = 'О', [207] = 'П', [208] = 'Р', [209] = 'С', [210] = 'Т', [211] = 'У', [212] = 'Ф', [213] = 'Х', [214] = 'Ц', [215] = 'Ч', [216] = 'Ш', [217] = 'Щ', [218] = 'Ъ', [219] = 'Ы', [220] = 'Ь', [221] = 'Э', [222] = 'Ю', [223] = 'Я', [224] = 'а', [225] = 'б', [226] = 'в', [227] = 'г', [228] = 'д', [229] = 'е', [230] = 'ж', [231] = 'з', [232] = 'и', [233] = 'й', [234] = 'к', [235] = 'л', [236] = 'м', [237] = 'н', [238] = 'о', [239] = 'п', [240] = 'р', [241] = 'с', [242] = 'т', [243] = 'у', [244] = 'ф', [245] = 'х', [246] = 'ц', [247] = 'ч', [248] = 'ш', [249] = 'щ', [250] = 'ъ', [251] = 'ы', [252] = 'ь', [253] = 'э', [254] = 'ю', [255] = 'я',
}
function string.rlower(s)
    s = s:lower()
    local strlen = s:len()
    if strlen == 0 then return s end
    s = s:lower()
    local output = ''
    for i = 1, strlen do
        local ch = s:byte(i)
        if ch >= 192 and ch <= 223 then -- upper russian characters
            output = output .. russian_characters[ch + 32]
        elseif ch == 168 then -- Ё
            output = output .. russian_characters[184]
        else
            output = output .. string.char(ch)
        end
    end
    return output
end
function string.rupper(s)
    s = s:upper()
    local strlen = s:len()
    if strlen == 0 then return s end
    s = s:upper()
    local output = ''
    for i = 1, strlen do
        local ch = s:byte(i)
        if ch >= 224 and ch <= 255 then -- lower russian characters
            output = output .. russian_characters[ch - 32]
        elseif ch == 184 then -- ё
            output = output .. russian_characters[168]
        else
            output = output .. string.char(ch)
        end
    end
    return output
end

function jsonSave(jsonFilePath, t)
    file = io.open(jsonFilePath, "w")
    file:write(encodeJson(t))
    file:flush()
    file:close()
  end
  
  function jsonRead(jsonFilePath)
    
    if not doesFileExist(jsonFilePath) then
      return nil
    end

    local file = io.open(jsonFilePath, "r+")
    local jsonInString = file:read("*a")
    file:close()
    local jsonTable = decodeJson(jsonInString)
    return jsonTable
  end

  function check_table(arg, table)
    for k, v in pairs(table) do
        if table[k][1] == arg then
            return true
        else
        end
    end
end

function check_index(arg, table)
    for k, v in pairs(table) do
        if table[k][1] == arg then
            index = k
            return index
        end
    end
end

function imgui.ButtonClickable(clickable, ...)
    if clickable then
        return imgui.Button(...)

    else
        local r, g, b, a = imgui.ImColor(imgui.GetStyle().Colors[imgui.Col.Button]):GetFloat4()
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(r, g, b, a/2) )
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(r, g, b, a/2))
        imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(r, g, b, a/2))
        imgui.PushStyleColor(imgui.Col.Text, imgui.GetStyle().Colors[imgui.Col.TextDisabled])
        imgui.Button(...)
        imgui.PopStyleColor()
        imgui.PopStyleColor()
        imgui.PopStyleColor()
        imgui.PopStyleColor()
    end
end

function onWindowMessage(msg, wparam, lparam)
    if msg == 0x100 or msg == 0x101 then
        if (wparam == key.VK_ESCAPE and allWindow.v) and not isPauseMenuActive() then
            consumeWindowMessage(true, false)
            if msg == 0x101 then
                allWindow.v = false
            end
        end
    end
end