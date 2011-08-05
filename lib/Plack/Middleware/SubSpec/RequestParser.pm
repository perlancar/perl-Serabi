package Plack::Middleware::SubSpec::RequestParser;

# VERSION

1;
# ABSTRACT:
__END__

X-SS-Log-Level
X-SS-Mark-Chunked


sub get_sub_name {
    my ($self) = @_;
    my $req = $self->req;
    my $http_req = $req->{http_req};

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

    # parse opts
    $opts //= "";
    if (length($opts)) {
        if ($opts =~ /0/) {
            $http_req->header('Content-Type' => 'application/x-spanel-noargs');
        }
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


