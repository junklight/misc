// 4 part multitimbral synth 
// based originally on PolySub
// 
// 4 sets of parameter busses giving 4 layers
// each layer can have different settings hence different sounds 

Engine_MT7 : CroneEngine {

	classvar <sdef;
  classvar <paramDefaults;
	classvar <maxNumVoices;

	var <l1_ctlBus; // collection of control busses for layer 1
	var <l2_ctlBus; // collection of control busses for layer 2
	var <l3_ctlBus; // collection of control busses for layer 3
	var <l4_ctlBus; // collection of control busses for layer 4
	var <mixBus; // audio bus for mixing synth voices
	var <l1_gr; // parent group for layer 1 voice nodes
	var <l2_gr; // parent group for layer 2 voice nodes
	var <l3_gr; // parent group for layer 3 voice nodes
	var <l4_gr; // parent group for layer 4 voice nodes
	var <l1_voices; // collection of voice nodes for layer 1
	var <l2_voices; // collection of voice nodes for layer 2
	var <l3_voices; // collection of voice nodes for layer 3
	var <l4_voices; // collection of voice nodes for layer 4

	*initClass {
		maxNumVoices = 16;
		StartUp.add {
      paramDefaults = Dictionary.with(
        \amp -> -12.dbamp, \amplag -> 0.02,
        \hz1 -> 1, \hz2 -> 2, \hz3 -> 0, \hz4 -> 0, \hz5 -> 0, \hz6 -> 0,
        \amp1 -> 1,\amp2 -> 0.5,\amp3 -> 0.3,\amp -> 1,\amp5 -> 1,\amp6 -> 1,
        \phase1 -> 0,\phase2 -> 0,\phase3 -> 0,\phase4 -> 0,\phase5 -> 0,\phase6 -> 0,
        \ampAtk -> 0.05, \ampDec -> 0.1, \ampSus -> 1.0, \ampRel -> 1.0, \ampCurve -> -1.0,
        \hz1_to_hz1 -> 0, \hz1_to_hz2 -> 0, \hz1_to_hz3 -> 0, \hz1_to_hz4 -> 0, \hz1_to_hz5 -> 0, \hz1_to_hz6 -> 0,
        \hz2_to_hz1 -> 0, \hz2_to_hz2 -> 0, \hz2_to_hz3 -> 0, \hz2_to_hz4 -> 0, \hz2_to_hz5 -> 0, \hz2_to_hz6 -> 0,
        \hz3_to_hz1 -> 0, \hz3_to_hz2 -> 0, \hz3_to_hz3 -> 0, \hz3_to_hz4 -> 0, \hz3_to_hz5 -> 0, \hz3_to_hz6 -> 0,
        \hz4_to_hz1 -> 0, \hz4_to_hz2 -> 0, \hz4_to_hz3 -> 0, \hz4_to_hz4 -> 0, \hz4_to_hz5 -> 0, \hz4_to_hz6 -> 0,
        \hz5_to_hz1 -> 0, \hz5_to_hz2 -> 0, \hz5_to_hz3 -> 0, \hz5_to_hz4 -> 0, \hz5_to_hz5 -> 0, \hz5_to_hz6 -> 0,
        \hz6_to_hz1 -> 0, \hz6_to_hz2 -> 0, \hz6_to_hz3 -> 0, \hz6_to_hz4 -> 0, \hz6_to_hz5 -> 0, \hz6_to_hz6 -> 0,       
	\carrier1 -> 1,\carrier2 -> 1,\carrier3 -> 0,\carrier4 -> 0,\carrier5 -> 0,\carrier6 -> 0,
	\opAmpA1 -> 0.05, \opAmpD1 -> 0.1, \opAmpS1 -> 1.0, \opAmpR1 -> 1.0, \opAmpCurve1 ->  -1.0,
	\opAmpA2 -> 0.05, \opAmpD2 -> 0.1, \opAmpS2 -> 1.0, \opAmpR2 -> 1.0, \opAmpCurve2 ->  -1.0,
	\opAmpA3 -> 0.05, \opAmpD3 -> 0.1, \opAmpS3 -> 1.0, \opAmpR3 -> 1.0, \opAmpCurve3 ->  -1.0,
	\opAmpA4 -> 0.05, \opAmpD4 -> 0.1, \opAmpS4 -> 1.0, \opAmpR4 -> 1.0, \opAmpCurve4 ->  -1.0,
	\opAmpA5 -> 0.05, \opAmpD5 -> 0.1, \opAmpS5 -> 1.0, \opAmpR5 -> 1.0, \opAmpCurve5 ->  -1.0,
	\opAmpA6 -> 0.05, \opAmpD6 -> 0.1, \opAmpS6 -> 1.0, \opAmpR6 -> 1.0, \opAmpCurve6 ->  -1.0;
      );

      sdef  = SynthDef.new(\ifm7, {
        // args for whole instrument
        arg out, amp=0.2, amplag=0.02, gate=1, ivel=0.1,hz,
        // operator frequency multiplier. these can be partials or custom intervals
        hz1=1, hz2=2, hz3=0, hz4=0, hz5=0, hz6=0,
        // operator amplitudes
        amp1=1,amp2=0.5,amp3=0.3,amp4=1,amp5=1,amp6=1,
				// velocity sensitivity for ops 
				vels1=1,vels2=1,vels3=1,vels4=1,vels5=1,vels6=1,
        // operator phases
        phase1=0,phase2=0,phase3=0,phase4=0,phase5=0,phase6=0,
        // phase modulation params
        hz1_to_hz1=0, hz1_to_hz2=0, hz1_to_hz3=0, hz1_to_hz4=0, hz1_to_hz5=0, hz1_to_hz6=0,
        hz2_to_hz1=0, hz2_to_hz2=0, hz2_to_hz3=0, hz2_to_hz4=0, hz2_to_hz5=0, hz2_to_hz6=0,
        hz3_to_hz1=0, hz3_to_hz2=0, hz3_to_hz3=0, hz3_to_hz4=0, hz3_to_hz5=0, hz3_to_hz6=0,
        hz4_to_hz1=0, hz4_to_hz2=0, hz4_to_hz3=0, hz4_to_hz4=0, hz4_to_hz5=0, hz4_to_hz6=0,
        hz5_to_hz1=0, hz5_to_hz2=0, hz5_to_hz3=0, hz5_to_hz4=0, hz5_to_hz5=0, hz5_to_hz6=0,
        hz6_to_hz1=0, hz6_to_hz2=0, hz6_to_hz3=0, hz6_to_hz4=0, hz6_to_hz5=0, hz6_to_hz6=0,
	// boolean if the carrier is output
	carrier1=1,carrier2=1,carrier3=0,carrier4=0,carrier5=0,carrier6=0,
	// operator amplitude envelopes
	opAmpA1=0.05, opAmpD1=0.1, opAmpS1=1.0, opAmpR1=1.0, opAmpCurve1= -1.0,
	opAmpA2=0.05, opAmpD2=0.1, opAmpS2=1.0, opAmpR2=1.0, opAmpCurve2= -1.0,
	opAmpA3=0.05, opAmpD3=0.1, opAmpS3=1.0, opAmpR3=1.0, opAmpCurve3= -1.0,
	opAmpA4=0.05, opAmpD4=0.1, opAmpS4=1.0, opAmpR4=1.0, opAmpCurve4= -1.0,
	opAmpA5=0.05, opAmpD5=0.1, opAmpS5=1.0, opAmpR5=1.0, opAmpCurve5= -1.0,
	opAmpA6=0.05, opAmpD6=0.1, opAmpS6=1.0, opAmpR6=1.0, opAmpCurve6= -1.0;

        var ctrls, mods, osc, op_env, chans, chan_vec, osc_mix, opEnv1, opEnv2, opEnv3, opEnv4, opEnv5, opEnv6,kilnod;

	opEnv1 = EnvGen.kr(Env.adsr(opAmpA1,opAmpD1,opAmpS1,opAmpR1,1.0, opAmpCurve1),gate,doneAction:0);
	opEnv2 = EnvGen.kr(Env.adsr(opAmpA2,opAmpD2,opAmpS2,opAmpR2,1.0, opAmpCurve2),gate,doneAction:0);
	opEnv3 = EnvGen.kr(Env.adsr(opAmpA3,opAmpD3,opAmpS3,opAmpR3,1.0, opAmpCurve3),gate,doneAction:0);
	opEnv4 = EnvGen.kr(Env.adsr(opAmpA4,opAmpD4,opAmpS4,opAmpR4,1.0, opAmpCurve4),gate,doneAction:0);
	opEnv5 = EnvGen.kr(Env.adsr(opAmpA5,opAmpD5,opAmpS5,opAmpR5,1.0, opAmpCurve5),gate,doneAction:0);
	opEnv6 = EnvGen.kr(Env.adsr(opAmpA6,opAmpD6,opAmpS6,opAmpR6,1.0, opAmpCurve6),gate,doneAction:0);

        // the 6 oscillators, their frequence, phase and amplitude
	ctrls = [[ Lag.kr(hz * hz1,0.01), phase1, Lag.kr(amp1 * vels1.max(0.01) * ivel ,0.01) * opEnv1    ],
                 [ Lag.kr(hz * hz2,0.01), phase2, Lag.kr(amp2,0.01) * opEnv2 * (vels2.max(0.01) * ivel) ],
                 [ Lag.kr(hz * hz3,0.01), phase3, Lag.kr(amp3,0.01) * opEnv3 * (vels3.max(0.01) * ivel) ],
                 [ Lag.kr(hz * hz4,0.01), phase4, Lag.kr(amp4,0.01) * opEnv4 * (vels4.max(0.01) * ivel) ],
                 [ Lag.kr(hz * hz5,0.01), phase5, Lag.kr(amp5,0.01) * opEnv5 * (vels5.max(0.01) * ivel) ],
                 [ Lag.kr(hz * hz6,0.01), phase6, Lag.kr(amp6,0.01) * opEnv6 * (vels6.max(0.01) * ivel) ]];

        // All the operators phase modulation params
        mods = [[hz1_to_hz1, hz2_to_hz1, hz3_to_hz1, hz4_to_hz1, hz5_to_hz1, hz6_to_hz1],
                [hz1_to_hz2, hz2_to_hz2, hz3_to_hz2, hz4_to_hz2, hz5_to_hz2, hz6_to_hz2],
                [hz1_to_hz3, hz2_to_hz3, hz3_to_hz3, hz4_to_hz3, hz5_to_hz3, hz6_to_hz3],
                [hz1_to_hz4, hz2_to_hz4, hz3_to_hz4, hz4_to_hz4, hz5_to_hz4, hz6_to_hz4],
                [hz1_to_hz5, hz2_to_hz5, hz3_to_hz5, hz4_to_hz5, hz5_to_hz5, hz6_to_hz5],
                [hz1_to_hz6, hz2_to_hz6, hz3_to_hz6, hz4_to_hz6, hz5_to_hz6, hz6_to_hz6]];

        // returns a six channel array of OutputProxy objects
        osc = FM7.ar(ctrls,mods);
        chan_vec = [carrier1,carrier2,carrier3,carrier4,carrier5,carrier6];
        osc_mix = Mix.new(chan_vec.collect({|v,i| osc[i]*v}));
        amp = Lag.ar(K2A.ar(amp ), amplag);
      	kilnod = DetectSilence.ar(osc_mix, 0.01, 0.2, doneAction:2);
        Out.ar(out, (osc_mix * amp).dup);
      });

			CroneDefs.add(sdef);


		} // Startup
	} // initClass

	*new { arg context, callback;
		^super.new(context, callback);
	}

	alloc {
			// add  in synth

		  //--------------
		  //--- voice control, all are indexed by arbitarry ID number
		  // (voice allocation should be performed by caller)
			// not sure if I need groups or not  
			// but lets us kill all groups 
			// grouped by layer (do we want to put them all in a higher parent group?)
			// guessing these are parallel groups because we are 
			// using supernova 
				
  		l1_gr = ParGroup.new(context.xg);
  		l2_gr = ParGroup.new(context.xg);
  		l3_gr = ParGroup.new(context.xg);
  		l4_gr = ParGroup.new(context.xg);

	  	l1_voices = Dictionary.new;
	  	l2_voices = Dictionary.new;
	  	l3_voices = Dictionary.new;
	  	l4_voices = Dictionary.new;
	  	l1_ctlBus = Dictionary.new;
	  	l2_ctlBus = Dictionary.new;
	  	l3_ctlBus = Dictionary.new;
	  	l4_ctlBus = Dictionary.new;

			// setup control busses for each layer
			// fairly sure we don't need to set defaults
		  sdef.allControlNames.do({ arg ctl;
			  var name = ctl.name;
			  // postln("control name: " ++ name);
			  if((name != \gate) && (name != \hz) && (name != \ivel) && (name != \out), {
			  	l1_ctlBus.add(name -> Bus.control(context.server));
			  	l1_ctlBus[name].set(paramDefaults[name]);
			  	l2_ctlBus.add(name -> Bus.control(context.server));
			  	l2_ctlBus[name].set(paramDefaults[name]);
			  	l3_ctlBus.add(name -> Bus.control(context.server));
			  	l3_ctlBus[name].set(paramDefaults[name]);
			  	l4_ctlBus.add(name -> Bus.control(context.server));
			  	l4_ctlBus[name].set(paramDefaults[name]);
			  });
		  });

		  // start a new voice
			// layer, voiceid, freq
		  this.addCommand(\start, "iiff", { arg msg;
			  this.addVoice(msg[1], msg[2], msg[3],msg[4],true);
		  });


		  // stop a voice
			// layer , voiceid
		  this.addCommand(\stop, "ii", { arg msg;
			  this.removeVoice(msg[1],msg[2]);
		  });

	  	// free all synths
			// currently kills all voices in all layers
		  this.addCommand(\stopAll, "", {
		  	l1_gr.set(\gate, 0);
		  	l2_gr.set(\gate, 0);
		  	l3_gr.set(\gate, 0);
		  	l4_gr.set(\gate, 0);
		  	l1_voices.clear;
		  	l2_voices.clear;
		  	l3_voices.clear;
		  	l4_voices.clear;
		  });

	  	// generate commands to set each control bus
			// we create commands for each layer 
			// these will map to parameters for each layer 
			// because all layer busses are the same we can 
			// just us the first one
	  	l1_ctlBus.keys.do({ arg name;
	  		this.addCommand("l1_" ++ name, "f", { arg msg; l1_ctlBus[name].setSynchronous(msg[1]); });
	  		this.addCommand("l2_" ++ name, "f", { arg msg; l2_ctlBus[name].setSynchronous(msg[1]); });
	  		this.addCommand("l3_" ++ name, "f", { arg msg; l3_ctlBus[name].setSynchronous(msg[1]); });
	  		this.addCommand("l4_" ++ name, "f", { arg msg; l4_ctlBus[name].setSynchronous(msg[1]); });
	  	});

	}

	addVoice { arg layer,id, hz, ivel,map=true;
		var params = List.with(\out, context.out_b.index, \hz, hz , \ivel , ivel);
		var numVoices = l1_voices.size + l2_voices.size + l3_voices.size + l4_voices.size;
		//postln("num voices: " ++ numVoices);

		var voices,ctls;

		if ( layer == 1 , {
						voices = l1_voices;
						ctls = l1_ctlBus;
		});
		if ( layer == 2 , {
						voices = l2_voices;
						ctls = l2_ctlBus;
		});
		if ( layer == 3 , {
						voices = l3_voices;
						ctls = l3_ctlBus;
		});
		if ( layer == 4 , {
						voices = l4_voices;
						ctls = l4_ctlBus;
		});

		if(voices[id].notNil, {
			voices[id].set(\gate, 1);
			voices[id].set(\hz, hz);
			voices[id].set(\ivel, ivel);
		}, {
			if(numVoices < maxNumVoices, {
				ctls.keys.do({ arg name;
					params.add(name);
					params.add(ctls[name].getSynchronous);
				});
				
				voices.add(id -> Synth.new(\ifm7, params, l1_gr));
				voices[id].set(\ivel, ivel);
				NodeWatcher.register(voices[id]);
				voices[id].onFree({
					voices.removeAt(id);
				});

				if(map, {
					ctls.keys.do({ arg name;
						voices[id].map(name, ctls[name]);
					});
				});
			});
		});
	}

	removeVoice { arg layer,id;
		if (layer == 1 , {
		   if(true, { //voices[id].notNil, {
		  	l1_voices[id].set(\gate, 0);
		  	//voices.removeAt(id);
		  });
			});
		if (layer == 2 , {
		   if(true, { //voices[id].notNil, {
		  	l2_voices[id].set(\gate, 0);
		  	//voices.removeAt(id);
		  });
			});
		if (layer == 3 , {
		   if(true, { //voices[id].notNil, {
		  	l3_voices[id].set(\gate, 0);
		  	//voices.removeAt(id);
		  });
			});
		if (layer == 4 , {
		   if(true, { //voices[id].notNil, {
		  	l4_voices[id].set(\gate, 0);
		  	//voices.removeAt(id);
		  });
			});
	}

	free {
		l1_gr.free;
		l2_gr.free;
		l3_gr.free;
		l4_gr.free;
		l1_ctlBus.do({ arg bus, i; bus.free; });
		l2_ctlBus.do({ arg bus, i; bus.free; });
		l3_ctlBus.do({ arg bus, i; bus.free; });
		l4_ctlBus.do({ arg bus, i; bus.free; });
		l1_voices.do({ arg voice, i; voice.free; });
		l2_voices.do({ arg voice, i; voice.free; });
		l3_voices.do({ arg voice, i; voice.free; });
		l4_voices.do({ arg voice, i; voice.free; });
	}

} // class
