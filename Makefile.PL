use ExtUtils::MakeMaker;

WriteMakefile(
    'ABSTRACT'       => 'Date sets math with timezones and DST',
    'AUTHOR'         => 'Flavio Soibelmann Glock - fglock@pucrs.br',
    'NAME'           => 'Date::Set::Timezone',
    'VERSION_FROM'   => 'lib/Date/Set/Timezone.pm', 
    'EXCLUDE_EXT'    => [ qw(Makefile gz LOG x~~) ],
    'PREREQ_PM'      => {    'Set::Infinite' => '0.43',
                             'Date::Set'     => '1.26',
                             'Date::ICal'    => '1.70',
                             'Test::Harness' => '1.23',
                             'Test::More'    => '0.31',
                        },
    'dist'           => { 'COMPRESS' => 'gzip' },
);

