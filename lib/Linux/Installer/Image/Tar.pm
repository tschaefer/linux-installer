package Linux::Installer::Image::Tar;

use strict;
use warnings;

use Moose;
with 'Linux::Installer::Image';

has 'options' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub {
        [ "preserve-permissions", "xattrs-include='*.*'", "numeric-owner", ]
    },
);

sub install {
    my $self = shift;

    my $options = join ' ', map { '--' . $_ } @{ $self->options };
    my $cmd = sprintf "tar --extract --file %s --directory %s %s", $self->path,
      $self->target, $options;
    $self->exec($cmd);

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf8

=head1 NAME

Linux::Installer::Image::Tar - Provides an image class.

=head1 DESCRIPTION

This module implements the image interface method install and provides further
attributes.

See L<Linux::Installer::Image>

=head1 ATTRIBUTES

=head2 options

Tar command line options, default C<[ "preserve-permissions",
"xattrs-include='*.*'", "numeric-owner", ]>. [optional]

=head1 METHODS

=head2 install

Installs (compressed) file archive image with B<tar>.

=head1 AUTHORS

Tobias Schäfer L<github@blackox.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Tobias Schäfer.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
