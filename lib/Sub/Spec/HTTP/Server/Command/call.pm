package Sub::Spec::HTTP::Server::Command;

use 5.010;
use strict;
use warnings;

use Sub::Spec::Caller qw(call_sub);

# VERSION

sub handle_call {
    my ($self, $env) = @_;
    call_sub(
        $env->{'ss.request'}{module},
        $env->{'ss.request'}{sub},
        $env->{'ss.request'}{args},
        {load=>0, convert_datetime_objects=>1});
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
