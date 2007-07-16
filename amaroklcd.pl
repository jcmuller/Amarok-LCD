#!/usr/bin/perl
#
#     Juan C. Mller
#     GPL
#     This scripts connects to an lcdproc ready screen and shows the
#     status of amarok.

use strict;
use warnings;
use diagnostics;
use lcdproc;

my $control = lcdproc->new();
$control->connect();
$control->initialize();

$control->dump();
my $input;

while (1) {
	$input = <STDIN>;

	if ( $input =~ /trackChange/ ) {
		$control->dump();
	}
	elsif ( $input =~ /engineStateChange/ ) {
		if ( $input =~ /pause/ ) {
			$control->lcd( widget => "title", data => $control->{pause}, xPos => 1, yPos =>3 );
		}
		elsif ( $input =~ /play/ ) {
			$control->dump();
		}
		elsif ( $input =~ /empty/ ) {
			$control->lcd( widget => "title", data => $control->{stop} , xPos => 1, yPos =>3 );
		}
	} elsif ( $input =~ /volumeChange/ ) {
		$control->lcd( widget => "sep", xPos => 1, yPos => 2,
			data => substr( $control->{shape}, 0, $control->{dcop}->vol() / 5 )
		);
	}
}
