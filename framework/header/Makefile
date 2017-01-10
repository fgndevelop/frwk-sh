# 
# The Script Framework Header is split into multiple files for easier editing.
# This Makefile mainly keeps those details out of the toplevel Makefile.
#

SFW_HEADER_SHEBANG	:= 01_shebang.h
SFW_HEADER_CONSTANTS	:= 02_constants.sh
SFW_HEADER_TRAP		:= 03_trap.sh
SFW_HEADER_OUTPUT	:= 04_output.sh
SFW_HEADER_HELP		:= 05_help.sh
SFW_HEADER_FUNCTIONS	:= 06_functions.sh
SFW_HEADER_INIT		:= 07_init.sh
SFW_HEADER_CUTOFF	:= 08_cutoff.h


SFW_HEADER_FILES	:= $(SFW_HEADER_SHEBANG) $(SFW_HEADER_CONSTANTS) $(SFW_HEADER_TRAP)
SFW_HEADER_FILES	+= $(SFW_HEADER_OUTPUT) $(SFW_HEADER_HELP) $(SFW_HEADER_FUNCTIONS)
SFW_HEADER_FILES	+= $(SFW_HEADER_INIT) $(SFW_HEADER_CUTOFF)

SFW_HEADER		:= sfw_header.sh.in

all : $(SFW_HEADER)

$(SFW_HEADER) : $(SFW_HEADER_FILES)
	@cat $^ > $@

.PHONY : clean
clean : 
	@rm -f $(SFW_HEADER)
	

