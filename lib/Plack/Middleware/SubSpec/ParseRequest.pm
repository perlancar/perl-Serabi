package Plack::Middleware::SubSpec::ParseRequest;

use 5.010;
use strict;
use warnings;

use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw(
                                uri_pattern
                                allowable_commands
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
                                after_parse
                        );

use Plack::Util::SubSpec qw(errpage);
use URI::Escape;

# VERSION

sub prepare_app {
    my $self = shift;
    if (!defined($self->uri_pattern)) {
        die "Please configure uri_pattern";
    }

    $self->{allowable_commands} //= [qw/call help spec listsub listmod/];

    $self->{parse_args_from_web_form}  //= 1;
    $self->{parse_args_from_body}      //= 1;
    $self->{parse_args_from_path_info} //= 1;
    $self->{per_arg_encoding}          //= 1;

    $self->{accept_json} //= 1;
    $self->{accept_yaml} //= 1;
    $self->{accept_php}  //= 1;

    $self->{allow_logs} //= 1;
}

sub call {
    my ($self, $env) = @_;

    my $req_uri = $env->{REQUEST_URI};
    my $pat     = $self->uri_pattern;
    unless ($req_uri =~ s/$pat//) {
        return errpage("Bad URL (doesn't match uri_pattern)");
    }

    # parse module & sub
    my $module = $+{module};
    if ($module) {
        $module =~ s/[^A-Za-z0-9_]+/::/g;
        $env->{"ss.request.module"} = $module;
    }
    my $sub = $+{sub};
    if ($sub) {
        $sub =~ s/[^A-Za-z0-9_]+//g;
        $env->{"ss.request.sub"} = $sub;
    }

    # parse args
    my $req = Plack::Request->new($env);
    my $accept = $env->{HTTP_ACCEPT} // "";
  PARSE_ARGS:
    {
        if ($self->parse_args_from_body &&
                $accept =~ m!\A(?:
                                 application/vnd.php.serialized|
                                 application/json|
                                 text/yaml)\z!x) {
            my $args;
            my $body_fh = $req->body;
            my $body = join "", <$body_fh>;
            if ($accept eq 'application/vnd.php.serialized') {
                #$log->trace('Request is PHP serialized');
                return errpage("PHP serialized data unacceptable")
                    unless $self->accept_php;
                request PHP::Serialization;
                eval { $args = PHP::Serialization::unserialize($body) };
                return errpage("Invalid PHP serialized data in request body: ".
                                   "$@") if $@;
            } elsif ($accept eq 'text/yaml') {
                #$log->trace('Request is YAML');
                return errpage("YAML data unacceptable")
                    unless $self->accept_yaml;
                require YAML::Syck;
                eval { $args = YAML::Load($body) };
                return errpage("Invalid YAML in request body: $@")
                    if $@;
            } elsif ($accept eq 'application/json') {
                #$log->trace('Request is JSON');
                return errpage("JSON data unacceptable")
                    unless $self->accept_json;
                require JSON;
                my $json = JSON->new->allow_nonref;
                eval { $args = $json->decode($body) };
                return errpage("Invalid JSON in request body: $@")
                    if $@;
            }
            return errpage("Arguments must be hash (associative array)")
                unless ref($args) eq 'HASH';
            $env->{"ss.request.args"} = $args;
            last PARSE_ARGS;
        }

        $req_uri =~ s/\?.*//;
        $req_uri =~ s!^/!!;
        if (length($req_uri) && $self->parse_args_from_path_info) {
            my @argv = map {uri_unescape($_)} split m!/!, $req_uri;
            # we actually parse args after we have spec (in
            # Plack::Middleware::SubSpec::ParseArgsFromPathInfo)
            $env->{"ss.request.argv"} = \@argv;
        }

        if ($self->parse_args_from_web_form) {
            my $args = {};
            my $form = $req->parameters;
            while (my ($k, $v) = each %$form) {
                if ($k =~ /(.+):j$/) {
                    $k = $1;
                    #$log->trace("CGI parameter $k (json)=$v");
                    return errpage("JSON data unacceptable") unless
                        $self->accept_json;
                    require JSON;
                    my $json = JSON->new->allow_nonref;
                    eval { $v = $json->decode($v) };
                    return errpage("Invalid JSON in query parameter $k: $@")
                        if $@;
                    $args->{$k} = $v;
                } elsif ($k =~ /(.+):y$/) {
                    $k = $1;
                    #$log->trace("CGI parameter $k (yaml)=$v");
                    return errpage("YAML data unacceptable") unless
                        $self->accept_yaml;
                    require YAML::Syck;
                    eval { $v = YAML::Load($v) };
                    return errpage("Invalid YAML in query parameter $k: $@")
                        if $@;
                    $args->{$k} = $v;
                } elsif ($k =~ /(.+):p$/) {
                    $k = $1;
                    #$log->trace("PHP parameter $k (php)=$v");
                    return errpage("PHP serialized data unacceptable") unless
                        $self->accept_php;
                    require PHP::Serialization;
                    eval { $v = PHP::Serialization::unserialize($v) };
                    return errpage("Invalid PHP serialized data in ".
                                     "query parameter $k: $@") if $@;
                    $args->{$k} = $v;
                } else {
                    #$log->trace("CGI parameter $k=$v");
                    $args->{$k} = $v;
                }
            }
            $env->{"ss.request.args"} = $args;
            my $req = Plack::Request->new($env);
        }
    }

    # parse call options in http headers
    my $opts = {};
    for my $k (keys %$env) {
        next unless $k =~ /^HTTP_X_SS_OPT_(.+)/;
        my $h = lc $1;
        if ($h =~ /\A(?:command|log_level|output_format|mark_log)\z/x) {
            $opts->{$h} = $env->{$k};
        } else {
            return errpage("Invalid request option: $h");
        }
    }
    $opts->{command} //= "call";
    $env->{"ss.request.opts"} = $opts;

    # give app a chance to do more parsing
    $self->after_parse->($self, $env) if $self->after_parse;

    # checks
    return errpage("Setting log_level not allowed", 403)
        if !$self->allow_logs && $opts->{log_level};
    return errpage("Command $opts->{command} not allowed", 403)
        unless grep {$_ eq $opts->{command}} @{$self->allowable_commands};

    # continue to app
    $self->app->($env);
}

1;
# ABSTRACT: Parse sub call request from HTTP request

=head1 SYNOPSIS

 # in your app.psgi
 use Plack::Builder;

 builder {
     enable "SubSpec::ParseRequest"
         uri_pattern => m!^/api/v1/(?<module>[^?]+)?/?(?<sub>[^?/]+)?!,
         after_parse => sub {
             my $env = shift;
             for ($env->{"ss.request.module"}) {
                 last unless $_;
                 s!/!::!g;
                 $_ = "My::API::$_" unless /^My::API::/;
             }
         };

    # enable other middlewares ...
 };


=head1 DESCRIPTION

This middleware parses sub request information from HTTP request (PSGI
environment) and should normally be the first middleware put in the stack. It
parses module name and subroutine name from the URI, call arguments from
URI/request body, and call options from URI/HTTP headers.

=head2 Parsing result

The result of parsing will be put in 'ss.request' PSGI environment key.

=head2 Parsing process

First, B<uri_pattern> configuration is checked. It should contain a regex with
named captures and will be matched against request URI. For example:

 qr!^/api/v1/(?<module>[^?/]+)/(?<sub>[^?/]+)!

If URI doesn't match this regex, a 400 error response is returned.

The C<$+{module}> capture, after some processing (replacement of all nonalphanum
characters into "::") will be put into C<$env->{"ss.request.module"}>.

The C<$+{sub}> capture will be put into C<$env->{"ss.request.sub"}>.

After that, call arguments will be parsed from the rest of the URI, or from
query (GET) parameters, or from request body (POST).

B<From the rest of the URI>. For example, if URI is
C</api/v1/Module1.SubMod1/func1/a1/a2?a3=val&a4=val> then after B<uri_pattern>
is matched it will become C<"/a1/a2?a3=val&a4=val"> and
C<$env->{"ss.request.module"}> is C<Module1::SubMod1> and
C<$env->{"ss.request.sub"}> is C<func1>. /a1/a2 will be split into array ["a1",
"a2"] and processed with L<Sub::Spec::GetArgs::Array>. After that, query
parameters will be processed as follows:

Parameter name maps to sub argument name, but it can be suffixed with ":<CHAR>"
to mean that the parameter value is encoded. This allows client to send complex
data structure arguments. C<:j> means JSON-encoded, C<:y> means YAML-encoded,
and C<:p> means PHP-serialization-encoded. You can disable this argument
decoding by setting B<per_arg_encoding> configuration to false.

Finally, request options are parsed from HTTP request headers matching
X-SS-<option-name>. For example, C<X-SS-Log-Level> can be used to set
C<log_level> option. Unknown headers will simply be ignored.


=head1 CONFIGURATIONS

=over 4

=item * uri_pattern => REGEX

Regexp to match against URI, to extract module and sub name. Should contain
named captures for C<module>, C<sub>. If regexp doesn't match, a 400 error
response will be generated.

=item * allowable_commands => ARRAY (default [qw/call help spec listmod listsub/])

Which commands to allow. Default is all commands. If you want to disable certain
commands, exclude it from the list. In principle the most important command is
'call', while the others are just helpers.

=item * parse_args_from_web_form => BOOL (default 1)

Whether to parse arguments from web form (GET/POST parameters)

=item * parse_args_from_body => BOOL (default 1)

Whether to parse arguments from body (if document type is C<text/yaml>,
C<application/json>, or C<application/vnd.php.serialized>.

=item * parse_args_from_path_info => BOOL (default 0)

Whether to parse arguments from path info. Note that uri_pattern will first be
removed from URI before args are extracted. Also, parsing arguments from path
info (array form, C</arg0/arg1/...>) requires that we have the sub spec first.
So we need to execute the L<Plack::Middleware::SubSpec::LoadSpec> first. The
actual parsing is done by L<Plack::Middleware::SubSpec::ParseArgsFromPathInfo>
first.

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

=item * per_arg_encoding => BOOL (default 1)

Whether we should allow each GET/POST request variable to be encoded, e.g.
http://foo?arg1:j=%5B1,2,3%5D ({arg1=>[1, 2, 3]}).

=item * after_parse => CODE

If set, the specified code will be called with arguments ($self, $env) to allow
doing more parsing/checks.

=back


=head1 SEE ALSO

L<Sub::Spec::HTTP>

L<Sub::Spec::HTTP::Client>

=cut
