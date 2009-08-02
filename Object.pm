################################################################################
# Object
#
# Simple class. Defines a constructor and string overloading.
# 
################################################################################
# $Id$
################################################################################
# $Log: $
################################################################################
package Object;
$__PACKAGE__::VERSION = '$Id$ ';

use strict;
use warnings;
use overload
    '""' => \&stringify;

our @ISA = qw();
our @Export = qw();

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

# Override
sub stringify
{
    my ($this) = @_;

    return "This is the string representation of this object.";
}

1;
