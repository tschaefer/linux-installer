package Linux::Installer;

use strict;
use warnings;

use Moose;
with 'Linux::Installer::Utils::Tools';

use File::Spec;
use File::Temp;
use JSON qw( decode_json );

use Linux::Installer::Disk;
use Linux::Installer::Partition;
use Linux::Installer::Utils::Types;

our $VERSION = '0.01';

has 'bootloader' => (
    is      => 'ro',
    isa     => 'Bootloader',
    lazy    => 1,
    builder => '_build_bootloader',
    init_arg => undef,
);

has 'config' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_config',
    init_arg => undef,
);

has 'device' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'disk' => (
    is      => 'ro',
    isa     => 'Linux::Installer::Disk',
    lazy    => 1,
    builder => '_build_disk',
    init_arg => undef,
);

has 'filesystems' => (
    is      => 'ro',
    isa     => 'Maybe[ArrayRef[Filesystem]]',
    lazy    => 1,
    builder => '_build_filesystems',
    init_arg => undef,
);

has 'images' => (
    is      => 'ro',
    isa     => 'Maybe[ArrayRef[Image]]',
    lazy    => 1,
    builder => '_build_images',
    init_arg => undef,
);

has 'json' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'partitions' => (
    is      => 'ro',
    isa     => 'ArrayRef[Linux::Installer::Partition]',
    lazy    => 1,
    builder => '_build_partitions',
    init_arg => undef,
);

has 'root' => (
    is       => 'ro',
    lazy     => 1,
    builder  => '_build_root',
    init_arg => undef,
);

sub _build_root {
    my $self = shift;

    return File::Temp::tempdir(
        TMPDIR   => 1,
        TEMPLATE => 'installerXXXXX',
        CLEANUP  => 0
    );
}

sub _build_bootloader {
    my $self = shift;

    my $type = ucfirst lc $self->config->{'bootloader'}{'type'};
    require "Linux/Installer/Bootloader/$type.pm";

    my $config = $self->config->{'bootloader'};
    delete $config->{'type'};
    $config->{'root_directory'} =
      File::Spec->catdir( ( $self->root, $self->device ) );
    $config->{'device'} = $self->device;

    my $bootloader =
      "Linux::Installer::Bootloader::$type"->new( { %{$config} } );

    return $bootloader;
}

sub _build_config {
    my $self = shift;

    my $data   = $self->read( File::Spec->rel2abs( $self->json ) );
    my $config = decode_json($data);

    return $config;
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
    foreach ( @{ $self->config->{'disk'} } ) {
        $number++;
        my $device = sprintf "%s%d", $self->device, $number;

        if ( $_->{'filesystem'} ) {

            my $type = ucfirst lc $_->{'filesystem'}->{'type'};
            require "Linux/Installer/Filesystem/$type.pm";

            my $filesystem = "Linux::Installer::Filesystem::$type"->new(
                {
                    device     => $device,
                    label      => $_->{'filesystem'}->{'label'} || undef,
                    mountpoint => $_->{'filesystem'}->{'mountpoint'} || undef,
                }
            );
            push @filesystems, $filesystem;
        }
    }

    return \@filesystems;
}

sub _build_images {
    my $self = shift;

    my ( @images, $number );
    foreach ( @{ $self->config->{'disk'} } ) {
        $number++;

        if ( $_->{'filesystem'}{'image'} ) {
            my $type = ucfirst lc $_->{'filesystem'}{'image'}{'type'};
            require "Linux/Installer/Image/$type.pm";

            my $target;
            if ( $type eq 'Tar' ) {
                $target = File::Spec->catdir(
                    (
                        $self->root, $self->device,
                        $_->{'filesystem'}{'mountpoint'}
                    )
                );
            }
            elsif ( $type eq 'Squashfs' ) {
                $target = sprintf "%s%d", $self->device, $number;
            }

            my $image = "Linux::Installer::Image::$type"->new(
                {
                    uri    => URI->new($_->{'filesystem'}{'image'}{'uri'}),
                    target => $target,
                }
            );
            push @images, $image;
        }
    }

    return \@images;
}

sub _build_partitions {
    my $self = shift;

    my %units = (
        B  => 1,
        KB => 1024,
        MB => 1024 * 1024,
        GB => 1024 * 1024 * 1024,
        TB => 1024 * 1024 * 1024 * 1024,
        PB => 1024 * 1024 * 1024 * 1024 * 1024,
    );

    no warnings "uninitialized";

    my ( @partitions, $start_sector, $end_sector, $number );
    foreach ( @{ $self->config->{'disk'} } ) {
        $number++;

        my $size = uc $_->{'size'};
        my ( $mult, $unit ) = $size =~ /(\d+)([A-Z]+)/;
        $size = $mult * $units{$unit};

        $start_sector = $end_sector + 2048;
        $end_sector   = $start_sector + $size / $self->disk->sector_size;

        my $device = sprintf "%s%d", $self->device, $number;

        my $partition = Linux::Installer::Partition->new(
            {
                device       => $device,
                type         => $_->{'type'},
                size         => $size,
                label        => $_->{'label'} || undef,
                start_sector => $start_sector,
                end_sector   => $end_sector,
            }
        );
        push @partitions, $partition;
    }

    return \@partitions;
}

sub _mount_filesystem {
    my $self = shift;

    my $root_directory =
      File::Spec->catdir( ( $self->root, $self->device ) );

    foreach ( sort { $a->mountpoint cmp $b->mountpoint }
        @{ $self->filesystems } )
    {
        my $path = File::Spec->catdir( ( $root_directory, $_->mountpoint ) );
        if ( !-d $path ) {
            my $cmd = sprintf "mkdir -p %s", $path;
            $self->exec($cmd);
        }
        my $cmd = sprintf "mount %s %s", $_->device, $path;
        $self->exec($cmd);
    }

    return;
}

sub _umount_filesystem {
    my $self = shift;

    my $root_directory =
      File::Spec->catdir( ( $self->root, $self->device ) );

    foreach ( sort { $b->mountpoint cmp $a->mountpoint }
        @{ $self->filesystems } )
    {
        my $cmd = sprintf "umount %s",
          File::Spec->catdir( ( $root_directory, $_->mountpoint ) );
        $self->exec($cmd);
    }

    return;
}

sub DEMOLISH {
    my $self = shift;

    my $cmd = sprintf "rm -r %s", $self->root;
    $self->exec($cmd);

    return;
}

sub run {
    my $self = shift;

    $self->logger->info("Run installation.");

    $self->disk->prepare();
    $_->create() foreach ( @{ $self->partitions } );
    $_->make()   foreach ( @{ $self->filesystems } );

    $self->_mount_filesystem();
    $self->bootloader->install();
    $_->install() foreach ( @{ $self->images } );
    $self->_umount_filesystem();

    $self->logger->info("Finish installation.");

    return;
}

__PACKAGE__->meta->make_immutable;

1;
