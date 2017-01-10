
read_config () {
  local config_file line line_count

  # A file name needs to be given
  [ -z ${1+x} ] && debug "missing argument to function call read_config()"

  config_file="$1"
  # Check whether config file exists and is readable
  [ -e "$config_file" ] || { runtime_error "file <$config_file> not found"; return 1; }
  [ -r "$config_file" ] || { runtime_error "cannot read file <$config_file>"; return 1; }


  # set function wide flags
  line_count=0
  
  # Outer loop will read each line
  while read line; do

    # Count the lines for proper error messages 
    line_count=$((line_count+1))
  
    # Set per-line flags
    has_name=0
    has_value=0
 
    # Only work on non-empty lines 
    if [ -n "$line" ]; then
      set -- $line
    else
      continue
    fi

    # If the line starts with a comment, disregard the entire line
    [ "${1%#*}" = "$1" ] || continue
 
    # Check if this is a name/value pair
    for token in "$@"; do 
        echo "Line $line_count, Token = $token"; 
    done

  
  done < "$config_file"

} 

  


