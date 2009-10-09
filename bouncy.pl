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
use Time::HiRes qw(time sleep);

my $screen_width  = 640;
my $screen_height = 480;

my $max_fps                    = 50;
my $min_seconds_between_frames = 1 / $max_fps;

my $app = SDL::App->new(
    -width  => 640,
    -height => 480,

    #     -flags  => SDL_FULLSCREEN,
);

my $app_rect = SDL::Rect->new(
    -height => $screen_height,
    -width  => $screen_width,
);

my $background_colour = $SDL::Color::yellow;

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
    Bouncy::Brick->new( x => 192, y => 100 ),
    Bouncy::Brick->new( x => 256, y => 100 ),
    Bouncy::Brick->new( x => 0,   y => 132 ),
    Bouncy::Brick->new( x => 64,  y => 132 ),
    Bouncy::Brick->new( x => 128, y => 132 ),
    Bouncy::Brick->new( x => 192, y => 132 ),
    Bouncy::Brick->new( x => 256, y => 132 ),
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
    my ( $surface, $x, $y, $source, $source_rect ) = @_;

    my $dest_rect = SDL::Rect->new(
        -x      => $x,
        -y      => $y,
        -width  => $source->width,
        -height => $source->height,
    );
    $source->blit( $source_rect, $surface, $dest_rect );
    return $dest_rect;
}

my $bat_x = 100;
my $bat_y = $screen_height - $bat->height;
my ( $x, $y ) = ( $bat_x + 54, $bat_y );

my $ball_xv = 300;      # pixels per second
my $ball_yv = -1000;    # pixels per second
my $gravity = 1250;     # pixels per second per second
my @xs      = ($x);
my @ys      = ($y);

my $background = SDL::Surface->new(
    -flags  => SDL_SWSURFACE,
    -width  => $screen_width,
    -height => $screen_height,
);
$background->display_format();
$background->fill( $app_rect, $background_colour );
foreach my $brick (@bricks) {
    put_sprite( $background, $brick->x, $brick->y, $brick->surface,
        $brick->rect );
}
$background->update($app_rect);

$background->blit( $app_rect, $app, $app_rect );
$app->update($app_rect);
$app->sync;

SDL::ShowCursor(0);

my $this_frame_time  = time;
my $last_frame_time  = $this_frame_time;
my $last_frame_sleep = 0;

my $last_measured_fps_time   = time;
my $last_measured_fps_frames = 0;
my $frames                   = 0;

while (1) {
    my $now = time;

    #warn "frame";
    $last_frame_time = $this_frame_time;
    $this_frame_time = $now;
    my $last_frame_seconds = $this_frame_time - $last_frame_time;

    if ( $now - $last_measured_fps_time > 1 ) {
        my $fps = ( $frames - $last_measured_fps_frames )
            / ( $now - $last_measured_fps_time );

        # printf( "%0.2f FPS\n", $fps );
        $last_measured_fps_frames = $frames;
        $last_measured_fps_time   = $now;
    }

    #warn $last_frame_seconds, ' <?' , $min_seconds_between_frames;
    if ( $last_frame_seconds < $min_seconds_between_frames ) {

        #warn "sleep";
        my $seconds_to_sleep
            = $min_seconds_between_frames - $last_frame_seconds;
        my $actually_slept = sleep($seconds_to_sleep);
        $last_frame_sleep = $actually_slept;

        #warn "  slept for $seconds_to_sleep = $last_frame_sleep";
        $this_frame_time = time + $seconds_to_sleep - $actually_slept;
    } else {
        $last_frame_sleep = 0;
    }

    $frames++;

    my @updates;

    # process event queue
    $event->pump;

    # handle user events
    my $event = SDL::Event->new;
    while ( $event->poll() ) {
        my $etype = $event->type;

        exit if ( $etype eq SDL_QUIT );
        exit if ( SDL::GetKeyState(SDLK_ESCAPE) );
        exit if ( $etype eq SDL_KEYDOWN );

        if ( $etype eq SDL_MOUSEBUTTONDOWN ) {
            $x       = $bat_x + $bat->width / 3;
            $y       = $bat_y;
            $ball_xv = 300;
            $ball_yv = -1000;
        }
        if ( $etype eq SDL_MOUSEMOTION ) {
            my $bat_background_rect = SDL::Rect->new(
                -x      => $bat_x,
                -y      => $bat_y,
                -width  => $bat->width,
                -height => $bat->height,
            );
            $background->blit( $bat_background_rect, $app,
                $bat_background_rect );
            push @updates, $bat_background_rect;

            $bat_x = $event->motion_x - 56;
            $bat_x = 0 if $bat_x < 0;
            $bat_x = $screen_width - 112 if $bat_x + 112 > $screen_width;
        }
    }

    # draw tail
    if (0) {
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
    }

    my $ball_background_rect = SDL::Rect->new(
        -x      => $xs[-1],
        -y      => $ys[-1] - $ball->height,
        -width  => $ball->width,
        -height => $ball->height,
    );
    $background->blit( $ball_background_rect, $app, $ball_background_rect );
    push @updates, $ball_background_rect;

    push @updates,
        put_sprite( $app, $x, $y - $ball->height, $ball, $ball_rect );
    push @updates, put_sprite( $app, $bat_x, $bat_y, $bat, $bat_rect );

    push @xs, $x;
    push @ys, $y;

    if ( @xs > 80 ) {
        shift @xs;
        shift @ys;
    }

    my $dx = $ball_xv * ( $last_frame_seconds + $last_frame_sleep );

    $x += $dx;
    if ( $x + $ball->width > $screen_width ) {
        $ball_xv = $ball_xv * -0.9;
        $ball_yv = $ball_yv * 0.9;
        $x -= $dx;
    }
    if ( $x < 0 ) {
        $ball_xv = $ball_xv * -0.9;
        $ball_yv = $ball_yv * 0.9;
        $x -= $dx;
    }

    $ball_yv += $gravity * ( $last_frame_seconds + $last_frame_sleep );
    my $dy = $ball_yv * ( $last_frame_seconds + $last_frame_sleep );
    $y += $dy;

    if ( ( $x + $ball->width / 2 > $bat_x && $x < $bat_x + 108 )
        && $y > $screen_height - $bat->height + 5 )
    {
        $ball_yv = -1000;
        $ball_xv
            = 0.3 * $ball_xv + ( $x + $ball->width / 2 - $bat_x - 56 ) * 4;
        $y -= $dy;
    } elsif ( $y > $screen_height ) {
        $ball_yv = $ball_yv * -0.7;
        $ball_xv = $ball_xv * 0.7;
        $y -= $dy;
    }
    if ( $y - $ball->height < 0 ) {
        $ball_yv = $ball_yv * -1.1;
        $ball_xv = $ball_xv * 0.9;
        $y -= $dy;
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
                $ball_xv = $ball_xv * -0.9;
                $x -= $dx;
            } else {
                $ball_yv = $ball_yv * -0.9;
                $y -= $dy;
            }
            my $brick_background_rect = SDL::Rect->new(
                -x      => $brick->x,
                -y      => $brick->y,
                -width  => $brick->w,
                -height => $brick->h,
            );
            $background->fill( $brick_background_rect, $background_colour );
            $app->fill( $brick_background_rect, $background_colour );
            push @updates, $brick_background_rect;
            $brick->visible(0);
            last;
        }
    }

    $app->update(@updates);
}

SDL::ShowCursor(1);
