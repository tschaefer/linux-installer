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

    return if ( !$path );

    my $out;
    my $cmd = sprintf "file -i %s", $path;
    $self->exec( $cmd, \$out );

    my ($application) = $out =~ /$path: application\/(.+); /;

    if ( $application =~ /gzip$/ ) {
        $cmd = sprintf "tar -xzf %s -C %s", $path, $self->target;
    }
    elsif ( $application =~ /bzip2$/ ) {
        $cmd = sprintf "tar -xjf %s -C %s", $path, $self->target;
    }
    elsif ( $application =~ /xz$/ ) {
        $cmd = sprintf "tar -xJf %s -C %s", $path, $self->target;
    }
    elsif ( $application =~ /path$/ ) {
        $cmd = sprintf "tar -xf %s -C %s", $path, $self->target;
    }

    $self->exec($cmd);

    return;
}

__PACKAGE__->meta->make_immutable;

1;
