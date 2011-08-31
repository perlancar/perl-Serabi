package Sub::Spec::HTTP::Server::Command;

use 5.010;
use strict;
use warnings;

use Sub::Spec::To::Text::Usage qw(spec_to_usage);

# VERSION

sub handle_usage {
    my ($env) = @_;
    my $ssu = $env->{"ss.request"}{uri};
    return [400, "SS request URI not specified"] unless $ssu;

    my $spec = $ssu->spec();
    spec_to_usage(spec => $spec);
}

1;
# ABSTRACT: Return function usage information

=head1 SYNOPSIS

 # used by Plack::Middleware::SubSpec::HandleCommand


=head1 DESCRIPTION

This module returns subroutine's spec. Will return 400 error if module or sub is
not specified in URI.

=cut
