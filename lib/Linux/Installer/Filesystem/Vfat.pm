package Linux::Installer::Filesystem::Vfat;

use strict;
use warnings;

use Moose;
with 'Linux::Installer::Filesystem';

has '+name' => (
    default => 'vfat',
);

sub make {
    my $self = shift;

    my $cmd = sprintf "mkfs.vfat %s %s",
      $self->label ? "-n " . $self->label : '',
      $self->device;
    $self->exec( $cmd, undef, undef, 1 );

    return;
}

__PACKAGE__->meta->make_immutable;

1;
