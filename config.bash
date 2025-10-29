# This is an example of star configuration file
# It is meant to be sourced from the script containing the star function

export _STAR_HOME=

# Value: yes, no (default: yes)
export __STAR_ENVVARS=yes


### COLOR OPTIONS ###
export __STAR_COLOR_NAME
export __STAR_COLOR_PATH
export __STAR_COLOR_RESET="\033[0m"

export __STAR_COLOR256_NAME
export __STAR_COLOR256_PATH
export __STAR_COLOR256_RESET="\033[0m"


### LIST OPTIONS ###
# Format:
# - this string is passed to GNU find, so any formatting for the "-print" option can be used:
#   - e.g: %f for name of starred directory
#   - e.g: %l for its absolute path
# - the string "<INDEX>" is used to add an index to each starred directory
#   - can be put anywhere in the string
#   - useful to navigate using the index of the star instead of its name
# - this string will be piped into the "column" command (see below for more)
#   - it is strongly recommended to put the path (%l) in the last column when separating
#     the vertical columns with whitespaces, as a path can contain whitespaces
export __STAR_LIST_FORMAT="<INDEX>: ${__STAR_COLOR_NAME}%f${__STAR_COLOR_RESET} -> ${__STAR_COLOR_PATH}%l${__STAR_COLOR_RESET}"

# Column command:
# To display the stars in vertically aligned columns, the "find" listing is piped into the column command
# - the listing has one result per line, each column is separated according to __STAR_LIST_FORMAT: by default we put spaces
# - by default, the GNU "column" command is used
#   - the default separator used is the whitespace character
#   - it is strongly recommended to set the number of columns (--table-columns-limit) according to the wanted number of columns
export __STAR_LIST_COLUMN_COMMAND="command column --table --separator ' ' --table-columns-limit 3"

# Value: loaded, name, none (default: loaded)
export __STAR_LIST_SORT="loaded"
# Value: asc, desc (default: desc)
export __STAR_LIST_ORDER="desc"
# Value: asc, desc (default: asc)
export __STAR_LIST_INDEX="asc"
