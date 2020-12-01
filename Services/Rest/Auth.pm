package Services::Rest::Auth;

use Services::Rest;

our @ISA = qw(Services::Rest);

sub get_token_info {
    my $self = shift;

    my $url = '';

    my $response = $self->_post(
        url  => 'http://interview.agileengine.com/auth',
        body => {
            apiKey => '23567b218376f79d9415'
        }
    );

    if ($response && !$response->is_success()) {
        die "Error " . $response->header('status') . ' - ' . $response->content();
    } elsif (!$response) {
        die "Error no response";
    }

    return JSON::XS::decode_json($response->content());

}

1;