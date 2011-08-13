#!perl -Tw

use 5.010;
use strict;
use warnings;

use HTTP::Request::Common;
use Plack::Builder;
use Plack::Test;

test_psgi
    app => sub {
        # enable ...
        # enable ...
    },
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET "/api/Module1/sub1");
        my $res = $cb->($req);
        # like $res->content, qr/Hello World/;
    };

# XXX test with Gepok, test Gepok-specific variables (gepok.connect_time, etc)
