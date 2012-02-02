=begin comment

This is a (PSGI middleware? PSGI app?) to create REST-style service while still
utilizing Rinci/Riap.

Alternative to Riap::HTTP / Perinci::Access::HTTP::Server (or use some parts of
Perinci::Access::HTTP::Server or its Plack::Middleware::Perinci::)?

You define resources and map verbs to Riap functions, e.g.:

 resources => {
     "/user" => {
         # /user/123 automatically maps to?
         id_parameter => 'id',
         verbs => [
             "GET \d+" => {riap => "/My/App/User/get_users"},
             "GET"     => {riap => "/My/App/User/list_users"},
         ]
     },
 }

(or create some DSL for this, examples abound in various library like
django-tastypie, etc). search also for RESTful rails, etc.

=end comment
