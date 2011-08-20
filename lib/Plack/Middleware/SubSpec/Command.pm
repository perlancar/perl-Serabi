package Plack::Middleware::SubSpec::Command;

use 5.010;
use strict;
use warnings;

use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw(
                                default_output_format
                                allowable_output_formats
                                time_limit
                        );

# VERSION

sub prepare_app {
    my $self = shift;
    $self->{allowable_output_formats} //= [qw/html json php yaml/];
}

sub _pick_default_format {
    my ($self, $env) = @_;
    # if client is a GUI browser, choose html. otherwise, json.
    my $ua = $env->{HTTP_USER_AGENT} // "";
    return "html" if $ua =~ m!Mozilla/|Opera/!;
    # mozilla already includes ff, chrome, safari, msie
    "json";
}

sub format_json {
    my ($self, $sub_res) = @_;
    require Data::Format::Pretty::JSON;
    return (Data::Format::Pretty::JSON::format_pretty($sub_res, {pretty=>0}),
            "application/json");
}

sub format_yaml {
    my ($self, $sub_res) = @_;
    require Data::Format::Pretty::YAML;
    return (Data::Format::Pretty::YAML::format_pretty($sub_res),
            "text/yaml");
}

sub format_php {
    my ($self, $sub_res) = @_;
    require Data::Format::Pretty::PHP;
    return (Data::Format::Pretty::PHP::format_pretty($sub_res),
            "application/vnd.php.serialized");
}

sub format_html {
    my ($self, $sub_res) = @_;
    require Data::Format::Pretty::HTML;
    return (Data::Format::Pretty::HTML::format_pretty($sub_res),
            "text/html");
}

sub call {
    my ($self, $env) = @_;

    my $mycmd = ref($self); $mycmd =~ s/.+:://
    return $self->app->($env) unless
        $env->{'ss.request.opts'}{command} eq $mycmd;

    die "This middleware needs psgi.streaming support"
        unless $env->{'psgi.streaming'};

    my $opts = $env->{'ss.request.opts'};
    my $ofmt = $opts->{output_format} // $self->default_output_format
        // $self->_pick_default_format($env);
    return errpage("Unknown output format: $ofmt")
        unless $ofmt =~ /^\w+/ && $self->can("format_$ofmt");
    return errpage("Output format $ofmt not allowed")
        unless grep {$_ eq $ofmt} @{$self->allowable_output_formats};

    return sub {
        my $respond = shift;

        my $exec_command = sub {
            my $time_limit = $self->time_limit // 0;
            if (ref($time_limit) eq 'CODE') {
                $time_limit = $time_limit->($self, $env) // 0;
            }
            $time_limit += 0;

            my $cmd_res;
            eval {
                local $SIG{ALRM} = sub { die "Timed out\n" };
                alarm $time_limit;
                $env->{'ss.start_command_time'} = [gettimeofday];
                $cmd_res = $self->exec_command($env);
                $env->{'ss.finish_command_time'} = [gettimeofday];
            };
            alarm 0;
            $cmd_res // [500,
                         $@ ? ($@ =~ /Timed out/ ?
                                   "Execution timed out" :
                                       "Exception: $@") : "BUG"];
        };

        my $writer;
        my $loglvl  = $opts->{'log_level'};
        my $marklog = $opts->{'mark_log'};
        my $sub_res;
        if ($loglvl) {
            unless ($loglvl =~ /\A(?:fatal|error|warn|info|debug|trace)\z/i) {
                $respond->(errpage("Unknown log level"));
                return;
            }
            $writer = $respond->([200, ["Content-Type" => "text/plain"]]);
            Log::Any::Adapter->set(
                {lexically=>\my $lex},
                "Callback",
                logging_cb => sub {
                    my ($method, $self, $format, @params) = @_;
                    my $msg = join(
                        "",
                        $marklog ? "L" : "",
                        "[$method]",
                        "[", scalar(localtime), "] ",
                        $format, "\n");
                    $writer->write($msg);
                },
            );
            $sub_res = $call_sub->();
        } else {
            $sub_res = $call_sub->();
        }

        $env->{'ss.command_executed'} = 1;
        $env->{'ss.response'} = $sub_res;

        my $fmt_method = "format_$ofmt";
        my ($res, $ct) = $self->$fmt_method($sub_res);

        if ($writer) {
            $writer->write($marklog ? "R$res" : $res);
            $writer->close;
        } else {
            $respond->([200, ["Content-Type" => $ct], [$res]]);
        }
    };
}

1;
# ABSTRACT: Base class for command handler

=head1 SYNOPSIS


=head1 DESCRIPTION

This module is a base class for command handlers
(Plack::Middleware::SubSpec::Command::* middlewares).


=head1 CONFIGURATIONS

=over 4

=item * default_output_format => STR, default 'json'

The default format to use if client does not specify 'output_format' request
option.

If unspecified, some detection logic will be done to determine default format:
if client is a GUI browser, 'html'; otherwise, 'json'.

=item * allowable_output_formats => ARRAY (default [qw/html json php yaml/])

Specify what output formats are allowed. When client requests an unallowed
format, 400 error is returned.

=item * time_limit => INT | CODE

Impose time limit, using alarm(). If coderef is given, it will be called for
every request with ($self, $env) argument and expected to return the time limit.

=back

=cut
