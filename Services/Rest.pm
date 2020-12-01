package Services::Rest;

use JSON::XS;
use LWP::UserAgent;
use URI::Escape qw(uri_escape);

use constant DEBUG => 0;

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub _execute {
    my $self = shift;
    my %args = @_;

    my $ua;
    {
        local $Net::HTPPS::SSL_SOCKET_CLASS = 'IO::Socket::SSL';
        $ua = LWP::UserAgent->new(
            agent    => undef,
            ssl_opts => {
                SSL_version => 'SSLv23:!SSLv2:!SSLv3'
            },
            timeout  => $args{timeout}
        );
    };

    my $headers = $self->_get_headers();

    my $request = HTTP::Request->new(
        $args{method},
        $args{endpoint},
        $headers,
        $args{body} ? JSON::XS::encode_json($args{body}) : undef
    );

    my $result = $ua->request($request);

    print Data::Dumper::Dumper($args{method}." - Response ".$result->content()) if DEBUG;

    return $result;
}

sub _get_headers {
    my $self = shift;

    return [
        accept       => 'application/json',
        content_type => 'application/json'
    ];
}

sub _parse_query_string {
    my $self = shift;
    my %args = @_;
    my $query = '';

    if (scalar(keys(%args)) > 0) {
        my @pairs;
        $query = "?";
        for my $key (keys %args) {
            push @pairs, join '=', map {uri_escape($_)} $key, $args{$key};
        }
        $query .= join "&", @pairs;
    }
    return $query;
}

sub _post {
    my $self = shift;
    my %args = @_;

    return $self->_execute(
        method   => 'POST',
        endpoint => $args{url},
        body     => $args{body},
        timeout  => $args{timeout}
    );
}

sub _get {
    my $self = shift;
    my %args = @_;

    my $query = ($args{query}) ? $self->_parse_query_string(%{$args{query}}) : '';
    my $endpoint = $args{url} . $query;

    return $self->_execute(
        method   => 'GET',
        endpoint => $endpoint,
        timeout  => $args{timeout}
    );
}

1;
