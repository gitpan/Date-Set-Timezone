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

$title="we have a timezone definition";
is( ''. $tz1->{dst},
    '[20030105..20030115T020000)', $title);

my $tz_utc = {
    dst => Date::Set::Timezone->new(),
    name => ['Z', ''],
    offset => [ 0, 0 ],
};

# create a null set, with UTC timezone
my $set_utc = Date::Set::Timezone->new()->tz( $tz_utc );

# creates a new set from a UTC timezone set
my $set2_utc = $set_utc->new( '20030101Z', '20030107Z' );
is ( ''.$set2_utc, "[20030101Z..20030107Z]", "new from UTC" );

# $Set::Infinite::TRACE = 1;

# changes timezone
$set2_utc = $set2_utc->tz_change( $tz1 );
is ( ''.$set2_utc, "[20030101T020000;STD-1..20030107T030000;DST-1]", "UTC to timezone" );

# make it floating time
# warn " -------------- START timezone to floating time $set2_utc ----------";
$set2_utc = $set2_utc->tz_change( undef );
is ( ''.$set2_utc, "[20030101T020000..20030107T030000]", "timezone to floating time" );

# change it back to timezone
$set2_utc = $set2_utc->tz_change( $tz1 );
is ( ''.$set2_utc, "[20030101T020000;STD-1..20030107T030000;DST-1]", "floating time to timezone" );


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

my @test_floating = ( 
    # before any timezone operation
    '[20030101T120000..20030107T120000]',  # before, inside
    '[20030104T230000..20030115T010000]',  # 1h before DST
    '[20030104T233000..20030115T013000]',  # 30min before DST
    '[20030105..20030115T020000]',         # touch begin, touch end
    '[20030105T003000..20030115T023000]',  # 30min after DST
    '[20030105T010000..20030115T030000]',  # 1h after DST
    '[20030107..20030117]',                # inside, after
);

# convert back to floating time - some times don't exist!
my @test_floating_again = (
    # before any timezone operation
    '[20030101T120000..20030107T120000]',  # before, inside
    '[20030104T230000..20030115T010000]',  # 1h before DST
    '[20030104T233000..20030115T013000]',  # 30min before DST
    '[20030104T230000..20030115T020000]',  # (error) touch begin, touch end
    '[20030104T233000..20030115T023000]',  # (error) 30min after DST
    '[20030105T010000..20030115T030000]',  # 1h after DST
    '[20030107..20030117]',                # inside, after
);

# these are the new UTC times, after we translate above from 'UTC' to 'local time'

my @test_translated = ( 
    # -2h STD / -3h DST from [05T00..15T02)
    '[20030101T100000..20030107T090000]',  # -2h .. -3h
    '[20030104T210000..20030114T220000]',  # -2h .. -2h or [-3h] (result is not well defined)
    '[20030104T213000..20030114T223000]',  # -2h .. -2h or [-3h] (result is not well defined)
    '[20030104T210000..20030115]',         # (error) .. -2h  
    '[20030104T213000..20030115T003000]',  # (error) .. -2h 
    '[20030104T220000..20030115T010000]',  # -3h .. -2h
    '[20030106T210000..20030116T220000]',  # -3h .. -2h
);

my @test_tz = ( 
    '[20030101T120000;STD-1..20030107T120000;DST-1]',
    '[20030104T230000;STD-1..20030115T010000;DST-1]',
    '[20030104T233000;STD-1..20030115T013000;DST-1]',
    '[20030104T230000;STD-1..20030115T020000;STD-1]',
    '[20030104T233000;STD-1..20030115T023000;STD-1]',
    '[20030105T010000;DST-1..20030115T030000;STD-1]',
    '[20030107;DST-1..20030117;STD-1]',
);

# $Set::Infinite::TRACE = 1;

for my $i (0 .. $#test) {
    is( ''. $test[$i], $test_floating[$i], 
        "$i - 0 - floating time" );
    $set = $test[$i]->tz( $tz1 );
    is( ''. $set->as_string, $test_tz[$i], 
        "$i - 1 - as TZ string" );
    is( ''. $set->tz_change( undef ), $test_floating_again[$i], 
        "$i - 2 - move to TZ, print as floating time ".$test_floating[$i] );
    is( ''. $set->as_string, $test_tz[$i], 
        "$i - 3 - as TZ string - tz_change doesn't mess with set" );
    is( ''. $set, $test_tz[$i], 
        "$i - 4 - print as TZ" );

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

# quantize in tz context
$set2 = $set->offset( unit=>'hours', value=>[0,2] );  # duration = 2 "localtime" hours
is ( ''.$set2, '[20030104T233000;STD-1..20030105T013000;DST-1]', "PT2H - tz" );

# quantize in UTC context
$set2 = $set->tz_change( $tz_utc )->offset( unit=>'hours', value=>[0,2] )->tz_change( $tz1 );  # duration = 2 "UTC" hours
is ( ''.$set2, '[20030104T233000;STD-1..20030105T023000;DST-1]', "PT2H - UTC" );

$set = Date::Set::Timezone->new ( '20030115T003000Z' );   # just before DST ends
$set = $set->tz( $tz1 );
# print "event is $set \n";
$set = $set->offset( unit=>'hours', value=>[0,2] );  # duration = 2 "localtime" hours
is ( ''.$set, '[20030115T003000;DST-1..20030115T023000;STD-1]', "PT2H again" );

# quantize thinks the hour boundaries are ...
$set2 = $set->offset( unit=>'hours', value=>[0,1] ); 
is ( ''.$set2,
    '[20030115T003000;DST-1..20030115T033000;STD-1]',
    "end-offset 1 hour" );
$set2 = $set->offset( unit=>'hours', value=>[0,1]  )->quantize(unit=>'hours' );
is ( ''.$set2,
'[20030115;DST-1..20030115T010000;DST-1),'.
'[20030115T010000;DST-1..20030115T010000;STD-1),'.
# missing hour due to 'local time' context
'[20030115T020000;STD-1..20030115T030000;STD-1),'.
'[20030115T030000;STD-1..20030115T040000;STD-1)',
    "as hours" );

$set2 = $set->tz_change( $tz_utc )->offset( unit=>'hours', value=>[0,1]  )->quantize(unit=>'hours' )->tz_change( $tz1 );
is ( ''.$set2,
'[20030115;DST-1..20030115T010000;DST-1),'.
'[20030115T010000;DST-1..20030115T010000;STD-1),'.
'[20030115T010000;STD-1..20030115T020000;STD-1),'.  # hour repeats
'[20030115T020000;STD-1..20030115T030000;STD-1),'.
'[20030115T030000;STD-1..20030115T040000;STD-1)', 
    "as hours - UTC context" );

# applying days duration 
$set = Date::Set::Timezone->new ( '20030115T003000Z' );   # just before DST end
$set = $set->tz( $tz1 );
# warn "event is $set \n";
# warn "event is ". $set->tz_change( undef ) . " floating";
# warn "event is ". $set->tz_change( $tz_utc ) . " UTC";
$set = $set->offset( unit=>'days', value=>[0,2] );  # duration = 2 hours
is ( ''.$set,
    '[20030115T003000;DST-1..20030117T003000;STD-1]', 
    "P2D");

# quantize thinks the day boundaries are ...
$set = $set->offset( unit=>'days', value=>[-1,0] )->quantize(unit=>'days'); 
is ( ''.$set,
    '[20030114;DST-1..20030115;DST-1),'.
    '[20030115;DST-1..20030116;STD-1),'.
    '[20030116;STD-1..20030117;STD-1),'.
    '[20030117;STD-1..20030118;STD-1)',
    "days");

# a simple RRULE
$set = $set->recur_by_rule( RRULE => 'FREQ=DAILY;BYHOUR=10' ); 
is ( ''.$set,
    '20030114T100000;DST-1,'.
    '20030115T100000;STD-1,'.  # <--- 09 !
    '20030116T100000;STD-1,'.
    '20030117T100000;STD-1',
    "recurrence");

# RRULE with hours nearby a DST change
$set = Date::Set::Timezone->new ( '20030115Z' );   # just before DST end
$set = $set->tz( $tz1 )->duration( unit=>'hours', duration=>4);
# print "event is $set \n";
$set2 = $set->recur_by_rule( RRULE => 'FREQ=HOURLY' ); 
is ( ''.$set2,
    '20030115;DST-1,'.
    '20030115T010000;DST-1,'.
    # '20030115T020000;DST-1,'.  -- ignored because we are using 'local time'
    '20030115T020000;STD-1,'.   # clock 'goes back'
    '20030115T030000;STD-1,'.
    '20030115T040000;STD-1',
    "hourly recurrence near DST end - $set");

# RRULE with hours nearby a DST start
$set = Date::Set::Timezone->new ( '20030104T230000Z' );   # just before DST begins
$set = $set->tz( $tz1 )->duration( unit=>'hours', duration=>4);
# print "event is $set \n";
$set2 = $set->recur_by_rule( RRULE => 'FREQ=HOURLY' ); 
is ( ''.$set2,
    '20030104T230000;STD-1,'.         
    '20030105T010000;DST-1,'.     # clock 'jumps'
    '20030105T020000;DST-1,'.
    '20030105T030000;DST-1',
    "hourly recurrence near DST begin - $set");




# $Set::Infinite::TRACE = 1;
# $Set::Infinite::PRETTY_PRINT = 1;

# creates a timezone specified by unbounded recurrences
# DTSTART mask is yyyy/mm/05 02:00:00 local time
my $dst_dtstart = Date::Set::Timezone->event( at => '20010105T020000Z' );
# warn "tz_recurr dtstart $dst_dtstart";
# $dst_dtstart = $dst_dtstart->fixtype;
# warn "tz_recurr dtstart $dst_dtstart";

my $dst_start = Date::Set::Timezone
    ->dtstart( start => $dst_dtstart )
    ->event( rule=>'FREQ=YEARLY;BYMONTH=3' );
my $dst_end   = Date::Set::Timezone
    ->dtstart( start => $dst_dtstart )
    ->event( rule=>'FREQ=YEARLY;BYMONTH=6' );
my $tz_recurr = {
    dst => $dst_start->until( $dst_end ) ,
    name => ['', 'dst'] ,
    offset => [ 2*3600, 1*3600 ] ,
};

# $dst_dtstart = $dst_dtstart->fixtype;
# warn "tz_recurr dtstart $dst_dtstart";
# warn "tz_recurr name @{$tz_recurr->{name}} ; dst ".$tz_recurr->{dst};
# $Set::Infinite::TRACE = 1;
# $Set::Infinite::PRETTY_PRINT = 1;
# warn "tz_recurr start ". $dst_start->intersection( '20030101Z', '20040101Z' );
# warn "tz_recurr end   ". $dst_end->intersection( '20030101Z', '20040101Z' );
# $Set::Infinite::TRACE = 1;
# $Set::Infinite::PRETTY_PRINT = 1;
# warn "tz_recurr bounded ". $tz_recurr->{dst}->intersection( '20030101Z', '20040101Z' );

is ( ''.$tz_recurr->{dst}->intersection( '20030101Z', '20040101Z' ),
    '[20030305T020000..20030605T020000)',
    # '[20030301Z..20030601Z)',
    'a dst specification made of two recurrences' );

$set = $set_utc->new( 
    '20030105Z', '20030107Z',    # before DST
    '20030205Z', '20030315Z',    # DST begins
    '20030405Z', '20030410Z',    # inside DST
    '20030505Z', '20030701Z',    # DST ends
);

is ( ''.$set,
    '[20030105Z..20030107Z],'.   
    '[20030205Z..20030315Z],'.   
    '[20030405Z..20030410Z],'.   
    '[20030505Z..20030701Z]',   
    'a set inherits it\'s creators timezone' );

# $Set::Infinite::TRACE = 1;
# $Set::Infinite::PRETTY_PRINT = 1;

is ( ''.$set->tz_change( $tz_recurr ),
    '[20030105T020000..20030107T020000],'.
    '[20030205T020000..20030315T010000;dst],'.
    '[20030405T010000;dst..20030410T010000;dst],'.
    '[20030505T010000;dst..20030701T020000]',
    'timezone specified by unbounded recurrences' );

# mix floating time / tz time
my $set_tz1 = Date::Set::Timezone->new( '20030105Z', '20030107Z' )->tz( $tz_recurr );
my $set_floating1 = Date::Set::Timezone->new( '20030115Z', '20030117Z' );
is ( ''. $set_tz1->union( $set_floating1 ),
    '[20030105..20030107],[20030115..20030117]',
    'tz union floating' );

is ( ''. $set_floating1->union( $set_tz1 ),
    '[20030105..20030107],[20030115..20030117]',
    'floating union tz' );

1;

