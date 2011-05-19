package SHARYANTO::YAML::Any;
BEGIN {
  $SHARYANTO::YAML::Any::VERSION = '0.72';
}
# ABSTRACT: SHARYANTO::YAML::Any - Pick a YAML implementation and use it.

use 5.005003;
use strict;
use Exporter ();

$SHARYANTO::YAML::Any::VERSION   = '0.72';
@SHARYANTO::YAML::Any::ISA       = 'Exporter';
@SHARYANTO::YAML::Any::EXPORT    = qw(Dump Load);
@SHARYANTO::YAML::Any::EXPORT_OK = qw(DumpFile LoadFile);

my @dump_options = qw(
    UseCode
    DumpCode
    SpecVersion
    Indent
    UseHeader
    UseVersion
    SortKeys
    AnchorPrefix
    UseBlock
    UseFold
    CompressSeries
    InlineSeries
    UseAliases
    Purity
    Stringify
);

my @load_options = qw(
    UseCode
    LoadCode
);

my @implementations = qw(
    YAML::Syck
    YAML::XS
    YAML::Old
    YAML
    YAML::Tiny
);

my %implementation_setups = (
    "YAML::Syck" => sub {
        $YAML::Syck::ImplicitTyping = 1;
    },
);

sub import {
    __PACKAGE__->implementation;
    goto &Exporter::import;
}

sub Dump {
    no strict 'refs';
    my $implementation = __PACKAGE__->implementation;
    for my $option (@dump_options) {
        my $var = "$implementation\::$option";
        my $value = $$var;
        local $$var;
        $$var = defined $value ? $value : ${"YAML::$option"};
    }
    return &{"$implementation\::Dump"}(@_);
}

sub DumpFile {
    no strict 'refs';
    my $implementation = __PACKAGE__->implementation;
    for my $option (@dump_options) {
        my $var = "$implementation\::$option";
        my $value = $$var;
        local $$var;
        $$var = defined $value ? $value : ${"YAML::$option"};
    }
    return &{"$implementation\::DumpFile"}(@_);
}

sub Load {
    no strict 'refs';
    my $implementation = __PACKAGE__->implementation;
    for my $option (@load_options) {
        my $var = "$implementation\::$option";
        my $value = $$var;
        local $$var;
        $$var = defined $value ? $value : ${"YAML::$option"};
    }
    return &{"$implementation\::Load"}(@_);
}

sub LoadFile {
    no strict 'refs';
    my $implementation = __PACKAGE__->implementation;
    for my $option (@load_options) {
        my $var = "$implementation\::$option";
        my $value = $$var;
        local $$var;
        $$var = defined $value ? $value : ${"YAML::$option"};
    }
    return &{"$implementation\::LoadFile"}(@_);
}

sub order {
    return @SHARYANTO::YAML::Any::_TEST_ORDER
        if defined @SHARYANTO::YAML::Any::_TEST_ORDER;
    return @implementations;
}

sub implementation {
    my @order = __PACKAGE__->order;
    for my $module (@order) {
        my $path = $module;
        $path =~ s/::/\//g;
        $path .= '.pm';
        return $module if exists $INC{$path};
        if (eval "require $module; 1") {
            ($implementation_setups{$module} // sub {})->();
            return $module;
        }
    }
    croak("SHARYANTO::YAML::Any couldn't find any of these YAML implementations: @order");
}

sub croak {
    require Carp;
    Carp::Croak(@_);
}

1;


__END__
=pod

=head1 NAME

SHARYANTO::YAML::Any - SHARYANTO::YAML::Any - Pick a YAML implementation and use it.

=head1 VERSION

version 0.72

=head1 SYNOPSIS

    use SHARYANTO::YAML::Any;
    $SHARYANTO::YAML::Indent = 3;
    my $yaml = Dump(@objects);

=head1 DESCRIPTION

SHARYANTO::YAML::Any is forked from YAML::Any. The difference is the order of
implementation selection (YAML::Syck first) and the setting
($YAML::Syck::ImplicitTyping is turned on, as any sane YAML user would do). The
rest is YAML::Any's documentation.

There are several YAML implementations that support the Dump/Load API.
This module selects the best one available and uses it.

=head1 ORDER

Currently, YAML::Any will choose the first one of these YAML
implementations that is installed on your system:

    YAML::XS
    YAML::Syck
    YAML::Old
    YAML
    YAML::Tiny

=head1 OPTIONS

If you specify an option like:

    $YAML::Indent = 4;

And YAML::Any is using YAML::XS, it will use the proper variable:
$YAML::XS::Indent.

=head1 SUBROUTINES

Like all the YAML modules that YAML::Any uses, the following subroutines
are exported by default:

    Dump
    Load

and the following subroutines are exportable by request:

    DumpFile
    LoadFile

=head1 METHODS

YAML::Any provides the following class methods.

=over

=item YAML::Any->order;

This method returns a list of the current possible implementations that
YAML::Any will search for.

=item YAML::Any->implementation;

This method returns the implementation the YAML::Any will use. This
result is obtained by finding the first member of YAML::Any->order that
is either already loaded in C<%INC> or that can be loaded using
C<require>. If no implementation is found, an error will be thrown.

=back

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2008. Ingy döt Net.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

