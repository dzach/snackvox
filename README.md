# Snackvox

A software Voice (sound) Operated Switch.
Based on the Snack Sound Toolkit's objects and written in the Tool Command Language, TCL.

### Dependencies:
- <a href='https://www.speech.kth.se/snack/index.html'>Snack 2.2.10</a>, TCL package
- [TCL 8.6](https://www.tcl.tk/software/tcltk/8.6.html)

### Principle of operation:

![how does it work](https://github.com/dzach/snackvox/blob/master/img/howdoesitwork.png)

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

snackvox manages to capture the very start of a sound event by storing frames of sound *before* the trigger happens.

Create the widget with:

```
snack::vox <widget-name> ?option value ...? 

where 'option' may be any of:

-buffer        : max length of the vox sound object, defaults to 30.0 seconds
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
