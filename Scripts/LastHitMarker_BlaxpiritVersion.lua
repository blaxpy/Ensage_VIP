--<<If the icon has become colored that means creep will die from your attack>>
--===By Blaxpirit===--

require("libs.Utils")
require("libs.HeroInfo")

local reg = false
local x_ratio = client.screenSize.x/1600
local rect = {}

function Tick( tick )

	local bloodseeker = entityList:GetEntities({classId=CDOTA_Unit_Hero_Bloodseeker})[1]
	if bloodseeker and bloodseeker:GetAbility(1) ~= nil then
		local bloodseekerAmplificationArray = {1.25, 1.3, 1.35, 1.4}
		bloodseekerAmplifier = bloodseekerAmplificationArray[bloodseeker:GetAbility(1).level]
	else
		bloodseekerAmplifier = 0
	end

--=================================<< ENTITIES >>=========================================
	--Heroes
	local heroes = entityList:GetEntities({type=LuaEntity.TYPE_HERO,illusion=false})
	for i, v in ipairs(heroes) do
		LastHitMarker(v,1,1.4,3,15)
	end
--========================================================================================
	-- Lane, neutral and summoned creeps
	local entities1 = {}
	
	local lanecreeps = entityList:GetEntities({classId=CDOTA_BaseNPC_Creep_Lane})
	local neutrals = entityList:GetEntities({classId=CDOTA_BaseNPC_Creep_Neutral})
	local creeps = entityList:GetEntities({classId=CDOTA_BaseNPC_Creep})
	local forge = entityList:GetEntities({classId=CDOTA_BaseNPC_Invoker_Forged_Spirit})	
	--------------------------------------------------------------------------------------
	for k,v in pairs(lanecreeps) do if v.spawned then entities1[#entities1 + 1] = v end end
	for k,v in pairs(neutrals) do if v.spawned then entities1[#entities1 + 1] = v end end
	for k,v in pairs(creeps) do if v.spawned then entities1[#entities1 + 1] = v end end
	for k,v in pairs(forge) do entities1[#entities1 + 1] = v end 
	--------------------------------------------------------------------------------------
	for i, v in ipairs(entities1) do
		LastHitMarker(v,2,1,-2,0)
	end
--========================================================================================
	-- Warlock's golems
	local golem = entityList:GetEntities({classId=CDOTA_BaseNPC_Warlock_Golem})
	for i, v in ipairs(golem) do
		LastHitMarker(v,2,1.3,0,7)
	end
--========================================================================================
	-- Veno's and rasta's wards
	local entities2 = {}

	local venowards = entityList:GetEntities({classId=CDOTA_BaseNPC_Venomancer_PlagueWard})
	local rastawards = entityList:GetEntities({classId=CDOTA_BaseNPC_ShadowShaman_SerpentWard})
	local observerwards = entityList:GetEntities({classId=CDOTA_NPC_Observer_Ward})
	--------------------------------------------------------------------------------------	
	for k,v in pairs(venowards) do entities2[#entities2 + 1] = v end
	for k,v in pairs(rastawards) do entities2[#entities2 + 1] = v end
	for k,v in pairs(observerwards) do entities2[#entities2 + 1] = v end
	--------------------------------------------------------------------------------------
	for i, v in ipairs(entities2) do
		LastHitMarker(v,3,1,0,0)
	end	
--========================================================================================
	-- Catapults 
	local siege = entityList:GetEntities({classId=CDOTA_BaseNPC_Creep_Siege})
	for i, v in ipairs(siege) do
		LastHitMarker(v,4,1.5,4,-7)
	end	
--========================================================================================
	--Wells
	local buildings = entityList:GetEntities({classId=CDOTA_BaseNPC_Building})
	for i, v in ipairs(buildings) do
		LastHitMarker(v,5,1.5,4,-7)
	end	
--========================================================================================
	-- Ancients, towers and barracks
	local entities3 = {}
	
	local ancients = entityList:GetEntities({classId=CDOTA_BaseNPC_Fort})
	local towers = entityList:GetEntities({classId=CDOTA_BaseNPC_Tower})
	local barracks = entityList:GetEntities({classId=CDOTA_BaseNPC_Barracks})
	--------------------------------------------------------------------------------------
	for k,v in pairs(ancients) do entities3[#entities3 + 1] = v end
	for k,v in pairs(towers) do entities3[#entities3 + 1] = v end
	for k,v in pairs(barracks) do entities3[#entities3 + 1] = v end
	--------------------------------------------------------------------------------------
	for i, v in ipairs(entities3) do
		LastHitMarker(v,5,1.5,4,50)
	end
--=====================================<< END >>==========================================
	
end

function LastHitMarker(v,damagetype,size,moveleft,moveup)
	--[[
		damagetypes:
			1 - hero, 
			2 - creeps and summons,
			3 - wards,
			4 - siege,
			5 - buildings.
	--]]
	local OnScreen = client:ScreenPosition(v.position)
	if OnScreen then
		local me = entityList:GetMyHero()
		local offset = v.healthbarOffset
		if offset == -1 then return end			
		
		if not rect[v.handle] then 
			rect[v.handle] = drawMgr:CreateRect(-9*x_ratio - moveleft,-33*x_ratio*size - moveup,0,0,0xFF8AB160) rect[v.handle].entity = v rect[v.handle].entityPosition = Vector(0,0,offset) rect[v.handle].visible = false 					
		end
		
		local mydamage = me.dmgMin + me.dmgBonus
		
		--Your hero's damage amplifications
		local tidebringer = me:FindSpell("kunkka_tidebringer")
		if tidebringer and tidebringer.level > 0 and tidebringer.cd == 0 then
			local tidebringer_bonusdmg = {15,30,45,60}
			mydamage = mydamage + tidebringer_bonusdmg[tidebringer.level]
		end
		
		local nethertoxin = me:FindSpell("viper_nethertoxin")
		if nethertoxin and nethertoxin.level > 0 then
			local nethertoxin_bonusdmg = {1.25,2.5,3.75,5}
			local multiplier = 1
			if damagetype == 1 then
				multiplier = 2
			end
			mydamage = mydamage + multiplier*nethertoxin_bonusdmg[nethertoxin.level]*GetdmgAmplifier(v)
		end
		
		local enemydamage = mydamage
		local allydamage = mydamage
		
		--[[Creeps and summons]]
		if damagetype == 2 then
			local quellingblade = me:FindItem("item_quelling_blade")
			if quellingblade then
				if not heroInfo[me.name].projectileSpeed then
					enemydamage = enemydamage*1.32
				else 
					enemydamage = enemydamage*1.12
				end
			end
		end
		
		local manabreak = me:FindSpell("antimage_mana_break")
		if manabreak and manabreak.level > 0 and v.mana > 0 then
			local manabreak_manaburn = {28,40,52,64}
			if (v.mana - manabreak_manaburn[manabreak.level]) > 0 then
				enemydamage = enemydamage + manabreak_manaburn[manabreak.level]*0.6
			else
				enemydamage = enemydamage + v.mana*0.6
			end
		end
		
		--[[NOT Wards and Buildings]]
		if damagetype ~= 3 and damagetype ~= 5 then
			local jinada = me:FindSpell("bounty_hunter_jinada")
			if jinada and jinada.level > 0 and jinada.cd == 0 then
				local jinadamultiplier = {1.5,1.75,2,2.25}
				enemydamage = enemydamage*jinadamultiplier[jinada.level]
			end
			local lothar_invis = me:FindModifier("modifier_item_invisibility_edge_windwalk")
			if lothar_invis then
				enemydamage = enemydamage + 175
				allydamage = allydamage + 175
			end
		end	
		
		--[[Siege and Buildings]]
		if damagetype == 4 or damagetype == 5 then
			enemydamage = enemydamage*0.5
			allydamage = allydamage*0.5
		end
		
		if damagetype ~= 1 then
			local bloodrage_me = me:FindModifier("modifier_bloodseeker_bloodrage")
			local bloodrage_victim = v:FindModifier("modifier_bloodseeker_bloodrage")
			if bloodrage_me then 
				enemydamage = enemydamage*bloodseekerAmplifier
				allydamage = allydamage*bloodseekerAmplifier
			end
			if bloodrage_victim then
				enemydamage = enemydamage*bloodseekerAmplifier
				allydamage = allydamage*bloodseekerAmplifier
			end
		end
		
		--Victim's damage resistance
		local resistance = v.dmgResist
		local desolator = me:FindItem("item_desolator")
		local desol_debuff = v:FindModifier("modifier_desolator_buff")
		if desolator and not desol_debuff then
			local armor = v.armor + v.bonusArmor - 7
			if armor > 0 then
				resistance = (0.06*(armor))/(1 + 0.06*(armor))
			else
				resistance = -(1 - 0.94^(-armor))
			end	
		end			
		
		if v.visible and v.alive and v.team ~= me.team then
			if v.health > 2*enemydamage*(1 - resistance) then
				rect[v.handle].visible = false
			elseif v.health > enemydamage*(1 - resistance) and v.health < 2*enemydamage*(1 - resistance) then
				rect[v.handle].w = 15*x_ratio*size
				rect[v.handle].h = 15*x_ratio*size
				rect[v.handle].textureId = drawMgr:GetTextureId("NyanUI/other/Passive_Coin")
				rect[v.handle].visible = true
			elseif v.health > 0 and v.health < enemydamage*(1 - resistance) then
				rect[v.handle].w = 15*x_ratio*size
				rect[v.handle].h = 15*x_ratio*size
				rect[v.handle].textureId = drawMgr:GetTextureId("NyanUI/other/Active_Coin")
				rect[v.handle].visible = true
			end
		elseif v.visible and v.alive and v.team == me.team and v ~= me then	
			if v.health > 2*allydamage*(1 - resistance) then
				rect[v.handle].visible = false
			elseif v.health > allydamage*(1 - resistance) and v.health < 2*allydamage*(1 - resistance) then
				rect[v.handle].w = 17*x_ratio*size
				rect[v.handle].h = 17*x_ratio*size
				rect[v.handle].textureId = drawMgr:GetTextureId("NyanUI/other/Passive_Deny")
				rect[v.handle].visible = true
			elseif v.health > 0 and v.health < allydamage*(1 - resistance) then
				rect[v.handle].w = 17*x_ratio*size
				rect[v.handle].h = 17*x_ratio*size
				rect[v.handle].textureId = drawMgr:GetTextureId("NyanUI/other/Active_Deny")
				rect[v.handle].visible = true
			end
		elseif rect[v.handle].visible then
			rect[v.handle].visible = false
		end
	end
end

function math_round( roundIn , roundDig )
    local mul = math.pow( 10, roundDig )
    return ( math.floor( ( roundIn * mul ) + 0.5 )/mul )
end

--Viper's damage amplification function
function GetdmgAmplifier(target)
	local percentage = math_round(target.health/target.maxHealth*100,1)
	if percentage <= 100 and percentage >= 81 then
		return 1
	elseif percentage < 81 and percentage >= 61 then
		return 2
	elseif percentage < 61 and percentage >= 41 then
		return 4
	elseif percentage < 41 and percentage >= 21 then
		return 8
	elseif percentage < 21 and percentage >= 0 then
		return 16
	end
end

function Load()
	if PlayingGame() then
		local me = entityList:GetMyHero()
		if not me then 
			script:Disable()
		else
			reg = true
			script:RegisterEvent(EVENT_TICK,Tick)
			script:UnregisterEvent(Load)
		end
	end
end

function GameClose()
	rect = {}
	collectgarbage("collect")
	if reg then
		script:UnregisterEvent(Tick)
		script:RegisterEvent(EVENT_TICK,Load)
		reg = false
	end
end

script:RegisterEvent(EVENT_TICK,Load)
script:RegisterEvent(EVENT_CLOSE,GameClose)
