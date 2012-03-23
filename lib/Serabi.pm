package Serabi;

use 5.010;
use strict;
use warnings;

# VERSION

1;
# ABSTRACT: Create REST-style web service with Riap backend

=head1 STATUS

Nothing is implemented yet.


=head1 DESCRIPTION

This will be a set of PSGI middlewares (Plack::Middleware::Serabi::*) to help
you build REST-style web service with L<Riap> backend. This is meant as an
alternative (or companion) to L<Perinci::Access::HTTP::Server>.

I currently have no plan implementing this, as I find L<Rinci>/Riap easy to
implement and sufficient for a rich and usable API service. But this library is
mostly only about mapping HTTP requests (URI's, methods, headers) as REST
resources and verbs, and then mapping them to Riap requests.


=head1 FAQ

=head2 Serabi?

Serabi is a delicious traditional food from where I live (Java, Indonesia). I
picked the name after a Python project, B<jango-tastypie>. Aside from the name,
both projects are unrelated.


=head1 SEE ALSO

L<Rinci>, L<Riap>, L<Perinci> (Gosh, have I "gone Ruby"?)

django-tastypie, https://github.com/toastdriven/django-tastypie

=cut
