# Styli.sh - Wallpaper switching made easy

# ┏━┳┓╋╋╋╋┏┳━┳┓
# ┃━┫┗┳┳┳┓┣┫━┫┗┓
# ┣━┃┏┫┃┃┗┫┣━┃┃┃
# ┗━┻━╋┓┣━┻┻━┻┻┛
# ╋╋╋╋┗━┛━━┛

Styli.sh is a Bash script that aims to automate the tedious process of finding new wallpapers, downloading and switching them via the configs. **Styli.sh** can search for specific wallpapers from unsplash or download
a random image from the specified subreddits. If you have pywal it also can set automatically your terminal colors.

![Preview](preview.png)

## Requirements

This script is made to work with `feh`, `nitrogen`, 
`XFCE`, `GNOME`, `KDE`, `MATE`, `CINNAMON`, `LXDE` or  `Sway`, having one of those is a requirement.
## Install
```
git clone https://github.com/thevinter/styli.sh .config/styl.sh
./.config/styli.sh
```

## Usage
```
# for deviant
styli.sh --artist deviant artist

# for bing daily wallpaper
styli.sh --bing 

# from a directory with wallpapers like Pictures folder
styli.sh --directory path

# for usage
styli.sh --help

# wallpaper from a link
styli.sh --link source

# wallpaper from picsum
styli.sh --picsum

# for subreddits
styli.sh --subreddit subreddit

# search on unsplash
styli.sh --search string

# save current wallpaper to $HOME/Pictures/wallpapers
styli.sh --save
```
## KDE, GNOME, XFCE & Sway
KDE, GNOME, XFCE and Sway are natively supported without the need of feh. The script currently does not allow to scale the image.
To use their built-in background managers use the appropriate flag.

## Tips And Tricks
To set a new background every time you reboot your computer add the following to your ```i3/config``` file (or any other WM config)
```
exec_always path/to/script/styli.sh
```

To change background every hour launch the following command
```
crontab -e
```
and add the following to the opened file
```
@hourly path/to/script/styli.sh
```

## Custom subreddits
To manage custom subreddits just edit the ```subreddits``` file by placing there all your desired communities, one for each newline

