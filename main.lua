-- =========================================================
-- FS22 Tax Mod (version 1.1.0.2)
-- =========================================================
-- Daily tax deductions with monthly returns
-- =========================================================
-- Author: TisonK
-- Im new to modding, so be gentle :)
-- If you like my work, consider looking at my other mods!
-- =========================================================
-- COPYRIGHT NOTICE:
-- All rights reserved. Unauthorized redistribution, copying,
-- or claiming this code as your own is strictly prohibited.
-- Original author: [TisonK]
-- =========================================================

TaxMod = {}
TaxMod.modName = "FS22_TaxMod"
TaxMod.settings = {}
TaxMod.hasRegisteredSettings = false
TaxMod.version = "1.1.0.2"

-- =====================
-- DEFAULT CONFIGURATION
-- =====================
TaxMod.DEFAULT_CONFIG = {
    enabled = true,
    taxRate = "medium",     
    returnPercentage = 20,   
    minimumBalance = 1000, 
    showNotification = true,
    showStatistics = true,
    debugMode = true
}

TaxMod.TAX_RATE_VALUES = {
    low = 0.01,      -- 1%
    medium = 0.02,   -- 2%
    high = 0.03      -- 3%
}

-- =====================
-- TAX STATISTICS
-- =====================
TaxMod.stats = {
    totalTaxesPaid = 0,
    totalTaxesReturned = 0,
    taxesThisMonth = 0,
    daysTaxed = 0,
    monthsReturned = 0
}

-- =====================
-- INTERNAL STATE
-- =====================
TaxMod.lastDay = -1
TaxMod.lastMonth = -1
TaxMod.isLoaded = false
TaxMod.welcomeBannerTimer = nil
TaxMod.welcomeMessageTimer = nil
TaxMod.settingsRetryTimer = nil

-- =====================
-- UTILITY FUNCTIONS
-- =====================
function TaxMod:log(msg)
    if self.settings.debugMode then
        print("[" .. self.modName .. "] " .. tostring(msg))
    end
end

function TaxMod:printBanner()
    self:log("===================================")
    self:log("Tax Mod")
    self:log("Version: " .. self.version)
    self:log("Author: TisonK")
    self:log("Tax Rate: " .. self.settings.taxRate)
    self:log("Return %: " .. self.settings.returnPercentage .. "%")
    self:log("Enabled: " .. tostring(self.settings.enabled))
    self:log("===================================")
end

function TaxMod:isServer()
    return g_currentMission ~= nil and g_currentMission:getIsServer()
end

function TaxMod:getTaxRate()
    return TaxMod.TAX_RATE_VALUES[self.settings.taxRate] or 0.02
end

function TaxMod:copyTable(t)
    local result = {}
    for k, v in pairs(t) do
        result[k] = v
    end
    return result
end

function TaxMod:formatMoney(amount)
    if g_i18n and g_i18n.formatMoney then
        return g_i18n:formatMoney(amount, 0, true, true)
    end
    return "€" .. tostring(amount)
end

-- =====================
-- SETTINGS SYSTEM
-- =====================
function TaxMod:getSettingsFilePath()
    local baseDir = getUserProfileAppPath() .. "modSettings"
    local modDir  = baseDir .. "/FS22_TaxMod"

    createFolder(baseDir)
    createFolder(modDir)

    return modDir .. "/settings.xml"
end

function TaxMod:loadSettingsFromXML()
    local filePath = self:getSettingsFilePath()
    local xmlFile = loadXMLFile("settings", filePath)
    
    if xmlFile ~= 0 then
        self.settings.enabled = Utils.getNoNil(getXMLBool(xmlFile, "FS22_TaxMod.enabled"), self.DEFAULT_CONFIG.enabled)
        self.settings.taxRate = Utils.getNoNil(getXMLString(xmlFile, "FS22_TaxMod.taxRate"), self.DEFAULT_CONFIG.taxRate)
        self.settings.returnPercentage = Utils.getNoNil(getXMLInt(xmlFile, "FS22_TaxMod.returnPercentage"), self.DEFAULT_CONFIG.returnPercentage)
        self.settings.minimumBalance = Utils.getNoNil(getXMLInt(xmlFile, "FS22_TaxMod.minimumBalance"), self.DEFAULT_CONFIG.minimumBalance)
        self.settings.showNotification = Utils.getNoNil(getXMLBool(xmlFile, "FS22_TaxMod.showNotification"), self.DEFAULT_CONFIG.showNotification)
        self.settings.showStatistics = Utils.getNoNil(getXMLBool(xmlFile, "FS22_TaxMod.showStatistics"), self.DEFAULT_CONFIG.showStatistics)
        self.settings.debugMode = Utils.getNoNil(getXMLBool(xmlFile, "FS22_TaxMod.debugMode"), self.DEFAULT_CONFIG.debugMode)
        
        -- Load statistics
        self.stats.totalTaxesPaid = Utils.getNoNil(getXMLInt(xmlFile, "FS22_TaxMod.stats.totalTaxesPaid"), 0)
        self.stats.totalTaxesReturned = Utils.getNoNil(getXMLInt(xmlFile, "FS22_TaxMod.stats.totalTaxesReturned"), 0)
        self.stats.taxesThisMonth = Utils.getNoNil(getXMLInt(xmlFile, "FS22_TaxMod.stats.taxesThisMonth"), 0)
        self.stats.daysTaxed = Utils.getNoNil(getXMLInt(xmlFile, "FS22_TaxMod.stats.daysTaxed"), 0)
        self.stats.monthsReturned = Utils.getNoNil(getXMLInt(xmlFile, "FS22_TaxMod.stats.monthsReturned"), 0)
        
        delete(xmlFile)
        self:log("[Tax Mod] Settings loaded from XML: " .. filePath)
    else
        self.settings = self:copyTable(self.DEFAULT_CONFIG)
        self.stats = {
            totalTaxesPaid = 0,
            totalTaxesReturned = 0,
            taxesThisMonth = 0,
            daysTaxed = 0,
            monthsReturned = 0
        }
        self:log("[Tax Mod] Using default settings")
        self:saveSettingsToXML()
    end
end

function TaxMod:saveSettingsToXML()
    local filePath = self:getSettingsFilePath()
    local xmlFile = createXMLFile("settings", filePath, "FS22_TaxMod")
    
    if xmlFile ~= 0 then
        setXMLBool(xmlFile, "FS22_TaxMod.enabled", self.settings.enabled)
        setXMLString(xmlFile, "FS22_TaxMod.taxRate", self.settings.taxRate)
        setXMLInt(xmlFile, "FS22_TaxMod.returnPercentage", self.settings.returnPercentage)
        setXMLInt(xmlFile, "FS22_TaxMod.minimumBalance", self.settings.minimumBalance)
        setXMLBool(xmlFile, "FS22_TaxMod.showNotification", self.settings.showNotification)
        setXMLBool(xmlFile, "FS22_TaxMod.showStatistics", self.settings.showStatistics)
        setXMLBool(xmlFile, "FS22_TaxMod.debugMode", self.settings.debugMode)
        
        -- Save statistics
        setXMLInt(xmlFile, "FS22_TaxMod.stats.totalTaxesPaid", self.stats.totalTaxesPaid)
        setXMLInt(xmlFile, "FS22_TaxMod.stats.totalTaxesReturned", self.stats.totalTaxesReturned)
        setXMLInt(xmlFile, "FS22_TaxMod.stats.taxesThisMonth", self.stats.taxesThisMonth)
        setXMLInt(xmlFile, "FS22_TaxMod.stats.daysTaxed", self.stats.daysTaxed)
        setXMLInt(xmlFile, "FS22_TaxMod.stats.monthsReturned", self.stats.monthsReturned)
        
        saveXMLFile(xmlFile)
        delete(xmlFile)
        self:log("[Tax Mod] Settings saved to XML: " .. filePath)
    else
        self:log("Failed to create XML file: " .. filePath)
    end
end

-- =====================
-- MOD LIFECYCLE
-- =====================
function TaxMod:loadMap()
    if g_currentMission == nil or self.isLoaded then return end

    self:loadSettingsFromXML()
    self.lastDay = g_currentMission.environment.currentDay
    self.lastMonth = g_currentMission.environment.currentMonth


    -- ⏱️ Info-notificatie na 60 seconden
    if self.settings.enabled and self.settings.showNotification then
        self.infoNotificationTimer = 20000
    end
    
    self.isLoaded = true
    addConsoleCommand("tax", "Configure Tax Mod settings", "onConsoleCommand", self)
end

function TaxMod:update(dt)
    if g_currentMission == nil or not self:isServer() then return end
    if not self.settings.enabled then return end

    -- ⏱️ Info-notificatie timer
    if self.infoNotificationTimer ~= nil then
        self.infoNotificationTimer = self.infoNotificationTimer - dt
        if self.infoNotificationTimer <= 0 then
            self.infoNotificationTimer = nil
            self:showInfoNotification()
        end
    end

    local env = g_currentMission.environment
    if env == nil then return end

    if env.currentDay ~= self.lastDay then
        self.lastDay = env.currentDay
        self:applyDailyTax()
    end

    if env.currentMonth ~= self.lastMonth then
        self.lastMonth = env.currentMonth
        self:applyMonthlyReturn()
    end
end
-- =====================
-- TAX LOGIC
-- =====================
function TaxMod:checkDailyTax(env)
    if env.currentDay ~= self.lastDay then
        self.lastDay = env.currentDay
        self:applyDailyTax()
    end
end

function TaxMod:checkMonthlyReturn(env)
    if env.currentMonth ~= self.lastMonth then
        self.lastMonth = env.currentMonth
        self:applyMonthlyReturn()
    end
end

function TaxMod:applyDailyTax()
    if not self.settings.enabled then return end
    if not self:isServer() then return end  -- <-- ADDED

    local farmId = g_currentMission.player.farmId
    if farmId == nil then return end
    
    local farm = g_farmManager:getFarmById(farmId)
    if farm == nil then return end
    
    local farmMoney = farm.money
    local minimumBalance = self.settings.minimumBalance
    
    if farmMoney < minimumBalance then
        self:log(
            "Farm balance (" .. self:formatMoney(farmMoney) ..
            ") below minimum (" .. self:formatMoney(minimumBalance) ..
            "), skipping tax"
        )
        return
    end
    
    local taxRate = self:getTaxRate()
    local taxAmount = math.floor(farmMoney * taxRate)
    
    if taxAmount <= 0 then return end

    g_currentMission:addMoney(-taxAmount, farmId, MoneyType.OTHER, true)
    
    self.stats.totalTaxesPaid = self.stats.totalTaxesPaid + taxAmount
    self.stats.taxesThisMonth = self.stats.taxesThisMonth + taxAmount
    self.stats.daysTaxed = self.stats.daysTaxed + 1
    
    self:log(
        "Daily tax applied | Farm ID: " .. tostring(farmId) ..
        " | Amount: -" .. self:formatMoney(taxAmount) ..
        " | Rate: " .. (taxRate * 100) .. "%"
    )
    
    self:showNotification("tax", -taxAmount)
    self:saveSettingsToXML()
end

function TaxMod:openFromTablet(action)
    if action == "enable" then
        self.settings.enabled = true
        self:saveSettingsToXML()
        self:log("Tax Mod enabled via tablet")
        return {success = true, action = "enabled"}
    elseif action == "disable" then
        self.settings.enabled = false
        self:saveSettingsToXML()
        self:log("Tax Mod disabled via tablet")
        return {success = true, action = "disabled"}
    elseif action == "status" or action == nil then
        -- Return status info
        return {
            enabled = self.settings.enabled,
            taxRate = self.settings.taxRate,
            returnPercentage = self.settings.returnPercentage,
            minimumBalance = self.settings.minimumBalance,
            stats = self.stats,
            formattedTaxRate = string.format("%.1f%%", self:getTaxRate() * 100)
        }
    end
    
    return {error = "Unknown action"}
end

function TaxMod:applyMonthlyReturn()
    if not self.settings.enabled then return end
    if not self:isServer() then return end  -- <-- ADDED

    local farmId = g_currentMission.player.farmId
    if farmId == nil then return end
    
    local returnPercentage =
        math.min(math.max(self.settings.returnPercentage, 0), 100) / 100
    
    local returnAmount =
        math.floor(self.stats.taxesThisMonth * returnPercentage)
    
    if returnAmount <= 0 then
        self:log("No monthly return (no taxes paid this month)")
        self.stats.taxesThisMonth = 0
        return
    end
    
    g_currentMission:addMoney(returnAmount, farmId, MoneyType.OTHER, true)
    
    self.stats.totalTaxesReturned =
        self.stats.totalTaxesReturned + returnAmount
    self.stats.monthsReturned =
        self.stats.monthsReturned + 1
    
    self:log(
        "Monthly tax return | Farm ID: " .. tostring(farmId) ..
        " | Amount: +" .. self:formatMoney(returnAmount) ..
        " | Return %: " .. (returnPercentage * 100) .. "%"
    )
    
    self:showNotification(
        "return",
        returnAmount,
        self.stats.taxesThisMonth
    )
    
    self.stats.taxesThisMonth = 0
    self:saveSettingsToXML()
end

-- =====================
-- NOTIFICATIONS
-- =====================
function TaxMod:showNotification(notificationType, amount, monthlyTaxes)
    if not self.settings.showNotification then return end
    
    local title = ""
    local message = ""
    
    if notificationType == "tax" then
        title = g_i18n:getText("tax_mod_tax_notification_title") or "Tax"
        message = string.format(g_i18n:getText("tax_mod_daily_tax_message") or "Daily tax deducted: %s", 
                              self:formatMoney(amount))
    elseif notificationType == "return" then
        title = g_i18n:getText("tax_mod_return_notification_title") or "Tax Return"
        message = string.format(g_i18n:getText("tax_mod_monthly_return_message") or "Monthly tax return: %s (Taxes paid this month: %s)", 
                              self:formatMoney(amount), 
                              self:formatMoney(monthlyTaxes or 0))
    end
    
    g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, 
        string.format("[%s] %s", title, message))
end

-- =====================
-- CONSOLE COMMANDS
-- =====================
function TaxMod:onConsoleCommand(...)
    local args = {...}

    if #args == 0 then
        print(g_i18n:getText("tax_mod_console_help"))
        return true
    end

    local action = args[1]:lower()

    if action == "status" then
        print("=== Tax Mod Status ===")
        print("Enabled: " .. tostring(self.settings.enabled))
        print("Tax Rate: " .. self.settings.taxRate .. " (" .. (self:getTaxRate() * 100) .. "%)")
        print("Return Percentage: " .. self.settings.returnPercentage .. "%")
        print("Minimum Balance: " .. self:formatMoney(self.settings.minimumBalance))
        print("Show Notifications: " .. tostring(self.settings.showNotification))
        print("Debug Mode: " .. tostring(self.settings.debugMode))
        print("Last Day: " .. tostring(self.lastDay))
        print("Last Month: " .. tostring(self.lastMonth))
        
        if self.settings.showStatistics then
            self:printStatistics()
        end
        
    elseif action == "enable" then
        self.settings.enabled = true
        self:saveSettingsToXML()
        print("Tax system enabled")
        
    elseif action == "disable" then
        self.settings.enabled = false
        self:saveSettingsToXML()
        print("Tax system disabled")
        
    elseif action == "simulate" then
        if g_currentMission and g_currentMission.environment then
            self:applyDailyTax()

            local env = g_currentMission.environment
            if env.currentDay == 1 then
                self:applyMonthlyReturn()
            end

            print("Simulation complete")
        else
            print("Cannot simulate - game not loaded")
        end

    elseif action == "rate" and args[2] then
        local rate = args[2]:lower()
        if rate == "low" or rate == "medium" or rate == "high" then
            self.settings.taxRate = rate
            self:saveSettingsToXML()
            print("Tax rate set to: " .. rate .. " (" .. (self:getTaxRate() * 100) .. "%)")
        else
            print("Invalid rate. Use: tax rate low|medium|high")
        end
        
    elseif action == "return" and args[2] then
        local percentage = tonumber(args[2])
        if percentage ~= nil and percentage >= 0 and percentage <= 100 then
            self.settings.returnPercentage = percentage
            self:saveSettingsToXML()
            print("Return percentage set to: " .. percentage .. "%")
        else
            print("Invalid percentage. Use: tax return [0-100]")
        end
        
    elseif action == "minimum" and args[2] then
        local amount = tonumber(args[2])
        if amount ~= nil and amount >= 0 then
            self.settings.minimumBalance = amount
            self:saveSettingsToXML()
            print("Minimum balance set to: " .. self:formatMoney(amount))
        else
            print("Invalid amount. Use: tax minimum [amount]")
        end
        
    elseif action == "statistics" then
        self:printStatistics()
        
    elseif action == "info" then
        self:showInfoNotification()
        print("Info notification shown in-game")

    elseif action == "simulate" then
        print("Simulating next tax cycle...")
        if g_currentMission and g_currentMission.environment then
            local env = g_currentMission.environment
            self:applyDailyTax()
            if env.currentDay == 1 then 
                self:applyMonthlyReturn()
            end
            print("Simulation complete")
        else
            print("Cannot simulate - game not loaded")
        end
        
    elseif action == "debug" then
        self.settings.debugMode = not self.settings.debugMode
        self:saveSettingsToXML()
        print("Debug mode: " .. tostring(self.settings.debugMode))
        
    elseif action == "reload" then
        self:loadSettingsFromXML()
        print("Settings reloaded from XML")
        
    else
        print("Unknown command. Type 'tax' for help.")
    end

    return true
end

function TaxMod:printStatistics()
    print("=== Tax Statistics ===")
    print("Total taxes paid: " .. self:formatMoney(self.stats.totalTaxesPaid))
    print("Total tax returns: " .. self:formatMoney(self.stats.totalTaxesReturned))
    print("Taxes this month: " .. self:formatMoney(self.stats.taxesThisMonth))
    print("Days taxed: " .. self.stats.daysTaxed)
    print("Months returned: " .. self.stats.monthsReturned)
    
    if self.stats.daysTaxed > 0 then
        local averageTax = math.floor(self.stats.totalTaxesPaid / self.stats.daysTaxed)
        print("Average daily tax: " .. self:formatMoney(averageTax))
    end
end

function TaxMod:printInfo()
    print("=== Tax Information ===")
    print("The Tax Mod deducts daily taxes from your farm based on your balance.")  
    print("At the end of each month, a percentage of the taxes paid is returned to you.")
    print("You can configure the tax rate, return percentage, and other settings via the console commands.")
    print("Type 'tax' in the console for a list of commands.")
    print("========================")
end

function TaxMod:showInfoNotification()
    if not self.settings.showNotification then return end

    local title = g_i18n:getText("tax_mod_info_notification_title") or "Tax Mod"
    local message = table.concat({
       g_i18n:getText("tax_mod_info_notify1"),
       g_i18n:getText("tax_mod_info_notify2"),
       g_i18n:getText("tax_mod_info_notify3"),
       g_i18n:getText("tax_mod_info_notify4")
    }, "\n")

    g_currentMission:addIngameNotification(
        FSBaseMission.INGAME_NOTIFICATION_OK,
        string.format("[%s] %s", title, message)
    )
end


-- =====================
-- MOD EVENTS
-- =====================
function TaxMod:deleteMap()
    self.isLoaded = false
    self.hasRegisteredSettings = false
end

function TaxMod:keyEvent(unicode, sym, modifier, isDown) end
function TaxMod:mouseEvent(posX, posY, isDown, isUp, button) end
function TaxMod:draw() end


-- =====================
-- GLOBAL REGISTRATION
-- =====================
g_TaxMod = TaxMod

-- =====================
-- REGISTER MOD
-- =====================
addModEventListener(TaxMod)
