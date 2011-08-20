package Plack::Middleware::SubSpec::Command::call;

use 5.010;
use strict;
use warnings;

use parent qw(Plack::Middleware::SubSpec::Command);

use Log::Any::Adapter;
use Plack::Util::SubSpec qw(errpage);
use Sub::Spec::Caller qw(call_sub);
use Time::HiRes qw(gettimeofday);

# VERSION

sub exec_call {
    my ($self, $env) = @_;
    call_sub(
        $env->{'ss.request.module'},
        $env->{'ss.request.sub'},
        $env->{'ss.request.args'},
        {load=>0, convert_datetime_objects=>1});
    $env->{'ss.finish_command_time'} = [gettimeofday];
}

1;
# ABSTRACT: Handle 'call' command (call subroutine and return the result)

=head1 SYNOPSIS

 # in your app.psgi
 use Plack::Builder;

 builder {
     # enable other middlewares ...
     enable "SubSpec::Command::call";
     # enable other middlewares ...
 };


=head1 DESCRIPTION

This middleware uses L<Sub::Spec::Caller> to call the requested subroutine and
format its result. Will return error 500 will be returned if requested output
format is unknown/unallowed.


=head1 CONFIGURATIONS

=over 4

=back

=cut
