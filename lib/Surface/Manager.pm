package Surface::Manager;

use strict;
use Mouse;
use Log::Minimal;

has surface => (
    is       => "rw",
    required => 1,
);

has check_interval => (
    is      => "rw",
    isa     => "Int",
    default => 5,
);

has enqueue_interval => (
    is      => "rw",
    isa     => "Int",
    default => 60,
);

no Mouse;

sub run {
    my $self = shift;
    my $surface = $self->surface;

    while (1) {
        if ($surface->is_active) {
            sleep $self->check_interval;
            next;
        }
        else {
            my $n;
            $n = $surface->cleanup;
            infof "%d old messages deleted.", $n if $n;

            $n = $surface->enqueue_all;
            infof "standalone mode: enqueue %d messages.", $n;
            sleep $self->enqueue_interval;
        }
    }
}

1;

__END__

