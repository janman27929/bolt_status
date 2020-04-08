use lib qw(. .. t lib ../lib /rdd/proj/lib);

use Prod;
use Get_status;

#---------------------[ USER_PARMS_START]---------------------
my $main_tag = 'Get_status';

my $rh_config = {
  work_file => './bolt.log' , # default
};

my $getopt_parms = {
  'w|f|work_file=s'	  => \$rh_config->{work_file},  
};   

my $usage_msg =<< 'EOF';
--------------------------------------------
Get_status.pl -[w|f|work_file FILENAME] 
--------------------------------------------

reads bolt log file and gives server status of job 

FILENAME defaults to ./bolt.log
EOF

#---------------------[ USER_PARMS_END]---------------------
my %data =(
  rh_config     => $rh_config,
  getopt_parms  => $getopt_parms,
  usage_msg     => $usage_msg,
);

my $main = Prod->new(%data);
$main->start($main_tag);




