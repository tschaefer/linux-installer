package Linux::Installer::Filesystem;

use strict;
use warnings;

use Try::Tiny;

use Moose::Role;
with 'Linux::Installer::Utils::Tools';

requires 'make';

has 'device' => (
    is       => 'ro',
    isa      => 'Str',
    writer   => '_set_device',
    required => 1,
);

has 'label' => (
    is  => 'ro',
    isa => 'Maybe[Str]',
);

has 'mountpoint' => (
    is  => 'rw',
    isa => 'Maybe[Str]',
);

has 'options' => (
    is     => 'ro',
    isa    => 'Maybe[ArrayRef]',
);

before ['make', 'mount', 'umount'] => sub {
    my $self = shift;

    return if ($self->device !~ /\/dev\/loop/);
    return if ($self->device =~ /\/dev\/mapper\/loop/);

    my ($name) = $self->device =~ /\/dev\/(loop.+)/;
    my $device = sprintf "/dev/mapper/%s", $name;

    $self->_set_device($device);

    return;
};

before 'make' => sub {
    my $self = shift;

    $self->logger->info( sprintf "Make filesystem: %s", $self->device );

    return;
};

sub stringify_options {
    my $self = shift;

    return '' if ( !$self->options );

    my $str = '';
    foreach my $option ( @{ $self->options } ) {
        $option = join ' ', each %{$option}
          if ( ref $option eq 'HASH' );

        $str = sprintf "%s %s", $str, $option;
    }

    return $str;
}

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
    my $rc  = try {
        $self->exec($cmd);
        1;
    };
    return if ( !$rc );

    $cmd = sprintf "umount %s", $self->mountpoint;
    $self->exec($cmd);

    $cmd = sprintf "rmdir %s", $self->mountpoint;
    $self->exec( $cmd, );

    return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Linux::Installer::Filesystem - Provides an interface for filesystem classes.

=head1 DESCRIPTION

This module provides common methods and attributes for filesystem classes.

=head1 ATTRIBUTES

=head2 device

Target device (partition). [required]

=head2 label

Filesystem label. [optional]

=head2 mountpoint

Filesystem mountpoint. [optional]

=head1 METHODS

=head2 make

Create filesystem. Must be implemented by consuming class.

=head2 mount

Mount filesystem if is created and mountpoint is available.

=head2

Umount filesystem if mounted.

=head1 AUTHORS

Tobias Schäfer L<github@blackox.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Tobias Schäfer.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
