package Plack::Util::SubSpec;

use 5.010;
use strict;
use warnings;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(errpage allowed str_log_level);

# VERSION

sub errpage {
    my ($msg, $code) = @_;
    $msg .= "\n" unless $msg =~ /\n\z/;
    $code //= 400;
    $msg = "$code - $msg";
    [$code,
     ["Content-Type" => "text/plain", "Content-Length" => length($msg)],
     [$msg]];
}

sub allowed {
    my ($value, $pred) = @_;
    if (ref($pred) eq 'ARRAY') {
        return $value ~~ @$pred;
    } else {
        return $value =~ /$pred/;
    }
}

my %str_log_levels = (
    fatal => 1,
    error => 2,
    warn  => 3,
    info  => 4,
    debug => 5,
    trace => 6,
);
my %int_log_levels = reverse %str_log_levels;
my $str_log_levels_re = join("|", keys %str_log_levels);
$str_log_levels_re = qr/(?:$str_log_levels_re)/;

# return undef if unknown
sub str_log_level {
    my ($level) = @_;
    return unless $level;
    if ($level =~ /^\d+$/) {
        return $int_log_levels{$level} // undef;
    }
    return unless $level =~ $str_log_levels_re;
    $level;
}

1;
