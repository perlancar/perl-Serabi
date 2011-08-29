package Plack::Middleware::SubSpec::Command::listmod;

use 5.010;
use strict;
use warnings;

use parent qw(Plack::Middleware);
#use Plack::Util::Accessor qw();

use Plack::Util::SubSpec qw(errpage);

# VERSION

sub prepare_app {
    my $self = shift;
    die "Not yet implemented";
}

sub call {
    my ($self, $env) = @_;

    # continue to app
    $self->app->($env);
}

1;
# ABSTRACT: List available modules
__END__

=head1 SYNOPSIS

 # In app.psgi
 use Plack::Builder;

 builder {
    enable "SubSpec::Command::listmod";
 };


=head1 DESCRIPTION

This middleware executes 'listmod' command.


=head1 CONFIGURATION

=over 4

=back

=cut
