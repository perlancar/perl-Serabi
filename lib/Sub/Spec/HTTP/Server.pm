package Sub::Spec::HTTP::Server;

use 5.010;
use strict;
use warnings;

# VERSION

1;
# ABSTRACT: PSGI application to serve remote (HTTP) subroutine call requests
__END__

=head1 SYNOPSIS

Suppose you want to expose functions in C<My::API::Adder> and
C<My::API::Adder::Array> as HTTP API functions, using URL
http://<host>/api/v1/<module>/<func>:

 package My::API::Adder;
 our %SPEC;
 $SPEC{add} = {args => {a=>["float*"=>{arg_pos=>0}],
                        b=>["float*"=>{arg_pos=>1}]}};
 sub add { my %args=@_; [200, "OK", $args{a}+$args{b}] }
 1;

 package My::API::Adder::Array;
 $SPEC{add_array} = {args => {a1=>"array*", a2=>"array*"}};
 sub add { my %args=@_; [200, "OK", [@{$args{a1}}, @{$args{a2}}]] }
 1;

First, write C<app.psgi>:

 #!perl
 use Plack::Builder;

 builder {
     # this is the basic composition
     enable "SubSpec::ParseRequest"
         uri_pattern => qr!^/api/v1/(?<module>[^?]+)/(?<sub>[^?/]+)!,
         after_parse => sub {
             my $env = shift;
             for ($env->{"ss.request.module"}) {
                 last unless $_;
                 s!/!::!g;
                 $_ = "My::API::$_" unless /^My::API::/;
             }
         };
     enable "SubSpec::LoadModule";
     enable "SubSpec::GetSpec";
     enable "SubSpec::ServeCall";
     enable "SubSpec::ServeHelp";
     enable "SubSpec::ServeSpec";
     enable "SubSpec::AccessLog";
 };

Run the app with PSGI server, e.g. Gepok:

 % plackup -s Gepok --https_ports 5001 \
       --ssl_key_file /path/to/ssl.key --ssl_cert_file /path/to/ssl.crt

Call your functions over HTTP(S)?:

 % curl http://localhost:5000/api/v1/Adder/add/2/3
 [200,"OK",6]

 % curl 'https://localhost:5001/api/v1/Adder/Array/add?a1:j=[1]&a2:j=[2,3]'
 [200,"OK",[1,2,3]]


=head1 DESCRIPTION

Sub::Spec::HTTP::I<Server> is a PSGI I<application> to serve remote (HTTP)
subroutine call requests. It is suitable for serving remote API. (Sorry for the
slight confusion between "server" and "application"; this module was not
originally PSGI-based.)

As the case with any PSGI application, you can use any I<PSGI server> to run it
with. But you might want to consider L<Gepok>, which has built-in HTTPS support.

This PSGI application is actually a set of modular middlewares
(Plack::Middleware::SubSpec::*) which you can compose in your app.psgi,
configuring each one and including only the ones you need. The Synopsis shows
one such basic composition. There are more middlewares to do custom stuffs. See
each middleware's documentation for details.

This module uses L<Log::Any> for logging.

This module uses L<Moo> for object system.


=head1 FAQ

=head2 I want to expose just a single module and provide a simpler API URL (e.g. without having to specify module name).

You can do something like this:

 enable "SubSpec::ParseRequest"
     uri_pattern => qr!^/api/v1/(?<sub>[^?/]+)!,
     after_parse => sub {
         my $env = shift;
         $env->{"ss.request.module"} = "Foo";
     };

=head1 I want to easily let user specify output format (e.g. /api/v1/json/... or /api/v1/yaml/...)

You can do something like:

 enable "SubSpec::ParseRequest"
     uri_pattern => qr!^/api/v1/(?:json|yaml)/(?<sub>[^?/]+)/(?<sub>[^?/]+)!,
     after_parse => sub {
         my $env = shift;
         $env->{REQUEST_URI} =~ m!^/api/v1/(json|yaml)!;
         $env->{"ss.request.opts"}{output_format} = $1;
     };

=head1 I want to add another output format (e.g. XML, MessagePack, Storable, etc).

You can subclass L<Plack::Middleware::SubSpec::ServeCall> and override
format_output() to support more formats. Or you can try to convince me that the
output format is popular enough to be included in
Plack::Middleware::SubSpec::ServeCall.

=head1 I need custom URI syntax (e.g. not exposing real module and/or func name)

You can use ParseRequest and provide a generic B<uri_pattern> and then complete
the request information in B<after_parse>. For example:

 enable "SubSpec::ParseRequest"
     uri_pattern => qr!!, # match anything
     after_parse => sub {
         my $env = shift;
         # parse REQUEST_URI on your own and put the result in
         # $env->{"ss.request.module"} and $env->{"ss.request.sub"}
     };

Or alternatively you can write your own request parser to replace ParseRequest.

=head2 I want to automatically load requested modules.

Enable the L<Plack::Middleware::SubSpec::LoadModule> middleware.

=head2 I want to limit only certain modules can be requested.

In ParseRequest's B<after_parse>, you can return a 400 error response if module
name (C<$env->{"ss.request.module"}>) does not satisfy your restrictions.

=head2 I want to automatically reload modules that changed on disk.

Use one of the module-reloading module on CPAN, e.g.: L<Module::Reload> or
L<Module::Reload::Conditional>.


=head1 SEE ALSO

L<Sub::Spec>

L<Sub::Spec::HTTP::Client>

L<Gepok>

=cut
