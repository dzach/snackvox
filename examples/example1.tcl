package require snackvox
proc monitor {var args} {
	puts -nonewline [format \r%6s [set $var]]
	flush stdout
}
snack::vox vox1
trace add variable [vox1 cget -levelvariable] write monitor
vox1 activate
update
vwait forever
