package Linux::Installer::App;

use strict;
use warnings;

use MooseX::App::Simple;
use Log::Log4perl;
use Try::Tiny;

use File::Spec;

use Linux::Installer;

parameter 'device' => (
    is            => 'ro',
    isa           => 'Str',
    required      => 1,
    documentation => q[Installer target device.],
);

option 'config' => (
    is            => 'ro',
    isa           => 'Str',
    required      => 1,
    cmd_flag      => 'config-file',
    cmd_aliases   => ['f',],
    documentation => q[Installer configuration file.],
);

option 'log' => (
    is            => 'ro',
    isa           => 'Str',
    required      => 1,
    cmd_flag      => 'log-config-file',
    cmd_aliases   => ['l',],
    documentation => q[Log4perl configuration file.],
);

sub run {
    my ($self) = @_;

    Log::Log4perl->init( $self->log );
    my $logger = Log::Log4perl->get_logger();

    my $installer = Linux::Installer->new(
        {
            json   => $self->config,
            device => $self->device
        }
    );

    my $rc = try {
        $installer->run();
        1;
    }
    catch {
        $logger->error( ( split / at/ )[0] );
    };

    return $rc ? 0 : 1;
}

__PACKAGE__->meta->make_immutable;

1;
