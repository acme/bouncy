package Bouncy::Sprite::Score;
use Moose;
use MooseX::StrictConstructor;
extends 'Bouncy::Sprite';

has 'font' => ( is => 'ro', isa => 'SDL::TTF_Font', required => 1 );
has 'text' => ( is => 'rw', isa => 'Str',           required => 1 );
has 'x'    => ( is => 'ro', isa => 'Int',           required => 1 );
has 'y'    => ( is => 'ro', isa => 'Int',           required => 1 );

has 'last_text' => ( is => 'rw', isa => 'Str', default => '' );
has 'last_rect' => ( is => 'rw', isa => 'SDL::Rect' );

__PACKAGE__->meta->make_immutable;

sub draw {
    my $self      = shift;
    my $text      = $self->text;
    my $last_text = $self->last_text;
    return if $text eq $last_text;

    my $foreground = $self->foreground;
    my $background = $self->background;
    my $font       = $self->font;

    my $x = $self->x;
    my $y = $self->y;

    my $last_rect = $self->last_rect;
    my @updates;

    if ($last_rect) {
        SDL::Video::blit_surface( $background, $last_rect, $foreground,
            $last_rect );
        push @updates, $last_rect;
    }

    my ( $fps_width, $fps_height ) = @{ SDL::TTF_SizeText( $font, $text ) };
    my $rect = SDL::Rect->new( 0, $y, $fps_width, $fps_height );
    my $surface = SDL::TTF_RenderText_Blended( $font, $text,
        SDL::Color->new( 0, 0, 0 ) );
    SDL::Video::blit_surface( $surface,
        SDL::Rect->new( 0, 0, $surface->w, $surface->h ),
        $foreground, $rect );

    $self->last_text($text);
    $self->last_rect($rect);

    push @updates, $rect;
    return @updates;
}

1;
