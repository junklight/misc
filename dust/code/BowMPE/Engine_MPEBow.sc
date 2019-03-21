// CroneEngine_PolyPerc
// sine with perc envelopes, triggered on freq
Engine_MPEBow : CroneEngine {
    // synth stuff
	  var bowd;
    var amp=0;
		var force=0;
		var pos=0.07;
	  var c1=0.25;
    var c3=31;
    var pan=0;
		var bend = 0;
    var reverbBus;
    var reverb;
		var sboardBus;
		var soundb;
		var shapebuf;
    // voice stuff 
	  // MPE gives us 15 voices 
    // just have a slot for each one 
    // mapping channel number to voice number
    var voices;
    // put all voices into a single group
    // for global stuff
    var voiceGroup;

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {
					// voice stuff
          voiceGroup = ParGroup.new(context.xg);
					// yes yes I know - but basically I want to use 
					// channel number as an index so 0 & 1 don't get used 
					// and 2-16 are all voices 
    		  voices=Array.fill(17,nil);

					// shaper function
					shapebuf = Buffer.alloc(context.server, 512, 1, {arg buf; buf.chebyMsg([0.25,0.5,0.25], false)});
	

					// Reverb 
					reverbBus = Bus.audio(context.server, 2);
					sboardBus = Bus.audio(context.server,2 );

					reverb = SynthDef(\effectd,{ 
									arg mix=0.5,size=100,time=4;
									var sigi = In.ar(reverbBus,2);
									var revrb = GVerb.ar(sigi,size,time); 
									var sigo = ((1 - mix) * sigi) + (mix * revrb);
									sigo = LPF.ar(in: sigo, freq: 14000);
								  sigo = CompanderD.ar(in: sigo, thresh: 0.4, slopeBelow: 1, slopeAbove: 0.25, clampTime: 0.002, relaxTime: 0.01);
									sigo = tanh(sigo).softclip;
									Out.ar(context.out_b, sigo); 
					}).play(target:context.xg);

					// one soundboard for all voices 
					soundb = SynthDef(\soundbrd, {
									  var son;
										son = In.ar(sboardBus,1);
										son = DWGSoundBoard.ar(son);
										son = BPF.ar(son,118,1)+son;
										son = BPF.ar(son,430,1)+son;
										son = BPF.ar(son,490,1)+son;
										son = LPF.ar(son,6000);
										Out.ar(reverbBus , Pan2.ar(son * 0.05 , pan));
					}).play(target:context.xg);

					// this is the voice 

				  bowd = SynthDef(\bowed, { |out=0, freq=440, ldness=0,amp=0,force=1,dist=0, gate=1,pos=0.07,c1=0.25,c3=31,pan=0,bend=0|
										var vib = Gendy1.kr(1,1,1,1,0.1, 4,mul:0.003,add:1);
										var famp = Lag.kr(amp);
										var son = DWGBowedTor.ar(freq*vib*(2**(bend/12)), amp,force , gate,pos,0.1,c1,c3);
										var dson = Shaper.ar(shapebuf,son,0.5);        
										var mld = ldness - (ldness * dist);
										var mln = ldness - (mld/2);
										var outmix = son*Lag.kr(mln) + dson*Lag.kr(mld);
										Out.ar(sboardBus,outmix*0.7);
					}).add;

					// noteOn(channel,freq,vel)
					this.addCommand(\noteOn, "iff" , {
							arg msg;
							// convert midi note to hz
							// convert velocity to 0-1
							var ch=msg[1],freq=msg[2].midicps,vel=(( 127/msg[3]) * 0.5) + 0.4;
							var vol = ((127/msg[3])* 0.7) + 0.2;

							if (voices[ch].isNil , {
									// start new voice
									voices[ch] = Synth.new(\bowed,[\gate,1,\freq,freq,\ldness,0.2,\amp,0.2]).onFree({ voices[ch] = nil; });
									//voiceGroup.add(voices[ch]);
									} , { 
									// not sure this should happen 
									// note on without prior note off 
									// just set frequency of existing note 
									voices[ch].set(\freq,freq);
									voices[ch].set(\amp,vel);
									//voices[ch].set(\force,vel);
									voices[ch].set(\gate,1);
									});
					});

					// noteOff(channel)
					this.addCommand(\noteOff,"i" , {
							arg msg;
							var ch=msg[1];
							if (voices[ch].isNil != true , {
								voices[ch].set(\gate,0);});
					});

					// pitchbend(channel,semitones)
					this.addCommand(\pitchbend,"if", {
							arg msg;
							var ch=msg[1],b = msg[2];
							if (voices[ch].isNil != true, {
								voices[ch].set(\bend,b);});
					});

					// pressure(channel,i)
					this.addCommand(\pressure,"if" , {
							arg msg;
							var ch=msg[1],v = (msg[2] * 0.5 )+ 0.4;
							var vol = (msg[2]* 0.7) + 0.2;
							if (voices[ch].isNil != true , {
								voices[ch].set(\ldness,vol);
								voices[ch].set(\amp,v);
				      });
					});

					// slide(channel,i)
					this.addCommand(\slide,"if" , {
							arg msg;
							var ch=msg[1],v = msg[2] ;
							if (voices[ch].isNil != true , {
								voices[ch].set(\dist,v);
				      });
					});

					// reverb mix(f)
					this.addCommand(\reverbmix,"f" , {
							arg msg;
							var mx=msg[1];
							reverb.set(\mix,mx);
					});

					// reverb time(f)
					this.addCommand(\reverbtime,"f" , {
							arg msg;
							var mx=msg[1];
							reverb.set(\time,mx);
					});



	}
}
