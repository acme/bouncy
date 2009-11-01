package Bouncy::FPS;
use Moose;
use MooseX::StrictConstructor;
use Time::HiRes qw(time sleep);

has 'max_fps' => ( is => 'ro', isa => 'Num', required => 1 );
has 'min_seconds_between_frames' => (
    is       => 'ro',
    isa      => 'Num',
    required => 0,
    lazy     => 1,
    default  => sub { my $self = shift; return 1 / $self->max_fps }
);
has 'last_frame_time' =>
    ( is => 'rw', isa => 'Num', required => 0, default => sub {time} );
has 'last_frame_seconds' =>
    ( is => 'rw', isa => 'Num', required => 0, default => 0 );
has 'last_frame_sleep' =>
    ( is => 'rw', isa => 'Num', required => 0, default => 0 );

__PACKAGE__->meta->make_immutable;

sub frame {
    my $self = shift;
    my $time = time;

    my $last_frame_seconds = $time - $self->last_frame_time;

    if ( $last_frame_seconds < $self->min_seconds_between_frames ) {
        my $seconds_to_sleep
            = $self->min_seconds_between_frames - $last_frame_seconds;
        my $actually_slept = sleep($seconds_to_sleep);
        $self->last_frame_sleep($actually_slept);
        $self->last_frame_time( $time + $actually_slept );
        $self->last_frame_seconds( $last_frame_seconds + $actually_slept );
    } else {
        $self->last_frame_sleep(0);
        $self->last_frame_time($time);
        $self->last_frame_seconds($last_frame_seconds);
    }

}

1;
