package Linux::Installer::Bootloader::Grub;

use strict;
use warnings;

use Moose;
with 'Linux::Installer::Bootloader';

use Readonly;

Readonly my $template =>
  "grub-install %s --boot-directory=%s --efi-directory=%s --target=%s %s";

has 'targets' => (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1,
);

has 'options' => (
    is  => 'ro',
    isa => 'ArrayRef',
);

has 'efi_directory' => (
    is      => 'rw',
    isa     => 'Str',
    default => '/boot/efi',
);

sub install {
    my $self = shift;

    foreach ( @{ $self->targets } ) {
        my $cmd = sprintf $template,
          ( join ' ', map { '--' . $_ } @{ $self->options } ),
          $self->boot_directory,
          $self->efi_directory,
          $_, $self->device;

        $self->exec($cmd);
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf8

=head1 NAME

Linux::Installer::Bootloader::Grub - Provides an bootloader class.

=head1 DESCRIPTION

This module implements the bootloader interface method install and provides
further attributes.

See L<Linux::Installer::Bootloader>

=head1 ATTRIBUTES

=head2 targets

Target platforms. [required]

=head2 options

Command line options. [optional]

=head2 efi_directory

EFI images directory. [optional | required with EFI targets]

=head1 METHODS

=head2 install

Installs B<grub2> bootloader.

=head1 AUTHORS

Tobias Schäfer L<github@blackox.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Tobias Schäfer.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
