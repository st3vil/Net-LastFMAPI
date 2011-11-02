#!/usr/bin/perl
# submit scrobbles
use strict;
use warnings;
use v5.10;
use File::Slurp;
use LastFuckingM;

my $bullytime = 0 if "@ARGV" =~ /bullshit-timestamps/;

my @log = read_file('../scrobbler.log');
my @set;
for (@log) {
    next if /^#/;
    my ($artist, $album, $song, $trackpos, $length, $rating, $ts) = split /\t/;
    if (defined $bullytime) {
        $ts = time - ((@log * 60 * 5) - ($bullytime++ * 60 * 5));
    }
    say "(".scalar(localtime($ts)).") $artist - $song";
    push @set, {
        artist => $artist,
        album => $album,
        track => $song,
        timestamp => $ts,
    };
    submat() if @set == 50
}
submat() if @set;

sub submat {
    my $res = lastfm(
        "track.scrobble",
        @set,
    );
    my $n = @set;
    unless ($res =~ /accepted="$n"/) {
        say "For fucks sake: $res";
        say "Consider --bullshit-timestamps" if $res =~ /Timestamp failed/;
        exit;
    }
    @set = ();
}

