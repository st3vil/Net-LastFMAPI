#!/usr/bin/perl
use strict;
use warnings;
use v5.10;
use LastFuckingM;

$LastFuckingM::json = 1;
my $res = LastFuckingM::req(
    "artist.getSimilar",
    artist => "Robbie Basho",
);
use YAML::Syck;
my $simlar = $res->{similarartists};
say "Arists similar to ".$simlar->{'@attr'}->{artist}.":";
say join ", ", map { $_->{name} } @{$simlar->{artist}}

