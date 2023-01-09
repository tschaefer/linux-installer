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

sub BUILD {
    my $self = shift;

    return $self->which($self->executable);
}

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

__END__

=pod

=encoding utf8

=head1 NAME

Linux::Installer::Image - Provides an interface for image classes.

=head1 DESCRIPTION

This module provides common methods and attributes for image classes.

=head1 ATTRIBUTES

=head2 target

Target path or device (partition). [required]

=head2 uri

Uniform Resource Identifier L<URI> refer to image. [required]

=head1 METHODS

=head2 install

Fetch and install image. Installation must be implemented by consuming class.
B<curl> is used to fetch the image file.

=head1 AUTHORS

Tobias Schäfer L<github@blackox.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Tobias Schäfer.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
