#!/usr/bin/perl

package main;

use strict;
use warnings;
use Controller;

our $VERSION = "0.501";

sub main
{
    my $controller = new Controller;
    $controller->work;
}

main();

__END__

=head1 NAME

amaroklcd

=head1 DESCRIPTION

This program is designed to connect to an LCDd server (http://www.lcdproc.org/) and to amaroK
(http://amarok.kde.org/), and then show the info from amaroK on this screen.

=head1 AUTHOR

Juan C. Muller E<lt>jcmuller@gmail.comE<gt>

=head1 COPYRIGHT (COPYLEFT)

2009, Juan C. Muller

=head1 LICENSE

This programs is licensed under the terms of the GPL.

=cut
