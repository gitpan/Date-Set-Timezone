# Timezone/DST code for Date::Set

# Copyright (c) 2003 Flavio Soibelmann Glock. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

# test cases

use strict;
use warnings;
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

# my $tz2 = {
#    dst => Date::Set::Timezone->new( '20030103Z', '20030112Z' )->complement( '20030112Z' ),
#    name => ['STD-2', 'DST-2'],
#    offset => [ 3*3600, 4*3600 ],
# };

$title="we have a timezone definition";
is( ''. $tz1->{dst}, 
    '[20030105Z..20030115T020000Z)', $title);

my @test = (
    # 'touch begin' of DST and '30min after DST' are not well-defined because that times 'don't exist'
    Date::Set::Timezone->new ( '20030101T120000Z', '20030107T120000Z' ),  # before, inside
    Date::Set::Timezone->new ( '20030104T230000Z', '20030115T010000Z' ),  # 1h before DST
    Date::Set::Timezone->new ( '20030104T233000Z', '20030115T013000Z' ),  # 30min before DST
    Date::Set::Timezone->new ( '20030105Z',        '20030115T020000Z' ),  # touch begin, touch end
    Date::Set::Timezone->new ( '20030105T003000Z', '20030115T023000Z' ),  # 30min after DST
    Date::Set::Timezone->new ( '20030105T010000Z', '20030115T030000Z' ),  # 1h after DST
    Date::Set::Timezone->new ( '20030107Z',        '20030117Z' ),         # inside, after
);

my @test_utc = ( 
    # before any timezone operation
    '[20030101T120000Z..20030107T120000Z]',  # before, inside
    '[20030104T230000Z..20030115T010000Z]',  # 1h before DST
    '[20030104T233000Z..20030115T013000Z]',  # 30min before DST
    '[20030105Z..20030115T020000Z]',         # touch begin, touch end
    '[20030105T003000Z..20030115T023000Z]',  # 30min after DST
    '[20030105T010000Z..20030115T030000Z]',  # 1h after DST
    '[20030107Z..20030117Z]',                # inside, after
);

# these are the new UTC times, after we translate above from 'UTC' to 'local time'

my @test_translated = ( 
    # -2h STD / -3h DST from [05T00..15T02)
    '[20030101T100000Z..20030107T090000Z]',  # -2h .. -3h
    '[20030104T210000Z..20030114T220000Z]',  # -2h .. -2h or [-3h] (result is not well defined)
    '[20030104T213000Z..20030114T223000Z]',  # -2h .. -2h or [-3h] (result is not well defined)
    '[20030104T210000Z..20030115Z]',         # (error) .. -2h  
    '[20030104T213000Z..20030115T003000Z]',  # (error) .. -2h 
    '[20030104T220000Z..20030115T010000Z]',  # -3h .. -2h
    '[20030106T210000Z..20030116T220000Z]',  # -3h .. -2h
);

my @test_tz = ( 
    '[20030101T120000 STD-1..20030107T120000 DST-1]',
    '[20030104T230000 STD-1..20030115T010000 DST-1]',
    '[20030104T233000 STD-1..20030115T013000 DST-1]',
    '[20030104T230000 STD-1..20030115T020000 STD-1]',
    '[20030104T233000 STD-1..20030115T023000 STD-1]',
    '[20030105T010000 DST-1..20030115T030000 STD-1]',
    '[20030107 DST-1..20030117 STD-1]',
);

for my $i (0 .. $#test) {
    is( ''. $test[$i], $test_utc[$i], "$i - UTC time" );
    $set = $test[$i]->tz( $tz1 );
    is( ''. $set->as_string( undef ), $test_translated[$i], "$i - move to TZ, print as UTC ".$test_utc[$i] );
    is( ''. $set, $test_tz[$i], "$i - print as TZ" );
    # my $utc = $test->tz_change( undef );
    # print "  as UTC: $utc \n";
    # my $tz = $utc->tz_change($tz1);
    # print "  back to TZ: $tz \n";
    # my $tz2 = $utc->tz_change($tz2);
    # print "  to TZ2: $tz2 \n";
}

# a test contributed by Martijn van Beers:
# DTSTART;TZID=Europe/Amsterdam:20011028T003000
# DURATION:PT2H
# normally, the event would end 20011028T023000
# but, when the clock goes back an hour at 2AM, 
# it would end on 20011028T013000

# applying hours duration 

$set = Date::Set::Timezone->new ( '20030104T233000Z' );   # just before DST begins
# print "event is $set \n";
$set = $set->tz( $tz1 );
# print "event is $set \n";
$set = $set->offset( unit=>'hours', value=>[0,2], utc=>1 );  # duration = 2 UTC hours
is ( ''.$set, '[20030104T233000 STD-1..20030105T023000 DST-1]', "PT2H" );

$set = Date::Set::Timezone->new ( '20030115T003000Z' );   # just before DST ends
$set = $set->tz( $tz1 );
# print "event is $set \n";
$set = $set->offset( unit=>'hours', value=>[0,2], utc=>1 );  # duration = 2 UTC hours
is ( ''.$set, '[20030115T003000 DST-1..20030115T013000 STD-1]', "PT2H" );

# quantize thinks the hour boundaries are ...
$set = $set->offset( unit=>'hours', value=>[0,1], utc=>1 )->quantize(unit=>'hours', utc=>1); 
is ( ''.$set,
    '[20030115 DST-1..20030115T010000 DST-1),'.
    '[20030115T010000 DST-1..20030115T010000 STD-1),'.
    '[20030115T010000 STD-1..20030115T020000 STD-1),'.  # clock 'repeats'
    '[20030115T020000 STD-1..20030115T030000 STD-1)',
    "as hours" );

# applying days duration 
$set = Date::Set::Timezone->new ( '20030115T003000Z' );   # just before DST end
$set = $set->tz( $tz1 );
# print "event is $set \n";
$set = $set->offset( unit=>'days', value=>[0,2] );  # duration = 2 hours
is ( ''.$set,
    '[20030115T003000 DST-1..20030117T003000 STD-1]', 
    "P2D");

# quantize thinks the day boundaries are ...
$set = $set->offset( unit=>'days', value=>[-1,0] )->quantize(unit=>'days'); 
is ( ''.$set,
    '[20030114 DST-1..20030115 DST-1),'.
    '[20030115 DST-1..20030116 STD-1),'.
    '[20030116 STD-1..20030117 STD-1),'.
    '[20030117 STD-1..20030118 STD-1)',
    "days");

# a simple RRULE
$set = $set->recur_by_rule( RRULE => 'FREQ=DAILY;BYHOUR=10' ); 
is ( ''.$set,
    '20030114T100000 DST-1,'.
    '20030115T100000 STD-1,'.  # <--- 09 !
    '20030116T100000 STD-1,'.
    '20030117T100000 STD-1',
    "recurrence");

# RRULE with hours nearby a DST change
$set = Date::Set::Timezone->new ( '20030115Z' );   # just before DST end
$set = $set->tz( $tz1 )->duration( unit=>'hours', duration=>4);
# print "event is $set \n";
$set2 = $set->recur_by_rule( RRULE => 'FREQ=HOURLY' ); 
is ( ''.$set2,
    '20030115 DST-1,'.
    '20030115T010000 DST-1,'.
    # '20030115T020000 DST-1,'.  -- ignored because we are using 'local time'
    '20030115T020000 STD-1,'.   # clock 'goes back'
    '20030115T030000 STD-1,'.
    '20030115T040000 STD-1',
    "hourly recurrence near DST end - $set");

# RRULE with hours nearby a DST start
$set = Date::Set::Timezone->new ( '20030104T230000Z' );   # just before DST begins
$set = $set->tz( $tz1 )->duration( unit=>'hours', duration=>4);
# print "event is $set \n";
$set2 = $set->recur_by_rule( RRULE => 'FREQ=HOURLY' ); 
is ( ''.$set2,
    '20030104T230000 STD-1,'.         
    '20030105T010000 DST-1,'.     # clock 'jumps'
    '20030105T020000 DST-1,'.
    '20030105T030000 DST-1',
    "hourly recurrence near DST begin - $set");


1;

