module vargus

import os

// run is the main cli app executor
pub fn (mut c Commander) run() {
	// check if c is the root
	if c.is_root {
		// exclude the app from the os.args
		// the os.args[0] is the app itself, 
		c.runner(c.command, []FlagArgs{}, os.args[1..os.args.len], PersistentCmdHooks{}, CommandConfig{})
	} else {
		println('\n [!misused] .run() can only be used on a root commander')
		exit(1)
	}
}

// runner is the helper for the `run` function
//	scmd => string command
fn (c &Commander) runner(scmd string, gfls []FlagArgs, osargs []string, persistent_hooks PersistentCmdHooks, p_config CommandConfig) {
	mut gflags := gfls.clone()

	// append global flags
	gflags << c.global_flags

	// persistent hooks
	p_hooks := c.get_persistent_hooks(persistent_hooks)

	// parse configurations
	cfg := c.parse_config(p_config)

	if osargs.len > 0 {
		// help message ([--help, -h, help] flag)
		if osargs[0] in help {
			if cfg.use_custom_help {
				cfg.custom_help(scmd, c.flags, gflags)
			} else {
				c.help(scmd, c.flags, gflags)
			}
			exit(0)
		}

		if osargs[0] in c.sub_commands_string {
			for i in c.sub_commands {
				if i.command == osargs[0] {
					i.runner(scmd + ' $i.command', gflags, osargs[1..osargs.len], p_hooks, cfg)
					break
				}
			}
		} else {
			if !args_has_hyphen_dash(osargs[0]) && !c.allow_next_args {
				if osargs.len > 1 {
					if args_has_hyphen_dash(osargs[1]) {
						c.command_err(osargs[0])
					}
				}
			}
		}
	}
	// this will be called if nothing happened above
	args, flags := c.parse_flags(osargs, gflags)
	
	if c.exec_func {
		c.execute(args, flags, p_hooks)
	} else {
		if cfg.use_custom_help {
			cfg.custom_help(scmd, c.flags, gflags)
		} else {
			c.help(scmd, c.flags, gflags)
		}
	}

	// exit app
	exit(0)
}

// execute is the command function runner
// it executes the function associated to the command
fn (c &Commander) execute(args []string, flags []FlagArgs, p_hooks PersistentCmdHooks) {
	// run pre-* hooks
	if p_hooks.use_persistent_pre_run {
		p_hooks.persistent_pre_run(args, flags)
	}
	if c.hooks.use_pre_run {
		c.hooks.pre_run(args, flags)
	}

	// execute main function
	c.function(args, flags)

	// run post-* hooks
	if c.hooks.use_post_run {
		c.hooks.post_run(args, flags)
	}
	if p_hooks.use_persistent_post_run {
		p_hooks.persistent_post_run(args, flags)
	}
}
