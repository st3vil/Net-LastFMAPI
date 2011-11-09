#!/usr/bin/perl
use strict;
use warnings;
use v5.10;
use File::Slurp;
use lib "$ENV{HOME}/pquery-pm/lib";
use pQuery;
use Time::HiRes "usleep";

my $file = "lib/Net/LastFMAPI.pm";
-f $file or die "where's the $file at?";

my @methods;
pQuery("http://www.last.fm/api/intro")
->find("div#leftcol .wspanel ul li")
->each(sub{
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
    usleep 10000;
});


my @new;
my @old = read_file($file);
push @new, shift @old until $new[-1] =~ /^our \$methods = {/;
say shift @old until $old[0] =~ /^};/;

for my $m (@methods) {
    my $method = lc delete $m->{method};
    if ($method eq "user.getinfo") {
        $m->{auth} = 1;
    }
    push @new, sprintf("    '%s' => {%s},\n",
        $method,
        join (", ", map { "$_ => $m->{$_}" }
                    grep { $m->{$_} } qw{auth post signed}
        ),
    );
}
push @new, @old;
write_file($file, @new);

say "done.";
