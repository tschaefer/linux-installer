package Linux::Installer::Partition;

use strict;
use warnings;

use Moose;
with 'Linux::Installer::Utils::Tools';

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
    is  => 'ro',
    isa => 'Maybe[Int]',
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

    $self->logger->info( sprintf "Create partition: %s", $self->device );

    my ( $device, $number );
    if ( $self->device =~ /[0-9]+p[0-9]+$/ ) {
        ( $device, $number ) =
          $self->device =~ /(\/dev\/[[:alnum:]]+)p([[:digit:]]+)/;
    }
    else {
          ( $device, $number ) =
            $self->device =~ /(\/dev\/[[:lower:]]+)([[:digit:]]+)/;
    }

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

__END__

=pod

=encoding utf8

=head1 NAME

Linux::Installer::Partition - Creates a partition.

=head1 SYNOPSIS

    use Linux::Installer::Partition;
    use Log::Log4perl;

    Log::Log4perl->init('conf/installer.log.conf');

    my $part = Linux::Installer::Partition->new(
        {
            device       => /dev/sda1,
            start_sector => 2048,
            end_sector   => 1048576,
            type         => 'EF00',
            label        => 'EFI',
        }
    );
    $part->create();

=head1 DESCRIPTION

This module provides a method and attributes for creating a partition with
B<sgdisk>.

=head1 ATTRIBUTES

=head2 device

Target device (partition). [required]

=head2 start_sector

Partition start sector. [required]

=head2 end_sector

Partition end sector. [required]

=head2 type

Partition type. [required]

=head2 label

Partition label. [optional]

=head2 size

Partition size. [optional]

=head1 METHODS

=head2 create

Run the creation.

=head1 AUTHORS

Tobias Schäfer L<github@blackox.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Tobias Schäfer.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
