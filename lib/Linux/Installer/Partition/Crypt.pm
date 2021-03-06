package Linux::Installer::Partition::Crypt;

use strict;
use warnings;

use Moose;
extends 'Linux::Installer::Partition';

use Linux::Installer::Utils::Types;

has 'passphrase' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'key_file' => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    builder  => '_build_key_file',
    init_arg => undef,
);

has 'device_mapper' => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    builder  => '_build_device_mapper',
    init_arg => undef,
);

sub _build_device_mapper {
    my $self = shift;

    my ($device) = $self->device =~ /([[:alnum:]]+)$/;
    my $device_mapper = sprintf "/dev/mapper/%s_crypt", $device;

    return $device_mapper;
}

sub _build_key_file {
    my $self = shift;

    my ( undef, $key_file ) = File::Temp::tempfile(
        OPEN     => 0,
        TMPDIR   => 1,
        TEMPLATE => 'installerXXXXX',
        SUFFIX   => '.dat',
        UNLINK   => 0,
    );

    $self->write( $key_file, $self->passphrase );

    return $key_file;
}

sub DEMOLISH {
    my $self = shift;

    my $cmd = sprintf "rm -f %s", $self->key_file;
    $self->exec($cmd);

    return;
}

after 'create' => sub {
    my $self = shift;

    $self->logger->info( sprintf "Encrypt partition: %s", $self->device );

    my $cmd =
      sprintf
      "cryptsetup luksFormat --batch-mode --type luks2 --key-file=%s %s",
      $self->key_file, $self->device;
    $self->exec($cmd);

    return;
};

sub open {
    my $self = shift;

    return if ( !-e $self->device );

    my ($dm_name) = $self->device_mapper =~ /([[:alnum:]_]+)$/;
    my $cmd = sprintf "cryptsetup open --key-file=%s %s %s", $self->key_file,
      $self->device, $dm_name;
    $self->exec($cmd);

    return;
}

sub close {
    my $self = shift;

    return if ( !-e $self->device_mapper );

    my $cmd = sprintf "cryptsetup close %s", $self->device_mapper;
    $self->exec($cmd);

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf8

=head1 NAME

Linux::Installer::Partition::Crypt - Provides crypt extension for partition class.

=head1 DESCRIPTION

This module provides common methods and attributes to encrypt a partition in
LUKS format with B<cryptsetup>.

See L<Linux::Installer::Partition>

=head1 ATTRIBUTES

=head2 passphrase

Initial passphrase for LUKS container. [required]

=head1 METHODS

=head2 create

This method runs after partition create and initialize the LUKS container.

=head2 open

Opens the LUKS container.

=head2 close

Closes the LUKS container.

=head1 AUTHORS

Tobias Schäfer L<github@blackox.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Tobias Schäfer.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
