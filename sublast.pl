#!/usr/bin/perl
use strict;
use warnings;
use v5.10;
use File::Slurp;
use LastFuckingM;

my $bullytime = "@ARGV" =~ /bullshit-timestamps/;

my @log = read_file('../scrobbler.log');
my $i = 0;
for (@log) {
    next if /^#/;
    my ($artist, $album, $song, $trackpos, $length, $rating, $ts) = split /\t/;
    if ($bullytime) {
        $ts = time - ((@log * 60 * 5) - ($i * 60 * 5));
    }
    $i++;
    say "(".scalar(localtime($ts))." $artist - $song";
    my $res = LastFuckingM::req(
        "track.scrobble",
        artist => $artist,
        album => $album,
        track => $song,
        timestamp => $ts,
    );
    unless ($res =~ /accepted="1"/) {
        say "For fucks sake: $res";
        say "Consider --bullshit-timestamps" if $res =~ /Timestamp failed/;
        exit;
    }
    sleep 1;
};


