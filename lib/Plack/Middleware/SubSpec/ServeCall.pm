    $self->{allow_return_json} //= 1;
    $self->{allow_return_yaml} //= 1;
    $self->{allow_return_php}  //= 1;

=item * allow_return_json => BOOL (default 1)

Whether we should comply when client requests JSON-encoded return data.

=item * allow_return_yaml => BOOL (default 1)

Whether we should comply when client requests YAML-encoded return data.

=item * allow_return_php => BOOL (default 1)

Whether we should comply when client requests PHP serialization-encoded return
data.

