package Linux::Installer::Image::Tar;

use strict;
use warnings;

use Moose;
with 'Linux::Installer::Image';

has '+name' => (
    default => 'tar',
);

sub install {
    my $self = shift;

    my $path = $self->path;

    my %opts = (
        gzip  => 'xzf',
        bzip2 => 'xjf',
        xz    => 'xJf',
        tar   => 'xf',
    );

    my $out;
    my $cmd = sprintf "file --mime-type %s", $path;
    $self->exec( $cmd, \$out );

    my ($__, $app) = $out =~ /$path: application\/(x-)?(.+)/;
    $cmd = sprintf "tar -%s %s -C %s", $opts{$app}, $path, $self->target;

    $self->exec($cmd);

    return;
}

__PACKAGE__->meta->make_immutable;

1;
