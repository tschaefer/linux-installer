package Linux::Installer::Bootloader;

use strict;
use warnings;

use Moose::Role;
with 'Linux::Installer::Utils::Tools';

requires 'install';

has 'boot_directory' => (
    is      => 'ro',
    isa     => 'Str',
    default => '/boot',
);

has 'device' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'root_directory' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'name' => (
    is  => 'ro',
    isa => 'Str',
);

before 'install' => sub {
    my $self = shift;

    $self->logger->info(sprintf "Install bootloader: %s.", $self->name);

    return;
};

1;
