---
layout: page
title: Linux tips and tricks
tagline: Various linux tips I keep forgetting about
tags: linux, tips
---
{% include JB/setup %}

Below is a set of notes to myself regarding various Linux tips and tricks, mainly applicable to Debian/Raspbian distributions: 

* TOC
{:toc}

--- 

### Installing / Uninstalling packages
* To install a package: `sudo apt-get install <package/app name>`
* To list installed packages: `dpkg --get-selections | grep -v deinstall`
* To remove an application/package: `sudo apt-get –purge remove <package/app name>`

--- 

### Customizing hostname
* Edit `/etc/hostname` and replace the currently assigned name with a new customzed name
* Also edit `etc/hosts` and replace the current name on the last line starting with `127.0.0.1` with the new customized name.
* Reboot

--- 

### Networking
* To check which UDP and TCP ports are currently in use: `netstat -atun` and/or `(sudo) lsof -i`
* To search for all IP addresses used in the local 192.168.0.xxx subnet: `nmap -sP 192.168.0.0/24`
* To check the open ports on a specific IP address: `nmap 192.168.0.xxx`
* To check ethernet bandwidth, install iperf `sudo apt-get install iperf` then on server side: `iperf -s`, and on client side: `iperf -c <IP of the server>`

---

### Services / Daemons

* To create a daemon executed automatically at boot, create an executable script in /etc/init.d, following the recommanded format/template
* To add this service: `sudo update-rc.d <name of the script> defaults`
* To remove the service: `sudo update-rc.d <name of the script> remove`
* To manually start/stop/get status from a service: `sudo service <name> start|stop|status` or `sudo /etc/init.d/<name> start|stop|status`
* To check that a particular daemon is running: `ps -A | grep <daemon name>`

--- 

### Files & Directories

* To display a file tree directly in the console : `tree -C <dir>`
* To find files modified in the last X days :`find . -mtime -X -print`
* To list all sub-directories and their size: `ls -p | grep “/” | xargs du -sh`
* To display the total size of a directory:  	`du -sh <dir>`
* To search & replace over multiple files : `find . -name “*.c” -print | xargs sed -i ‘s/\bxxxx\b/yyyy/g’ `
* To find a file but excluding some sub-directory from the search: `find . <....> -not -path */dirToExclude/* `
* To search for a file in compresssed archives: `for file in $(find <...>);	do tar -tvf $file | grep “fichier”;`
* To sync the content of two directories: `rsync -a src/ dst/`
* to print content of a file with line numbers at the beginning of each line: `less -N <file>`
* To look for any stuff opened by anyone: `sudo lsof | grep <name of interest>`
* To delete all files smaller than a given size: `find . -size -100k -type f -delete`

--- 

### Console 
* To come back to previous directory after a cd : `cd -`
* To get output traces both on stdout and in a file: `<command> | tee trace.log`
* To search in command history: `Ctrl+R`

--- 

### Text search
* to search text in files, printing found occurrence line number, recursively, ignoring case, ignoring binary files: `grep -nriI <text> <search pattern>`

--- 

### Disk space clean-up
* `ncdu` (NCurses based Disk Usage) is just the simplest most efficient console-based way to spot largest directories, without having to remember any command line.

--- 

### Share a folder with SAMBA
* Install SAMBA
<pre><code>sudo apt-get install samba samba-common-bin
</code></pre>
* edit `/etc/samba/smb.conf`, customize the "workgroup" parameter (e.g. workgroup=WORKGROUP), then add an entry for the shared folder at the end of the config file, for example:

<pre><code>[DisplayNameOfTheShare]
	comment= description of this shared dir
	path=/path/to/folder
	browseable=Yes
	writeable=Yes
	only guest=no
	create mask=0777
	directory mask=0777
	public=no
</code></pre>

* Add a samba user (e.g. pi) to access this folder:

<pre><code>smbpasswd -a pi
</code></pre>

---

### Automounting a FAT-formatted USB drive

- A memo to myself to auto-mount a FAT drive at boot WITH permissions for anyone to write (cf umask=0000 option), with this line in `/etc/fstab`:

<pre><code>/dev/sda1 /media/usb vfat auto,users,rw,uid=pi,gid=pi,umask=0000 0 0
</code></pre>
--- 

### Authorize ssh access from a known machine without password
* on the local machine that you wish to declare as authorized to access the remote machine, generate (if not already available) the ssh public key (just type Enter when prompted for passphrase):
<pre><code>ssh-keygen
</code></pre>

* then send this public key to the remote machine you want to access without a password, e.g.:
<pre><code>ssh-copy-id -i ~/.ssh/id_rsa.pub pi@192.168.0.13
</code></pre>

This will in practice copy the local machine's public key (stored locally in `~/.ssh/id_rsa.pub` after executing `ssh-keygen`) into the `~/.ssh/authorized_keys` file on the remote machine.



