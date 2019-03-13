##
## Voice (sound) operated switch, VOX
##
## using the Snack Sound Toolkit's sound objects
## http://www.speech.kth.se/snack/index.html
##
## Copyright © 2004-2019, Dimitrios Zachariadis
## Licensed under a BSD type license
##
#
# Create with:
# snack::vox <widget-name> ?option value ...?, where 'option' may be any of:
# 	-buffer        : max length of the vox sound object, defaults to 30 seconds
# 	-device        : audio device to use, defaults to the first audio input device found
# 	-head          : prepend sound that happened '-head' seconds before the trigger
# 	-oncommand, 
# 	-offcommand    : vox switch callback scripts, user definable
# 	-tail          : append sound that happended '-tail' seconds after the sound went off
# 	-threshold     : trigger level setting
# 	-thresholdvariable :
# 	                 if provided, it will be used instead of the internal variable
# 	                 to facilitate setting by e.g. a Tk scale widget
# -levelvariable   : indicates max sound level measured during a sound frame
#
if {[catch {package req sound}]} {
	error "package sound is required"
}
namespace eval ::snack::vox {
	variable {}
	array set {} {
		cnt 0
	}
	interp alias {} vox {} ::snack::vox
}

namespace eval ::snack::vox {
	variable {}

# namespace ::snack::vox
proc bufferfull w {
	namespace upvar [namespace parent]::${w} {} v
	##
	## reset pointers
	##
	##   |                                  highwater_s -->|
	##   |+++++++++++++++++++++++++++++++++++++++++++++++++|
	##   |      <cut this>       |  <headlen_s>  |  body   |
	##   |++++++++++++++++++++++++++++++++++++++++++++++++++
	##   0             head_p -->|                 fs_p -->|
	##   this will become '0' ---^                         |
	##             this will be the current frame start ---^
	##
	if {$v(state) && [llength $v(-offcommand)]} {
		eval $v(-offcommand) sound $v(snd) start $v(head_p) end [expr {$v(fs_p) - 1}] minlevel $v(minlev) maxlevel $v(maxlev) onframes $v(onframes) continuous $v(continuous_f)
		$v(snd) cut 0 [expr {$v(fs_p) - 1}]
		# reset state
		set v(state) 0
		set v(maxlev) 0
		set v(onframes) 0
		set v(fs_p) 0
		set v(continuous_f) 0
		set v(curcont_f) 0
	} else {
		set v(fs_p) [expr {$v(fs_p) - $v(head_p)}]
		# cut the sound up to the head_p pointer
		$v(snd) cut 0 [expr {$v(head_p) - ($v(head_p) > 1)}]
	}
	# sound now has a new length
	# reset head to the start of the sound
	set v(head_p) 0
}

# namespace ::snack::vox
proc detect w {
	## accumulate sound and set moving pointers to sound frames,
	##   as time progresses
	## This should be run as a coroutine
	namespace upvar [namespace parent]::${w} {} v
	set me [info coroutine]
	while {1} {
		# nlen_s : length of new sound added to the sound object
		#   just before we were called
		# v(fs_p) : pointer to the first sample of this frame
		set nlen_s [expr {[$v(snd) length] - $v(fs_p)}]
		# v(flen_s) is the frame length in samples
		#puts "[$v(snd) length] - $v(fs_p)"
		while {$nlen_s >= $v(flen_s)} {
			# assign frame start and end sample pointers and flags
			set fend_p [expr {$v(fs_p) + $v(flen_s) - 1}]
			#puts state=$v(state)\t$v(fs_p)\t$fend_p
			## -----------------------------------------------
			## sound event detection
			## -----------------------------------------------
			# notify user about signal level
	#		set $v(-levelvariable) [expr {
	#			max([$v(snd) max -start $v(fs_p) -end $fend_p],
	#			abs([$v(snd) min -start $v(fs_p) -end $fend_p]))
	#		}]
			set $v(-levelvariable) [expr {round(100 * [
				::tcl::mathfunc::max {*}[$v(snd) power -start $v(fs_p) -end $fend_p]
			])}]
			# Are we just monitoring the sound level?
			if {!$v(vox)} {
				# no other action is required. Advance the frame start pointer
				if {[$v(snd) length] >= $v(highwater_s)} {
					bufferfull $w
				}
				# update head_p
				if {$v(fs_p) - $v(head_p) >= $v(headlen_s)} {
					# we've got enough samples for the head, so
					# advance the head_p pointer
					set v(head_p) [expr {$v(fs_p) - $v(headlen_s)}]
				}
				incr v(fs_p) $v(flen_s)
				set nlen_s [expr {$nlen_s - $v(flen_s)}]
				# carry on with the next frame
				continue
			}
			## -----------------------------------------------
			## event body calculation
			##
			## In the end, the sound extracted from the event will look like this:
			##      ____________________________________________________
			##     |              |                      |              |
			##     | head segment |      event body      | tail segment |
			##     |______________|______________________|______________|
			##
			## sound event : a sound becoming louder than a trigger level, and staying louder
			##               for -hold seconds
			## head segment: prepended sound that happened -head seconds before the trigger
			## tail segment: appended sound that happended -tail seconds after the sound 
			##               went off
			##
			## -----------------------------------------------
			# set trigger state
			set sig [expr {
				[set $v(-levelvariable)] > [set $v(-thresholdvariable)]? 1:0
			}]
			if {$v(state) == 0} { # we have been in a quiet state so far
				if {$sig} {        # state = 0, sig = 1, we just detected a sound
					set v(state) 1
					# set counter for hold and tail frames
					set v(holdcnt_f) $v(hold_f)
					set v(tailcnt_f) $v(tail_f)
					# run user callback
					if {[llength $v(-oncommand)]} {
						eval $v(-oncommand) sound $v(snd) start $v(head_p) end $fend_p minlevel $v(minlev) maxlevel [set $v(-levelvariable)] onframes 0 continuous 0
					}
					# start counting 'on' frames
					incr v(onframes)
					incr v(curcont_f)
					set v(maxlev) [::tcl::mathfunc::max $v(maxlev) [set $v(-levelvariable)]]

				} else {         # stete = 0, sig = 0, still quiet here
					# update min level from this quiet frame
					set v(minlev) [expr {round(100 * [
						::tcl::mathfunc::min {*}[$v(snd) power -start $v(fs_p) -end $fend_p]
					])}]
					# update head_p
					if {$v(fs_p) - $v(head_p) >= $v(headlen_s)} {
						# we've got enough samples for the head, so
						# advance the head_p pointer
						set v(head_p) [expr {$v(fs_p) - $v(headlen_s)}]
					}
					set v(curcont_f) 0
				}
			} else {             # state >= 1
				if {$sig} {      # state >= 1,  sig = 1
					# sound is still on, so restart the hold_f and tail_f counters
					set v(holdcnt_f) $v(hold_f)
					set v(tailcnt_f) $v(tail_f)
					# count 'on' frames
					incr v(onframes)
					incr v(curcont_f)
					if {$v(curcont_f) > $v(continuous_f)} {
						set v(continuous_f) $v(curcont_f)
					}
					# reset state. could have been '2'
					set v(state) 1
					set v(maxlev) [::tcl::mathfunc::max $v(maxlev) [set $v(-levelvariable)]]

				} else {         # state >= 1,  sig = 0
					# transition from an 'on' to an 'off' condition
					# count down tail frames
					incr v(tailcnt_f) -1
					# have we reach the tail target?
					if {$v(tailcnt_f) == 0} { # happens once, values can go negative
						## tail frames count reached, set the end pointer for the sound event
						set v(end_p) $fend_p
						set v(state) 2
					}
					# count down hold frames, waiting for some more sound
					incr v(holdcnt_f) -1
					# reset current continous frame count
					set v(curcont_f) 0
					# done with hold time ?
					if {$v(holdcnt_f) <= 0 && $v(state) == 2} {
						## hold ended with no more sound and tail target reached
						if {[llength $v(-offcommand)]} {
							# soundObj start_sample end_sample onframes postproc
							eval $v(-offcommand) sound $v(snd) start $v(head_p) end $v(end_p) minlevel $v(minlev) maxlevel $v(maxlev) onframes $v(onframes) continuous $v(continuous_f)
						}
						# reset state
						set v(state) 0
						set v(onframes) 0
						set v(maxlev) 0
						set v(minlev) Inf
						set v(head_p) $v(end_p)
						set v(continuous_f) 0
					}
				}
			}
			# advance v(fs_p) by one frame length of samples
			incr v(fs_p) $v(flen_s)
			# update sound length
			set nlen_s [expr {[$v(snd) length] - $v(fs_p)}]
		}
		# max sound length reached?
		#puts "[$v(snd) length] >= $v(highwater_s)"
		if {[$v(snd) length] >= $v(highwater_s)} {
			bufferfull $w
		}
		# gather sound for some time, and come back in detect again
		set v(tick) [after $v(frame_ms) [list $me]]
		yield
	}
}

# namespace ::snack::vox
proc getopt {w opt} {
	namespace upvar [namespace parent]::${w} {} v
	if {![string match "-*" $opt] || ![info exists v($opt)]} {
		set opts [lsort -dict [array names v -*]]
		error "unknown option \"$opt\": must be [join [lrange $opts 0 end-1] {, }] or [lindex $opts end]"
	}
	return $v($opt)
}

# namespace ::snack::vox
proc handle {w cmd args} {
	# handle vox subcommands
	namespace upvar [namespace parent]::${w} {} v

	if {[llength $args] % 2} {
#		return -code error "wrong # args: should be $w $cmd ?option value ...?"
	}
	switch -glob -- $cmd {
		act* { # activate vox, but only if it is deactiveted
			if {[llength $v(coro)]} return
			$v(snd) flush
			set v(fs_p) 0
			set v(head_p) 0
			$v(snd) rec -device $v(-device)
			set v(coro) [namespace parent]::${w}::coro
			coroutine $v(coro) [namespace current]::detect $w
			# coroutine will be called by tick timer at regular intervals
		}
		dea* { #deactivate
			# stop vox detecting
			after cancel $v(tick)
			# stop vox recording
			$v(snd) stop
			# delete the coroutine
			rename $v(coro) {}
			set v(coro) {}
			return
		}
		conf* {
			if {![llength $args]} {
				# return the option values
				return [lsort -dict -stride 2 [array get v -*]]
			} elseif {[llength $args] == 1} {
				# return just this option value
				return [getopt $w [lindex $args 0]]
			} else {
				# set the options to the provided values
				dict for {k o} $args {
					if {![string match "-*" $k] || ![info exists v($k)]} {
						error "Unknown option $k. Should be one of [lsort -dict [array names v -*]]"
					}
				}
			}
			array set v $args
			# update internal options
			updateopts $w
			return
		}
		cget {
			if {[llength $args] != 1} {
				error "wrong # args. Should be $w cget option"
			}
			return [getopt $w [lindex $args 0]]
		}
		sta* { # start vox operation
			set v(vox) 1
		}
		sto* { # stop vox operation, monitor stays on
			set v(vox) 0
		}
		des* { # destroy
			# cancel frame recording
			after cancel $v(tick)
			# destroy snack sound object
			catch {$v(snd) destroy}
			# delete all widget commands and variables
			namespace delete [namespace parent]::${w}
			rename $w {}
		}
		default {
			error "bad subcommand \"$cmd\": must be cget, configure, destroy, start or stop"
		}
	}
}

# namespace ::snack::vox
proc updateopts w {
	namespace upvar [namespace parent]::${w} {} v
	# set frame duration in ms
	set v(frame_ms) [expr {int(1000.0 * $v(flen_s) / $v(rate))}]
	# calculate the number of frames to wait for another signal, 
	#   after the sound just dropped below -threshold
	set v(hold_f) [expr {int($v(-hold) * 1000.0 / $v(frame_ms))}]
	# frames to append to sound body
	set v(tail_f) [expr {int($v(-tail) * 1000.0 / $v(frame_ms))}]
	# fremes to prepend to sound body
	set v(headlen_s) [expr {int($v(-head) * $v(rate))}]
	set v(highwater_s) [expr {int($v(-buffer) * $v(rate)) - $v(flen_s)}]
	set $v(-thresholdvariable) $v(-threshold)
}
# end of namespace ::snack::vox
}

proc ::snack::vox args {
	# create a snack sound object with vox capabilities
	# did the user provide a name for this widget?
	if {![llength $args] || [string match "-*" [lindex $args 0]]} {
		# no name was provided by the user, create one
		set w vox[incr (cnt)]
		while {[info command $w] ne {}} {
			set w vox[incr (cnt)]
		}
	} else {
		# widget name was provided by user
		set args [lassign $args w]
		if {[info command $w] ne {}} {
			error "command $w already exists"
		}
	}
	if {[llength $args] %2} {
		lassign [string map {:: { }} [info level [info level]]] a b c
		error "wrong #args. Should be [join [concat $a $b] "::"] $c ?option value ...?"
	}
	# create widget's options/variables. 
	# Options starting with a '-' are user readable/writable
	namespace eval [namespace current]::${w} {
		variable {}
		# flen_s         : frame length in samples
		# holdcnt_f      : counter for remaining hold frames
		# fs_p           : pointer to the first sample of a frame
		# bs_p           : pointer to the start frame of the sound body
		# state          : the current state of vox, on|off
		# hold           : the number of frames to hold vox on, vox tail
		# frame_ms       : time to record audio for detection of sound, in msec
		#
		array set {} {
			coro {}
			vox 1 rate 16000 flen_s 800 headlen_s 1600
			fs_p 0 bs_p 0 head_p 0 end_p 0
			hold_f 20 tail_f 10 holdcnt_f 20 tailcnt_f 10 continuous_f 0 curcont_f 0
			state 0 tick {} maxlev 0 minlev Inf
			-buffer 30
			-head 0.2
			-hold 1.5
			-oncommand {}
			-offcommand {}
			-tail 0.5
			-threshold 1500
		}
		# user requested squelch level variable
		set (-thresholdvariable) [namespace current]::sq
		# read only signal level variable
		set (-levelvariable) [namespace current]::lev
		set (-device) [lindex [snack::audio inputDevices] 0]
	}
	namespace upvar [namespace current]::${w} {} v

	set opts [lsort -dict [array names v -*]]
	dict for {k o} $args {
		if {$k ni $opts} {
			error "unknown option \"$k\": must be [
				join [lrange $opts 0 end-1] {, }] or [lindex $opts end]"
		}
	}
	array set v $args
	set $v(-levelvariable) 0
	vox::updateopts $w

	# the sound object
	set v(snd) [::snack::sound -channels 1 -rate $v(rate)]

	interp alias {} $w {} [namespace current]::vox::handle $w
	return $w
}
package provide snackvox 0.2.3

