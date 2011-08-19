=head2 $server->access_log()

Log request. The default implementation logs like this (all in one line):

 [Fri Feb 18 22:05:38 2011] "GET /v1/MyModule/my_func;j?arg1=1&arg2=2"
 [127.0.0.1:949] [-] [mod MyModule] [sub my_func]
 [args 14 {"name":"val"}] [resp 12 [200,"OK",1]] [subt 2.123ms] [reqt 5.947ms]

where subt is time spent in the subroutine, and reqt is time spent for the whole
request (from connect until response is sent, which includes reqt).

=cut

sub access_log {
    my ($self) = @_;
    my $req = $self->req;
    my $http_req = $req->{http_req};
    my $resp = $self->resp;

    my $fmt = join(
        "",
        "[%s] ", # time
        "[%s] ", # from
        "\"%s %s\" ", # HTTP method & URI
        "[user %s] ",
        "[mod %s] [sub %s] [args %s %s] ",
        "[resp %s %s] [subt %s] [reqt %s]",
        "%s", # extra info
        "\n"
    );
    my $from;
    if ($req->{proto} eq 'tcp') {
        $from = $req->{remote_ip} . ":" .
            ($req->{https} ? $self->https_port : $self->http_port);
    } else {
        $from = "unix";
    }

    my $args_s = $json->encode($self->{sub_args} // "");
    my $args_len = length($args_s);
    my $args_partial = $args_len > $self->access_log_max_args_len;
    $args_s = substr($args_s, 0, $self->access_log_max_args_len)
        if $args_partial;

    my ($resp_s, $resp_len, $resp_partial);
    if ($req->{access_log_mute_resp}) {
        $resp_s = "*";
        $resp_partial = 0;
        $resp_len = "*";
    } else {
        $resp_s = $json->encode($self->resp // "");
        $resp_len = length($resp_s);
        $resp_partial = $resp_len > $self->access_log_max_resp_len;
        $resp_s = substr($resp_s, 0, $self->access_log_max_resp_len)
            if $resp_partial;
    }

    my $logline = sprintf(
        $fmt,
        scalar(localtime $req->{time_connect}[0]),
        $from,
        $http_req->method, $http_req->uri,
        $req->{auth_user} // "-",
        $req->{sub_module} // "-", $req->{sub_name} // "-",
        $args_len.($args_partial ? "p" : ""), $args_s,
        $resp_len.($resp_partial ? "p" : ""), $resp_s,
        (!defined($req->{time_call_start}) ? "-" :
             !defined($req->{time_call_end}) ? "D" :
                 sprintf("%.3fms",
                         1000*tv_interval($req->{time_call_start},
                                          $req->{time_call_end}))),
        sprintf("%.3fms",
                1000*tv_interval($req->{time_connect},
                                 $req->{time_finish_response})),
        keys(%{$req->{log_extra}}) ? " ".$json->encode($req->{log_extra}) : "",
    );

    if ($self->_daemon->{daemonized}) {
        #warn "Printing to access log $daemon->{_access_log}: $logline";
        # XXX rotating?
        syswrite($self->_daemon->{_access_log}, $logline);
    } else {
        warn $logline;
    }
}

