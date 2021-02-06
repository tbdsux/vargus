module vargus

import os

// run is the main cli app executor
pub fn (mut c Commander) run() {
	// exclude the app from the os.args
	// the os.args[0] is the app itself, 
	c.runner([]FlagArgs{}, os.args[1..os.args.len])
}

// runner is the helper for the `run` function
fn (c &Commander) runner(gfls []FlagArgs, osargs []string) {
	mut x := osargs.clone()
	mut gflags := gfls.clone()

	// append global flags
	gflags << c.global_flags

	if osargs.len > 0 {
		if osargs[0] in c.sub_commands_string {
			for i in c.sub_commands {
				if i.command == osargs[0] {
					i.runner(gflags, osargs[1..osargs.len])
					break
				}
			}
		} else {
			args, flags := parse_flags(c, x, gflags)
			c.execute(c.function, args, flags)
		}
	} else {
		args, flags := parse_flags(c, x, gflags)
		c.execute(c.function, args, flags)
	}
}

// execute is the command function runner
// it executes the function associated to the command
fn (c &Commander) execute(f fn(args []string, flags []FlagArgs), args []string, flags []FlagArgs) {
	f (args, flags)
}