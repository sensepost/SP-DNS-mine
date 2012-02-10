#!/usr/bin/perl
#
# Google DNS name / sub domain miner
# SensePost Research 2003
# roelof@sensepost.com
#
# Assumes the GoogleSearch.wsdl file is in same directory
#

use SOAP::Lite;
if ($#ARGV<0){die "perl dns-mine.pl domainname\ne.g. perl dns-mine.pl cnn.com\n";}
my $company = $ARGV[0];
                                                                                                                  
####### You want to edit these four lines: ##############
$key   = "----YOUR GOOGLE API KEY HERE----";
@randomwords=("site","web","document",$company);
my $service = SOAP::Lite->service('file:./GoogleSearch.wsdl');
my $numloops=2;            #number of pages - max 100
#########################################################

## Loop through all the words to overcome Google's 1000 hit limit
foreach $randomword (@randomwords){
	print "\nAdding word [$randomword]\n";
	
	#method 1
	my $query = "$randomword $company -www.$company";
	push @allsites,DoGoogle($key,$query,$company);

	#method 2
        my $query = "-www.$company $randomword site:$company";
	push @allsites,DoGoogle($key,$query,$company);

}                                                                                                        
             
## Remove duplicates                                                                                                     
@allsites=dedupe(@allsites);
print STDOUT "\n---------------\nDNS names:\n---------------\n";
foreach $site (@allsites){
        print STDOUT "$site\n";
}

## Check for subdomains
foreach $site (@allsites){
	my $splitter=".".$company;
	my ($frontpart,$backpart)=split(/$splitter/,$site);
	if ($frontpart =~ /\./){
		@subs=split(/\./,$frontpart);
		my $temp="";
		for (my $i=1; $i<=$#subs; $i++){
			$temp=$temp.(@subs[$i].".");
		}
		push @allsubs,$temp.$company;
	}
}
print STDOUT "\n---------------\nSub domains:\n---------------\n";
@allsubs=dedupe(@allsubs);
foreach $sub (@allsubs){
	print STDOUT "$sub\n";
}
			
	

############------subs-------##########
sub dedupe{
        my (@keywords) = @_;
        my %hash = ();
        foreach (@keywords) {
                $_ =~ tr/[A-Z]/[a-z]/;
                chomp;
                if (length($_)>1){$hash{$_} = $_;}
        }
        return keys %hash;
}

sub parseURL{
	my ($site,$company)=@_;
	if (length($site)>0){
		if ($site =~ /:\/\/([\.\w]+)[\:\/]/){
			my $mined=$1;
			if ($mined =~/$company/){
				return $mined;
			}
		}
	}
	return "";
}

sub DoGoogle{
	my ($GoogleKey,$GoogleQuery,$company)=@_;
	my @GoogleDomains="";
        for ($j=0; $j<$numloops; $j++){
                print STDERR "$j ";
                my $results = $service
                    -> doGoogleSearch($GoogleKey,$GoogleQuery,(10*$j),10,"true","","true","","latin1","latin1");
                                                                                                                  
                my $re=(@{$results->{resultElements}});
                foreach my $results(@{$results->{resultElements}}){
                        my $site=$results->{URL};
			my $dnsname=parseURL($site,$company);
			if (length($dnsname)>0){
	                        push @GoogleDomains,$dnsname;
			}
                }
                if ($re !=10){last;}
        }
	return @GoogleDomains;
}