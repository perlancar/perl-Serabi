package Sub::Spec::HTTP::Server::Command;

use 5.010;
use strict;
use warnings;

# VERSION

sub handle_list_subs {
    my ($env) = @_;
    my $ssu = $env->{"ss.request"}{uri};
    return [400, "SS request URI not specified"] unless $ssu;

    $ssu->list_subs();
}

1;
# ABSTRACT: List subroutines in a module

=head1 SYNOPSIS

 # used by Plack::Middleware::SubSpec::HandleCommand


=head1 DESCRIPTION

This module returns list of subroutines within a module. Will return 400 error
if module is not specified in URI.

=cut
