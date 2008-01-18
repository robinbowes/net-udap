use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::UDAP',
    AUTHOR              => 'Robin Bowes <robin@robinbowes.com>',
    VERSION_FROM        => 'lib/Net/UDAP.pm',
    ABSTRACT_FROM       => 'lib/Net/UDAP.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-UDAP-*' },
);
