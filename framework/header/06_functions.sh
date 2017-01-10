# Generic functions that do not fit into one of the other categories
# but are part of the basic sfw framework. This is NOT the place
# for "nice to have" library functions 

# This function uses eval magic to split up a list of items that possibly contain
# whitespace. This function is required by argv() and also by the sfw_cli.sh library
# for the nopt_argv() function, see sfw_cli.sh for details. It is not meant to be 
# called directly as it does not do proper error checking 

# See also:
# http://www.linuxjournal.com/content/bash-preserving-whitespace-using-set-and-eval
#
# Usage: _sfw_get_arg_from_list <name of list> <N> <name of return variable>
# Returns: 
# 0 on success (with $return_variable = N-th argument)
# 1 on failure


# This function is meant to provide a single point of failure for both the
# argv() function from the generic sfw header as well as for the nopt_argv()
# function that is part of the sfw_cli.sh library
# It is not meant to be called directly and simply provides a consistent 
# argument check for both (argv and nopt_argv) use cases. 
#
# Usage _sfw_argv_wrapper <caller name> <arg list name> [arguments to the originating function call]
_sfw_get_arg_from_list() 
{
  local _sfw_caller _sfw_arg_list _sfw_numeric_arg _sfw_var_name _sfw_nth_arg

  # We only check rudimentarily for our "own" arguments and store them 
  [ $# -lt 2 ] && debug "illegal number of arguments to function call: _sfw_arg_wrapper()"
  _sfw_caller="$1"
  eval _sfw_arg_list="\$${2}"

  # We shift for easier reading. From now on we're dealing with the arguments
  # that were provided to the CALLING function (remember, this is a wrapper)
  # Hence we're performing argument checking on the caller's behalf
  shift 2

  # Now we check if the caller was called properly
  [ -z ${1+x} ] && debug "missing argument to function call: ${_sfw_caller}()"

  # Check if the argument is indeed numeric and if so, store it
  case "$1" in
    *[!0-9]*) debug "numeric argument to function call expected: ${_sfw_caller}()" ;;
  esac

  # Make sure N is >= 1 (this one is nasty, did YOU think of it ?)
  [ $1 -ge 1 ] && _sfw_numeric_arg=$1 || _sfw_numeric_arg=1

  # If there is another argument, the caller wants the result in a variable 
  [ -z ${2:+x} ] || _sfw_var_name=$2

  # Get the argument from the list using ev[ia]l magic
  # We WANT parameter expansion here so we do NOT quote
  eval set -- $_sfw_arg_list
  
  # If the numerical argument is out of range, we return right away
  # Otherwise we now have the Nth argument from the list and "set" it
  [ $_sfw_numeric_arg -le $# ] && eval set -- \$${_sfw_numeric_arg} || return 1

  # Let's see how the caller wants the result returned
  [ -z ${_sfw_var_name+x} ] && printf "%s\n" "$*" || eval $_sfw_var_name=\"$*\"

  return 0
}

# This function is the user level interface to command line arguments 
# It simply calls the sfw internal function _sfw_argv_wrapper, see above
# Usage: argv <N> [variable name]
# Returns:
argv() { _sfw_get_arg_from_list argv _sfw_cmdline_arg_list $@ && return 0 || return 1; }

# echo does, depending on the shell, support a couple of options
# Hence a mere 'echo $var' will not always yield the result which
# you might expect, try this with 
#
# var="-e -n value" ; echo $var
# and / or read 
# http://unix.stackexchange.com/questions/65803/why-is-printf-better-than-echo/65819#65819
#
# This is not an issue as long as you control the output / value of $var,
# but if you are working with text from unknown sources / user input, it
# might ruin your output. This simple echo replacement avoids that issue
# in a portable manner.
# 
# Usage: echo TEXT
echo() { printf '%s\n' "$*"; }
