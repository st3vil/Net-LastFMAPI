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

our $VERSION = 0.1;
our $url = 'http://ws.audioscrobbler.com/2.0/';
our $api_key = 'dfab9b1c7357c55028c84b9a8fb68880';
our $secret = 'd004c86dcfa8ef4c3977b04f558535f2';
our $session_key; # see load_save_sessionkey()
our $ua = new LWP::UserAgent(agent => "Net::LastFMAPI/$VERSION");
our $username; # not important

our $json = 0;
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
    'album.addTags' => { auth => 1, post => 1, signed => 1 },
    'album.getBuylinks' => {  },
    'album.getInfo' => {  },
    'album.getShouts' => {  },
    'album.getTags' => { auth => 1, signed => 1 },
    'album.getTopTags' => {  },
    'album.removeTag' => { auth => 1, post => 1, signed => 1 },
    'album.search' => {  },
    'album.share' => { auth => 1, post => 1, signed => 1 },
    'artist.addTags' => { auth => 1, post => 1, signed => 1 },
    'artist.getCorrection' => {  },
    'artist.getEvents' => {  },
    'artist.getImages' => {  },
    'artist.getInfo' => {  },
    'artist.getPastEvents' => {  },
    'artist.getPodcast' => {  },
    'artist.getShouts' => {  },
    'artist.getSimilar' => {  },
    'artist.getTags' => { auth => 1, signed => 1 },
    'artist.getTopAlbums' => {  },
    'artist.getTopFans' => {  },
    'artist.getTopTags' => {  },
    'artist.getTopTracks' => {  },
    'artist.removeTag' => { auth => 1, post => 1, signed => 1 },
    'artist.search' => {  },
    'artist.share' => { auth => 1, post => 1, signed => 1 },
    'artist.shout' => { auth => 1, post => 1, signed => 1 },
    'auth.getMobileSession' => { signed => 1 },
    'auth.getSession' => { signed => 1 },
    'auth.getToken' => { signed => 1 },
    'chart.getHypedArtists' => {  },
    'chart.getHypedTracks' => {  },
    'chart.getLovedTracks' => {  },
    'chart.getTopArtists' => {  },
    'chart.getTopTags' => {  },
    'chart.getTopTracks' => {  },
    'event.attend' => { auth => 1, post => 1, signed => 1 },
    'event.getAttendees' => {  },
    'event.getInfo' => {  },
    'event.getShouts' => {  },
    'event.share' => { auth => 1, post => 1, signed => 1 },
    'event.shout' => { auth => 1, post => 1, signed => 1 },
    'geo.getEvents' => {  },
    'geo.getMetroArtistChart' => {  },
    'geo.getMetroHypeArtistChart' => {  },
    'geo.getMetroHypeTrackChart' => {  },
    'geo.getMetroTrackChart' => {  },
    'geo.getMetroUniqueArtistChart' => {  },
    'geo.getMetroUniqueTrackChart' => {  },
    'geo.getMetroWeeklyChartlist' => {  },
    'geo.getMetros' => {  },
    'geo.getTopArtists' => {  },
    'geo.getTopTracks' => {  },
    'group.getHype' => {  },
    'group.getMembers' => {  },
    'group.getWeeklyAlbumChart' => {  },
    'group.getWeeklyArtistChart' => {  },
    'group.getWeeklyChartList' => {  },
    'group.getWeeklyTrackChart' => {  },
    'library.addAlbum' => { auth => 1, post => 1, signed => 1 },
    'library.addArtist' => { auth => 1, post => 1, signed => 1 },
    'library.addTrack' => { auth => 1, post => 1, signed => 1 },
    'library.getAlbums' => {  },
    'library.getArtists' => {  },
    'library.getTracks' => {  },
    'library.removeAlbum' => { auth => 1, post => 1, signed => 1 },
    'library.removeArtist' => { auth => 1, post => 1, signed => 1 },
    'library.removeScrobble' => { auth => 1, post => 1, signed => 1 },
    'library.removeTrack' => { auth => 1, post => 1, signed => 1 },
    'playlist.addTrack' => { auth => 1, post => 1, signed => 1 },
    'playlist.create' => { auth => 1, post => 1, signed => 1 },
    'radio.getPlaylist' => { auth => 1, signed => 1 },
    'radio.search' => {  },
    'radio.tune' => { auth => 1, post => 1, signed => 1 },
    'tag.getInfo' => {  },
    'tag.getSimilar' => {  },
    'tag.getTopAlbums' => {  },
    'tag.getTopArtists' => {  },
    'tag.getTopTags' => {  },
    'tag.getTopTracks' => {  },
    'tag.getWeeklyArtistChart' => {  },
    'tag.getWeeklyChartList' => {  },
    'tag.search' => {  },
    'tasteometer.compare' => {  },
    'tasteometer.compareGroup' => {  },
    'track.addTags' => { auth => 1, post => 1, signed => 1 },
    'track.ban' => { auth => 1, post => 1, signed => 1 },
    'track.getBuylinks' => {  },
    'track.getCorrection' => {  },
    'track.getFingerprintMetadata' => {  },
    'track.getInfo' => {  },
    'track.getShouts' => {  },
    'track.getSimilar' => {  },
    'track.getTags' => { auth => 1, signed => 1 },
    'track.getTopFans' => {  },
    'track.getTopTags' => {  },
    'track.love' => { auth => 1, post => 1, signed => 1 },
    'track.removeTag' => { auth => 1, post => 1, signed => 1 },
    'track.scrobble' => { auth => 1, post => 1, signed => 1 },
    'track.search' => {  },
    'track.share' => { auth => 1, post => 1, signed => 1 },
    'track.unban' => { auth => 1, post => 1, signed => 1 },
    'track.unlove' => { auth => 1, post => 1, signed => 1 },
    'track.updateNowPlaying' => { auth => 1, post => 1, signed => 1 },
    'user.getArtistTracks' => {  },
    'user.getBannedTracks' => {  },
    'user.getEvents' => {  },
    'user.getFriends' => {  },
    'user.getInfo' => { auth => 1 },
    'user.getLovedTracks' => {  },
    'user.getNeighbours' => {  },
    'user.getNewReleases' => {  },
    'user.getPastEvents' => {  },
    'user.getPersonalTags' => {  },
    'user.getPlaylists' => {  },
    'user.getRecentStations' => { auth => 1, signed => 1 },
    'user.getRecentTracks' => {  },
    'user.getRecommendedArtists' => { auth => 1, signed => 1 },
    'user.getRecommendedEvents' => { auth => 1, signed => 1 },
    'user.getShouts' => {  },
    'user.getTopAlbums' => {  },
    'user.getTopArtists' => {  },
    'user.getTopTags' => {  },
    'user.getTopTracks' => {  },
    'user.getWeeklyAlbumChart' => {  },
    'user.getWeeklyArtistChart' => {  },
    'user.getWeeklyChartList' => {  },
    'user.getWeeklyTrackChart' => {  },
    'user.shout' => { auth => 1, post => 1, signed => 1 },
    'venue.getEvents' => {  },
    'venue.getPastEvents' => {  },
    'venue.search' => {  },
};
#}}}
sub lastfm {
    my ($method, @params) = @_;

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
    $params{format} ||= "json" if $json;
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
        croak "Something went wrong:\n$content";
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
__END__

=head1 NAME

Net::LastFMAPI - LastFM API 2.0

=head1 SYNOPSIS

  use Net::LastFMAPI;
  my $xml = lastfm("artist.getSimilar", artist => "Robbie Basho");

  $Net::LastFMAPI::json = 1;
  my $data = lastfm(...); # decodes it for you

  # sets up a session/gets authorisation when needed for write actions:
  my $res = lastfm(
      "track.scrobble",
      artist => "Robbie Basho",
      track => "Wounded Knee Soliloquy",
      timestamp => time(),
  );
  $success = $res =~ m{<scrobbles accepted="1"};

=head1 DESCRIPTION

Makes requests to http://ws.audioscrobbler.com/2.0/ and returns the result.

Takes care of POSTing to write methods, doing authorisation when needed.

Dies if something went obviously wrong.

=head1 THE SESSION KEY

  $Net::LastFMAPI::session_key = "secret"

It will be sought when an authorised request is needed.

If it is not saved then on-screen instructions should be followed to authorise
with whoever is logged in to L<last.fm>.

It is saved in the symlink B<$ENV{HOME}/.net-lastfmapi-sessionkey>. This is
probably fine.

Consider altering the subroutines B<talk_authentication>, B<load_save_sessionkey>,
or simply setting the B<$Net::LastFMAPI::session_key> before needing it.

=head1 RETURN PERL DATA

  $Net::LastFMAPI::json = 1
  
This will automatically add B<format =E<gt> "json"> to every request B<and decode
the result> into perl data for you.

Not all methods support JSON. Beware of "@attr" and empty elements turned into
whitespace strings instead of empty arrays.

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

