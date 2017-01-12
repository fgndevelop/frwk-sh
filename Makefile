# 20170107_fgn
#
# Script Framework Toplevel Makefile
#
# This Makefile "bootstraps" the Script Framework. It is the single
# point of configuration, all adjustments to variables will be propagated
# from this Makefile to the rest of the project by means of sed and awk.
#
# Actions taken:
# 
# 1) Setting current SFW_VERSION in all versioned files
# 2) Creating the payload for frwk-sh
# 3) Writing default values into frwk-sh
# 4) Calling the sub Makefile to create frwk-sh and it's man pages
# 5) Adding the payload to frwk-sh
#

# default target
.PHONY : all
all : 

#################################################################################

# This is the default format of diagnostic messages
# [OK/FAIL] <Description of action (max. 22 characters)> [FILE] <filename>
SUCCESS			:= printf "[ OK ] %-22s(%s)\n"
FAILURE			:= printf "[FAIL] %-22s(%s)\n"

# TOPLEVEL is the directory this Makefile (or a link to it) resides in
# We use abspath instead of realpath so that we get proper toplevel directory values
# when the Makefile is a symlink. abspath doesn't check for existence, but that's not
# an issue as MAKEFILE_LIST is a list of existing files
# The variable is recursive as it is exported to the payload Makefile by value
TOPLEVEL		= $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
SHELL 			:= /bin/sh

# Script Framework version string and sed command (see PAYLOAD target)
# CAVE: the sed command must be defined as a recursive variable due to
# references to $@ and $<
SFW_VERSION		:= Shell Script Framework v1.0
set_sfw_version 	= @sed -e 's|@SFW_VERSION@|$(SFW_VERSION)|g' $< > $@

#################################################################################

# Shell Script Framework subdirectories
SFW_DIR			:= $(TOPLEVEL)/framework
SFW_TMPL_DIR		:= $(SFW_DIR)/tmpl
SFW_MAN_DIR		:= $(SFW_DIR)/man
SFW_MAKE_DIR		:= $(SFW_DIR)/make
SFW_LIB_DIR		:= $(SFW_DIR)/lib
SFW_UTILS_DIR		:= $(SFW_DIR)/utils

# These include the sources for the sfw payload that will be attached to frwk-sh
SFW_HEADER_FILE		:= $(SFW_DIR)/header/sfw_header.sh.in

# The sfw parser (used by the sfw Makefile and the cli tool)
PARSER			:= $(SFW_UTILS_DIR)/parser.awk.in
RUN_PARSER		:= awk -f $(PARSER)

# sfw cli (frwk-sh) subdirectories and files
SFW_CLI_DIR		:= $(TOPLEVEL)/cli
SFW_CLI_MAKEFILE	:= $(SFW_CLI_DIR)/Makefile
SFW_CLI_SCRIPT		:= $(SFW_CLI_DIR)/frwk-sh.sh
SFW_CLI			:= $(SFW_CLI_DIR)/frwk-sh

#################################################################################

# The payload is the data that makes up the Script Framework and will be appended
# to $(SFW_CLI) as a compressed tar ball 

# Payload directories and payload file
PAYLOAD_TOP_DIR		:= $(TOPLEVEL)/payload
PAYLOAD_DIR		:= $(PAYLOAD_TOP_DIR)/sfw
PAYLOAD_SFW_HEADER_DIR	:= $(PAYLOAD_DIR)/header
PAYLOAD_LIB_DIR		:= $(PAYLOAD_DIR)/lib
PAYLOAD_MAN_DIR		:= $(PAYLOAD_DIR)/man
PAYLOAD_MAKE_DIR	:= $(PAYLOAD_DIR)/make
PAYLOAD_UTILS_DIR	:= $(PAYLOAD_DIR)/utils
PAYLOAD_DIRS		:= $(PAYLOAD_TOP_DIR) $(PAYLOAD_DIR) $(PAYLOAD_LIB_DIR)
PAYLOAD_DIRS		+= $(PAYLOAD_MAN_DIR) $(PAYLOAD_UTILS_DIR) $(PAYLOAD_SFW_HEADER_DIR)
PAYLOAD_DIRS		+= $(PAYLOAD_MAKE_DIR)
PAYLOAD_FILE		:= payload.tar.bz2

# Single Shell Script Framework files 
PAYLOAD_MAKEFILE	:= $(PAYLOAD_MAKE_DIR)/Makefile.in
PAYLOAD_MAKEFILE_CUSTOM	:= $(PAYLOAD_MAKE_DIR)/Makefile.custom
PAYLOAD_SCRIPT		:= $(PAYLOAD_TOP_DIR)/script.sh
PAYLOAD_USAGE_TXT	:= $(PAYLOAD_TOP_DIR)/script.usage
PAYLOAD_SFW_HEADER_FILE	:= $(PAYLOAD_SFW_HEADER_DIR)/sfw_header.sh
PAYLOAD_COPYING		:= $(PAYLOAD_TOP_DIR)/LICENSE
PAYLOAD_README		:= $(PAYLOAD_TOP_DIR)/README.in

# The Shell Script Framework man page default files
PAYLOAD_MAN_HEADER	:= $(PAYLOAD_MAN_DIR)/man_page.header
PAYLOAD_MAN_DEMO	:= $(PAYLOAD_MAN_DIR)/man_page.demo
PAYLOAD_MAN_FOOTER	:= $(PAYLOAD_MAN_DIR)/man_page.footer

PAYLOAD_MAN_FILES	:= $(PAYLOAD_MAN_HEADER) $(PAYLOAD_MAN_DEMO) \
			   $(PAYLOAD_MAN_FOOTER) 

# The Shell Script Framework Library files
PAYLOAD_LIB_CLI		:= $(PAYLOAD_LIB_DIR)/sfw_cli.sh
PAYLOAD_LIB_DYN		:= $(PAYLOAD_LIB_DIR)/sfw_dyn.sh
PAYLOAD_LIB_STD		:= $(PAYLOAD_LIB_DIR)/sfw_std.sh
PAYLOAD_LIBS		:= $(PAYLOAD_LIB_CLI) $(PAYLOAD_LIB_DYN) $(PAYLOAD_LIB_STD)

# The Shell Script Framework utilities 
PAYLOAD_UTILS		:= $(PAYLOAD_UTILS_DIR)/$(basename $(notdir $(PARSER)))

# For the template Makefile.in that will be shipped with the payload,
# we only set default values during variable substitution taken from this Makefile.
# The remaining variables in the (payload) Makefile will be set by frwk-sh
# when creating a script project or have to be entered by the user afterwards.
$(PAYLOAD_MAKEFILE) : EXPORT	:= SUCCESS='$(value SUCCESS)'
$(PAYLOAD_MAKEFILE) : EXPORT	+= FAILURE='$(value FAILURE)'
$(PAYLOAD_MAKEFILE) : EXPORT	+= TOPLEVEL='$(value TOPLEVEL)'
$(PAYLOAD_MAKEFILE) : EXPORT	+= SHELL='$(SHELL)'
$(PAYLOAD_MAKEFILE) : EXPORT	+= SFW_VERSION='$(SFW_VERSION)'
$(PAYLOAD_MAKEFILE) : EXPORT	+= MAN_DEMO_DATE=$(firstword $(shell stat -c%y $(SFW_MAN_DIR)/man_page.demo.in))

# Create required directories
$(PAYLOAD_DIRS) : 
	@mkdir -p $@

# The main Makefile
$(PAYLOAD_MAKEFILE) : $(SFW_MAKE_DIR)/Makefile.in 
	@$(EXPORT) $(RUN_PARSER) -v silent=1 $< > $@

# The custom Makefile
$(PAYLOAD_MAKEFILE_CUSTOM) : $(SFW_MAKE_DIR)/Makefile.custom.in
	$(set_sfw_version)

# SFW sample usage for the payload
$(PAYLOAD_USAGE_TXT) : $(SFW_TMPL_DIR)/script.usage.in
	$(set_sfw_version)

# SFW sample script code for the payload
$(PAYLOAD_SCRIPT) : $(SFW_TMPL_DIR)/script.sh.in
	$(set_sfw_version)

# Default license (GPL 2)
$(PAYLOAD_COPYING) : $(SFW_TMPL_DIR)/LICENSE
	@cp $< $@

# Default README (just a stub)
$(PAYLOAD_README) : $(SFW_TMPL_DIR)/README.in
	$(set_sfw_version)

# The sfw header file has got it's own Makefile
$(SFW_HEADER_FILE) : % : $(dir %)/Makefile
	@$(MAKE) --silent -C $(@D)

# Parse the header file for the payload
$(PAYLOAD_SFW_HEADER_FILE) : $(SFW_HEADER_FILE)
	$(set_sfw_version)

# SFW libraries for the payload
$(PAYLOAD_LIBS) : $(PAYLOAD_LIB_DIR)/%.sh : $(SFW_LIB_DIR)/%.sh
	$(set_sfw_version)

# The utilities used by the sfw Makefile
$(PAYLOAD_UTILS) : $(PAYLOAD_UTILS_DIR)/% : $(SFW_UTILS_DIR)/%.in
	$(set_sfw_version)
	@chmod +x $@

# Catch all rule for the "payload/sfw/man from sfw/man files"
$(PAYLOAD_MAN_DIR)/% : $(SFW_MAN_DIR)/%.in
	$(set_sfw_version)

# Create a compressed tar ball from the payload files
$(PAYLOAD_FILE) : $(PAYLOAD_DIRS) \
		  $(PAYLOAD_MAKEFILE) \
		  $(PAYLOAD_MAKEFILE_CUSTOM) \
	          $(PAYLOAD_SFW_HEADER_FILE) \
		  $(PAYLOAD_LIBS) \
	          $(PAYLOAD_MAN_FILES) \
                  $(PAYLOAD_SCRIPT) \
                  $(PAYLOAD_USAGE_TXT) \
                  $(PAYLOAD_COPYING) \
                  $(PAYLOAD_README) \
		  $(PAYLOAD_UTILS)
	@tar -C $(PAYLOAD_TOP_DIR) -cjf $@ . && \
	$(SUCCESS) "payload built" "$@" || \
	$(FAILURE) "payload not built" "$@"

#################################################################################

MAN_SOURCE     	:= Script Framework 
MAN_MANUAL     	:= Script Framework User Guide
MAN_AUTHOR    	:= $(SCRIPT_MAINTAINER)


# Shell Script Framework main man page variable substitutions.
# The lines below are added to the Makefile sfw_init/Makefile,
# as the sfw.5 man page will be built from there.

SFW_MAN_PAGE	:= frwk-sh.7.gz

$(SFW_MAN_PAGE) :  SCRIPT_NAME			:= Shell Script Framework 
$(SFW_MAN_PAGE) :  SCRIPT_MAINTAINER		:= Frank G. Neumann
$(SFW_MAN_PAGE) :  SCRIPT_SHORT_DESCRIPTION	:= assists in  writing user friendly shell scripts
$(SFW_MAN_PAGE) :  MAN_SECTION           	:= 7

#################################################################################

# This part of the Makefile prepares the cli directory for building with 
# the just created sfw payload file. Basically, we are simulating a frwk-sh
# run (since we cannot yet use frwk-sh itself), which also serves as a test for
# the sfw build system.

# We introduce a global variable (EXPORT) here, since the variables are
# needed for both the SFW_CLI_MAKEFILE and SFW_CLI target and we dont't
# know which one is called first (e.g. "make man" depends on SFW_CLI_MAKEFILE) 
EXPORT	:= SCRIPT_INTERPRETER='/bin/sh'
EXPORT	+= SCRIPT_NAME='frwk-sh'
EXPORT	+= SCRIPT_VERSION='0.1a'
EXPORT	+= SCRIPT_SYNOPSIS='[options] <scriptname>'
EXPORT	+= SCRIPT_SYNOPSIS_WITH_CMDS='unused'
EXPORT	+= SCRIPT_MAINTAINER='Frank G. Neumann'
EXPORT	+= SCRIPT_BUGREPORT='$$(SCRIPT_MAINTAINER) <fgndevelop@posteo.de>'
EXPORT	+= SCRIPT_CMD_LIST=''
EXPORT	+= SCRIPT_MIN_ARGS=1
EXPORT	+= SCRIPT_SHORT_DESCRIPTION='Initialize or update a Shell Script Framework project'
EXPORT	+= SCRIPT_LIBS='$(SFW_LIB_DIR)/sfw_cli.sh $(SFW_LIB_DIR)/sfw_std.sh'
EXPORT	+= MAN_SECTION='1'
EXPORT	+= MAN_SOURCE='$(SFW_VERSION)'
EXPORT	+= MAN_MANUAL="$(MAN_MANUAL)"

# Create the Makefile for frwk-sh:
# First extract the payload that was just created
# Remove the files that we don't need for this particular project
# Parse the Makefile for generic variables that are inherited from this Makefile
# Add definitions for the sfw(5) man page to the Makefile
# Remove the template Makefile
$(SFW_CLI_MAKEFILE) : $(PAYLOAD_FILE) 
	@tar -xf $(PAYLOAD_FILE) -C $(SFW_CLI_DIR)
	@rm -f $(SFW_CLI_DIR)/$(notdir $(PAYLOAD_SCRIPT))
	@rm -f $(SFW_CLI_DIR)/$(subst $(PAYLOAD_TOP_DIR)/,,$(PAYLOAD_USAGE_TXT))
	@rm -f $(SFW_CLI_DIR)/$(subst $(PAYLOAD_TOP_DIR)/,,$(PAYLOAD_README))
	@$(EXPORT) $(RUN_PARSER) $(PAYLOAD_MAKEFILE) > $@
	@printf "\n%s\n" "# Definitions for $(SFW_MAN_PAGE) automatically added by toplevel Makefile" >> $@
	@sed -ne '/^\$$(SFW_MAN_PAGE)/{s/$$(SFW_MAN_PAGE)/$(SFW_MAN_PAGE)/g;p}' \
	$(lastword $(MAKEFILE_LIST)) >> $@

# make the frwk-sh script and attach the payload
# All variables specific to the frwk-sh script are passed via the command line
# as this is consistent with the calls to $(RUN_PARSER)
$(SFW_CLI): $(SFW_CLI_MAKEFILE) $(SFW_CLI_SCRIPT)
	@$(MAKE) $(EXPORT) --silent -C $(SFW_CLI_DIR)
	@cat $(PAYLOAD_FILE) >> $(SFW_CLI) && \
	$(SUCCESS) "payload appended" "$(notdir $@) + $(PAYLOAD_FILE)" || \
	$(FAILURE) "payload not appended" "$(notdir $@)"

.PHONY : all man shared

# Per-target dependencies
man : $(SFW_CLI_MAKEFILE)
all compressed shared : $(PAYLOAD_FILE) $(SFW_CLI)

# One rule for all build targets
all compressed man :
	@$(MAKE) --silent -C $(SFW_CLI_DIR) $@ 

#################################################################################

# Install targets. By default, just the cli is installed.
# Use install-libs to install the sfw libraries, too. This will allow
# for all other sfw-built scripts to dynamically include the sfw libraries.
#
# The actual installation is delegated to the framework's sub make.

# If a relative DESTDIR is passed to the sub make, this will be taken as relative
# to the sub directory, so we make sure an absolut DESTDIR is passed.

# We don't know for sure where DESTDIR is set, so we export it to be on the safe side
ifneq ($(DESTDIR),)
export	DESTDIR			:= $(realpath $(DESTDIR))
endif

# Install and uninstall targets
.PHONY : install install-man install-libs
.PHONY : uninstall uninstall-man uninstall-libs

install install-man install-libs : all
	@$(MAKE) --silent -C $(SFW_CLI_DIR) $@ 

# If the sfw_init Makefile does not exist, there's no reason
# to try uninstalling anything (we'd fail, because we need the Makefile)
uninstall uninstall-man uninstall-libs :
	@if [ -e "$(SFW_CLI_MAKEFILE)" ]; then \
	  $(MAKE) --silent -C $(SFW_CLI_DIR) $@; \
	 else \
	  $(FAILURE) "not installed" "sfw"; \
	 fi

#################################################################################

.PHONY : clean

# Clean up in the cli directory  "natively", if a previous (successful)
# make left a Makefile behind
clean ::
	@[ -f $(SFW_CLI_DIR)/Makefile ] && $(MAKE) --silent -C $(SFW_CLI_DIR) clean || :

# Clean all other remnants of building sfw_init
clean ::
	@rm -f $(SFW_CLI_DIR)/Makefile
	@rm -rf $(SFW_CLI_DIR)/$(subst $(PAYLOAD_TOP_DIR)/,,$(PAYLOAD_SFW_HEADER_DIR))
	@rm -rf $(SFW_CLI_DIR)/$(subst $(PAYLOAD_TOP_DIR)/,,$(PAYLOAD_UTILS_DIR))
	@rm -rf $(SFW_CLI_DIR)/$(subst $(PAYLOAD_TOP_DIR)/,,$(PAYLOAD_MAN_DIR))/
	@rm -rf $(SFW_CLI_DIR)/$(subst $(PAYLOAD_TOP_DIR)/,,$(PAYLOAD_LIB_DIR))

# Clean up the toplevel directory
clean :: 
	@rm -f $(PAYLOAD_FILE)
	@rm -rf $(PAYLOAD_TOP_DIR)
	@$(MAKE) --silent -C $(dir $(SFW_HEADER_FILE)) clean
	@$(SUCCESS) "cleaned" "$(TOPLEVEL)"

# End of Makefile
