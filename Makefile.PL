use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    'ABSTRACT'      => 'Simple installer for embedded Linux systems.',
    'AUTHOR'        => 'Tobias Schaefer <github@blackox.org>',
    'DISTNAME'      => 'Linux-Installer',
    'EXE_FILES'     => [ 'bin/linux-installer' ],
    'META_MERGE'    => {
        resources   => {
            'license'    => 'http://dev.perl.org/licenses',
            'homepage'   => 'https://github.com/tschaefer/linux-installer',
            'repository' => 'https://github.com/tschaefer/linux-installer.git',
        }
    },
    'NAME'          => 'Linux::Installer',
    'PREREQ_PM'     => {
        'IPC::Run'              => '0.99',
        'Log::Log4perl'         => '1.49',
        'Moose'                 => '2.2010',
        'Readonly'              => '2.05',
        'Text::ParseWords'      => '3.30',
        'Try::Tiny'             => '0.30',
        'URI'                   => '1.73',
    },
    'VERSION_FROM'  => 'lib/Linux/Installer.pm',
    'clean'         => { FILES => 'Linux-Installer-*' },
    'dist'          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE' => 'perl', ) : ()),
);
