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
use SDL::TTFont;
use Bouncy::Brick;
use Time::HiRes qw(time sleep);

my $screen_width  = 960;
my $screen_height = 600;

my $max_fps                    = 300;
my $min_seconds_between_frames = 1 / $max_fps;

my $app = SDL::App->new(
    -width  => $screen_width,
    -height => $screen_height,

    #     -flags  => SDL_FULLSCREEN,
);

my $mixer = SDL::Mixer->new( -frequency => 44100, -size => 1024 );
my $ping = SDL::Sound->new('ping.ogg');
$ping->volume(64);
my $explosion = SDL::Sound->new('explosion.ogg');
my $bounce    = SDL::Sound->new('bounce.ogg');
my $music     = SDL::Music->new('Hydrate-Kenny_Beltrey.ogg');
$mixer->play_music( $music, -1 );

my $app_rect = SDL::Rect->new( 0, 0, $screen_width, $screen_height );

my $background_colour = $SDL::Color::yellow;

my $font = SDL::TTFont->new(
    -normal => 1,
    -name   => 'DroidSansMono.ttf',
    -size   => 20,
    -fg     => $SDL::Color::black,
    -bg     => SDL::Color->new( -r => 200, -g => 200, -b => 200 ),
);
my $score = 0;

my $background_tile = SDL::Surface->new( -name => 'background_tile.png' );
$background_tile->display_format();
my $background_tile_rect = SDL::Rect->new( 0, 0, $background_tile->width,
    $background_tile->height );

my $ball = SDL::Surface->new( -name => 'ball2.png' );
$ball->display_format();
my $ball_rect = SDL::Rect->new( 0, 0, $ball->width, $ball->height );

my $brick_rect = SDL::Rect->new( 0, 0, 64, 32 );
Bouncy::Brick->rect($brick_rect);
my $brick_red = SDL::Surface->new( -name => 'brick_red.png' );
$brick_red->display_format();
my $brick_blue = SDL::Surface->new( -name => 'brick_blue.png' );
$brick_blue->display_format();
my $brick_purple = SDL::Surface->new( -name => 'brick_purple.png' );
$brick_purple->display_format();
my $brick_yellow = SDL::Surface->new( -name => 'brick_yellow.png' );
$brick_yellow->display_format();
my $brick_green = SDL::Surface->new( -name => 'brick_green.png' );
$brick_green->display_format();

my @bricks;
my $map = "


    RRRRRRR
  PBBBBBBBBBP
 PPPBBBBBBBPPP
PPRPPGGGGGPPRPP
BPPPYYYYYYYPPPB
BBPYYYYYYYYYPBB";
my ( $brick_x, $brick_y ) = ( 0, 24 );
$map =~ s/^\n//;
foreach my $line ( split "\n", $map ) {
    foreach my $character ( split //, $line ) {
        if ( $character eq 'R' ) {
            push @bricks,
                Bouncy::Brick->new(
                x        => $brick_x,
                y        => $brick_y,
                surface  => $brick_red,
                strength => 2,
                );
        } elsif ( $character eq 'B' ) {
            push @bricks,
                Bouncy::Brick->new(
                x       => $brick_x,
                y       => $brick_y,
                surface => $brick_blue,
                );
        } elsif ( $character eq 'P' ) {
            push @bricks,
                Bouncy::Brick->new(
                x       => $brick_x,
                y       => $brick_y,
                surface => $brick_purple,
                );
        } elsif ( $character eq 'Y' ) {
            push @bricks,
                Bouncy::Brick->new(
                x       => $brick_x,
                y       => $brick_y,
                surface => $brick_yellow,
                );
        } elsif ( $character eq 'G' ) {
            push @bricks,
                Bouncy::Brick->new(
                x       => $brick_x,
                y       => $brick_y,
                surface => $brick_green,
                );
        }
        $brick_x += 64;
    }
    print "\n";
    $brick_x = 0;
    $brick_y += 32;
}

my $bat = SDL::Surface->new( -name => 'bat.png' );

$bat->display_format_alpha();

my $bat_rect = SDL::Rect->new( 0, 0, $bat->width, $bat->height );

my $event = SDL::Event->new();

my $bat_x = $screen_width / 2;
my $bat_y = $screen_height - $bat->height;
$app->warp( $bat_x, $bat_y );
my ( $x, $y ) = ( $bat_x + 54, $bat_y );

my $ball_xv = 300;      # pixels per second
my $ball_yv = -1120;    # pixels per second
my $gravity = 1250;     # pixels per second per second
my @xs      = ($x);
my @ys      = ($y);

my $background = SDL::Surface->new(
    -flags  => SDL_SWSURFACE,
    -width  => $screen_width,
    -height => $screen_height,
);
$background->display_format();

my ( $tile_x, $tile_y ) = ( 0, 0 );
while ( $tile_x < $screen_width ) {
    while ( $tile_y < $screen_height ) {
        put_sprite( $background, $tile_x, $tile_y, $background_tile,
            $background_tile_rect );
        $tile_y += $background_tile->height;
    }
    $tile_y = 0;
    $tile_x += $background_tile->width;
}

$background->fill(
    SDL::Rect->new( 0, 0, $screen_width, 24 ),
    SDL::Color->new( -r => 200, -g => 200, -b => 200 )
);

my $foreground = SDL::Surface->new(
    -flags  => SDL_SWSURFACE,
    -width  => $screen_width,
    -height => $screen_height,
);
$foreground->display_format();
$background->blit( $app_rect, $foreground, $app_rect );

foreach my $brick (@bricks) {
    put_sprite( $foreground, $brick->x, $brick->y, $brick->surface,
        $brick->rect );
}

$foreground->blit( $app_rect, $app, $app_rect );
put_sprite( $app, $bat_x, $bat_y, $bat, $bat_rect );
$app->update($app_rect);

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
            $ball_yv = -1120;
        }
        if ( $etype eq SDL_MOUSEMOTION ) {

            # draw the bat
            my $bat_foreground_rect
                = SDL::Rect->new( $bat_x, $bat_y, $bat->width, $bat->height );
            $foreground->blit( $bat_foreground_rect, $app,
                $bat_foreground_rect );
            push @updates, $bat_foreground_rect;

            $bat_x = $event->motion_x - 56;
            $bat_x = 0 if $bat_x < 0;
            $bat_x = $screen_width - 112 if $bat_x + 112 > $screen_width;
            push @updates,
                put_sprite( $app, $bat_x, $bat_y, $bat, $bat_rect );
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
    my $text        = "Score: $score";
    my $score_width = $font->width($text);
    my $score_rect  = SDL::Rect->new( 0, 0, $score_width, 20 );
    $foreground->blit( $score_rect, $app, $score_rect );
    $font->print( $app, 0, 0, $text );
    push @updates, $score_rect;

    # draw the ball
    my $ball_foreground_rect
        = SDL::Rect->new( $xs[-1], $ys[-1] - $ball->height,
        $ball->width, $ball->height );
    $foreground->blit( $ball_foreground_rect, $app, $ball_foreground_rect );
    push @updates, $ball_foreground_rect;

    push @updates,
        put_sprite( $app, $x, $y - $ball->height, $ball, $ball_rect );

    push @xs, $x;
    push @ys, $y;

    if ( @xs > 80 ) {
        shift @xs;
        shift @ys;
    }

    my $dx = $ball_xv * ( $last_frame_seconds + $last_frame_sleep );

    $x += $dx;
    if ( $x + $ball->width > $screen_width ) {
        $ball_xv = $ball_xv * -1;
        $ball_yv = $ball_yv * 1;
        $x -= $dx;
        play_ping( 255 - ( $x * 255 / $screen_width ) );
    }
    if ( $x < 0 ) {
        $ball_xv = $ball_xv * -1;
        $ball_yv = $ball_yv * 1;
        $x -= $dx;
        play_ping( 255 - ( $x * 255 / $screen_width ) );
    }

    $ball_yv += $gravity * ( $last_frame_seconds + $last_frame_sleep );
    my $dy = $ball_yv * ( $last_frame_seconds + $last_frame_sleep );
    $y += $dy;

    if ( ( $x + $ball->width / 2 > $bat_x && $x < $bat_x + 108 )
        && $y > $screen_height - $bat->height + 5 )
    {
        $ball_yv = -1120;
        $ball_xv
            = 0.3 * $ball_xv + ( $x + $ball->width / 2 - $bat_x - 56 ) * 8;
        $y -= $dy;
        play_bounce( 255 - ( $x * 255 / $screen_width ) );
    } elsif ( $y > $screen_height ) {
        $ball_yv = $ball_yv * -0.7;
        $ball_xv = $ball_xv * 0.7;
        $y -= $dy;
        play_ping( 255 - ( $x * 255 / $screen_width ) ) if $dy > 0.2;
    }
    if ( $y - $ball->height < 0 ) {
        $ball_yv = $ball_yv * -1;
        $ball_xv = $ball_xv * 1;
        $y -= $dy;
        play_ping( 255 - ( $x * 255 / $screen_width ) );
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
                $ball_xv = $ball_xv * -1;
                $x -= $dx;
            } else {
                $ball_yv = $ball_yv * -1;
                $y -= $dy;
            }
            $brick->strength( $brick->strength - 1 );
            if ( $brick->strength == 0 ) {
                my $brick_background_rect
                    = SDL::Rect->new( $brick->x, $brick->y, $brick->w,
                    $brick->h );
                $background->blit( $app_rect, $foreground, $app_rect );
                $foreground->blit( $app_rect, $app,        $app_rect );
                push @updates, $brick_background_rect;
                $brick->visible(0);
                $score++;
                play_explosion( 255 - ( $brick->x * 255 / $screen_width ) );
            }

            play_ping( 255 - ( $brick->x * 255 / $screen_width ) );
            last;
        }
    }

    $app->update(@updates);
}

sub put_sprite {
    my ( $surface, $x, $y, $source, $source_rect ) = @_;

    my $dest_rect = SDL::Rect->new( $x, $y, $source->width, $source->height );
    $source->blit( $source_rect, $surface, $dest_rect );
    return $dest_rect;
}

sub play_ping {
    my $left = shift;
    my $channel = $mixer->play_channel( -1, $ping, 0 );
    $mixer->set_panning( $channel, 127 + $left / 2, 254 - $left / 2 );
}

sub play_explosion {
    my $left = shift;
    my $channel = $mixer->play_channel( -1, $explosion, 0 );
    $mixer->set_panning( $channel, 127 + $left / 2, 254 - $left / 2 );
}

sub play_bounce {
    my $left = shift;
    my $channel = $mixer->play_channel( -1, $bounce, 0 );
    $mixer->set_panning( $channel, 127 + $left / 2, 254 - $left / 2 );
}

SDL::ShowCursor(1);
