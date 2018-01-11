package Linux::Installer::Bootloader::Grub;

use strict;
use warnings;

use Moose;
with 'Linux::Installer::Bootloader';

use Readonly;

use File::Spec;

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

has '+name' => (
    default => 'Grub',
);

sub install {
    my $self = shift;

    foreach ( @{ $self->targets } ) {
        my $cmd = sprintf $template,
          ( join ' ', map { '--' . $_ } @{ $self->options } ),
          File::Spec->catdir(
            ( $self->root_directory, $self->boot_directory ) ),
          File::Spec->catdir( ( $self->root_directory, $self->efi_directory ) ),
          $_, $self->device;

        $self->exec($cmd);
    }

    return;
}

1;
