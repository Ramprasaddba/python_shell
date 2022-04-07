#!/bin/sh
# 2021-01-15
# Script clears cache items
# 
# 2022-03-30:
# - Added scriptName variable
# 2022-03-15:
# - Created browser_cleaner()
#
# 2022-01-21:
# - Update MAIN() added if statement to check if $HOME/cronlogs exists before 'touch $logfile' 
# - Removed ALL redirects to $logfile
# - Added single redirect to $logfile to MAIN()
# 2022-01-14: Updated  MAIN() to test for bleachbit before running functions that require bleachbit
# 2022-01-11: Updated func_clear_files_recent adding a check for recently-used.xbel
# 2021-04-18: Updated cp cmd in clear_files_recent to redirect STDOUT & STDERR to /dev/null
# 2020-01-16: Updated trash_empty() providing FQpath to trash-empty in order to avoid rc=127


<< 'EXITCODES'
exit code 1: bleachbit application not found
EXITCODES

# Constant Variables
tStamp=$(date +%Y%m%d_%H%M)
scriptName=`basename "$0"`
logfile=$HOME/cronlogs/cron_run-"$scriptName"_"$tStamp".log

spacer='-------------//-------------------'

# Function runs all browser cleaners
func_browser_cleaner (){
    printf "\nStarting function....${FUNCNAME}\n"
    IFS=$'\n'
    get_pids=( $(ps auxh) )
    get_chrome_pid=$(echo "${get_pids[*]}" | grep -E '/google.*/chrome')
    get_brave_pid=$(echo "${get_pids[*]}" | grep -E '/brave.*/brave')
    get_ff_pid=$(echo "${get_pids[*]}" | grep -E '/firefox.*/firefox')

    printf "\n"
    if [ -z "$get_chrome_pid" ]; then
    printf "\nChrome PID not found...running cleaners"
        printf "\n"
        for cleaner in $(bleachbit -l | command grep chrome)
    do
        bleachbit -c $cleaner 
    done
    printf "\nRan browser cleaner for Chrome"
    else
        printf "\nRunning Chrome process detected...skipping cleanup"
    fi

    printf "\n"
    if [ -z "$get_brave_pid" ]; then
    printf "\nBrave PID not found...running cleaners"
        printf "\n"
        for cleaner in $(bleachbit -l | command grep brave)
    do
        bleachbit -c $cleaner
    done
    printf "\nRan browser cleaner for Brave"
    else
        printf "\nRunning Brave process detected...skipping cleanup"
    fi

    printf "\n"
    if [ -z "$get_ff_pid" ]; then
    printf "\nFirefox PID not found...running cleaners"
        printf "\n"
        for cleaner in $(bleachbit -l | command grep firefox)
    do
        bleachbit -c $cleaner
    done
    printf "\nRan browser cleaner for Firefox"
    else
        printf "\nRunning Firefox process detected...skipping cleanup"
    fi
    printf "\n$FUNCNAME rc=$?\n" 
}
        


# This function is used to remove all entries from the "Recent Files" of file manager
func_clear_files_recent (){
    printf "\n"
    if [ -f $HOME/.local/share/recently-used.xbel ]; then
        printf "Starting ${FUNCNAME}\n"
        command cp $HOME/bin/static/recently-used.xbel $HOME/.local/share/recently-used.xbel &>/dev/null
        printf "cp command rc=$?"
    else
        printf "${FUNCNAME} results:  $HOME/static/recently-used.xbel does not exist."
    fi
    printf "\n"
}


# This function removes old logs generated by cron jobs from the $HOME/cronlogs directory
func_bleachbit_cron_logs (){
    printf "\n"
    # only the printf statements in this function write to log file. Output of bleachbit command not included in log file
    printf "\nStarting ${FUNCNAME}\n"
    cd $HOME/cronlogs
    command bleachbit -s $(find . -type f -mtime +5) &>/dev/null
    printf "$FUNCNAME rc=$?\n" 
    printf "\n"
}


# This file removes all shell history lines that contain mp4
func_delete_history (){
    printf "\n"
    printf "\nStarting ${FUNCNAME}\n"
    echo $SHELL | command grep zsh
    if [ $? == 0 ]; then
        sed -i '/mp4/d' $HOME/.zsh_history
    else
        sed -i '/mp4/d' $HOME/.bash_history
    fi
    printf "$FUNCNAME rc=$?\n" 
    printf "\n"
}

# Function cleans up browsers history and cookies along with MRU of vlc
func_run_bleachbit_cleaners (){
    printf "\n"
    # only the printf statements in this function write to log file. Output of bleachbit command not included in log file
    printf "\nStarting ${FUNCNAME}\n"  >> $logfile
    command bleachbit -c vlc.mru  &>/dev/null
    #command bleachbit -c system.trash firefox.cache google_chrome.cache opera.cache chromium.cache chromium.history chromium.cookies google_chrome.history vlc.mru  &>/dev/null
    printf "$FUNCNAME rc=$?\n" 
    printf "\n"
}

func_run_bleachbit_targeted (){
    printf "\n"
    # only the printf statements in this function write to log file. Output of bleachbit command not included in log file
    printf "\nStarting ${FUNCNAME}\n"  
    cd $HOME/.cache/thumbnails &>/dev/null
    command bleachbit -s `find . -type f -name "*.png"` &>/dev/null
    printf "$FUNCNAME rc=$?\n" >> $logfile
    printf "\n"
}

func_trash_empty (){
    printf "\n"
    date +%H:%M:%S
    printf "Starting ${FUNCNAME}\n"
    $HOME/.local/bin/trash-empty -f 3 &>/dev/null
    date +%H:%M:%S
    printf "$FUNCNAME rc=$?\n" 
    printf "\n"
    
}

func_truncate_vlc_history (){
    printf "\n"
    printf "Starting ${FUNCNAME}\n"
    truncate -s 0 $HOME/.config/vlc/vlc-qt-interface.conf &>/dev/null
    printf "$FUNCNAME rc=$?\n" 
    printf "\n"
}

func_check_bleachbit (){
        get_bleachbit_ver=$(bleachbit --version 2>/dev/null)
        if [ -n "$get_bleachbit_ver" ]; then
            printf "Version Info:\n %s" "$get_bleachbit_ver"
        else
            printf "Bleachbit application not found...exiting"
            exit 1
        fi
}



MAIN() {

if [ -d $HOME/cronlogs ]; then
    touch $logfile
else
    mkdir $HOME/cronlogs
    touch $logfile
fi
(
start_tStamp=`date +%Y%m%d_%H:%M`
echo $spacer >> $logfile
printf "Start Time: ${start_tStamp}\n" 
func_check_bleachbit
func_clear_files_recent 
func_delete_history 
func_trash_empty 
func_truncate_vlc_history 
func_browser_cleaner

#bleachbit functions should not append to $logfile here
file $(command bleachbit -v) &>/dev/null
if [ $? == "0" ]; then
    printf "\nCalling bleachbit functions"
    func_bleachbit_cron_logs  
    func_run_bleachbit_cleaners
    func_run_bleachbit_targeted
    end_tStamp=$(date +%Y%m%d_%H:%M)
printf "End Time: ${end_tStamp}\n" 
echo $spacer 
else
    printf "bleachbit application NOT FOUND"
fi
printf "\n"
) >> $logfile
}

MAIN
