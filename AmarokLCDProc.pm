use strict;
use warnings;

package AmarokLCDProc;

use DCOP::Amarok::Player;
use IO::LCDproc;
use Time::HiRes;
use Carp;
use Object;

our @ISA = 'Object';
our $VERSION = '$Id$ ';

sub _initialize
{
	my ($this, %args) = @_;

	$this->SUPER::_initialize(%args);

	$this->{_input} = $args{pipe};

	my $hostname = 'localhost' || $args{lcdproc_hostname};
	my $port     = '13666'     || $args{lcdproc_port};
	my $user     = $ENV{USER}  || $args{amarok_user};

	$this->{_player} = new DCOP::Amarok::Player(user => $user)
	  or Carp::croak "Couldn't attach to DCOP: $!";

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

	$this->{_title}->set(data => $p->title);
	$this->{_album}->set(data => $p->album);
	$this->{_artist}->set(data => $p->artist);
	$this->{_volume}->set(data => $p->getVolume);

	my $elapsedsecs   = $p->elapsedsecs;
	my $totaltimesecs = $p->totaltimesecs;
	my $width         = $this->{_client_width};

	$this->{_sleep} = int(1000000 * (($totaltimesecs / $width) || 6) / 3);
	my $position = int($elapsedsecs / ($totaltimesecs or 60) * $width);

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
		my $width         = $this->{_client_width};

		$position = int($elapsedsecs / ($totaltimesecs or 60) * $width);
	}

	$this->{_slider}->set(xPos => $position);
}

sub work
{
	my ($this) = @_;

	my $input = $this->{_input};

	STDOUT->autoflush();

	$input->blocking(0);

	while (1)
	{
		if (my $line = $input->getline)
		{
			if ($line =~ /exit/)
			{
				exit(0);
			}

			if ($line =~ /trackChange/)
			{
				$this->setValues();
			} elsif ($line =~ /engineStateChange/)
			{
				if ($line =~ /playing/)
				{
					$this->{_title}->restore;
					$this->{_status} = 1;
				} elsif ($line =~ /pause/)
				{
					$this->{_title}->save
					  unless ($this->{_title}->{data} =~ /paused|stopped/);
					$this->{_title}->set(data => 'paused');
					$this->{_status} = 0;
				} else
				{
					$this->{_title}->save
					  unless ($this->{_title}->{data} =~ /paused|stopped/);
					$this->{_title}->set(data => 'stopped');
					$this->{_slider}->set(xPos => 0);
					$this->{_status} = 0;
				}
			} elsif ($line =~ /volumeChange/)
			{
				$line =~ /: (\d+)/;
				$this->{_volume}->set(data => $1);
			}
		}

		$this->setSlider or Carp::croak;

		Time::HiRes::usleep $this->{_sleep};
	}
}

1;

__END__
# Local Variables:
# tab-width:4
# End:
