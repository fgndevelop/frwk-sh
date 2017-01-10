# Usage and version information are displayed if the user ask's for them.
# Usage text and variable values are parsed into the executable script
# automatically when running "make"
#
# "--help" and "--version / -V" are expected to work for all scripts. Period.
# Since the getopts() library is not a requirement, we do not rely on it's
# functionality and simple parse the command line ourselves.
# Since these functions are either called during script initialization or 
# not at all, they will be unset by the init code. 

_sfw_help_version_check()
{
  local cmdline_arg

  for cmdline_arg in "$@"; do 
    case $cmdline_arg in
 
      # Print usage text
      --help)
	cat << EOF_USAGE_TEXT
Usage: $_sfw_script_name $_sfw_synopsis
@SCRIPT_SHORT_DESCRIPTION@

_usage_text_replaced_by_sed_

For more details see ${_sfw_man_title}(${_sfw_man_section}).
EOF_USAGE_TEXT
	exit 0
	;;

      # Print version information
      -V|--version)
  	echo "$_sfw_script_name $_sfw_script_version (powered by @SFW_VERSION@)"
  	echo "$_sfw_copyright"
  	echo "$_sfw_license"
  	echo "$_sfw_copying"
  	echo "$_sfw_warranty"
  	exit 0
	;;
    esac
  done
}

