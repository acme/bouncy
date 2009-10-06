#!/usr/bin/env perl 
use strict;
use warnings;
use lib 'lib';
use SDL;
use SDL::App;
use SDL::Event;
use SDL::Surface;
use SDL::Color;
use SDL::Rect;
use Bouncy::Brick;

my $screen_width  = 640;
my $screen_height = 480;

my $app = SDL::App->new(
    -width  => 640,
    -height => 480,
    -flags  => SDL_ANYFORMAT | SDL_HWACCEL
        | SDL_RLEACCEL,    # SDL_HWACCEL SDL_DOUBLEBUF SDL_ANYFORMAT
);

my $app_rect = SDL::Rect->new(
    -height => $screen_height,
    -width  => $screen_width,
);

my $background = $SDL::Color::yellow;

my $ball = SDL::Surface->new( -name => 'ball2.png' );
$ball->display_format();
my $ball_rect = SDL::Rect->new(
    -x      => 0,
    -y      => 0,
    -width  => $ball->width,
    -height => $ball->height,
);

my $brick = SDL::Surface->new( -name => 'red.png' );
$brick->display_format();
my $brick_rect = SDL::Rect->new(
    -x      => 0,
    -y      => 0,
    -width  => $brick->width,
    -height => $brick->height,
);
Bouncy::Brick->surface($brick);
Bouncy::Brick->rect($brick_rect);

my @bricks = (
    Bouncy::Brick->new( x => 0,   y => 100 ),
    Bouncy::Brick->new( x => 64,  y => 100 ),
    Bouncy::Brick->new( x => 128, y => 100 ),
    Bouncy::Brick->new( x => 0,   y => 132 ),
    Bouncy::Brick->new( x => 64,  y => 132 ),
    Bouncy::Brick->new( x => 128, y => 132 ),
    Bouncy::Brick->new( x => 0,   y => 164 ),
    Bouncy::Brick->new( x => 0,   y => 196 ),
    Bouncy::Brick->new( x => 0,   y => 228 ),
    Bouncy::Brick->new( x => 0,   y => 260 ),
    Bouncy::Brick->new( x => 0,   y => 292 ),
    Bouncy::Brick->new( x => 0,   y => 324 ),
    Bouncy::Brick->new( x => 576, y => 164 ),
    Bouncy::Brick->new( x => 576, y => 196 ),
    Bouncy::Brick->new( x => 576, y => 228 ),
    Bouncy::Brick->new( x => 576, y => 260 ),
    Bouncy::Brick->new( x => 576, y => 292 ),
    Bouncy::Brick->new( x => 576, y => 324 ),
);

my $bat = SDL::Surface->new( -name => 'bat.png' );
$bat->display_format();
my $bat_rect = SDL::Rect->new(
    -x      => 0,
    -y      => 0,
    -width  => $bat->width,
    -height => $bat->height,
);

my $event = SDL::Event->new();

sub put_sprite {
    my ( $x, $y, $source, $source_rect ) = @_;

    my $dest_rect = SDL::Rect->new(
        -x      => $x,
        -y      => $y,
        -width  => $source->width,
        -height => $source->height,
    );
    $source->blit( $source_rect, $app, $dest_rect );
}

my $bat_x = 100;
my $bat_y = $screen_height - $bat->height;
my ( $x, $y ) = ( $bat_x + 54, $bat_y );

my $dx = 0.2;
my $dy = -1.25;
my @xs = ($x);
my @ys = ($y);

SDL::ShowCursor(0);

while (1) {

    # process event queue
    $event->pump;
    $event->poll;
    my $etype = $event->type;

    # handle user events
    last if ( $etype eq SDL_QUIT );
    last if ( SDL::GetKeyState(SDLK_ESCAPE) );
    last if ( $etype eq SDL_KEYDOWN );

    if ( $etype eq SDL_MOUSEBUTTONDOWN ) {
        $x  = $bat_x + $bat->width / 3;
        $y  = $bat_y;
        $dx = 0.2;
        $dy = -1.25;
    }
    if ( $etype eq SDL_MOUSEMOTION ) {
        $bat_x = $event->motion_x - 56;
        $bat_x = 0 if $bat_x < 0;
        $bat_x = $screen_width - 112 if $bat_x + 112 > $screen_width;
    }

    $app->fill( $app_rect, $background );

    SDL::GFXAalineRGBA(
        $$app, $x,
        $y - $ball->height / 2,
        $xs[0] + $ball->width / 2,
        $ys[0] - $ball->height / 2,
        0, 127, 127, 255
    );
    SDL::GFXAalineRGBA(
        $$app,
        $x + $ball->width,
        $y - $ball->height / 2,
        $xs[0] + $ball->width / 2,
        $ys[0] - $ball->height / 2,
        0, 127, 127, 255
    );

    put_sprite( $x,     $y - $ball->height, $ball, $ball_rect );
    put_sprite( $bat_x, $bat_y,             $bat,  $bat_rect );

    foreach my $brick (@bricks) {
        put_sprite( $brick->x, $brick->y, $brick->surface, $brick->rect )
            if $brick->visible;
    }

    push @xs, $x;
    push @ys, $y;

    if ( @xs > 80 ) {
        shift @xs;
        shift @ys;
    }

    $x += $dx;
    if ( $x + $ball->width > $screen_width ) {
        $dx = $dx * -0.9;
        $dy = $dy * 0.9;
        $x += $dx;
    }
    if ( $x < 0 ) {
        $dx = $dx * -0.9;
        $dy = $dy * 0.9;
        $x += $dx;
    }

    $y  += $dy;
    $dy += 0.002;
    if ( ( $x + $ball->width / 2 > $bat_x && $x < $bat_x + 108 )
        && $y > $screen_height - $bat->height + 5 )
    {
        $dy = -1.25;
        $dx = 0.3 * $dx + ( $x + $ball->width / 2 - $bat_x - 56 ) / 100;
        $y += $dy;
    } elsif ( $y > $screen_height ) {
        $dy = $dy * -0.7;
        $dx = $dx * 0.7;
        $y += $dy;
    }
    if ( $y - $ball->height < 0 ) {
        $dy = $dy * -1.1;
        $dx = $dx * 0.9;
        $y += $dy;
    }

    foreach my $brick (@bricks) {
        next unless $brick->visible;
        if (   $x > $brick->x - $ball->width
            && $x < $brick->x + $brick->w
            && $y > $brick->y
            && $y < $brick->y + $brick->h + $ball->height )
        {
            if (   $ys[-1] > $brick->y
                && $ys[-1] < $brick->y + $brick->h + $ball->height )
            {
                $dx = $dx * -0.9;
                $x += $dx;
            } else {
                $dy = $dy * -0.9;
                $y += $dy;
            }
            $brick->visible(0);
            last;
        }
    }

    $app->sync;
}

SDL::ShowCursor(1);
