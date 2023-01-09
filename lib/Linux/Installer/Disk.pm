package Linux::Installer::Disk;

use strict;
use warnings;

use Moose;
with 'Linux::Installer::Utils::Tools';

use File::Spec;

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

sub _read_disk_info {
    my ( $self, $uri ) = @_;

    my ($dev) = $self->device =~ /([a-z0-9]+)$/;
    my $file  = File::Spec->catdir( '/sys/class/block', $dev, $uri );
    my $info; $info  = $self->read($file) if (-e $file);

    return $info;
}

sub _build_name {
    my $self = shift;

    my $name = $self->_read_disk_info('device/model') || 'unknwon';

    return $name;
}

sub _build_sector_size {
    my $self = shift;

    my $sector_size = $self->_read_disk_info('queue/hw_sector_size');

    return $sector_size;
}

sub _build_size {
    my $self = shift;

    my $sectors = $self->_read_disk_info('size');
    my $size    = $sectors * $self->sector_size;

    return $size;
}

sub BUILD {
    my $self = shift;

    return $self->which('sgdisk');
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

__END__

=pod

=encoding utf8

=head1 NAME

Linux::Installer::Disk - Zaps a disk.

=head1 SYNOPSIS

    use Linux::Installer::Disk;
    use Log::Log4perl;

    Log::Log4perl->init('conf/installer.log.conf');

    my $disk = Linux::Installer::Disk->new(
        {
            device => '/dev/sda',
        }
    );
    $disk->prepare();

=head1 DESCRIPTION

This module provides attributes gathering some infos from sysfs about the
device (disk) and a method for zapping the disk with B<sgdisk>.

=head1 ATTRIBUTES

=head2 device

Target device (disk). [required]

=head2 name

Device model name. [readonly]

=head2 sector_size

Device sector size in bytes. [readonly]

=head2 size

Device size in bytes. [readonly]

=head1 METHODS

=head2 prepare

Zap the device.

=head1 AUTHORS

Tobias Schäfer L<github@blackox.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Tobias Schäfer.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
