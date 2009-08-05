################################################################################
# InfoControl
#
# Talks to DCOP::Amarok::Player and IO::LCDproc
################################################################################
# $Id$
################################################################################
package InfoControl;
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

	$this->{_input}     = $args{input};
	$this->{_output}    = $args{output};
	$this->{_to_slider} = $args{slider};

	$this->{_input}->reader;
	$this->{_output}->writer;
	$this->{_to_slider}->writer;

	$this->{_input}->autoflush;
	$this->{_output}->autoflush;
	$this->{_to_slider}->autoflush;

	my $user = $ENV{USER} || $args{amarok_user};

	$this->{_player} = new DCOP::Amarok::Player(user => $user)
	  or Carp::croak "Couldn't attach to DCOP: $!";

	$this->setValues;
	$this->work;
}

sub setValues
{
	my ($this) = @_;

	my $p      = $this->{_player};
	my $output = $this->{_output};

	if (!$p)
	{
		Carp::croak "No reference to DCOP::Amarok::Player object! $!";
	}

	for my $element (qw(title album artist))
	{
		my $data = $p->$element;
		if ($data =~ m{^\s*$})
		{
			$data = '                 ';	
		}
		$this->debug("InfoControl: ${element}: ", $data);
		print $output "${element}: ", $data, "\n";
	}

	my $volume = $p->getVolume;
	$this->debug("InfoControl: volume: ", $volume);
	print $output "volume: ", $volume, "\n";
}

sub work
{
	my ($this) = @_;

	my $input     = $this->{_input};
	my $output    = $this->{_output};
	my $to_slider = $this->{_to_slider};

	$this->debug("InfoControl::work");

	while (1)
	{
		while (<$input>)
		{
			$this->debug("InfoControl: Got $_");

			if (/exit/)
			{
				$this->debug("InfoControl: $_");
				print $output $_;
				print $to_slider $_;
				threads->exit(0);
			}
			elsif (/trackChange/)
			{
				$this->setValues();
				$this->debug("InfoControl: $_");
				print $to_slider $_;
			}
			else
			{
				$this->debug("InfoControl: $_");
				print $output $_;
			}
		}
	}
}

1;
