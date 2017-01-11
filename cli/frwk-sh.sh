##############################################################################
# This function sets one of the above variables when requested on the 
# command line using the -v|variable option
# Usage: set_variable ARGUMENT (where ARGUMENT is a name=value pair)
#
# Returns:
# 0 = success
# 1 = failure

set_variable()
{
  local var_name var_value

  # A missing argument is a bug...
  [ -z ${1+x} ] && debug "missing argument to function call: set_variable()"

  # Split the argument into name and value 
  var_name=${1%=*}
  var_value=${1#*=}

  # If the argument is not properly formatted, that's obviously an error
  # The below condition will be true when there is no "=" in the argument
  if [ "$var_name" = "$var_value" ]; then
    usage_error "illegal argument to -v option -- '$1'"
  fi
 
  # Set variable "name" to "value"
  case "$var_name" in 
    "SCRIPT_INTERPRETER") SCRIPT_INTERPRETER=$var_value ;;
    "SCRIPT_CMD_LIST") SCRIPT_CMD_LIST=$var_value ;;
    "SCRIPT_MIN_ARGS") SCRIPT_MIN_ARGS=$var_value ;;
    "SCRIPT_VERSION") SCRIPT_VERSION=$var_value ;;
    "SCRIPT_MAINTAINER") SCRIPT_MAINTAINER=$var_value ;;
    "SCRIPT_SYNOPSIS") SCRIPT_SYNOPSIS=$var_value ;;
    "SCRIPT_SHORT_DESCRIPTION") SCRIPT_SHORT_DESCRIPTION=$var_value ;;
    "MAN_SECTION") MAN_SECTION=$var_value ;;
    "MAN_SOURCE") MAN_SOURCE=$var_value ;;
    "MAN_MANUAL") MAN_MANUAL=$var_value ;;
    *) usage_error "Unknown variable name: $var_name" ;;
  esac

  return 0
}

##############################################################################
# Find out the line number of our payload cutoff
#
# Usage: find_binary_payload
#
# Returns:
# 0 = ERROR
# n = the line number (success)

find_binary_payload() {
  local lineno

  # Due to the BINARY payload grep will not process this file without
  # the -a switch. -n for the linenumber, and -x to match the whole line
  # so we don't get the actual grep command reported as a match, too
  lineno="$(grep -anx "PAYLOAD_CUTOFF" "$0" 2>&1)"

  # Extract the line number
  lineno="${lineno%:*}"
  lineno=$((lineno+1))

  # return 0 if we failed, the line number otherwise
  [ -z "$lineno" ] && return 0 || return $lineno
}

##############################################################################
# Set the library list in the Makefile
# First, we check if a file by the given library name exists
# and if so, it is put on the list. If not, we check if 
# a library in the sfw library directory exists. This is a 
# shortcut for the libraries that come with sfw.
# If a library is not found either way, a warning is printed
#
# The challenge with library filenames is portability:
# if the script should be built on different systems / in different
# places, too, filenames will usually have to be relative to the
# script_dir directory. This is easy for sfw libraries, but for external
# libraries the user must take care of this himself. 
#

set_liblist() {
  local libname sfw_lib pattern result_list=""

  for lib in $liblist; do 

    libname=""

    # if the file <$lib> exists, add it to the library list
    # In this case, we just copy the filename exactly 
    if [ -e $lib ]; then
      libname=${lib}

    # otherwise check whether there is a sfw library 
    # and make a $(TOPLEVEL) relativ filename 
    else 
      sfw_lib=$script_dir/sfw/lib/sfw_${lib}.sh
      [ -e $sfw_lib ] && libname="\$(SFW_LIB_DIR)/sfw_${lib}.sh"
    fi

    # If a library wasn't found, echo a warning 
    if [ -z "$libname" ]; then
      echo "warning: library <$lib> not found" >&2
      libname=$lib
    fi
    result_list="${result_list:+$result_list }$libname"

  done
  
  # Different regexp for appending (-a) and replacing (-l)
  if [ $append -eq 0 ]; then
    pattern="\(^.*=\).*"
  else
    pattern="\(^.*= .*\)"
  fi

  # Let there be sed
  sed -i -e "/^SCRIPT_LIBS/s|$pattern|\1 ${result_list}|g" \
  $script_dir/Makefile
}

##############################################################################
# When creating the sfw script directory, the Makefile template
# (which is parsed into a Makefile for this script) is saved as 
# "$backup_makefile" before being parsed. This enables us to take a
# diff with the "new" Makefile.in when the script directory is 
# updated.
# This way we have the best chances to apply Makefile template
# changes to the existing Makefile without messing with all the
# changes to variables that the user probably applied. 
#
# Usage: update_Makefile
#
# Returns:
# 0 = success
# 1 = failure

update_Makefile()
{
  local line_total diff_result=0 diff_file="Makefile.changes"

  # Next we create the diff to find out the difference from  
  # the old (current) to the new TEMPLATE Makefile 
  diff -u "${sfw_make_dir}/${backup_makefile}.in" "${sfw_make_dir}/Makefile.in" \
       > "${sfw_make_dir}/$diff_file" || diff_result=$?

  # DEBUG: this is waiting for removal
  # Whatever the result is, now that we have the diff we
  # overwrite ".Makefile.current.in" with the new version
  # mv -f "${sfw_make_dir}/Makefile.in" "${sfw_make_dir}/$makefile_backup"

  # Evaluate the diff result
  case $diff_result in

    # diff returns 0 when files are equal, which means that there is no
    # difference between the "old" and the "new" Makefile template.
    # So the Makefile does not need to be changed, either
    0) rm -f "${sfw_make_dir}/$diff_file"
       rm -f "${script_dir}/${backup_makefile}"
       rm -f "${sfw_make_dir}/${backup_makefile}.in"
       runtime_msg "Makefile templates did not change, Makefile not updated"
       return 0
       ;;

    # diff returns 2 if there was an error, which is fatal in our case
    # remove the (empty) diff file and install the new Makefile - unpatched,
    # that is, but after all we want to update
    2) runtime_error "Creating a diff from the current Makefile template failed."
       rm -f "${sfw_make_dir}/$diff_file"
       $parser "${sfw_make_dir}/Makefile.in" > "${script_dir}/Makefile"
       return 1
       ;;

    # diff worked and there were differences (diff returned 1)
    # Now we try to merge the changes into the new Makefile
    # NOTE: a probably existing Makefile.custom is NOT touched when 
    # updating, since it is CUSTOM for a reason. We don't need a 
    # backup from patch as we already have one in <Makefile.old>
    # If merging fails, we ask the user to manually inspect the now mutilated Makefile. 
    1) if ! patch -u --no-backup-if-mismatch --merge \
                  "${script_dir}/Makefile" \
                  "${sfw_make_dir}/$diff_file" > /dev/null; then
         runtime_error "A conflict occurred when merging changes to the new Makefile."
	 runtime_error "Conflicts are between \"<<<<<<<\"  and \">>>>>>>\" in <Makefile>"
	 runtime_error "The diff (changes from the old to the new Makefile version) is in"
         runtime_error "<${sfw_make_dir}/$diff_file>"
         return 1
    # Patching worked, remove the diff and finall parse the Makefile since
    # new variables might have been introduced with the new Makefile template.
       else
         $parser "${script_dir}/Makefile" > "${script_dir}/Makefile.tmp"
         mv -f "${script_dir}/Makefile.tmp" "${script_dir}/Makefile"
         runtime_msg "Makefile successfully updated."
       fi
       ;;

    # Diff returned something else ? Oups... 
    *) debug "Unknown error value returned by diff: $?"
       ;;
  esac
  return 0
}

##############################################################################
# Extract the payload into a directory and initialize it
# Below are the files that are likely to be changed by the
# user, hence especially in the case of an update they get
# extra attention:
# 1) <script.sh> is the sample script code and will be moved
#    to <name.sh> where name is what the user provided on the
#    command line
# 2) <./sfw/script.usage> is the usage text that is displayed when 
#    --help is provided on the command line. This file is moved
#    to <name.usage> 
# 3) The <Makefile.in> template Makefile will be moved to <Makefile>
#    with only a few variable substitutions per default (see top of this file)
#    Updating this file requires a little more work, see update_Makefile()
#
# Usage: extract_payload
#
# Returns: 
# 0 = success
# 1 = failure

extract_payload()
{
  local parser="awk -f ${sfw_dir}/utils/parser.awk" makefile_backup custom_make 
  local sfw_make_dir
 
  # The backup is used to update existing sfw projects with new sfw versions 
  sfw_make_dir="${sfw_dir}/make"
  backup_makefile="Makefile.old"
  custom_makefile="Makefile.custom"

  # If we're NOT updating...
  if [ $update -eq 0 ]; then

    # First, we extract the entire payload. If that fails, something
    # is very wrong. We can't do anything about it, though. 
    if ! tail -n +${payload_lineno} $0 | tar -C "$script_dir" -xjf -; then
      runtime_error "Extracting sfw payload to <$script_dir> failed."
      return 1
    fi

    # If a source script was given, copy it over the demo script
    [ $source -eq 1 ] && cp -f $sourcefile $script_dir/script.sh

    # Next, rename <script.sh> which is by now either the provided
    # script or the sfw-provided sample script
    mv $script_dir/script.sh $script_dir/${SCRIPT_NAME}.sh

    # File: <README.in>
    # parse the README template and remove the original file
    $parser "${script_dir}/README.in" > "$script_dir/README"
    rm "${script_dir}/README.in"

    # File: sfw/man/man_page.demo
    # parse the man page body to update filenames etc.
    SFW_DEMO_MANPAGE="$(readlink -e "${script_dir}/${SCRIPT_NAME}.usage")"
    export SFW_DEMO_MANPAGE
    $parser -v silent=1 "${sfw_dir}/man/man_page.demo" > "${sfw_dir}/man/man_page.demo.tmp"
    mv -f "${sfw_dir}/man/man_page.demo.tmp" "${sfw_dir}/man/man_page.demo"
    unset SFW_DEMO_MANPAGE

    # File: <script.usage>
    # parse script.usage and rename it. Add the absolute filename as 
    # an additional hint for the user on where to find the file
    # Finally, remove the original script.usage template file
    SFW_USAGE_TXT="$(readlink -e "${script_dir}/${SCRIPT_NAME}.usage")"
    export SFW_USAGE_TXT
    $parser "${script_dir}/script.usage" > "${script_dir}/${SCRIPT_NAME}.usage"
    unset SFW_USAGE_TXT
    rm "$script_dir/script.usage"

    # File: <sfw/make/Makefile.in> 
    # Parse the template Makefile to create the toplevel Makefile
    $parser "${sfw_make_dir}/Makefile.in" > "${script_dir}/Makefile"
   
    # File: <sfw/make/Makefile.custom.in> 
    # Parse the template custom Makefile just in case and remove the template
    $parser "${sfw_make_dir}/${custom_makefile}.in" > "${sfw_make_dir}/$custom_makefile"
    rm "${sfw_make_dir}/${custom_makefile}.in"

    # If the user wants a custom Makefile right away, we copy it into
    # the script_dir directory
    [ $custom -eq 1 ] && cp "${sfw_make_dir}/$custom_make" "$script_dir"

  # If we ARE updating, selectivly update those files that
  # may have changed during an sfw update
  else


    # Make sure the old Makefile template still exists as otherwise we 
    # cannot update to the new version
    if ! [ -e "${sfw_make_dir}/Makefile.in" ]; then
      runtime_error "old Makefile template is missing, cannot update"
      return 1
    # Save the old Makefile.in
    else 
      cp -f "${sfw_make_dir}/Makefile.in" "${sfw_make_dir}/${backup_makefile}.in"
    fi

    # Save the probably edited toplevel Makefile
    cp "${script_dir}/Makefile" "${script_dir}/${backup_makefile}"

    # Now extract the sfw subdirectory
    # TODO: if Makefile.custom.in changed it's format, we have a problem
    if ! tail -n +${payload_lineno} $0 | tar -C "$script_dir" -xjf - "./sfw"; then
      runtime_error "Extracting sfw subdirectory from payload failed !"
      return 1
    fi

    # Try to update the Makefile
    # Print some guidance on how to deal with a failed update
    if ! update_Makefile; then
      runtime_error "Updating the Makefile failed."
      runtime_error "The old Makefile was saved to <Makefile.old>"
      runtime_error "You have to manually apply changes to the new <Makefile>"
    fi

    # Finally, parse the updated Makefile as variables might have been
    # introduced that were not present in the previous Makefile
    if $parser "$script_dir/Makefile" > $script_dir/Makefile.tmp; then
      mv "$script_dir/Makefile.tmp" "$script_dir/Makefile"
    else
      echo "Parsing the Makefile for variable substitutions failed."
      echo "Look for @VARIABLE@ - style variables in the Makefile and"
      echo "substitute them manually"
      rm "$script_dir/Makefile.tmp"
    fi

  fi 
 
  # Set the library list in the Makefile if required
  # This way, a script directory can be updated and have its
  # library settings changed / appended at the same time 
  [ $append -eq 1 -o $list -ne 0 ] && set_liblist 

  return 0
}

##############################################################################
# Make sure we have a directory for the sfw based script 
#
# Usage: init_script_dir
#
# Returns:
# 0 = success
# 1 = failure

init_script_dir()
{

  # Initialize the script directory and the sfw subdirectory variables
  # If no directory name was provided, we use the script name as directory name
  [ -z "$script_dir" ] && script_dir="./${SCRIPT_NAME}"
  sfw_dir="${script_dir}/sfw"

  # If the directory does not exist, try to create it 
  if ! [ -d "$script_dir" ]; then
   
    # if -u was specified with a non existing directory, that's an error
    if [ $update -eq 1 ]; then
      runtime_error "directory $script_dir does not exist, cannot update"
      return 1
    fi

    # otherwise we try to create the directory
    if ! mkdir -p "$script_dir"; then
      runtime_error "Failed to create directory <$script_dir>"
      return 1
    fi
  
  # Existing directories can be a) updated or b) overwritten when using --force
  # That means if neither of the two flags is set, we have an error
  else
    if [ "${force}${update}" = "00" ]; then
      runtime_error "Directory <$script_dir> already exists, use -f to overwrite or -u to update."
      return 1
    fi
  fi

  # Saul Goodman
  return 0
}

################################################################################################
# Usage: parse_cmdline
#
# Returns: 
# 0 = success
# 1 = failure

parse_cmdline()
{
  local option opt_list
  
  # Options recognized:
  opt_list="a:cd:fl:s:uv:+append-library:+custom+script_dir:+force+library+source:+update+variable:"

  # Check command line arguments. 
  while [ $OPTIND -le $argc ]; do
  
    # Support functions for internal error messages:
    # -a and -l options are mutually exclusive
    # -l option can be used to clear the library list (no arguments) or to 
    # exclusively specify the list (with arguments)
    # Mixing both is not allowed 
    append_or_list() { usage_error "either append (-a) or list (-l) libraries: $OPTARG"; }
    mixed_list() { usage_error "Mixed -l options, use -l either with or without arguments"; }
  
    if getopts "$opt_list" option; then 
  
      case "$option" in 
  
        # Append a library to the default library list
        a|append-library)
          [ $list -eq 0 ] || append_or_list 
          append=1
          liblist="${liblist:+$liblist }$OPTARG"
          ;;
  
        # Include a custom Makefile
        c|custom)
          [ $custom -eq 1 ] && more_than_once "$option"
          custom=1
          ;;
  
        # The user can give a path were he wants the directory to be created
        d|directory)
  	  [ -n "$script_dir" ] && more_than_once "$option"
            script_dir="$OPTARG"
  	  ;;
  
        # Overwrite data in an existing directory
        f|force)
          [ $force -eq 1 ] && more_than_once $option
   	  force=1
          ;;
  
        # Add a library to the script Makefile (and ultimately to the resulting script)
        l|library)
          [ $append -eq 0 ] || append_or_list 
          [ $list -eq 2 ] && mixed_list
          list=1
          liblist="${liblist:+$liblist }$OPTARG"
          ;;
 
        # Use an existing script as source file
        s|source)
          [ $source -eq 1 ] && more_than_once $option
          is_readable $OPTARG && { source=1; sourcefile="$OPTARG"; }
          ;;
  
        # update data in an existing directory
        u|update)
          [ $update -eq 1 ] && more_than_once $option
          update=1 
          ;;

        # set a variable value (which will be substituted in the Makefile)
        v|variable)
          set_variable "$OPTARG"
          ;;
  
        # The option is invalid or missing an argument
        # the -l option is allowed without arguments to clear the list
        # of libraries
        "?") invalid_option $OPTARG ;;
        ":") 
           case $OPTARG in 
             l|library)
               [ $list -eq 2 ] && more_than_once $OPTARG
               [ $list -eq 1 ] && mixed_list 
               list=2 
               ;;
             *) missing_argument $OPTARG ;;
           esac
           ;;
  
        # Catch all for debugging
        *) debug "Unexpected value returned by getopts: <$option>"
           ;; 
     
      esac
  
    # Non-option arguments are simply taken without complaints
    else 
      is_nopt_arg $OPTIND
      OPTIND=$((OPTIND+1))
    fi
  
  done
}
  
#########################################################################
#
# Usage: main
#
# Returns: 
# 0 = all subfunctions succeeded
# 1 = failure

main() 
{
  # Flags will be set during command line argument parsing
  local append=0 list=0 custom=0 force=0 source=0 update=0 payload_lineno=0

  # Find out what the user wants, this is mainly about setting
  # a few flags in accordance with command line arguments
  parse_cmdline

  # Find out if what the user wants makes sense
  if [ $force -eq 1 -a $update -eq 1 ]; then
    usage_error "Illegal combination of options, use either <f|force> OR <u|update>"
  fi

  # Any filenames on the cmdline ? Otherwise exit with error message
  [ $nopt_argc -eq 0 ] && usage_error "You have to provide a name for your script"

  # Too many filenames on the cmdline ? Exit with error
  # We only support one script project at any given time to keep things simple
  [ $nopt_argc -gt 1 ] && usage_error "Too many arguments on command line"

  # Now we have to figure out which script project we're working on, 
  # i.e. the SCRIPT_NAME to use
  # Stripping a trailing "/" is meant to support autocompletion
  # e.g. when the user is updating an existing script directory
  nopt_argv 1 SCRIPT_NAME
  SCRIPT_NAME="${SCRIPT_NAME%/}"

  # Basically, any valid filename serves as a valid script name
  # A backslash is hence not allowed
  case "$SCRIPT_NAME" in 
    */*)  
      runtime_error "Illegal script name: $SCRIPT_NAME"
      return 1
      ;;
  esac

  # Now we have a valid script name so it's time to initialize our
  # target directory
  init_script_dir || return 1

  # This has to work - and it will, unless someone messed with the script
  if find_binary_payload; then
    runtime_error "Could not find binary payload in $0 !"
    return 1
  else
    payload_lineno="$?"
  fi 

  # We have a directory, we know where the payload is. Now we can deliver it 
  extract_payload

  return 0
}

#########################################################################
# Most of the default values are hard-coded into the template Makefile
# (which is part of the payload), hence we only set per-script values here
#
# TODO: document these settings in the man page for frwk-sh (1)

SCRIPT_INTERPRETER=/bin/sh
SCRIPT_CMD_LIST=""
SCRIPT_MIN_ARGS=1
SCRIPT_NAME=""
SCRIPT_VERSION="0.1a"
SCRIPT_MAINTAINER="Script Maintainer"
SCRIPT_SYNOPSIS="[options] <file>"
SCRIPT_SYNOPSIS_WITH_CMDS='<$(subst $(nul) $(nul),|,$(SCRIPT_CMD_LIST))> [options]'
SCRIPT_SHORT_DESCRIPTION="Shell Script Framework based demo script"

# Default man page variables
MAN_SECTION=1
MAN_SOURCE="Demo man page"
MAN_MANUAL="Shell Script Framework demo man page"

# These variables are exported to the environment for the parser
export SCRIPT_INTERPRETER SCRIPT_CMD_LIST SCRIPT_MIN_ARGS \
       SCRIPT_NAME SCRIPT_VERSION SCRIPT_MAINTAINER \
       SCRIPT_SYNOPSIS SCRIPT_SYNOPSIS_WITH_CMDS \
       SCRIPT_SHORT_DESCRIPTION 
export MAN_SECTION MAN_SOURCE MAN_MANUAL

##############################################################################

# These will be initialized by init_script_dir()
script_dir=""
sfw_dir=""

sourcefile=""
liblist=""

if main; then 
  exit 0
else
  exit 1
fi

PAYLOAD_CUTOFF
