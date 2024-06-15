-- Declare the buttons and frames at the top to avoid scope issues
local AutoEquipButton
local TextFrame

-- Function to create the new interface with text
local function CreateTextInterface()
    if not TextFrame then
        TextFrame = CreateFrame("Frame", "TextFrame", UIParent, "BasicFrameTemplateWithInset")
        TextFrame:SetSize(300, 200)
        TextFrame:SetPoint("CENTER")

        TextFrame.title = TextFrame:CreateFontString(nil, "OVERLAY")
        TextFrame.title:SetFontObject("GameFontHighlightMedium")
        TextFrame.title:SetPoint("TOP", TextFrame, "TOP", 0, -5)
        TextFrame.title:SetText("AutoEquip 1.0.0")

        TextFrame.text = TextFrame:CreateFontString(nil, "OVERLAY")
        TextFrame.text:SetFontObject("GameFontHighlight")
        TextFrame.text:SetPoint("TOPLEFT", TextFrame, "TOPLEFT", 10, -40)
        TextFrame.text:SetPoint("BOTTOMRIGHT", TextFrame, "BOTTOMRIGHT", -10, 40)
        TextFrame.text:SetJustifyH("LEFT")
        TextFrame.text:SetJustifyV("TOP")
        TextFrame.text:SetText("Hello the purpose of this addon is to minimize the manualization of putting the highest item level gear on any character! To use it simply open your character frame and click the Button with the arrow facing down. The addon will scan your bags and equip the highest item level gear you can use. If you want to checkout the code itself it will be in my github: https://github.com/biomesu")

        -- Create the close button
        TextFrame.closeButton = CreateFrame("Button", nil, TextFrame, "UIPanelCloseButton")
        TextFrame.closeButton:SetPoint("TOPRIGHT", TextFrame, "TOPRIGHT")

         -- Make the frame movable
         TextFrame:SetMovable(true)
         TextFrame:EnableMouse(true)
         TextFrame:RegisterForDrag("LeftButton")
         TextFrame:SetScript("OnDragStart", TextFrame.StartMoving)
         TextFrame:SetScript("OnDragStop", TextFrame.StopMovingOrSizing)
    end
    TextFrame:Show()
end

-- Create the AutoEquip button when the character frame is shown
local function CreateAutoEquipButton()
    if not AutoEquipButton then  -- Check if the button doesn't already exist
        -- Create a new button named "AutoEquipButton" within the CharacterFrame using the "UIPanelButtonTemplate"
        AutoEquipButton = CreateFrame("Button", "AutoEquipButton", CharacterFrame )
        AutoEquipButton:SetSize(30, 30)  -- Set the size of the button (width, height)
        AutoEquipButton:SetPoint("TOPLEFT", CharacterFrameInsetRight, "TOPLEFT", 25, 30)  -- Position the button
        AutoEquipButton:SetText("")  -- Set the initial text displayed on the button

        local tex = AutoEquipButton:CreateTexture(nil, "BACKGROUND")
        tex:SetTexture("Interface\\AddOns\\EquipMaster\\Textures\\add.tga")
        tex:SetAllPoints(AutoEquipButton)
        AutoEquipButton:SetNormalTexture(tex)

        local highlightText = AutoEquipButton:CreateTexture(nil, "HIGHLIGHT")
        highlightText:SetTexture("Interface\\AddOns\\EquipMaster\\Textures\\add2.tga")
        highlightText:SetBlendMode("ADD")
        highlightText:SetAllPoints(AutoEquipButton)

        AutoEquipButton:SetHighlightTexture(highlightText)

        -- Function to check if the player can use the item based on player's level
        local function CanPlayerUseItem(itemLink)
            local playerLevel = UnitLevel("player")  -- Get the player's current level
            local requiredLevel = select(5, GetItemInfo(itemLink))  -- Get the required level to use the item
            return requiredLevel and requiredLevel <= playerLevel  -- Return true if player can use the item, otherwise false
        end

        -- Mapping of itemEquipLoc values to inventory slot names
        local equipSlotMap = {
            ["INVTYPE_HEAD"] = "HeadSlot",
            ["INVTYPE_NECK"] = "NeckSlot",
            ["INVTYPE_SHOULDER"] = "ShoulderSlot",
            ["INVTYPE_CHEST"] = "ChestSlot",
            ["INVTYPE_ROBE"] = "ChestSlot",
            ["INVTYPE_WAIST"] = "WaistSlot",
            ["INVTYPE_LEGS"] = "LegsSlot",
            ["INVTYPE_FEET"] = "FeetSlot",
            ["INVTYPE_WRIST"] = "WristSlot",
            ["INVTYPE_HAND"] = "HandsSlot",
            ["INVTYPE_FINGER"] = "Finger0Slot",  -- Special case, Finger0Slot and Finger1Slot
            ["INVTYPE_TRINKET"] = "Trinket0Slot",  -- Special case, Trinket0Slot and Trinket1Slot
            ["INVTYPE_CLOAK"] = "BackSlot",
            ["INVTYPE_WEAPON"] = "MainHandSlot",  -- Special case, can also be OffHandSlot
            ["INVTYPE_SHIELD"] = "SecondaryHandSlot",
            ["INVTYPE_2HWEAPON"] = "MainHandSlot",
            ["INVTYPE_WEAPONMAINHAND"] = "MainHandSlot",
            ["INVTYPE_WEAPONOFFHAND"] = "SecondaryHandSlot",
            ["INVTYPE_HOLDABLE"] = "SecondaryHandSlot",
            ["INVTYPE_RANGED"] = "RangedSlot",
            ["INVTYPE_THROWN"] = "RangedSlot",
            ["INVTYPE_RANGEDRIGHT"] = "RangedSlot",
            ["INVTYPE_RELIC"] = "RangedSlot",
        }

        -- Function to find and equip the highest item level gear
        local function AutoEquipGear()
            local playerLevel = UnitLevel("player")  -- Get the player's current level
            local bestItems = {}  -- Table to store the best items for each slot

            -- Loop through each bag
            for bag = 0, 4 do
                -- Loop through each slot in the bag
                for slot = 1, C_Container.GetContainerNumSlots(bag) do
                    local itemLink = C_Container.GetContainerItemLink(bag, slot)  -- Get the item link in the current slot
                    if itemLink then
                        local itemName, _, itemRarity, itemLevel, _, _, _, _, itemEquipLoc = GetItemInfo(itemLink)  -- Retrieve item information
                        if IsEquippableItem(itemLink) and CanPlayerUseItem(itemLink) then  -- Check if item is equippable and usable
                            local slotName = equipSlotMap[itemEquipLoc]  -- Get the slot name corresponding to item's equip location
                            if slotName then
                                if not bestItems[slotName] or itemLevel > bestItems[slotName].itemLevel then
                                    -- Update best item for the slot if current item is better
                                    bestItems[slotName] = { itemLink = itemLink, itemLevel = itemLevel }
                                end
                            end
                        end
                    end
                end
            end

            -- Equip the best items found
            for slotName, item in pairs(bestItems) do
                local slotId = GetInventorySlotInfo(slotName)  -- Get the inventory slot ID for the given slot name
                local currentItemLink = GetInventoryItemLink("player", slotId)  -- Get the currently equipped item in that slot
                local currentItemLevel = currentItemLink and select(4, GetItemInfo(currentItemLink)) or 0  -- Get its item level or default to 0

                -- Equip the best item if it has higher item level than the currently equipped one
                if item.itemLevel > currentItemLevel then
                    EquipItemByName(item.itemLink)
                end
            end
        end

        -- Set the function AutoEquipGear as the OnClick handler for the button
        AutoEquipButton:SetScript("OnClick", AutoEquipGear)
    end
end

-- Hook the CharacterFrame's OnShow event to create the button when the frame is shown
CharacterFrame:HookScript("OnShow", CreateAutoEquipButton)

-- Directly call the function to show the text interface
CreateTextInterface()

-- Debug message to confirm that the addon is loaded
print("AutoEquip Addon Loaded")

