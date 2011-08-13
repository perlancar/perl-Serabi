package Plack::Middleware::SubSpec::ParseRequest;

use 5.010;
use strict;
use warnings;

use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw(
                                uri_pattern
                                allow_call_request
                                allow_help_request
                                allow_spec_request
                                parse_args_from_web_form
                                parse_args_from_body
                                parse_args_from_path_info
                                accept_json
                                accept_yaml
                                accept_php
                                allow_return_json
                                allow_return_yaml
                                allow_return_php
                                allow_logs
                                per_arg_encoding
                        );

# VERSION

sub call {
    my ($env, $env) = @_;

    if ($http_req->header('X-SS-Log-Level')) {
        $req->{log_level} = $http_req->header('X-SS-Log-Level');
        $log->trace("Turning on chunked transfer ...");
        $req->{chunked}++;
    }
    if ($http_req->header('X-SS-Mark-Chunk')) {
        $log->trace("Turning on mark prefix on each chunk ...");
        $req->{mark_chunk}++;
        $log->trace("Turning on chunked transfer ...");
        $req->{chunked}++;
    }

    my $uri = $http_req->uri;
    $log->trace("request URI = $uri");
    unless ($uri =~ m!\A/+v1
                      /+([^/]+(?:/+[^/]+)*) # module
                      /+([^/]+?)    # func
                      (?:;([^?]*))? # opts
                      (?:\?|\z)
                     !x) {
        $self->resp([
            400, "Invalid request URI, please use the syntax ".
                "/v1/MODULE/SUBMODULE/FUNCTION?PARAM=VALUE..."]);
        die;
    }
    my ($module, $sub, $opts) = ($1, $2, $3);

    $module =~ s!/+!::!g;
    unless ($module =~ /\A\w+(?:::\w+)*\z/) {
        $self->resp([
            400, "Invalid module, please use alphanums only, e.g. My/Module"]);
        die;
    }
    $req->{sub_module} = $self->module_prefix ?
        $self->module_prefix.'::'.$module : $module;

    unless ($sub =~ /\A\w+(?:::\w+)*\z/) {
        $self->resp([
            400, "Invalid sub, please use alphanums only, e.g. my_func"]);
        die;
    }
    $req->{sub_name}   = $sub;

    $req->{opts}       = $opts;

        if ($opts =~ /l:([1-6])(m?)(?::|\z)/) {
            $http_req->header('X-SS-Mark-Chunk' => 1) if $2;
            my $l = $1;
            my $level =
                $l == 6 ? 'trace' :
                $l == 5 ? 'debug' :
                $l == 4 ? 'info' :
                $l == 3 ? 'warning' :
                $l == 2 ? 'error' :
                $l == 1 ? 'fatal' : '';
            $http_req->header('X-SS-Log-Level' => $level) if $level;
        }
    }
    $log->trace("parse request URI: module=$module, sub=$sub, opts=$opts");
}

1;
# ABSTRACT: Parse sub call request from HTTP request

=head1 SYNOPSIS

 # in your app.psgi
 use Plack::Builder;

 builder {
    enable "SubSpec::ParseRequest"
        #parse_args_from_path_info => 1,
        #parse_args_from_web_form => 1,
        #parse_args_from_body => 1,
        #accept_json => 1,
        #accept_yaml => 1,
        #accept_php => 1,
        #do_per_arg_decoding => 1,
    ;

    # enable other middlewares ...
 };


=head1 DESCRIPTION

This middleware parses sub call request from HTTP request (PSGI environment) and
should normally be the first middleware put in the stack.

The result of parsing should be put in these PSGI environment keys:

=over 4

=item * ss.request.module

The module name which contains the subroutine to call, a string scalar.

=item * ss.request.sub

The subroutine name to call, a string scalar.

=item * ss.request.args

The call arguments, hashref.

=item * ss.request.options

Call options. A hashref with the following known keys:

=over 4

=item * type => STR 'call'/'usage'/'spec' (default 'call')

Specify request type. 'call' is the default, meaning a request to call the
subroutine and return the result. 'usage' requests help/usage information
instead. 'spec' requests sub spec instead.

=item * log_level => INT 0 to 6 or STR (default 0)

Specify log level. If set to values larger than 0, when calling the subroutine,
log messages produced by L<Log::Any> will be passed to the HTTP client. The
number specifies log level: 0 is none, 1 fatal, 2 error, 3 warn, 4 info, 5
debug, 6 trace]. Alternatively, the string "fatal", "error", etc can be used
instead.

=item * output_format => STR 'yaml'/'json'/'php'/'pretty'/'nopretty'/'html' (default 'json' or 'pretty' or 'html')

Specify preferred output format. The default is 'json', or 'html' if User-Agent
is detected as a GUI browser, or 'pretty' is User-Agent header is a text browser
or command-line client (this detection is done by
L<Plack::Middleware::SubSpec::FormatOutput>).

Pretty-printing is done with one of L<Data::Format::Pretty>'s formatter modules.

=back

=back

The next section describes how this middleware parses sub request; the default
behaviour is rather flexible and should accomodate common needs. If your need is
not met, however, you can write your own sub request parser middleware. Just
remember the abovementioned PSGI environment keys that need to be produced.

=head2 How sub request is parsed by Plack::Middleware::SubSpec::ParseRequest

This middleware can extract module name and sub name from request URI, sub
arguments from URI/request body, call options from URI/request headers.

First it copies C<REQUEST_URI> $env key to C<ss.temp.request_uri> so that
request URI can be modified without ruining C<REQUEST_URI> for other
middlewares.

It then checks if C<before_parse> configuration is set. If so, it will call the
code specified in C<before_parse> (passing $env as argument) to give a chance to
modify/preprocess C<ss.temp.request_uri> or other data.

After that, it will expect request URI to be in the form of:

 /MODULE/SUBMODULE/FUNCTION?ARG=VAL&ARG2=VAL&...

or if C<module> configuration is set, the form of:

 /FUNCTION/ARG/ARG2/...;SHORT_OPTS?MOREARG=VAL&...

or if C<module> and C<sub> is set, the form of:

 /ARG/ARG2/...;SHORT_OPTS?MOREARG=VAL&...

Otherwise, a 400 response will be returned.

MODULE/SUBMODULE is module name, the slashes will be replaced by "::"'s. For
example, Foo/Bar will become Foo::Bar in ss.request.module.

ARGS are sub arguments. Arguments will be parsed from request URI if C<module>
and C<parse_args_from_path_info> is set, or they will be parsed from request
body (if C<parse_args_from_body> is true), or from GET/POST request variables
(if C<parse_args_from_web_form> is true).

SHORT_OPTS are a sequence of one or more letters, specifying request options:

=over 4

=item * C<h> (for "help") means setting option C<type> to C<usage>.

=item * C<y> means setting option C<output_format> to C<yaml>.

=item * C<j> means setting option C<output_format> to C<json>.

=item * C<p> means setting option C<output_format> to C<php>.

=item * C<r> means setting option C<output_format> to C<>.

if (length($opts)) {
        if ($opts =~ /y/) {
            $http_req->header('Accept' => 'text/yaml');
        }
        if ($opts =~ /t/) {
            $http_req->header('Accept' => 'text/html');
        }
        if ($opts =~ /r/) {
            $http_req->header('Accept' => 'text/x-spanel-pretty');
        }
        if ($opts =~ /R/) {
            $http_req->header('Accept' => 'text/x-spanel-nopretty');
        }
        if ($opts =~ /j/) {
            $http_req->header('Accept' => 'application/json');
        }
        if ($opts =~ /p/) {
            $http_req->header('Accept' => 'application/vnd.php.serialized');
        }
        if ($opts =~ /[h?]/) {
            $req->{help}++;
            $http_req->header('Content-Type' => 'application/x-spanel-noargs');
        }

=item * C<

=back

To specify more options, you can use HTTP request headers, X-SS-<option-name>.
For example, C<X-SS-Log-Level> can be used to set C<log_level> option.


=head1 CONFIGURATIONS

=over 4

=item * module => STR (optional)

If specified, we are only exposing a single module, and thus request URI need
not contain module name at all.

=item * sub => STR (optional)

If specified, we are only exposing a single function from a single module, and
thus request URI need not contain the module name or sub name at all.

=item * allow_call_request => BOOL (default 1)

Whether to allow subroutine call, default is 1. Unless you want your API service
to only serve e.g. help/usage information or sub spec, you'd want to enable
this.

=item * allow_help_request => BOOL (default 1)

Whether to allow requests for help/usage information. You might want to turn
this off on some production servers.

=item * allow_spec_request => BOOL (default 1)

Whether to allow requests for sub spec. You might want to turn this off on some
production servers.

=item * allow_logs => BOOL (default 1)

Whether to allow request for returning log messages (request option 'log_level'
with value larger than 0). You might want to turn this off on production
servers.

=item * accept_json => BOOL (default 1)

Whether to accept JSON-encoded data (either in GET/POST request variables, etc).

=item * accept_php => BOOL (default 1)

Whether to accept PHP serialization-encoded data (either in GET/POST request
variables, etc). If you only want to deal with, say, JSON encoding, you might
want to turn this off.

=item * accept_yaml => BOOL (default 1)

Whether to accept YAML-encoded data (either in GET/POST request variables, etc).
If you only want to deal with, say, JSON encoding, you might want to turn this
off.

=item * allow_return_json => BOOL (default 1)

Whether we should comply when client requests JSON-encoded return data.

=item * allow_return_yaml => BOOL (default 1)

Whether we should comply when client requests YAML-encoded return data.

=item * allow_return_php => BOOL (default 1)

Whether we should comply when client requests PHP serialization-encoded return
data.

=item * per_arg_encoding => BOOL (default 1)

Whether we should allow each GET/POST request variable to be encoded, e.g.
http://foo?arg1:j=%5B1,2,3%5D ({arg1=>[1, 2, 3]}).

=item * before_parse => CODE

If specified, the code will be called with $env as the argument. It can modify
C<ss.temp.request_uri> in $env, for example if your API URL format is:

 /api/v1/MODULE/FUNC

then you can supply this code in C<before_parse>:

 sub {
     my $env = shift;
     return unless $env->{"ss.temp.request_uri"};
     $env->{"ss.temp.request_uri"} =~ s!^/api/v1/!/!;
 }

so that ParseRequest can parse module name and sub name from
C<ss.temp.request_uri>.

=back


=head1 SEE ALSO

L<Sub::Spec::HTTP::Client>

=cut
