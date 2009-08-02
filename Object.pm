use strict;
use warnings;

package Object;

our $VERSION = '$Id$ ';

sub new
{
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $this  = {};
    bless $this, $class;
    $this->_initialize(@_);
    return $this;
}

# Override
sub _initialize
{
    my ($this, %args) = @_;

    # Stub
}

1;

