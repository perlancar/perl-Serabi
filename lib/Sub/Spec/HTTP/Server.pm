package Sub::Spec::HTTP::Server;

use 5.010;
use strict;
use warnings;

# VERSION

1;
# ABSTRACT: PSGI application to serve remote (HTTP) subroutine call requests
__END__

=head1 SYNOPSIS

Suppose you want to expose functions in C<My::API::Module1> and
C<My::API::Module2> as HTTP API functions:

 package My::API::Module1;
 our %SPEC;
 $SPEC{mult} = {args => {a=>["float*"=>{arg_pos=>0}],
                         b=>["float*"=>{arg_pos=>1}]}};
 sub mult { my %args=@_; [200, "OK", $args{a}*$args{b}] }
 1;

 package My::API::Module2;
 $SPEC{array_concat} = {args => {a1=>"array*", a2=>"array*"}};
 sub add { my %args=@_; [200, "OK", [@{$args{a1}}, @{$args{a2}}]] }
 1;

First, write C<app.psgi>:

 #!/usr/bin/perl

 use 5.010;
 use strict;
 use warnings;

 use Plack::Builder;
 use Sub::Spec::HTTP::Server;

 my $sshttps = Sub::Spec::HTTP::Server->new;
 my $app = $sshttps->psgi_app;

 builder {
     enable "SubSpec::RequestParser";
     enable "SubSpec::Auth";
     enable "SubSpec::Authz";
     enable "SubSpec::Response::Usage";
     enable "SubSpec::Response::Call";
     enable "SubSpec::AccessLog";
     $app;
 };

Run the app with PSGI server, e.g. Gepok:

 % plackup -s Gepok --https_ports 5001 \
       --ssl_key_file /path/to/ssl.key --ssl_cert_file /path/to/ssl.crt

Call your functions over HTTP:

 % curl http://localhost:5000/My/API/Module1/mult/2/3
 [200,"OK",6]

 % curl 'https://localhost:5001/My/API/Module2/array_concat?a1:j=[1]&a2:j=[2]'
 [200,"OK",[1,2]]


=head1 DESCRIPTION

Sub::Spec::HTTP::I<Server> is a PSGI I<application> to serve remote (HTTP)
subroutine call requests. It is suitable for serving remote API. (Sorry for the
slight confusion between "server" and "application"; this module was not
originally PSGI-based.)

As the case with any PSGI application, you can use any I<PSGI server> to run it
with. But you might want to consider L<Gepok>, which has built-in HTTPS support.

This module uses L<Log::Any> for logging.

This module uses L<Moo> for object system.


=head1 FAQ


=head1 SEE ALSO

L<Sub::Spec>

L<Sub::Spec::HTTP::Client>

L<Gepok>

=cut
