package SHARYANTO::YAML::Any;
BEGIN {
  $SHARYANTO::YAML::Any::VERSION = '0.72';
}
# ABSTRACT: SHARYANTO::YAML::Any - Pick a YAML implementation and use it.

use 5.010;
use strict;
use Exporter ();

our @ISA       = qw(Exporter);
our @EXPORT    = qw(Dump Load);
our @EXPORT_OK = qw(DumpFile LoadFile);

use YAML::Syck;
$YAML::Syck::ImplicitTyping = 1;

1;
