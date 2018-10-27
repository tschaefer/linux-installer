package Linux::Installer::Image::Binary;

use strict;
use warnings;

use Moose;
with 'Linux::Installer::Image';

sub install {
    my $self = shift;

    my $cmd = sprintf "dd if=%s of=%s bs=2M", $self->path, $self->target;
    $self->exec($cmd);

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf8

=head1 NAME

Linux::Installer::Image::Binary - Provides an image class.

=head1 DESCRIPTION

This module implements the image interface method install.

See L<Linux::Installer::Image>

=head1 METHODS

=head2 install

Installs binary image with B<dd>.

=head1 AUTHORS

Tobias Schäfer L<github@blackox.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Tobias Schäfer.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
