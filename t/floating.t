#!perl -w
# Timezone/DST code for Date::Set

# Copyright (c) 2003 Flavio Soibelmann Glock. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

# test cases

use strict;
# use warnings;
use Test::More qw(no_plan);
use Date::Set::Timezone;
$| = 1;

my $title;
my ($set, $set2, $set3);

# create timezone hashes
my $tz1 = {
    dst => Date::Set::Timezone->new( '20030105Z', '20030115T020000Z' )->complement( '20030115T020000Z' ),
    name => ['STD-1', 'DST-1'],
    offset => [ 2*3600, 3*3600 ],
};

my $tz_utc = {
    dst => Date::Set::Timezone->new(),
    name => ['Z', ''],
    offset => [ 0, 0 ],
};

# mix floating time / tz time
my $set_tz1 = Date::Set::Timezone->new( '20030104Z', '20030107Z' )->tz( $tz1 );
my $set_floating1 = Date::Set::Timezone->new( '20030115Z', '20030117Z' );
is ( ''. $set_tz1->union( $set_floating1 ),
    '[20030104;STD-1..20030107;DST-1],[20030115;DST-1..20030117;STD-1]',
    'tz union floating' );

is ( ''. $set_floating1->union( $set_tz1 ),
    '[20030104..20030107],[20030115..20030117]',
    'floating union tz' );

1;

