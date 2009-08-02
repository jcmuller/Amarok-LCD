use strict;
use warnings;

package Controller;

our $VERSION = '$Id$ ';

use Carp;
use IO::Pipe;
use Time::HiRes;
use AmarokLCDProc;
use Object;
our @ISA = 'Object';

sub work
{
	my ($this) = @_;

	$this->spawnChild;

	if ($this->isParent)
	{
		$this->waitForInputAndProcess();
	}

	for (qw/TERM INT HUP/)
	{
		$SIG{$_} = $this->getSignalHandler($_);
	}
}

sub getSignalHandler
{
	my ($this, $type) = @_;

	my $handler = sub
	{
		my $out = $this->{_to_slider_control};
		print $out "exit\n";
		waitpid($this->{_pid}, 0);
	};

	return $handler;
}

sub waitForInputAndProcess
{
	my ($this) = @_;

	my $out = $this->{_to_child};

	while (1)
	{
		while (<STDIN>)
		{
			print $out $_;
			
			if (/exit/)
			{
				waitpid($this->{_pid}, 0);
				exit(0);
			}
		}
	}
}

sub isParent
{
	my ($this) = @_;
	
	return $this->{_is_parent};
}

sub spawnChild
{
	my ($this) = @_;

	my $to_child   = new IO::Pipe;

	$this->{_status} = 1;

	if (my $pid = fork())
	{

		# Parent
		$to_child->writer;
		$to_child->autoflush;
		$to_child->blocking(0);

		$this->{_is_parent} = 1;

		$this->{_to_child} = $to_child;
		$this->{_pid}      = $pid;
	} elsif (defined $pid)
	{
		# Child
		$to_child->reader;
		$to_child->autoflush;
		$to_child->blocking(0);

		new AmarokLCDProc(pipe => $to_child);
	} else
	{
		Carp::croak "Unknown state: $!";
	}
}

1;

__END__
# Local Variables:
# tab-width:4
# End:
