#!/usr/bin/env perl 
use strict;
use warnings;
use lib 'lib';
use SDL;
use SDL::App;
use SDL::Color;
use SDL::Event;
use SDL::Mixer;
use SDL::Rect;
use SDL::Surface;
use SDL::Tool::Font;
use Bouncy::Brick;
use Time::HiRes qw(time sleep);

my $screen_width  = 640;
my $screen_height = 480;

my $max_fps                    = 300;
my $min_seconds_between_frames = 1 / $max_fps;

my $app = SDL::App->new(
    -width  => 640,
    -height => 480,

    #     -flags  => SDL_FULLSCREEN,
);

my $mixer = SDL::Mixer->new( -frequency => 44100, -size => 4096 );
my $ping = SDL::Sound->new('ping.ogg');
$ping->volume(64);
my $explosion = SDL::Sound->new('explosion.ogg');
my $bounce    = SDL::Sound->new('bounce.ogg');
my $music     = SDL::Music->new('Hydrate-Kenny_Beltrey.ogg');
$mixer->play_music( $music, -1 );

my $app_rect = SDL::Rect->new( 0, 0, $screen_width, $screen_height );

my $background_colour = $SDL::Color::yellow;

my $font = SDL::Tool::Font->new(
    -normal => 1,
    -ttfont => 'DroidSansMono.ttf',
    -size   => 20,
    -fg     => $SDL::Color::black,
    -bg     => $background_colour,
);
my $score = 0;

my $ball = SDL::Surface->new( -name => 'ball2.png' );
$ball->display_format();
my $ball_rect = SDL::Rect->new( 0, 0, $ball->width, $ball->height );

my $brick = SDL::Surface->new( -name => 'red.png' );
$brick->display_format();
my $brick_rect = SDL::Rect->new( 0, 0, $brick->width, $brick->height );
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
my $bat_rect = SDL::Rect->new( 0, 0, $bat->width, $bat->height );

my $event = SDL::Event->new();

sub put_sprite {
    my ( $surface, $x, $y, $source, $source_rect ) = @_;

    my $dest_rect = SDL::Rect->new( $x, $y, $source->width, $source->height );
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

            # draw the bat
            my $bat_background_rect
                = SDL::Rect->new( $bat_x, $bat_y, $bat->width, $bat->height );
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

    # draw score
    my $score_rect = SDL::Rect->new( 0, 0, $screen_width, 20 );
    $background->blit( $score_rect, $app, $score_rect );
    $font->print( $app, 0, 0, "Score: $score" );
    push @updates, $score_rect;

    # draw the ball
    my $ball_background_rect
        = SDL::Rect->new( $xs[-1], $ys[-1] - $ball->height,
        $ball->width, $ball->height );
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
        play_ping();
    }
    if ( $x < 0 ) {
        $ball_xv = $ball_xv * -0.9;
        $ball_yv = $ball_yv * 0.9;
        $x -= $dx;
        play_ping();
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
        play_bounce();
    } elsif ( $y > $screen_height ) {
        $ball_yv = $ball_yv * -0.7;
        $ball_xv = $ball_xv * 0.7;
        $y -= $dy;
        play_ping() if $dy > 0.2;
    }
    if ( $y - $ball->height < 0 ) {
        $ball_yv = $ball_yv * -1.1;
        $ball_xv = $ball_xv * 0.9;
        $y -= $dy;
        play_ping();
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
            my $brick_background_rect
                = SDL::Rect->new( $brick->x, $brick->y, $brick->w,
                $brick->h );
            $background->fill( $brick_background_rect, $background_colour );
            $app->fill( $brick_background_rect, $background_colour );
            push @updates, $brick_background_rect;
            $brick->visible(0);
            play_explosion();
            $score++;
            last;
        }
    }

    $app->update(@updates);
}

sub play_ping {
    $mixer->play_channel( -1, $ping, 0 );
}

sub play_explosion {
    $mixer->play_channel( -1, $explosion, 0 );
}

sub play_bounce {
    $mixer->play_channel( -1, $bounce, 0 );
}

SDL::ShowCursor(1);
