#!/usr/bin/env perl 
use strict;
use warnings;
use lib 'lib';
use Bouncy::Brick;
use SDL;
use SDL::App;
use SDL::Color;
use SDL::Event;
use SDL::Mixer;
use SDL::Rect;
use SDL::Surface;
use SDL::TTFont;
use Set::Object;
use Time::HiRes qw(time sleep);

my $screen_width  = 960;
my $screen_height = 600;
my $sound         = 0;

my $max_fps                    = 300;
my $min_seconds_between_frames = 1 / $max_fps;

my $app = SDL::App->new(
    -width  => $screen_width,
    -height => $screen_height,

    #     -flags  => SDL_FULLSCREEN,
);

my ( $mixer, $ping, $explosion, $explosion_multiple, $bounce, $music );

if ($sound) {
    $mixer = SDL::Mixer->new( -frequency => 44100, -size => 1024 );
    $ping = SDL::Sound->new('ping.ogg');
    $ping->volume(64);
    $explosion          = SDL::Sound->new('sound/explosion.ogg');
    $explosion_multiple = SDL::Sound->new('sound/explosion_multiple.ogg');
    $bounce             = SDL::Sound->new('bounce.ogg');
    $music              = SDL::Music->new('Hydrate-Kenny_Beltrey.ogg');
    $mixer->play_music( $music, -1 );
}

my $app_rect = SDL::Rect->new( 0, 0, $screen_width, $screen_height );

my $font = SDL::TTFont->new(
    -normal => 1,
    -name   => 'DroidSansMono.ttf',
    -size   => 20,
    -fg     => SDL::Color->new( 0, 0, 0 ),
    -bg     => SDL::Color->new( 200, 200, 200 ),
);
my $score = 0;

my $background_tile = load_image('background_tile.png');
my $background_tile_rect
    = SDL::Rect->new( 0, 0, $background_tile->w, $background_tile->h );

my $ball = load_image('ball2.png');
my $ball_rect = SDL::Rect->new( 0, 0, $ball->w, $ball->h );

my $brick_rect = SDL::Rect->new( 0, 0, 64, 32 );
Bouncy::Brick->rect($brick_rect);

my $brick_red        = load_image('brick_red.png');
my $brick_red_broken = load_image('brick_red_broken.png');
my $brick_blue       = load_image('brick_blue.png');
my $brick_purple     = load_image('brick_purple.png');
my $brick_yellow     = load_image('brick_yellow.png');
my $brick_green      = load_image('brick_green.png');

my $bricks = Set::Object->new();
my $map    = "


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
        my $screen_rect = SDL::Rect->new( $brick_x, $brick_y, 64, 32 );
        if ( $character eq 'R' ) {
            $bricks->insert(
                Bouncy::Brick->new(
                    x           => $brick_x,
                    y           => $brick_y,
                    surface     => $brick_red,
                    strength    => 2,
                    screen_rect => $screen_rect,
                )
            );
        } elsif ( $character eq 'B' ) {
            $bricks->insert(
                Bouncy::Brick->new(
                    x           => $brick_x,
                    y           => $brick_y,
                    surface     => $brick_blue,
                    screen_rect => $screen_rect,
                )
            );
        } elsif ( $character eq 'P' ) {
            $bricks->insert(
                Bouncy::Brick->new(
                    x           => $brick_x,
                    y           => $brick_y,
                    surface     => $brick_purple,
                    screen_rect => $screen_rect,
                )
            );
        } elsif ( $character eq 'Y' ) {
            $bricks->insert(
                Bouncy::Brick->new(
                    x           => $brick_x,
                    y           => $brick_y,
                    surface     => $brick_yellow,
                    screen_rect => $screen_rect,
                )
            );
        } elsif ( $character eq 'G' ) {
            $bricks->insert(
                Bouncy::Brick->new(
                    x           => $brick_x,
                    y           => $brick_y,
                    surface     => $brick_green,
                    screen_rect => $screen_rect,
                )
            );
        }
        $brick_x += 64;
    }
    $brick_x = 0;
    $brick_y += 32;
}

my $bat = load_image_alpha('bat.png');

my $bat_rect = SDL::Rect->new( 0, 0, $bat->w, $bat->h );

my $event = SDL::Event->new();

my $bat_x = $screen_width / 2;
my $bat_y = $screen_height - $bat->h;
$app->warp( $bat_x, $bat_y );
my ( $x, $y ) = ( $bat_x + 54, $bat_y );

my $ball_xv = 300;      # pixels per second
my $ball_yv = -1110;    # pixels per second
my $gravity = 1250;     # pixels per second per second
my @xs      = ($x);
my @ys      = ($y);

my $background
    = SDL::Surface->new( SDL_SWSURFACE, $screen_width, $screen_height, 8, 0,
    0, 0, 0 )->display;

my ( $tile_x, $tile_y ) = ( 0, 0 );
while ( $tile_x < $screen_width ) {
    while ( $tile_y < $screen_height ) {
        put_sprite( $background, $tile_x, $tile_y, $background_tile,
            $background_tile_rect );
        $tile_y += $background_tile->h;
    }
    $tile_y = 0;
    $tile_x += $background_tile->w;
}

$background->fill_rect(
    SDL::Rect->new( 0, 0, $screen_width, 24 ),
    SDL::Color->new( 200, 200, 200 )
);

my $foreground
    = SDL::Surface->new( SDL_SWSURFACE, $screen_width, $screen_height, 8, 0,
    0, 0, 0 )->display;
SDL::BlitSurface( $background, $app_rect, $foreground, $app_rect );

foreach my $brick ( $bricks->members ) {
    SDL::BlitSurface( $brick->surface, $brick->rect, $foreground, $brick->screen_rect );
}

SDL::BlitSurface( $foreground, $app_rect, $app, $app_rect );
put_sprite( $app, $bat_x, $bat_y, $bat, $bat_rect );
draw_score();

SDL::Surface::update_rect( $app, 0, 0, $screen_width, $screen_height );

#$app->update_rects($app_rect);

SDL::ShowCursor(0);

my $this_frame_time  = time;
my $last_frame_time  = $this_frame_time;
my $last_frame_sleep = 0;

my $last_measured_fps_time   = time;
my $last_measured_fps_frames = 0;
my $frames                   = 0;

my $bricks_since_bat = 0;

while (1) {
    my @updates;
    my $now = time;

    #warn "frame";
    $last_frame_time = $this_frame_time;
    $this_frame_time = $now;
    my $last_frame_seconds = $this_frame_time - $last_frame_time;

    if ( $now - $last_measured_fps_time > 1 ) {
        my $fps = ( $frames - $last_measured_fps_frames )
            / ( $now - $last_measured_fps_time );

        # draw fps
        my $text = sprintf( "%0.1f FPS", $fps );
        my $fps_width = $font->width($text);
        my $fps_rect
            = SDL::Rect->new( $screen_width - $fps_width, 0, $fps_width, 20 );
        SDL::BlitSurface( $foreground, $fps_rect, $app, $fps_rect );

        # $font->print( $app, $screen_width - $fps_width, 0, $text );
        push @updates, $fps_rect;

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
            $x                = $bat_x + $bat->w / 3;
            $y                = $bat_y;
            $ball_xv          = 300;
            $ball_yv          = -1110;
            $bricks_since_bat = 0;
        }
        if ( $etype eq SDL_MOUSEMOTION ) {

            # draw the bat
            my $bat_foreground_rect
                = SDL::Rect->new( $bat_x, $bat_y, $bat->w, $bat->h );
            SDL::BlitSurface( $foreground, $bat_foreground_rect, $app,
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

    # draw the ball
    my $ball_foreground_rect
        = SDL::Rect->new( $xs[-1], $ys[-1] - $ball->h, $ball->w, $ball->h );
    SDL::BlitSurface( $foreground, $ball_foreground_rect, $app, $ball_foreground_rect );
    push @updates, $ball_foreground_rect;

    push @updates, put_sprite( $app, $x, $y - $ball->h, $ball, $ball_rect );

    push @xs, $x;
    push @ys, $y;

    if ( @xs > 80 ) {
        shift @xs;
        shift @ys;
    }

    my $dx = $ball_xv * ( $last_frame_seconds + $last_frame_sleep );

    $x += $dx;
    if ( $x + $ball->w > $screen_width ) {
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

    if ( ( $x + $ball->w / 2 > $bat_x && $x < $bat_x + 108 )
        && $y > $screen_height - $bat->h + 5 )
    {
        $ball_yv = -1110;
        $ball_xv = 0.3 * $ball_xv + ( $x + $ball->w / 2 - $bat_x - 56 ) * 8;
        $y -= $dy;
        play_bounce( 255 - ( $x * 255 / $screen_width ) );
        $bricks_since_bat = 0;
    } elsif ( $y > $screen_height ) {
        $ball_yv = $ball_yv * -0.7;
        $ball_xv = $ball_xv * 0.7;
        $y -= $dy;
        play_ping( 255 - ( $x * 255 / $screen_width ) ) if $dy > 0.2;
    }
    if ( $y - $ball->h < 0 ) {
        $ball_yv = $ball_yv * -1;
        $ball_xv = $ball_xv * 1;
        $y -= $dy;
        play_ping( 255 - ( $x * 255 / $screen_width ) );
    }

    foreach my $brick ( $bricks->members ) {
        my $brick_x = $brick->x;
        my $brick_y = $brick->y;
        my $brick_w = 64;
        my $brick_h = 32;
        if (   $x > $brick_x - $ball->w
            && $x < $brick_x + $brick_w
            && $y > $brick_y
            && $y < $brick_y + $brick_h + $ball->h )
        {
            if (   $ys[-1] > $brick_y
                && $ys[-1] < $brick_y + $brick_h + $ball->h )
            {
                $ball_xv = $ball_xv * -1;
                $x -= $dx;
            } else {
                $ball_yv = $ball_yv * -1;
                $ball_xv *= 0.90;
                $ball_yv *= 0.95;
                $y -= $dy;
            }
            $brick->strength( $brick->strength - 1 );
            if ( $brick->strength == 0 ) {
                SDL::BlitSurface( $background, $brick->screen_rect, $foreground,
                    $brick->screen_rect );
                SDL::BlitSurface( $foreground, $brick->screen_rect, $app,
                    $brick->screen_rect );
                push @updates, $brick->screen_rect;
                $bricks->remove($brick);
                $bricks_since_bat++;
                $score += $bricks_since_bat;
                push @updates, draw_score();
                if ( $bricks_since_bat > 1 ) {
                    play_explosion_multiple(
                        255 - ( $brick_x * 255 / $screen_width ) );
                } else {
                    play_explosion(
                        255 - ( $brick_x * 255 / $screen_width ) );
                }
            } else {
                SDL::BlitSurface( $brick_red_broken, $brick->rect, $foreground,
                    $brick->screen_rect );
                SDL::BlitSurface( $brick_red_broken, $brick->rect, $app,
                    $brick->screen_rect );
                push @updates, $brick->screen_rect;
                play_ping( 255 - ( $brick_x * 255 / $screen_width ) );
            }
            last;
        }
    }

    SDL::Surface::update_rect( $app, 0, 0, 0, 0 );

    #    $app->update_rect(0, 0, $screen_width, $screen_height);
    #    $app->update_rects(@updates);
}

sub draw_score {
    my $text        = "Score: $score";
    my $score_width = $font->width($text);
    my $score_rect  = SDL::Rect->new( 0, 0, $score_width, 20 );
    SDL::BlitSurface( $foreground, $score_rect, $app, $score_rect );

    # $font->print( $app, 0, 0, $text );
    return $score_rect;
}

sub put_sprite {
    my ( $surface, $x, $y, $source, $source_rect ) = @_;

    my $dest_rect = SDL::Rect->new( $x, $y, $source->w, $source->h );
    SDL::BlitSurface( $source, $source_rect, $surface, $dest_rect );
    return $dest_rect;
}

sub play_ping {
    my $left = shift;
    if ($sound) {
        my $channel = $mixer->play_channel( -1, $ping, 0 );
        $mixer->set_panning( $channel, 127 + $left / 2, 254 - $left / 2 );
    }
}

sub play_explosion {
    my $left = shift;
    if ($sound) {
        my $channel = $mixer->play_channel( -1, $explosion, 0 );
        $mixer->set_panning( $channel, 127 + $left / 2, 254 - $left / 2 );
    }
}

sub play_explosion_multiple {
    my $left = shift;
    if ($sound) {
        my $channel = $mixer->play_channel( -1, $explosion_multiple, 0 );
        $mixer->set_panning( $channel, 127 + $left / 2, 254 - $left / 2 );
    }
}

sub play_bounce {
    my $left = shift;
    if ($sound) {
        my $channel = $mixer->play_channel( -1, $bounce, 0 );
        $mixer->set_panning( $channel, 127 + $left / 2, 254 - $left / 2 );
    }
}

sub load_image {
    my $filename = shift;
    my $image    = SDL::IMG_Load($filename)->display;
    return $image;
}

sub load_image_alpha {
    my $filename = shift;
    my $image    = SDL::IMG_Load($filename)->display_alpha;
    return $image;
}

SDL::ShowCursor(1);
