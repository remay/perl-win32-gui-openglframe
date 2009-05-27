#!perl -w
use strict;
use warnings;
use ExtUtils::MakeMaker;

# perl script to produce the RC file for
# Win32::GUI::OpenGLFrame:  create Resource
# file with a VERSIONINFO section

# The variables:
my %info = (
    Version => MM->parse_version('OpenGLFrame.pm'),
    Dllname => 'OpenGLFrame.dll',
    Years   => '2006..2009',
);

# Open the target file
if ( @ARGV > 0 ) {
    my $file = $ARGV[0];
    open(my $fh, '>', $file) or die qq(Failed to open '$file': $!);
    select $fh;
}

{
    my $fileVersion = $info{Version};
    $fileVersion .= "_00" unless $fileVersion =~ m/_/;
    $info{FileVersion} =
        sprintf("%02d,%02d,%02d,00", $fileVersion =~ m/^(.*)\.([^_]*)_?(.*)$/);
}

print <<"__RC";
#include "Winver.h"

1 VERSIONINFO
FILEVERSION    $info{FileVersion}
PRODUCTVERSION $info{FileVersion}
FILEOS         VOS__WINDOWS32
FILETYPE       VFT_DLL
{
  BLOCK "StringFileInfo"
  {
    BLOCK "040904E4"
    {
      VALUE "Comments"         , "Perl Win32::GUI::OpenGLFrame - an extension to Win32::GUI"
      VALUE "CompanyName"      , "Robert May"
      VALUE "FileDescription"  , "Win32::GUI::OpenGLFrame perl extension"
      VALUE "FileVersion"      , "$info{Version}"
      VALUE "InternalName"     , "$info{Dllname}"
      VALUE "LegalCopyright"   , "Copyright © Robert May $info{Years}"
      VALUE "LegalTrademarks"  , "GNU and Artistic licences"
      VALUE "OriginalFilename" , "$info{Dllname}"
      VALUE "ProductName"      , "Win32::GUI::OpenGLFrame perl extension"
      VALUE "ProductVersion"   , "$info{Version}"
    }
  }

  BLOCK "VarFileInfo"
  {
    VALUE "Translation", 0x0409, 0x04E4
  }
}
__RC

exit(0);
__END__
