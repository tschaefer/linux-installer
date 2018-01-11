package Linux::Installer::Filesystem::F2fs;

use strict;
use warnings;

use Moose;
with 'Linux::Installer::Filesystem';

has '+name' => (
    default => 'f2fs',
);

sub make {
    my $self = shift;

    my $cmd = sprintf "mkfs.f2fs %s %s",
      $self->label ? "-l " . $self->label : '',
      $self->device;
    $self->exec( $cmd, undef, undef, 1 );

    return;
}

__PACKAGE__->meta->make_immutable;

1;
