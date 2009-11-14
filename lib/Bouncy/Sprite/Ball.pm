package Bouncy::Sprite::Ball;
use Moose;
use MooseX::StrictConstructor;
extends 'Bouncy::Sprite';

has 'surface' => ( is => 'ro', isa => 'SDL::Surface', required => 1 );
has 'x'    => ( is => 'rw', isa => 'Num',           required => 1 );
has 'y'    => ( is => 'rw', isa => 'Num',           required => 1 );

has 'last_rect' => ( is => 'rw', isa => 'SDL::Rect' );

__PACKAGE__->meta->make_immutable;

sub draw {
    my $self      = shift;

    my $surface = $self->surface;
    my $foreground = $self->foreground;
    my $background = $self->background;

    my $x = $self->x;
    my $y = $self->y;

    my $last_rect = $self->last_rect;
    my @updates;

    if ($last_rect) {
        SDL::Video::blit_surface( $background, $last_rect, $foreground,
            $last_rect );
        push @updates, $last_rect;
    }

    my $rect = SDL::Rect->new( $x, $y, $surface->w, $surface->h );

    SDL::Video::blit_surface( $surface,
        SDL::Rect->new( 0, 0, $surface->w, $surface->h ),
        $foreground, $rect );

    $self->last_rect($rect);

    push @updates, $rect;
    return @updates;
}

1;
