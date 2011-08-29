package Plack::Middleware::SubSpec::Command::listsub;

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
# ABSTRACT: List available functions in a module
__END__

=head1 SYNOPSIS

 # In app.psgi
 use Plack::Builder;

 builder {
    enable "SubSpec::Command::listsub";
 };


=head1 DESCRIPTION

This middleware executes 'listsub' command.


=head1 CONFIGURATION

=over 4

=back

=cut
