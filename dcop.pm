package dcop;
use strict;
use IO::Socket::INET;
use Fcntl;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = {};
	$self->{start} = localtime;
	$self->{user}  = "sputnik";
	$self->{dcop}  = "/usr/bin/dcop --user $self->{user} amarok player";
	bless( $self, $class );
	return $self;
}

sub album() {
	my $self = shift;
	chomp( $_ = `$self->{dcop} album` );
	return $_;
}

sub artist() {
	my $self = shift;
	chomp( $_ = `$self->{dcop} artist` );
	return $_;
}

sub title() {
	my $self = shift;
	chomp( $_ = `$self->{dcop} title` );
	return $_;
}

sub playPause() {
	my $self = shift;
	system("$self->{dcop} playPause");
}

sub stop() {
	my $self = shift;
	system("$self->{dcop} stop");
}

sub next() {
	my $self = shift;
	system("$self->{dcop} next");
}

sub prev() {
	my $self = shift;
	system("$self->{dcop} prev");
}

sub getRandom(){
	my $self = shift;
	chomp($_=`$self->{dcop} randomModeStatus`);
	return $_;
}

sub toggleRandom() {
	# returns new status of randomness
	my $self = shift;
	chomp( $_ = `$self->{dcop} randomModeStatus` );
	if ( $_ =~ /true/ ) {
		system("$self->{dcop} enableRandomMode 0");
	}
	else {
		system("$self->{dcop} enableRandomMode 1");
	}
	chomp( $_ = `$self->{dcop} randomModeStatus` );
	return $_;
}

sub mute() {
	my $self = shift;
	system("$self->{dcop} mute");
}

sub volUp() {
	my $self = shift;
	system("$self->{dcop} volumeUp");
}

sub volDn() {
	my $self = shift;
	system("$self->{dcop} volumeDown");
}

sub vol() {
	my $self = shift;
	chomp( $_ = `$self->{dcop} getVolume` );
	return $_;
}

sub status() {
	my $self = shift;
	chomp( $_ = `$self->{dcop} status` );
	return $_;
}

sub track(){
				my $self = shift;
				chomp($_=`$self->{dcop} track`);
				return $_;
}

sub totaltime(){
				my $self = shift;
				chomp($_=`$self->{dcop} totalTime`);
				return $_;
}

sub elapsed(){
				my $self = shift;
				chomp($_=`$self->{dcop} trackCurrentTime`);
				
				return $self->_mins($_);
}

sub _mins(){
	my $self = shift;
	my $totsecs = shift;
	my $secs = $totsecs % 60;
	my $mins = ($totsecs-$secs)/60;
	$secs = '0'.$secs if($secs<10);
	return "${mins}:${secs}";
}

sub fwd(){
				my $self = shift;
				system("$self->{dcop} seekRelative +5");
}

sub rew(){
				my $self = shift;
				system("$self->{dcop} seekRelative -5");
}

#sub album(){
#				my $self = shift;
#				system("$self->{dcop} album");
#}
#

#sub album(){
#				my $self = shift;
#				chomp($_=`$self->{dcop} album`);
#				return $_;
#}
#
return 1;
