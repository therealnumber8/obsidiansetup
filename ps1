# ps1
# First, let's ensure we have color support
force_color_prompt=yes

# Define color codes for better readability
BLUE="\[\033[38;5;75m\]"
GREEN="\[\033[38;5;71m\]"
YELLOW="\[\033[38;5;227m\]"
RED="\[\033[38;5;196m\]"
ORANGE="\[\033[38;5;214m\]"
RESET="\[\033[0m\]"

# Function to get git branch and status
parse_git_branch() {
    local branch=$(git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
    if [ ! -z "$branch" ]; then
        local git_status=$(git status --porcelain 2>/dev/null)
        if [ ! -z "$git_status" ]; then
            echo " ($branch*)"
        else
            echo " ($branch)"
        fi
    fi
}

# Function to show command execution time
timer_start() {
    timer=${timer:-$SECONDS}
}

timer_stop() {
    local duration=$((SECONDS - timer))
    unset timer
    if [ $duration -gt 2 ]; then
        echo "${duration}s "
    fi
}

trap 'timer_start' DEBUG

# Function to get system load
get_load() {
    local load=$(uptime | awk -F'[a-z]:' '{ print $2}' | cut -d' ' -f2)
    echo "$load"
}

# Set the prompt command to run before each prompt
PROMPT_COMMAND='
    status=$?;
    timer_stop;
    history -a;
    if [ $status -eq 0 ]; then
        status_color=$GREEN
    else
        status_color=$RED
    fi'

# The actual PS1 string
PS1='${BLUE}[${RESET}\t${BLUE}]${RESET} $(if [[ ${EUID} == 0 ]]; then echo "${RED}\u${RESET}"; else echo "${GREEN}\u${RESET}"; fi)@${YELLOW}\h${RESET}:${BLUE}\w${ORANGE}$(parse_git_branch)${RESET} ${status_color}➜${RESET} '
