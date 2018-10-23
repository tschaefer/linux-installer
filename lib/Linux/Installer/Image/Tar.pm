package Linux::Installer::Image::Tar;

use strict;
use warnings;

use Moose;
with 'Linux::Installer::Image';

has '+name' => ( default => 'tar', );

has 'options' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub {
        [ "preserve-permissions", "xattrs-include='*.*'", "numeric-owner", ]
    },
);

sub install {
    my $self = shift;

    my $options = join ' ', map { '--' . $_ } @{ $self->options };
    my $cmd = sprintf "tar --extract --file %s --directory %s %s", $self->path,
      $self->target, $options;
    $self->exec($cmd);

    return;
}

__PACKAGE__->meta->make_immutable;

1;
