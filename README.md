# qswitch - quickly switch directory from bash prompt

## Purpose

I use the command line (bash shell) for almost everything.  However,
sometimes I found myself spending more time cd'ing from directory to
directory than actually doing something useful ;-)

To avoid this, I wrote a small perl script that allows changing
directories using "aliases" defined in a separate file.  These aliases
are searched for (partial) matches, and a "cd" to this directory
executed. The perl script also allows for TAB completion of the
aliases.

Since changing the current directory in the perl process would not
change the current directory of the bash prompt, the script is
executed in two stages. First, a bash function (here named `qsw`, for
"quick switch", which is very fast to type) executes the perl script
`qswitch.pl`. The output of the perl script is directed to a temporary
file which is the sourced from the bash function.

## Usage

### Change to a certain directory

Type `qsw` followed by an alias or part of an alias. TAB completion
also is provided. Note that `qsw` will cd to the first directory for
which the alias matches, even if a "better" match would exist later in
the list. Therefore, avoid aliases that would be partial matches of others.

`qsw alias`

### Edit the alias definitions

It is possible to specify the editor to be used.  I exclusively use
`nano`, `emacs`, and sometimes `kate`, but the script is simple to
adapt if you have other preferences. Being able to chose the editor
is important: For example, `nano` will fail terribly within an emacs'
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

### List all aliases

`qsw --list`

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

Then, type `qsw --edit`, define some aliases, and enjoy fast cd'ing...
