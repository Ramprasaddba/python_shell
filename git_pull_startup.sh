#!/bin/sh 
# Version 0.0.4

# Script run on startup to pull git projects.

# 05-02-2021:  Added func_pull_zsh_syntax  
# 07-11-2021:  Added func_pull_Docker_build

# Set variables
timeStamp=`date +%Y%m%d_%H%M`
GITDIR=$HOME/GIT_REPO

# git repo directories
pythonCourse=$GITDIR/python_course
dotfiles=$GITDIR/dotfiles
zshdir=$GITDIR/zsh-syntax-highlighting
dockerBuild=$GITDIR/Docker_build

func_set_colors () {
    bold=$(tput bold)
    blink=$(tput blink)
    boldoff=$(tput sgr0)
    red=$(tput setaf 1)
    green=$(tput setaf 2)
    yellow=$(tput setaf 3)
    cyan=$(tput setaf 6)
    normal=$(tput setaf 9)
    boldoff=$(tput sgr0)
}

func_print_spacer (){
	printf "${normal}"
	printf "\n\n\n"
}

func_remove_30day_dirs (){
	IFS=$'\n'
	cd $GITDIR
	listDirs=($(find . -maxdepth 1 -mtime +20 -name "*202*" -type d))
	if [[ ${#listDirs[@]} -ne 0 ]]; then
	for dirName in ${listDirs[*]}
	do
		printf "\n>>> Remove dir: ${dirName}"
		sleep 2
               rm -rf ${dirName}
		if [[ $? == 0 ]]; then
			printf "${green}"
			printf "\nDeleted Directory ${dirName} succcessful"
			printf "${normal}"
			sleep 1
		else
			printf "${red}"
			printf "\nDeleted Directory ${dirName} FAILED"
			printf "${normal}"
		fi
	printf "\n"
	done
	else
		printf "\nNo directories older than 30 days found"
	fi
}

function func_pull_zsh_syntax {
	cd $GITDIR
	mv $zshdir $zshdir.$timeStamp
	if [[ $? != 0 ]]; then
	    printf "$zshdir NOT COPIED\n"
	    printf "No git clone will be attempted for $zshdir\n"
	else
		git clone https://github.com/zsh-users/zsh-syntax-highlighting.git
    fi
}


function pull_pythoncourse (){
	    printf "git clone attempt for $pythonCourse\n"
	    git clone https://github.com/dwashington102/python_course
	    if [[ $? != 0 ]]; then
		    printf "git clone attempted, but failed for $pythonCourse\n"
	    else
		    printf "git clone succeeded for $pythonCourse\n"
        fi
}


function pull_dotfiles (){
	    printf "git clone attempt for $dotfiles\n"
	    git clone https://github.com/dwashington102/dotfiles
	    if [[ $? != 0 ]]; then
		    printf "git clone attempted, but failed for $dotfiles\n"
	    else
		    printf "git clone succeeded for $dotfiles\n"
        fi
}

func_pull_Docker_build (){
	    printf "git clone attempt for $dockerBuild\n"
	    git clone https://github.com/dwashington102/Docker_build
	    if [[ $? != 0 ]]; then
		    printf "git clone attempted, but failed for $dockerBuild\n"
	    else
		    printf "git clone succeeded for $dockerBuild\n"
        fi
}


function rename_pythoncourse (){
	cd $GITDIR
	mv $pythonCourse $pythonCourse.$timeStamp
	if [[ $? != 0 ]]; then
	    printf "$pythonCourse NOT COPIED\n"
	    printf "No git clone will be attempted for $pythonCourse\n"
	else
		pull_pythoncourse
    fi
}


function rename_dotfiles (){
	cd $GITDIR
	mv $dotfiles $dotfiles.$timeStamp
	if [[ $? != 0 ]]; then
	    printf "$dotfiles NOT COPIED\n"
	    printf "No git clone will be attempted for $dotfiles\n"
	else
        pull_dotfiles
    fi
}

func_rename_Docker_build (){
	cd $GITDIR
	mv $dockerBuild $dockerBuild.$timeStamp
	if [[ $? != 0 ]]; then
	    printf "$dockerBuild NOT COPIED\n"
	    printf "No git clone will be attempted for $dockerBuild"
	else
	    func_pull_Docker_build
	fi

}


function check_pythoncourse (){
	if [ -d "$pythonCourse" ]; then
		rename_pythoncourse
    else
	    pull_pythoncourse
    fi
}


function check_dotfiles (){
	if [ -d "$dotfiles" ]; then
		rename_dotfiles
	else
		pull_dotfiles
    fi
}

func_check_conn_github () {
    wget -q --spider www.github.com
    if [ $? -ne 0 ]; then
	printf "${red}"
        printf "\nNetwork connection to github cannot be established."
	printf "\nCheck network connection...exiting"
	func_print_spacer
	exit 100
    else
	printf "${green}"
        printf "\nConnection to Github confirmed"
		func_print_spacer
	printf "${normal}"
    fi
}

function MAIN (){
func_set_colors
func_check_conn_github
cd $GITDIR
check_pythoncourse
func_print_spacer
func_pull_zsh_syntax
func_print_spacer
check_dotfiles
func_print_spacer
func_rename_Docker_build
func_print_spacer
func_remove_30day_dirs
}



# Where the magic happens
MAIN
printf "${yellow}"
printf "\ngit pull actions completed\n"
printf "${normal}"
exit 0
