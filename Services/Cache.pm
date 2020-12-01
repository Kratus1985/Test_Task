package Services::Cache;

use Cache::Memory::Simple;
use feature qw/state/;

our @ISA = qw(Cache::Memory::Simple);

sub new {
    state $cache = Cache::Memory::Simple->new();

    return $cache;
}

1;