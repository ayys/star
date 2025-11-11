
# This script is meant to be sourced by star.
# It manages color for star output, depending on terminal capabilities.

# Adjust colors depending on terminal capabilities
if [[ -t 1 ]]; then
    if [[ "$COLORTERM" = "truecolor" || "$COLORTERM" = "24bit" ]]; then
        # Use true color (=24 bits colors)
        export __STAR_COLOR_NAME="${__STAR_COLOR_NAME-$'\033[38;2;255;131;0m'}"
        export __STAR_COLOR_PATH="${__STAR_COLOR_PATH-$'\033[38;2;1;169;130m'}"
        export __STAR_COLOR_RESET="${__STAR_COLOR_RESET-$'\033[0m'}"
    else
        # Fallback to 256-color codes
        export __STAR_COLOR_NAME="${__STAR_COLOR256_NAME-$'\033[38;5;214m'}"
        export __STAR_COLOR_PATH="${__STAR_COLOR256_PATH-$'\033[38;5;36m'}"
        export __STAR_COLOR_RESET="${__STAR_COLOR256_RESET-$'\033[0m'}"
    fi
else
    # No terminal detected, disable colors
    export __STAR_COLOR_NAME=""
    export __STAR_COLOR_PATH=""
    export __STAR_COLOR_RESET=""
fi
unset __STAR_COLOR256_NAME
unset __STAR_COLOR256_PATH
unset __STAR_COLOR256_RESET
