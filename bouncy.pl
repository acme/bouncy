#!/usr/bin/env perl 
use strict;
use warnings;
use SDL;
use SDL::App;
use SDL::Event;
use SDL::Surface;
use SDL::Color;
use SDL::Rect;

my $screen_width  = 640;
my $screen_height = 480;

my $app = SDL::App->new(
    -width  => 640,
    -height => 480,
    -icon   => 'ball.png',
    -flags  => SDL_ANYFORMAT | SDL_HWACCEL
        | SDL_RLEACCEL,    # SDL_HWACCEL SDL_DOUBLEBUF SDL_ANYFORMAT
);

my $app_rect = SDL::Rect->new(
    -height => $screen_height,
    -width  => $screen_width,
);

my $background = $SDL::Color::black;

my $ball = SDL::Surface->new( -name => "ball.png" );
$ball->display_format();
my $ball_rect = SDL::Rect->new(
    -x      => 0,
    -y      => 0,
    -width  => $ball->width,
    -height => $ball->height,
);
my $event = SDL::Event->new();

sub put_sprite {
    my ( $x, $y ) = @_;

    my $dest_rect = SDL::Rect->new(
        -x => $x - ( $ball->width / 2 ),
        -y => $y - ( $ball->height / 2 ),
        -width  => $ball->width,
        -height => $ball->height,
    );
    $ball->blit( $ball_rect, $app, $dest_rect );
}

my ( $x, $y ) = ( $screen_width / 2, $screen_height / 2 );
my $dx = 1;
my $dy = 0;
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
        $x  = $event->button_x;
        $y  = $event->button_y;
        $dx = 1;
        $dy = -1;
    }

    $app->fill( $app_rect, $background );
    put_sprite( $x, $y );

    $x += $dx;
    if ( $x + $ball->width / 2 > $screen_width ) {
        $dx = $dx * -0.9;
        $dy = $dy * 0.9;
        $x += $dx;
    }
    if ( $x - $ball->width / 2 < 0 ) {
        $dx = $dx * -0.9;
        $dy = $dy * 0.9;
        $x += $dx;
    }

    $y  += $dy;
    $dy += 0.002;
    if ( $y + $ball->height / 2 > $screen_height ) {
        $dy = $dy * -0.9;
        $dx = $dx * 0.9;
        $y += $dy;
    }
    if ( $y - $ball->height / 2 < 0 ) {
        $dy = $dy * -1.1;
        $dx = $dx * 0.9;
        $y += $dy;
    }
    $app->sync;
}

