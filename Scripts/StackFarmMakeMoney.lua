--<<Stacks forest with naga's iilusions and meepo's clones>>
--===By Blaxpirit===--

require("libs.Utils")
require("libs.ScriptConfig")

config = ScriptConfig.new()
config:SetParameter("Active", "H", config.TYPE_HOTKEY)
config:SetParameter("FarmKey", "Y", config.TYPE_HOTKEY)
config:SetParameter("StackKey", "U", config.TYPE_HOTKEY)
config:Load()

local toggleKey = config.Active
local farmKey = config.FarmKey
local stackKey = config.StackKey


local reg = false
local active = true
local activated = false
local monitor = client.screenSize.x/1600
local F11 = drawMgr:CreateFont("F11","Tahoma",11*monitor,550*monitor) 
local statusText = drawMgr:CreateText(3*monitor,107*monitor,-1,"(" .. string.char(toggleKey) .. ") Forest Farm: On",F11) statusText.visible = false

sleepTick = nil

activeunit = {}
ordered = {}

Positions = {
	--[[Radiant]]
--								{1: pull point			 |2: run away point		  |3: wait point 		   |4: forest attack point	|5:team 
	--[[Easy camp]] 			{Vector(3073,-4676,256),  Vector(5108,-4967,256),  Vector(3071,-5438,256),  Vector(3126,-3229,256),  team = 2},
	--[[Left hard camp]] 		{Vector(-1131,-4044,127), Vector(-3584,-3475,128), Vector(-1555,-3455,127), Vector(-1096,-4096,127), team = 2},
	--[[Left medium camp]] 		{Vector(-366,-2945,127),  Vector(-717,-1625,127),  Vector(-493,-2295,127),  Vector(-407,-3182,127),  team = 2},
	--[[Right hard camp]] 		{Vector(1617,-3722,256),  Vector(152,-4460,256),   Vector(1007,-3920,256),  Vector(1603,-3502,256),  team = 2},
	--[[Right medium camp]] 	{Vector(3126,-3439,256),  Vector(4954,-3723,256),  Vector(3852,-3838,256),  Vector(3126,-3229,256),  team = 2},
--	--[[Ancient camp]] 			{Vector(-2991,191,256),   Vector(-3483,-1735,247), Vector(-2433,-356,256),  team = 2},

	--[[Dire]]
--								{1: pull point			 |2: run away point		  |3: wait point 		   |4: forest attack point	|5:team 
	--[[Easy camp]] 			{Vector(-3116,4668,256),  Vector(-658,5016,256),   Vector(-3098,4967,256),  Vector(-3071,4466,256),  team = 3},
	--[[Left hard camp]] 		{Vector(-4472,3505,256),  Vector(-1995,3516,27),   Vector(-3593,3995,256),  Vector(-4496,3493,256),  team = 3},
	--[[Left medium camp]] 		{Vector(-1588,2697,127),  Vector(-1308,4895,256),  Vector(-1189,3162,127),  Vector(-1604,2545,127),  team = 3},
	--[[Right hard camp]] 		{Vector(1167,3295,256),   Vector(345,5274,256),    Vector(987,3818,256),    Vector(1239,3235,256),   team = 3},
	--[[Right medium camp]] 	{Vector(-371,3768,256),   Vector(-600,5428,256),   Vector(-515,4845,256),   Vector(-268,3625,256),   team = 3},
--	--[[Ancient camp]] 			{Vector(4447,-1950,127),  Vector(5480,-282,256),   Vector(4697,-1377,127),  team = 3}

}

function Key(msg,code)
	if client.chat or client.console or client.loading then return end
	
	if activated then
		if IsKeyDown(toggleKey) then
			active = not active
			if active then
				statusText.text = "(" .. string.char(toggleKey) .. ") Farm or Stack: On"
			else
				for i,v in ipairs(units) do
					activeunit[v.handle] = 0
				end
				statusText.text = "(" .. string.char(toggleKey) .. ") Farm or Stack: Off"
			end
		end
		
		if active then
			if msg == KEY_UP then
				if code == farmKey then
					DoSmth(1)
				elseif code == stackKey then
					DoSmth(2)
				end
			end
		end
	end
end

function Tick(tick)
	if not PlayingGame() then return end
	if sleepTick and sleepTick > tick then return end
	
	if me.classId == CDOTA_Unit_Hero_Meepo then
		units = entityList:FindEntities({ type = LuaEntity.TYPE_MEEPO,alive=true})
		activated = true
		statusText.visible = true
	elseif me.classId == CDOTA_Unit_Hero_Naga_Siren then
		units = entityList:FindEntities({CDOTA_Unit_Hero_Naga_Siren,alive=true,illusion=true})
		activated = true 
		statusText.visible = true
	end
	
	if active and activated then
		for i,v in ipairs(units) do
			local waitt = 0 
			if isPosEqual(v.position,Vector(-493,-2295,127),100) then
				waitt = 3.7
			else isPosEqual(v.position,Vector(-515,4845,256),100)
				waitt = 2
			end
			if activeunit[v.handle] and activeunit[v.handle] ~= 0 and not ordered[v.handle] and isPosEqual(v.position,Positions[activeunit[v.handle]][3],100) and math.floor(client.gameTime%60) == math.floor(52.7+waitt-540/v.movespeed) then
				ordered[v.handle] = true
				v:Move(Positions[activeunit[v.handle]][1])
				v:Move(Positions[activeunit[v.handle]][2],true)
				sleepTick = GetTick() + 1000
				statusText.text = "Stacking" 
			elseif ordered[v.handle] and math.floor(client.gameTime%60) == 0 then
				v:Move(Positions[activeunit[v.handle]][3])
				sleepTick = GetTick() + 1000
				statusText.text = "Returning to wait point" 
			elseif ordered[v.handle] and math.floor(client.gameTime%60) < 51 then
				ordered[v.handle] = false
				statusText.text = "Waiting" 
			end
		end
	end
end

function DoSmth(action)
	for i,v in ipairs(units) do
		activeunit[v.handle] = 0
	end
	for k,m in ipairs(units) do 
		mp:Select(m)
		local sel = mp.selection[1]
		if not activeunit[sel.handle] or activeunit[sel.handle] == 0 then
			if sel then
				local range = 100000
				for i,v in ipairs(Positions) do 
					local rang = GetDistance2D(sel.position,v[1])
					local empty = true
					for j,w in ipairs(units) do
						if activeunit[w.handle] and activeunit[w.handle] == i then
							empty = false
						end
					end
					if action == 1 and range > rang and empty then
						range = rang
						activeunit[sel.handle] = i
					elseif v.team == mp.team and range > rang and empty then
						range = rang
						activeunit[sel.handle] = i
					end
				end
				if action == 1 then
					sel:AttackMove(Positions[activeunit[sel.handle]][4])
					statusText.text = "Farming Jungle" 
				else
					sel:Move(Positions[activeunit[sel.handle]][3])
					statusText.text = "Moving to camp's wait point" 
				end
			else
				activeunit[sel.handle] = 0
			end
		end
	end
	mp:Select(me)
end

function isPosEqual(v1, v2, d)
	return (v1-v2).length <= d
end

function Load()
	if PlayingGame() then
		me = entityList:GetMyHero()
		mp = entityList:GetMyPlayer()
		if not me then 
			script:Disable()
		else
			reg = true
			script:RegisterEvent(EVENT_TICK,Tick)
			script:RegisterEvent(EVENT_KEY,Key)
			script:UnregisterEvent(Load)
		end
	end
end

function GameClose()
	statusText.visible = false
	activeunit = {}
	ordered = {}
	collectgarbage("collect")
	if reg then
		script:UnregisterEvent(Tick)
		script:UnregisterEvent(Key)
		script:RegisterEvent(EVENT_TICK,Load)
		reg = false
	end
end

script:RegisterEvent(EVENT_CLOSE,GameClose)
script:RegisterEvent(EVENT_TICK,Load)
