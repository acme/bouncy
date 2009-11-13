package Bouncy::Sprite;
use Moose;
use MooseX::StrictConstructor;

has 'foreground' => (
    is       => 'ro',
    isa      => 'SDL::Surface',
    required => 1,
);
has 'background' => (
    is       => 'ro',
    isa      => 'SDL::Surface',
    required => 1,
);

__PACKAGE__->meta->make_immutable;

1;
