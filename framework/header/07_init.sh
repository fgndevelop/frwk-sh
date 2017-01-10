# Strictly report errors and unset variables
# This requires the following:
#  
# When working with positional parameters: 
#  use ${1-} to avoid error messages when using positional parameters
#
# When dealing with variables:
#  Use [ -z ${var+x} ] to check if a variable is set before using it
#  The result is true, if the variable is unset, false otherwise
#
# see http://www.redsymbol.net/articles/unofficial-bash-strict-mode/
# for details
#
# CAVE: pipefail
# Since "pipefail" is not overly portable it is not set here.
# Either set it yourself or see:
# http://unix.stackexchange.com/questions/14270/get-exit-status-of-process-thats-piped-to-another

set -o nounset
set -o errexit

# Make sure IFS is what we expect it to be.
# (Unsetting IFS makes IFS default to ' \t\n' in many, but not all shells.
# Do NOT use bashism here, see
#  https://wiki.ubuntu.com/DashAsBinSh#I_am_a_developer._How_can_I_avoid_this_problem_in_future.3F
_sfw_old_ifs=$IFS
IFS=$(printf ' \t\n')

# Set exit and interrupt traps
trap _sfw_cleanup EXIT
set_interrupt _sfw_interrupt_handler

# Check whether "--help or -V/--version" is on the cmdline
_sfw_help_version_check "$@"
unset _sfw_help_version_check

# Even if a script does not use commands, there might be a 
# requirement for a certain number of arguments, e.g. a filename
# Hence if a minimum number of arguments is defined (via the Makefile),
# it will automatically be checked
if [ -n "$_sfw_min_args" ]; then
  [ $# -lt $_sfw_min_args ] && usage_error "missing command line argument"
fi

# For ease of development, the Makefile provides the variable SCRIPT_CMD_LIST 
# All words in that variable are considered valid commands to the script
# If a SCRIPT_CMD_LIST was provided, "cmd" is now set to the command provided
# on the command line or we exit with error

if [ -n "$_sfw_cmd_list" ]; then 

  # No cmdline arguments => no valid command
  [ -z ${1+x} ] && usage_error "missing command"

  # Now scan the whole SCRIPT_CMD_LIST
  for cmd in $_sfw_cmd_list; do
    [ "$cmd" = "$1" ] && break
  done

  # To avoid setting a flag in the for-loop to indicate a valid command was found,
  # we simply check the _sfw_cmd against $1 again to find out why the loop finished
  [ "$cmd" = "$1" ] || usage_error "invalid command <$1>"

  # Now remove the command from the cmdline and adjust relevant variables
  shift 1
  argc=$((argc-1))
fi

# Finally, save the command line arguments to an internal list so we can 
# provide command line arguments anywhere in the script. Each argument is
# quoted so that even whitespace containing arguments will be returned intact
# See argv() for details

for arg in "$@"; do 
  _sfw_cmdline_arg_list="${_sfw_cmdline_arg_list:-} '${arg}'"
done
_sfw_cmdline_arg_list="${_sfw_cmdline_arg_list# }"
unset arg

