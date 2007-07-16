#!/usr/bin/perl
#
#     Juan C. Müller
#     GPL
#     This scripts connects to an lcdproc ready screen and shows the
#     status of amarok.

use strict;
use warnings;
use diagnostics;
use IO::Socket;
use Fcntl;

my $host = "localhost";
my $port = "13666";
my $verbose=0;
my ($input, $title, $artist, $album);
my $dcop="/usr/bin/dcop amarok player";
my $widget="amarok";
my $stop=&center("stopped");
my $pause=&center("paused");

print "Connecting to LCDproc at $host\n" if ($verbose >= 5);
my $remote = IO::Socket::INET->new(
	Proto     => "tcp",
	PeerAddr  => $host,
	PeerPort  => $port,
) or die "Cannot connect to LCDproc port\n";

$remote->autoflush(1);

sleep 1;

print $remote "hello\n";
my $lcdconnect = <$remote>;
print $lcdconnect if ($verbose >=5);

($lcdconnect =~ /lcd.+wid\s+(\d+)\s+hgt\s+(\d+)/);
my $lcdwidth = $1; my $lcdheight= $2;
print "Detected LCD size of $lcdwidth x $lcdheight\n" if ($verbose >= 5);

# Turn off blocking mode...
fcntl($remote, F_SETFL, O_NONBLOCK);

print $remote "client_set name {AMAROK_LCD}\n";
print $remote "screen_add amarok\n";
print $remote "screen_set amarok name {AMAROK_LCD}\n";
print $remote "screen_set amarok heartbeat on\n";
print $remote "widget_add amarok artist title\n";
print $remote "widget_add amarok title string\n";
print $remote "widget_add amarok album string\n";
print $remote "widget_add amarok sep string\n";

&dump();

while(1){
	$input=<STDIN>;
	#`kdialog --msgbox "$input"`;
	if($input=~/trackChange/){
		&dump();
	} elsif($input=~/engineStateChange/){
		if($input=~/paused/){
			&lcd("title", 1, 3, $pause);
		} elsif($input=~/play/){
#			&lcd("title", 1, 3, "       playing");
#			sleep 2;
			&dump();
		} elsif($input=~/empty/){
			&lcd("title", 1, 3, $stop);
		}
	}
}

sub mins(){
	my $totsecs=$_[0];
	my $secs=$totsecs%60;
	my $mins=($totsecs-$secs)/60;
	$secs='0'.$secs if($secs<10);
	return "${mins}:${secs}";
}
	
sub dump(){
	$artist=`$dcop artist`;
	$album=&center(`$dcop album`);
	$title=&center(`$dcop title`);
	chomp $title;
	chomp $artist;
	chomp $album;
	&lcd("title", 1, 3, $title);
	&lcd("artist", "", "", $artist);
	&lcd("album", 1, 4, $album);
	&lcd("sep", 1, 2, "_-^-_-^-^-_-^-^-_-^-");
}

sub center(){
	my $num=10-(length($_[0])/2);
	return " "x$num.$_[0];
}

sub lcd(){
	my $tmp=$_[0];
	my $x=$_[1];
	my $y=$_[2];
	my $stuff=$_[3];
	print $remote "widget_set $widget $tmp $x $y {$stuff}\n";
}


