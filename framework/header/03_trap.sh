# This is the generic sfw clean up function wich cleans up sfw changes
# to the environment. This is not necessary when the script is executed
# in a subshell, but a script might get sourced using ".", too.
# If set, a user defined cleanup hook will be called, too.
#
# For more information regarding traps and signal propagation in shell scripts,
# see this not exhaustive list: 
# http://www.cons.org/cracauer/sigint.html
# http://www.vidarholen.net/contents/blog/?p=34

# https://www.gnu.org/software/autoconf/manual/autoconf-2.69/html_node/Signal-Handling.html
# http://docstore.mik.ua/orelly/unix/ksh/ch08_04.htm

# Clean up sfw changes to the environment
_sfw_cleanup() 
{
  # Restore IFS
  [ -z ${_sfw_old_ifs+x} ] && IFS=$_sfw_old_ifs

  # call a user provided cleanup hook, if it is set
  [ -n "${_sfw_user_exit_hook}" ] && eval "$_sfw_user_exit_hook"

  # explicitly set return value to 0 as otherwise the return value 
  # will be the result of the above comparison 
  return 0
}

# This function can be called by the script to install a custom exit
# hook since _sfw_cleanup just cleans up the mess we made ourselves

set_exit_hook() 
{
  [ -z ${1+x} ] && debug "Missing argument to function call set_exit_hook()"
  _sfw_user_exit_hook=$1
  return 0
}

# A wrapper for the _sfw_internal_variable
unset_exit_hook() { _sfw_user_cleanup_hook=""; return 0; }

# SIGINT, SIGHUP and SIGTERM trap
# This is not a perfectly clean solution as there may be case when a program
# called by the script has a legitimate reason to receive SIGINT without 
# actually exiting (e.g. emacs), yet those cases are rare.
#
# So all we do for now is calling the cleanup function and then removing
# the trap to kill ourselves. The EXIT trap is removed because otherwise 
# the cleanup function would be called twice. If this is not what you want
# in your particular script, choose a different interrupt handler using 
# set_interrupt 
#
# Signal propagation also enables the shell to set the return code according
# to the signal received (e.g. on SIGINT, return code $? will be 130) 

_sfw_interrupt_handler() 
{
  # Tell the user what happened
  printf '\n%s: terminating script on SIG%s, cleaning up\n' "$_sfw_script_name" $1 >&2
  _sfw_cleanup

  # Unset the exit trap as all it does is to call _sfw_cleanup
  # The user is not supposed to set it's own exit trap, rather
  # use "set_cleanup_hook" to set up a hook for user-specific cleanup
  trap - EXIT $1
  kill -s $1 $$
  return 0
}

set_interrupt() 
{
  local sig signals="INT TERM HUP"

  # Set interrupt handler for all of the above signals
  for sig in $signals; do
    trap "${1-_sfw_interrupt_handler} $sig" $sig
  done
}

