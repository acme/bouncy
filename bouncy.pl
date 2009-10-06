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
    -flags => SDL_ANYFORMAT | SDL_HWACCEL
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
        $dx = 1;
        $dy = -1.3;
    }
    if ( $etype eq SDL_MOUSEMOTION ) {
        $bat_x = $event->motion_x - 56;
        $bat_x = 0 if $bat_x < 0;
        $bat_x = $screen_width - 112 if $bat_x + 112 > $screen_width;
    }

    $app->fill( $app_rect, $background );
    put_sprite( $x,     $y - $ball->height, $ball, $ball_rect );
    put_sprite( $bat_x, $bat_y,             $bat,  $bat_rect );

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
        $dx = 0.5 * $dx + ( $x + $ball->width / 2 - $bat_x - 56 ) / 100;
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
    $app->sync;
}

