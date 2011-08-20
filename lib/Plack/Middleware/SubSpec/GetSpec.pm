package Plack::Middleware::SubSpec::GetSpec;

use 5.010;
use strict;
use warnings;

use parent qw(Plack::Middleware);
#use Plack::Util::Accessor qw();

use Plack::Util::SubSpec qw(errpage);

# VERSION

#sub prepare_app {
#    my $self = shift;
#}

sub call {
    my ($self, $env) = @_;

    my $module = $env->{'ss.request.module'};
    my $sub    = $env->{'ss.request.sub'};
    if ($module && $sub) {
        my $spec     = $module . "::SPEC";
        no strict 'refs';
        my $sub_spec = ${$spec}{$sub};
        return errpage("Can't find sub spec for $module::$sub", 500);
        $env->{'ss.spec'} = $sub_spec;
    }

    # continue to app
    $self->app->($env);
}

1;
# ABSTRACT: Get sub spec

=head1 SYNOPSIS

 # in your app.psgi
 use Plack::Builder;

 builder {
     enable "SubSpec::GetSpec";
 };


=head1 DESCRIPTION

This middleware gets sub spec from %SPEC package variable, and puts it to
$env->{'ss.spec'}. Will do nothing if $env->{'ss.request.module'} or
$env->{'ss.request.sub'} is not set. Should be enabled after SubSpec::LoadModule
middleware.


=head1 CONFIGURATIONS

=over 4

=back

=cut
