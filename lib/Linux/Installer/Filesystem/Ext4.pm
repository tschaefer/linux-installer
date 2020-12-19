package Linux::Installer::Filesystem::Ext4;

use strict;
use warnings;

use Moose;
with 'Linux::Installer::Filesystem';

sub make {
    my $self = shift;

    my $cmd = sprintf "mkfs.ext4 %s %s %s",
      $self->label ? "-L " . $self->label : '',
      $self->stringify_options,
      $self->device;
    $self->exec($cmd);

    $cmd = sprintf "tune2fs -c -1 -i 0 %s", $self->device;
    $self->exec($cmd);

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf8

=head1 NAME

Linux::Installer::Filesystem::Ext4 - Provides a filesystem class.

=head1 SYNOPSIS

    use Linux::Installer::Filesystem::Ext4;
    use Log::Log4perl;

    Log::Log4perl->init('conf/installer.log.conf');

    my $ext4 = Linux::Installer::Filesystem::Ext4->new(
        {
            device => '/dev/sda4',
        }
    );
    $ext4->make();


=head1 DESCRIPTION

This module implements the filesystem interface method make.

See L<Linux::Installer::Filesystem>

=head1 METHODS

=head2 make

Creates ext4 filesystem and disables periodic checks.

=head1 AUTHORS

Tobias Schäfer L<github@blackox.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Tobias Schäfer.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
