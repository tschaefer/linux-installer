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

__END__

=pod

=encoding utf8

=head1 NAME

Linux::Installer::Utils::Types - Provides Moose subtypes.

=head1 DESCRIPTION

The package provides Moose subtypes describing the several Linux::Installer
classes.

=head1 METHODS

=head2 subtype

Does specified role or is specified class.

=over 2

=item *

Filesystem

=item *

Bootloader

=item *

Image

=item *

Partition

=item *

Disk

=back

=head1 AUTHORS

Tobias Schäfer L<github@blackox.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Tobias Schäfer.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
