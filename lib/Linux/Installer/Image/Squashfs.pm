package Linux::Installer::Image::Squashfs;

use strict;
use warnings;

use Moose;
with 'Linux::Installer::Image';

has '+name' => (
    default => 'tar',
);

sub install {
    my $self = shift;

    my $cmd = sprintf "dd if=%s of=%s bs=2M", $self->path, $self->target;
    $self->exec($cmd);

    return;
}

__PACKAGE__->meta->make_immutable;

1;
