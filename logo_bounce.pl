#!/usr/bin/env perl 
use strict;
use warnings;
use SDL;
use SDL::App;
use SDL::Color;
use SDL::Event;
use SDL::Mixer;
use SDL::Rect;
use SDL::Surface;
use SDL::TTF_Font;

my $screen_width  = 960;
my $screen_height = 600;

my $app = SDL::App->new(
    -width  => $screen_width,
    -height => $screen_height,

    # -flags  => SDL_FULLSCREEN,
);

my $app_rect = SDL::Rect->new( 0, 0, $screen_width, $screen_height );

my $app_pixel_format = $app->format;
my $white_pixel = SDL::MapRGB( $app_pixel_format, 255, 255, 255 );

SDL::TTF_Init();

my $image = SDL::DisplayFormat( SDL::IMG_Load('logo.png') );

SDL::FillRect( $app, SDL::Rect->new( 0, 0, $screen_width, $screen_height ),
    $white_pixel );

SDL::UpdateRect( $app, 0, 0, $app->w, $app->h );

my @y_offsets;
foreach my $i ( 0 .. 400 ) {
    push @y_offsets, 200 - sin( $i * 3.141596 / 400 ) * 50;
}

my $event = SDL::Event->new();

my $step   = 1;
my $degree = 0;
while (1) {

    # process event queue
    $event->pump;

    # handle user events
    $event->pump;
    while ( $event->poll() ) {
        my $etype = $event->type;

        exit if ( $etype eq SDL_QUIT );
        exit if ( SDL::GetKeyState(SDLK_ESCAPE) );
        exit if ( $etype eq SDL_KEYDOWN );
    }

    my $x = 0;
    while ( $x < $image->w ) {

        SDL::BlitSurface(
            $image,
            SDL::Rect->new( $x, 0, $step, $image->h ),
            $app,
            SDL::Rect->new(
                200 + $x, $y_offsets[ ( $degree * 4 + $x / 2 ) % 400 ],
                $step, $image->h
            )
        );
        $x += $step;
    }
    SDL::UpdateRect( $app, 200, 150, $image->w, $image->h + 50 );
    $degree++;
}
