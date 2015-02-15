--<<Combo: remnant+smash+grip+rolling and show ulti time bars>>
--===By Blaxpirit===--
--Smash grip roll combo by D.L.

require("libs.Utils")
require("libs.ScriptConfig")
require("libs.Animations")

config = ScriptConfig.new()
config:SetParameter("Hotkey", "G", config.TYPE_HOTKEY)
config:SetParameter("AutoPick", false)
config:SetParameter("SkillBuild", 1)
config:Load()

local key = config.Hotkey
local autopick = config.AutoPick
local skillbuild = config.SkillBuild

local x_ratio = client.screenSize.x/1600
local F15 = drawMgr:CreateFont("F15","Tahoma",15*x_ratio,550*x_ratio)

local statusText = drawMgr:CreateText(1330*x_ratio,40*x_ratio,-1,"Press "..string.char(key).." to enable, press again to disable",F15) statusText.visible = false

local play = false
local sleep,start,stage = nil,nil,0
local remnants = {}
local ultistate = {}
local unbinded = false

--=====================<< SkillBuilds >>=======================
--1 - smash, 2 - roll, 3 - grip, 6 - ult, 7 - attribute bonus
--lvl		 1 2 3 4 5 6 7 8 9 10 
local sb1 = {3,2,1,3,3,6,3,1,1,1,6,2,2,2,7,6,7,7,7,7,7,7,7,7,7}
local sb2 = {2,1,3,3,3,6,3,1,1,1,6,2,2,2,7,6,7,7,7,7,7,7,7,7,7}
--=========================<< END >>===========================


function Key(msg,code)
	if not PlayingGame() or client.chat then return end
	
	if msg == KEY_UP then
		if code == key then
			if not start then
				sleep,start = nil,true
				statusText.text = "Status: On"
				return true
			else
				sleep,start,stage = nil,nil,0
				statusText.text = "Status: Off"
				return true
			end
		end
	end
end

function Tick(tick)	
	if not client.connected or client.loading or client.console then return end
	
	if client.gameState == Client.STATE_PICK and autopick then
		client:ExecuteCmd("dota_select_hero npc_dota_hero_earth_spirit")
		autopick = false
	end
	
	local me = entityList:GetMyHero() 
	local mp = entityList:GetMyPlayer()

	if skillbuild == 1 then
		sb = sb1
	elseif skillbuild == 2 then
		sb = sb2
	end
	
	local sel = mp.selection[1]
	if sel and sel.name == "npc_dota_hero_earth_spirit" and not unbinded then
		client:ExecuteCmd("unbind q")
		client:ExecuteCmd("unbind e")
		client:ExecuteCmd("unbind f")
		client:ExecuteCmd("unbind r")
		unbinded = true
	elseif sel and sel.name ~= "npc_dota_hero_earth_spirit" and unbinded then
		client:ExecuteCmd("bind q \"dota_ability_quickcast 0\"")
		client:ExecuteCmd("bind e \"dota_ability_quickcast 2\"")
		client:ExecuteCmd("bind f \"dota_ability_quickcast 4\"")
		client:ExecuteCmd("bind r \"dota_ability_quickcast 5\"")
		unbinded = false
	end
	
	local points = me.abilityPoints		
	if points > 0 and SleepCheck("points") then
		local prev = SelectUnit(me)
		mp:LearnAbility(me:GetAbility(sb[me.level+1-points]))
		SelectBack(prev)
		Sleep(125,"points")
	end
	
	Track()		
	
	if start then
		local sel = entityList:GetMyPlayer().selection[1]
		if sel and sel.handle ~= me.handle then
			start = nil
			statusText.text = "Status: Off"
			return
		end
		
		local remnant = me:GetAbility(4)
		local grip = me:GetAbility(3)
		local roll = me:GetAbility(2)
		local smash = me:GetAbility(1)
		
		local stunned = entityList:GetEntities(function (ent) return ent.type == LuaEntity.TYPE_HERO and ent:DoesHaveModifier("modifier_stunned") == true end)[1]
		local last = Last()

		if me:CanCast() then
			if stage == 0 then			
				if me.activity == LuaEntityNPC.ACTIVITY_MOVE then
					me:Stop()					
				end	
				stage = 1
			elseif stage == 1 then
				if remnant:CanBeCasted() and smash:CanBeCasted() then
					local cursor = client.mousePosition
					me:CastAbility(remnant,(cursor - me.position) * 190 / GetDistance2D(cursor,me) + me.position,false)
					me:CastAbility(smash,cursor,true)	
					sleep = tick + 1200
					stage = 2
				end			
			elseif stage == 2 and stunned and grip:CanBeCasted() and GetDistance2D(stunned,me) < grip.castRange then				
				if last then
					me:CastAbility(grip,last.position)
					stage = 3
					sleep = tick + 800
				else
					me:CastAbility(grip,stunned.position)
					stage = 3
					sleep = tick + 800
				end
			elseif stage == 3 and roll:CanBeCasted() and stunned and stunned:DoesHaveModifier("modifier_earth_spirit_boulder_smash_silence") then			
				me:CastAbility(roll,(stunned.position - me.position) * 600 / GetDistance2D(stunned,me) + me.position,false)
				stage = 0
				start = nil
				statusText.text = "Status: Off"
			end			
		end
		
		if sleep and tick > sleep then
			statusText.text = "Status: Off"
			sleep,start = nil
			stage = 0
		end
	end
	
	if not client.chat and sel and sel.name == "npc_dota_hero_earth_spirit" and SleepCheck("abilities") then
		local cursor = client.mousePosition
		local enchant_remnant = me:FindAbility("earth_spirit_petrify")
		if enchant_remnant and enchant_remnant.abilityPhase then return end
		--[[ Q hotkey - smash ]]
		if IsKeyDown(81) then
			local smash = me:GetAbility(1)
			local remnant = me:GetAbility(4)
			local victim = entityList:GetEntities(function (v) return v.hero and v.alive and v.visible and not v:IsIllusion() and v:DoesHaveModifier("modifier_earthspirit_petrify") and v ~= me and GetDistance2D(v,me) <= 200 end)[1]
			local closest_remnant = entityList:GetEntities(function (v) return v.classId==CDOTA_Unit_Earth_Spirit_Stone and GetDistance2D(v,me) <= 200 end)[1]
			local enemy = entityList:GetEntities(function (v) return v.hero and v.alive and v.visible and not v:IsIllusion() and v.team ~= me.team and (GetDistance2D(v,me) <= 150 and GetDistance2D(v,cursor) <= 100) end)[1]
			local allied_hero = entityList:GetEntities(function (v) return v.hero and v.alive and v.visible and not v:IsIllusion() and v.team == me.team and v ~= me and (GetDistance2D(v,me) <= 150 and GetDistance2D(v,cursor) <= 100) end)[1]
			local creep = entityList:GetEntities(function (v) return (v.classId==CDOTA_BaseNPC_Creep_Lane or v.classId==CDOTA_BaseNPC_Creep_Neutral) and GetDistance2D(v,cursor) <= 100 end)[1]
			local roll_buff = me:FindModifier("modifier_earth_spirit_rolling_boulder_caster")
			if smash:CanBeCasted() and not roll_buff then
				if remnant:CanBeCasted() and not (closest_remnant or enemy) and SleepCheck("remnant") then
					me:CastAbility(remnant,(cursor - me.position) * 150 / GetDistance2D(cursor,me) + me.position)
					Sleep(750,"remnant")
				end
				if victim or closest_remnant then
					me:CastAbility(smash,cursor)
					Sleep(750,"remnant")
					Sleep(100,"abilities")
				elseif enemy then
					me:CastAbility(smash,enemy)
					Sleep(100,"abilities")
				elseif allied_hero then
					me:CastAbility(smash,allied_hero)
					Sleep(100,"abilities")	
				elseif creep then
					me:CastAbility(smash,enemy)
					Sleep(100,"abilities")
				end
			end
		end
		--[[ E hotkey - grip ]]
		if IsKeyDown(69) then
			local grip = me:GetAbility(3)
			local remnant = me:GetAbility(4)
			local victim = entityList:GetEntities(function (v) return v.hero and v.alive and v.visible and not v:IsIllusion() and v:DoesHaveModifier("modifier_earthspirit_petrify") and GetDistance2D(v,cursor) <= 180 end)[1]
			local closest_remnant = entityList:GetEntities(function (v) return v.classId==CDOTA_Unit_Earth_Spirit_Stone and GetDistance2D(v,cursor) <= 180 end)[1]
			local allied_hero = entityList:GetEntities(function (v) return v.hero and v.alive and v.visible and not v:IsIllusion() and v.team == me.team and v ~= me and GetDistance2D(v,cursor) <= 100 end)[1]
			local allied_creep = entityList:GetEntities(function (v) return (v.classId==CDOTA_BaseNPC_Creep_Lane or v.classId==CDOTA_BaseNPC_Creep_Neutral) and v.alive and v.visible and not v:IsIllusion() and v.team == me.team and GetDistance2D(v,cursor) <= 100 end)[1]
			if grip:CanBeCasted() then
				if remnant:CanBeCasted() and not (victim or closest_remnant or allied_hero or allied_creep) and SleepCheck("remnant") then
					me:CastAbility(remnant,cursor)
					Sleep(750,"remnant")
				end
				if victim then
					me:CastAbility(grip,victim.position)
					Sleep(750,"remnant")
					Sleep(100,"abilities")
				elseif closest_remnant then
					me:CastAbility(grip,closest_remnant.position)
					Sleep(750,"remnant")
					Sleep(100,"abilities")
				elseif allied_hero then
					me:CastAbility(grip,allied_hero)
					Sleep(100,"abilities")
				elseif allied_creep then
					me:CastAbility(grip,allied_creep)
					Sleep(100,"abilities")
				end
			end
		end
		--[[ F hotkey - enchant remnant ]] 
		if IsKeyDown(70) then
			local enchant_remnant = me:GetAbility(5)
			local victim = entityList:GetEntities(function (v) return v.hero and v.alive and v.visible and not (v:IsIllusion() or v:IsMagicImmune() or v:IsInvul()) and v ~= me and GetDistance2D(v,cursor) <= 100 end)[1]
			if enchant_remnant:CanBeCasted() and victim then
				me:SafeCastAbility(enchant_remnant,victim)
				Sleep(750,"remnant")
				Sleep(100,"abilities")
			end
		end
		--[[ R hotkey - magnetize ]]
		if IsKeyDown(82) then
			local magnetize = me:GetAbility(6)
			local enemy = entityList:GetEntities(function (v) return v.hero and v.alive and v.visible and not v:IsIllusion() and v.team ~= me.team and GetDistance2D(v,me) < 300 end)[1]
			if magnetize:CanBeCasted() and enemy then
				me:CastAbility(magnetize)
				Sleep(100,"abilities")
			end
		end
		--[[ T hotkey - stun and roll ]]
		if IsKeyDown(84) then
			local smash = me:GetAbility(1)
			local roll = me:GetAbility(2)
			local remnant = me:GetAbility(4)
			local roll_buff = me:FindModifier("modifier_earth_spirit_rolling_boulder_caster")
			local closest_remnant = entityList:GetEntities(function (v) return v.classId==CDOTA_Unit_Earth_Spirit_Stone and GetDistance2D(v,me) <= 200 end)[1]
			if roll:CanBeCasted() and smash:CanBeCasted() and remnant:CanBeCasted() and me:GetTurnTime(cursor) == 0 and SleepCheck("remnant") then
				me:CastAbility(remnant,(cursor - me.position) * 170 / GetDistance2D(cursor,me) + me.position)
				me:CastAbility(roll,cursor)
				Sleep(750,"remnant")
				Sleep(650,"roll")
				Sleep(100,"abilities")
			end
			if roll_buff and smash:CanBeCasted() and SleepCheck("roll") then
				me:CastAbility(smash,cursor)
				Sleep(100,"abilities")
			end
		end
	end
end

function Last()
	local remn = entityList:GetEntities({classId = CDOTA_Unit_Earth_Spirit_Stone})
	if #remn > 1 then
		table.sort(remn, function(a,b) return remnants[a.handle]>remnants[b.handle] end)
		return remn[1]
	else
		return remn[1]
	end
end

function Track()
	local remn = entityList:GetEntities({classId = CDOTA_Unit_Earth_Spirit_Stone})
	for i,v in ipairs(remn) do
		if not remnants[v.handle] then
			remnants[v.handle] = client.totalGameTime
		end
	end
end

function Load()
	if PlayingGame() then
		local me = entityList:GetMyHero()
		if me.classId ~= CDOTA_Unit_Hero_EarthSpirit then
			script:Disable()
		else
			play = true
			statusText.text = "Press "..string.char(key).." to enable, press again to disable"
			statusText.visible = true
			sleep,start,stage = nil,nil,0
			remnants = {}
			unbinded = false
			script:RegisterEvent(EVENT_TICK,Tick)
			script:RegisterEvent(EVENT_KEY,Key)
			script:UnregisterEvent(Load)
		end
	end
end

function GameClose()
	collectgarbage("collect")
	if play then
		statusText.text = "Press "..string.char(key).." to enable, press again to disable"
		statusText.visible = false
		sleep,start,stage = nil,nil,0
		remnants = {}
		unbinded = false
		script:UnregisterEvent(Tick)
		script:UnregisterEvent(Key)
		play = false
	end
end

script:RegisterEvent(EVENT_CLOSE,GameClose)
script:RegisterEvent(EVENT_TICK,Load)
