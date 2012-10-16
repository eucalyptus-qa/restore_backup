#!/usr/bin/perl
use strict;

$ENV{'EUCALYPTUS'} = "/opt/eucalyptus";
$ENV{'EUCA_INSTANCES'} = "/disk1/storage/eucalyptus/instances";

$ENV{'BACKUP_LOCATION'} = "/disk1/storage/backup";


print "\n";
get_my_ip();

if( $ENV{'MY_IP'} eq "" ){
	print "[ERROR]\tCouldn't detect my IP\n";
	exit(1);
};
print "My IP is $ENV{'MY_IP'}\n";

read_input_file();

print "\nDetected SOURCE is $ENV{'QA_SOURCE'}\n";

if( $ENV{'QA_SOURCE'} ne "BZR" ){
	$ENV{'EUCALYPTUS'} = "";
};

print "\$ENV{'EUCALYPTUS'} = \"$ENV{'EUCALYPTUS'}\"\n\n";


print "\n########################################################################\n";

report_disk_status();

print "\nMonitoring Cloud Conditions\n";

print "\n";
print("ls -lad $ENV{'EUCALYPTUS'}/var/run/eucalyptus/eucalyptus-cloud.pid\n");
system("ls -lad $ENV{'EUCALYPTUS'}/var/run/eucalyptus/eucalyptus-cloud.pid");

print "\n";
print("cat $ENV{'EUCALYPTUS'}/var/run/eucalyptus/eucalyptus-cloud.pid\n");
system("cat $ENV{'EUCALYPTUS'}/var/run/eucalyptus/eucalyptus-cloud.pid");

print "\n";
print("ps axww | grep euca\n");
system("ps axww | grep euca");
print "\n";

### stop all components

print "\nStopping all eucalyptus components\n";
print "\n$ENV{'EUCALYPTUS'}/etc/init.d/eucalyptus-cloud stop\n";
system("$ENV{'EUCALYPTUS'}/etc/init.d/eucalyptus-cloud stop");
sleep(3);
print "\n$ENV{'EUCALYPTUS'}/etc/init.d/eucalyptus-cc stop\n";
system("$ENV{'EUCALYPTUS'}/etc/init.d/eucalyptus-cc stop");
sleep(3);
print "\n$ENV{'EUCALYPTUS'}/etc/init.d/eucalyptus-nc stop\n";
system("$ENV{'EUCALYPTUS'}/etc/init.d/eucalyptus-nc stop");
sleep(3);

report_disk_status();

report_tgt_status();

### Sangmin's request
print "\n";
print "tgtadm --op delete --mode account --user eucalyptus\n";
system("tgtadm --op delete --mode account --user eucalyptus");
print "\n";
sleep(3);

report_tgt_status();

print "\n########################################################################\n";

if( is_killall_dhcpd_when_restore_from_memo() == 1 ){
	print "\nKilling dhcpd\n";
	system("killall dhcpd");
	sleep(3);
	system("killall dhcpd3");
	sleep(3);

};

print "\n";
print "After Stopping Eucalyptus Components\n";
print("ps axww | grep euca\n");
system("ps axww | grep euca");
print "\n";

print "\nTEMP SOLUTION: Killing eucalyptus-cloud\n";
print("killall -9 eucalyptus-cloud\n");
system("killall -9 eucalyptus-cloud");
print "\n";
sleep(1);

print "\nTEMP SOLUTION: Killing mysqld\n";
print("killall -9 mysqld\n");
system("killall -9 mysqld");
print "\n";
sleep(1);

print "\nTEMP SOLUTION: Killing postgres\n";
print("killall -9 postgres\n");
system("killall -9 postgres");
print "\n";
sleep(1);


restore_network_state();

###	hack to remove stange route issue on rhel5 	added 020812
print "\n";
print "route del qa-server.eucalyptus\n";
system("route del qa-server.eucalyptus");
print "\n";
sleep(1);

report_disk_status();

### clean the instance directory
print "\nclean up the eucalyptus instance directory\n";
prun ("rm -fr $ENV{'EUCA_INSTANCES'}/*");

report_disk_status();

###	TRY CLEAN STOP ON TGTD FIRST	ADDED 010912
print "\n";
print("service tgtd force-stop\n");
system("service tgtd force-stop");
print "\n";
sleep(3);

print "\n";
print("/etc/init.d/tgtd force-stop\n");
system("/etc/init.d/tgtd force-stop");
print "\n";
sleep(3);

###	TO PREVENT 'DARK MATTER'	010512
print "\n";
print("killall -9 tgtd\n");
system("killall -9 tgtd");
print "\n";
sleep(1);

###	ADDED
kill_nine_tgt();

print("ps aux | grep tgt\n");
system("ps aux | grep tgt");
print "\n";
sleep(1);

report_tgt_status();

for (my $i=0; $i<3; $i++) { # run three times for a dependency tree of depth three
#	prun ("dmsetup table | grep euca | cut -d':' -f 1 | sort | uniq | xargs -L 1 dmsetup remove");
#	prun ("losetup -a | grep vmware | cut -d':' -f 1 | xargs -L 1 losetup -d");

	prun ("dmsetup table | cut -d':' -f 1 | sort | uniq | xargs -L 1 dmsetup remove");
	prun ("losetup -a | cut -d':' -f 1 | xargs -L 1 losetup -d");
	print "\n";
	sleep(2);
}

report_disk_status();

### copy the backup instance directory			### not needed ? since they are empty	061011
#print "\ncopy the backup instance directory back\n";
#print "\ncp -ar /disk1/storage/eucalyptus/backup/. $ENV{'EUCA_INSTANCES'}/.\n";
#system("cp -ar /disk1/storage/eucalyptus/backup/. $ENV{'EUCA_INSTANCES'}/.");

if( -e "/tmp/eucalyptus" ){
	print "\nclean up /tmp/eucalyptus\n";
	print "\nrm -fr /tmp/eucalyptus\n";
	system("rm -fr /tmp/eucalyptus");
};
print "\n";

###	ADDED 011512
print "\n";
print "Clean Up /root Directory\n";
print "\n";

print "rm -fr /root/cred_depot\n";
system("rm -fr /root/cred_depot");
print "\n";

print "rm -fr /root/seeds\n";
system("rm -fr /root/seeds");
print "\n";

print "rm -f /root/*.zip\n";
system("rm -f /root/*.zip");
print "\n";

print "rm -f /root/*.pem\n";
system("rm -f /root/*.pem");
print "\n";

print "rm -f /root/eucarc\n";
system("rm -f /root/eucarc");
print "\n";

print "rm -f /root/iamrc\n";
system("rm -f /root/iamrc");
print "\n";

print "rm -f /root/jssecacerts\n";
system("rm -f /root/jssecacerts");
print "\n";

print "\n";
print "\n";

#create a directory 
#system("chmod 755 /tmp");
#system("mkdir -p /tmp/eucalyptus");
#system("chmod 755 /tmp/eucalyptus");


print "\n########################################################################\n";


if( $ENV{'EUCALYPTUS'} ne "" ){
	### SOURCE = BZR
	print "\n\nHandling BZR SOURCE case\n";

	#clean the euca directory
	print "\nclean up the eucalyptus directory /opt/eucalyptus\n";
	system("rm -fr /opt/eucalyptus");

	system("mkdir -p /opt/eucalyptus");
	system("chmod 755 /opt/eucalyptus");

	print "\nCopy the backed-up eucalyptus directory back\n";
#	print "\np -ar /backup/eucalyptus/. /opt/eucalyptus/.\n";
#	system("cp -ar /backup/eucalyptus/. /opt/eucalyptus/.");

	print "\ncp -Lr $ENV{'BACKUP_LOCATION'}/. /opt/eucalyptus/.\n";
	system("cp -Lr $ENV{'BACKUP_LOCATION'}/. /opt/eucalyptus/.");

	restart_iscsid();		###	ADDED 060612

}else{
	### SOURCE = PACKAGE or REPO
	print "\n\nHandling REPO case\n";

	if( $ENV{'QA_DISTRO'} eq "CENTOS" || $ENV{'QA_DISTRO'} eq "RHEL" ){
#		print "\nIn case of CENTOS or RHEL, adjusting python link\n";
#		fix_python_link();
	};

print "\n########################################################################\n";


	report_disk_status();

	print "\nUNINSTALL PACKAGE\n\n";
	uninstall_package();

	report_disk_status();


print "\n########################################################################\n";

	#clean the euca artifact directories
	print "\n\nClean the euca artifact directories\n";
	print "\nrm -fr /var/lib/eucalyptus\n";
        system("rm -fr /var/lib/eucalyptus");
	print "\nrm -fr /etc/eucalyptus\n";
        system("rm -fr /etc/eucalyptus");

	### Added 090611
	print "\nrm -fr /var/log/eucalyptus\n";
	system("rm -fr /var/log/eucalyptus");

print "\n########################################################################\n";

	report_disk_status();

	restart_iscsid();		###	ADDED 060612

#	remove_tgt();

	print "\nINSTALL FROM PACKAGE\n\n";
	install_from_package();

print "\n########################################################################\n";

	if( $ENV{'QA_DISTRO'} eq "CENTOS" || $ENV{'QA_DISTRO'} eq "RHEL" ){
#		print "\nIn case of CENTOS or RHEL, returning python link\n";
#		return_python_link();
	};
};

report_disk_status();

post_ops_create_link_for_qa_machine();			### solution to disk space problem	061011

report_disk_status();

post_ops_mount_disk();				### Check for redundancy with the ops above

report_disk_status();

report_tgt_status();

#copy the euca directory
#system("cp -ar /backup/eucalyptus/. /tmp/eucalyptus/.");

#create a symbloic link
#system("ln -s /backup/eucalyptus /opt");

print "\n########################################################################\n";


print "\n\n[TEST_REPORT]\tEND OF CLEANUP AND RESTORE\n\n";

exit(0);

1;

sub prun {
    my ($cmd) = @_;
    print ("$cmd\n");
    return system ("$cmd");
}

sub get_my_ip{
#        my $scan = `ifconfig | grep "inet addr"`;
        my $scan = `ip addr show | grep inet`;
	my @temp_array = split("\n", $scan);
	foreach my $tip (@temp_array){
        	if( $tip =~ /(192\.168\.\d+\.\d+)/ ){
			my $cip = $1;
			my $temp_buf = `cat ./2b_tested.lst | grep $cip`;
			if( $temp_buf =~ /$cip/m ){
        	        	$ENV{'MY_IP'} = $cip;
				return 0;
			};
        	};
	};
        return 1;
};


# does_It_Have( $arg1, $arg2 )
# does the string $arg1 have $arg2 in it ??
sub does_It_Have{
        my ($string, $target) = @_;
        if( $string =~ /$target/ ){
                return 1;
        };
        return 0;
};


# Read input values from 2b_tested.lst
sub read_input_file{

	my $is_memo = 0;
	my $memo = "";

	my %vmware_group;
	my $is_vmware_included = 0;
	
	open( INPUT, "< ./2b_tested.lst" ) || die $!;

	my $line;
	while( $line = <INPUT> ){
		chomp($line);
		if( $is_memo ){
			if( $line ne "END_MEMO" ){
				$memo .= $line . "\n";
			};
		};

        	if( $line =~ /^([\d\.]+)\t(.+)\t(.+)\t(\d+)\t(.+)\t\[(.+)\]/ ){
			if( $ENV{'MY_IP'} eq $1 ){
				print "\n";
				print "IP $1 [Distro $2, Version $3, ARCH $4] will be built from $5 as Eucalyptus-$6\n";
				$ENV{'QA_DISTRO'} = $2;
				$ENV{'QA_DISTRO_VER'} = $3;
				$ENV{'QA_ARCH'} = $4;
				$ENV{'QA_SOURCE'} = $5;
				$ENV{'QA_ROLL'} = $6;
			};

			### ADDITION TO HANDLE VMWARE BROKER REPO BUILD	100711
			my $this_distro = lc($2);
			my $this_roll = $6;

			if( $this_distro eq "vmware" ){
				if( $this_roll =~ /NC(\d+)/ ){
					$vmware_group{$1} = 1;
					$is_vmware_included = 1;
				};
			};

        	}elsif( $line =~ /^NETWORK\t(.+)/ ){
        	        print( "\nNETWORK\t$1\n" );
			$ENV{'QA_NETWORK_MODE'} = $1;
        	}elsif( $line =~ /^BZR_DIRECTORY\t(.+)/ ){
        	        print ( "\nBZR DIRECTORY\t$1\n" );
			$ENV{'QA_BZR_DIR'} = $1; 
        	}elsif( $line =~ /^BZR_REVISION\t(.+)/ ){
        	        print ( "\nBZR REVISION\t$1\n" );
			$ENV{'QA_BZR_REV'} = $1;
        	}elsif( $line =~ /^GIT_REPO\s+(.+)/ ){
        	        print ( "\nGIT_REPO\t$1\n" );
			$ENV{'QA_GIT_REPO'} = $1;
		}elsif( $line =~ /^PXE_TYPE\t(.+)/ ){
                        print ( "\nPXE_TYPE\t$1\n" );
			$ENV{'QA_PXETYPE'} = $1;
		}elsif( $line =~ /^TESTNAME\s+(.+)/ ){
			print "\nTESTNAME\t$1\n";
			$ENV{'QA_TESTNAME'} = $1;
		}elsif( $line =~ /^TEST_SEQ\s+(.+)/ ){
			print "\nTEST_SEQ\t$1\n";
			$ENV{'QA_TEST_SEQ'} = $1;
		}elsif( $line =~ /^MEMO/ ){
			$is_memo = 1;
		}elsif( $line =~ /^END_MEMO/ ){
			$is_memo = 0;
		};
	};	

	close(INPUT);

	if( $is_vmware_included == 1 ){
		if( $ENV{'QA_ROLL'} =~ /CLC/ || $ENV{'QA_ROLL'} =~ /WS/ || $ENV{'QA_ROLL'} =~ /SC/ ){
			$memo .= "\nINSTALL_VMBROKER=YES\n";
		}elsif( $ENV{'QA_ROLL'} =~ /CC(\d+)/){
			if( $vmware_group{$1} == 1){
				$memo .= "\nINSTALL_VMBROKER=YES\n";
			};
		};
	};

	$ENV{'QA_MEMO'} = $memo;

	return 0;
};

sub is_install_vmbroker_from_memo{
	if( $ENV{'QA_MEMO'} =~ /^INSTALL_VMBROKER=YES/m ){
		print "\n";
		print "FOUND in MEMO\n";
		print "INSTALL_VMBROKER=YES\n";
		print "\n";
		$ENV{'QA_INSTALL_VMBROKER'} = "YES";
		return 1;
	};
	return 0;
};


sub is_install_san_from_memo{
	$ENV{'QA_INSTALL_SAN'} = "NO";
        if( $ENV{'QA_MEMO'} =~ /^SAN_PROVIDER=(\w+)/m ){
		my $san_option = $1;
                print "FOUND in MEMO\n";
                print "SAN_PROVIDER=$san_option\n";
		if( !($san_option =~ /^NO/) ){
                	$ENV{'QA_INSTALL_SAN'} = "YES";
                	$ENV{'QA_MEMO_SAN_PROVIDER'} = $san_option;
                	return 1;
		};
        };
	
	if( $ENV{'QA_MEMO'} =~ /^EBS_STORAGE_MANAGER=(\w+)/m ){
		my $ebs_option = $1;
                print "FOUND in MEMO\n";
                print "EBS_STORAGE_MANAGER=$ebs_option\n";
		if( !($ebs_option =~ /^NO/) ){
                	$ENV{'QA_INSTALL_SAN'} = "YES";
                	$ENV{'QA_MEMO_EBS_STORAGE_MANAGER'} = $ebs_option;
                	return 1;
		};
        };
        return 0;
};


############################################# PACKAGE UN-INSTALLATION SUBROUTINES #####################################

sub ubuntu_package_uninstall{

	my $roll = $ENV{'QA_ROLL'};
	my $bzr_dir = $ENV{'QA_BZR_DIR'};

	my $pkgname = "eucalyptus";

### temp fix for puma 030211 V
	if( $bzr_dir =~ /eee/ ){
#		$pkgname = "eucalyptus-eee";
	};

#	system("apt-get --force-yes -y remove " . $pkgname . "-cloud");
#	system("apt-get --force-yes -y remove " . $pkgname . "-cc");
#	system("apt-get --force-yes -y remove " . $pkgname . "-sc");
#	system("apt-get --force-yes -y remove " . $pkgname . "-walrus");
#	system("apt-get --force-yes -y remove " . $pkgname . "-nc");

	system("apt-get --force-yes -y purge eucalyptus* ");
        system("apt-get --force-yes -y purge python*-eucadmin ");
        system("apt-get --force-yes -y purge euca2ools");			### NEEDED ??

	return 0;
};


sub debian_package_uninstall{

	my $distro = $ENV{'QA_DISTRO'};
	my $source = $ENV{'QA_SOURCE'};
	my $roll = $ENV{'QA_ROLL'};
	
	my $bzr_dir = $ENV{'QA_BZR_DIR'};

	my $pkgname = "eucalyptus";

	if( $bzr_dir =~ /eee/ ){
		$pkgname = "eucalyptus-eee";
	};

	# Eucalyptus Un-Install
#	system("apt-get --force-yes -y remove " . $pkgname . "-cc");
#	system("apt-get --force-yes -y remove " . $pkgname . "-cloud");
#	system("apt-get --force-yes -y remove " . $pkgname . "-sc");
#	system("apt-get --force-yes -y remove " . $pkgname . "-walrus");
#	system("apt-get --force-yes -y remove " . $pkgname . "-nc");

	system("apt-get --force-yes -y purge eucalyptus* ");
        system("apt-get --force-yes -y purge python*-eucadmin ");
        system("apt-get --force-yes -y purge euca2ools");			### NEEDED ??

	return 0;
};


sub opensuse_package_euca_repo_uninstall{
	
	my $distro = $ENV{'QA_DISTRO'};
	my $source = $ENV{'QA_SOURCE'};
	my $roll = $ENV{'QA_ROLL'};
	my $bzr_dir = $ENV{'QA_BZR_DIR'};

	my $pkgname = "eucalyptus";

	if( $bzr_dir =~ /eee/ ){
		$pkgname = "eucalyptus-eee";
	};

	# Eucalyptus Un-Install
#	system("zypper -n rm " . $pkgname . "-cc");
#	system("zypper -n rm " . $pkgname . "-cloud");
#	system("zypper -n rm " . $pkgname . "-sc");
#	system("zypper -n rm " . $pkgname . "-walrus");
#	system("zypper -n rm " . $pkgname . "-nc");

	system("zypper -n rm eucalyptus* ");
        system("zypper -n rm python*-eucadmin ");
        system("zypper -n rm euca2ools");			### NEEDED ??


	return 0;
};


sub opensuse_package_local_repo_uninstall{

	my $distro = $ENV{'QA_DISTRO'};
	my $arch = $ENV{'QA_ARCH'};
	my $source = $ENV{'QA_SOURCE'};
	my $roll = $ENV{'QA_ROLL'};

	my $bzr_dir = $ENV{'QA_BZR_DIR'};
	my $bzr_rev = $ENV{'QA_BZR_REV'};

	return 0;
};

sub opensuse_package_uninstall{
	my $source = $ENV{'QA_SOURCE'};

	if( $source eq "REPO" ){
		opensuse_package_euca_repo_uninstall();
	}else{
		opensuse_package_local_repo_uninstall();
	};

	return 0;
};

sub centos_package_euca_repo_uninstall{

        my $distro = $ENV{'QA_DISTRO'};
	my $arch = $ENV{'QA_ARCH'};
        my $source = $ENV{'QA_SOURCE'};
        my $roll = $ENV{'QA_ROLL'};
        my $bzr_dir = $ENV{'QA_BZR_DIR'};

	my $this_arch = "x86_64";
	if( $arch eq "32" ){
		$this_arch = "i386";
	};

	my $pkgname = "eucalyptus";

	if( $bzr_dir =~ /eee/ ){
		$pkgname = "eucalyptus-eee";
	};

	# Eucalyptus Un-Install
#	system("yum -y erase " . $pkgname . "-cc.$this_arch --nogpgcheck");
#	system("yum -y erase " . $pkgname . "-cloud.$this_arch --nogpgcheck");
#	system("yum -y erase " . $pkgname . "-sc.$this_arch --nogpgcheck");
#	system("yum -y erase " . $pkgname . "-walrus.$this_arch --nogpgcheck");
#	system("yum -y erase " . $pkgname . "-nc.$this_arch --nogpgcheck");

	system("yum -y erase eucalyptus* ");
        system("yum -y erase python*-eucadmin ");
        system("yum -y erase euca2ools");			### NEEDED ??

	return 0;
};


sub centos_package_local_repo_uninstall{

        my $distro = $ENV{'QA_DISTRO'};
        my $arch = $ENV{'QA_ARCH'};
        my $source = $ENV{'QA_SOURCE'};
        my $roll = $ENV{'QA_ROLL'};

        my $bzr_dir = $ENV{'QA_BZR_DIR'};
        my $bzr_rev = $ENV{'QA_BZR_REV'};

	return 0;
};


sub centos_package_uninstall{
	my $source = $ENV{'QA_SOURCE'};

        if( $source eq "REPO" ){
                centos_package_euca_repo_uninstall();
        }else{
                centos_package_local_repo_uninstall();
        };

        return 0;
};


sub fedora_package_euca_repo_uninstall{

	my $distro = $ENV{'QA_DISTRO'};
	my $arch = $ENV{'QA_ARCH'};
	my $source = $ENV{'QA_SOURCE'};
	my $roll = $ENV{'QA_ROLL'};
	my $bzr_dir = $ENV{'QA_BZR_DIR'};


	my $pkgname = "eucalyptus";

	if( $bzr_dir =~ /eee/ ){
		$pkgname = "eucalyptus-eee";
	};

#	system("yum -y erase " . $pkgname . "-cc --nogpgcheck");
#	system("yum -y erase " . $pkgname . "-cloud --nogpgcheck");
#	system("yum -y erase " . $pkgname . "-sc --nogpgcheck");
#	system("yum -y erase " . $pkgname . "-walrus --nogpgcheck");
#	system("yum -y erase " . $pkgname . "-nc --nogpgcheck");

	system("yum -y erase eucalyptus* ");
        system("yum -y erase python*-eucadmin ");
        system("yum -y erase euca2ools");			### NEEDED ??

	return 0;
};

sub fedora_package_local_repo_uninstall{

        my $distro = $ENV{'QA_DISTRO'};
        my $arch = $ENV{'QA_ARCH'};
        my $source = $ENV{'QA_SOURCE'};
        my $roll = $ENV{'QA_ROLL'};

        my $bzr_dir = $ENV{'QA_BZR_DIR'};
        my $bzr_rev = $ENV{'QA_BZR_REV'};

	return 0;
};


sub fedora_package_uninstall{
	my $source = $ENV{'QA_SOURCE'};

        if( $source eq "REPO" ){
		fedora_package_euca_repo_uninstall();
        }else{
		fedora_package_local_repo_uninstall();
        };

        return 0;
};


sub rhel_package_euca_repo_uninstall{

        my $distro = $ENV{'QA_DISTRO'};
	my $arch = $ENV{'QA_ARCH'};
        my $source = $ENV{'QA_SOURCE'};
        my $roll = $ENV{'QA_ROLL'};
        my $bzr_dir = $ENV{'QA_BZR_DIR'};

	my $this_arch = "x86_64";
	if( $arch eq "32" ){
		$this_arch = "i386";
	};

	my $pkgname = "eucalyptus";

	if( $bzr_dir =~ /eee/ ){
		$pkgname = "eucalyptus-eee";
	};

	# Eucalyptus Un-Install
#	system("yum -y erase " . $pkgname . "-cc.$this_arch --nogpgcheck");
#	system("yum -y erase " . $pkgname . "-cloud.$this_arch --nogpgcheck");
#	system("yum -y erase " . $pkgname . "-sc.$this_arch --nogpgcheck");
#	system("yum -y erase " . $pkgname . "-walrus.$this_arch --nogpgcheck");
#	system("yum -y erase " . $pkgname . "-nc.$this_arch --nogpgcheck");

	system("yum -y erase eucalyptus* ");
        system("yum -y erase python*-eucadmin ");
        system("yum -y erase euca2ools");			### NEEDED ??

	return 0;
};



sub uninstall_package{

	my $distro = $ENV{'QA_DISTRO'};

	$ENV{'EUCALYPTUS'} = "";

	if( $distro eq "UBUNTU"){

		ubuntu_package_uninstall();

	}elsif( $distro eq "DEBIAN" ){

		debian_package_uninstall();

	}elsif( $distro eq "OPENSUSE" ){

		opensuse_package_uninstall();

	}elsif( $distro eq "CENTOS" ){

		centos_package_uninstall();

	}elsif( $distro eq "FEDORA" ){

		fedora_package_uninstall();

	}elsif( $distro eq "RHEL" ){

		rhel_package_euca_repo_uninstall();

	}else{
		return 1;
	};

	return 0;
};



############################################# PACKAGE INSTALLATION SUBROUTINES #####################################

sub force_start_libvirt{

	print("/etc/init.d/libvirt-bin stop\n");
	system("/etc/init.d/libvirt-bin stop");
	sleep(5);

	print("/etc/init.d/libvirt-bin start\n");
	system("/etc/init.d/libvirt-bin start");
	sleep(3);

	print("ps aux | grep libvirt\n");
	system("ps aux | grep libvirt");

	return 0;
};


sub ubuntu_package_install{

	my $distro_ver = $ENV{'QA_DISTRO_VER'};
	my $roll = $ENV{'QA_ROLL'};
	my $bzr_dir = $ENV{'QA_BZR_DIR'};

	my $pkgname = "eucalyptus";

### temp fix for puma 030211 V
	if( $bzr_dir =~ /eee/ ){
#		$pkgname = "eucalyptus-eee";
	};

	if( does_It_Have($roll, "CLC") ){
		system("apt-get --force-yes -y install " . $pkgname . "-cloud");
 		if( !is_before_dual_repo() ){
			if( is_install_san_from_memo() || is_install_vmbroker_from_memo() ){
				system("apt-get --force-yes -y install eucalyptus-enterprise-libs");
#				system("apt-get --force-yes -y install libeucalyptus-enterprise-storage-san-java");
			};
		};
	};

	if( does_It_Have($roll, "CC") ){
		system("apt-get --force-yes -y install " . $pkgname . "-cc");
		if( is_install_vmbroker_from_memo() ){
			if( $ENV{'QA_GIT_REPO'} ne "" && !is_before_dual_repo() ){
                                system("apt-get --force-yes -y install eucalyptus-enterprise-vmware-broker");
                        }else{
				system("apt-get --force-yes -y install " . $pkgname . "-broker");
			};
		};
	};

	if( does_It_Have($roll, "SC") ){
		system("apt-get --force-yes -y install " . $pkgname . "-sc");
		if( is_install_san_from_memo() && !is_before_dual_repo() ){
			system("apt-get --force-yes -y install " . $pkgname . "-enterprise-storage-san");
		};
		if( $distro_ver eq "PRECISE" ){
			print("/usr/sbin/tgtd stop\n");
			system("/usr/sbin/tgtd stop");
			sleep(3);
			print("killall -9 tgtd\n");
			system("killall -9 tgtd");
			print("service tgt stop\n");
			system("service tgt stop");
			sleep(3);
			print("service tgt start\n");
			system("service tgt start");
		};

	};

	if( does_It_Have($roll, "WS") ){
		system("apt-get --force-yes -y install " . $pkgname . "-walrus");
	};

	if( does_It_Have($roll, "NC") ){
		system("apt-get --force-yes -y install " . $pkgname . "-nc");
		sleep(5);

		force_start_libvirt();
	};

	return 0;
};


sub debian_package_install{

	my $distro = $ENV{'QA_DISTRO'};
	my $source = $ENV{'QA_SOURCE'};
	my $roll = $ENV{'QA_ROLL'};
	
	my $bzr_dir = $ENV{'QA_BZR_DIR'};
	my $pkg_branch = "1.6";

	my $pkgname = "eucalyptus";

	if( $bzr_dir =~ /eee/ ){
		$pkgname = "eucalyptus-eee";
	};


	# Eucalyptus Install
	if( does_It_Have($roll, "CLC") ){
		system("apt-get --force-yes -y install " . $pkgname . "-cloud");
	};

	if( does_It_Have($roll, "CC") ){
		system("apt-get --force-yes -y install " . $pkgname . "-cc");
		if( is_install_vmbroker_from_memo() ){
			system("apt-get --force-yes -y install " . $pkgname . "-broker");
		};
	};

	if( does_It_Have($roll, "SC") ){
		system("apt-get --force-yes -y install " . $pkgname . "-sc");
		if( is_install_san_from_memo() && !is_before_dual_repo() ){
			system("apt-get --force-yes -y install " . $pkgname . "-enterprise-storage-san");
			sleep(3);
                        system("/etc/init.d/tgtd stop");
                        sleep(3);
                        system("/etc/init.d/tgtd start");
		};
	};

	if( does_It_Have($roll, "WS") ){
		system("apt-get --force-yes -y install " . $pkgname . "-walrus");
	};

	if( does_It_Have($roll, "NC") ){
		system("apt-get --force-yes -y install " . $pkgname . "-nc");
		sleep(5);
				
		system("/etc/init.d/libvirt-bin stop");
		sleep(3);
		system("/etc/init.d/libvirt-bin start");
		sleep(3);
		system("ps aux | grep libvirt");
	};

	return 0;
};


sub opensuse_package_euca_repo_install{
	
	my $distro = $ENV{'QA_DISTRO'};
	my $source = $ENV{'QA_SOURCE'};
	my $roll = $ENV{'QA_ROLL'};
	my $bzr_dir = $ENV{'QA_BZR_DIR'};

	my $pkgname = "eucalyptus";

	if( $bzr_dir =~ /eee/ ){
		$pkgname = "eucalyptus-eee";
	};


	# Eucalyptus Install
	if( does_It_Have($roll, "CLC") ){
		system("zypper -n in " . $pkgname . "-cloud");
	};

	if( does_It_Have($roll, "CC") ){
		system("zypper -n in " . $pkgname . "-cc");
		if( is_install_vmbroker_from_memo() ){
			system("zypper -n in " . $pkgname . "-broker");
		};
	};

	if( does_It_Have($roll, "SC") ){
		system("zypper -n in " . $pkgname . "-sc");
		if( is_install_san_from_memo() && !is_before_dual_repo() ){
                        system("zypper -n in " . $pkgname . "-enterprise-storage-san");
			sleep(3);
                        system("/etc/init.d/tgtd stop");
                        sleep(3);
                        system("/etc/init.d/tgtd start");
                };
	};

	if( does_It_Have($roll, "WS") ){
		system("zypper -n in " . $pkgname . "-walrus");
	};

	if( does_It_Have($roll, "NC") ){
		system("zypper -n in " . $pkgname . "-nc");
	};

	return 0;
};


sub opensuse_package_local_repo_install{

	my $distro = $ENV{'QA_DISTRO'};
	my $arch = $ENV{'QA_ARCH'};
	my $source = $ENV{'QA_SOURCE'};
	my $roll = $ENV{'QA_ROLL'};

	my $bzr_dir = $ENV{'QA_BZR_DIR'};
	my $bzr_rev = $ENV{'QA_BZR_REV'};

	return 0;
};

sub opensuse_package_install{
	my $source = $ENV{'QA_SOURCE'};

	if( $source eq "REPO" ){
		opensuse_package_euca_repo_install();
	}else{
		opensuse_package_local_repo_install();
	};

	return 0;
};

sub centos_package_euca_repo_install{

        my $distro = $ENV{'QA_DISTRO'};
	my $arch = $ENV{'QA_ARCH'};
        my $source = $ENV{'QA_SOURCE'};
        my $roll = $ENV{'QA_ROLL'};
        my $bzr_dir = $ENV{'QA_BZR_DIR'};

	my $this_arch = "x86_64";
	if( $arch eq "32" ){
		$this_arch = "i386";
	};

	my $pkgname = "eucalyptus";

	if( $bzr_dir =~ /eee/ ){
		$pkgname = "eucalyptus-eee";
	};


	# Eucalyptus Install
	if( does_It_Have($roll, "CLC") ){
		###     TEMP. SOL       051512
                if( is_before_dual_repo()  ){
                        system("yum -y install " . $pkgname . "-cloud.$this_arch --nogpgcheck");
                }else{
                        system("yum -y groupinstall eucalyptus-cloud-controller --nogpgcheck");
                };
	};

	if( does_It_Have($roll, "CC") ){
		system("yum -y install " . $pkgname . "-cc.$this_arch --nogpgcheck");
		if( is_install_vmbroker_from_memo() ){
#			system("yum -y install " . $pkgname . "-broker.$this_arch --nogpgcheck");
			system("yum -y install " . $pkgname . "-broker --nogpgcheck");
		};
	};

	if( does_It_Have($roll, "SC") ){
		system("yum -y install " . $pkgname . "-sc.$this_arch --nogpgcheck");

		if( is_install_san_from_memo() ){

			if( is_before_dual_repo() ){
				### VERSION 3.0 AND BEFORE
				# DO NOTHING
			}elsif( is_euca_version_three_one() ){
				### VERSION 3.1
				system("yum -y install " . $pkgname . "-enterprise-storage-san --nogpgcheck");
				sleep(3);
                        	system("/etc/init.d/tgtd stop");
                        	sleep(3);
                        	system("/etc/init.d/tgtd start");
			}else{
				### VERSION 3.2 AND AFTER
				my $san_storage_package = "";
				if( $ENV{'QA_MEMO_SAN_PROVIDER'} eq "EmcVnxProvider" ){
					$san_storage_package = "eucalyptus-enterprise-storage-san-emc";
				}elsif( $ENV{'QA_MEMO_SAN_PROVIDER'} eq "NetappProvider" ){
					$san_storage_package = "eucalyptus-enterprise-storage-san-netapp";
				}elsif( $ENV{'QA_MEMO_SAN_PROVIDER'} eq "EquallogicProvider" ){
					$san_storage_package = "eucalyptus-enterprise-storage-san-equallogic";
				};
				system("yum -y install " . $san_storage_package . " --nogpgcheck");
				sleep(3);
			};
		};
	};

	if( does_It_Have($roll, "WS") ){
		system("yum -y install " . $pkgname . "-walrus.$this_arch --nogpgcheck");
	};

	if( does_It_Have($roll, "NC") ){
		system("yum -y install euca2ools --nogpgcheck");

		system("yum -y install " . $pkgname . "-nc.$this_arch --nogpgcheck");
	};							

	return 0;
};


sub centos_package_local_repo_install{

        my $distro = $ENV{'QA_DISTRO'};
        my $arch = $ENV{'QA_ARCH'};
        my $source = $ENV{'QA_SOURCE'};
        my $roll = $ENV{'QA_ROLL'};

        my $bzr_dir = $ENV{'QA_BZR_DIR'};
        my $bzr_rev = $ENV{'QA_BZR_REV'};

	return 0;
};


sub centos_package_install{
	my $source = $ENV{'QA_SOURCE'};

        if( $source eq "REPO" ){
                centos_package_euca_repo_install();
        }else{
                centos_package_local_repo_install();
        };

        return 0;
};


sub fedora_package_euca_repo_install{

	my $distro = $ENV{'QA_DISTRO'};
	my $arch = $ENV{'QA_ARCH'};
	my $source = $ENV{'QA_SOURCE'};
	my $roll = $ENV{'QA_ROLL'};
	my $bzr_dir = $ENV{'QA_BZR_DIR'};


	my $pkgname = "eucalyptus";

	if( $bzr_dir =~ /eee/ ){
		$pkgname = "eucalyptus-eee";
	};


	# Eucalyptus Install
	if( does_It_Have($roll, "CLC") ){
		###     TEMP. SOL       051512
		if( is_before_dual_repo()  ){
			system("yum -y install " . $pkgname . "-cloud --nogpgcheck");
                }else{
                        system("yum -y groupinstall eucalyptus-cloud-controller --nogpgcheck");
                };
	};

	if( does_It_Have($roll, "CC") ){
		system("yum -y install " . $pkgname . "-cc --nogpgcheck");
		if( is_install_vmbroker_from_memo() ){
 			system("yum -y install " . $pkgname . "-broker --nogpgcheck");
		};
	};

	if( does_It_Have($roll, "SC") ){
		system("yum -y install " . $pkgname . "-sc --nogpgcheck");
		if( is_install_san_from_memo() && !is_before_dual_repo() ){
			system("yum -y install " . $pkgname . "-enterprise-storage-san --nogpgcheck");
			sleep(3);
                        system("/etc/init.d/tgtd stop");
                        sleep(3);
                        system("/etc/init.d/tgtd start");
		};
	};

	if( does_It_Have($roll, "WS") ){
		system("yum -y install " . $pkgname . "-walrus --nogpgcheck");
	};

	if( does_It_Have($roll, "NC") ){
		system("yum -y install " . $pkgname . "-nc --nogpgcheck");
	};

	return 0;
};

sub fedora_package_local_repo_install{

        my $distro = $ENV{'QA_DISTRO'};
        my $arch = $ENV{'QA_ARCH'};
        my $source = $ENV{'QA_SOURCE'};
        my $roll = $ENV{'QA_ROLL'};

        my $bzr_dir = $ENV{'QA_BZR_DIR'};
        my $bzr_rev = $ENV{'QA_BZR_REV'};

	return 0;
};


sub fedora_package_install{
	my $source = $ENV{'QA_SOURCE'};

        if( $source eq "REPO" ){
		fedora_package_euca_repo_install();
        }else{
		fedora_package_local_repo_install();
        };

        return 0;
};


sub rhel_package_euca_repo_install{

        my $distro = $ENV{'QA_DISTRO'};
	my $arch = $ENV{'QA_ARCH'};
        my $source = $ENV{'QA_SOURCE'};
        my $roll = $ENV{'QA_ROLL'};
        my $bzr_dir = $ENV{'QA_BZR_DIR'};

	my $this_arch = "x86_64";
	if( $arch eq "32" ){
		$this_arch = "i386";
	};

	my $pkgname = "eucalyptus";

	if( $bzr_dir =~ /eee/ ){
		$pkgname = "eucalyptus-eee";
	};


	# Eucalyptus Install
	if( does_It_Have($roll, "CLC") ){
		###     TEMP. SOL       051512
		if( is_before_dual_repo()  ){
                        system("yum -y install " . $pkgname . "-cloud.$this_arch --nogpgcheck");
                }else{
                        system("yum -y groupinstall eucalyptus-cloud-controller --nogpgcheck");
                };

	};

	if( does_It_Have($roll, "CC") ){
		system("yum -y install " . $pkgname . "-cc.$this_arch --nogpgcheck");
		if( is_install_vmbroker_from_memo() ){
#			system("yum -y install " . $pkgname . "-broker.$this_arch --nogpgcheck");
			system("yum -y install " . $pkgname . "-broker --nogpgcheck");
		};
	};

	if( does_It_Have($roll, "SC") ){
		system("yum -y install " . $pkgname . "-sc.$this_arch --nogpgcheck");
		if( is_install_san_from_memo() && !is_before_dual_repo() ){
			system("yum -y install " . $pkgname . "-enterprise-storage-san --nogpgcheck");
			sleep(3);
                        system("/etc/init.d/tgtd stop");
                        sleep(3);
                        system("/etc/init.d/tgtd start");
		};
	};

	if( does_It_Have($roll, "WS") ){
		system("yum -y install " . $pkgname . "-walrus.$this_arch --nogpgcheck");
	};

	if( does_It_Have($roll, "NC") ){
		system("yum -y install euca2ools --nogpgcheck");

		system("yum -y install " . $pkgname . "-nc.$this_arch --nogpgcheck");
	};							

	return 0;
};



sub install_from_package{

	my $distro = $ENV{'QA_DISTRO'};

	$ENV{'EUCALYPTUS'} = "";

	if( $distro eq "UBUNTU"){

		ubuntu_package_install();

	}elsif( $distro eq "DEBIAN" ){

		debian_package_install();

	}elsif( $distro eq "OPENSUSE" ){

		opensuse_package_install();

	}elsif( $distro eq "CENTOS" ){

		centos_package_install();

	}elsif( $distro eq "FEDORA" ){

		fedora_package_install();

	}elsif( $distro eq "RHEL" ){

		rhel_package_euca_repo_install();

	}else{
		return 1;
	};

	### get PEM file for eee
	get_pem();

	return 0;
};

sub get_pem{

	system("wget http://qa-server/4qa/4_eee/pem/EEE-2.0-QAkey-All-128EA36F131-license.pem");
	system("cp ./EEE-2.0-QAkey-All-128EA36F131-license.pem /etc/eucalyptus/.");
	return 0;
};


sub fix_python_link{
	system("rm -f /usr/bin/python");
	system("ln -sf /usr/bin/python2.4 /usr/bin/python");
	return 0;
};

sub return_python_link{

	post_ops_install_python25();

#        system("rm -f /usr/bin/python");
#        system("ln -sf /usr/bin/python2.5 /usr/bin/python");
        return 0;
};


sub post_ops_install_python25{

	my $distro = $ENV{'QA_DISTRO'};
	my $distro_ver = $ENV{'QA_DISTRO_VER'};
        my $source = $ENV{'QA_SOURCE'};
        my $roll = $ENV{'QA_ROLL'};
        my $arch = $ENV{'QA_ARCH'};

        chdir($ENV{'PWD'});

	if( $distro eq "RHEL" && $distro_ver =~ /^5\./ ){

		system("yum -y install swig make");

		system("wget http://qa-server/4qa/4_eee/rhel/Python-2.5.tgz");
		system("tar xvfz Python-2.5.tgz");
		chdir("./Python-2.5");
		system("./configure");
		system("make");
		system("make install");

		chdir($ENV{'PWD'});

		if( $arch eq "64" ){
			system("cp /usr/include/openssl/opensslconf-x86_64.h /usr/include/");
	       	}else{
			system("cp /usr/include/openssl/opensslconf-i386.h /usr/include/");
	       	};

		system("wget http://qa-server/4qa/4_eee/rhel/M2Crypto-0.20.2.tar.gz");
                system("tar xvfz M2Crypto-0.20.2.tar.gz");
                chdir("./M2Crypto-0.20.2");

                system("python2.5 setup.py install");
	
	}elsif( $distro eq "CENTOS" ){
		system("yum -y install swig make");

		my $where_dir = "4_euca2ools/python25";
		my $to_dir = "rpms_4_euca2ools";

		system("mkdir -p ./$to_dir");

		my $rpm_common_01 = "help2man-1.33.1-2.noarch.rpm";
		install_rpm($rpm_common_01, $where_dir, $to_dir);

		if( $arch eq "64" ){
			my $rpm_01 = "python25-2.5.1-bashton1.x86_64.rpm";
			my $rpm_02 = "python25-libs-2.5.1-bashton1.x86_64.rpm";
			my $rpm_03 = "python25-devel-2.5.1-bashton1.x86_64.rpm";

			system("wget -q -O ./$to_dir/$rpm_01 http://qa-server/4qa/$where_dir/$rpm_01");
			system("wget -q -O ./$to_dir/$rpm_02 http://qa-server/4qa/$where_dir/$rpm_02");
			system("rpm -i ./$to_dir/$rpm_01 ./$to_dir/$rpm_02"); 

                        install_rpm($rpm_03, $where_dir, $to_dir);

			system("cp /usr/include/openssl/opensslconf-x86_64.h /usr/include/");
	       	}else{
			my $rpm_01 = "python25-2.5.1-bashton1.i386.rpm";
                        my $rpm_02 = "python25-libs-2.5.1-bashton1.i386.rpm";
                        my $rpm_03 = "python25-devel-2.5.1-bashton1.i386.rpm";

			system("wget -q -O ./$to_dir/$rpm_01 http://qa-server/4qa/$where_dir/$rpm_01");
                        system("wget -q -O ./$to_dir/$rpm_02 http://qa-server/4qa/$where_dir/$rpm_02");
                        system("rpm -i ./$to_dir/$rpm_01 ./$to_dir/$rpm_02");

                        install_rpm($rpm_03, $where_dir, $to_dir);

			system("cp /usr/include/openssl/opensslconf-i386.h /usr/include/");
	       	};

		system("rm -f /usr/bin/python");
		system("ln -sf /usr/bin/python2.5 /usr/bin/python");
	};

	chdir($ENV{'PWD'});

	return 0;
};


sub install_rpm{
	my ($rpm, $where, $to) = @_;

	if( !( -e "./$to" ) ){ 
        	system("mkdir -p ./$to");
	};

        system("wget -q -O ./$to/$rpm http://qa-server/4qa/$where/$rpm");
        system("rpm -i ./$to/$rpm");

	return 0;
};



sub post_ops_mount_disk{

	my $source = $ENV{'QA_SOURCE'};
	my $roll = $ENV{'QA_ROLL'};

	$ENV{'EUCA_MOUNT_POINT'} = "/disk1/storage";

	$ENV{'EUCA_INSTANCES'} = "/disk1/storage/eucalyptus/instances";

		
	if( -e "$ENV{'EUCALYPTUS'}/var/lib/eucalyptus/vmware" ){
		print("rm -fr $ENV{'EUCALYPTUS'}/var/lib/eucalyptus/vmware\n");
		system("rm -fr $ENV{'EUCALYPTUS'}/var/lib/eucalyptus/vmware");
	};

	print("mkdir -p $ENV{'EUCA_INSTANCES'}/vmware\n");
	system("mkdir -p $ENV{'EUCA_INSTANCES'}/vmware");

	print("ln -sf $ENV{'EUCA_INSTANCES'}/vmware $ENV{'EUCALYPTUS'}/var/lib/eucalyptus/\n");
	system("ln -sf $ENV{'EUCA_INSTANCES'}/vmware $ENV{'EUCALYPTUS'}/var/lib/eucalyptus/");

	if( does_It_Have($roll, "WS") ){
		if( -e "$ENV{'EUCALYPTUS'}/var/lib/eucalyptus/bukkits" ){
			print("rm -fr $ENV{'EUCALYPTUS'}/var/lib/eucalyptus/bukkits\n");
			system("rm -fr $ENV{'EUCALYPTUS'}/var/lib/eucalyptus/bukkits");
		};
		print("mkdir -p $ENV{'EUCA_INSTANCES'}/bukkits\n");
		system("mkdir -p $ENV{'EUCA_INSTANCES'}/bukkits");

		print("ln -sf $ENV{'EUCA_INSTANCES'}/bukkits $ENV{'EUCALYPTUS'}/var/lib/eucalyptus/\n");
		system("ln -sf $ENV{'EUCA_INSTANCES'}/bukkits $ENV{'EUCALYPTUS'}/var/lib/eucalyptus/");
	};

	if( does_It_Have($roll, "SC") ){
		if( -e "$ENV{'EUCALYPTUS'}/var/lib/eucalyptus/volumes" ){
			print("rm -fr $ENV{'EUCALYPTUS'}/var/lib/eucalyptus/volumes\n");
			system("rm -fr $ENV{'EUCALYPTUS'}/var/lib/eucalyptus/volumes");
		};
		print("mkdir -p $ENV{'EUCA_INSTANCES'}/volumes\n");
		system("mkdir -p $ENV{'EUCA_INSTANCES'}/volumes");

		print("ln -sf $ENV{'EUCA_INSTANCES'}/volumes $ENV{'EUCALYPTUS'}/var/lib/eucalyptus/\n");
		system("ln -sf $ENV{'EUCA_INSTANCES'}/volumes $ENV{'EUCALYPTUS'}/var/lib/eucalyptus/");
	};

	print("chown -R eucalyptus:eucalyptus $ENV{'EUCA_INSTANCES'}\n");
	system("chown -R eucalyptus:eucalyptus $ENV{'EUCA_INSTANCES'}");
	
	return 0;
};


sub post_ops_create_link_for_qa_machine{

	if( $ENV{'QA_SOURCE'} eq "BZR" ){
		$ENV{'EUCALYPTUS'} = "/opt/eucalyptus";
	};

	$ENV{'EUCA_DISK'} = "/disk1/storage/eucalyptus";

	print("rm -fr $ENV{'EUCA_DISK'}/var/lib\n");
	system("rm -fr $ENV{'EUCA_DISK'}/var/lib");

	print("mkdir -p $ENV{'EUCA_DISK'}/var/lib\n");
	system("mkdir -p $ENV{'EUCA_DISK'}/var/lib");


	print("rm -fr $ENV{'EUCA_DISK'}/var/log\n");
	system("rm -fr $ENV{'EUCA_DISK'}/var/log");

	print("mkdir -p $ENV{'EUCA_DISK'}/var/log\n");
	system("mkdir -p $ENV{'EUCA_DISK'}/var/log");


	print("mv -f $ENV{'EUCALYPTUS'}/var/lib/eucalyptus $ENV{'EUCA_DISK'}/var/lib/.\n");
	system("mv -f $ENV{'EUCALYPTUS'}/var/lib/eucalyptus $ENV{'EUCA_DISK'}/var/lib/.");

	print("mv -f $ENV{'EUCALYPTUS'}/var/log/eucalyptus $ENV{'EUCA_DISK'}/var/log/.\n");
	system("mv -f $ENV{'EUCALYPTUS'}/var/log/eucalyptus $ENV{'EUCA_DISK'}/var/log/.");


	print("ln -sf $ENV{'EUCA_DISK'}/var/lib/eucalyptus/ $ENV{'EUCALYPTUS'}/var/lib/\n");
	system("ln -sf $ENV{'EUCA_DISK'}/var/lib/eucalyptus/ $ENV{'EUCALYPTUS'}/var/lib/");

	print("ln -sf $ENV{'EUCA_DISK'}/var/log/eucalyptus/ $ENV{'EUCALYPTUS'}/var/log/\n");
	system("ln -sf $ENV{'EUCA_DISK'}/var/log/eucalyptus/ $ENV{'EUCALYPTUS'}/var/log/");


	return 0;
};

### Dan's patch to clean up network states	062711
sub restore_network_state {
    my $input = shift @_ || "./2b_tested.lst";
    my $subnet = "";
    my $pubipstr = "";
    my $ret = 0;

    open(FH, "$input");
    while(<FH>) {
	chomp;
	my $line = $_;
	if ($line =~ /^\s*SUBNET_IP\s*(.*)/) {
	    $subnet = $1;
	} elsif ($line =~ /^\s*MANAGED_IPS\s*(.*)/) {
	    $pubipstr = $1;
	}

    }
    close(FH);

    my $devstr;
    my $cmd;

    chomp($devstr = `ls /sys/class/net/`);
    $devstr =~ s/\s+/ /g;
    my @devlist = split(/\s+/, $devstr);

    $pubipstr =~ s/\s+/ /g;
    my @pubips = split(/\s+/, $pubipstr);
    
    for (my $k=0; $k<@devlist; $k++) {
	my $dev = $devlist[$k];

	if ($subnet ne "" && $dev ne "") {
	    print "CLEARING IP_SUBNET ARTIFACTS\n";
	    print "IP_SUBNET=$subnet\n";
	    $cmd = "ip addr flush dev $dev to $subnet/20";
	    print "RUNNING CMD: $cmd\n";
	    if (system($cmd)) {print "FAILED\n";$ret++;}
	    print "FINISHED RUNNING CMD: $cmd\n";
	}
	if ($pubipstr ne "" && $dev ne "") {
	    print "CLEARING MANAGED_IPS ARTIFACTS\n";
	    print "MANAGED_IPS=$pubipstr\n";
	    for (my $j=0; $j<@pubips; $j++) {
		my $ip = $pubips[$j];
		$cmd = "ip addr del $ip/32 dev $dev >/dev/null 2>&1";
		print "RUNNING CMD: $cmd\n";
		if (system($cmd)>>8 == 1) {print "FAILED\n";$ret++;}
		print "FINISHED RUNNING CMD: $cmd\n";
	    }
	}

	print "CLEARING BRIDGES\n";
	if ($dev =~ /eucabr/) {
	    $cmd = "ifconfig $dev down";
	    print "RUNNING CMD: $cmd\n";
	    if (system($cmd)) {print "FAILED\n";$ret++;}
	    print "FINISHED RUNNING CMD: $cmd\n";
	    
	    $cmd = "brctl delbr $dev";
	    print "RUNNING CMD: $cmd\n";
	    if (system($cmd)) {print "FAILED\n";$ret++;}
	    print "FINISHED RUNNING CMD: $cmd\n";
	}

	print "CLEARING VLAN TAGGED IPS\n";
	if ($dev =~ /\.\d+/) {
	    $cmd = "vconfig rem $dev";
	    print "RUNNING CMD: $cmd\n";
	    if (system($cmd)) {print "FAILED\n";$ret++;}
	    print "FINISHED RUNNING CMD: $cmd\n";
	}
	
    }

    print "CLEARING IPTABLES RULES";
    $cmd = "iptables -F >/dev/null 2>&1";
    print "RUNNING CMD: $cmd\n";
    if (system($cmd)) {print "FAILED\n";$ret++;}
    print "FINISHED RUNNING CMD: $cmd\n";
    
    $cmd = "iptables -t nat -F >/dev/null 2>&1";
    print "RUNNING CMD: $cmd\n";
    if (system($cmd)) {print "FAILED\n";$ret++;}
    print "FINISHED RUNNING CMD: $cmd\n";

    $cmd = "iptables -P FORWARD ACCEPT >/dev/null 2>&1";
    print "RUNNING CMD: $cmd\n";
    if (system($cmd)) {print "FAILED\n";$ret++;}
    print "FINISHED RUNNING CMD: $cmd\n";

    my $iptchainstr;

    chomp($iptchainstr = `iptables -L -n | grep Chain | grep -v INPUT | grep -v OUTPUT | grep -v FORWARD | awk '{print \$2}'`);
    print "IPT: $iptchainstr\n";
    my @iptchains = split(/\s+/, $iptchainstr);
    for (my $i=0; $i<@iptchains; $i++) {
	my $chain = $iptchains[$i];
	$cmd = "iptables -F $chain";
	print "RUNNING CMD: $cmd\n";
	if (system($cmd)) {print "FAILED\n";$ret++;}
	print "FINISHED RUNNING CMD: $cmd\n";
	$cmd = "iptables -X $chain";
	print "RUNNING CMD: $cmd\n";
	if (system($cmd)) {print "FAILED\n";$ret++;}
	print "FINISHED RUNNING CMD: $cmd\n";
    }

    return(0);
};



sub report_disk_status{

	sleep(1);
	print "\n";
	print "DISK CHECK\n";

        print("df -h\n");
        system("df -h");

	print "\n";
	print "\n";

        print("du -sh /disk1/storage\n");
        system("du -sh /disk1/storage");

	print "\n";
	print "\n";

	return 0;
};

sub report_tgt_status{

        sleep(1);
        print "\n";
        print "TGT CHECK\n";

        print("tgtadm --lld iscsi --mode target --op show\n");
        system("tgtadm --lld iscsi --mode target --op show");

        print "\n";
        print "\n";

        return 0;
};


sub restart_iscsid{

        print "\n";
        print "RESTART ISCSID\n";

	if( $ENV{'QA_DISTRO'} eq "UBUNTU" || $ENV{'QA_DISTRO'} eq "DEBIAN" ){
	        print("/etc/init.d/open-iscsi stop\n");
	        system("/etc/init.d/open-iscsi stop\n");
		sleep(1);

	        print("/etc/init.d/open-iscsi start\n");
	        system("/etc/init.d/open-iscsi start\n");
	}else{
	        print("/etc/init.d/iscsid stop\n");
	        system("/etc/init.d/iscsid stop\n");
		sleep(1);

	        print("/etc/init.d/iscsid start\n");
	        system("/etc/init.d/iscsid start\n");
	};

        print "\n";

        return 0;
};


sub remove_tgt{

        print "\n";
        print "REMOVE TGT\n";

	if( $ENV{'QA_DISTRO'} eq "UBUNTU" || $ENV{'QA_DISTRO'} eq "DEBIAN" ){
		print("apt-get --force-yes -y purge tgt\n");
		system("apt-get --force-yes -y purge tgt");
	}else{
		print("yum -y erase scsi-target-utils\n");
		system("yum -y erase scsi-target-utils");
	};

	print "\n";

	return 0;
};


sub kill_nine_tgt{

	my $ps = `ps aux | grep tgt`;
	my @ps_array = split("\n", $ps);

	print "\n";
	print "========================================================\n";
	print "KILL NINE TGT\n";
	print "========================================================\n";
	print "\n";

	foreach my $proc (@ps_array){
		print "PS LINE:\n" .$proc . "\n";
		if( $proc =~ /^\S+\s+(\d+)\s/ ){
			my $procid = $1;
			print "FOUND PID: " .$procid . "\n";
			my $cmd = "kill -9 $procid\n";
			system($cmd);
			print "\n";
		};	
	};

	print "========================================================\n";
	print "END OF KILL NINE TGT\n";
	print "========================================================\n";
	print "\n";

	return 0;
};




sub is_killall_dhcpd_when_restore_from_memo{
	if( $ENV{'QA_MEMO'} =~ /KILLALL_DHCPD_WHEN_RESTORE=YES/ ){
		print "FOUND in MEMO\n";
		print "KILLALL_DHCPD_WHEN_RESTORE=YES\n";
		$ENV{'QA_MEMO_KILLALL_DHCPD_WHEN_RESTORE'} = "YES";
		return 1;
	};
	return 0;
};

sub is_euca_version_from_memo{
        if( $ENV{'QA_MEMO'} =~ /^EUCA_VERSION=(.+)\n/m ){
                my $extra = $1;
                $extra =~ s/\r//g;
                print "FOUND in MEMO\n";
                print "EUCA_VERSION=$extra\n";
                $ENV{'QA_MEMO_EUCA_VERSION'} = $extra;
                return 1;
        };
        return 0;
};

sub is_before_dual_repo{
	if( is_euca_version_from_memo() ){
		if( $ENV{'QA_MEMO_EUCA_VERSION'} =~ /^2/ || $ENV{'QA_MEMO_EUCA_VERSION'} =~ /^3\.0/ ){
			return 1;
		};
	};
	return 0;
};  

sub is_euca_version_three_one{
	if( is_euca_version_from_memo() ){
		if( $ENV{'QA_MEMO_EUCA_VERSION'} =~ /^3\.1/ ){
			return 1;
		};
	};
	return 0;
};

1;
