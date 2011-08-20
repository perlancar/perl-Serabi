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
 $SPEC{add_array} = {
     summary => 'Concatenate two arrays together',
     args => {a1=>["array*" => {summary => 'First array'}],
              a2=>["array*" => {summary => 'Second array'}]},
 };
 sub add { my %args=@_; [200, "OK", [@{$args{a1}}, @{$args{a2}}]] }
 1;

First, write C<app.psgi>:

 #!perl
 use Plack::Builder;

 builder {
     # this is the basic composition
     enable "SubSpec::LogAccess";
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
     enable "SubSpec::Command::call";
     enable "SubSpec::Command::help";
     enable "SubSpec::Command::spec";
     enable "SubSpec::Command::listmod";
     enable "SubSpec::Command::listsub";
 };

Run the app with PSGI server, e.g. Gepok:

 % plackup -s Gepok --https_ports 5001 \
       --ssl_key_file /path/to/ssl.key --ssl_cert_file /path/to/ssl.crt

Call your functions over HTTP(S)?:

 % curl http://localhost:5000/api/v1/Adder/add/2/3
 [200,"OK",6]

 % curl -H 'X-SS-Log-Level: trace' \
   'https://localhost:5001/api/v1/Adder/Array/add?a1:j=[1]&a2:j=[2,3]'
 [200,"OK",[1,2,3]]

Request help/usage information:

 % curl -H 'X-SS-Command: help' \
   'http://localhost:5000/api/v1/Adder/Array/add'
 My::API::Adder::Array::add - Concatenate two arrays together

 Arguments:
   a1   (array, required) First array
   a2   (array, required) Second array

List available function in a module:

 % curl -H 'X-SS-Command: listsub' \
   'http://localhost:5000/api/v1/Adder/Array'
 ['add_array']

List available modules:

 % curl -H 'X-SS-Command: listmod' \
   'http://localhost:5000/api/v1/Adder/Array'
 ['add_array']


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

=head1 I want to let user specify output format from URI (e.g. /api/v1/json/... or /api/v1/yaml/...)

You can do something like:

 enable "SubSpec::ParseRequest"
     uri_pattern => qr!^/api/v1/(?:json|yaml)/(?<sub>[^?/]+)/(?<sub>[^?/]+)!,
     after_parse => sub {
         my $env = shift;
         $env->{REQUEST_URI} =~ m!^/api/v1/(json|yaml)!;
         $env->{"ss.request.opts"}{output_format} = $1;
     };

=head1 I want to support another output format (e.g. XML, MessagePack, etc).

Subclass L<Plack::Middleware::SubSpec::ServeCall> and add format_<fmtname>
method. The method accepts sub response and is expected to return a tuplet
($output, $content_type).

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
L<Module::Reload::Conditional>. Do it before/after the SubSpec::LoadModule
middleware.

=head2 I want to authenticate clients.

Enable L<Plack::Middleware::Auth::Basic> (or other authen middleware you prefer)
before SubSpec::ParseRequest.

=head2 I want to authorize clients.

Take a look at L<Plack::Middleware::SubSpec::Authz::ACL> which allows
authorization based on various conditions. Normally this is put after
authentication and before any request serving middleware
(Plack::Middleware::SubSpec::Server*).

=head2 I want to support new commands.

You can write a Plack::Middleware::SubSpec::Command::<cmdname> middleware and
enable it at the appropriate position in your PSGI application. But first
consider if that is really what you want. If you want to serve static files or
do stuffs unrelated to calling subroutines or subroutine spec, you ought to put
it somewhere else.


=head1 SEE ALSO

L<Sub::Spec>

L<Sub::Spec::HTTP::Client>

L<Gepok>

=cut
