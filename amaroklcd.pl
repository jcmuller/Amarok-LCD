#!/usr/bin/perl

use strict;
use warnings;
use DCOP::Amarok::Player;
use IO::LCDproc;
use threads;
use threads::shared;
use Time::HiRes qw/ usleep /;

our $VERSION = '0.034';

#### BEGIN CONFIG
# Configuration Options
## LCDproc
my $hostname = 'localhost';
my $port = '13666';
my $user = "$ENV{USER}";
### END CONFIG

my $amarok	= DCOP::Amarok::Player->new( user => "$user" ) or die "Couldn't attach to DCOP: $!\n";
my $client	=  IO::LCDproc::Client->new( name => "AMAROK_LCD", host => $hostname, port => $port );
my $screen	=  IO::LCDproc::Screen->new( name => "amarok", client => $client );
my $artist 	=  IO::LCDproc::Widget->new( 	name => "artist",
											type => "title");
my $title	=  IO::LCDproc::Widget->new(	name => "title",
											align => "center",
											xPos => 1,
											yPos => 3 );
my $album	=  IO::LCDproc::Widget->new(	name => "album",
											align => "center",
											xPos => 1,
											yPos => 4 );
my $vol		=  IO::LCDproc::Widget->new(	name => "vol",
											type => "hbar",
											xPos => 1,
											yPos => 2);
my $slider	=  IO::LCDproc::Widget->new(	name => "slider",
											data => "o",
											yPos => 2 );


$client->add( $screen );
$screen->add( $artist, $title, $album, $vol, $slider );
$client->connect() or die "cannot connect: $!";
$client->initialize();

$title->set(  data => $amarok->title()     );
$album->set(  data => $amarok->album()     );
$artist->set( data => $amarok->artist()    );
$vol->set(    data => $amarok->getVolume );
$slider->set( xPos => int( $amarok->elapsedsecs() / ($amarok->totaltimesecs() or 60 ) * $client->{width}));

$SIG{TERM} = \&bye;
$SIG{INT}  = \&bye;

my $status:shared = ($amarok->status() > 0) ? 1 : 0;
my $sleep:shared = int( 1000000 * (( $amarok->totaltimesecs() / $client->{width} ) || 6 ));
my $counter:shared = $amarok->elapsedsecs() / $amarok->totaltimesecs() * $client->{width};
my $thread = threads->new(\&slider);

while($status>-1) {
	$_ = <STDIN>;
	if ( /trackChange/ ) {
		$artist->set( data => $amarok->artist );
		$title->set(  data => $amarok->title  );
		$album->set(  data => $amarok->album  );
		$counter =  $amarok->elapsedsecs() / $amarok->totaltimesecs() * $client->{width};
		$slider->set( xPos => $counter );
		$sleep = int( 1000000 * (( $amarok->totaltimesecs() / $client->{width} ) || 6 ));
	} elsif ( /engineStateChange/ ) {
		if( /playing/ ) {
			$status = 1;
			$title->restore;
		} elsif ( /pause/ ) {
			$status = 0;
			$title->save unless ($title->{data} =~ /paused|stopped/);
			$title->set(data => "paused");
		} else {
			$status = 0;
			$title->save unless($title->{data} =~ /paused|stopped/);
			$title->set(data => "stopped");
			$counter = 1;
			$slider->set(xPos => $counter);
		}
	} elsif( /volumeChange/ ){
		m/: (\d+)/;
		$vol->set(data => $1);
	}
	&bye() if(/kill/ || /exit/ || /quit/);
}

sub slider {
	while(1) {
		return if($status < 0);
		$counter++ if($status > 0);
		$slider->set(xPos => $counter);
		usleep($sleep);
	}
}

sub bye {
	$status = -1;
	kill 14, $thread;
	$thread->join();
}

__END__

=head1 NAME

amaroklcd

=head1 DESCRIPTION

This program is designed to connect to an LCDd server (http://www.lcdproc.org/) and to amaroK
(http://amarok.kde.org/), and then show the info from amaroK on this screen.

=head1 AUTHOR

Juan C. Muller E<lt>jcmuller@gmail.comE<gt>

=head1 COPYRIGHT (COPYLEFT)

2005, Juan C. Muller

=head1 LICENSE

This programs is licensed under the terms of the GPL.

=cut
