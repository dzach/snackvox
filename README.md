# Snackvox

A software Voice Operated Switch.
Based on the Snack Sound Toolkit and written in the Tool Command Language, TCL.

### Dependencies:
- <a href='https://www.speech.kth.se/snack/index.html'>Snack 2.2.10</a>, TCL package
- [TCL 8.6](https://www.tcl.tk/software/tcltk/8.6.html)

### Principle of operation:

![how does it work](https://github.com/dzach/snackvox/blob/master/img/howdoesitwork.png)

Diagram description:

- time progresses from left to right
- *th* follows *t0*, trailing it by head time (*fH* frames).
- At *f1* the level drops below the trigger level, but hold 
  frames (*fh*) keep the event going.
- At *f2* the level rises again above trigger level.
- At *f3* the level drops again below trigger level.
- At *t4* the hold frames are exhausted, and the sound event ends.
- *Head* (*fH*) and *tail* (*fT*) frames are prepended and appended to the body.
- *th* marks the start of the head frames and *tt* the end of the 
  tail frames. These become the *start* and *end* pointers of the
  sound event. 

### Short description of operation:

The **switch** function works by examining the incoming audio for the presense of a sound. If a sound exists and is above a set trigger level, or if a sound has just dropped below the trigger level but no *-hold* time has yet passed, then the switch is **on**. If the sound has been below the trigger level for more than *-hold* seconds, then the switch is **off**. The transitions between the **on** and **off** states define a **sound event**. 

At the beginning and the end of a sound event, the *-oncommand* and *-offcommand* callback routines are called, if defined, with the following arguments: *sound* object, *start* sample, *end* sample, *minlevel*, *maxlevel*, *onframes*, *continuous* **on** frames. However, certain arguments, i.e. *end*, *maxlevel*, *onframes*, *continuous*, have only meaning with the *-offcommand*.

The *-offcommand* callback can make use of the *start* and *end* values and, for example, further examine and/or save the sound event to disk.

The *activate* command acts similarly to a power knob; it turns on the widget and activates an internal timer which kicks in at frequent intervals and allows snackvox to continuously examine the contents of the widget's sound object. 

The **voice switch** functionality of the widget is independent from the *activate* command; it is turned on and off with the *start* and *stop* commands. This helps monitor the incoming sound without necessarily invoking the callback routines.

During each cycle of the detection process, the contents of the sound object, i.e. the sound samples, are segmented into **frames**. A *-head* length of past audio is kept in the sound object, as snackvox progresses through each frame. Each frame's maximum level value is written to *-levelvariable*. Then:

- If the switch is *stop*'ped, the process goes immediately into sleep, waiting for another cycle to come.
- If the switch has been *start*'ed, the process continues by examining the trigger criteria, as described above.
	- When a sound rises above the trigger level, the *start* pointer is set pointing *-head* seconds into the past audio, and the *-oncommand* callback routine is called.
	- If a sound drops momentarily below the trigger level for less than *-hold* seconds and then rises again, the process continues.
	- If a sound drops for more than *-hold* seconds below the trigger level, then this is deemed the end of the sound. The *end* pointer is set to point *-tail* seconds after the last **on** frame, and the *-offcommand* callback is called. The *start* and *end* pointers define the extent of the sound event.

Keeping *-head* seconds of past audio prior to a trigger allows snackvox to capture the very start of a sound event, even if the sound is still below the trigger level.

### Coding ###
Create the widget with:

```
snack::vox ?pathName? ?option value ...? 

where 'option' may be any of:

-buffer        : max length of the snackvox sound object, defaults to 30.0 seconds. Sounds lasting more than *-buffer* seconds are segmented to multiple sound events of maximum *-buffer* length.
-device        : audio device to use, defaults to the first audio input device found
-head          : prepend sound that happened '-head' decimal seconds before the trigger
-oncommand, 
-offcommand    : vox switch callback scripts, user definable
-tail          : append sound that happended '-tail' decimal seconds after the sound went off
-threshold     : trigger level setting
-thresholdvariable :
                 variable name to read the threshold value from
-levelvariable : contains max sound level measured during a frame

```

Commands (see the comming [manual](http://)):

*pathName* activate
*pathName* deactivate
*pathName* cget option
*pathName* configure ?option ?value? ?option value ...??
*pathName* start
*pathName* stop
*pathName* destroy

### Example code: ###

Monitor the audio level (helps with getting a value for a *-threshold* setting):
```
package re snackvox
proc monitor {var args} {
	puts -nonewline [format \r%6s [set $var]]
	flush stdout
}
snack::vox vox1
trace add variable [vox1 cget -levelvariable] write monitor
vox1 activate
update
vwait forever
```

Echo the input and display the **on** and **off** events:
```
package re snackvox
proc monitor {var args} {
	puts -nonewline [format \r%6s [set $var]]
	flush stdout
}
# use a separate sound objuct to echo the recorded sound, while still monitoring the input
sound s1
# create a snackvox widget
snack::vox vox1 -threshold 5000 -oncommand {apply {args {
	puts \ton\t[dict get $args minlevel]
}}} -offcommand {apply {args {
	s1 copy [dict get $args sound] -start [dict get $args start] -end [dict get $args end]
	s1 play
	puts \toff\t[dict get $args maxlevel]
}}}
# monitor the input level
trace add variable [vox1 cget -levelvariable] write monitor
vox1 activate
vox1 start
# start TCL's event loop
update
vwait forever
```
