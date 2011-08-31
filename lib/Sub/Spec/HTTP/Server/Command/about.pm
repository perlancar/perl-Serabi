package Sub::Spec::HTTP::Server::Command;

use 5.010;
use strict;
use warnings;

# VERSION

sub handle_about {
    my ($env) = @_;
    my $ssreq = $env->{"ss.request"};

    my $ssu = $ssreq->{uri};
    return [200, "OK", {
        uri     => ($ssu ? $ssu->{_uri} : undef),
        module  => ($ssu ? $ssu->module : undef),
        sub     => ($ssu ? $ssu->sub    : undef),
        args    => ($ssu ? $ssu->args   : undef),
    }];
}

1;
# ABSTRACT: Return information about the server and request

=head1 SYNOPSIS

 # used by Plack::Middleware::SubSpec::HandleCommand


=head1 DESCRIPTION

This command returns a hashref containing information about the server and
request, e.g.: 'module', 'sub', 'args'

=cut
