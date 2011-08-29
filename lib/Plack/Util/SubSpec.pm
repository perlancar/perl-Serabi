package Plack::Util::SubSpec;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(errpage);

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

1;
