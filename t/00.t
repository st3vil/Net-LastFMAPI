#!/usr/bin/perl
use strict;
use warnings;
use v5.10;
use Test::More;
use FindBin '$Bin';
use lib "$Bin/..";
use LastFuckingM;
use Storable 'dclone';

eval {
lastfm(
    "track.scrobble",
    ({
        artist => "Robbie Basho",
        track => "Wounded Knee Soliloquy",
        timestamp => time() - 30,
    }) x 51,
)
};
like $@, qr/^too multitudinous \(limit 50\)/, "too multitudinously scrobbling";

our @uaaction = ();
our $uaaction = sub {
    push @uaaction, dclone([@_]);
    return YouAye->new(content => '<lfm status="ok">');
};
package YouAye;
sub new {
    shift;
    return bless {@_}, __PACKAGE__;
}
sub get {
    shift;
    $main::uaaction->("get", @_);
}
sub post {
    shift;
    $main::uaaction->("post", @_);
}
sub decoded_content {
    shift->{content};
}
sub is_success { 1 }
package main;
$LastFuckingM::ua = YouAye->new();

lastfm(
    "track.scrobble",
    ({
        artist => "Robbie Basho",
        track => "Wounded Knee Soliloquy",
        timestamp => 1320224836 - 30,
    }) x 4,
);

is($uaaction[-1]->[0], "post", "scrobbles POSTed");
is($uaaction[-1]->[3]->{api_sig}, "30c3b59dc26c6d67cdb3fef190ea47ba", "request signed");

lastfm(
    "user.getInfo",
);

is($uaaction[-1]->[0], "get", "info GETed");
is($uaaction[-1]->[1], 'http://ws.audioscrobbler.com/2.0/?api_key=dfab9b1c7357c55028c84b9a8fb68880&method=user.getInfo', "uri");

