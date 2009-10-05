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

my $app = new SDL::App(
    -width  => 640,
    -height => 480,
    -icon   => 'ball.png',
    -flags  => SDL_ANYFORMAT | SDL_HWACCEL
        | SDL_RLEACCEL,    # SDL_HWACCEL SDL_DOUBLEBUF SDL_ANYFORMAT
);

my $app_rect = new SDL::Rect(
    -height => $screen_height,
    -width  => $screen_width,
);

my $background = $SDL::Color::black;

my $sprite = new SDL::Surface( -name => "ball.png" );
$sprite->display_format();
my $sprite_rect = new SDL::Rect(
    -x      => 0,
    -y      => 0,
    -width  => $sprite->width,
    -height => $sprite->height,
);
my $event = new SDL::Event();

## User tweakable settings (via cmd-line)
my %settings = (
    'numsprites'    => 20,
    'screen_width'  => 640,
    'screen_height' => 480,

    #    'screen_width'  => 1366,
    #    'screen_height' => 768,
    'video_bpp'  => 8,
    'fast'       => 0,
    'hw'         => 0,
    'flip'       => 1,
    'fullscreen' => 0,
    'bpp'        => undef,
);

## Prints diagnostics

sub instruments {
    if ( ( $app->flags & SDL_HWSURFACE ) == SDL_HWSURFACE ) {
        printf("Screen is in video memory\n");
    } else {
        printf("Screen is in system memory\n");
    }

    if ( ( $app->flags & SDL_DOUBLEBUF ) == SDL_DOUBLEBUF ) {
        printf("Screen has double-buffering enabled\n");
    }

    if ( ( $sprite->flags & SDL_HWSURFACE ) == SDL_HWSURFACE ) {
        printf("Sprite is in video memory\n");
    } else {
        printf("Sprite is in system memory\n");
    }

    # Run a sample blit to trigger blit (if posssible)
    # acceleration before the check just after
    put_sprite( 0, 0 );

    if ( ( $sprite->flags & SDL_HWACCEL ) == SDL_HWACCEL ) {
        printf("Sprite blit uses hardware acceleration\n");
    }
    if ( ( $sprite->flags & SDL_RLEACCEL ) == SDL_RLEACCEL ) {
        printf("Sprite blit uses RLE acceleration\n");
    }
    $app->fill( $app_rect, $background );
}

sub put_sprite {
    my ( $x, $y ) = @_;

    my $dest_rect = new SDL::Rect(
        -x => $x - ( $sprite->width / 2 ),
        -y => $y - ( $sprite->height / 2 ),
        -width  => $sprite->width,
        -height => $sprite->height,
    );
    $sprite->blit( $sprite_rect, $app, $dest_rect );
}

sub game_loop {

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
                $x + sin( $i + $_/2 ) * $_,
                $screen_height / 2 + (
                    sin( ( $i + $_ ) * 0.2 )
                        * ( $settings{screen_height} / 3 )
                )
            );
            $x += $delta;
        }
        $i += 0.05;

        # __graw gfx end
        # $app->unlock();
        $app->sync;

        #$app->flip if $settings{flip};
    }
}

## Main program loop

#get_cmd_args();
#set_app_args();
#init_game_context();
#instruments();
game_loop();

#exit(0);

