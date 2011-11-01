package LastFuckingM;
# partial interface to lastfm's new orifice
use strict;
use warnings;
use v5.10;
use LWP::UserAgent;
use Digest::MD5 'md5_hex';
use URI;

my $url = 'http://ws.audioscrobbler.com/2.0/';
my $api_key = 'dfab9b1c7357c55028c84b9a8fb68880';
my $secret = 'd004c86dcfa8ef4c3977b04f558535f2';
my $sk_symlink = "$ENV{HOME}/.last-fucking-m-sessionkey";
my $sk = readlink($sk_symlink);
my $ua = new LWP::UserAgent(agent => "LastFuckingM/-666");

# TODO crawl api docs
my %post_methods = map { $_ => 1 } qw{track.scrobble};
my %sk_methods = map { $_ => 1 } qw{track.scrobble};

sub req {
    my ($method, %params) = @_;
    $params{method} = $method;
    $params{api_key} = $api_key;

    sessionise(\%params);

    sign(\%params);

    my $res = $post_methods{$method} ?
        $ua->post($url, Content => \%params)
        : $ua->get(do {
            my $uri = URI->new($url);
            $uri->query_form(%params);
            $uri });

    my $content = $res->decoded_content;
    unless ($res->is_success && $content =~ /<lfm status="ok">/) {
        use YAML::Syck;
        say Dump($res);
        die "Something went wrong:\n$content";
    }
    return $content;
}

sub sessionise {
    my $params = shift;
    return unless $sk_methods{$params->{method}};
    $params->{api_sig} = undef;
    $params->{sk} = $sk ||= do {
        my $res = req("auth.gettoken", api_sig => undef);
        my ($token) = $res =~ m{<token>(.+)</token>}
            or die "no foundo token: $res";
        say "Sorry about this but could you go over here: "
            ."http://www.last.fm/api/auth/?api_key="
            .$api_key."&token=".$token;
        say "Hit enter to continue...";
        <STDIN>;
        my $sess = req("auth.getSession",
            token => $token,
            api_sig => undef,
        );
        my ($name) = $sess =~ m{<name>(.+)</name>}
            or die "no name!? $sess";
        my ($key) = $sess =~ m{<key>(.+)</key>}
            or die "no key!? $sess";
        say "Hello thar $name";
        symlink($key, $sk_symlink);
        $key
    };
}

sub sign {
    my $params = shift;
    return unless exists $params->{api_sig};
    delete $params->{api_sig};
    my $jumble = join "", map { $_ => $params->{$_} } sort keys %$params;
    my $hash = md5_hex($jumble.$secret);
    $params->{api_sig} = $hash;
}

1
