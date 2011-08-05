        $self->_daemon->update_scoreboard({state => "W"});
        if ($req->{chunked}) {
            # if client specified logging, we temporarily divert Log::Any logs
            # to the client via chunked response
            $self->_start_chunked_http_response();
            Log::Any::Adapter->set(
                {lexically=>\my $lex},
                "Callback",
                logging_cb => sub {
                    my ($method, $self, $format, @params) = @_;
                    my $msg = join(
                        "",
                        $req->{mark_chunk} ? "L" : "",
                        "[$method]",
                        "[", scalar(localtime), "] ",
                        $format, "\n");
                    $req->{sock}->print(
                        sprintf("%02x\r\n", length($msg)),
                        $msg, "\r\n");
                    # this seems needed?
                    $req->{sock}->flush();
                    # XXX also log to the previous adapter
                },
            );
            $self->call_sub();
        } else {
            # otherwise, logs will be sent to default location (set by
            # Spanel::Log)
            $self->call_sub();
        }
    };
    my $eval_err = $@;
    if ($eval_err) {
        $log->debug("Child died: $eval_err")
            unless $eval_err =~ /^Died at .+ line \d+\.$/; # deliberate die
        $self->resp([500, "Died when processing request: $eval_err"])
            unless $self->resp;
    }
    $self->resp([500, "BUG: response not set"]) if !$self->resp;

    eval { $self->send_http_response() };
    $eval_err = $@;
    $log->debug("Child died when sending response: $eval_err") if $eval_err;

    $req->{time_finish_response} = [gettimeofday];
    $self->access_log();
}

