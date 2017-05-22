#!/usr/bin/perl
#use strict; 
#use warnings;
use BerkeleyDB;
#import( qw( DB_RDOnly ) );
#use BerkeleyDB  qw( DB_RDOnly ) ;


use Data::Dumper qw(Dumper);
#print Dumper \@ARGV;

my $base = ".";
my $dbDir = "$base/lists";
my $urls = "urls";
my $domains = "domains";
my $expressions = "expressions"; 

## Captura de parametros @ARGV
my $action = $ARGV[0];
my $group = $ARGV[1];
my $type = $ARGV[2];
my $value = $ARGV[3];

doMain();

sub ajtest
{
###
%s = (
        'as2-queen' => 1 ,
        'as1-queen' => 2,
    );
#
my $regex = qr/queen/;
print "$_ => $s{$_}\n" for grep $regex, keys %s;
#
my ($first_matching_key) = grep { $_ =~ /queen/ } keys %s;
print "First matching key is $first_matching key\n";
print "Corresponding value is $s{$first_matching_key}\n";

###
}

sub doMain
{
	my $ret=0;

	# Valida parametro de tipo se existir
	if ($type eq "er") { $type=$expressions; }
	elsif ($type eq "url") { $type=$urls; }
	elsif ($type eq "domain") { $type=$domains; }
	elsif ($type) { $action="help" }

	# se tiver valor faz checagem com o tipo
	if ($value)
	{
		checkValue();
	}

	# Executa a ação solicitada	
	if ($action eq "add" and $#ARGV eq 3)
	{ 
		add();
	}
	elsif ($action eq "del" and $#ARGV eq 3)
	{
		del();
	}
	elsif ($action eq "list")
	{
		list();
	}
	elsif ($action eq "make")
	{
		make();
	}
	elsif ($action eq "purge" and $#ARGV ge 1)
	{
		print "TODO - Apagando todos dados\n";
	}
	elsif ($action eq "ajtest")
	{
		ajtest();
	}
	else
	{
		$ret=1;
		help();
	}

	return $ret;
}

sub make
{
	my @groups;

	if ($group)
	{
		if ( ! -r "$dbDir/$group" )
		{
			print "Grupo não pode ser lido\n";
			return 1;
		}
		@groups = ($group);
	}
	else
	{
		opendir my($dh), $dbDir or die "Couldn't open dir '$dbDir': $!";
		@groups = grep { !/^\./ } readdir $dh;
		closedir $dh;
	}

	if ($type)
	{
		foreach my $dir (@groups)
		{
			print "-> $dir/$type\n";
			makeData("$dbDir/$dir/$type");
		}
	}
	else
	{
		foreach my $dir (@groups)
		{
			if ( -r "$dbDir/$dir/$domains" )
			{
				print "-> $dir/$domains\n";
				makeData("$dbDir/$dir/$domains");
			}
			if ( -r "$dbDir/$dir/$urls" )
			{
				print "-> $dir/$urls\n";
				makeData("$dbDir/$dir/$urls");
			}
			if ( -r "$dbDir/$dir/$expressions" )
			{
				print "-> $dir/$expressions\n";
				makeData("$dbDir/$dir/$expressions");
			}
		}
	
	}

	my $file="$dbDir/$group/$type";
}

sub makeData
{
	my $file = (@_)[0];

	if ( ! -r $file) { print "Arquivo $file nao pode ser lido\n";  } ;

	# Cria ou abre banco de dados
	my $db = new BerkeleyDB::Btree
		-Filename => "$file.db",
		-Flags => DB_CREATE | DB_TRUNCATE
		 or die "Cannot open file $file: $! $BerkeleyDB::Error\n" ; 

	open(my $fh, "<", $file)
		|| die "Can't open $file: $!";

	if ( $type eq $domains )
	{
		while (my $row = <$fh>)
		{
			$row =~ s/[^[:print:]]+//g;
			if ( $row !=~ /^[[:space:]]*$/ and $row ne undef )
			{
				$x = $db->db_put($row,undef);
				print "\t->$row\n";
			}
			chomp $row;
		}
	}
	else
	{
		while (my $row = <$fh>)
		{
			$row =~ s/[^[:print:]]+//g;
			if ( $row !=~ /^[[:space:]]*$/ and $row ne undef )
			{
				$x = $db->db_put($row,undef);
				print "\t->$row\n";
			}
			chomp $row;
		}
	}

	close $fh;
	$db->db_sync();
	$db->db_close();

}

sub list
{
	my @groups;

	if ($group)
	{
		if ( ! -r "$dbDir/$group" )
		{
			print "Grupo não pode ser lido\n";
			return 1;
		}
		@groups = ($group);
	}
	else
	{
		opendir my($dh), $dbDir or die "Couldn't open dir '$dbDir': $!";
		@groups = grep { !/^\./ } readdir $dh;
		closedir $dh;
	}

	if ($type)
	{
		foreach my $dir (@groups)
		{
			print "-> $dir/$type\n";
			listData("$dbDir/$dir/$type");
		}
	}
	else
	{
		foreach my $dir (@groups)
		{
			if ( -r "$dbDir/$dir/$domains.db" )
			{
				print "-> $dir/$domains\n";
				listData("$dbDir/$dir/$domains");
			}
			if ( -r "$dbDir/$dir/$urls.db" )
			{
				print "-> $dir/$urls\n";
				listData("$dbDir/$dir/$urls");
			}
			if ( -r "$dbDir/$dir/$expressions.db" )
			{
				print "-> $dir/$expressions\n";
				listData("$dbDir/$dir/$expressions");
			}
		}
	
	}

	my $file="$dbDir/$group/$type";
}

sub listData
{
	my $file = (@_)[0];

	# Abre banco de dados
	tie my %db, "BerkeleyDB::Btree", 
		-Filename => "$file.db",
		-Flags => DB_RDOnly
		 or die "Cannot open file $file: $! $BerkeleyDB::Error\n" ; 
	my $k;
	my $v;
	while ( ($k,$v) = each %db)
	{
		print "\t-> $k -> ".toCode($k)." \n";
	}

	untie %db;

}

sub del
{
	print "Deletando $value ... ";
	my $file="$dbDir/$group/$type";
	if ( -w "$file.db" )
	{
		# Abre banco de dados
		my $db = new BerkeleyDB::Btree
			-Filename => "$file.db"
			 or die "Cannot open file $file: $! $BerkeleyDB::Error\n" ; 
	
		$x = $db->db_del(".$value",undef);
	
		$db->db_sync();
		$db->db_close();


		print "OK\n";
		return 0;
	}
	else
	{
		print "FAIL: Sem acesso ao arquivo\n";
		return 1;
	}
}

sub add {
	# Cria diretorios caso não haja 
	mkdir $dbDir;
	mkdir "$dbDir/$group";

	my $file="$dbDir/$group/$type";

	# Cria ou abre banco de dados
	my $db = new BerkeleyDB::Btree
		-Filename => "$file.db",
		-Flags => DB_CREATE
		 or die "Cannot open file $file: $! $BerkeleyDB::Error\n" ; 

	if ( $type eq $domains )
	{
		$x = $db->db_put($value,undef);
	}
	else
	{
		$x = $db->db_put($value,undef);
	}

	$db->db_sync();
	$db->db_close();

	print "Adicionado: $value -> $file\n";

}

sub checkValue
{
	print "Fazendo checagem de valor .... \n";
}

sub toCode
{
return;
#	print "m.tumblr.com::$_[0]\n";
	my @chars = split //,$_[0];
	my $v='';
	for my $ch (@chars)
	{
		$v .= sprintf ( "$ch:%u ",ord($ch));
	}
	return $v;
}

sub help
{
	print "Usage:\n";

	print "\tacl.pl <list|purge|make> [groupName [type]]\n";
	print "\tacl.pl <purge> <groupName> [type]\n";
	print "\tacl.pl <add|del> <groupName> <type> <value>\n\n";

	print "Actions: list, add, del, purge\n";
	print "Types: url, domain, er\n";

	print "Examples:\n";
	print "\tacl.pl add porn url sexy.com\n";
	print "\tacl.pl del porn url sexy.com\n";
	print "\tacl.pl purge porn\n";
	print "\tacl.pl purge porn domain\n";
	print "\tacl.pl list\n";
	print "\tacl.pl list porn er\n\n";
}


