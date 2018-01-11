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

    $$output = $out if ($output);
    $$error  = $err if ($error);

    $self->logger->trace($out) if ($out);

    $self->logger->error_die($err) if ( $rc && $err && !$no_exception );

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

1;
