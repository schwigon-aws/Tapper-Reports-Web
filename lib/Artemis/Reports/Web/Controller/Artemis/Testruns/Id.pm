package Artemis::Reports::Web::Controller::Artemis::Testruns::Id;

use strict;
use warnings;
use File::Basename;

use parent 'Artemis::Reports::Web::Controller::Base';

sub parse_precondition : Private
{
        my ( $testrun ) = @_;
        my $retval;
        foreach ($testrun->ordered_preconditions) {
                my $precondition = $_->precondition_as_hash;
                if ($precondition->{precondition_type} eq 'virt' ) {
                        $retval->{name} = $precondition->{name} || "Virtualisation Test";
                        $retval->{arch} = $precondition->{host}->{root}{arch};
                        $retval->{root} = $precondition->{host}->{root}{image} || $precondition->{host}->{root}{name}; # can be an image or copyfile or package
                        $retval->{test} = basename($precondition->{host}->{testprogram}{execname}) if $precondition->{host}->{testprogram}{execname};
                        foreach my $guest (@{$precondition->{guests}}) {
                                my $guest_summary;
                                $guest_summary->{arch} = $guest->{root}{arch};
                                $guest_summary->{root} = $guest->{root}{image} || $guest->{root}{name}; # can be an image or copyfile or package
                                $guest_summary->{test} = basename($guest->{testprogram}{execname}) if $guest->{testprogram}{execname};
                                push @{$retval->{guests}}, $guest_summary;
                        }
                        # can stop here because virt preconditions usually defines everything we need for a summary
                        return $retval;
                        
                }
        }

}


sub index :Path :Args(1)
{
        my ( $self, $c, $testrun_id ) = @_;
        my $report         : Stash;
        my $testrun        : Stash;
        my $preconditions  : Stash;

        my $reportlist_rgt : Stash = {};
        $testrun = $c->model('TestrunDB')->resultset('Testrun')->search(id => $testrun_id)->first();
        
        if (not $testrun) {
                $c->response->body(qq(No testrun with id "$testrun_id" found in the database!));
                return;
        }
        
        $preconditions = parse_precondition($testrun);
        
        my $rgt_reports = $c->model('ReportsDB')->resultset('Report')->search
          (
           {
            "reportgrouptestrun.testrun_id" => $testrun_id
           },
           {  order_by  => 'id desc',
              join      => [ 'reportgrouptestrun', ],
              '+select' => [ 'reportgrouptestrun.testrun_id', 'reportgrouptestrun.primaryreport' ],
              '+as'     => [ 'rgt_id',                        'rgt_primary'                      ],
           }
          );
        $reportlist_rgt = $c->forward('/artemis/reports/prepare_simple_reportlist', [ $rgt_reports ]);
        $report = $c->model('ReportsDB')->resultset('Report')->search
          (
           {
            "reportgrouptestrun.primaryreport" => 1,
           },
           {
            join => [ 'reportgrouptestrun', ]
           }
           );
        

        
}


1;