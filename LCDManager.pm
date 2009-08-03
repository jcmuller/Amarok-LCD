################################################################################
# LCDManager
#
# Talks to IO::LCDproc
################################################################################
# $Id: $
################################################################################
package LCDManager;
$__PACKAGE__::VERSION = q($Rev: 171 $);

use strict;
use warnings;

our @ISA = qw(Object);
our @Export = qw();

use Carp;
use IO::LCDproc;
use Object;
use Time::HiRes;
use threads;

sub _initialize
{
	my ($this, %args) = @_;

	$this->SUPER::_initialize(%args);

	$this->{_input} = $args{input};
	$this->{_input}->reader;
	$this->{_input}->autoflush;

	my $hostname = 'localhost' || $args{lcdproc_hostname};
	my $port     = '13666'     || $args{lcdproc_port};

	my $client = new IO::LCDproc::Client(
		name => 'AMAROK_LCD',
		host => $hostname,
		port => $port,
	);

	my $screen = new IO::LCDproc::Screen(
		name   => 'amarok',
		client => $client,
	);

	$this->{_title} = new IO::LCDproc::Widget(
		name  => 'title',
		align => 'center',
		xPos  => 1,
		yPos  => 3
	);

	$this->{_artist} = new IO::LCDproc::Widget(
		name => 'artist',
		type => 'title',
	);

	$this->{_album} = new IO::LCDproc::Widget(
		name  => 'album',
		align => 'center',
		xPos  => 1,
		yPos  => 4,
	);

	$this->{_volume} = new IO::LCDproc::Widget(
		name => 'volume',
		type => 'hbar',
		xPos => 1,
		yPos => 2
	);

	$this->{_slider} = new IO::LCDproc::Widget(
		name => 'slider',
		data => 'o',
		yPos => 2,
	);

	$client->add($screen);

	$screen->add(
		$this->{_artist}, $this->{_title}, $this->{_album},
		$this->{_volume}, $this->{_slider},
	);

	$client->connect or Carp::croak "Couldn't connect to LCDproc: $!";
	$client->initialize;

	$this->{_client_width} = $client->{width};

	$this->work;
}

sub setValue
{
	my ($this, $name, $value) = @_;

	if (!defined($this->{"_$name"}))
	{
		Carp::croak "Name passed in $name is invalid: $!";
	}

	my $attr = 'data';

	if ($name eq 'slider')
	{
		$attr = 'xPos';
		$value = int($value * $this->{_client_width});
		$value = 1 if ($value == 0);
	}

	print "LCDManager: Setting $name $attr $value\n";
	$this->{"_$name"}->set($attr => $value);
}

sub work
{
	my ($this) = @_;

	my $input = $this->{_input};

	STDOUT->autoflush();

	while (<$input>)
	{
		if (/exit/)
		{
			print "LCDManager: got exit\n";
			threads->exit(0);
		}
		elsif (/(artist|title|album|volume|slider): (.+)/i)
		{
			$this->setValue($1, $2);
		}
		elsif (/statusChange/)
		{
			if (/playing/)
			{
				$this->{_title}->restore;
			}
			elsif (/pause/)
			{
				$this->{_title}->save
				  unless ($this->{_title}->{data} =~ /paused|stopped/);
				$this->{_title}->set(data => 'paused');
			}
			else
			{
				$this->{_title}->save
				  unless ($this->{_title}->{data} =~ /paused|stopped/);
				$this->{_title}->set(data => 'stopped');
				$this->{_slider}->set(xPos => 0);
			}
		}
		elsif (/volumeChange/)
		{
			/: (\d+)/;
			$this->{_volume}->set(data => $1);
		}
	}
}

1;
