package Tapper::Reports::Web::Controller::Tapper::Rss;

use XML::Feed;
use DateTime;
use Tapper::Reports::Web::Util::Filter;

use parent 'Catalyst::Controller';

use common::sense;
## no critic (RequireUseStrict)

=head2 index

Controller for RSS feeds of results reported to Tapper Reports
Framework. The function expectes an unrestricted number of arguments
that are interpreted as filters. Thus, the arguments need to be in pairs
of $filter_type/$filter_value. Since index is a catalyst function the
typical catalyst arguments $self and $c do not occur in the API doc.

@param array - filter arguments

=cut

sub index :Path :Args()
{
        my ($self,$c, @args) = @_;

        my $filter = Tapper::Reports::Web::Util::Filter->new(context => $c);


        my $feed = XML::Feed->new('RSS');
        $feed->title( ' RSS Feed' );
        $feed->link( $c->req->base ); # link to the site.
        $feed->description('Tapper Reports');

        my $feed_entry;
        my $title;


        my $filter_condition;


        $filter_condition = $filter->parse_filters(\@args);
        if ( defined $filter_condition->{error} ) {
                $feed_entry  = XML::Feed::Entry->new('RSS');
                $feed_entry->title( $filter_condition->{error} );
                $feed_entry->issued( DateTime->now );
                $feed->add_entry($feed_entry);
        }

        # default 2 days
        if (not $filter_condition->{early}{created_at}) {
                my $now = DateTime->now();
                $now->subtract(days => 2);
                $filter_condition->{early}{created_at} = {'>' => $now};
        }


        my $reports = $c->model('ReportsDB')->resultset('Report')->search
          (
           $filter_condition->{early},
           {
            columns   => [ qw( id
                               suite_id
                               created_at
                               machine_name
                               created_at
                               success_ratio
                               successgrade
                               reviewed_successgrade
                               total
                            )],
           }
           );
        foreach my $filter (@{$filter_condition->{late}}) {
                $reports = $reports->search($filter);
        }


        # Process the entries
        foreach my $report ($reports->all) {
                $feed_entry  = XML::Feed::Entry->new('RSS');
                $title       = $report->successgrade;
                $title      .= " ".($report->success_ratio // 0)."%";
                $title      .= " ".($report->suite ? $report->suite->name : 'unknown suite');
                $title      .= " @ ";
                $title      .= $report->machine_name || 'unknown machine';
                $feed_entry->title( $title );
                $feed_entry->link( $c->req->base->as_string.'/tapper/reports/id/'.$report->id );
                $feed_entry->issued( $report->created_at );
                $feed->add_entry($feed_entry);
        }

        $c->res->body( $feed->as_xml );
}

1;

__END__

=head1 NAME

Tapper::Reports::Web::Controller::Tapper::Hardware - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head1 AUTHOR

Steffen Schwigon,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
