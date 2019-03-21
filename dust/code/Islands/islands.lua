-- Islands
-- based on earthsea + FM7 + sequencers
--
-- 4 layer instrument
-- using grid 
-- (also responds to midi for note playing) 
--
-- Button 2 - edit sound mode 
-- Button 3 - sequencer detail page
-- Button 2 + 3 - settings 
--
local islandsparams = require 'junklight/islands'
local MT = require 'junklight/mt7'
local esea = require 'junklight/esea'
local tab = require 'tabutil'
engine.name = 'MT7'
local g = grid.connect()

local soundscaper = require 'junklight/soundscaper'
local kria = require 'ansible/kria'
local BeatClock = require 'beatclock'
local clk = BeatClock.new()

local root = { x=5, y=5 }
local lit = {}
lit[1] = {}
lit[2] = {}
lit[3] = {}
lit[4] = {}
local current_layer = 1
-- think we need table per layer
-- but small steps
-- for now just put all three 
-- sequencers for the layer 
-- into a table 
local sequencer = {} 
sequencer[1] = soundscaper.new()
sequencer[2] = soundscaper.new()
sequencer[3] = soundscaper.new()
sequencer[4] = soundscaper.new()
local screen_framerate = 15
local screen_refresh_metro
local MAX_NUM_VOICES = 16
-- trying to make the various modes a bit 
-- mode readable using constants 
--
-- ok some constants for modes 
local PLAY_MODE = 0
local EDIT_MODE = 1
local SEQ_MODE = 2
local SETTINGS_MODE = 3
-- modes as above ^^
local mode = PLAY_MODE

-- edit modes 
local OFF_EMODE = 0
local CARRIER_EMODE = 1
local MATRIX_EMODE = 2
local AMP_EMODE = 3
local FREQ_EMODE = 4
local A_EMODE = 5
local D_EMODE = 6
local S_EMODE = 7
local R_EMODE = 8
local PA_EMODE = 9
local PD_EMODE = 10
local PS_EMODE = 11
local PR_EMODE = 12
-- edit modes as above 
local emode = OFF_EMODE
local eop = 0
local modop = 0
local enote = 0

-- settings mode 
local OFF_SMODE = 0
local L1SEQ_SMODE = 1
local L2SEQ_SMODE = 2
local L3SEQ_SMODE = 3
local L4SEQ_SMODE = 4
-- settings mode variable
local smode = OFF_SMODE

local buttons_down = {}


local vel = 1.0

-- current count of active voices
local nvoices = 0
-- kria
--
local k
local note_off_list = {}
local ids = 10000
local clock_count = 1
local clocked = true
local preset_mode = false

function make_note(track,n,oct,dur,tmul,rpt,glide) 
		x = 0
		y = 0
    id = ids
		ids = ids + 1
		hz = esea.getHz(n,oct)
		vel = 0.7
    makenote(1,id,track,hz,vel,x,y) 
		print("[" .. track .. "] Note " .. n .. "/" .. oct .. " for " .. dur .. " repeats " .. rpt .. " glide " .. glide  )
		-- ignore repeats and glide for now 
		table.insert(note_off_list,{ timestamp = clock_count + (dur * tmul), id = id,hz = hz,track = track}) 
end

function init()
	clk:add_clock_params()
	params:add_separator()
	params:add{type="option",name="Note Sync",id="note_sync",options={"Off","On"},default=2, action=nsync}
	params:add{type="option",name="Loop Sync",id="loop_sync",options={"None","Track","All"},default=1, action=lsync}
	params:add_separator()
	islandsparams.add_params()
  MT.add_params()
	-- for k,p in pairs(params.params) do 
	--	v.action = function(v) gridredraw(); p.action(v) end 
	-- end
	k = kria.loadornew("ansible/kria.data")
	--k = kria.new()
  k:init(make_note)
  clk.on_step = step
  clk.on_select_internal = function() clk:start() end
  -- clk.on_select_external = reset_pattern
	params:add_separator()
	params:add_number("clock_ticks", "clock ticks", 1, 96,1)
  params:bang()
  -- grid refresh timer, 15 fps
  -- metro_grid_redraw = metro.alloc(function(stage) gridredraw() end, 1 / 15)
  -- metro_grid_redraw:start()
  if g then gridredraw() end
  screen_refresh_metro = metro.alloc()
  screen_refresh_metro.callback = function(stage)
		gridredraw()
    redraw()
  end
  screen_refresh_metro:start(1 / screen_framerate)
end

function step()
	clock_count = clock_count + 1
	table.sort(note_off_list,function(a,b) return a.timestamp < b.timestamp end)
	while note_off_list[1] ~= nil and note_off_list[1].timestamp <= clock_count do
		print("note off " .. note_off_list[1].id)
    makenote(0,note_off_list[1].id,note_off_list[1].track,note_off_list[1].hz,0.7,0,0) 
		table.remove(note_off_list,1)
	end
	if clock_count % params:get("clock_ticks") == 0 then 
	   if clocked then 
		   k:clock()	
	   end
	end
end

function g.event(x, y, z)
	if mode == SEQ_MODE then 
	    k:event(x,y,z)
			gridredraw()
			return
	end
  if y ==8  then
		if mode == PLAY_MODE then
			if x >= 8 and x<= 12 then 
				-- sequencers have {8-12,8} as controls
				-- in PLAY Mode only 
				sequencer[current_layer]:event(x,y,z)
			else
				control_row_play(x,y,z)
			end
		elseif mode == EDIT_MODE then
			-- make an edit control row in a bit
			control_row_play(x,y,z)
		end
  else
		-- play or edit func
		if mode == PLAY_MODE then
			play_notes(x,y,z)
		elseif mode == EDIT_MODE then 
			edit_sound(x,y,z)
		elseif mode == SETTINGS_MODE then
			-- settings_event(x,y,z)
		end
  end
  gridredraw()
end

function gridredraw()
  g.all(0)
	-- display current layer - common to everything
  g.led(current_layer,8,10)
	if mode == PLAY_MODE then 
		draw_playnotes()
		draw_control_row_play()
	elseif mode == EDIT_MODE then 
		draw_soundedit()
		draw_control_row_edit()
	elseif mode == SEQ_MODE then 
		-- not made yet
		if preset_mode then 
			k:draw_presets(g)
		else 
			k:draw(g)
		end
	elseif mode == SETTINGS_MODE then 
	  draw_settings()
	end
  g:refresh()
end

function enc(n,delta)
  if n == 1 then
    mix:delta("output", delta)
  end
	if mode == PLAY_MODE then 
		if n == 2 then 
				vel = vel + (delta/200)
				if vel < 0 then 
					vel = 0.0
				elseif vel > 1 then 
					vel = 1.0
				end
	end
	elseif mode == EDIT_MODE then 
		edit_enc(n,delta)
	elseif mode == SETTINGS_MODE then
		settings_enc(n,delta)
	end 
end

function key(n,z)
	-- using the keys to switch between modes 
	-- 2    play <--> edit 
	-- 3    play <--> seq 
	-- 2 + 3   - settings mode 
	if z == 1 then 
		buttons_down[n] = true
	else
		buttons_down[n] = false
	end
	if n == 2 and z == 1 then 
		if mode == PLAY_MODE then
			 mode = EDIT_MODE 
		elseif mode == SEQ_MODE then 
			 mode = EDIT_MODE
		elseif mode == EDIT_MODE then 
			 mode = PLAY_MODE 
		elseif mode == SETTINGS_MODE then
			 mode = PLAY_MODE
		end
	elseif n ==3 and z == 1 then
		if mode == PLAY_MODE then
			 mode = SEQ_MODE 
		elseif mode == EDIT_MODE then 
			 mode = SEQ_MODE
		elseif mode == SEQ_MODE then 
			 mode = PLAY_MODE
		elseif mode == SETTINGS_MODE then
			 mode = SEQ_MODE
		end
	end
	if z == 1 then
	  if (n == 2 and buttons_down[3] == true ) or (n==3 and buttons_down[2] == true ) then 
			mode = SETTINGS_MODE
		end
	end
end

function redraw()
  screen.clear()
  screen.aa(0)
  screen.line_width(1)
	-- top line is mode line and common to all modes 
	-- except settings
	if mode ~= SETTINGS_MODE then
		local layn = "Layer: " 
		screen.move(0,10)
		screen.text(layn .. current_layer)
	end
	screen.move(100,10)
	if mode == PLAY_MODE then 
		screen.text("play")
		screen_playnotes()
	elseif mode == EDIT_MODE then
		screen.text("edit")
		screen_editsound()
	elseif mode == SEQ_MODE then 
		screen.text("seq")
	elseif mode == SETTINGS_MODE then 
	  screen.move(90,10)
		screen.text("settings")
		screen_settings()
	end 
  screen.update()
end



function cleanup()
end

function control_row_play(x,y,z) 
	if x >=1 and x <=4 then
		-- switch layer 
		-- if notes pressed - can't change layer
		-- for k,v in pairs(lit[current_layer]) do
		--	print("lit notes")
		--	return
		-- end
		current_layer = x
	elseif y == 16 then
		engine.stopAll()
	end
end

function draw_control_row_play() 
	-- sequencers are meant to draw 
	-- (and listen for)
	-- their own controls 
	-- they are given 8,8-12 for the moment 
	-- this ISN'T policed 
	-- they are just meant to be good citizens
	sequencer[current_layer]:draw_control_row(g)
	

end

--------------------------------------------------------------
----  Play Notes  Mode 
--------------------------------------------------------------
--

function screen_playnotes()
	local i = 2
	local cnt = 0
	local ln = "Notes:"
	for k,v in pairs(lit[current_layer]) do
		ln = ln .." " .. esea.note_name(v.x,v.y) 
		cnt = cnt + 1
		if cnt == 7 then 
				screen.move(0,10*i)
				screen.text(ln)
				cnt = 0
				i = i + 1
				ln = "     "
		end
	end
  screen.move(0,10*i)
  screen.text(ln)
	screen.move(0,10*5)
	screen.text("Velocity " .. vel)
end

function draw_playnotes()
	for x = 1,16 do
		for y = 1,7 do
			 g.led(x,y,esea.note_colour(x,y))
		end
	end
  for i,e in pairs(lit[current_layer]) do
		if e ~= nil then
   	   g.led(e.x, e.y,15)
	  end
  end
end

function play_notes(x,y,z)
  local e = {}
  e.id = x*8 + y
  e.x = x
  e.y = y
  e.state = z
  grid_note(e,current_layer)
end

function makenote(state,id,layer,hz,vel,x,y) 
	if state == 1 then 
	print("engine start " .. layer .. " " .. id .. " " .. hz .. " " .. vel )
   engine.start(layer,id, hz,vel)
   lit[current_layer][id] = {}
   lit[current_layer][id].x = x
   lit[current_layer][id].y = y
	else
	 lit[current_layer][id] = nil
   engine.stop(layer,id)
	end
end

function grid_note(e,layer)
  local note = ((7-e.y)*5) + e.x
	local hz = esea.getHzET(note)
	if layer == nil then
		 layer = current_layer
	end
  if e.state > 0 then
    if nvoices < MAX_NUM_VOICES then
      makenote(1,e.id,layer,hz,vel,e.x,e.y) 
			sequencer[current_layer]:watch(makenote,1,e.id,hz,vel,layer,e.x,e.y)
      nvoices = nvoices + 1
    end
  else
    if lit[current_layer][e.id] ~= nil then
      makenote(0,e.id,layer,hz,vel,e.x,e.y)
			sequencer[current_layer]:watch(makenote,0,e.id,hz,vel,layer,e.x,e.y)
     	lit[current_layer][e.id] = nil
      nvoices = nvoices - 1
    end
  end
  gridredraw()
end


--------------------------------------------------------------
----  Sound Edit Mode 
--------------------------------------------------------------
--

local edit_display = {
	[OFF_EMODE] = function()
			return "Press parameter to edit"
	end,
	[CARRIER_EMODE] = function()
			local r = params:get("l" .. current_layer .. "_carrier" .. eop) 
			return "Carrier " .. eop .. " out: " .. r .. " dbs"
	end,
	[MATRIX_EMODE] = function()
			local r = params:get("l" .. current_layer .. "_hz"..(eop).."_to_hz"..modop) 
			return eop .. " --> " .. modop .. ": " .. string.format("%.2f",r) 
	end,
	[FREQ_EMODE] = function()
			local r = params:get("l" .. current_layer .. "_hz" .. eop) 
			local p = params:get("l" .. current_layer .. "_phase" .. eop) 
			return "Freq " .. eop .. " "  .. string.format("%.2f",r) .. " (" .. string.format("%.2f",p) .. ")"
	end,
	[AMP_EMODE] = function()
			local r = params:get("l" .. current_layer .. "_amp" .. eop) 
			local v = params:get("l" .. current_layer .. "_vels" .. eop) 
			return "Amp " .. eop .. " " .. r .. " (" .. v .. ")"
	end,
	[A_EMODE] = function()
			local r = params:get("l" .. current_layer .. "_opAmpA" .. eop ) 
			return "Attack " .. eop .. ": " .. r 
	end,
	[D_EMODE] = function()
			local r = params:get("l" .. current_layer .. "_opAmpD" .. eop ) 
			return "Decay " .. eop .. ": " .. r 
	end,
	[S_EMODE] = function()
			local r = params:get("l" .. current_layer .. "_opAmpS" .. eop )
			return "Sustain " .. eop .. ": " .. r 
	end,
	[R_EMODE] = function()
			local r = params:get("l" .. current_layer .. "_opAmpR" .. eop ) 
			return "Release " .. eop .. ": " .. r 
	end,
  default = function()
		  return "unknown"
	end,
}

function screen_editsound()
	-- if not in an EMODE do we want 
	-- to display some help ? 
	--
	-- display parameters to edit 
	screen.move(15,30)
	screen.text(edit_display[emode]())
end

function edit_sound(x,y,z)

	if x == 1 and y <= 6 and z == 1 then 
			emode = CARRIER_EMODE
			eop = y
	elseif x == 1 and y <= 6 and z == 0 then 
			-- emode = OFF_EMODE
			-- eop = 0
	end
	if x >= 3 and x <= 8 and y >= 1 and y <= 6 and z == 1 then 
			emode = MATRIX_EMODE
			eop = x - 2
			modop = y
	elseif x >= 3 and x <= 8 and y >= 1 and y <= 6 and z == 0  then 
			-- emode = OFF_EMODE
	end
	if z == 1 then 
			if x == 10 then 
				emode = FREQ_EMODE
				eop = y
			elseif x == 11 then 
				emode = AMP_EMODE
				eop = y
			elseif x == 13 then 
				emode = A_EMODE
				eop = y
			elseif x == 14 then 
				emode = D_EMODE
				eop = y
			elseif x == 15 then 
				emode = S_EMODE
				eop = y
			elseif x == 16 then 
				emode = R_EMODE
				eop = y
			end
	elseif z == 0 and x >= 10 and x <= 16 then 
			-- experimentaly - don't turn off 
			-- param edit on key lift 
			-- just leave us in that mode
			-- emode = OFF_EMODE
			-- eop = 0
	end
	if x == 2 and y == 7 and z == 1 then
      engine.start(current_layer,16, esea.getHzET(math.random(15) + math.random(15) + 30 ),0.7)
			enote = 1
	elseif x == 2 and y == 7 and z == 0 then
			engine.stop(current_layer,16)
			enote = 0
	end
end

function edit_enc(n,delta)
	if n == 2 then 
		if emode == CARRIER_EMODE then
			-- carriers 
			params:delta("l" .. current_layer .. "_carrier" .. eop,delta)
		elseif emode == MATRIX_EMODE then 
			params:delta("l" .. current_layer .. "_hz"..eop.."_to_hz"..modop,delta) 
		elseif emode == FREQ_EMODE then 
			params:delta("l" .. current_layer .. "_hz"..eop,delta) 
		elseif emode == AMP_EMODE then 
			params:delta("l" .. current_layer .. "_amp"..eop,delta) 
		elseif emode == A_EMODE then 
			params:delta("l" .. current_layer .. "_opAmpA".. eop ,delta) 
		elseif emode == D_EMODE then 
			params:delta("l" .. current_layer .. "_opAmpD".. eop ,delta) 
		elseif emode == S_EMODE then 
			params:delta("l" .. current_layer .. "_opAmpS".. eop ,delta) 
		elseif emode == R_EMODE then 
			params:delta("l" .. current_layer .. "_opAmpR".. eop ,delta) 
		end
	end
	if n == 3 and emode == FREQ_EMODE then 
	  params:delta("l" .. current_layer .. "_phase"..(eop),delta) 
	elseif n == 3 and emode == AMP_EMODE then 
	  params:delta("l" .. current_layer .. "_vels"..(eop),delta) 
	end
end

function draw_soundedit()
	local v,r
	if enote == 1 then
		g.led(2,7,15)
	end
	for j = 1,6 do 
			r = params:get("l" .. current_layer .. "_carrier" .. j) 
      v = (r*15.0) 
			g.led(1,j,math.floor(v))
	end
	for i = 3,8 do
		for j = 1,6 do 
			r = params:get("l" .. current_layer .. "_hz"..(i-2).."_to_hz"..j) 
      v = ((r/6.3)*13) + 2
			g.led(i,j,math.floor(v))
		end
	end
	-- frequency 
	for j = 1,6 do 
			r = params:get("l" .. current_layer .. "_hz"..j) 
			v = ((r/5)*13)+2
	    g.led(10,j,math.floor(v))
	end
	-- amplitude
	for j = 1,6 do 
			r = params:get("l" .. current_layer .. "_amp"..j) 
			v = ((r/5)*13)+2
	    g.led(11,j,math.floor(v))
	  g.led(11,j,2)
	end
	-- env a 
	for j = 1,6 do 
			r = params:get("l" .. current_layer .. "_opAmpA".. j ) 
			v = ((r/5)*13)+2
	    g.led(13,j,math.floor(v))
	end
	-- env d 
	for j = 1,6 do 
			r = params:get("l" .. current_layer .. "_opAmpD".. j ) 
			v = ((r/5)*13)+2
	    g.led(14,j,math.floor(v))
	end
	-- env s
	for j = 1,6 do 
			r = params:get("l" .. current_layer .. "_opAmpS".. j ) 
			v = ((r/5)*13)+2
	    g.led(15,j,math.floor(v))
	end
	-- env r
	for j = 1,6 do 
			r = params:get("l" .. current_layer .. "_opAmpR".. j ) 
			v = ((r/5)*13)+2
	    g.led(16,j,math.floor(v))
	end
	--for i = 13,16 do
	--	for j = 1,6 do 
	--		g.led(i,j,2)
	--	end
	--end
end

function draw_control_row_edit() 

end

--------------------------------------------------------------
----  Settings Mode 
--------------------------------------------------------------
--

local settings_display = {
}

function draw_settings() 
	local v,r
	--for j = 1,4 do 
	--		r = params:get("l" .. j .. "_seq_type") 
  --    v = ((r/3.0)*15.0) 
	--		g.led(2,j+1,math.floor(v))
	-- end
end

function screen_settings()
	screen.move(15,30)
	screen.text("unused")
end

function settings_enc(n,delta)
end

function settings_event(x,y,z)
end


