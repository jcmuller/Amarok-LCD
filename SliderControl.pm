################################################################################
# SliderControl
#
# Talks to DCOP::Amarok::Player and IO::LCDproc
################################################################################
# $Id$
################################################################################
package SliderControl;
$__PACKAGE__::VERSION = q($Rev$);

use strict;
use warnings;

our @ISA = qw(Object);
our @Export = qw();

use Carp;
use DCOP::Amarok::Player;
use IO::LCDproc;
use Object;
use Time::HiRes;
use threads;

sub _initialize
{
	my ($this, %args) = @_;

	$this->SUPER::_initialize(%args);

	$this->{_input}  = $args{input};
	$this->{_output} = $args{output};

	$this->{_input}->reader;
	$this->{_output}->writer;

	$this->{_input}->autoflush;
	$this->{_output}->autoflush;

	$this->{_position} = 0;

	my $user = $ENV{USER} || $args{user};

	$this->{_player} = new DCOP::Amarok::Player(user => $user)
	  or Carp::croak "Couldn't attach to DCOP: $!";

	$this->setValues;
	$this->work;
}

sub setValues
{
	my ($this) = @_;

	my $p = $this->{_player};

	if (!$p)
	{
		Carp::croak "No reference to DCOP::Amarok::Player object! $!";
	}

	my $elapsedsecs   = $p->elapsedsecs;
	my $totaltimesecs = $p->totaltimesecs;
	my $width         = $this->{_client_width} || 20;

	$this->{_sleep} = int(500_000 * (($totaltimesecs / $width) || 6) / 3);
#	my $position = int($elapsedsecs / ($totaltimesecs or 60) * $width);
	my $position = int($elapsedsecs / ($totaltimesecs or 60) * 100);

	$this->setSlider($position);
}

sub setSlider
{
	my ($this, $position) = @_;

	if (!$position)
	{
		my $p = $this->{_player};

		my $elapsedsecs   = $p->elapsedsecs;
		my $totaltimesecs = $p->totaltimesecs;
	#	my $width         = $this->{_client_width};

#		$position = int($elapsedsecs / ($totaltimesecs or 60) * $width);
		$position = int($elapsedsecs / ($totaltimesecs or 60) * 100);
	}

	my $output = $this->{_output};
	$this->debug("SliderControl: slider: $position");

	if ($position != $this->{_position})
	{
		$this->{_position} = $position;
		print $output "slider: $position\n";
	}
}

sub work
{
	my ($this) = @_;

	my $input = $this->{_input};

	$input->blocking(0);

	while (1)
	{
		if (my $line = $input->getline)
		{
			if ($line =~ /exit/)
			{
				$this->debug("SliderControl: got exit");
				threads->exit(0);
			}

			if ($line =~ /trackChange/)
			{
				$this->setValues();
			}
		}

		$this->setSlider;

		Time::HiRes::usleep $this->{_sleep};
	}
}

1;
