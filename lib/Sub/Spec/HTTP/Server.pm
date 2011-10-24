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
http://<host>/api/<module>/<func>:

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

Then:

 $ servepm My::API::Adder My::API::Adder::Array

Then call your functions over HTTP(S)?:

 % curl http://localhost:5000/api/My::API::Adder/add/2/3
 [200,"OK",6]

 % curl -H 'X-SS-Req-Log-Level: trace' \
   'http://localhost:5000/api/My::API::Adder::Array/add?a1:j=[1]&a2:j=[2,3]'
 [200,"OK",[1,2,3]]

Request help/usage information:

 % curl -H 'X-SS-Req-Command: help' \
   'http://localhost:5000/api/My::API::Adder::Array/add'
 My::API::Adder::Array::add - Concatenate two arrays together

 Arguments:
   a1   (array, required) First array
   a2   (array, required) Second array

List available function in a module (request key 'command' given in request
variable):

 % curl 'http://localhost:5000/api/My::API::Adder?-ss-req-command=list_subs'
 ['add']

List available modules:

 % curl -H 'X-SS-Req-Command: list_mods' \
   'http://localhost:5000/api/'
 ['My::API::Adder','My::API::Adder::Array']


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

=head2 How can I customize URL?

For example, instead of:

 http://localhost:5000/api/My::API::Adder/func

you want:

 http://localhost:5000/adder/func

or perhaps (if you only have one module to expose):

 http://localhost:5000/func

You can do this by customizing uri_pattern when enabling SubSpec::ParseRequest
middleware (see servepm source code).

=head1 I want to let user specify output format from URI (e.g. /api/json/... or /api/v1/yaml/...)

Again, this can be achieved by customizing the SubSpec::ParseRequest middleware.
You can do something like:

 enable "SubSpec::ParseRequest"
     uri_pattern => qr!^/api/v1/(?<output_format>json|yaml)/
                       (?<module>[^?/]+)?
                       (?:/(?<sub>[^?/]+)?)!x;

or:

 enable "SubSpec::ParseRequest"
     uri_pattern => qr!^/api/v1/(?<fmt>j|y)/
                       (?<module>[^?/]+)?
                       (?:/(?<sub>[^?/]+)?)!x,
     after_parse => sub {
         my $env = shift;
         my $fmt = $env->{"ss.uri_pattern_matches"}{fmt};
         $env->{"ss.request"}{output_format} = $fmt =~ /j/ ? 'json' : 'yaml';
     };

=head1 I need even more custom URI syntax

You can leave C<uri_pattern> empty and perform your custom URI parsing in
C<after_parse>. For example:

 enable "SubSpec::ParseRequest"
     after_parse => sub {
         my $env = shift;
         # parse $env->{REQUEST_URI} on your own and put the result in
         # $env->{"ss.request"}{uri}
     };

Or alternatively you can write your own request parser to replace ParseRequest.

=head2 I want to enable HTTPS.

Supply --https_ports, --ssl_key_file and --ssl_cert_file options in servepm.

=head2 I don't want to expose my subroutines and module structure directly!

Well, isn't exposing functions the whole point of API?

If you have modules that you do not want to expose as API, simply exclude it
(e.g. using C<allowed_modules> configuration in SubSpec::ParseRequest
middleware. Or, create a set of wrapper modules to expose only the
functionalities that you want to expose.

=head1 I want to support another output format (e.g. XML, MessagePack, etc).

Add a format_<fmtname> method to L<Plack::Middleware::SubSpec::HandleCommand>.
The method accepts sub response and is expected to return a tuplet ($output,
$content_type).

Note that you do not have to modify the
Plack/Middleware/SubSpec/HandleCommand.pm file itself. You can inject the method
from another file.

Also make sure that the output format is allowed (see configuration
C<allowed_output_formats> in the command handler middleware).

=head2 I want to automatically reload modules that changed on disk.

Use one of the module-reloading module on CPAN, e.g.: L<Module::Reload> or
L<Module::Reload::Conditional>.

=head2 I want to authenticate clients.

Enable L<Plack::Middleware::Auth::Basic> (or other authen middleware
you prefer) before SubSpec::ParseRequest.

=head2 I want to authorize clients.

Take a look at L<Plack::Middleware::SubSpec::Authz::ACL> which allows
authorization based on various conditions. Normally this is put after
authentication and before command handling.

=head2 I want to support new commands.

Write Sub::Spec::HTTP::Server::Command::<cmdname>, and include the command in
SubSpec::ParseRequest's C<allowed_commands> configuration.

But first consider if that is really what you want. If you want to serve static
files or do stuffs unrelated to calling subroutines or subroutine spec, you
ought to put it somewhere else, e.g.:

 my $app = builder {
     mount "/api" => builder {
         enable "SubSpec::ParseRequest", ...;
         ...
     },
     mount "/static" => ...
 };


=head1 TIPS AND TRICKS

=head2 Proxying API server

Not only can you serve local modules ("pm://" URIs), you can serve remote
modules ("http://" or "https://" URIs) making your API server a proxy for
another.

=head2 Performance tuning

To be written.


=head1 SEE ALSO

L<Sub::Spec::HTTP>

L<Gepok>

=cut
