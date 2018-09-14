package Linux::Installer::Partition;

use strict;
use warnings;

use Moose;
with 'Linux::Installer::Utils::Tools';

use Linux::Installer::Utils::Types;

has 'device' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'end_sector' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'label' => (
    is  => 'ro',
    isa => 'Maybe[Str]',
);

has 'size' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'start_sector' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);
has 'type' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub create {
    my ( $self, $start_sector, $end_sector ) = @_;

    $self->logger->info( sprintf "Create partition: %s", $self->device, );

    my ( $device, $number ) =
      $self->device =~ /(\/dev\/[[:lower:]]+)([[:digit:]]+)/;

    my $cmd = sprintf "sgdisk --new=%d:%d:%d %s", $number, $self->start_sector,
      $self->end_sector, $device;
    $self->exec($cmd);

    $cmd = sprintf "sgdisk --typecode=%d:%s %s", $number, $self->type, $device;
    $self->exec($cmd);

    if ( $self->label ) {
        $cmd = sprintf "sgdisk --change-name=%d:%s %s", $number, $self->label,
          $device;
        $self->exec($cmd);
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;
