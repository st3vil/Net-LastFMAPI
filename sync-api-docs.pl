#!/usr/bin/perl
use strict;
use warnings;
use v5.10;
use File::Slurp;
use lib "$ENV{HOME}/pquery-pm/lib";
use pQuery;

my $file = "lib/Net/LastFMAPI.pm";
-f $file or die "where's the $file at?";

my @methods;
pQuery("http://www.last.fm/api/intro")
->find("div#leftcol .wspanel ul li")
->each(sub{
    sleep 1;
    $_ = pQuery($_)->html;
    say "studying: $_";
    m{<a href="(/api/show/\?service=\d+)">(.+)</a>} || die "not <a>: $_";
    my $method = $2;
    $_ = pQuery("http://www.last.fm$1")->find("div#wsdescriptor")->html;
    my $auth = m{This service requires authentication};
    my $sig = m{<span class="param">api_sig</span>};
    my $post = m{must be accessed with an HTTP POST request};
    push @methods, {
        method => $method,
        post => $post,
        signed => $sig,
        auth => $auth,
    };
});


my @new;
my @old = read_file($file);
push @new, shift @old until $new[-1] =~ /^my \$methods = {/;
say shift @old until $old[0] =~ /^};/;

for my $m (@methods) {
    my $attributes = join ", ", map { "$_ => 1" } grep { $m->{$_} } qw{auth post signed};
    push @new, sprintf("    '%s' => { %s },\n", $m->{method}, $attributes);
}
push @new, @old;
write_file($file, @new);

say "done.";
