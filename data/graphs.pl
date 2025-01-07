#!/usr/bin/perl

# Get directory
my $dir;
BEGIN {
	$dir = $0;
	$dir =~ s/[^\/]*$//g;
	if(!$dir){ $dir = "./"; }
	$lib = $dir."lib/";
}
use lib $lib;
use utf8;
use warnings;
use strict;
use Data::Dumper;
use POSIX qw(strftime);
use JSON::XS;
use ODILeeds::NPG;

# Define input files
my $file_scenario = $dir."scenarios/index.json";
my $file_colours = $dir."colours.csv";
my $file_index = $dir."graphs/index.json";



my (@lines,%scenarios,@cols,$line,$scenario,@graphs,$html,$i,$graph,$svg);

# Get the scenario config
msg("Reading scenarios from <cyan>$file_scenario<none>\n");
open(FILE,$file_scenario);
@lines = <FILE>;
close(FILE);
%scenarios = %{JSON::XS->new->utf8->decode(join("\n",@lines))};
foreach $scenario (keys(%scenarios)){
	msg("\t$scenario: $scenarios{$scenario}{'color'} / $scenarios{$scenario}{'css'}\n");
}

# Load in the extra colour definitions
msg("Reading colours from <cyan>$file_colours<none>\n");
open(FILE,$file_colours);
@lines = <FILE>;
close(FILE);
foreach $line  (@lines){
	$line =~ s/[\n\r]//g;
	(@cols) = split(/,(?=(?:[^\"]*\"[^\"]*\")*(?![^\"]*\"))/,$line);
	if($cols[0]){
		$scenarios{$cols[0]} = ();
		$scenarios{$cols[0]}{'color'} = $cols[1];
	}
}



if(-e $file_index){
	msg("Read in graph definitions from <cyan>$file_index<none>\n");
	# Get the graph config
	open(FILE,$file_index);
	@lines = <FILE>;
	close(FILE);
	@graphs = @{JSON::XS->new->utf8->decode(join("\n",@lines))};



	# Create the SVG output
	$graph = ODILeeds::NPG->new();
	$graph->setScenarios(%scenarios);

	$html = "";
	for($i = 0; $i < (@graphs); $i++){
		msg("Processing <cyan>".$dir."graphs/$graphs[$i]{'csv'}<none>\n");
		$graph->load($dir.'graphs/'.$graphs[$i]{'csv'})->process();
		
		# If we have a y-axis scaling we scale the values
		if($graphs[$i]{'yscale'}){
			$graph->scaleY($graphs[$i]{'yscale'});
		}
		
		# Output the SVG
		$svg = $graph->draw(('yaxis-label'=>$graphs[$i]{'yaxis-label'},'yscale'=>$graphs[$i]{'yscale'},'yaxis-max'=>$graphs[$i]{'yaxis-max'},'width'=>'640','xaxis-max'=>2051,'xaxis-line'=>1,'stroke'=>3,'strokehover'=>5,'point'=>4,'pointhover'=>6,'line'=>2,'yaxis-format'=>"commify",'yaxis-labels-baseline'=>'middle','xaxis-ticks'=>1,'left'=>$graphs[$i]{'left'}));
		open(FILE,'>',$dir.'graphs/'.$graphs[$i]{'svg'});
		print FILE $svg;
		close(FILE);
		
		$html = "";
		$html .= "\t\t\t<figure class=\"jekyll-parse\">\n";
		$html .= "\t\t\t\t<figcaption><strong>Figure ".($i+1).":</strong> $graphs[$i]{'title'}</figcaption>\n";
		$html .= "\t\t\t\t<div class=\"table-holder\">";
		$html .= $graph->table(());
		$html .= "</div>\n";
		$html .= "\t\t\t\t$svg\n";
		$html .= "\t\t\t\t<div class=\"download\">\n";
		$html .= "\t\t\t\t\t<a href=\"data/graphs/$graphs[$i]{'svg'}\"><img src=\"resources/download.svg\" alt=\"download\" title=\"Download graph from Figure ".($i+1)."\" /> SVG</a>\n";
		$html .= "\t\t\t\t\t<a href=\"data/graphs/$graphs[$i]{'csv'}\"><img src=\"resources/download.svg\" alt=\"download\" title=\"Download data from Figure ".($i+1)."\" /> CSV</a>\n";
		$html .= "\t\t\t\t</div>\n";
		$html .= "\t\t\t</figure>\n\n";
		
		open(FILE,">",$dir.'graphs/'.$graphs[$i]{'figure'});
		print FILE $html;
		close(FILE);
	}

}else{
	error("Unable to read graph definitions from <cyan>$file_index<none>\n");
}




#####################
# Subroutines

sub msg {
	my $str = $_[0];
	my $dest = $_[1]||"STDOUT";
	
	my %colours = (
		'black'=>"\033[0;30m",
		'red'=>"\033[0;31m",
		'green'=>"\033[0;32m",
		'yellow'=>"\033[0;33m",
		'blue'=>"\033[0;34m",
		'magenta'=>"\033[0;35m",
		'cyan'=>"\033[0;36m",
		'white'=>"\033[0;37m",
		'none'=>"\033[0m"
	);
	foreach my $c (keys(%colours)){ $str =~ s/\< ?$c ?\>/$colours{$c}/g; }
	if($dest eq "STDERR"){
		print STDERR $str;
	}else{
		print STDOUT $str;
	}
}

sub error {
	my $str = $_[0];
	$str =~ s/(^[\t\s]*)/$1<red>ERROR:<none> /;
	msg($str,"STDERR");
}

sub warning {
	my $str = $_[0];
	$str =~ s/(^[\t\s]*)/$1<yellow>WARNING:<none> /;
	msg($str,"STDERR");
}


