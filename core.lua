local ADDON, NAME = {}, "CFUtil"
ADDON.hooks = {}
local _G = getfenv(0)
local f = CreateFrame("Frame")
local help,debugframe
f.OnEvent = function(event,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20)
  return f[event]~=nil and f[event](a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20)
end
f:SetScript("OnEvent", function() f.OnEvent(event,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20) end)
f:RegisterEvent("VARIABLES_LOADED")
f.VARIABLES_LOADED = function()
  CFUtilDB = (CFUtilDB~=nil) and CFUtilDB or {filter=true}
  ADDON.setupHooks()
  if _G.Print==nil then 
    _G.Print = function(msg) 
      if not DEFAULT_CHAT_FRAME:IsVisible() then
        FCF_SelectDockFrame(DEFAULT_CHAT_FRAME)
      end
      local out = "|cff9664c8CFUtil:|r "..tostring(msg)
      DEFAULT_CHAT_FRAME:AddMessage(out)
    end 
  end
end
ADDON.setupHooks = function()
  do
    ADDON.systemId = GetChatTypeIndex("SYSTEM") or 11
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
          ChatFrame_RemoveAllMessageGroups(frame) 
          frame:AddMessage(msg,r,g,b,id) 
        end
      else
        ADDON.hooks.AddMessage(DEFAULT_CHAT_FRAME,msg,r,g,b,id)
      end
    end
    DEFAULT_CHAT_FRAME.AddMessage = ADDON.AddMessage
    ADDON.hooks.FCF_SetWindowName = FCF_SetWindowName
    ADDON.FCF_SetWindowName = function(frame, name, doNotSave)
      if string.lower(name) == "debug" then
        ChatFrame_RemoveAllMessageGroups(frame)
        ADDON.debugFrame = frame
      end
      ADDON.hooks.FCF_SetWindowName(frame, name, doNotSave)
    end
    FCF_SetWindowName = ADDON.FCF_SetWindowName
  end
end
debugframe = function()
  if ADDON.debugFrame ~= nil then return ADDON.debugFrame end
  for i=1,NUM_CHAT_WINDOWS do
    local tab = getglobal("ChatFrame"..i.."Tab")
    local tabName = tab:GetText()
    if tab ~= nil and (string.lower(tabName) == "debug") then
      ADDON.debugFrame = getglobal("ChatFrame"..i)
      ChatFrame_RemoveAllMessageGroups(ADDON.debugFrame)
      return ADDON.debugFrame
    end
  end
end
help = function()
  Print("Create a new chatwindow and name it Debug (case insensitive) to show system messages")
  Print("  ")
  Print("Options")
  Print("/cfutil filter")
  Print("  toggles hiding system messages from main frame")
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
    else
      help()
    end
  end
end
SLASH_CFUTIL1 = "/cfutil"
_G[NAME] = ADDON
