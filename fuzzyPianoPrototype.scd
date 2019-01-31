//setup MIDI
MIDIClient.disposeClient;
MIDIClient.init(1, 1);
MIDIClient.sources;
s.control
~in = MIDIIn.connect;
~out = MIDIOut.new(0);
~out.latency = 0;



//handle incoming midi messages, add delay and change velocity with gaussian random numbers

//var randomTimeDelta, randomVelocityDelta;
~delayDeviation = 0.01;
~velocityDeviation = 5;
~randomTimeDelta = Pgauss(0,~delayDeviation,inf);
~randomVelocityDelta = Pgauss(0, ~velocityDeviation,  inf);

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


//gui for midi and changing the standard deviation of the gaussian distribution

~lastSelectedOutputItem = -1;
~lastSelectedInputItem = -1;
w = Window.new("Midi Settings", Rect(100, 100, 680, 550));
w.view.decorator = FlowLayout(w.view.bounds);

m = EZListView(w, 240@240, "Midi inputs", margin:10@5, labelHeight:60);
MIDIClient.sources.do({|item, index|
	m.addItem(item.name, {|a| a.value.postln;
		if(~lastSelectedInputItem >= 0, {~in.disconnect(0, ~lastSelectedInputItem)});
		~in.connect(0,MIDIClient.sources.at(a.value));
		~lastSelectedInputItem = a.value;
	} );
	index.postln;
});

l = EZListView(w, 240@240, "Midi outputs", margin:10@5, labelHeight:60);
MIDIClient.destinations.do({|item, index|
	l.addItem(item.name, {|a| a.value.postln;
		if(~lastSelectedOutputItem >= 0, {("disconnecting: " ++ ~lastSelectedOutputItem).postln;
			~out.disconnect(~lastSelectedOutputItem);});
		("connecting: " ++ a.value).postln;
		~out.connect(a.value);
		~lastSelectedOutputItem = a.value;
	} );
	index.postln;55
});

~delaySlider = EZSlider.new(w, 90@400, "Delay standard deviation in s", ControlSpec(0.001, 1),labelWidth:80, labelHeight:60, layout:'vert', margin:10@5);
~delaySlider.action = {|a| ~randomTimeDelta.dev = ~delaySlider.value;
};

~velocitySlider = EZSlider.new(w, 90@400, "Velocity Standard Deviation in Velocity Numbers", ControlSpec(1, 10), labelWidth:80, labelHeight:60, layout:'vert', margin:10@5 );
~velocitySlider.action = {|a| ~randomVelocityDelta.dev = a.value};

w.front;



//cleanup, auskommentieren und ausführen bevor man den oberen teil nochmal ausführt. alternativ den interpreter neu starten
/*(
~on.free;
~off.free;
)
*/