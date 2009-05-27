#!perl -wT
use strict;
use warnings;

use Test::More (tests => 1);

#Check that Win32::GUI::OpenGLFrame exports w32gSwapBuffers
#as advertised.
use Win32::GUI::OpenGLFrame;
ok(not exists &__PACKAGE__::w32gSwapBuffers, "w32gSwapBuffers not exported by default");

use Win32::GUI::OpenGLFrame qw(w32gSwapBuffers);
ok(exists &__PACKAGE__::w32gSwapBuffers, "w32gSwapBuffers exported on request");
