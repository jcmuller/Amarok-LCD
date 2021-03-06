################################################################################
# Controller
################################################################################
# $Id$
################################################################################
package Controller;
$__PACKAGE__::VERSION = q($Rev$);

use strict;
use warnings;

our @ISA    = qw(Object);
our @Export = qw();

use Carp;
use IO::Pipe;
use threads;

use Configure;
use InfoControl;
use LCDManager;
use Object;
use SliderControl;

sub work
{
	my ($this) = @_;

	$this->createThreads;

	for (qw/TERM INT HUP/)
	{
		$SIG{$_} = sub { $this->doExit };
	}

	$this->waitForInputAndProcess();
}

sub waitForInputAndProcess
{
	my ($this) = @_;

	my $to_control = $this->{_to_control};

	while (<STDIN>)
	{
		$this->debug("Controller: $_");

		if (/configure/)
		{
			my $t = threads->create('createConfigureThread', $this);
			$t->detach;
		}
		elsif (/exit|quit/)
		{
			$this->debug("Controller: to control: exit");
			print $to_control "exit\n";
			$this->{_control}->join;
			$this->{_slider}->join;
			$this->{_lcd}->join;
			exit(0);
		}
		else
		{
			print $to_control $_;
		}
	}

	$this->doExit();
}

sub doExit
{
	my ($this) = @_;

	my $to_control = $this->{_to_control};

	$this->debug("Controller: to control: exit");
	print $to_control "exit\n";
	$this->{_control}->join;
	$this->{_slider}->join;
	$this->{_lcd}->join;
	exit(0);
}

sub createThreads
{
	my ($this) = @_;

	my $to_lcd     = new IO::Pipe;
	my $to_slider  = new IO::Pipe;
	my $to_control = new IO::Pipe;

	$this->{_lcd}     = threads->create('createLcdThread', $this, $to_lcd);
	$this->{_slider}  = threads->create('createSliderThread', $this, $to_slider, $to_lcd);
	$this->{_control} = threads->create('createControlThread', $this, $to_control, $to_lcd, $to_slider);

	$to_control->writer;
	$to_control->autoflush;
	$this->{_to_control} = $to_control;
}

sub createLcdThread
{
	my ($this, $to_lcd) = @_;

	new LCDManager(input => $to_lcd);
}

sub createSliderThread
{
	my ($this, $to_slider, $to_lcd) = @_;

	new SliderControl(input => $to_slider, output => $to_lcd);
}

sub createControlThread
{
	my ($this, $to_control, $to_lcd, $to_slider) = @_;

	new InfoControl(input => $to_control, output => $to_lcd, slider => $to_slider);
}

sub createConfigureThread
{
	my ($this) = @_;

	new Configure;
}

1;
