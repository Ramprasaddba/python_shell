#!/bin/bash


# Copies existing reregister.py to /tmp, changes the delay_run var to 1 resulting in a delay of only 1 second before GUI
func_cp_rereg (){
cp /opt/ibm/reregister/reregister.py /tmp/bf_reregister.py
sed -i 's/delay_run = .*/delay_run = randint(0, 1)/' /tmp/bf_reregister.py

# Remove entry from bf_reregister.py where the update_config script is called
sed -i 's/subprocess.*update_config.*stdout//' /tmp/bf_reregister.py

# Remove entries in bf_reregister.py where the beekeeper.ini file is deleted
sed -i "s/os.remove.*beekeeper.ini\")/os.rename(\"\/tmp\/beekeeper.ini\", \"\/tmp\/bf_beekeeper.ini\")/" /tmp/bf_reregister.py

chmod +x /tmp/bf_reregister.py
}

#Check if zenity window is open
func_check_zenity () {
    command ps -ef | command grep -E 'zenity.*Registration\ GUI'
	if [ $? == "0" ]; then
        zenity --warning --width=400 --height=200 --text '<b><span foreground="orange">***** THIS COMPUTER IS NOT REGISTERED *****\n</span></b>\nRegistration is required when accessing internal IBM resources.\n\nMinimize all windows and click OK button to launch Registration GUI.\n\nComplete the Registration GUI' &>/dev/null 
	    exit 0
	fi
}

#Confirm if reregistration.py is currently running.  If running display zenity popup and exit
func_check_running_reg () {
	get_reg_pid=$(command pgrep -f 'python.*reregister.py')
	if [ ! -z "$get_reg_pid" ]; then
	    func_get_xdisplay
		zenity --warning --width=400 --height=200 --text '<b><span foreground="blue">***** THIS COMPUTER IS NOT REGISTERED *****\n</span></b>\nRegistration is required when accessing internal IBM resources.\n\nMinimize all windows and click OK button to launch Registration GUI.\n\nComplete the Registration GUI' &>/dev/null
		exit 0
	fi
}

#Confirm python3 is installed. Exit if no version of python3 is installed.
func_get_py_ver (){                                                                                                                                                                           
        command -v python3 &>/dev/null
        if [ $? != 0 ]; then
            printf "\nPython3 is not installed"
            exit 1
        else
            printf "\nPython3 is installed"
			PYCMD="python3"
        fi
}

# Confirm if Xsession is running, set DISPLAY env, throw zenity popup before registration GUI is displayed.
func_get_xdisplay (){
	   bes_userid=$(env | command grep -m1 -E '(USER.*=|LOGNAME=)' | awk -F'=' '{print $2}')
	   get_xdisplay_var=$(w -h | command grep -m1 -E "^$bes_userid.*session" | awk '{print $2}')
	   if [ ! -z "$get_xdisplay_var" ]; then
            printf "\nCaptured Xsession"
            XDISPLAY=${get_xdisplay_var}
	        printf "\nDEBUG >>>> DISPLAY= $XDISPLAY"
            func_check_zenity
       fi
}

# If no Xsession is found, use 'w -h' output and wall command to inform user to register computer
func_get_term (){         
       bes_userid=$(env | command grep -m1 -E '(USER.*=|LOGNAME=)' | awk -F'=' '{print $2}')
	   get_terms_var=$(w -h | grep -m1 $bes_userid | awk '{print $2}')
	   #get_terms_var=$(w -h | /usr/bin/grep -m1 -E '[[:alnum:]]\s+(pts|tty)' | awk '{print $2}')
       if [ -z "$get_terms_var" ]; then
              printf "\nNo users currently connected"
              printf "\n"
              exit 1
       else
	          TERMDISPLAY=${get_terms_var}
	          printf "\nDEBUG >>>> TERMDISPLAY= $XDISPLAY"
	          wall /tmp/bf_reg.msg
       fi
}

MAIN (){
XDISPLAY=""
func_cp_rereg
func_check_running_reg
func_get_py_ver
file $(which w) &>/dev/null
if [ $? == 0 ]; then
       func_get_xdisplay
       if [ -z $XDISPLAY ]; then
             func_get_term
       fi
else
       #The w command was not found.
       # The w command is needed to gather a list of connected users, without the w command exit script here
       printf "\n 'w' command not found"
       printf "\n"
       exit 1
fi
zenity --warning --width=400 --height=200 --text '<b><span foreground="red">***** THIS COMPUTER IS NOT REGISTERED *****\n</span></b>\nRegistration is required when accessing internal IBM resources.\n\nMinimize all windows and click OK button to launch Registration GUI.\n\nComplete the Registration GUI' &>/dev/null
$PYCMD /tmp/bf_reregister.py
}

MAIN
exit 0