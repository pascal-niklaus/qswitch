# qswitch - quickly switch directory from bash prompt

## Purpose

I use the command line (bash shell) for almost everything.  However,
sometimes I found myself spending more time cd'ing from directory to
directory than actually doing something useful ;-)

To avoid this, I wrote a small perl script that allows changing
directories using "aliases" defined in a separate file.  These aliases
are searched for (partial) matches, and a "cd" to this directory
executed. The perl script allows for TAB completion of the
aliases (and directories, if new ones are specified).

Since changing the current directory in the perl process would not
change the current directory of the bash prompt, the script is
executed in two stages. First, a bash function (here named `qsw`, for
"Quick SWitch", which is very fast to type) executes the perl script
`qswitch.pl`. The output of the perl script is directed to a temporary
file which is then sourced from the bash function.

## Usage

### Change to a certain directory

Type `qsw` followed by an alias or part of an alias. TAB completion
also is provided. Note that `qsw` will cd to the first directory for
which the alias matches (alphabetical order), even if a "better"
(i.e. complete) match would exist later in the list. Therefore, avoid
aliases that are partial matches of others.

`qsw alias`

### Add, remove, and modify aliases

`qsw --add alias directory`

`qsw --remove alias`

`qsw --modify alias`

Aliases can be added/removed/modified as indicated above. Tab completion
works for the alias (remove and modify) and the directory (add, 2nd argument).

The use of an "--option" may be unorthodox for "subcommands" with
arguments but has the advantage that it does not interfere with TAB completion
of the aliases.

### List all aliases

`qsw --list`


### Edit the alias definitions

It is also possible to edit the alias file, optionally specifying the
editor to be used. By default, the editor specified by the environment
variable `SELECTED_EDITOR` is used, or `~/.selected_editor` scanned
for such a definition. Alternatively, some editors can be specified on
the command line. I exclusively use `nano`, `emacs`, and sometimes
`kate`, but the script is simple to adapt if you have other
preferences. Being able to chose the editor is important: For example,
`nano` will fail terribly within an emacs eshell.

`qsw --edit`

`qsw --nano`

`qsw --kate`

`qsw --emacs`

The alias definition file has the following format

```
alias1, /full/path/directory1
alias2, /full/path/directory2
```

### Installation

Copy the `qswitch.pl` file to a directory that is writable (the alias file will be placed
in the same directory). Then, create a symlink from `/usr/local/bin/_qswitch` to `qswitch.pl`.

In my `.bashrc` file, I have:

```
qsw() {
    _qswitch $@ > /tmp/qsw.bash
    source /tmp/qsw.bash
}

_qsw_complete() {
    COMPREPLY=($(COMP_CWORD=$COMP_CWORD perl /usr/local/bin/_qswitch ${COMP_WORDS[@]:0} ))
}

complete -F _qsw_complete qsw
```

Then, type `qsw --add alias directory` to define an aliases, and enjoy fast cd'ing...
