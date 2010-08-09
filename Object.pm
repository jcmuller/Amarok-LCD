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

use FileHandle;

my $DEBUG = 0;
my $FH;

sub new
{
	my $proto = shift;
	my $class = ref $proto || $proto;
	my $this  = {};
	bless $this, $class;
	$this->_initialize(@_);
	return $this;
}

sub _initialize
{
	my ($this, %args) = @_;
	
	#Override

	$this->debug("Instantiated new ", ref $this);
}

sub DESTROY
{
	my ($this) = @_;

	$this->debug("Killing ", ref $this);

	my $fh = $this->{_log};

	if (defined $fh)
	{
		$fh->close;
	}
}

sub debug_method
{
	my ($this, $method) = @_;
	$DEBUG = $method;

	if ($DEBUG == 2) 
	{
		my $filename = '/tmp/amaroklcd_log';
		my $fh = new FileHandle($filename, '>>') or Carp::croak("Could not open $filename for writing: $!");

		if (defined $fh)
		{
			$fh->autoflush;
			$FH = $fh;
		}
	}
}

# Override
sub stringify
{
	my ($this) = @_;

	use Data::Dumper;
	return Dumper($this);
}

sub debug
{
	my ($this, @args) = @_;

	if ($DEBUG == 1)
	{
		print STDERR @args, "\n";
	}
	elsif ($DEBUG == 2)
	{
		if (defined $FH)
		{
			print $FH @args, "\n";
		}
	}
}

1;
