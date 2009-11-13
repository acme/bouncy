#!/usr/bin/env perl 
use strict;
use warnings;
use lib 'lib';
use Bouncy::Brick;
use Bouncy::FPS;
use Bouncy::Sprite;
use Bouncy::Sprite::FPS;
use Bouncy::Sprite::Score;
use SDL;
use SDL::App;
use SDL::Color;
use SDL::Event;
use SDL::Events;
use SDL::Mixer::MixChunk;
use SDL::Mixer::MixMusic;
use SDL::Mixer;
use SDL::MouseMotionEvent;
use SDL::Rect;
use SDL::Surface;
use SDL::TTF_Font;
use SDL::Video;
use Set::Object;
use Time::HiRes qw(time sleep);

my $screen_width  = 960;
my $screen_height = 600;
my $sound         = 1;

my $max_fps = 300;

my $app = SDL::App->new(
    -width  => $screen_width,
    -height => $screen_height,

    #     -flags  => SDL_FULLSCREEN,
);

my ( $ping, $explosion, $explosion_multiple, $bounce, $music );

if ($sound) {
    SDL::MixOpenAudio( 44100, SDL::Constants::AUDIO_S16, 2, 4096 );
    $ping = SDL::MixLoadWAV('ping.ogg');
    $ping->volume(64);
    $explosion          = SDL::MixLoadWAV('sound/explosion.ogg');
    $explosion_multiple = SDL::MixLoadWAV('sound/explosion_multiple.ogg');
    $bounce             = SDL::MixLoadWAV('bounce.ogg');
    my $mix_music = SDL::MixLoadMUS('Hydrate-Kenny_Beltrey.ogg');
    SDL::MixPlayMusic( $mix_music, -1 );
}

my $app_rect = SDL::Rect->new( 0, 0, $screen_width, $screen_height );

SDL::TTF_Init();
my $ttf_font     = SDL::TTF_OpenFont( 'DroidSans-Bold.ttf', 22 );
my $score        = 0;
my $points       = 0;
my $points_added = time;

my $background_tile = load_image('background_tile.png');
my $background_tile_rect
    = SDL::Rect->new( 0, 0, $background_tile->w, $background_tile->h );

my $ball = load_image_alpha('ball2.png');
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
my ( $x, $y ) = ( $bat_x - $ball->w / 2, $bat_y );

my $ball_xv = 300;      # pixels per second
my $ball_yv = -1110;    # pixels per second
my $gravity = 1250;     # pixels per second per second
my @xs      = ($x);
my @ys      = ($y);

my $background = SDL::Video::display_format(
    SDL::Surface->new( SDL_SWSURFACE, $screen_width, $screen_height, 8, 0, 0,
        0, 0
    )
);

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

my $background_pixel_format = $background->format;
my $grey_pixel
    = SDL::Video::map_RGB( $background_pixel_format, 200, 200, 200 );
SDL::Video::fill_rect( $background, SDL::Rect->new( 0, 0, $screen_width, 24 ),
    $grey_pixel );

my $foreground = SDL::Video::display_format(
    SDL::Surface->new( SDL_SWSURFACE, $screen_width, $screen_height, 8, 0, 0,
        0, 0
    )
);
SDL::Video::blit_surface( $background, $app_rect, $foreground, $app_rect );

foreach my $brick ( $bricks->members ) {
    SDL::Video::blit_surface( $brick->surface, $brick->rect, $foreground,
        $brick->screen_rect );
}

SDL::Video::blit_surface( $foreground, $app_rect, $app, $app_rect );
put_sprite( $app, $bat_x, $bat_y, $bat, $bat_rect );

my $sprite_fps = Bouncy::Sprite::FPS->new(
    foreground => $app,
    background => $foreground,
    text       => '? FPS',
    font       => $ttf_font,
    x          => $screen_width,
    y          => 0,
);
$sprite_fps->draw;
my $sprite_score = Bouncy::Sprite::Score->new(
    foreground => $app,
    background => $foreground,
    text       => 'Score: 0',
    font       => $ttf_font,
    x          => 0,
    y          => 0,
);
$sprite_score->draw;

SDL::Video::update_rect( $app, 0, 0, $screen_width, $screen_height );

SDL::ShowCursor(0);

my $bricks_since_bat = 0;

my $fps = Bouncy::FPS->new( max_fps => $max_fps );

while (1) {
    my @updates;
    $fps->frame;

    $sprite_fps->text( sprintf( "%0.1f FPS", $fps->fps ) );
    push @updates, $sprite_fps->draw;

    # process events
    while (1) {
        SDL::Events::pump_events();
        last unless SDL::Events::poll_event($event);

        if ( $event->type == SDL_KEYDOWN ) {
            exit;
        } elsif ( $event->type == SDL_MOUSEBUTTONDOWN ) {
            $x                = $bat_x + $bat->w / 3;
            $y                = $bat_y;
            $ball_xv          = 300;
            $ball_yv          = -1110;
            $bricks_since_bat = 0;
        } elsif ( $event->type == SDL_MOUSEMOTION ) {

            # draw the bat
            my $bat_foreground_rect
                = SDL::Rect->new( $bat_x, $bat_y, $bat->w, $bat->h );
            SDL::Video::blit_surface(
                $foreground, $bat_foreground_rect,
                $app,        $bat_foreground_rect
            );
            push @updates, $bat_foreground_rect;

            $bat_x = $event->motion->x - 56;
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
    SDL::Video::blit_surface( $foreground, $ball_foreground_rect, $app,
        $ball_foreground_rect );
    push @updates, $ball_foreground_rect;

    push @updates, put_sprite( $app, $x, $y - $ball->h, $ball, $ball_rect );

    push @xs, $x;
    push @ys, $y;

    if ( @xs > 80 ) {
        shift @xs;
        shift @ys;
    }

    my $dx = $ball_xv * ( $fps->last_frame_seconds );

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

    $ball_yv += $gravity * ( $fps->last_frame_seconds );
    my $dy = $ball_yv * ( $fps->last_frame_seconds );
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
                SDL::Video::blit_surface(
                    $background, $brick->screen_rect,
                    $foreground, $brick->screen_rect
                );
                SDL::Video::blit_surface(
                    $foreground, $brick->screen_rect,
                    $app,        $brick->screen_rect
                );
                push @updates, $brick->screen_rect;
                $bricks->remove($brick);
                $bricks_since_bat++;
                $points += $bricks_since_bat;
                $points_added = time;
                push @updates, draw_score();

                if ( $bricks_since_bat > 1 ) {
                    play_explosion_multiple(
                        255 - ( $brick_x * 255 / $screen_width ) );
                } else {
                    play_explosion(
                        255 - ( $brick_x * 255 / $screen_width ) );
                }
            } else {
                SDL::Video::blit_surface(
                    $brick_red_broken, $brick->rect,
                    $foreground,       $brick->screen_rect
                );
                SDL::Video::blit_surface( $brick_red_broken, $brick->rect,
                    $app, $brick->screen_rect );
                push @updates, $brick->screen_rect;
                play_ping( 255 - ( $brick_x * 255 / $screen_width ) );
            }
            last;
        }
    }
    push @updates, draw_score();
    SDL::Video::update_rects( $app, @updates );
}

sub draw_score {
    if ( $points && ( time - $points_added ) > 2 ) {
        $score += $points;
        $points = 0;
    }
    my $score_text;
    if ($points) {
        $score_text = "Score: $score +$points";
    } else {
        $score_text = "Score: $score";
    }

    $sprite_score->text($score_text);
    return $sprite_score->draw;
}

sub put_sprite {
    my ( $surface, $x, $y, $source, $source_rect ) = @_;

    my $dest_rect = SDL::Rect->new( $x, $y, $source->w, $source->h );
    SDL::Video::blit_surface( $source, $source_rect, $surface, $dest_rect );
    return $dest_rect;
}

sub play_ping {
    my $left = shift;
    if ($sound) {
        my $channel = SDL::MixPlayChannel( -1, $ping, 0 );
        SDL::MixSetPanning( $channel, 127 + $left / 2, 254 - $left / 2 );
    }
}

sub play_explosion {
    my $left = shift;
    if ($sound) {
        my $channel = SDL::MixPlayChannel( -1, $explosion, 0 );
        SDL::MixSetPanning( $channel, 127 + $left / 2, 254 - $left / 2 );
    }
}

sub play_explosion_multiple {
    my $left = shift;
    if ($sound) {
        my $channel = SDL::MixPlayChannel( -1, $explosion_multiple, 0 );
        SDL::MixSetPanning( $channel, 127 + $left / 2, 254 - $left / 2 );
    }
}

sub play_bounce {
    my $left = shift;
    if ($sound) {
        my $channel = SDL::MixPlayChannel( -1, $bounce, 0 );
        SDL::MixSetPanning( $channel, 127 + $left / 2, 254 - $left / 2 );
    }
}

sub load_image {
    my $filename = shift;
    my $image    = SDL::Video::display_format( SDL::IMG_Load($filename) );
    return $image;
}

sub load_image_alpha {
    my $filename = shift;
    my $image = SDL::Video::display_format_alpha( SDL::IMG_Load($filename) );
    return $image;
}

SDL::ShowCursor(1);
