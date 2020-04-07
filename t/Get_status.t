use lib qw(. .. t lib ../lib /rdd/proj/lib);

use v5.16;
use Test2::V0; 
use Test2::Plugin::DieOnFail;
use Modern::Perl;
use Carp::Always;
use Rdd_Mocks qw(get_mock load_mock);

use base qw(Test::Class);

my $pkg_name = 'Get_status';
require $pkg_name . ".pm";

load_mock($pkg_name);
my $mock_01 = mock 'Get_status' => (
  override => [
    get_curr_date_time        => sub{'Sat Apr  4 11:01:59 2020'},
    get_bolt_job_start_time   => sub{'16:45 0:00'},
  ],
);

#-------------------------[ TEST HARNESS METHODS HERE ]-------------------------
# this runs only ONCE, on program startup
sub startup   : Test(startup) {
  my $self = shift;
}

# this runs BEFORE each and every test
sub setup : Test(setup) {
  my $self = shift;
}

# this runs AFTER each and every test
sub teardown : Test(teardown) {
  my $self = shift;
}

# this runs only ONCE, on program exit
sub shutdown  : Test(shutdown) {
  my $self = shift;
}

#-------------------------------[ UNIT TESTS HERE ]-----------------------------

sub AA_test_main : Test(no_plan) {
  #main->set_rhConfig({work_file => 't/cpkoel_prod_mock.log'});
  @ARGV = qw(-f t/cpkoel_prod_mock.log);
  main->start;
}

sub test_Get_status : Test(no_plan) {
  my $self  = Get_status->new(
    work_file => 't/cpkoel_prod_mock.log',
  ); 
  $self->setup;
  my $fin = $self->get_finished;
  is  scalar @$fin, 2, 'is: finished elems';
  is scalar @{$self->get_failed}, 2, 'is: failed elems';
  my $rpt = $self->make_report();
  like ($rpt, qr/server10\s+server11\s+server12\s+server13\s+server5/i, 'like: match for active servers');
  is  split (/^/, $rpt), 14, 'got right report length';
  print '-'x30, '[ test_Get_status ]', '-'x30 ,"\n";
  $DB::single = 1; 
  $DB::single = 1; 
}

if (! caller()) {
  Test::Class->runtests;
}


