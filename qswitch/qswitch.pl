#!/usr/bin/perl

use File::Spec;
use File::Basename;
use Getopt::Long;
use List::Util qw(max);

## ------------- tab completion

BEGIN {
    my $me = File::Spec->rel2abs($0);
    $me = readlink($me) if -l $me;
    (undef, my $directory, undef) = 
        File::Spec->splitpath( $me );
    $directory =~ s/\/$//;
    our $scfile = "$directory/shortcuts.txt";

    sub readTagsDirs($) {
        my $file = shift;
        my %entries;
        open (my $fh, "<", $file) || die "can't open file: $!";        
        while(<$fh>) {
            $entries{$1} = $2
                if(/^(.+?) *, *(.+?) *$/);
        }
        close $fh;
        return \%entries;
    }      
}

use Getopt::Complete (
    'list!' => undef,
    'edit!' => undef,
    'nano!' => undef,
    'kate!' => undef,
    'emacs!' => undef,
    '<>' => sub {       
        return [ keys readTagsDirs($scfile) ];
    }
    );

## ------------- process command line options 

my $edt = undef;
my $lst = undef;
my $kate = undef;
my $emacs = undef;
my $nano = undef;
my $editor = 'nano';                  # my default editor

GetOptions(
    'edit' => \$edt,
    'list' => \$lst,
    'kate' => \$kate,
    'emacs' => \$emacs,
    'nano' => \$nano);

$edt |= ($kate | $emacs | $nano);     # editor specs imply --edit
$editor = "kate -n" if($kate);      
$editor = "emacs" if($emacs);

my $tag = shift @ARGV;                # "tag" to search for

# ------------- edit list with specified editor

if($edt) {
    my $cmd = "$editor $scfile\n";
    print "$cmd";
    exit 0;
} 

# ------------- print list on screen

if($lst) {
    my $c = readTagsDirs($scfile);
    my $tab = max map { /^([^ ,]+)/; length($1); } keys $c;   
    foreach my $k (sort keys $c) {
        print "echo '",sprintf("%*s %s",-$tab,$k,$c->{$k}),"'\n";
    }
    exit 0;
}

# ------------- search entries and 'cd' to first match

if($tag eq "") {
    print "echo No shortcut specified!\n";
    exit 1;
} else {
    my $c = readTagsDirs($scfile);
    foreach my $k (sort keys $c) {
        if($k =~ /$tag/i) {
            print "cd $c->{$k}\n";
            exit 0;
        }       
    }
}

print "echo No shortcut found!\n";

1;
