#!/bin/bash

: <<'COMMENTS'
This script is used by BigFix when laptops are not correctly registered.
The script confirms if Xsession or Terminals are being used
Confirm which version of Python is installed
Copy the company provided reregister.py to /tmp
The reregister.py is launched if Xsession is running
The wall command is used if Terminal sessions only
COMMENTS

# Copies existing reregister.py to /tmp, changes the delay_run var to 1 resulting in a delay of only 1 second before GUI
func_cp_rereg (){
cp /opt/ibm/reregister/reregister.py /tmp/bf_reregister.py
sed -i 's/delay_run = .*/delay_run = randint(0, 1)/' /tmp/bf_reregister.py
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

#Confirm python3 is installed. If python3 is not installed attempt to throw wall message
func_get_py_ver (){                                                                                                                                                                           
        command -v python3 &>/dev/null
        if [ $? != 0 ]; then
            printf "\nPython3 is not installed"
            func_get_term
            exit 1
        else
            printf "\nPython3 is installed"
			PYCMD="python3"
        fi
}

# Confirm if Xsession is running, set DISPLAY env, throw zenity popup before registration GUI is displayed.
func_get_xdisplay (){
	   bes_userid=$(env | command grep -m1 -E '(USER.*=|LOGNAME=)' | awk -F'=' '{print $2}')
       get_xdisplay_var=$(w -h | grep -m1 $bes_userid | awk '{print $2}')
	   if [ ! -z "$get_xdisplay_var" ]; then
              printf "\nCaptured Xsession"
              DISPLAY=${get_xdisplay_var}
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
	          DISPLAY=${get_terms_var}
              # 2022-02-04: Added following because older CentOS7 machines run a version of wall that does not accept a file as input
              command wall -v &>/dev/null
              if [ $? == "0" ]; then
	   		      wall /tmp/bf_reg.msg
              else
                  wall < /tmp/bf_reg.msg
              fi
       fi
}

MAIN (){
DISPLAY=""
func_cp_rereg
func_check_running_reg
func_get_py_ver
file $(which w) &>/dev/null
if [ $? == 0 ]; then
       func_get_xdisplay
       if [ -z $DISPLAY ]; then
             func_get_term
       fi
else
       #The w command was not found.
       # The w command is needed to gather a list of connected users, without the w command exit script here
       printf "\n 'w' command not found"
       printf "\n"
       exit 1
fi
printf "\nDISPLAY var: '$DISPLAY'\n"
zenity --warning --width=400 --height=200 --text '<b><span foreground="red">***** THIS COMPUTER IS NOT REGISTERED *****\n</span></b>\nRegistration is required when accessing internal IBM resources.\n\nMinimize all windows and click OK button to launch Registration GUI.\n\nComplete the Registration GUI' &>/dev/null
$PYCMD /tmp/bf_reregister.py &
}

MAIN
