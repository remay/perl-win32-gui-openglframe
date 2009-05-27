package Win32::GUI::OpenGLFrame;

# Win32::GUI::OpenGLFrame
# (c) Robert May, 2006..2009
# released under the same terms as Perl.

use 5.006;
use strict;
use warnings;

use Win32::GUI qw(WS_OVERLAPPEDWINDOW WS_CHILD WS_CLIPCHILDREN WS_CLIPSIBLINGS);
require Exporter;
our @ISA = qw(Exporter Win32::GUI::Window);
sub CS_OWNDC()           {32}

our @EXPORT_OK = qw(w32gSwapBuffers);

our $WINDOW_CLASS;
our $VERSION = "0.00_01";
our $XS_VERSION = $VERSION;
$VERSION = eval $VERSION;

require XSLoader;
XSLoader::load('Win32::GUI::OpenGLFrame', $XS_VERSION);

sub Win32::GUI::Window::AddOpenGLFrame {
    return Win32::GUI::OpenGLFrame->new(@_);
}

sub new {
    my $class = shift;
    my $parent = shift;
    my %options = @_;

    my $displayfunc = delete($options{-display});
    my $initfunc = delete($options{-init});
    my $reshapefunc = delete($options{-reshape});
    my $doubleBuffer = delete($options{-doubleBuffer}) || 0;
    my $depthFlag = delete($options{-depth}) || 0;

    # Window class with CS_OWNDC, and no background brush
    $WINDOW_CLASS = Win32::GUI::Class->new(
        -name  => "Win32GUI_OpenGLFrame",
        -style => CS_OWNDC,
        -brush => 0,
    ) unless $WINDOW_CLASS;

    my $self = $class->SUPER::new(
        -parent    => $parent,
        -popstyle  => WS_OVERLAPPEDWINDOW,
        -pushstyle => WS_CHILD|WS_CLIPCHILDREN|WS_CLIPSIBLINGS,
        -class => $WINDOW_CLASS,
        -visible => 1,
        -onPaint => \&_paint,
        -onResize => \&_resize,
        %options,
    );
    $self->{-display} = $displayfunc;
    $self->{-reshape} = $reshapefunc;

    # TODO - don't want to destroy the DC
    my $dc = $self->GetDC();
    $self->{-dc} = $dc->{-handle};

    # Set a suitable Pixel format
    $self->_SetOpenGLPixelFormat($doubleBuffer, $depthFlag) or die "SetOpenGLPixelFormat failed: $^E";

    # Create an OpenGL rendering context for this window, and
    # activate it
    $self->{-rc} = wglCreateContext($self->{-dc}) or die "wglCreateContext: $^E";
    wglMakeCurrent($self->{-dc}, $self->{-rc}) or die "wglMakeCurrent: $^E";

    $initfunc->() if $initfunc;
    $reshapefunc->($self->ScaleWidth(), $self->ScaleHeight()) if $reshapefunc;

    return $self;
}

sub DESTROY {
    my ($self) = @_;

    wglMakeCurrent();  # remove the current rendering context
    wglDeleteContext($self->{-rc});
    #TODO release DC!

    $self->SUPER::DESTROY(@_); # pass destruction up the chain
}

######################################################################
# Static (non-method) functions
# TODO why did I do this - is it to avoid clashing with OpenGL's
# SwapBuffers??
######################################################################
sub w32gSwapBuffers
{
    my $hdc = wglGetCurrentDC();
    if($hdc) {
        glFlush(); # XXX Should we have a glFinish() here?
        return SwapBuffers($hdc);
    }

    return 0;
}

######################################################################
# internal callback functions
######################################################################
sub _paint {
    my ($self, $dc) = @_;
    $dc->Validate();

    wglMakeCurrent($self->{-dc}, $self->{-rc}) or die "wglMakeCurrent: $^E";
    if ($self->{-display}) {
        $self->{-display}->($self);
        glFlush();
    }
    else {
        # default: clear all buffers, and diaplay
        glClear();
	w32gSwapBuffers();
    }

    return 0;
}

sub _resize {
    my ($self) = @_;
    if($self->{-handle} and $self->{-dc} and $self->{-rc}) {
        wglMakeCurrent($self->{-dc}, $self->{-rc}) or die "wglMakeCurrent: $^E";
        if ($self->{-reshape}) {
            $self->{-reshape}->($self->ScaleWidth(), $self->ScaleHeight())
        }
        else {
	    # default: resize viewport to window
            glViewport(0,0,$self->ScaleWidth(),$self->ScaleHeight());
        }
    }

    return 1;
}

1; # end of OpenGLFrame.pm
__END__

=head1 NAME

Win32::GUI::OpenGLFrame - Integrate OpenGL with Win32::GUI

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 EXPORTS

=head1 AVAILABLE FUNCTIONS

=head1 SEE ALSO

=head1 SUPPORT

Contact the author for support.

=head1 AUTHORS

Robert May (C<robertmay@cpan.org>)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006..2009 by Robert May

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
