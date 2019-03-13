package require snackvox
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
