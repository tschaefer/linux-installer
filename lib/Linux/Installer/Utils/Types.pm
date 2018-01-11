package Linux::Installer::Utils::Types;

use strict;
use warnings;

use Moose::Util::TypeConstraints;
use Moose::Util qw( does_role );
use namespace::clean;


subtype 'Filesystem'
    => as 'Object'
    => where { does_role( $_, 'Linux::Installer::Filesystem') }
    => message { 'Not a filesystem.' };

subtype 'Bootloader'
    => as 'Object'
    => where { does_role( $_, 'Linux::Installer::Bootloader') }
    => message { 'Not a bootloader.' };

subtype 'Image'
    => as 'Object'
    => where { does_role( $_, 'Linux::Installer::Image') }
    => message { 'Not a image.' };

1;
