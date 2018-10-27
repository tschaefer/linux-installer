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

before 'install' => sub {
    my $self = shift;

    $self->logger->info(sprintf "Install bootloader: %s", $self->device);

    return;
};

1;

__END__

=pod

=encoding utf8

=head1 NAME

Linux::Installer::Bootloader - Provides an interface for bootloader classes.

=head1 DESCRIPTION

This module provides common methods and attributes for bootloader classes.

=head1 ATTRIBUTES

=head2 device

Target device (disk). [required]

=head2 boot_directory

Bootloader images and configuration directory, default C</boot>. [optional]

=head1 METHODS

=head2 install

Install bootloader. Must be implemented by consuming class.

=head1 AUTHORS

Tobias Schäfer L<github@blackox.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Tobias Schäfer.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
