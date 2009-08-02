################################################################################
# Object
#
# Simple class. Defines a constructor and string overloading.
# 
################################################################################
# $Id: Object.pm 166 2009-08-02 17:14:39Z sputnik $
################################################################################
# $Log: $
################################################################################
package Object;
$__PACKAGE__::VERSION = '$Id: Object.pm 166 2009-08-02 17:14:39Z sputnik $ ';

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
