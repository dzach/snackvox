# Snackvox

A software Voice Operated Switch.
Based on the Snack Sound Toolkit and written in the Tool Command Language, TCL.

### Dependencies:
- <a href='https://www.speech.kth.se/snack/index.html'>Snack 2.2.10</a>, TCL package
- [TCL 8.6](https://www.tcl.tk/software/tcltk/8.6.html)

### Principle of operation:
See the [wiki pages](https://github.com/dzach/snackvox/wiki/Principle-of-operation).
### Coding ###
Create the widget with:

```
snack::vox ?pathName? ?option value ...? 

where 'option' may be any of:

-buffer        : max length of the snackvox sound object, defaults to 30.0 seconds. 
                 Sounds lasting more than *-buffer* seconds are segmented to multiple 
		 sound events of maximum *-buffer* length.
-device        : audio device to use, defaults to the first audio input device found.
-head          : prepend sound that happened '-head' decimal seconds before the trigger.
-oncommand, 
-offcommand    : callback scripts
-tail          : append sound that happended '-tail' decimal seconds after the sound went off
-threshold     : trigger level setting
-thresholdvariable :
                 variable name to read the threshold value from. Defaults to an internal name.
-levelvariable : variable name for reading max sound levels per frame. Defaults to an internal name.

```

Commands:
```
*pathName* activate
*pathName* deactivate
*pathName* cget option
*pathName* configure ?option ?value? ?option value ...??
*pathName* start
*pathName* stop
*pathName* destroy
```

### Example code: ###

NOTE: TCL should be able to find the package *snackvox*, e.g. by including the directory where it is stored in the *::auto-path* variable.

[example 1](https://github.com/dzach/snackvox/blob/master/examples/example1.tcl) : Monitor the audio level (helps with getting a value for a *-threshold* setting):

[expample 2](https://github.com/dzach/snackvox/blob/master/examples/example1.tcl) : Echo the input and display the **on** and **off** events:
