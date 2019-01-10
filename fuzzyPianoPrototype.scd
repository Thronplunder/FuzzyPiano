s.quit
//boot server and set up globals/reset everything
(
s.reboot.doWhenBooted({
	MIDIClient.disposeClient;
	MIDIClient.init;
	MIDIClient.destinations;

	MIDIIn.connectAll;
	~out = MIDIOut.new(0);
	~randomTimeDelta = Pgauss(0,0.01,inf);
	~randomVelocityDelta = Pgauss(0, 5,  inf);
})
)

//handle incoming midi messages, add delay and change velocity with gaussian random numbers
(
var randomTimeDelta, randomVelocityDelta;


randomTimeDelta = Pgauss(0,~delayDeviation,inf);
randomVelocityDelta = Pgauss(0, ~velocityDeviation,  inf);

//handle note on messages. change up velocity, resend them after a random delay
~on = MIDIFunc.noteOn({|vel, num, chan, src|
	var timeDelay, newVelocity;

	timeDelay = ~randomTimeDelta.asStream.next.abs;
	newVelocity = (vel + ~randomVelocityDelta.asStream.next).fold(0, 127);
	("Delay: " ++ timeDelay ++ " new Velocity: " ++ newVelocity).postln;
	SystemClock.sched(timeDelay, {
		"delayed noteOn".postln;
		~out.noteOn(chan, num, newVelocity);});

});
//handle note off messages
~off = MIDIFunc.noteOff({|vel, num, chan, src|
	var timeDelay, newVelocity;
	"noteOff received".postln;
	~out.noteOff(chan, num, vel);
});
)
//cleanup
(
~on.free;
~off.free;
)



//gui for midi and changinbg the standard deviation of the gaussian distribution
(
var lastSelectedItem = -1, delaySlider, velocitySlider;
w = Window.new("Midi Output", 650@4230, true, true, s);
w.view.decorator = FlowLayout(w.view.bounds);

l = EZListView(w, 240@240, "Midi outputs");
MIDIClient.destinations.do({|item, index|
	l.addItem(item.name, {|a| a.value.postln;
		if(lastSelectedItem > 0, {~out.disconnect(lastSelectedItem)});
		~out.connect(a.value);
		lastSelectedItem = a.value;
	} );
	index.postln;
});
c = FlowView.new(w, 200@400);

delaySlider = EZSlider.new(w, 80@400, "Delay standard deviation in s", ControlSpec(0.001, 1),labelWidth:80, labelHeight:40, layout:'vert');
delaySlider.action = {~randomTimeDelta.dev = delaySlider.value;};

velocitySlider = EZSlider.new(w, 80@400, "Velocity Standard Deviation", ControlSpec(1, 10), labelWidth:80, labelHeight:40, layout:'vert' );
velocitySlider.action = {~randomeVelocityDelta.dev = velocitySlider.value};

w.front;
)



//random tests, ignore
~delayDeviation
~out.uid
SystemClock.seconds
Pgauss(0, 1, 1).asStream.next.abs