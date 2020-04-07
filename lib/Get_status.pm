use Modern::Perl;
use v5.10;

package Get_status { 
#--user parms
my $width=100;
my $cols=5;

#--system parms
my $col_width = int($width  / $cols);
our $status={};

sub work_file {shift->{work_file}}
sub new { 
  my ($class, %parms) = @_;
  my $self = bless{%parms}, $class;
  return $self; 
}

sub setup     { 
  my ($self, %parms)=@_;  
  $self->load;
  $self;
}

sub load {
	my ($self,) = @_;
  my $file = $self->work_file;
  die ("FAIL: cant read file:$file:\n") unless (-r $file);
  open (my $fh, '<', $self->work_file ) or die "Open:$self->work_file:$!";
  while (<$fh>) {
    next if /^\s*$/;
    next if $self->is_Started($_);
    next if $self->is_Failed($_);
    next if $self->is_Finished($_);
  }
  close ($fh) or die "Close:$self->work_file:$!";
}

sub is_Started {
	my ($self,$text_line) = @_;
  return 0 unless $text_line =~ /^Started on (\S+).../;
  $status->{$1}= 'started';
  return 1;
} 

sub is_Failed {
	my ($self,$text_line) = @_;
  return 0 unless $text_line =~ /^Failed on (\S+):/;
  $status->{$1}= 'failed';
  return 1;
} 

sub is_Finished {
	my ($self,$text_line) = @_;
  return 0 unless $text_line =~ /^Finished on (\S+):/;
  $status->{$1}= 'finished';
  return 1;
} 

sub get_still_active  {shift;_get_status('started')}
sub get_finished      {shift;_get_status('finished')}
sub get_failed        {shift;_get_status('failed')}

sub _get_status {
  my ($tag) = @_;
  my @list; 
  map {push @list, $_} grep {$status->{$_} eq $tag } keys %$status;
  return \@list;
}

sub make_report {
	my ($self,) = @_;
  my %rpt_data = (
    curr_date_time      => get_curr_date_time(),
    title => {
      active    => prn_title('Still Active Servers'),
      finished  => prn_title('Finished Servers'),
      failed    => prn_title('Failed Servers'),
      footer    => prn_title(),
    },
    active_servers      => $self->get_formatted_status_list('started'),
    finished_servers    => $self->get_formatted_status_list('finished'),
    failed_servers      => $self->get_formatted_status_list('failed'),
    total_server_count  => get_total_server_count(),
    bolt_job_start_time => get_bolt_job_start_time(),
  );
  my $rpt =<<"EOF";
Bolt Status Report for Date: $rpt_data{curr_date_time}
$rpt_data{title}{active}
$rpt_data{active_servers}
$rpt_data{title}{failed}
$rpt_data{failed_servers}
$rpt_data{title}{finished}
$rpt_data{finished_servers}
$rpt_data{title}{footer}
Total     : $rpt_data{total_server_count}
Start Time: $rpt_data{bolt_job_start_time}
EOF
  $rpt;
}

sub get_curr_date_time {scalar localtime}

sub get_formatted_status_list { 
	my ($self, $tag, @user_data) = @_;
  die ("FAIL: bad \$tag\n") unless ($tag =~ /^\w+$/);
  my $data = _get_status($tag);
  $self->get_formatted_list ($data, @user_data);
}

sub get_formatted_list {
	my ($self, $org_list, $cols, $width) = @_;
  die ("FAIL: bad \$org_list\n") if (!$org_list or ref $org_list ne 'ARRAY');
  $cols   ||= 5;
  $width  ||= 100;
  my $fmt_list = '';
  my $printf_expr = calc_print_expr($col_width, $cols);
  my @list = sort {$a cmp $b} @$org_list;
  my $row = 0;
  for my $i (1..@list-1) {
    next unless ($i % $cols == 0);
    $row++;
    $fmt_list .= sprintf($printf_expr, @list[($i-$cols) .. $i-1]);
  }
  return $fmt_list if ($row * $cols -1 == @list);
  my @tmp = @list[($row * $cols) .. @list-1];
  $fmt_list .= sprintf(  calc_print_expr($col_width, scalar @tmp), @tmp);
  return $fmt_list;
}

sub prn_title {
	my ($title) = @_;
  return '-' x $width unless $title;
  $title = "[ $title ]";
  my $leader_width = ($width - length($title)) / 2;
  return '-' x $leader_width . $title . '-' x $leader_width;
}

sub calc_print_expr {
	my ($col_width, $cols) = @_;
  #TODO: parm_checks
  return "%-${col_width}s" x$cols . "\n";
}

sub get_total_server_count {
	my ($self,) = @_;
  scalar keys %$status
}

# get_bolt_job_start_time
sub get_bolt_job_start_time {
	my ($self,) = @_;
  $DB::single = 1; 
  my @stdout = qx(ps faux | grep bin/bolt | grep -v grep);
  return 'FINISHED' unless @stdout;
  return join(' ', (split(/\s+/,$stdout[0]))[8,9]);
  # root     29854  0.0  0.0 107956   356 pts/0    S    16:36   0:00          \_ sleep 30
}

sub main     { 
  my ($self)=@_;  
  print $self->make_report();
  $self;
}

sub teardown  { 
  my ($self, %parms)=@_;  
  $self;
}

}#-- Get_status


{
package main; 
use Carp::Always;
use Getopt::Long ();
use Modern::Perl;

my $rhConfig = {
  debug => 0,
  work_file => './bolt.log',
};

my %hParms = ( 
  'w|f|work_file=s'	=> \$rhConfig->{work_file},  
);   

sub ShowError {
  print "$_[0]\n" if @_;   
  print <<'EOF';

--------------------------------------------
get_status.pl -[w|f|work_file FILENAME] 
--------------------------------------------

reads bolt log file and gives server status of job 

FILENAME defaults to ./bolt.log

EOF
  exit $?;
}

sub set_rhConfig {shift; $rhConfig = shift}

sub start {
eval {
  Getopt::Long::GetOptions (%hParms) or die ("FAIL: CLI errors");
  my $self = Get_status->new(
    %$rhConfig,
  );

  $self->setup();
  $self->main ();
  $self->teardown();
};

ShowError($@) if $@;
}

}#-- main

1;

