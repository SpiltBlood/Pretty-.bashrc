# ~/.bashrc
# Two-line prompt:
#   user@host [HH:MM] dir 
#       └──────────────┴──$
#
# Colors:
#   user/host   = green (non-root) / red (root)
#   time        = uncolored (fixed width and bracketed HH:MM)
#   dir         = blue (writable) / red (non-writable)
#   arrow       = dir color
#   prompt char = user color
#
# Written By <-Totally_Lost-> and ChatGPT <-- He did most of the work!
tput clear
fortune
# interactive only
[[ $- == *i* ]] || return

# aliases
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../../'
alias .4='cd ../../../../'
alias .5='cd ../../../../../'
alias f='fortune'

# globals
# use ANSI escapes as real escape characters
_red=$'\e[31m'
_green=$'\e[32m'
_blue=$'\e[34m'
_reset=$'\e[0m'
user_name="$(whoami)"
host_short="$(hostname -s)"

set_bash_prompt() {
  # locals
  local user_color dir_color prompt_char
  local time_str dir_display user_host
  local first_line_plain line_len middle_len arrow_middle dir_len
  local colored_first colored_second spaces dir_middle uname_len
  local arrow_col last_adjust

  # decide user color & prompt char
  if [ "$(id -u)" -eq 0 ]; then
    user_color="${_red}"
    prompt_char="#"
  else
    user_color="${_green}"
    prompt_char="$"
  fi

  # choose dir color by writability
  if [ -w "$PWD" ]; then
    dir_color="${_blue}"
  else
    dir_color="${_red}"
  fi
  
  # fixed-width backeted time
  time_str="[$(date +'%I:%M %P')]"
  date_str="$(date +'%A %b/%d/%Y')"

  # username and short hostname (plain text) get Current Dir
  user_host="${user_name}@${host_short}"
  dir_display="$PWD"

  # build plain (no-color) first line for width calculation
  first_line_plain="${user_host} ${time_str} ${dir_display}"
  line_len=${#first_line_plain} # assign lengths
  dir_len=${#dir_display}

  # center arrow under [user@host]
  uname_len=${#user_host} # get length of user@host string
  arrow_col=$(((uname_len / 2) -1 )) # set the arrow to start @ or near the @
  (( arrow_col < 0 )) && arrow_col=0 # no negatives
  spaces=$(printf '%*s' $arrow_col '') # spaces
  
  # arrow Maths
  dir_middle=$(( (dir_len / 2) - 2 )) # get the middle of the dir_display var
  (( dir_middle < 0 )) && dir_middle=0 # no negatives
  middle_len=$(( ((line_len - 2) - (dir_len / 2)) - arrow_col )) # get the length of the rest of the arrow
  (( middle_len < 0 )) && middle_len=0 # no negatives

  # robustly build a string of '─' of length middle_len (avoids seq issues)
  if (( middle_len > 0 )); then
    # create a string (all spaces) of length middle_len, then replace spaces with '─'
    printf -v arrow_middle '%*s' "$middle_len" ''
    arrow_middle=${arrow_middle// /─}
    # create a string (all spaces) of length dir_len, then replace spaces with '─'
    printf -v last_adjust '%*s' "$dir_middle"
    last_adjust=${last_adjust// /─}
    # compose final string
    arrow_middle="$arrow_middle┴$last_adjust"
  else
    arrow_middle=''
  fi

  # build the colored PS1 lines.
  # wrap actual color escape sequences with \[ \] so bash calculates prompt length correctly.
  colored_first="\[${user_color}\]${user_host}\[${_reset}\] ${time_str} \[${dir_color}\]${dir_display}\[${_reset}\]"
  colored_second="${spaces}\[${dir_color}\]└${arrow_middle}─\[${_reset}\]\[${user_color}\]${prompt_char}\[${_reset}\] "

  PS1="${colored_first}\n${colored_second}"
  
  # these line setup a margin of one line across the top of the term
  # which does do as advertised, with drawbacks
	# this line is to ensure LINES and COLUMNS are set
	#(:)

	#trap deinit-term exit
	#trap init-term winch
	#init-term
	#update_clock
}


function init-term() {
	printf '\e[H' # go home
	printf '\n' # ensure we have space for the scrollbar
	  printf '\e7' # save the cursor location
	    printf '\e[0;2r' # set the scrollable region (margin)
	  printf '\e8' # restore the cursor location
	printf '\e[1B' # move cursor down
}

function deinit-term() {
	printf '\e7' # save the cursor location
	  printf '\e[r' # reset the scrollable region (margin)
	  printf '\e[H' # move cursor to the bottom line
	  printf '\e[0K' # clear the line
	printf '\e8' # reset the cursor location
}

function update_clock() {
    while sleep 1s; do
        tput sc
        tput cup 0 0
        printf "${user_color}$date_str${_reset}"
        tput cup 0 $(($(tput cols)-9))
        printf "${user_color}$time_str${_reset}"
        tput rc
    done &
}

PROMPT_COMMAND='set_bash_prompt'
