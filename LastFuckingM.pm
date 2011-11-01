package LastFuckingM;
# partial interface to lastfm's new orifice
use strict;
use warnings;
use v5.10;
use LWP::UserAgent;
use Digest::MD5 'md5_hex';
use JSON::XS;
use URI;

our $url = 'http://ws.audioscrobbler.com/2.0/';
our $api_key = 'dfab9b1c7357c55028c84b9a8fb68880';
our $secret = 'd004c86dcfa8ef4c3977b04f558535f2';
our $session_key; # see get_session_key()
our $ua = new LWP::UserAgent(agent => "LastFuckingM/-666");
our $json = 0;

our $sk_symlink = "$ENV{HOME}/.last-fucking-m-sessionkey";
sub load_save_sessionkey {
    my $key = shift;
    if ($key) {
        symlink($key, $sk_symlink)
    }
    else {
        $key = readlink($sk_symlink);
    }
    $session_key = $key;
}

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
    'user.getInfo' => {  },
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

sub req {
    my ($method, %params) = @_;
    $params{method} = $method;
    $params{api_key} = $api_key;
    $params{format} ||= "json" if $json;

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
        $DB::single = 1;
        die "Something went wrong:\n$content";
    }
    if ($params{format} eq "json") {
        return decode_json($content);
    }
    else {
        return $content;
    }
}

sub sessionise {
    my $params = shift;
    return unless $methods->{$params->{method}}->{auth};
    $params->{sk} = get_session_key();
}

sub get_session_key {
    unless (defined $session_key) {
        load_save_sessionkey()
    }
    unless (defined $session_key) {
        my $res = req("auth.gettoken", format => "xml");

        my ($token) = $res =~ m{<token>(.+)</token>}
            or die "no foundo token: $res";

        talk_authorisation($token);

        my $sess = req("auth.getSession", token => $token, format => "xml");

        my ($name) = $sess =~ m{<name>(.+)</name>}
            or die "no name!? $sess";
        my ($key) = $sess =~ m{<key>(.+)</key>}
            or die "no key!? $sess";

        load_save_sessionkey();
    }
    return $session_key || die "unable to acquire session key...";
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

1
