package SHARYANTO::YAML::Any;
# ABSTRACT: Pick a YAML implementation and use it.

# NOTE: temporary namespace, will eventually be refactored, tidied up, and sent
# to a more proper namespace.

use 5.010;
use strict;
use Exporter ();

our @ISA       = qw(Exporter);
our @EXPORT    = qw(Dump Load);
our @EXPORT_OK = qw(DumpFile LoadFile);

our $VERSION   = '0.72';

use YAML::Syck;
$YAML::Syck::ImplicitTyping = 1;

1;
__END__

=for Pod::Coverage .*
