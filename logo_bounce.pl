#!/usr/bin/env perl 
use strict;
use warnings;
use lib 'lib';
use Bouncy::FPS;
use SDL;
use SDL::App;
use SDL::Color;
use SDL::Event;
use SDL::Events;
use SDL::Image;
use SDL::Mixer;
use SDL::Rect;
use SDL::Surface;
use SDL::TTF_Font;
use SDL::Video;

my $screen_width  = 960;
my $screen_height = 600;

my $app = SDL::App->new(
    -width  => $screen_width,
    -height => $screen_height,

    # -flags  => SDL_FULLSCREEN,
);

my $app_rect = SDL::Rect->new( 0, 0, $screen_width, $screen_height );

my $app_pixel_format = $app->format;
my $white_pixel = SDL::Video::map_RGB( $app_pixel_format, 255, 255, 255 );

my $image = SDL::Video::display_format( SDL::Image::load('logo.png') );

SDL::Video::fill_rect( $app,
    SDL::Rect->new( 0, 0, $screen_width, $screen_height ), $white_pixel );

SDL::Video::update_rect( $app, 0, 0, $app->w, $app->h );

my @y_offsets;
foreach my $i ( 0 .. 400 ) {
    push @y_offsets, 200 - sin( $i * 3.141596 / 400 ) * 50;
}

my $event = SDL::Event->new();

my $fps = Bouncy::FPS->new( max_fps => 300 );

my $step   = 1;
my $degree = 0;
while (1) {
    $fps->frame;

    while (1) {
        SDL::Events::pump_events();
        last unless SDL::Events::poll_event($event);

        if ( $event->type == SDL_KEYDOWN ) {
            exit;
        }
    }

    SDL::Video::fill_rect( $app,
        SDL::Rect->new( 200, 150, $image->w, $image->h + 50 ), $white_pixel );

    my $x = 0;
    while ( $x < $image->w ) {
        SDL::Video::blit_surface(
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
    SDL::Video::update_rect( $app, 200, 150, $image->w, $image->h + 50 );
    $degree += $fps->last_frame_seconds * 100;
}
