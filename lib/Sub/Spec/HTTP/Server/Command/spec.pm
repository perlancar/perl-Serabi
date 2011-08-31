package Sub::Spec::HTTP::Server::Command;

use 5.010;
use strict;
use warnings;

# VERSION

sub handle_spec {
    my ($env) = @_;
    my $ssu = $env->{"ss.request"}{uri};
    return [400, "SS request URI not specified"] unless $ssu;

    [200, "OK", $ssu->spec()];
}

1;
# ABSTRACT: Return subroutine spec

=head1 SYNOPSIS

 # used by Plack::Middleware::SubSpec::HandleCommand


=head1 DESCRIPTION

This module returns subroutine's spec. Will return 400 error if module or sub is
not specified in URI.

=cut
