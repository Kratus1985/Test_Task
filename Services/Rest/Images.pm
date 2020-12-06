package Services::Rest::Images;

use Services::Rest;
use Services::Rest::Auth;
use Services::Cache;
use Data::Dumper;

our @ISA = qw(Services::Rest);

use constant URL => 'http://interview.agileengine.com/images';

#my $token = '210b0f36c5ccb5acc3d70a597c32586de075c893';
my $token;

sub load {
    my $self = shift;

    my $cache = Services::Cache->new();

    my $images = $cache->get('images');

    unless ($images) {
        $images = $self->_load_bulk();
        $cache->set('images', $images, 300);
    }

    return $images;
}

sub _load_bulk {
    my $self = shift;

    my @images = ();

    my $count = 1;
    my $page;

    do {
        $page = $self->_get_images(page => $count);

        for (@{$page->{pictures}}) {
            my $img = $self->_get_image_info(id => $_->{id});

            push @images, $img;
        }

        $count++;
    } while ($page->{hasMore} && $count < 2);

    return \@images;
}

sub _get_image_info {
    my $self = shift;
    my %args = @_;

    my $response = $self->_get(
        url => URL . "/" . $args{id},
    );

    if ($response && !$response->is_success()) {
        print Data::Dumper::Dumper("Error", $response->content());
    }

    return JSON::XS::decode_json($response->content());
}

sub _get {
    my $self = shift;
    my %args = @_;

    my $retry = 2;
    my $response;

    do {
        $response = $self->SUPER::_get(%args);

        if ($response && !$response->is_success()) {
            my $result = JSON::XS::decode_json($response->content());
            if ($result && $response->code() == 401 && $result->{status} eq 'Unauthorized') {
                $token = '';
            }
        } else {
            $retry = 0;
        }
        $retry--;
    } while ($retry > 0);

    return $response;
}

sub _get_images {
    my $self = shift;
    my %args = @_;

    my $query = $args{page} ? ({page => $args{page}}) : ();

    my $response = $self->_get(
        url   => URL,
        query => $query
    );

    if ($response && !$response->is_success()) {
        print Data::Dumper::Dumper("Error", $response->content());
    }

    return JSON::XS::decode_json($response->content());
}

sub _get_token {
    my $self = shift;

    return $token if $token;

    $token = Services::Rest::Auth->get_token_info()->{token};
    return $token;
}

sub _get_headers {
    my $self = shift;

    my $headers = [
        'accept'        => 'application/json',
        'content-type'  => 'application/json',
        'Authorization' => 'Bearer ' . $self->_get_token()
    ];

    return $headers;
}

sub search_by {
    my $self = shift;
    my %args = @_;

    my @filtered = grep {
        if (
            $self->_filter(author => $args{author}, tag => $args{tag}, camera => $args{camera}, id => $args{id}, image => $_)
        ) {
            $_;
        }
    } @{$args{images}};
    return \@filtered;
}

sub _filter {
    my $self = shift;
    my %args = @_;

    my $image = $args{image};

    my %filter = (
        $args{author} ? (author => $args{author}) : (),
        $args{tag} ? (tags => $args{tag}) : (),
        $args{camera} ? (camera => $args{camera}) : (),
        $args{id} ? (id => $args{id}) : ()
    );

    my @result = map { $image->{$_} =~ /\Q$filter{$_}/ ? 1 : () } keys %filter;

    return scalar(@result) == scalar (keys %filter);
}

1;