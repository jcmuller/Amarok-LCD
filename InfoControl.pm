################################################################################
# InfoControl
#
# Talks to DCOP::Amarok::Player and IO::LCDproc
################################################################################
# $Id: $
################################################################################
package InfoControl;
$__PACKAGE__::VERSION = q($Rev: 171 $);

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
		print "InfoControl: ${element}: ", $p->$element, "\n";
		print $output "${element}: ", $p->$element, "\n";
	}

	print "InfoControl: volume: ", $p->getVolume, "\n";
	print $output "volume: ", $p->getVolume, "\n";
}

sub work
{
	my ($this) = @_;

	my $input     = $this->{_input};
	my $output    = $this->{_output};
	my $to_slider = $this->{_to_slider};

	print "InfoControl::work\n";

	while (1)
	{
		while (<$input>)
		{
			print "InfoControl: Got $_";

			if (/exit/)
			{
				print "InfoControl: $_";
				print $output $_;
				print $to_slider $_;
				threads->exit(0);
			}
			elsif (/trackChange/)
			{
				$this->setValues();
				print "InfoControl: $_";
				print $to_slider $_;
			}
			else
			{
				print "InfoControl: $_";
				print $output $_;
			}
		}
	}
}

1;
