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
    if ($module) {
        eval { load $module };
        return errpage("Can't load module".($self->debug ? ": $@" : ""), 500)
            if $@;
    }
    # continue to app
    $self->app->($env);
}

1;
# ABSTRACT: Load requested module

=head1 SYNOPSIS

 # in app.psgi
 use Plack::Builder;

 builder {
     enable "SubSpec::LoadModule";
 };


=head1 DESCRIPTION

This middleware loads module specified in $env->{'ss.request.module'} using
L<Module::Load>. Will do nothing if module is not specified. Will return 500
error if failed to load module. It should be enabled after the
SubSpec::ParseRequest middleware.


=head1 CONFIGURATIONS

=over 4

=item * debug => BOOL (default 0)

If set to true, will display full error message in error page when failing to
load module. Otherwise, only a generic "failed to load module" message is
displayed.

=back

=cut
