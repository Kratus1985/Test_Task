package Services::Rest::Images;

use Services::Rest;
use Services::Rest::Auth;
use Services::Cache;
use Data::Dumper;

our @ISA = qw(Services::Rest);

use constant URL => 'http://interview.agileengine.com/images';

sub load {
    my $self = shift;

    my $cache = Services::Cache->new();

    my $images = $cache->get('images');

    unless ($images) {
        $images = $self->_load_bulk();
        $cache->set('images', $images, 60);
    }

    return $images;
}

sub _load_bulk {
    my $self = shift;

    my %images = ();

    my $count = 1;
    my $page;

    do {

        # Get All the images
        $page = $self->_get_images(page => $count);

        for (@{$page->{pictures}}) {
            my $img = $self->_get_image_info(id => $_->{id});
            $images{$img->{id}} = $img;
        }

        $count++;
    } while ($page->{hasMore});

    return \%images;
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

    my $token = Services::Rest::Auth->get_token_info();
    return $token->{token};
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

1;