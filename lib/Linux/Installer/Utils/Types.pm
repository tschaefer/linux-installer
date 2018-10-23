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

subtype 'Partition'
    => as 'Object'
    => where { $_->isa( 'Linux::Installer::Partition' ) }
    => message { 'Not a partition.' };

subtype 'Disk'
    => as 'Object'
    => where { $_->isa( 'Linux::Installer::Disk' ) }
    => message { 'Not a disk.' };

1;
