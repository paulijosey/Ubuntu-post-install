#!/bin/bash

# figure out which installer to use
# TODO: Extend to multiple package managers
if type apt >/dev/null 2>&1; then
	echo 'Using apt as package manager'
	installpkg(){ apt-get install -y "$1" >/dev/null 2>&1 ;}
	grepseq="\"^[PGU]*,\""
fi

# programs from the standard ubuntu repos
basic_programs=(htop \		# system monitor
		gotop \		# system monitor
		vim \		# text editor
		neovim \	# text editor
		wget )

# function to read a csv file in the form
# TAG	|	NAME/GIT URL	|	PURPOSE/DESCRIPTION


maininstall() { # Installs all needed programs from main repo.
	echo 'installing ' $1
	installpkg "$1"
	}

pipinstall() { \
	echo 'Installing Python Package ' $1
	command -v pip || installpkg python-pip >/dev/null 2>&1
	yes | pip install "$1"
	}

# Update system
cd ~
#sudo apt update

# install all programs from basic_programs list
for i in ${basic_programs[@]}
do
	maininstall "$i"
done
