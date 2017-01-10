#
# Printing information and error messages in sfw scripts. These functions
# are provided in order to unify output throughout the script whenever
# runtime messages or errors have to be provided to the user.
#

# This function is meant for internal use only and does not check arguments.
# ALL runtime output goes to stderr, so it can easily be suppressed / distinguished
# from application output
_sfw_print_msg () { printf "%s: %s\n" $_sfw_script_name "$*" >&2; }

# Generic runtime information can be printed using this function. All it does
# is to prepend the script's name to the given text
# 
# Usage:
# runtime_msg <message>

runtime_msg()
{
  # Argument check 
  [ -z ${1+x} ] && debug "Missing argument to function call: runtime_error()"
  
  # Pretty message
  _sfw_print_msg "$*" 
}

# Type of error: usage_error
# The user made a mistake in the usage of the script, most of the time this
# happens when fiddeling with command line arguments. Hence along with the
# actual error message information on how to get further help is provided.
# The error message is printed to stderr
#
# Usage:
# usage_error <error message>

usage_error()
{	
  # Argument check 
  [ -z ${1+x} ] && debug "missing argument to function call: usage_error()"

  # Print error message, give advice
  _sfw_print_msg "$*" 
  echo "Try '$_sfw_script_name --help' for more information." >&2
  exit 1
} 

# Type of error: runtime_error
# This function is for errors that occured outside of the script's
# responsibility. Since it's not a syntactical error, no additional
# information is displayed (main difference to usage_error)
#
# Usage:
# runtime_error <error message>

runtime_error()
{
  # Argument check 
  [ -z ${1+x} ] && debug "Missing argument to function call: runtime_error()"

  # Pretty error message
  _sfw_print_msg "$*"
} 

# Output an internal error. The programmer made a mistake, so a
# bug report help message is printed, too.
#
# Usage:
# debug <message>

debug ()
{
  # Now this really shouldn't happen 
  [ -z ${1+x} ] && debug "Missing argument to function call: debug()"

  # Print error and bug report message
  _sfw_print_msg "$*"
  _sfw_print_msg "Command line: $_sfw_cmdline_arg_list"
  _sfw_print_msg "Report this bug to: @SCRIPT_BUGREPORT@"
  exit 1
} 
