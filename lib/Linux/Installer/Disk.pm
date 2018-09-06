package Linux::Installer::Disk;

use strict;
use warnings;

use Moose;
with 'Linux::Installer::Utils::Tools';

has 'device' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    builder  => '_build_name',
    init_arg => undef,
);

has 'sector_size' => (
    is       => 'ro',
    isa      => 'Int',
    lazy     => 1,
    builder  => '_build_sector_size',
    init_arg => undef,
);

has 'size' => (
    is       => 'ro',
    isa      => 'Int',
    lazy     => 1,
    builder  => '_build_size',
    init_arg => undef,
);

sub _build_name {
    my $self = shift;

    my ($dev) = $self->device =~ /.+\/(.+)$/;
    my $file  = "/sys/class/block/$dev/device/model";
    my $name  = $self->read($file);

    return $name;
}

sub _build_sector_size {
    my $self = shift;

    my ($dev)       = $self->device =~ /.+\/(.+)$/;
    my $file        = "/sys/class/block/$dev/queue/hw_sector_size";
    my $sector_size = $self->read($file);

    return $sector_size;
}

sub _build_size {
    my $self = shift;

    my ($dev)   = $self->device =~ /.+\/(.+)$/;
    my $file    = "/sys/class/block/$dev/size";
    my $sectors = $self->read($file);
    my $size    = $sectors * $self->sector_size;

    return $size;
}

sub prepare {
    my $self = shift;

    $self->logger->info( sprintf "Prepare disk: %s", $self->device );

    my $cmd = sprintf "sgdisk --zap-all %s", $self->device;
    $self->exec($cmd);

    return;
}

__PACKAGE__->meta->make_immutable;

1;
