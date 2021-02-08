module vargus

// parse_flags is the main flag parser
// it parses all flags in the osargs
fn parse_flags(cmd &Commander, osargs []string, gflags []FlagArgs) ([]string, []FlagArgs) {
	mut flags := []FlagArgs{}
	mut args := osargs.clone()
	mut all_flags := cmd.flags.clone()

	// append
	all_flags << gflags

	// extract values
	for i in osargs {
		for ic, c in all_flags {
			mut x := c

			long := '--$c.name'
			short := '-$c.short_arg'

			if i.starts_with(long) || i.starts_with(short) {
				// check if equals sign is used
				if '=' in i {
					y := args[args.index(i)].split('=')
					flag := y[0]
					value := y[1]

					if flag == long || flag == short {
						// simple validation for set values on flags
						match x.data_type {
							.string_var {
								x.value = value
							}
							.integer {
								if int_validator(value) {
									x.value = value
								} else {
									value_err(flag, 'int')
								}
							}
							.float {
								if float_validator(value) {
									x.value = value
								} else {
									value_err(flag, 'float')
								}
							}
							.boolean {
								if value == 'false' || value == 'true' {
									// do nothing
								} else {
									// if the value set is not equal to true or false,
									// show value error
									value_err(flag, 'bool')
								}
							}
						}

						// append new flag w/ value to flags
						flags << x

						// remove old flag w/ value from all
						all_flags.delete(ic)

						// remove from osargs
						args.delete(args.index(i))
					}
				} else {
					value := args[args.index(i)+1] or {
						''
					}

					if i == long || i == short {
						// simple validation for set values on flags
						val := args[args.index(value)] or {
							if x.data_type != .boolean {
								// show blank error
								blank_err(i)
							}
							'' // it is needed, 
						}

						// validate values
						match x.data_type {
							.string_var {
								x.value = val
							}
							.integer {
								if int_validator(val) {
									x.value = value
								} else {
									value_err(i, 'int')
								}
							}
							.float {
								if float_validator(val) {
									x.value = value
								} else {
									value_err(i, 'float')
								}
							}
							.boolean {
								if value == 'false' || value == 'true' {
									x.value = value
								} else {
									// if the value set is not equal to true or false,
									// parse it but next arg will be parsed to args
									x.value = 'true'
								}
							}
						}

						// append new flag w/ value to flags
						flags << x

						// remove old flag w/ value from all
						all_flags.delete(ic)

						// remove from osargs
						if value != '' {
							// only delete from args if flag data_type is not boolean
							if x.data_type != .boolean {
								args.delete(args.index(value))
							}
						}
						
						if i in args {
							args.delete(args.index(i))
						} else {
							// show blank error
							blank_err(osargs[osargs.index(i)-1])
						}
					}
				}
			}
		}
	}

	
	prsd_helper_flags := parse_helper(all_flags)

	// append parsed flags from helper
	flags << prsd_helper_flags

	return args, flags
}

// parse_helper is a helper to the main parser
// it verifies values of flags and checks if they are required or not
fn parse_helper(flags []FlagArgs) []FlagArgs {
	mut fl := flags.clone()

	for mut i in fl {
		if i.value == '' {
			// if required show error
			if i.required == true {
				required_err(i.name, i.short_arg)
			}

			// otherwise, set value with default
			i.value = i.default_value
		}
	}

	return fl
}