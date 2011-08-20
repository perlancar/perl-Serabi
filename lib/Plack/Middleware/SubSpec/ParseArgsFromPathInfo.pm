package Plack::Middleware::SubSpec::ParseArgsFromPathInfo;

use 5.010;
use strict;
use warnings;

use parent qw(Plack::Middleware);
#use Plack::Util::Accessor qw();

use Plack::Util::SubSpec qw(errpage);
use Sub::Spec::GetArgs::Array qw(get_args_from_array);

# VERSION

#sub prepare_app {
#    my $self = shift;
#}

sub call {
    my ($self, $env) = @_;

    my $argv = $env->{"ss.request.argv"};
    my $spec = $env->{"ss.spec"};

    if ($argv && $spec) {
        my $res = get_args_from_array(array=>$argv, spec=>$spec);
        return errpage("Can't parse arguments from path info: $res->[1]",
                       $res->[0]) unless $res->[0] == 200;
        $env->{'ss.request.args'} //= {};
        for my $k (keys %{$res->[2]}) {
            $env->{'ss.request.args'}{$k} = $res->[2]{$k};
        }
    }

    # continue to app
    $self->app->($env);
}

1;
# ABSTRACT: Parse sub arguments from path info

=head1 SYNOPSIS

 # in your app.psgi
 use Plack::Builder;

 builder {
     enable "SubSpec::ParseArgsFromPathInfo";
 };


=head1 DESCRIPTION

This middleware parses sub argument from path info, using
L<Sub::Spec::GetArgs::Array>. It should be enabled after SubSpec::GetSpec
middleware (and thus separated from SubSpec::ParseRequest) because parsing
positional arguments requires that we have sub spec first.


=head1 SEE ALSO

L<Plack::Middleware::SubSpec::ParseRequest>

=cut
