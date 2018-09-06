package Linux::Installer::Image;

use strict;
use warnings;

use Moose::Role;

use Linux::Installer::Utils::Types;
with 'Linux::Installer::Utils::Tools';

use File::Temp;
use URI;

requires 'install';

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
);

has 'path' => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    builder  => '_build_path',
    init_arg => undef,
);

has 'target' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'uri' => (
    is       => 'ro',
    isa      => 'URI',
    required => 1,
);

before 'install' => sub {
    my $self = shift;

    $self->logger->info( sprintf "Install image: %s", $self->uri->canonical );

    my $cmd = sprintf "curl --insecure --location --output %s %s", $self->path,
      $self->uri->canonical;
    $self->exec($cmd);

    return;
};

after 'install' => sub {
    my $self = shift;

    my $cmd = sprintf "sync -f %s", $self->target;
    $self->exec($cmd);

    return;
};

sub DEMOLISH {
    my $self = shift;

    my $cmd = sprintf "rm -f %s", $self->path;
    $self->exec($cmd);

    return;
}

sub _build_path {
    my $self = shift;

    my (undef, $path) = File::Temp::tempfile(
        OPEN     => 0,
        TMPDIR   => 1,
        TEMPLATE => 'installerXXXXX',
        SUFFIX   => '.dat',
        UNLINK   => 0,
    );

    return $path;
}

1;
