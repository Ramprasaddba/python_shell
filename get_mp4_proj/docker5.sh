#!/usr/bin/env bash

:<<'COMMENTS'
Script sets tags using the values in arr
-- downloads index.html from Site 
-- Locate docker image repo: getmp4
-- Builds docker container using using existing volume (-v) and passing command: ${getUrl}/tags/${myTag}
-- Moves TEMPDIR to /data/{timestamp}

Where getUrl is site
tags = secondary entry at site
myTag is arr value

Requirements:
- Install podman (docker may work, but podman should be used)
- Create podman volume "mydb": podman volume create mydb

EXIT CODES:
   1: Container image "getmp4" NOT FOUND
   2: podman nor docker is installed 
   3: Name of download file is not index.html 
   148: wget failed to pull index file


# Site:
# m_ot
COMMENTS

#Changes
# 2022-05-02; Added search_item()
# 2022-04-24: Updated docker run command changing "tags" to "term"

loopCount=$((RANDOM % 10 + 1))
declare -ag arr=()

MAIN() {
    func_set_dockercmd
    func_getUserUrl
    func_search_items
    func_get_imageId
    func_run
}

func_set_dockercmd () {
    which docker > /dev/null 2>&1
    if [ "$?" == "0" ]; then
        DOCKERCMD='docker'
    else
        which podman > /dev/null 2>&1                                                                                                                                       
        if [ "$?" == "0" ]; then
            DOCKERCMD='podman'
        else
            printf "docker nor podman command found on server"
            printf "Install the required packages...exiting"
            exit 2
        fi
    fi
}

func_search_items (){
    unset itemCount
    unset loopCount
    declare -i itemCount=1
    declare -i loopCount=1

    printf "\nHow many items to search: "
    read itemCount

    while [ $loopCount -le $itemCount ]
    do
        echo "Enter search item number($loopCount)"
        read searchString
        arr+=("$searchString")
        ((loopCount++))
    done
    printf "\nBeginning process to build containers..."
    sleep 2
}


func_getUserUrl () {
    dbStorage="$HOME/.local/share/containers/storage/volumes/mydb/_data"
    topDir=$(mktemp -p $dbStorage -d)
    pushd $topDir &>/dev/null
    printf "\nWhich URL: "
    read getUrl
    IFS=$'\n'
    wget --no-check-certificate ${getUrl} -O index.html
    if [ $? -eq 0 ]; then
        ls -1 index.html > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            printf "\nDownload file name is not index.html"
            printf "\n"
	    exit 3
        else
            printf "\nDownload file name is index.html...beginning to process"
            printf "\n"
        fi
    else
        printf "\nwget failed to pull index file"
        printf "\nConfirm the correct URL...exiting."
        printf "\n"
        exit 148
    fi
}


func_get_imageId() {
    # Gather a list of docker images repo name "getmp4"
    $DOCKERCMD images -n | grep -m1 getmp4  &>/dev/null
    if [ "$?"  == "0" ]; then
	# Added grep -m1 in order to restrict the number of images being returned
        get_imgId=$($DOCKERCMD images -n | grep -m1 getmp4  | awk '{print $3}')
        printf "\nContainer being built with image: ${get_imgId}"
	    printf "\n"
	    $DOCKERCMD ps 
    else
	    printf "\nUnable to locate Image Repository '${get_ImgId}'"
	    exit 1
    fi
}


func_run() {
    unset podCount
    podCount=1
    for myTag in "${arr[@]}"
    do
        printf "\nRetrieving: ${myTag}"
        sleep 10
        printf "\nCreating Docker Container\n"
        # docker run statement is adding an arguement after the Image-ID
        mkdir "$topDir/$myTag"
        $DOCKERCMD container run -d -m 512M --env TERM=dumb --rm --name ${getUserUrl}v${podCount} -w "/data" -v $topDir/$myTag:/data ${get_imgId} ${getUrl}/term/${myTag}
        podCount=$((podCount + 1))
        sleep 3
    done
    $DOCKERCMD ps
}

MAIN
