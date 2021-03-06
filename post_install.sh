#!/bin/sh

# TODO: add dot file install process
while getopts ":a:r:b:p:h" o; do case "${o}" in
	h) printf "Optional arguments for custom use:\\n  -r: Dotfiles repository (local file or url)\\n  -p: Dependencies and programs csv (local file or url)\\n  -h: Show this message\\n" && exit ;;
	r) dotfilesrepo=${OPTARG} && git ls-remote "$dotfilesrepo" || exit ;;
	b) repobranch=${OPTARG} ;;
	p) progsfile=${OPTARG} ;;
	*) printf "Invalid option: -%s\\n" "$OPTARG" && exit ;;
esac done

# TODO: change default dorfile options to my repo
[ -z "$dotfilesrepo" ] && dotfilesrepo=""
[ -z "$progsfile" ] && progsfile="https://github.com/paulijosey/Ubuntu-post-install/blob/master/progs.csv"
[ -z "$repobranch" ] && repobranch="master"

# figure out which installer to use
# TODO: Extend to multiple package managers
if type apt >/dev/null 2>&1; then
	echo 'Using apt as package manager'
	installpkg(){ apt-get install -y "$1" >/dev/null 2>&1 ;}
fi

# programs that are neccessary for the install process
basic_programs=(curl git csvkit)

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

PPAadd(){
	echo 'addind PPA ' $1
	curl -s "$1" | sudo apt-key --keyring /etc/apt/trusted.gpg.d/"$2" add -
	}


# function to read a csv file in the form
# TAG	|	NAME/GIT URL	|	PURPOSE/DESCRIPTION
installationloop() { \
	([ -f "$progsfile" ] && cp "$progsfile" /tmp/progs.csv) || curl -Ls "$progsfile" | sed '/^#/d' | eval grep "$grepseq" > /tmp/progs.csv
	n=$(wc -l < /tmp/progs.csv)

	# first add all the PPA's
	echo 'fetching and adding needed PPA's
	while [ 1 -lt $n ]; do
		line="$n"','"$n"'p'
		program=$(csvcut -c 2 /tmp/progs.csv | sed -n "$line")
		tag=$(csvcut -c 1 /tmp/progs.csv | sed -n "$line")
		PPA=$(csvcut -c 3 /tmp/progs.csv | sed -n "$line")

		n=$((n-1))
		case "$tag" in
			"R") PPAadd "$program" "$PPA" ;;
			*) ;;
		esac
	done

	# now install the programs
	n=$(wc -l < /tmp/progs.csv)
	while [ 1 -lt $n ]; do
		line="$n"','"$n"'p'
		program=$(csvcut -c 2 /tmp/progs.csv | sed -n "$line")
		tag=$(csvcut -c 1 /tmp/progs.csv | sed -n "$line")

		n=$((n-1))
		case "$tag" in
			"G") gitmakeinstall "$program" "$comment" ;;
			"P") pipinstall "$program" "$comment" ;;
			"S") maininstall "$program" "$comment" ;;
			*) ;;
		esac
	done < /tmp/progs.csv ;}


########################### The main install process ##################################################

# Update system
cd ~
sudo apt update

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
echo 'Installation finished'
