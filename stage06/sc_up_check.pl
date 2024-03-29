#!/usr/bin/perl
use strict;
use Cwd;

$ENV{'PWD'} = getcwd();

# does_It_Have( $arg1, $arg2 )
# does the string $arg1 have $arg2 in it ??
sub does_It_Have{
	my ($string, $target) = @_;
	if( $string =~ /$target/ ){
		return 1;
	};
	return 0;
};



#################### EUCALYPTUS COMPONENTS CHECK ##########################

my @ip_lst;
my @distro_lst;
my @version_lst;
my @arch_lst;
my @source_lst;
my @roll_lst;

my %cc_lst;
my %sc_lst;
my %nc_lst;

my $clc_index = -1;
my $cc_index = -1;
my $sc_index = -1;
my $ws_index = -1;

my $clc_ip = "";
my $cc_ip = "";
my $sc_ip = "";
my $ws_ip = "";

my $nc_ip = "";

my $rev_no = 0;

my $max_cc_num = 0;

my $index = 0;

my $vmbroker_group  = "";

$ENV{'EUCALYPTUS'} = "/opt/eucalyptus";

#### read the input list
read_input_file_for_vmware();


if( $source_lst[0] eq "PACKAGE" || $source_lst[0] eq "REPO" ){
	$ENV{'EUCALYPTUS'} = "";
};




### Check if Storage Controllers are Rebooted Cleanly
print "\n\n----------------------- Signal Check on Storage Controllers -----------------------\n";

my $is_error = 0;
my $is_checked = 0;

for( my $i = 0; $i <= @ip_lst && $is_error == 0; $i++){
	my $this_ip = $ip_lst[$i];
	my $this_distro = $distro_lst[$i];
	my $this_version = $version_lst[$i];
	my $this_arch = $arch_lst[$i];
	my $this_roll = $roll_lst[$i];

	$this_distro = lc($this_distro);

	###	if distro is SC,
	if( does_It_Have($this_roll, "SC") || does_It_Have($this_roll, "NC") ){
		$is_error = signal_check_machine($this_ip);
		print "\n";
		$is_checked = 1;
	};
};

print "\n";

if( $is_error == 1 ){
	print "\n[TEST_REPORT]\tFAILED TO CONTACT SOME STORAGE CONTROLLER MACHINES !!!\n\n";
	exit(1);
};

if( $is_checked == 1 ){
	print "\nSleeping for 2 min for Stablization\n";
	sleep(120);

	print "\n[TEST_REPORT]\tALL STORAGE CONTROLLER MACHINES ARE UP AND RUNNING\n\n";
}else{
	print "\n[TEST_REPORT]\tNO ACTIONS TAKEN\n\n";
};

exit(0);





###################### SUBROUTINES ########################################

sub print_time{
	my ($sec,$min,$hour,$mday,$mon,$year,$wday, $yday,$isdst)=localtime(time);
        my $this_time = sprintf "[%4d-%02d-%02d %02d:%02d:%02d]\t", $year+1900,$mon+1,$mday,$hour,$min,$sec;
	return $this_time;
};

sub signal_check_machine{

	my $this_ip = shift @_;

	print "\n\n----------------------- Signal Check Machine $this_ip -----------------------\n";
	print "\n";

	my $is_up = 0;

	for(my $i = 0; $i < 30 && $is_up == 0 ; $i++ ){

		my $outstr = "";
	
		print print_time() . " TRIAL $i: Signal Check Machine $this_ip\n";
		print("ssh -o BatchMode=yes -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -o StrictHostKeyChecking=no root\@$this_ip \"uname -r\"\n");
		print "\n";

		$outstr = `ssh -o BatchMode=yes -o ServerAliveInterval=1 -o ServerAliveCountMax=5 -o StrictHostKeyChecking=no root\@$this_ip \"uname -r\"`;

		if( $outstr =~ /^\d/ ){
			print "RETURNED: " . $outstr;
			print "\n";
			$is_up = 1;
		}else{
			print "No ANSWERS\n\n";
			sleep(30);
		};
	};

	print print_time() . " Machine $this_ip is UP\n";
	print "\n";

	if( $is_up == 1 ){
		return 0;
	};
	return 1;
};


sub read_input_file_for_vmware{

	open( LIST, "../input/2b_tested.lst" ) or die "$!";
	my $line;
	while( $line = <LIST> ){
		chomp($line);
		if( $line =~ /^([\d\.]+)\t(.+)\t(.+)\t(\d+)\t(.+)\t\[(.+)\]/ ){
			print "IP $1 [Distro $2, Version $3, Arch $4] was built from $5 with Eucalyptus-$6\n";

			if( 1 || !( $2 eq "VMWARE" || $2 eq "WINDOWS" ) ){		### QUICK HACK TO INCLUDE VMWARE	012412

				push( @ip_lst, $1 );
				push( @distro_lst, $2 );
				push( @version_lst, $3 );
				push( @arch_lst, $4 );
				push( @source_lst, $5 );
				push( @roll_lst, $6 );

				my $this_roll = $6;

				if( does_It_Have($this_roll, "CLC") ){
					$clc_index = $index;
					$clc_ip = $1;
				};

				if( does_It_Have($this_roll, "CC") ){
					$cc_index = $index;
					$cc_ip = $1;
	
					if( $this_roll =~ /CC(\d+)/ ){
						$cc_lst{"CC_$1"} = $cc_ip;
						if( $1 > $max_cc_num ){
							$max_cc_num = $1;
						};
					};			
				};

				if( does_It_Have($this_roll, "SC") ){
					$sc_index = $index;
					$sc_ip = $1;
	
					if( $this_roll =~ /SC(\d+)/ ){
	                	                $sc_lst{"SC_$1"} = $sc_ip;
	                	        };
				};

				if( does_It_Have($this_roll, "WS") ){
	                	        $ws_index = $index;
	                	        $ws_ip = $1;
	                	};
	
				if( does_It_Have($this_roll, "NC") ){
					$nc_ip = $1;
					if( $this_roll =~ /NC(\d+)/ ){
						if( $nc_lst{"NC_$1"} eq	 "" ){
	        	                        	$nc_lst{"NC_$1"} = $nc_ip;
						}else{
							$nc_lst{"NC_$1"} = $nc_lst{"NC_$1"} . " " . $nc_ip;
						};
	        	                };
	        	        };
				$index++;
	
			}elsif( $2 eq "VMWARE" ){
				my $this_roll = $6;
				if( does_It_Have($this_roll, "NC") ){
                                        if( $this_roll =~ /NC(\d+)/ ){
						if( !($vmbroker_group =~ /$1,/) ){
							$vmbroker_group .= $1 . ",";
						};
					};
				};
			};

	        }elsif( $line =~ /^BZR_REVISION\s+(\d+)/  ){
			$rev_no = $1;
			print "REVISION NUMBER is $rev_no\n";
		};
	};

	close( LIST );

	chop($vmbroker_group);

	return 0;
};
