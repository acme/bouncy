package Bouncy::Brick;
use Moose;
use MooseX::ClassAttribute;
use MooseX::StrictConstructor;

has 'x'        => ( is => 'ro', isa => 'Int', required => 1 );
has 'y'        => ( is => 'ro', isa => 'Int', required => 1 );
has 'strength' => ( is => 'rw', isa => 'Int', required => 1, default => 1 );
has 'screen_rect' => ( is => 'rw', isa => 'SDL::Rect', required => 1 );
has 'surface' => (
    is       => 'ro',
    isa      => 'SDL::Surface',
    required => 1,
);
class_has 'w' => (
    is      => 'ro',
    isa     => 'Int',
    default => 64,
);
class_has 'h' => (
    is      => 'ro',
    isa     => 'Int',
    default => 32,
);
class_has 'rect' => (
    is  => 'rw',
    isa => 'SDL::Rect',
);

__PACKAGE__->meta->make_immutable;

1;
