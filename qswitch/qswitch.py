#!/usr/bin/env python3

import argparse
import sys
import os
import rapidfuzz as fz
import pathlib
import subprocess
from yachalk import chalk


def fullpath(x):
    """Expand to full path."""
    return pathlib.Path(x).resolve()


def read_db(db):
    """Read alias database into dict."""
    aliases = dict()
    with open(db) as h:
        for line in h:
            line = line.strip()
            if len(line) == 0:
                continue
            (key, path) = line.split(',', 1)
            aliases[key.strip()] = path.strip()
    return aliases


def write_db(db, filename):
    """Write nicely-formatted database into file."""
    longest_key = max([len(k) for k in db.keys()])
    db_sorted = dict(sorted(db.items()))
    with open(filename, "w") as h:
        for (k, v) in db_sorted.items():
            k = k+","
            print(f"{k:{longest_key+1}} {v}", file=h)


def print_db(db, handle):
    """Print the database."""
    (fg, bg) = [int(x) for x in os.environ["COLORFGBG"].split(";")]
    longest_key = max([len(k) for k in db.keys()])
    db_sorted = dict(sorted(db.items()))
    i = 0
    for (k, v) in db_sorted.items():
        k = k+":"
        i += 1
        if i % 2 == 0:
            print(chalk.bold(f"{k:{longest_key+1}} {v}"), file=handle)
        else:
            print(chalk.dim(f"{k:{longest_key+1}} {v}"), file=handle)


if __name__ == '__main__':
    # ----- command line arguments
    parser = argparse.ArgumentParser(
        description='Quickly change directory'
    )
    parser.add_argument(
        'alias', metavar='PATH', type=str, nargs='?',
        help="Table (.csv file) with preferences and topics")
    parser.add_argument(
        '--add', metavar='ALIAS', type=str)
    parser.add_argument(
        '--remove', metavar='ALIAS', type=str)
    parser.add_argument(
        '--modify', metavar='ALIAS', type=str)
    parser.add_argument(
        '--list', action='store_true')
    parser.add_argument(
        '--edit', action='store_true')
    parser.add_argument(
        '--kate', action='store_true')
    parser.add_argument(
        '--nano', action='store_true')
    parser.add_argument(
        '--emacs', action='store_true')
    args = parser.parse_args()

    ## do we edit ?
    edit = args.kate | args.nano | args.emacs | args.edit
    if args.kate:
        editor = 'kate -n'
    elif args.emacs:
        editor = 'emacs -nw'
    else:
        editor = 'nano'

    ## read the db
    db = os.environ['QSW_DB']
    aliases = read_db(db)
    akeys = aliases.keys()

    ## specific commands
    if args.list:
        print_db(aliases, sys.stderr)
    elif args.add:
        if args.alias is None:
            print(f"A path must be provided for alias {args.add}",
                  file=sys.stderr)
        else:
            fp = fullpath(args.alias)
            print("added: {}".format(fp))
            aliases[args.add] = fp
            write_db(aliases, db)
    elif args.remove:
        if args.remove in akeys:
            del aliases[args.remove]
            write_db(aliases, db)
        else:
            print(f"Alias {args.remove} not contained in database",
                  file=sys.stderr)
    elif args.modify:
        if args.alias is None:
            print(f"A path must be provided for alias {args.modify}",
                  file=sys.stderr)
        elif args.modify not in akeys:
            print(f"Alias {args.modify} not contained in database",
                  file=sys.stderr)
        else:
            aliases[args.modify] = args.alias
            write_db(aliases, db)
        sys.exit(1)
    elif args.edit:
        subprocess.run(f"{editor} {db}", shell=True)
    else:
        if args.alias is None:
            print("An alias must be provided", file=sys.stderr)
        else:
            best = [(k, fz.fuzz.ratio(k, args.alias)) for k in akeys]
            best = sorted(best, key=lambda x: x[1], reverse=True)
            (key, score) = best[0]
            path = aliases[key]
            if score < 80:
                print((f"No reasonably match found for '{args.alias}',"
                      f" best was '{best[1][0]}' at {score:.1f}%"),
                      file=sys.stderr)
            else:
                if score != 100:
                    print(f"Best match was for '{key}', score={score:.1f}%",
                          file=sys.stderr)
                print(path)
                sys.exit(0)
    sys.exit(1)
