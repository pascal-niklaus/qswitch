#!/usr/bin/perl

use File::Spec;
use File::Basename;
use Cwd;
use Getopt::Long;
use List::Util;
use Data::Dumper;

use Text::Fuzzy;
## sudo perl -MCPAN -e 'install Text::Fuzzy'

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
    'add!' => undef,
    'remove!' => undef,
    'modify!' => undef,
    'list!' => undef,
    'edit!' => undef,
    'nano!' => undef,
    'kate!' => undef,
    'emacs!' => undef,
    '<>' => sub {    
        my ($command, $value, $option, $other_opts) = @_;
        return  Getopt::Complete::directories(@_)
                if( $other_opts->{'<>'} ) ;
        return []
            if( $other_opts->{add} );
        return [ keys %{readTagsDirs($scfile)} ];

    }
    );

## ------------- process command line options 

sub writeTagsDirs($$) {
    my ($file, $c)  = @_;
    open OUT,">",$file || die "Could not open file: $!";    
    my $tab = List::Util::max map { /^([^ ,]+)/; length($1); } keys %$c;   
    foreach my $k (sort keys %$c) {
        print OUT sprintf("%*s %s",-$tab-1,$k.',',$c->{$k}),"\n";
    }
    close OUT;
}

my $editor = 'nano';

if(!($editor = $ENV{SELECTED_EDITOR})) {
    my $edfile = "$ENV{HOME}/.selected_editor";
    if( -e $edfile ) {
        open ( IN,"<",$edfile ) || die "Could not open file: $!";
        while(<IN>) {
            $editor = $2
                if(/SELECTED_EDITOR *= *(['"]?)(.+)\g1/);
        }
        close IN;   
    }
}

$ARGS{edit} //= ($ARGS{kate} | $ARGS{emacs} | $ARGS{nano});
$editor = "kate -n" if($ARGS{kate});      
$editor = "emacs" if($ARGS{emacs});

# ------------- edit list with specified editor

if($ARGS{edit}) {
    print "$editor $scfile\n";
    exit 0;
} 

# ------------- print list on screen

if($ARGS{list}) {
    print "cat '$scfile'";
    exit 0;
}

my $tag = (shift @{$ARGS{'<>'}}) || die "No alias provided";

# ------------- add or remove directory

if($ARGS{add} || $ARGS{remove} || $ARGS{modify}) {
    my $c = readTagsDirs($scfile);
    if($ARGS{remove}) {
        delete $c->{$tag} || die "Alias '$tag' not found";
    } else {
        my $dir = shift @{$ARGS{'<>'}} || '.';
        $dir = Cwd::getcwd().'/'.$dir
            if($dir!~/^\//);
        $dir = Cwd::abs_path($dir);
        die "Alias already exists! Use --modify instead" 
            if($add && $c->{$tag});
        die "Alias does not exists! Use --add instead"
            if($mod && !$c->{$tag});
        $c->{$tag} = $dir;
    } 
    writeTagsDirs($scfile,$c);    
    exit 0;
}

# ------------- search entries and 'cd' to first match

my $c = readTagsDirs($scfile);

my %dists = ();

my $tagfuzzy = Text::Fuzzy->new($tag);
foreach my $k (sort keys %{$c}) {
    if($k =~ /$tag/i) {
        $dists{$k} = $tagfuzzy->distance($k);
    }
}
my @keys_by_dist = sort { $dists{$a} <=> $dists{$b} } keys %dists;

if (scalar(@keys_by_dist) == 0) {
    print STDERR "No matching alias found for '$tag'!\n";
    print ".\n";
    sys.exit(0);
}

if (scalar(@keys_by_dist) > 1) {
    print STDERR "MULTIPLE TAGS MATCH, TAKING CLOSEST:";
    foreach my $v (@keys_by_dist) { print STDERR " $v"; }
    print STDERR "\n";
}

print $c->{$keys_by_dist[0]},"\n";

1;
