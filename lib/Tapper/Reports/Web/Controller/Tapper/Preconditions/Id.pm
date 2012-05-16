package Tapper::Reports::Web::Controller::Tapper::Preconditions::Id;

use strict;
use warnings;

use parent 'Tapper::Reports::Web::Controller::Base';

sub index :Path :Args(1)
{
        my ( $self, $c, $id ) = @_;
        my $precondition : Stash;

        my $precond_search = $c->model('TestrunDB')->resultset('Precondition')->find($id);
        if (not $precond_search) {
                $c->response->body(qq(No precondition with id "$id" found in the database!));
                return;
        }
        $precondition = $precond_search->precondition_as_hash;
        $precondition->{id} = $precond_search->id;
        return;
}

1;
