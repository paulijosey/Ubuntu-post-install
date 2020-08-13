#!/bin/bash

# TODO: add dot file install process
while getopts ":a:r:b:p:h" o; do case "${o}" in
	h) printf "Optional arguments for custom use:\\n  -r: Dotfiles repository (local file or url)\\n  -p: Dependencies and programs csv (local file or url)\\n  -h: Show this message\\n" && exit ;;
	r) dotfilesrepo=${OPTARG} && git ls-remote "$dotfilesrepo" || exit ;;
	b) repobranch=${OPTARG} ;;
	p) progsfile=${OPTARG} ;;
	*) printf "Invalid option: -%s\\n" "$OPTARG" && exit ;;
esac done

# TODO: change default options to my repo
[ -z "$dotfilesrepo" ] && dotfilesrepo=""
[ -z "$progsfile" ] && progsfile=""
[ -z "$repobranch" ] && repobranch="master"

# figure out which installer to use
# TODO: Extend to multiple package managers
if type apt >/dev/null 2>&1; then
	echo 'Using apt as package manager'
	installpkg(){ apt-get install -y "$1" >/dev/null 2>&1 ;}
	grepseq="\"^[PGU]*,\""
fi

# programs that are neccessary for the install process
basic_programs=(curl git)

maininstall() { # Installs all needed programs from main repo.
	echo 'installing ' $1
	installpkg "$1"
	}

pipinstall() { \
	echo 'Installing Python Package ' $1
	command -v pip || installpkg python-pip >/dev/null 2>&1
	yes | pip install "$1"
	}

gitmakeinstall() {
	echo 'Installing Git Repo ' $1
	progname="$(basename "$1" .git)"
	dir="$repodir/$progname"
	sudo -u "$name" git clone --depth 1 "$1" "$dir" >/dev/null 2>&1 || { cd "$dir" || return ; sudo -u "$name" git pull --force origin master;}
	cd "$dir" || exit
	make >/dev/null 2>&1
	make install >/dev/null 2>&1
	cd /tmp || return ;}

# function to read a csv file in the form
# TAG	|	NAME/GIT URL	|	PURPOSE/DESCRIPTION
installationloop() { \
	([ -f "$progsfile" ] && cp "$progsfile" /tmp/progs.csv) || curl -Ls "$progsfile" | sed '/^#/d' | eval grep "$grepseq" > /tmp/progs.csv
	total=$(wc -l < /tmp/progs.csv)
	aurinstalled=$(pacman -Qqm)
	while IFS=, read -r tag program comment; do
		n=$((n+1))
		echo "$comment" | grep "^\".*\"$" >/dev/null 2>&1 && comment="$(echo "$comment" | sed "s/\(^\"\|\"$\)//g")"
		case "$tag" in
			"G") gitmakeinstall "$program" "$comment" ;;
			"P") pipinstall "$program" "$comment" ;;
			*) maininstall "$program" "$comment" ;;
		esac
	done < /tmp/progs.csv ;}


########################### The main install process ##################################################

# Update system
cd ~
#sudo apt update

# install all programs from basic_programs list
for i in ${basic_programs[@]}
do
	maininstall "$i"
done

# The command that does all the installing. Reads the progs.csv file and
# installs each needed program the way required. Be sure to run this only after
# the user has been created and has priviledges to run sudo without a password
# and all build dependencies are installed.
echo 'start installation'
installationloop

