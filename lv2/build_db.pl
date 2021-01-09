#!/usr/bin/perl -w
use strict;
use warnings;

# The file name o fthe resulting JSON file
my $db_filename = "lv2.json";

open(my $out, ">$db_filename") or die "$!: $db_filename";
print $out "[\n";

## Load all LV2 plugins installed
my @lv2_urls = map {chomp; $_} `lv2ls`;

foreach my $url (@lv2_urls){
    rand() > 0.9 or next;
    my @info = `lv2info $url`;
    my $name;
    my $class;
    my $state = "start";
    my %port_data = ();
    my $port;
    foreach my $l (@info){

	chomp $l;
	$l =~ /\S/ or next;
	
	if($l =~ /^http:/){
	    $l eq $url or die "$l ne $url";
	    next;
	}
	if($state eq "start" and $l =~ /^\s+Name:\s+(.+)\s*$/){
	    $name = $1;
	    next;
	}elsif($state eq "start" and $l =~ /^\s+Class:\s+(.+)\s*$/){
	    $class = $1;
	    next;
	}elsif($l =~ /^\s+Port\s+(\d+):\s*$/){
	    $port = $1;
	    $state = "port";
	    defined($port_data{$port}) or $port_data{$port} = {}; 
	    next;
	}elsif($state eq "port" and $l =~ /^\s+Type:\s+http:.+\#(.+)\s*$/){
	    $port_data{$port}->{Type} = $1;
	    next;
	}elsif($state eq "port" and $l =~ /^\s+Symbol:\s+(\S+)\s*$/){
	    $port_data{$port}->{Symbol} = $1;
	    next;
	}elsif($state eq "port" and $l =~ /^\s+Name:\s+(.+)\s*$/){
	    $port_data{$port}->{Name} = $1;
	    next;
	}
    }

    if(!defined($name)){
	# Deduce name from URL
	warn "No name for $url\n";
	$url =~ /([a-z_\%0-9]+)/ or die $url;
	$name = $1;
    }
    unless(defined($name) and
	   defined($class)){
	die $url;
    }
    foreach my $n (keys %port_data){
	defined $port_data{$n}->{Name} or
	    die "$port $url Name";
	defined $port_data{$n}->{Type} or
	    die "$port $url Type";
	defined $port_data{$n}->{Symbol} or
	    die "$port $url Symbol";
    }
    # Write a record
    print $out  "{\n".'  "url":"'.$url.'",'."\n".'  "class":"'.$class.'",'."\n".'  "name":"'.$name.'",'."\n";
    print $out '  "Ports":['."\n"; 
    my $ports = "";
    foreach my $port (keys %port_data){
	$ports .= "    {\n";
	$ports .= '      "Port":'.$port.",\n";
	$ports .= '      "Name":"'.$port_data{$port}->{Name}.'"'.",\n";
	$ports .= '      "Type":"'.$port_data{$port}->{Type}.'"'.",\n";
	$ports .= '      "Symbol":"'.$port_data{$port}->{Symbol}.'"'."\n";
	$ports .= "    },\n";
    }

    # Remove the last comma from $ports
    $ports =~ s/,\s+$/\n/s;

    print $out $ports;
    print $out "  ]\n";
    print $out '},'."\n";
}
print $out "]\n";

	   
