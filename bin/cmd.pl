#!/usr/bin/perl
# a command interface to Net::LastFMAPI
use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/../lib";
use Net::LastFMAPI;

die "usage: $0 user.whatEver something=nothing nothing=Some Things etc=etc\n" unless @ARGV;
if (exists $Net::LastFMAPI::methods->{lc($ARGV[0])}) {
    my $method = shift @ARGV;
    my %params;
    my $args = "@ARGV";
    while ($args =~ m{\G *(\S+)=(.*?)(?= *\S+=|$)}g) {
        $params{$1} = $2;
    }
    say lastfm($method, %params);
}
else {
    say "Bad command or file name.";
}
