package Plack::Middleware::SubSpec::LoadModule;

use 5.010;
use strict;
use warnings;

use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw(debug);

use Module::Load;
use Plack::Util::SubSpec qw(errpage);

# VERSION

#sub prepare_app {
#    my $self = shift;
#}

sub call {
    my ($self, $env) = @_;

    my $module = $env->{'ss.request.module'};
    return errpage("No ss.request.module/ss.request.module defined", 500)
        unless $module;
    eval { load $module };
    return errpage("Can't load module".($self->debug ? ": $@" : ""), 500)
        if $@;
    # continue to app
    $self->app->($env);
}

1;
# ABSTRACT: Load requested module

=head1 SYNOPSIS

 # in your app.psgi
 use Plack::Builder;

 builder {
     # enable other middlewares ...
     enable "SubSpec::LoadModule";
    # enable other middlewares ...
 };


=head1 DESCRIPTION

This middleware load module specified in $env->{'ss.request.module'} (so
obviously it should be executed after ParseRequest). It basically just pass it
to L<Module::Load>'s load() and return 500 error code if module cannot be
loaded.

If you want custom module loading (e.g. with autoreloading capability, loading
other from filesystem, etc), please write a middleware under
Plack::Middleware::SubSpec::LoadModule::* namespace.

=head1 CONFIGURATIONS

=over 4

=item * debug => BOOL

=back

=cut
