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

my $sprite = SDL::Surface->new( -name => "ball.png" );
$sprite->display_format();
my $sprite_rect = SDL::Rect->new(
    -x      => 0,
    -y      => 0,
    -width  => $sprite->width,
    -height => $sprite->height,
);
my $event = SDL::Event->new();

sub put_sprite {
    my ( $x, $y ) = @_;

    my $dest_rect = SDL::Rect->new(
        -x => $x - ( $sprite->width / 2 ),
        -y => $y - ( $sprite->height / 2 ),
        -width  => $sprite->width,
        -height => $sprite->height,
    );
    $sprite->blit( $sprite_rect, $app, $dest_rect );
}

my $i = 0;
while (1) {

    # process event queue
    $event->pump;
    $event->poll;
    my $etype = $event->type;

    # handle user events
    last if ( $etype eq SDL_QUIT );
    last if ( SDL::GetKeyState(SDLK_ESCAPE) );
    last if ( $etype eq SDL_KEYDOWN );

    $app->fill( $app_rect, $background );

    my $delta = 40;
    my $x     = 0;
    foreach ( 1 .. 16 ) {
        put_sprite(
            $x + sin( $i + $_ / 2 ) * $_,
            $screen_height / 2
                + ( sin( ( $i + $_ ) * 0.2 ) * ( $screen_height / 3 ) )
        );
        $x += $delta;
    }
    $i += 0.05;

    $app->sync;
}

