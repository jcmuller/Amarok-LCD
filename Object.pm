################################################################################
# Object
#
# Simple class. Defines a constructor and string overloading.
################################################################################
# $Id$
################################################################################
package Object;
$__PACKAGE__::VERSION = q($Rev$);

use strict;
use warnings;
use overload '""' => \&stringify;

our @ISA    = qw();
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

	use Data::Dumper;
	return Dumper($this);
}

1;
