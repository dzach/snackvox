# Snackvox

A software Voice (sound) Operated Switch.
Based on the Snack Sound Toolkit's objects and written in the Tool Command Language, TCL.

### Prerequisits:
	- [Snack 2.2.10](http://www.speech.kth.se/snack/index.html), TCL package
	- TCL 8.6

### Principle of operation:

![how does it work] (http://hs.local:3000/me/snackvox/raw/master/img/howdoesitwork.png)

### Short description of operation:

- time progresses from left to right
- *th* follows *t0*, trailing it by head time (*fH* frames).
- At *f1* the level drops below the trigger level, but hold 
  frames (*fh*) keep the event going.
- At *f2* the level raises again above trigger level.
- At *f3* the level drops again below trigger level.
- At *t4* the hold frames are exhausted, and the sound event ends.
- *Head* (*fH*) and *tail* (*fT*) frames are prepended and appended to the body.
- *th* marks the start of the head frames and *tt* the end of the 
  tail frames. These become the *start* and *end* pointers of the
  sound event. 

Due to the operation on frames, e.g. segments of sound, at a time, snackvox is able to keep sound that happened *before* the trigger time, thus avoiding cutting off the beginning of a sound event.

Create with:

```
snack::vox <widget-name> ?option value ...? 

where 'option' may be any of:

-buffer        : max length of the vox sound object, defaults to 30 seconds
-device        : audio device to use, defaults to the first audio input device found
-head          : prepend sound that happened '-head' seconds before the trigger
-oncommand, 
-offcommand    : vox switch callback scripts, user definable
-tail          : append sound that happended '-tail' seconds after the sound went off
-threshold     : trigger level setting
-thresholdvariable :
                 variable name to read the threshold value from
-levelvariable : contains max sound level measured during a frame

```
