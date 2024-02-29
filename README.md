# qswitch - quickly switch directory from bash prompt

## Purpose

I use the command line (shell) for almost everything.  However,
sometimes I found myself spending more time `cd`'ing from directory to
directory than actually doing something useful ;-)

To avoid this, I wrote a small script that allows changing directories
using "aliases" defined in a separate file.  These aliases are
searched for (partial) matches, and a `cd` to this directory is
executed. The script allows for TAB completion of these aliases (and
directories, if new ones are specified) and thus is very fast to use.

## Usage

### Change to a certain directory

Type `qsw` followed by an alias or part of an alias. TAB completion
is provided. Note that `qsw` will `cd` to the directory with the
best match based on some fuzzy matching algorithm. 

`qsw alias`

### Add, remove, and modify aliases

`qsw --add <alias> <directory>   # e.g. qsw --add myshortcut .`

`qsw --remove alias`

`qsw --modify alias directory`

Aliases can be added/removed/modified as indicated above. Tab
completion works for the alias (e.g. remove and modify) and the
directory (add, 2nd argument).

The use of an "--option" may be unorthodox for "subcommands" with
arguments but has the advantage that it does not interfere with TAB
completion of the aliases.

### List all aliases

`qsw --list`

### Edit the alias definitions

For major cleanups, it is possible to edit the alias file, optionally
specifying the editor to be used. By default, the editor specified by
the environment variable `SELECTED_EDITOR` is used, or
`~/.selected_editor` scanned for such a definition. Alternatively,
some editors can be specified on the command line. I exclusively use
`nano`, `emacs`, and sometimes `kate`, but the script is simple to
adapt if you have other preferences. Being able to chose the editor is
important: For example, `nano` will fail terribly within an emacs
eshell.

`qsw --edit`

`qsw --nano`

`qsw --kate`

`qsw --emacs`

The alias definition file has the following format

```
alias1, /full/path/directory1
alias2, /full/path/directory2
```

## Installation

I have two versions of the script. The old one is written in Perl and
I used it with `bash`. The new one is written in Python and I use it
with `fish`, which recently has become my default shell because it is
so much more intuitive, not least for programming.

The new Python script should also work with bash, but I have not tried it.

### Perl script (which I used with `bash`)

Commands run from bash cannot change the current directory of the
calling process. Therefore, the script is executed in two
stages. First, a bash function (here named `qsw`, for "Quick SWitch",
which is very fast to type) executes the perl script
`_qswitch.pl`. The output of the perl script is captured and used to
`cd` into the selected directory.

Copy the `qswitch.pl` file to a directory that is writable (the alias
file will be placed in the same directory). Then, create a symlink
from `/usr/local/bin/_qswitch` to `qswitch.pl`.

In my `.bashrc` file, I have:

```
qsw() {
    CD=$( _qswitch $@)
    cd "$CD"
}

_qsw_complete() {qsw 
    COMPREPLY=($(COMP_CWORD=$COMP_CWORD perl /usr/local/bin/_qswitch ${COMP_WORDS[@]:0} ))
}

complete -F _qsw_complete qsw
```

### Python script (which I use with `fish`)

With my switch to `fish`, I translated my old Perl script to Python.

First, two environment variables with the program to execute and the
location of the shortcut text file have to be set. I do this in a
script in `~/.config/fish/conf.d`. 

```
set -gx QSW_DB /path/to/your/shortcuts.txt
set -gx QSW_EXE /path/to/qswitch.py
```

Then, a function named `qsw` (or whatever) needs to be defined. I do
this in `~/.config/functions`.

```
function qsw
    set -l DIR (command  $QSW_EXE $argv)
    if test $status = 0
        cd $DIR
    end
end
```

TAB completion is added in `~/.config/fish/completions/qsw.fish`:

```
## completions of shortcuts
function __qsw_complete_shortcuts
    cat $QSW_DB | cut -d"," -f1
end

## qsw --add ALIAS PATH
complete -f -c qsw -l add --no-files
## qsw --edit [--kate|--emacs|--nano]
complete -f -c qsw -l edit --no-files
## qsw --list
complete -f -c qsw -l list --no-files
## qsw --modify ALIAS PATH
complete -f -c qsw -l modify -ra "(__qsw_complete_shortcuts)"
## qsw --remove ALIAS
complete -f -c qsw -l remove -ra "(__qsw_complete_shortcuts)"
## qsw ALIAS
complete -f -c qsw -a "(__qsw_complete_shortcuts)"
```
