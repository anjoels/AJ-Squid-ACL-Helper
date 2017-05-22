#!/usr/bin/perl 
use Time::HiRes qw(sleep gettimeofday tv_interval);
use threads;
use BerkeleyDB;


# TODO multiplas requisicoes em unico listen, 

my $base = "/home/ajsouza/teste-squid";
my $dbDir = "$base/lists";
my $urls = "urls";
my $domains = "domains";
my $expressions = "expressions"; 

my $log='';

my @erros;

## OBS.:  -- arquivos de banco necessitam permisão de escrita

$|=1;


while (<>)
{
	# my $thr = threads->create('check',$_)->join();
	# checkThreads($_); 
	check($_);
}

sub checkDomain
{
	my $file = "$dbDir/$group/$domains";
	my %db;

	if ( ! -r "$file.db" ) { return 3; }

	# Abre banco de dados ou reporta erro
	if ( ! tie %db, "BerkeleyDB::Btree", -Filename => "$file.db", -Flags => DB_RDOnly, -Cachesize => 500000 )
	{ 
		push @errors, "'$group/$domains:DataBaseError-CheckFileAndPermissions'" ;
		return 2;
	}

	foreach my $k (keys %db)
#	while ( (my $k, my $v) = each %db)
	{
# print "K:$k - $domain\n";
		# pre-selecao - aumenta consideravelmente a performance
		if ( index($domain,$k) ge 0 )
		{
# print "index:$k - $domain\n";
			my $er = quotemeta($k);
			if ( $domain =~ /^(.*\.)?$er$/ )
			{
				$log = "mstr=$k";
				untie %db;
				return 0; # retorna assim que encontrar, performance
			}
		}

	}

	untie %db;

	return 1;
}

sub checkUrl
{
	my $file = "$dbDir/$group/$urls";
	my %db;

	if ( ! -r "$file.db" ) { return 3; }
	if ( ! tie %db, "BerkeleyDB::Btree", -Filename => "$file.db", -Flags => DB_RDOnly )
	{ 
		push @errors, "'$group/$urls:DataBaseError-CheckFileAndPermissions'" ;
		return 2;
	}

	foreach my $k (keys %db)
	#while ( (my $k, my $v) = each %db)
	{
		if ( index($uri,$k) ge 0)
		{
			untie %db;
			return 0; # retorna assim que encontrar, performance
		}
	}
	untie %db;

	return 1;
}

sub checkEr
{
	my $file = "$dbDir/$group/$expressions";
	my %db;

	if ( ! -r "$file.db" ) { return 3; }

	if ( ! tie %db, "BerkeleyDB::Btree", -Filename => "$file.db", -Flags => DB_RDOnly )
	{ 
		push @errors, "'$group/$expressions:databaseerror-checkfileandpermissions'" ;
		return 2;
	}

	foreach my $k (keys %db)
	#while ( (my $k, my $v) = each %db)
	{
		if ( $uri =~ /$k/)
		{
			untie %db;
			return 0; # retorna assim que encontrar, performance
		}
	}

	untie %db;

	return 1;
}

sub check
{
	my $start = [gettimeofday()];

	($group, $domain, $uri)  = split(/[[:space:]]+/,$_);

	if ( checkDomain ($group,$domain) eq 0 )
	{
		printf ("OK log=match:$group/domain(%.3f)-$log-\n",tv_interval($start));
		return 0;
	}
	elsif (checkUrl ($group,$uri) eq 0 )
	{
		printf ("OK log=match:$group/url(%.3f)\n",tv_interval($start));
		return 0;
	}
	elsif ( checkEr ($group,$uri) eq 0 )
	{
		printf ("OK log=match:$group/expression(%.3f)\n",tv_interval($start));
		return 0;
	}

	# se houve erro reporta
	if (@errors)
	{
		printf ("ERR log=$errors[0](%.3f)\n",tv_interval($start));
		#print "ERR log=$errors[0]\n";
	}
	else
	{
		printf ("ERR log=(%.3f)\n",tv_interval($start));
		#print "ERR\n";
	}

	return 1;
}


sub checkThreads
{
	my $start = [gettimeofday()];

	($group, $domain, $uri)  = split(/[[:space:]]+/,$_);

	my $thrD = threads->create('checkDomain',$group,$domain);
	my $thrU = threads->create('checkUrl',$group,$uri);
	my $thrE = threads->create('checkEr',$group,$uri);
	
	my $keep=3;
	while ($keep)
	{
		if ($thrD && ! $thrD->is_running())
		{
			if ($thrD->join() eq 0)
			{
				printf ("OK log=match:$group/domain(%.3f)\n",tv_interval($start));
				$keep=0;
				return 0;
			}
			else
			{
				$keep--;
			}
			$thrD = undef;
		}
		if ($thrU && ! $thrU->is_running())
		{
			if ($thrU->join() eq 0)
			{
				printf ("OK log=match:$group/url(%.3f)\n",tv_interval($start));
				$keep=2;
				return 0;
			}
			else
			{
				$keep--;
			}
			$thrU = undef;
		}
		if ($thrE && ! $thrE->is_running())
		{
			if ($thrE->join() eq 0)
			{
				printf ("OK log=match:$group/expression(%.3f)\n",tv_interval($start));
				$keep=0;
				return 0;
			}
			else
			{
				$keep--;
			}
			$thrE = undef;
		}

	}
	if ($thrD) { $thrD->kill(); }
	if ($thrU) { $thrU->kill(); }
	if ($thrE) { $thrE->kill(); }
#	trheads->exit();


	# se houve erro reporta
	if (@errors)
	{
		printf ("ERR log=$errors[0](%.3f)\n",tv_interval($start));
		#print "ERR log=$errors[0]\n";
	}
	else
	{
		printf ("ERR log=(%.3f)\n",tv_interval($start));
		#print "ERR\n";
	}

	return 1;
}

