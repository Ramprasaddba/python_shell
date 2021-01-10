#!/usr/bin/env python3

# Script changes the Linux Desktop Background using the gsettings command:
# Backgrounds and stored in MYPATH

# Import required modules
import os
import sys
import random
import time
from os import path
import os.path


# Import module required to run gsettings command
import gi
gi.require_version('Gtk', '3.0')
from  gi.repository import Gio, Gtk


#Define GLOBAL CONSTANTS
BACKGROUNDS='/usr/share/backgrounds/various'

#Define variables


def main():
    check_mypath()
    get_wallpaper()


# Function will confirm if directory defined by BACKGROUNDS exists.  If not the program exits
def check_mypath():                 
    test_dir = (path.isdir(BACKGROUNDS))
    if test_dir == True:   #Boolean check
        time.sleep(3)      #Sleep just for the heck of it
    else:
        print('PATH:', BACKGROUNDS, " does not exists")
        print('Exiting...')
        exit(1)

# Function builds a random list of backgrounds in BACKGROUNDS
def get_wallpaper():    
    wallpaper_lst = []

    for (dirpath, dirname, filenames) in os.walk(BACKGROUNDS):
        for afile in filenames:
            wallpaper_lst.append(afile)

    mytest = len(wallpaper_lst)
    mytest = mytest - 1      # Decrease size of mytest by 1 to account for wallpaper_lst[] starting at 0 rather than 1
    my_rand = random.randint(0, mytest) 
    wallpaper = wallpaper_lst[my_rand]    #Sets the wallpaper to a random item from the wallpaper_lst
    get_wm(wallpaper)


#  For GNOME WM function uses gi module to set schema org.gnome.desktop.background
def set_wallpaper(wallpaper):
    settings = Gio.Settings.new("org.gnome.desktop.background")
    settings.set_string("picture-uri", "file://" + BACKGROUNDS + '/' + wallpaper)
    settings.apply()


#  For Cinnamon WM function uses gi module to set schema org.cinnamon.desktop.background
def cinnamon_set_wallpaper(wallpaper):
    settings = Gio.Settings.new("org.cinnamon.desktop.background")
    settings.set_string("picture-uri", "file://" + BACKGROUNDS + '/' + wallpaper)
    settings.apply()


# Confirm if the WM is GNOME or Cinnamon
def get_wm(wallpaper):
    wm_type=os.system('gsettings get org.gnome.desktop.background picture-uri  2>/dev/null')

    if wm_type==0:
        #print('DEBUG >>>>>> Gnome Found')
        set_wallpaper(wallpaper)
    else:
        #print('DEBUG >>>>>> Gnome NOT FOUND')
        cinnamon_set_wallpaper(wallpaper)



if __name__ == '__main__':
    main()

