#!perl -w
use strict;
use warnings;

use 5.006;
use Config;
use ExtUtils::MakeMaker;
use File::Find();

my @demos;
File::Find::find(sub { push @demos, $File::Find::name unless -d $_ }, 'demos');

my %config = (
    NAME          =>  'Win32::GUI::OpenGLFrame',
    VERSION_FROM  =>  'OpenGLFrame.pm',
    ABSTRACT_FROM =>  'OpenGLFrame.pm',
    AUTHOR        =>  'Robert May <robertmay@cpan.org>',
    PREREQ_PM     => {'Win32::GUI' => 0,
                      'OpenGL'     => 0,},

    PL_FILES      => {'OpenGLFrameRC.PL' => '$(BASEEXT).rc', },
    OBJECT        =>  '$(BASEEXT)$(OBJ_EXT) $(BASEEXT).res',
    LIBS          =>  '-lopengl32',
    macro         => {RC => 'rc.exe',
                      RCFLAGS => '',
                      INST_DEMODIR => '$(INST_LIB)/Win32/GUI/demos/$(BASEEXT)',
                      DEMOS => "@demos" },
    clean         => {FILES => '*.rc *.res', },
);

# if building using gcc (MinGW or cygwin) use windres
# as the resource compiler
if($Config{cc} =~ /gcc/i) {
    $config{macro}->{RC} =      'windres';
    $config{macro}->{RCFLAGS} = '-O coff -o $*.res';
}

WriteMakefile(%config);

package MY;

# Add rule for .rc to .res conversion
# Add rules to install demo scripts
sub postamble {
  return <<'__POSTAMBLE';

# Win32::GUI::OpenGLFrame RC section

.rc.res:
	$(RC) $(RCFLAGS) $<

# Win32::GUI::OpenGLFrame demo script section

pure_all :: demo_to_blib
	$(NOECHO) $(NOOP)

demo_to_blib: $(DEMOS)
	$(NOECHO) $(MKPATH) $(INST_DEMODIR)
	$(CP) $? $(INST_DEMODIR)
	$(NOECHO) $(TOUCH) demo_to_blib

clean ::
	-$(RM_F) demo_to_blib

__POSTAMBLE
}
