use strict;
use warnings;

use ExtUtils::MakeMaker;

use File::ShareDir::Install;
$File::ShareDir::Install::INCLUDE_DOTFILES = 1;
$File::ShareDir::Install::INCLUDE_DOTDIRS = 1;
install_share dist => "share";

my %WriteMakefileArgs = (
  "ABSTRACT" => "Convert coordinates between Lat/Lon and the British National Grid",
  "AUTHOR" => "Toby Thurston <toby\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::ShareDir::Install" => "0.06"
  },
  "DISTNAME" => "Geo-Coordinates-OSGB",
  "LICENSE" => "gpl",
  "NAME" => "Geo::Coordinates::OSGB",
  "PREREQ_PM" => {
        'File::Share' => "0.25",
  },
  "VERSION" => "2.20",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = ();

unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

{
package
MY;
use File::ShareDir::Install qw(postamble);
}
