package Linux::Installer::Utils::Tools;

use strict;
use warnings;

use Moose::Role;

use IPC::Run;
use Log::Log4perl::Logger;
use Log::Log4perl;
use Text::ParseWords;
use Try::Tiny;

has 'logger' => (
    is       => 'ro',
    isa      => 'Log::Log4perl::Logger',
    lazy     => 1,
    default  => sub { return Log::Log4perl->get_logger( ref $_[0] ) },
    init_arg => undef,
);

sub exec {
    my ( $self, $cmd, $output, $error, $no_exception ) = @_;

    my @exec = shellwords($cmd);

    $self->logger->debug( join ' ', @exec );

    my ( $rc, $out, $err );
    try {
        IPC::Run::run( \@exec, '>', \$out, '2>', \$err );
        $rc = $? >> 8;
    }
    catch {
        $self->logger->error_die( ( split / at/ )[0] );
    };

    if ($rc) {
        $err = $err // "failed.";

        $self->logger->error_die($err) if (!$no_exception);
        $self->logger->error($err);
    }

    $self->logger->trace($out) if ($out);

    $$output = $out if ($output);
    $$error  = $err if ($error);

    return $rc ? 1 : 0;
}

sub read {
    my ( $self, $file ) = @_;

    my $fh;
    my $string = do {
        local $/ = undef;
        open $fh, '<', $file or $self->logger->error_die("$!: $file");
        <$fh>;

    };
    close $fh or $self->logger->error_die("$!: $file");

    $string =~ s/^\s+|\s+$//g;

    return $string;
}

sub write {
    my ( $self, $file, $string ) = @_;

    open my $fh, '>', $file or $self->logger->error_die("$!: $file");
    print $fh $string;
    close $fh or $self->logger->error_die("$!: $file");

    return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Linux::Installer::Utils::Tools - Provides basic attributes and IO methods.

=head1 DESCRIPTION

The package provides basic attributes and IO tools and is consumed by the
several Linux::Installer classes and roles.

=head1 ATTRIBUTES

=head2 logger

Log::Log4perl::Logger object. [readonly]

=head1 METHODS

=head2 exec

Execute a command and optional receive output and / or error message.
Dies if the command can not be executed. Also dies if the command
return value is unequal 0. This can be avoided by setting no exception.

    $self->exec("ls -l", \$out, \$err, 1);

=head2 read

Slurps a file, trims whitespace and returns string.
Dies on open and close error.

    my $mounts = $self->read("/proc/mounts");

=head2 write

Writes string into a file. Dies on open and close error.

    $self->write("/tmp/foobar", "Hello, World.");

=head1 AUTHORS

Tobias Schäfer L<github@blackox.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Tobias Schäfer.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
