package Sub::Spec::HTTP::Server::Command;

use 5.010;
use strict;
use warnings;

# VERSION

sub handle_call {
    my ($env) = @_;
    my $uri = $env->{"ss.request"}{uri};
    return [400, "SS request URI not specified"] unless $uri;

    my $res;
    eval { $res = $uri->call(%{$env->{"ss.request"}{args}}) };
    my $eval_err = $@;

    # sometimes when a sub which drops privileges dies, it has not regained
    # privileges.
    if ($< == 0 && $>) { $> = 0; $) = $( }

    return [500, "Exception when calling $uri->{_uri}: $@"] if $@;
}

1;
# ABSTRACT: Handle 'call' command (call subroutine and return the result)

=head1 SYNOPSIS

 # used by Plack::Middleware::SubSpec::HandleCommand


=head1 DESCRIPTION

This module uses L<Sub::Spec::Caller> to call the requested subroutine and
format its result. Will return error 500 will be returned if requested output
format is unknown/unallowed.


=head1 CONFIGURATIONS

=over 4

=back

=cut
