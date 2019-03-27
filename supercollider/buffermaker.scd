// need to make a buffer to work in
// I'm lazy so I just make one and reuse it. If you want to be fancy
// you'll need to put the rest of the code following buffer creation into
// the callback
b = Buffer.alloc(s,2048);

// this is the function that makes the wavetables
// hardwired as 2048 - you can edit the number above and below
// if you want more.
// I'm finding I still get a lot of aliasing - I guess better to use bandlimited
// version of the functions than the absolute ones I'm using but sod it - bit of judicious
// eq takes away the worst of it for my purposes
//
// funnction args are:
//   buffer
//   name of file (path is hardwired below - you'll need to edit it to suit )
//   function  with args x,old,i  - same as wavefill
//   startrange and endrange - same as signal.wavefill (see if you can guess why ;-) )


(
~maketable = {
	arg b,n,fn,startrange,endrange;
	a = Signal.newClear(2048);
	a.waveFill(fn , startrange,endrange);

	b.setn(0,a);

	b.write("/Volumes/Untitled/Users/mark williamson/Music/supercollider/wavetables/" + n + ".aif",headerFormat: "aiff", sampleFormat: "int24", numFrames: -1, startFrame: 0, leaveOpen: false);
}
)

// just mamking your standard waves
// numbering the files lets you control the order they get loaded

~maketable.value(b,"01_sin" , { arg x, old, i; sin(x)} , 0 , 2pi );
~maketable.value(b,"02_saw" , { arg x, old, i; 2 * (x - floor(0.5 + x)) }, 0.0, 1.0 );
~maketable.value(b,"03_tri" , { arg x, old, i; (2 * abs(2 * (x - floor(0.5 + x)))) - 1 }, 0.0, 1.0);
~maketable.value(b,"04_sqr" , { arg x, old, i; 2 * (( 2 * floor (x)) - floor( 2 * x )) + 1 }, 0.0, 1.0);

// now demo them

~wsv = SoundFile.collectIntoBuffers("/Volumes/Untitled/Users/mark williamson/Music/supercollider/wavetables/*.aif");

// little test - assumes you've loaded the 4 files above into buffers 0,3 (edit first arg of VOsc with first
// buffer number if not

(
SynthDef(\test,{ arg out=0,len=20,note=42;
    var x,y,wavepos,fltfreq,osc,freq,flt,env;
	env = EnvGen.kr(Env.perc(len/2,len/2,1.0,4),doneAction: 2);
	freq = midicps(note);
	wavepos = MouseX.kr(0,3);
	fltfreq = MouseY.kr(10,15000);
	osc =  VOsc.ar(0 + wavepos, freq: freq ,mul: 0.05);
 	flt = BMoog.ar(osc ,fltfreq, 0.05);
	Out.ar(out,flt * env );
}).play;
);


