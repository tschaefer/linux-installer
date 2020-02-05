package Linux::Installer;

use strict;
use warnings;

use Moose;
with 'Linux::Installer::Utils::Tools';

use Readonly;
use English qw(-no_match_vars);

use File::Spec;
use File::Temp;
use JSON::XS;
use YAML::XS;
use Try::Tiny;

use Linux::Installer::Disk;
use Linux::Installer::Utils::Types;

our $VERSION = '1.00';

no warnings qw( uninitialized );

has 'bootloader' => (
    is       => 'ro',
    isa      => 'Bootloader',
    lazy     => 1,
    builder  => '_build_bootloader',
    init_arg => undef,
);

has 'config' => (
    is       => 'ro',
    isa      => 'HashRef',
    lazy     => 1,
    builder  => '_build_config',
    init_arg => undef,
);

has 'device' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'disk' => (
    is       => 'ro',
    isa      => 'Disk',
    lazy     => 1,
    builder  => '_build_disk',
    init_arg => undef,
);

has 'filesystems' => (
    is       => 'ro',
    isa      => 'Maybe[ArrayRef[Filesystem]]',
    lazy     => 1,
    builder  => '_build_filesystems',
    init_arg => undef,
);

has 'images' => (
    is       => 'ro',
    isa      => 'Maybe[ArrayRef[Image]]',
    lazy     => 1,
    builder  => '_build_images',
    init_arg => undef,
);

has 'configfile' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'partitions' => (
    is       => 'ro',
    isa      => 'ArrayRef[Partition]',
    lazy     => 1,
    builder  => '_build_partitions',
    init_arg => undef,
);

has 'root' => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    builder  => '_build_root',
    init_arg => undef,
);

has 'mountpoint' => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    builder  => '_build_mountpoint',
    init_arg => undef,
);

Readonly::Scalar my $KiB => 1024;

Readonly::Hash my %BYTES => (
    B   => 1,
    KiB => $KiB,
    MiB => $KiB * $KiB,
    GiB => $KiB * $KiB * $KiB,
    TiB => $KiB * $KiB * $KiB * $KiB,
    PiB => $KiB * $KiB * $KiB * $KiB * $KiB,
);

Readonly::Scalar my $PARTITION_ALLIGNMENT => 2048;

sub _build_root {
    my $self = shift;

    return File::Temp::tempdir(
        TMPDIR   => 1,
        TEMPLATE => 'installerXXXXX',
        CLEANUP  => 0
    );
}

sub _require_package {
    my ( $self, $package, $subpackage ) = @_;

    $subpackage = $subpackage if ($subpackage);
    $package    = $package;

    my $perlmodule;
    try {
        $perlmodule = sprintf "Linux/Installer/%s%s.pm", $package,
          $subpackage ? "/$subpackage" : "";
        require $perlmodule;
    }
    catch {
        $self->logger->error_die( sprintf "Module '%s' not found.",
            $perlmodule );
    };

    $perlmodule =~ s/\//::/g;
    $perlmodule =~ s/\.pm//;

    return $perlmodule;
}

sub _build_bootloader {
    my $self = shift;

    my $config = $self->config->{'bootloader'};

    $config->{'root_directory'} = $self->mountpoint;
    $config->{'device'}         = $self->device;
    $config->{'boot_directory'} =
      File::Spec->catdir(
        ( $self->mountpoint, $config->{'boot_directory'} || '/boot' ) );
    $config->{'efi_directory'} =
      File::Spec->catdir(
        ( $self->mountpoint, $config->{'efi_directory'} || '/boot/efi' ) );

    my $package    = $self->_require_package( 'Bootloader', $config->{'type'} );
    my $bootloader = $package->new( { %{$config} } );

    return $bootloader;
}

sub _build_config {
    my $self = shift;

    my $data = $self->read( File::Spec->rel2abs( $self->configfile ) );

    my $config;
    $config = try {
        my $json = JSON::XS::decode_json($data);
        return $json;
    };
    return $config if ($config);

    $config = try {
        my $yaml = YAML::XS::Load($data);
        return $yaml;
    };
    return $config if ($config);

    $self->logger->error_die("Bad configuration file.");

    return;
}

sub _build_disk {
    my $self = shift;

    my $mounts = $self->read('/proc/mounts');
    my $device = $self->device;
    $self->logger->error_die( sprintf "%s is in use.", $self->device )
      if ( $mounts =~ /$device/m );

    my $disk = Linux::Installer::Disk->new( { device => $self->device } );

    return $disk;
}

sub _build_filesystems {
    my $self = shift;

    my ( @filesystems, $number );
    foreach my $partition ( @{ $self->config->{'disk'} } ) {
        if ( $partition->{'filesystem'} && %{ $partition->{'filesystem'} } ) {
            my $config = $partition->{'filesystem'};

            my $part = $self->partitions->[$number];
            my $device =
              ref $part eq 'Linux::Installer::Partition::Crypt'
              ? $part->device_mapper
              : $part->device;

            my $mountpoint;
            $mountpoint =
              File::Spec->catdir(
                ( $self->mountpoint, $config->{'mountpoint'} ) )
              if ( $config->{'mountpoint'} );

            my $package =
              $self->_require_package( 'Filesystem', $config->{'type'} );
            my $filesystem = $package->new(
                {
                    device     => $device,
                    label      => $config->{'label'},
                    mountpoint => $mountpoint,
                }
            );
            push @filesystems, $filesystem;
        }
        $number++;
    }

    return \@filesystems;
}

sub _build_images {
    my $self = shift;

    my ( @images, $number );
    foreach my $partition ( @{ $self->config->{'disk'} } ) {
        $number++;

        if ( $partition->{'filesystem'}{'image'} ) {
            my $config = $partition->{'filesystem'}{'image'};

            my $type = $config->{'type'};

            my $target;
            if ( $type eq 'Tar' ) {
                $target = File::Spec->catdir(
                    (
                        $self->mountpoint,
                        $partition->{'filesystem'}{'mountpoint'}
                    )
                );
            }
            elsif ( $type eq 'Binary' ) {
                $target = sprintf "%s%d", $self->device, $number;
            }

            my $package = $self->_require_package( 'Image', $type );
            my $image   = $package->new(
                {
                    uri    => URI->new( $config->{'uri'} ),
                    target => $target,
                }
            );
            push @images, $image;
        }
    }

    return \@images;
}

sub _determine_partition_size {
    my ( $self, $size ) = @_;

    my ( $mult, $unit ) = $size =~ /([0-9]+)([A-Za-z]+)/;
    $size = $mult * $BYTES{$unit};

    return $size;
}

sub _build_partitions {
    my $self = shift;

    my ( @partitions, $start_sector, $end_sector, $number, $total_size );
    foreach my $partition ( @{ $self->config->{'disk'} } ) {
        $number++;

        my $size = $partition->{'size'};
        $size = $self->_determine_partition_size($size);
        $total_size += $size;

        $start_sector = $end_sector + $PARTITION_ALLIGNMENT;
        $end_sector   = $start_sector + $size / $self->disk->sector_size;

        my $device =
            $self->device =~ /[a-z]+[0-9]+$/
          ? $self->device . 'p'
          : $self->device;
        $device = sprintf "%s%d", $device, $number;

        my $crypt;
        $crypt = "Crypt" if ( $partition->{'crypt'} );
        my $package = $self->_require_package( "Partition", $crypt );

        my $partition = $package->new(
            {
                device       => $device,
                type         => $partition->{'type'},
                size         => $size,
                label        => $partition->{'label'},
                start_sector => $start_sector,
                end_sector   => $end_sector,
                passphrase   => $partition->{'crypt'},
            }
        );
        push @partitions, $partition;
    }

    $self->logger->error_warn( sprintf "Configuration exceeds disk size '%d B'",
        $self->disk->size )
      if ( $total_size > $self->disk->size );

    return \@partitions;
}

sub _build_mountpoint {
    my $self = shift;

    return File::Spec->catdir( ( $self->root, $self->device ) );
}

sub _mount_filesystem {
    my $self = shift;

    my $cmd = sprintf "mkdir -p %s", $self->mountpoint;
    $self->exec($cmd);

    $_->mount()
      foreach ( sort { $a->mountpoint cmp $b->mountpoint }
        @{ $self->filesystems } );

    return;
}

sub _umount_filesystem {
    my $self = shift;

    $_->umount()
      foreach ( sort { $b->mountpoint cmp $a->mountpoint }
        @{ $self->filesystems } );

    return;
}

sub _open_crypted_partition {
    my $self = shift;

    foreach ( @{ $self->partitions } ) {
        $_->open() if ( ref $_ eq "Linux::Installer::Partition::Crypt" );
    }

    return;
}

sub _close_crypted_partition {
    my $self = shift;

    foreach ( @{ $self->partitions } ) {
        $_->close() if ( ref $_ eq "Linux::Installer::Partition::Crypt" );
    }

    return;
}

sub DEMOLISH {
    my $self = shift;

    # DEMOLISH can not be overriden
    my $ref = ref $self;
    return if ( $ref !~ /^Linux::Installer$/ );

    $self->_umount_filesystem();
    $self->_close_crypted_partition();
    my $cmd = sprintf "rm -r %s", $self->root;
    $self->exec($cmd);

    return;
}

sub run {
    my $self = shift;

    $self->logger->info("Run installation.");

    $self->disk->prepare();
    $_->create() foreach ( @{ $self->partitions } );
    $self->_open_crypted_partition();
    $_->make()   foreach ( @{ $self->filesystems } );
    $self->_mount_filesystem();
    $self->bootloader->install();
    $_->install() foreach ( @{ $self->images } );

    $self->logger->info("Finish installation.");

    return 1;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf8

=head1 NAME

Linux::Installer - Main class controlling the installation process.

=head1 SYNOPSIS

    use Linux::Installer;
    use Log::Log4perl;

    Log::Log4perl->init('conf/installer.log.conf');

    my $installer = Linux::Installer->new(
        {
            configfile => 'conf/installer.json',
            device     => '/dev/sda',
        }
    );
    $installer->run();

=head1 DESCRIPTION

This module parses the user configuration, creates the needed
Linux::Installer objects and runs the installation.

=over 2

=item *

zap disk

=item *

create partitions (GPT)

=item *

crypt partitions with LUKS container (dm-crypt)

=item *

make filesystem (ext2, ext3, ext4, f2fs, vfat)

=item *

install images (tarball, binary)

=item *

install bootloader (grub2)

=back

The configuration is provided in JSON or YAML format and B<must> at least
describe a disk with one partition containing a filesystem and the mountpoint
C</boot> and a bootloader, see L<conf/installer.json>.
There is no syntactic nor semantic check of the configuration.

All submodules (Moose classes) can be used seperatly. There are no
dependencies between these.

Log::Log4perl B<must> be initialized external before using Linux::Installer or
one of its submodules, see L</SYNOPSIS> and L<conf/installer.log.conf>.

=head1 ATTRIBUTES

=head2 device

Target device (disk) for installation. [required]

=head2 configfile

File containing the JSON or YAML formatted configuration. [required]

=head1 METHODS

=head2 run

Run the installation.

=head1 AUTHORS

Tobias Schäfer L<github@blackox.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Tobias Schäfer.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
