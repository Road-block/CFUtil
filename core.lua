local ADDON, NAME = {}, "CFUtil"
ADDON.hooks = {}
ADDON.msgBfr = {}
local _G = getfenv(0)
local f = CreateFrame("Frame")
local help,debugframe,copyframe,tabClickHook,flash
f.OnEvent = function(event,...)
  return f[event]~=nil and f[event](unpack(arg))
end
f:SetScript("OnEvent", function(...) f.OnEvent(event,unpack(arg)) end)
f:RegisterEvent("VARIABLES_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f.PLAYER_LOGIN = function(...)
  local frame = debugframe()
  if frame ~= nil then
    local name, fontSize, r, g, b, a, shown, locked = GetChatWindowInfo(frame:GetID())
    if (not shown and not frame.isDocked) then
      FCF_OpenNewWindow(name)
    end
  else
    FCF_OpenNewWindow("Debug")
    frame = debugframe()
  end
end
f.VARIABLES_LOADED = function(...)
  CFUtilDB = (CFUtilDB~=nil) and CFUtilDB or {filter=true}
  CFUtilDB.debug = {}
  ADDON.setupHooks()
  if _G.Print==nil then 
    _G.Print = function(...)
      local printf = function(f)
        if not DEFAULT_CHAT_FRAME:IsVisible() then
          FCF_SelectDockFrame(DEFAULT_CHAT_FRAME)
        end
        local out = "|cff9664c8CFUtil:|r "..f
        DEFAULT_CHAT_FRAME:AddMessage(out)
      end 
      for i,a in ipairs(arg) do
        if type(a)=="table" then
          for k,v in pairs(a) do
            printf(k..":"..tostring(v))
          end
        elseif type(a)=="function" then
          printf(tostring(a()))
        else
          printf(tostring(a))
        end
      end
    end 
  end
end
ADDON.setupHooks = function()
  do
    ADDON.systemId = GetChatTypeIndex("SYSTEM") or 11
    ADDON.copyFrame = copyframe()
    --[[ADDON.hooks.SendChatMessage = SendChatMessage
    ADDON.SendChatMessage = function(msg,chatType,lang,chan)
      CFUtilDB.chathistory = (CFUtilDB.chathistory~=nil) and CFUtilDB.chathistory or {}
      -- table.insert(CFUtilDB.chathistory,{msg,chatType,lang,chan})
      ADDON.hooks.SendChatMessage(msg,chatType,lang,chan)
    end
    SendChatMessage = ADDON.SendChatMessage]]
    ADDON.hooks.AddMessage = DEFAULT_CHAT_FRAME.AddMessage
    ADDON.AddMessage = function(DEFAULT_CHAT_FRAME,msg,r,g,b,id)
      CFUtilDB.chathistory = (CFUtilDB.chathistory~=nil) and CFUtilDB.chathistory or {}
      -- table.insert(CFUtilDB.chathistory,{msg,r,g,b,id})
      if id ~= nil and id == ADDON.systemId then
        if not CFUtilDB.filter then
          ADDON.hooks.AddMessage(DEFAULT_CHAT_FRAME,msg,r,g,b,id)
        end
        local frame = debugframe()
        if frame~=nil then
          local name, fontSize, r, g, b, a, shown, locked = GetChatWindowInfo(frame:GetID())
          if (shown or frame.isDocked) then
            ChatFrame_RemoveAllMessageGroups(frame) 
            frame:AddMessage(msg,r,g,b,id)
            flash(frame)
          end
        end
        table.insert(ADDON.msgBfr,msg)
      else
        ADDON.hooks.AddMessage(DEFAULT_CHAT_FRAME,msg,r,g,b,id)
      end
    end
    DEFAULT_CHAT_FRAME.AddMessage = ADDON.AddMessage
    ADDON.hooks.FCF_SetWindowName = FCF_SetWindowName
    ADDON.FCF_SetWindowName = function(frame, name, doNotSave)
      if string.lower(name) == "debug" then
        local tab = getglobal(frame:GetName().."Tab")
        tabClickHook(tab)
        ChatFrame_RemoveAllMessageGroups(frame)
        frame:SetMaxLines(1024)
        ADDON.debugFrame = frame
      end
      ADDON.hooks.FCF_SetWindowName(frame, name, doNotSave)
    end
    FCF_SetWindowName = ADDON.FCF_SetWindowName
  end
end
flash = function(frame)
  local tabFlash = getglobal(frame:GetName().."TabFlash");
  if ( not frame.isDocked or (frame == SELECTED_DOCK_FRAME) or UIFrameIsFlashing(tabFlash) ) then
    return
  end
  tabFlash:Show();
  UIFrameFlash(tabFlash, 0.25, 0.25, 60, nil, 0.5, 0.5);
end
tabClickHook = function(tab)
  local clickFunc = tab:GetScript("OnClick")
  if tab.hasCustom == nil and type(clickFunc) == "function" then
    tab.hasCustom = true
    tab:SetScript("OnClick",function() 
        if IsShiftKeyDown() then 
          ADDON.copyFrame.AddSelectText(table.concat(ADDON.msgBfr,"\n"))
          if ADDON.debugFrame:IsVisible() then
            ADDON.copyFrame:ClearAllPoints()
            ADDON.copyFrame:SetAllPoints(ADDON.debugFrame)
          end
          ADDON.copyFrame:Show()
        end 
        clickFunc(this,arg1,arg2)
      end)
  end
end
debugframe = function()
  if ADDON.debugFrame ~= nil then return ADDON.debugFrame end
  for i=1,NUM_CHAT_WINDOWS do
    local tab = getglobal("ChatFrame"..i.."Tab")
    local cf = getglobal("ChatFrame"..i)
    local tabName = tab:GetText()
    if tab ~= nil and (string.lower(tabName) == "debug") then
      tabClickHook(tab)
      ADDON.debugFrame = cf
      ChatFrame_RemoveAllMessageGroups(ADDON.debugFrame)
      ADDON.debugFrame:SetMaxLines(1024)
      return ADDON.debugFrame
    end
  end
end
copyframe = function()
  local cf = CreateFrame("Frame", NAME.."ChatCopyFrame", UIParent)
  cf:SetWidth(500)
  cf:SetHeight(400)
  cf:SetPoint('CENTER', UIParent, 'CENTER', 0,0)
  cf:SetFrameStrata('DIALOG')
  cf:Hide()
  cf:SetBackdrop({
    bgFile = [[Interface\Buttons\WHITE8x8]],
    insets = {left = 3, right = 3, top = 4, bottom = 3
  }})
  cf:SetBackdropColor(0, 0, 0, 0.7)
  local cfb = CreateFrame("EditBox", NAME.."ChatCopyFrameEdit", cf)
  cfb:SetMultiLine(true)
  cfb:SetAutoFocus(true)
  cfb:EnableMouse(true)
  cfb:SetMaxLetters(99999)
  cfb:SetHistoryLines(1)
  cfb:SetFont('Fonts\\ARIALN.ttf', 12, 'THINOUTLINE')
  cfb:SetWidth(590)
  cfb:SetHeight(590)
  cfb:SetScript("OnEscapePressed", function() 
      cfb:SetText("")
      cf:Hide() 
    end)
  cf.editBox = cfb
  cf.AddSelectText = function(txt)
    cf.editBox:SetText(txt)
    cf.editBox:HighlightText(--[[0,cf.editBox:GetNumLetters()]])
  end
  local scrl = CreateFrame("ScrollFrame", NAME.."ChatCopyFrameScroll", cf, 'UIPanelScrollFrameTemplate')
  scrl:SetPoint('TOPLEFT', cf, 'TOPLEFT', 8, -30)
  scrl:SetPoint('BOTTOMRIGHT', cf, 'BOTTOMRIGHT', -30, 8)
  scrl:SetScrollChild(cfb)
  return cf
end
help = function()
  Print("Create a new chatwindow and name it \"Debug\" (case insensitive) if it wasn't automatically created")
  Print("  Shift-Click the chatframe Tab to open a copy frame. Esc to close it.")
  Print("  ")
  Print("Cmd-line Options")
  Print("/cfutil filter")
  Print("  toggles hiding system messages from main frame")
  Print("/cfutil clear")
  Print("  clears the debug frame and the copy frame buffer")
  Print("/cls")
  Print("  clears all chat windows and the copy frame buffer")
  Print("/print <any>")
  Print("  prints any arguments following to default chat")
end
SlashCmdList["CFUTIL"] = function(msg)
  if msg == nil or msg == "" then
    help()
  else
    local args = {}
    for arg in string.gfind(msg,"%S+") do
      table.insert(args,arg)
    end
    local argn = table.getn(args)
    if string.lower(msg) == "filter" then
      CFUtilDB.filter = not CFUtilDB.filter
      local status = CFUtilDB.filter and "|cff00ff00ON|r" or "|cffff0000OFF"
      Print("Filtering system messsages from main frame: "..status)
    elseif string.lower(msg) == "clear" then
      if ADDON.debugFrame ~= nil then
        ADDON.debugFrame:Clear()
      end
      ADDON.msgBfr = {}
    else
      help()
    end
  end
end
if type(SlashCmdList["PRINT"])=="nil" then
  SlashCmdList["PRINT"] = function(text)
    RunScript("local func=function(...) Print(unpack(arg)) end func("..text..")")
  end
  SLASH_PRINT1 = "/print"
end
if type(SlashCmdList["CLS"])=="nil" then
  SlashCmdList["CLS"] = function()
    for i=1,NUM_CHAT_WINDOWS do
      getglobal("ChatFrame"..i):Clear()
    end
    ADDON.msgBfr = {}
  end  
  SLASH_CLS1 = "/cls"
end
SLASH_CFUTIL1 = "/cfutil"
_G[NAME] = ADDON
