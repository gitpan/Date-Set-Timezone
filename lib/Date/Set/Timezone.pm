# Timezone/DST code for Date::Set

# Copyright (c) 2003 Flavio Soibelmann Glock. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Date::Set::Timezone;

use strict;
use warnings;
use Carp;
use Date::Set;
use vars qw( @ISA $VERSION );
@ISA = qw( Date::Set Set::Infinite );

our $VERSION = (qw'$Revision: 0.03 $')[1]; 

# avoid warnings about 'used only once'
$Date::Set::PRETTY_PRINT = $Date::Set::PRETTY_PRINT;
$Date::Set::too_complex  = $Date::Set::too_complex;

# ------------ POD --------------

=head1 NAME

Date::Set::Timezones - Date set math with timezones and DST

=head1 SYNOPSIS

    use Date::Set::Timezone;

    $a = Date::Set::Timezone->event( at => '20020311Z' );      # 20020311

    # TODO! (see timezone.t for some examples)

=head1 DESCRIPTION

Date::Set::Timezone is a module for date/time sets. It allows you to generate
groups of dates, like "every wednesday", and then find all the dates
matching that pattern. It also allows operations with timezones and 
daylight saving times.

This module is part of the Reefknot project http://reefknot.sf.net

It requires Date::ICal, Set::Infinite, and Date::Set.

It doesn't include timezones definitions.

=cut

# Timezone parameters
#
#    dst => Date::Set::Timezone->new( '20030105Z', '20030115T020000Z' )->complement( '20030115T020000Z' ),
#
# 'dst' is a set that includes all the DST times.
#
# This set is built of local times (it does not have a timezone)
#
#    name => ['STD-1', 'DST-1'],
#
# 'name' is an array containing the standard timezone name and the DST timezone name.
#
#    offset => [ 0, 3600 ],
#
# 'offset' is an array containing the standard timezone offset and the DST timezone offset.
#
# NOTE: any existing Date::Set data is interpreted as UTC time.
# NOTE: extracted Date::ICal (list+min/max) will always come in UTC time.
# NOTE: parameters to new() must be UTC time (with 'Z' at the end).
# NOTE: RRULE:UNTIL= only works for UTC time, because of the way new() works.
#     This is what RFC2445 expects, anyway!

# ------------ TIMEZONE METHODS --------------

=head1 TIMEZONE METHODS

=head2 tz

Translates a set to another timezone.
It changes the timezone only. Time values are not changed.

    tz( { dst => $new_timezone_set , 
          name => ['STD-1', 'DST-1'], 
          offset => [ 3600, 2*3600 ] } )

This is a function. It doesn't change it's object. It returns a new object.

tz() without a parameter allows to work in 'local time' or 'UTC' mode 
(remove timezone info).

There might be conversion errors nearby DST endings because of 'repeated times' when time 'goes back'.

=cut

sub tz {
    my ($self, $tz) = @_;
    # print " [ tz (",$self->{cant_cleanup},") $self ]\n";
    my $res = $self->_tz_change( $tz );
    $res->{cant_cleanup} = $self->{cant_cleanup};
    # print " [ tz gives (",$res->{cant_cleanup},") $res ]\n";
    return $res;
}

=head2 tz_change

Moves a set to another timezone.
It changes both the timezone and time values, and adjusts DST.

    tz_change( { dst => $new_timezone_set , 
          name => ['STD-1', 'DST-1'], 
          offset => [ 3600, 2*3600 ] } )

This is a function. It doesn't change it's object. It returns a new object.

tz_change() without a parameter moves the set to 'UTC'.

=cut

# Time values are changed and DST corrected.
sub tz_change {
    my ($self, $tz) = @_;
    my $res = $self->copy;
    # $res->{cant_cleanup} = $self->{cant_cleanup};
    $res->{tz} = $tz;
    return $res;
}

# changes a set timezone to another timezone
# translating the times:
#    20021010 DST => 20021010 EST
#    20021010Z => 20021010 EST
sub _tz_change {
    my ($self, $new_tz) = @_;
    # return $self unless exists $self->{tz} && defined $self->{tz};
    my $tz = $self->{tz};

    # we need to move DST definition to UTC
    # _dst_to_utc($new_tz);

    my $result = $self->new();
    my @list = $self->list;
    for my $subset ( @list ) {
            # to UTC
            if ($tz) {
                my @min = $subset->min_a;
                my @max = $subset->max_a;
                # TODO: we don't actually have 'integer' sets
                $min[0]++ if $min[1];  # open-begin integer set
                $max[0]-- if $max[1];  # open-end integer set
                my $min = __PACKAGE__->new($min[0]);
                my $max = __PACKAGE__->new($max[0]);
                my $ofs_min = $tz->{dst}->contains( $min ) ? 
                    $tz->{offset}[1] : $tz->{offset}[0];
                my $ofs_max = $tz->{dst}->contains( $max ) ? 
                    $tz->{offset}[1] : $tz->{offset}[0];
                $subset = $subset->offset(unit=>'seconds', value=>[+$ofs_min, +$ofs_max] );
                # print " _tz_change UTC=$subset [-$ofs_min, -$ofs_max] \n";
            }
            # to TZ
            if ($new_tz) {
                my @min = $subset->min_a;
                my @max = $subset->max_a;
                # TODO: we don't actually have 'integer' sets
                $min[0]++ if $min[1];  # open-begin integer set
                $max[0]-- if $max[1];  # open-end integer set
                my $min = __PACKAGE__->new($min[0]);  # + $new_tz->{offset}[1]);
                my $max = __PACKAGE__->new($max[0]);  # + $new_tz->{offset}[1]);

                # print "min is ", $new_tz->{dst}->contains( $min ) ? 'contained' : 'not contained';
                # print "; max is ", $new_tz->{dst}->contains( $max ) ? 'contained' : 'not contained';
                # print "\n";

                my $ofs_min = $new_tz->{dst}->contains( $min ) ? 
                    $new_tz->{offset}[1] : $new_tz->{offset}[0];
                my $ofs_max = $new_tz->{dst}->contains( $max ) ? 
                    $new_tz->{offset}[1] : $new_tz->{offset}[0];
                # print " _tz_change val:$min;$max dst:",$new_tz->{dst}," offset:-$ofs_min,-$ofs_max\n";
                # print " _tz_change subset was=$subset\n";
                $subset = $subset->offset(unit=>'seconds', value=>[-$ofs_min, -$ofs_max] );
                # print " _tz_change subset is =$subset\n";
            }
            push @{$result->{list}}, @{$subset->{list}}; 
    }
    $result->{tz} = $new_tz;  # if defined $new_tz;
    return $result;
}

sub _dst_to_utc {
    my $tz = shift;
    return unless $tz;
    # moves DST definition to UTC
    unless ( exists $tz->{dst_utc} ) {
        # print "tz is undef\n" unless defined $tz;
        # print "tz is ",join(" ", %$tz)," =", ref($tz),"\n";
        $tz->{dst_utc} = $tz->{dst}->offset( unit=>'seconds', value=> [-$tz->{offset}[0], -$tz->{offset}[1]] );
        # print "created tz->dst_utc ", $tz->{dst_utc},"\n";
    }
}

# ------------ Set::Infinite "INHERITED" METHODS --------------

# we call this section DATE::SET METHODS because we actually
# inherit Date::Set first.

=head1 DATE::SET METHODS

=head2 new

new() behaves differently from Date::Set::new() in that:

    $new_set = $set->new();

keeps timezone info.

=cut

# new() parameters always need a 'Z' at the end!
# use tz() to redefine the timezone
sub new {
    my $class = shift;
    my $self = Date::Set->new(@_);
    bless $self, __PACKAGE__;
    # new() gets parent's "tz"
    $self->{tz} = ref($class) ? $class->{tz} : undef;
    return $self;
}

=head2 as_string

as_string() behaves differently from Date::Set::as_string() in that
it prints timezone/DST info.

If supplied with a timezone argument, as_string() stringifies
the times under that timezone. 

as_string(undef) stringifies the set as UTC times. 

=cut

# returns a stringified set with timezones/dst
# as_string accepts a timezone as parameter.
# default timezone is self->{tz}
# 'undef' timezone is UTC
## our $in_string = 0;
sub as_string {
    # return if $in_string;
    # $in_string++;
    my ($self, $tz) = @_;
    $tz = $self->{tz} if $#_ != 1;
    # print " $#_ - $_[-1] - tz is " . ( $tz ? $tz : 'undef' ) . "\n";
    unless (defined $tz) {
        # print "* no tz \n";
        return Set::Infinite::as_string($self);
    }
    # print "* tz \n";

    # we need to move DST definition to UTC
    _dst_to_utc($tz);

    return ( $Date::Set::PRETTY_PRINT ? $self->_pretty_print : $Date::Set::too_complex ) if $self->{too_complex};
    $self->cleanup;
    return join($Set::Infinite::separators[5], map { _simple_as_string($_, $tz) } @{$self->{list}} );
}

sub _simple_as_string {
    my ($self, $tz) = @_;
    my $s;
    # print " [simple:string] ";

    return "" unless defined $self;

    $self->{open_begin} = 1 if ($self->{a} == -$Date::Set::inf );
    $self->{open_end}   = 1 if ($self->{b} == $Date::Set::inf );

    my $tmp1 = $self->{a};
    my $dst1 = $tz->{dst_utc}->contains( $self->{a} ) ? 1 : 0;

    my $tmp2 = $self->{b};
    if ($tmp1 == $tmp2) {
        $tmp1 = Date::Set::ICal->new( $tmp1 + $tz->{offset}[$dst1] );
        $tmp1 =~ s/Z//;
        return $tmp1 . ($tz->{name}[$dst1] ? " " . $tz->{name}[$dst1] : "") ;
    }
    # $tmp1 = "$tmp1";
    # $tmp2 = "$tmp2";
    my $dst2 = $tz->{dst_utc}->contains( $self->{b} ) ? 1 : 0;
    $tmp1 = Date::Set::ICal->new( $tmp1 + $tz->{offset}[$dst1] );
    $tmp2 = Date::Set::ICal->new( $tmp2 + $tz->{offset}[$dst2] );
    $tmp1 =~ s/Z//;
    $tmp2 =~ s/Z//;
    $s = $self->{open_begin} ? $Set::Infinite::separators[2] : $Set::Infinite::separators[0];
    $s .= $tmp1 . ($tz->{name}[$dst1] ? " " . $tz->{name}[$dst1] : "" ). 
        $Set::Infinite::separators[4] . $tmp2 . 
        ($tz->{name}[$dst2] ? " " . $tz->{name}[$dst2] : "") ;
    $s .= $self->{open_end} ? $Set::Infinite::separators[3] : $Set::Infinite::separators[1];
    return $s;
}

=head2 offset

offset() behaves differently from Date::Set::offset() in that
times are adjusted for timezone/DST.

Parameter 'utc' specifies how the offset should be 
calculated:

    utc => 1  # uses UTC time
    utc => 0  # (default) uses clock time (local time); adjusts for timezone/DST

=cut

# units that default to 'utc'=>0
our %utc_offset = ( years => 0, months => 0, days => 0, weeks => 0, hours => 0, weekdays => 0 );

sub offset {
    my ($self, %param) = @_;
    # duration of days or bigger across a DST change needs a UTC translation
    my $utc = $param{utc};
    $utc = $utc_offset{$param{unit}} if exists $param{unit} && ! defined $utc;
    $utc = 1 unless defined $utc;
    my $translated = 0;
    # print " offset: @_ \n";
    my $tz = $self->{tz};
    if ( $tz && $utc == 0 ) {
        $translated = 1;
        $self = $self->tz ( undef );  # translate time to UTC (use 'local time' value)
    }
    $self = Set::Infinite::offset( $self, %param );
    # print " offset got $self \n";
    if ($translated) {
        $self = $self->tz ( $tz );
    }
    return $self;
}

=head2 quantize

quantize() behaves differently from Date::Set::quantize() in that
times are adjusted for timezone/DST.

Parameter 'utc' specifies how the offset should be 
calculated:

    utc => 1  # uses UTC time
    utc => 0  # (default) uses clock time (local time); adjusts for timezone/DST

=cut

sub quantize {
    my ($self, %param) = @_;
    # duration of days or bigger across a DST change needs a UTC translation
    my $utc = $param{utc};
    $utc = $utc_offset{$param{unit}} if exists $param{unit} && ! defined $utc;
    $utc = 1 unless defined $utc;
    my $translated = 0;
    # print " offset: @_ \n";
    my $tz = $self->{tz};
    if ( $tz && $utc == 0 ) {
        $translated = 1;
        $self = $self->tz ( undef );  # translate time to UTC (use 'local time' value)
    }
    $self = Set::Infinite::quantize( $self, %param );
    # print " [ quantize got $self ] \n";
    if ($translated) {
        $self = $self->tz ( $tz );
    }
    return $self;
}

# ------------ Date::Set "INHERITED" METHODS --------------

# none.

#---------------

=head1 AUTHOR

Flavio Soibelmann Glock <fglock@pucrs.br> 

Thanks to Martijn van Beers for help with testing, examples, and API discussions.

=cut

1;

