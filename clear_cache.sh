#!/bin/sh

run_bleachbit (){
	bleachbit -c firefox.cache google_chrome.cache opera.cache chromium.cache chromium.history chromium.cookies google_chrome.history vlc.mru
}

truncate_vlc_history (){
	truncate -s 0 $HOME/.config/vlc/vlc-qt-interface.conf
}

clear_files_recent (){
	cp $HOME/bin/static/recently-used.xbel $HOME/.local/share/recently-used.xbel
	cd $HOME/.cache/thumbnails
	bleachbit -s `find . -type f -name "*.png"`
}

delete_history (){
 	sed -i '/mp4/d' $HOME/.zsh_history
}

MAIN() {
run_bleachbit
truncate_vlc_history
clear_files_recent
delete_history
}

MAIN
exit 0
