#!/usr/bin/perl

use strict;
use warnings;

use lib '.';

use Services::Rest::Images;

my $sevice = Services::Rest::Images->new();

my $images = $sevice->load();

my $cached_images = $sevice->load();
1;
