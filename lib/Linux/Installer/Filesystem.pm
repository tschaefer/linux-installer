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
    is  => 'ro',
    isa => 'Str',
    init_arg => undef,
);

before 'make' => sub {
    my $self = shift;

    $self->logger->info( sprintf "Make filesystem: %s", $self->device );

    return;
};

1;
