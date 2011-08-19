package Plack::Middleware::SubSpec::LoadModule;

use 5.010;
use strict;
use warnings;

use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw(debug);

use Module::Load;

# VERSION

#sub prepare_app {
#    my $self = shift;
#}

# XXX this is duplicated in each middleware. refactor.
sub __err {
    my ($msg, $code) = @_;
    $msg .= "\n" unless $msg =~ /\n\z/;
    [$code // 400, ["Content-Type" => "text/plain"], [$msg]];
}

sub call {
    my ($self, $env) = @_;

    my $module = $env->{'ss.request.module'};
    return __err("No ss.request.module/ss.request.module defined", 500)
        unless $module && $sub;
    eval { load $module };
    return __err("Can't load module".($self->debug ? ": $@" : ""), 500)
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
