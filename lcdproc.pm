package lcdproc;
use strict;
use warnings;
use Carp;
use IO::Socket::INET;
use Fcntl;
use dcop;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = {};
	$self->{start}   = localtime;
	$self->{host}    = "localhost";
	$self->{port}    = "13666";
	$self->{verbose} = 0;
	$self->{input}   = undef;
	$self->{title}   = undef;
	$self->{artist}  = undef;
	$self->{album}   = undef;
	$self->{dcop}    = undef;
	$self->{widget}  = "amarok";
	$self->{remote}  = undef;
	$self->{misc}    = undef;
	$self->{shape}   = "####################";
	bless( $self, $class );
	$self->{stop}  = $self->center("stopped");
	$self->{pause} = $self->center("paused");
	$self->{dcop}  = dcop->new();

	return $self;
}

sub connect {
	my $self = shift;
	$self->debug("Connecting to LCDproc at $self->{host}\n");
	$self->{remote} = IO::Socket::INET->new(
		Proto    => "tcp",
		PeerAddr => $self->{host},
		PeerPort => $self->{port},
	  )
	  or croak "Cannot connect to LCDproc port: $!\n";
	$self->{remote}->autoflush(1);

	sleep 1;
}

sub initialize {
	my $self = shift;
	my $fh   = *{ $self->{remote} };
	print $fh "hello\n";
	$self->{misc} = <$fh>;
	$self->debug( $self->{misc} );
	( $self->{misc} =~ /lcd.+wid\s+(\d+)\s+hgt\s+(\d+)/ );
	$self->debug("Detected LCD size of $1 x $2\n");

	#   Turn off blocking mode...
	fcntl( $fh, F_SETFL, O_NONBLOCK );

	print $fh "client_set name {AMAROK_LCD}\n";
	print $fh "screen_add amarok\n";
	print $fh "screen_set amarok name {AMAROK_LCD}\n";
	print $fh "screen_set amarok heartbeat on\n";
	print $fh "widget_add amarok artist title\n";
	print $fh "widget_add amarok title string\n";
	print $fh "widget_add amarok album string\n";
	print $fh "widget_add amarok sep string\n";
}

sub dump {
	my $self = shift;
	$self->lcd( widget => "artist", data => $self->{dcop}->artist );

	$self->lcd( widget => "sep", xPos => 1, yPos => 2,
		data => substr( $self->{shape}, 0, $self->{dcop}->vol() / 5 ) 
	);
	$self->lcd( widget => "title", xPos => 1, yPos =>3, data => $self->center( $self->{dcop}->title ) );
	$self->lcd( widget => "album", xPos => 1, yPos => 4, data => $self->center( $self->{dcop}->album ) );
}

sub center {
	my $self = shift;
	my $num = 10 - ( length( $_[0] ) / 2 );
	return " " x $num . $_[0];
}

sub lcd {
	my $self  = shift;
	my $fh    = *{ $self->{remote} };
	my %params = @_;
	return unless( $params{widget} && $params{data} );
	$params{xPos}="" unless $params{xPos};
	$params{yPos}="" unless $params{yPos};
	print $fh "widget_set $self->{widget} $params{widget} $params{xPos} $params{yPos} {$params{data}}\n";
}

sub debug {
	my $self = shift;
	warn shift if ( $self->{verbose} > 4 );
}

return 1;
