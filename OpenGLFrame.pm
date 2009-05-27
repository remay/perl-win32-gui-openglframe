package Win32::GUI::OpenGLFrame;

# Win32::GUI::OpenGLFrame
# (c) Robert May, 2006..2009
# released under the same terms as Perl.

use 5.006;
use strict;
use warnings;

our $VERSION = "0.00_01";
our $XS_VERSION = $VERSION;
$VERSION = eval $VERSION;

use Win32::GUI qw(WS_OVERLAPPEDWINDOW WS_CHILD WS_CLIPCHILDREN WS_CLIPSIBLINGS);
our @ISA = qw(Win32::GUI::Window);

use Exporter qw(import);
our @EXPORT_OK = qw(w32gSwapBuffers);

require XSLoader;
XSLoader::load('Win32::GUI::OpenGLFrame', $XS_VERSION);

sub Win32::GUI::Window::AddOpenGLFrame {
    return Win32::GUI::OpenGLFrame->new(@_);
}

sub CS_OWNDC()           {32}
our $WINDOW_CLASS;

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
        %options,
    );

    # Set a suitable Pixel format
    my $dc = $self->_SetOpenGLPixelFormat($doubleBuffer, $depthFlag) or die "SetOpenGLPixelFormat failed: $^E";

    # Create an OpenGL rendering context for this window, and
    # activate it
    my $rc = wglCreateContext($dc) or die "wglCreateContext: $^E";
    wglMakeCurrent($dc, $rc) or die "wglMakeCurrent: $^E";

    # Store away our class instance data
    $self->ClassData( {
            dc      => $dc,
            rc      => $rc,
            display => $displayfunc,
            reshape => $reshapefunc,
        } );

    # Call our initialisation function
    $initfunc->($self) if $initfunc;

    # Now that we've got everything initialised, register our _paint and _resize
    # handlers.
    $self->SetEvent("Paint", \&_paint);
    $self->SetEvent("Resize", \&_resize);
    
    # Ensure that out paint and resize (reshape) handers get called once.
    $self->_resize();
    $self->InvalidateRect(0);
    
    return $self;
}

sub DESTROY {
    my ($self) = @_;

    # my $idata = $self->ClassData();
    # Previous line shows a bug in ClassData, where _UserData() can return undef if the
    # window has been destroyed and the perlud structure de-allocated.  We do our own thing
    # here for now:
    # XXX Submit patch to Win32::GUI to fix ClassData()
    my $idata;
    if (my $tmp = $self->_UserData()) {
        $idata = $tmp->{__PACKAGE__};
    }

    if(defined $idata) {
        wglMakeCurrent();  # remove the current rendering context
        wglDeleteContext($idata->{rc});
        Win32::GUI::DC::ReleaseDC($self, $idata->{dc}); # not necessary, but good form
    }

    $self->SUPER::DESTROY(@_); # pass destruction up the chain
}

######################################################################
# Static (non-method) functions
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

    my $idata = $self->ClassData();

    wglMakeCurrent($idata->{dc}, $idata->{rc}) or die "wglMakeCurrent: $^E";

    if ($idata->{display}) {
        $idata->{display}->($self);
        glFlush();
    }
    else {
        # default: clear all buffers, and display
        glClear();
        w32gSwapBuffers();
    }

    return 0;
}

sub _resize {
    my ($self) = @_;

    my $idata = $self->ClassData();

    wglMakeCurrent($idata->{dc}, $idata->{rc}) or die "wglMakeCurrent: $^E";

    if ($idata->{reshape}) {
        $idata->{reshape}->($self->ScaleWidth(), $self->ScaleHeight())
    }
    else {
	    # default: resize viewport to window
        glViewport(0,0,$self->ScaleWidth(),$self->ScaleHeight());
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
