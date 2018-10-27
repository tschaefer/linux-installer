package Linux::Installer::Filesystem::F2fs;

use strict;
use warnings;

use Moose;
with 'Linux::Installer::Filesystem';

sub make {
    my $self = shift;

    my $cmd = sprintf "mkfs.f2fs %s %s",
      $self->label ? "-l " . $self->label : '',
      $self->device;
    $self->exec( $cmd, undef, undef, 1 );

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf8

=head1 NAME

Linux::Installer::Filesystem::F2fs - Provides a filesystem class.

=head1 SYNOPSIS

    use Linux::Installer::Filesystem::F2fs;
    use Log::Log4perl;

    Log::Log4perl->init('conf/installer.log.conf');

    my $f2fs = Linux::Installer::Filesystem::F2fs->new(
        {
            device => '/dev/sda2',
        }
    );
    $f2fs->make();


=head1 DESCRIPTION

This module implements the filesystem interface method make.

See L<Linux::Installer::Filesystem>

=head1 METHODS

=head2 make

Creates f2fs filesystem.

=head1 AUTHORS

Tobias Schäfer L<github@blackox.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Tobias Schäfer.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
