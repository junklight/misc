-- Bowed MpE 
--
-- Requires an MPE controller
--
-- v0.1 - mark williamson - 5th October 2018 

local ControlSpec = require "controlspec"

engine.name = "MPEBow"

lights = {}

function init() 

	for i = 1,16 do
		lights[i] = false
  end

	midi_in_device = midi.connect(1)
	midi_in_device.event = midi_event

  params:add{type = "control", id = "reverb_mix", name = "Reverb Mix", controlspec = ControlSpec.new(0, 1, "lin", 0, 0.2, "")
, action = engine.reverbmix}

  params:add{type = "control", id = "reverb_time", name = "Reverb Time", controlspec = ControlSpec.new(0.1, 20, "exp", 0, 1, "")
, action = engine.reverbtime}


end


function redraw()
  screen.clear()
  
  for m = 1,16 do
    if lights[m] then
        l = l + 7
		else
				l = 2
    end
    for n = 1,5 do
      screen.rect(0.5+m*6, 0.5+n*6, 6, 6)
      if lights[m] then
				screen.fill()
			end
      screen.level(l)
      screen.stroke()
    end
  end
  
  screen.update()
end

function midi_event(data)

	--print("Here")	
  if #data == 0 then return end
  
  local msg = midi.to_msg(data)
  local chan = msg.ch
  

	--print("type",msg.type);
    
				-- Note off
				if msg.type == "note_off" then
				engine.noteOff(chan)
				lights[chan] = false
				redraw()

				-- Note on
				elseif msg.type == "note_on" then
				engine.noteOn(chan,msg.note, msg.vel)
				lights[chan] = true
				redraw()

				-- Key pressure
				-- elseif msg.type == "key_pressure" then
				-- set_key_pressure(msg.note, msg.val / 127)

				-- Channel pressure
				elseif msg.type == "channel_pressure" then
				engine.pressure(chan,msg.val / 127)

				-- Pitch bend
				elseif msg.type == "pitchbend" then
				local bend_st = (util.round(msg.val / 2)) / 8192 * 2 -1 -- Convert to -1 to 1
				engine.pitchbend(chan,bend_st * 48) -- 48 Semitones of bend

        elseif data[1] & 0xf0 == 176 and data[2] == 74 then
				local slide_st = data[3]/127.0
				engine.slide(chan,slide_st)

				else
								-- print("-")
								-- print(tab.print(msg))
								print(msg.type)
								print("-")
								print(tab.print(data))
								print(data[1] & 0xf0 )

				end
  
  
end


