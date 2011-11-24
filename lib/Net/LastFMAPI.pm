package Net::LastFMAPI;
use strict;
use warnings;
use v5.10;
use LWP::UserAgent;
use Digest::MD5 'md5_hex';
use JSON::XS;
use File::Slurp;
use File::Path 'make_path';
use URI;
use Exporter 'import';
our @EXPORT = ('lastfm');
use Carp;

our $VERSION = 0.3;
our $url = 'http://ws.audioscrobbler.com/2.0/';
our $api_key = 'dfab9b1c7357c55028c84b9a8fb68880';
our $secret = 'd004c86dcfa8ef4c3977b04f558535f2';
our $session_key; # see load_save_sessionkey()
our $ua = new LWP::UserAgent(agent => "Net::LastFMAPI/$VERSION");
our $username; # not important
our $xml = 0;
our $cache = 0;

our $cache_dir = "$ENV{HOME}/.net-lastfmapi-cache/";
our $sk_symlink = "$ENV{HOME}/.net-lastfmapi-sessionkey";
sub load_save_sessionkey { # see get_session_key()
    my $key = shift;
    if ($key) {
        symlink($key, $sk_symlink)
    }
    else {
        $key = readlink($sk_symlink);
    }
    $session_key = $key;
}
sub dumpfile {
    my $file = shift;
    my $json = encode_json(shift);
    write_file($file, $json);
}
sub loadfile {
    my $file = shift;
    my $json = read_file($file);
    decode_json($json);
}
#{{{
our $methods = {
    'album.addtags' => {auth => 1, post => 1, signed => 1},
    'album.getbuylinks' => {},
    'album.getinfo' => {},
    'album.getshouts' => {},
    'album.gettags' => {auth => 1, signed => 1},
    'album.gettoptags' => {},
    'album.removetag' => {auth => 1, post => 1, signed => 1},
    'album.search' => {},
    'album.share' => {auth => 1, post => 1, signed => 1},
    'artist.addtags' => {auth => 1, post => 1, signed => 1},
    'artist.getcorrection' => {},
    'artist.getevents' => {},
    'artist.getimages' => {},
    'artist.getinfo' => {},
    'artist.getpastevents' => {},
    'artist.getpodcast' => {},
    'artist.getshouts' => {},
    'artist.getsimilar' => {},
    'artist.gettags' => {auth => 1, signed => 1},
    'artist.gettopalbums' => {},
    'artist.gettopfans' => {},
    'artist.gettoptags' => {},
    'artist.gettoptracks' => {},
    'artist.removetag' => {auth => 1, post => 1, signed => 1},
    'artist.search' => {},
    'artist.share' => {auth => 1, post => 1, signed => 1},
    'artist.shout' => {auth => 1, post => 1, signed => 1},
    'auth.getmobilesession' => {signed => 1},
    'auth.getsession' => {signed => 1},
    'auth.gettoken' => {signed => 1},
    'chart.gethypedartists' => {},
    'chart.gethypedtracks' => {},
    'chart.getlovedtracks' => {},
    'chart.gettopartists' => {},
    'chart.gettoptags' => {},
    'chart.gettoptracks' => {},
    'event.attend' => {auth => 1, post => 1, signed => 1},
    'event.getattendees' => {},
    'event.getinfo' => {},
    'event.getshouts' => {},
    'event.share' => {auth => 1, post => 1, signed => 1},
    'event.shout' => {auth => 1, post => 1, signed => 1},
    'geo.getevents' => {},
    'geo.getmetroartistchart' => {},
    'geo.getmetrohypeartistchart' => {},
    'geo.getmetrohypetrackchart' => {},
    'geo.getmetrotrackchart' => {},
    'geo.getmetrouniqueartistchart' => {},
    'geo.getmetrouniquetrackchart' => {},
    'geo.getmetroweeklychartlist' => {},
    'geo.getmetros' => {},
    'geo.gettopartists' => {},
    'geo.gettoptracks' => {},
    'group.gethype' => {},
    'group.getmembers' => {},
    'group.getweeklyalbumchart' => {},
    'group.getweeklyartistchart' => {},
    'group.getweeklychartlist' => {},
    'group.getweeklytrackchart' => {},
    'library.addalbum' => {auth => 1, post => 1, signed => 1},
    'library.addartist' => {auth => 1, post => 1, signed => 1},
    'library.addtrack' => {auth => 1, post => 1, signed => 1},
    'library.getalbums' => {},
    'library.getartists' => {},
    'library.gettracks' => {},
    'library.removealbum' => {auth => 1, post => 1, signed => 1},
    'library.removeartist' => {auth => 1, post => 1, signed => 1},
    'library.removescrobble' => {auth => 1, post => 1, signed => 1},
    'library.removetrack' => {auth => 1, post => 1, signed => 1},
    'playlist.addtrack' => {auth => 1, post => 1, signed => 1},
    'playlist.create' => {auth => 1, post => 1, signed => 1},
    'radio.getplaylist' => {auth => 1, signed => 1},
    'radio.search' => {},
    'radio.tune' => {auth => 1, post => 1, signed => 1},
    'tag.getinfo' => {},
    'tag.getsimilar' => {},
    'tag.gettopalbums' => {},
    'tag.gettopartists' => {},
    'tag.gettoptags' => {},
    'tag.gettoptracks' => {},
    'tag.getweeklyartistchart' => {},
    'tag.getweeklychartlist' => {},
    'tag.search' => {},
    'tasteometer.compare' => {},
    'tasteometer.comparegroup' => {},
    'track.addtags' => {auth => 1, post => 1, signed => 1},
    'track.ban' => {auth => 1, post => 1, signed => 1},
    'track.getbuylinks' => {},
    'track.getcorrection' => {},
    'track.getfingerprintmetadata' => {},
    'track.getinfo' => {},
    'track.getshouts' => {},
    'track.getsimilar' => {},
    'track.gettags' => {auth => 1, signed => 1},
    'track.gettopfans' => {},
    'track.gettoptags' => {},
    'track.love' => {auth => 1, post => 1, signed => 1},
    'track.removetag' => {auth => 1, post => 1, signed => 1},
    'track.scrobble' => {auth => 1, post => 1, signed => 1},
    'track.search' => {},
    'track.share' => {auth => 1, post => 1, signed => 1},
    'track.unban' => {auth => 1, post => 1, signed => 1},
    'track.unlove' => {auth => 1, post => 1, signed => 1},
    'track.updatenowplaying' => {auth => 1, post => 1, signed => 1},
    'user.getartisttracks' => {},
    'user.getbannedtracks' => {},
    'user.getevents' => {},
    'user.getfriends' => {},
    'user.getinfo' => {auth => 1},
    'user.getlovedtracks' => {},
    'user.getneighbours' => {},
    'user.getnewreleases' => {},
    'user.getpastevents' => {},
    'user.getpersonaltags' => {},
    'user.getplaylists' => {},
    'user.getrecentstations' => {auth => 1, signed => 1},
    'user.getrecenttracks' => {},
    'user.getrecommendedartists' => {auth => 1, signed => 1},
    'user.getrecommendedevents' => {auth => 1, signed => 1},
    'user.getshouts' => {},
    'user.gettopalbums' => {},
    'user.gettopartists' => {},
    'user.gettoptags' => {},
    'user.gettoptracks' => {},
    'user.getweeklyalbumchart' => {},
    'user.getweeklyartistchart' => {},
    'user.getweeklychartlist' => {},
    'user.getweeklytrackchart' => {},
    'user.shout' => {auth => 1, post => 1, signed => 1},
    'venue.getevents' => {},
    'venue.getpastevents' => {},
    'venue.search' => {},
};
#}}}
sub lastfm {
    my ($method, @params) = @_;
    $method = lc($method);

    my $cache = $cache;
    if ($cache) {
        unless (-d $cache) {
            $cache = $cache_dir;
            make_path($cache);
        }
        my $file = "$cache/".md5_hex(encode_json(\@_));
        if (-f $file) {
            my $data = loadfile($file);
            return $data->{content}
        }
        else {
            $cache = $file
        }
    }

    my %params;
    my $i = 0;
    while (my $p = shift @params) {
        if (ref $p eq "HASH") {
            while (my ($k,$v) = each %$p) {
                $params{$k."[".$i."]"} = $v;
            }
            croak "too multitudinous (limit 50)" if $i > 49;
            $i++
        }
        else {
            $params{$p} = shift @params;
        }
    }
    $params{method} = $method;
    $params{api_key} = $api_key;
    $params{format} = "json" unless $params{format} || $xml;
    delete $params{format} if $params{format} && $params{format} eq "xml";

    unless (exists $methods->{$method}) {
        carp "method $method is not known to Net::LastFMAPI"
    }

    sessionise(\%params);

    sign(\%params);

    my $res;
    if ($methods->{$method}->{post}) {
        $res = $ua->post($url, Content => \%params);
    }
    else {
        my $uri = URI->new($url);
        $uri->query_form(%params);
        $res = $ua->get($uri);
    }

    $params{format} ||= "xml";
    my $content = $res->decoded_content;
    unless ($res->is_success &&
        ($params{format} ne "xml" || $content =~ /<lfm status="ok">/)) {
        no warnings "once";
        $DB::single = 1;
        my $consider;
        if ($content =~ /Invalid session key - Please re-authenticate/) {
            $consider = "setting NET_LASTFMAPI_REAUTH=1 to re-authenticate";
        }
        croak "Something went wrong:\n$content".
            ($consider?"\n\nConsider $consider":"");
    }

    if ($params{format} eq "json") {
        $content = decode_json($content);
    }
    if ($cache) {
        dumpfile($cache, {content => $content});
    }
    return $content;
}

sub sessionise {
    my $params = shift;
    my $m = $methods->{$params->{method}};
    unless (delete $params->{auth} || $m && $m->{auth}) {
        return
    }
    $params->{sk} = get_session_key();
}

sub get_session_key {
    unless (defined $session_key) {
        load_save_sessionkey()
    }
    unless (defined $session_key) {
        my $key;
        eval { $key = request_session(); };
        if ($@) {
            die "--- Died while making requests to get a session:\n$@";
        }
        load_save_sessionkey($key);
    }
    return $session_key || die "unable to acquire session key...";
}

sub request_session {
    my $res = lastfm("auth.gettoken", format => "xml");

    my ($token) = $res =~ m{<token>(.+)</token>}
        or die "no foundo token: $res";

    talk_authorisation($token);

    my $sess = lastfm("auth.getSession", token => $token, format => "xml");

    ($username) = $sess =~ m{<name>(.+)</name>}
        or die "no name!? $sess";
    my ($key) = $sess =~ m{<key>(.+)</key>}
        or die "no key!? $sess";
    return $key;
}


sub talk_authorisation {
    my $token = shift;
    say "Sorry about this but could you go over here: "
        ."http://www.last.fm/api/auth/?api_key="
        .$api_key."&token=".$token;
    say "Hit enter to continue...";
    <STDIN>;
}

sub sign {
    my $params = shift;
    return unless $methods->{$params->{method}}->{signed};
    my $jumble = join "", map { $_ => $params->{$_} } sort keys %$params;
    my $hash = md5_hex($jumble.$secret);
    $params->{api_sig} = $hash;
}

if ($ENV{NET_LASTFMAPI_REAUTH}) {
    say "Re-authenticatinging...";
    if (readlink($sk_symlink)) {
        unlink($sk_symlink);
    }
    undef $session_key;
    get_session_key();
    say "Got session key: $session_key";
    say "Unsetting NET_LASTFMAPI_REAUTH...";
    say delete $ENV{NET_LASTFMAPI_REAUTH};
    say "Done";
    exit;
}

1;

__END__

=head1 NAME

Net::LastFMAPI - LastFM API 2.0

=head1 SYNOPSIS

  use Net::LastFMAPI;
  my $perl_data = lastfm("artist.getSimilar", artist => "Robbie Basho");

  # sets up a session/gets authorisation when needed for write actions:
  my $res = lastfm(
      "track.scrobble",
      artist => "Robbie Basho",
      track => "Wounded Knee Soliloquy",
      timestamp => time(),
  );
  $success = $res->{scrobbles}->{'@attr'}->{accepted} == 1;

  my $xml = lastfm(...); # with config value: xml => 1
  my $xml = lastfm(..., format => "xml");
  $success = $xml =~ m{<scrobbles accepted="1"};

  # see also:
  # bin/cmd.pl
  # bin/scrobble.pl
  # bin/portablog-scrobbler.pl

=head1 DESCRIPTION

Makes requests to http://ws.audioscrobbler.com/2.0/ and returns the result.

Takes care of POSTing to write methods, doing authorisation when needed.

Dies if something went obviously wrong.

Can return xml if you like, defaults to returning perl data/requesting json.
Not all methods support JSON. Beware of "@attr" and empty elements turned into
whitespace strings instead of empty arrays.

=head1 THE SESSION KEY

  $Net::LastFMAPI::session_key = "secret"

It will be sought when an authorised request is needed.

If it is not saved then on-screen instructions should be followed to authorise
with whoever is logged in to L<last.fm>.

It is saved in the symlink B<$ENV{HOME}/.net-lastfmapi-sessionkey>. This is
probably fine.

Consider altering the subroutines B<talk_authentication>, B<load_save_sessionkey>,
or simply setting the B<$Net::LastFMAPI::session_key> before needing it.

=head1 RETURN XML

  $Net::LastFMAPI::xml = 1

This will return an xml string to you. You can also set B<format =E<gt> "xml">
for a particular request. Apparently, not all methods support JSON. For casual
hacking, though, getting perl data is much more convenient.

=head1 CACHING

  $Net::LastFMAPI::cache = 1

  $Net::LastFMAPI::cache_dir = "$ENV{HOME}/.net-lastfmapi-cache/"

Does caching. Default cache directory is shown. Good for development.

=head1 SEE ALSO

L<Net::LastFM> doesn't handle sessions for you, won't POST to write methods

I had no luck with the 1.2 API modules: L<WebService::LastFM>,
L<Music::Audioscrobbler::Submit>, L<Net::LastFM::Submission>

=head1 BUGS/CODE

L<https://github.com/st3vil/Net-LastFMAPI>

=head1 AUTHOR

Steev Eeeriumn <drsteve@cpan.org>

=head1 COPYRIGHT

   Copyright (c) 2011, Steev Eeeriumn. All Rights Reserved.
 This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
     (see http://www.perl.com/perl/misc/Artistic.html)

