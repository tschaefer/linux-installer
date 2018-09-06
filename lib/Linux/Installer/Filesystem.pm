package Linux::Installer::Filesystem;

use strict;
use warnings;

use Moose::Role;
with 'Linux::Installer::Utils::Tools';

use Linux::Installer::Image;
use Linux::Installer::Utils::Types;

requires 'make';

has 'device' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'label' => (
    is  => 'ro',
    isa => 'Maybe[Str]',
);

has 'mountpoint' => (
    is  => 'ro',
    isa => 'Maybe[Str]',
);

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
);

before 'make' => sub {
    my $self = shift;

    $self->logger->info( sprintf "Make filesystem: %s", $self->device );

    return;
};

sub mount {
    my ($self) = @_;

    return if ( !$self->mountpoint );

    if ( !-d $self->mountpoint ) {
        my $cmd = sprintf "mkdir %s", $self->mountpoint;
        $self->exec($cmd);
    }

    my $cmd = sprintf "mount %s %s", $self->device, $self->mountpoint;
    $self->exec($cmd);

    return;
}

sub umount {
    my ( $self, $root ) = @_;

    return if ( !$self->mountpoint );

    return if ( !-e $self->mountpoint );

    my $cmd = sprintf "mountpoint -q %s", $self->mountpoint;
    return if ( $self->exec($cmd) );

    $cmd = sprintf "umount %s", $self->mountpoint;
    $self->exec($cmd);

    $cmd = sprintf "rmdir %s", $self->mountpoint;
    $self->exec( $cmd, );

    return;
}

1;
