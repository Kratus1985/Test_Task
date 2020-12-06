#!/usr/bin/perl

use strict;
use warnings;

use lib '.';

use Mojolicious::Lite;
use Services::Rest::Images;

my $service = Services::Rest::Images->new();

$service->load();

get '/' => sub {
    my $self = shift;

    $self->render(json => {response => 'is working'});
};

get '/images/:id' => sub {
    my $self = shift;

    $self->render(json => {response => $service->search_by(
        images => $service->load(),
        id     => $self->param('id')
    )});
};

get '/images' => sub {
    my $self = shift;

    $self->render(json => {response => $service->load()});
};

get '/search' => sub {
    my $self = shift;

    $self->render(json => {response => $service->search_by(
        images => $service->load(),
        author => $self->param('author'),
        tag    => $self->param('tag'),
        camera => $self->param('camera')
    )});
};

app->start;

# https://agileengine.gitlab.io/interview/test-tasks/beQwwuNFStubgcbH/