#!/usr/bin/perl
# submit scrobbles from a scrobbler.log
# format as per http://www.audioscrobbler.net/wiki/Portable_Player_Logging
use strict;
use warnings;
use v5.10;
use FindBin '$Bin';
use lib "$Bin/../lib";
use Net::LastFMAPI;

die "usage: $0 user.getInfo something=nothing something=nothing\n" unless @ARGV;
if (exists $Net::LastFMAPI::methods->{lc($ARGV[0])}) {
    my $method = shift @ARGV;
    my %params;
    my $args = "@ARGV";
    while ($args =~ m{\G *(\S+)=(.*?)(?= *\S+=|$)}g) {
        $params{$1} = $2;
        shift @_;
    }
    say lastfm($method, %params);
}
else {
    say "Bad command or file name.";
}
