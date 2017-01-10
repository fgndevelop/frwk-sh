#
# Global variables used by the Shell Script Framework and it's functions.
# In order to minimize namespace conflicts, variables as well as framework-internal
# functions are prefixed with "_sfw_". This accounts for function's local variables,
# too as they inherit variables local to the caller which is another possible source
# of namespace conflicts. "_sfw_"-variables are not meant to be referenced directly
# from the main script.
#
# Variables are mostly initialized by sfw_init or the Makefile
#

# Generic script information
_sfw_script_name="@SCRIPT_NAME@"						
_sfw_script_version="@SCRIPT_VERSION@"				
_sfw_synopsis="@SCRIPT_SYNOPSIS@"				
_sfw_man_section="@MAN_SECTION@"
_sfw_man_title="@MAN_TITLE_LOWER@"

# Copyright and license information, appended to the version information
_sfw_copyright="@COPYRIGHT@"
_sfw_license="@LICENSE@"
_sfw_copying="@COPYING@"
_sfw_warranty="@WARRANTY@"

# Variables used for command line argument handling
_sfw_cmd_list="@SCRIPT_CMD_LIST@"			# The script's cmdlist
_sfw_min_args=@SCRIPT_MIN_ARGS@				# required number of arguments to the script
_sfw_cmdline_arg_list=""				# Command line arguments, will be set at the end of header

# User-defined cleanup hook that will be called on exit
_sfw_user_exit_hook=""

# Global variables for the user (i.e. script programmer)
argc=$#							# Number of cmdline arguments

