package Linux::Installer::Filesystem::Ext3;

use strict;
use warnings;

use Moose;
with 'Linux::Installer::Filesystem';

has '+name' => (
    default => 'ext3',
);

sub make {
    my $self = shift;

    my $cmd = sprintf "mkfs.ext3 %s %s",
      $self->label ? "-L " . $self->label : '',
      $self->device;
    $self->exec( $cmd, undef, undef, 1 );

    $cmd = sprintf "tune2fs -c -1 -i 0 %s", $self->device;
    $self->exec($cmd);

    return;
}

__PACKAGE__->meta->make_immutable;

1;
