#! /usr/bin/perl -w

use warnings;
use strict;
require 5.008;

BEGIN {
    unshift @INC, "$ENV{PROJ_PATH}/etc/perl_local_lib"; #ParseExcel module installed in this directory
}
use Spreadsheet::ParseExcel;
use Getopt::Long;

###############################################################################################################
### global variables
###############################################################################################################
my $WorkBookName;
my $BlockName;
my $workbook;
my $row_min;
my $row_max;
my $col_min;
my $col_max;
my @cvgrps = ();
my $worksheet;
my $help;
my $used_in_class;

########################################################################################################################################
### Subroutines
########################################################################################################################################

sub parse_args {
  Getopt::Long::GetOptions (
    "help"                => \$help,               
    "class"               => \$used_in_class,
    "WorkBookName=s"      => \$WorkBookName,
    "BlockName=s"         => \$BlockName,
  );

sub usage {
print <<USAGE;

****************************************************************************************************************************************
Script for parsing coverage excel to generage covergroup define file and new file
****************************************************************************************************************************************
    Options : -WorkBookName=s                              #input excel file name
              -BlockName=s                                 #ip_covgrp_def.sv, ip_covgrp_new.sv and ip_covgrp_sample.sv will be generage
              -class                                       #Indicate coverages will be included in class

    Usage   : parse_covgrp.pl -WorkBookName EXCEL NAME [-BlockName BLOCK] [-class]

    Example : parse_covgrp.pl -WorkBookName func_cov.xls -Blockname usb   #usb_covgrp_def.sv, usb_covgrp_new.sv and usb_covgrp_sample.sv
              parse_covgrp.pl -WorkBookName func_cov.xls -class           #covgrp_def.sv, covgrp_new.sv and covgrp_sample.sv
*****************************************************************************************************************************************
USAGE
}

  if($help) {
    usage();
    exit;
  }
}


sub read_excel {
  my $sheet_cnt = 0;
  my $current_covtype;
  my $parser = Spreadsheet::ParseExcel -> new();
  $workbook = $parser->parse($WorkBookName);

  foreach my $sheet ($workbook->worksheets()) {
    if($sheet_cnt == 0) {
      $worksheet = $sheet;
      ($row_min, $row_max) = $sheet -> row_range();
      ($col_min, $col_max) = $sheet -> col_range();
      print "row_min = $row_min, row_max = $row_max, col_min = $col_min, col_max = $col_max\n";
    } else {
      warn "***Warning***: More than one worksheet detected, only the first worksheet will be parsed!\n";
      last;
    }
    $sheet_cnt ++;
  }
  foreach my $row (($row_min +1)..$row_max) { #read header
    my $covergroup = {}; #refrence
    my $excel_row = $row;

    $excel_row = $row + 1;
    #print "************************row: $row************************************\n";
    foreach my $col ($col_min..$col_max) {
      if($col == 0) {
        if(my $cell = $worksheet -> get_cell($row, $col)) {
          my $value = $cell -> value();
          $value =~ s/[\s+]//g;
          if($value =~ /#/ || $value eq "") {
            next;
          }
          #print "[debug] covergroupname ($row,$col) = $value\n";
          $covergroup->{"covergroup_name"} = $value;
        } else {
          die "***Error***: 'CovergroupName' of row $excel_row must be specified!\nExit from script.\n";
        }
        #print "covergroup_name of row %d: %s\n", $row, $value;
      }
      if($col == 1) {
        if(my $cell = $worksheet -> get_cell($row, $col)) {
          my $value = $cell -> value();
          #$value =~ s/[\s+]//g; #blank between posedge and event can not be ignored.
          $covergroup->{"trigger_event"} = $value;
          #printf "trigger_event of row %d: %s\n", $row, $value;
        }
      }
      if($col == 2) { #$col=2 is Note column
        if(my $cell = $worksheet -> get_cell($row, $col)) { #Judge if cell is defined
          my $value = $cell -> value();
          $value =~ s/[\s+]//g;
          $covergroup->{"cover_type"} = $value;
          #print "[debug]covtype($row,$col) = $value\n";
          if($value =~ /#/ || $value eq "") {
            next;
          }
          if($value ne ''){
            if($value ne "coverpoint" && $value ne "cross") {
              die "***Error***: 'CoverType' of row $excel_row is not 'coverpoint' or 'cross'! \nExit from script.\n";
            } else {
              $current_covtype = $value;
            }
          }
        } else {
          die "***Error***: 'CoverType' of row $excel_row must be specified!\nExit from script.\n";
        }
        #printf "cover_type of row %d: %s\n", $row, $value;
      }
      if($col == 3) {
        if(my $cell = $worksheet -> get_cell($row, $col)) {
          my $value = $cell -> value();
          $value =~ s/[\s+]//g;
          $covergroup->{"point_name"} = $value;
        }
      }
      if($col == 4) {
        if(my $cell = $worksheet -> get_cell($row, $col)) {
          my $value = $cell -> value();
          $value =~ s/[\s+]//g;
          $covergroup->{"variable_name"} = $value;
        } else {
          die "***Error***: 'VariableName' of row $excel_row must be specified!\nExit from script.\n";
        }
        #printf "variable_name of row %d: %s\n", $row, $value;
      }
      if($col == 5) { #Point Condition
        if(my $cell = $worksheet -> get_cell($row, $col)) {
          my $value = $cell -> value();
          $value =~ s/[\s+]//g;
          $covergroup->{"point_condition"} = $value;
        }
        #printf "point_condition of row %d: %s\n", $row, $value;
      }
      if($col == 6) { #Bin Condition
        if(my $cell = $worksheet -> get_cell($row, $col)) {
          my $value = $cell -> value();
          $value =~ s/[\s+]//g;
          $covergroup->{"bin_condition"} = $value;
        }
        #printf "bin_condition of row %d: %s\n", $row, $value;
      }
      if($col == 7) { #BinName
        if(my $cell = $worksheet -> get_cell($row, $col)) { #Judge if cell is defined
          my $value = $cell -> value();
          $value =~ s/[\s+]//g if($current_covtype eq "coverpoint");
          $covergroup->{"bin_name"} = $value;
        } else { #undefined cell
            if($current_covtype eq "coverpoint") {
              die "***Error***: BinName of row $excel_row for covertype 'coverpoint' must be specified! \nExit from script.\n";
            }
        }
        #printf "cover_type of row %d: %s\n", $row, $value;
      }
      if($col == 8) { #BinValue
        if(my $cell = $worksheet -> get_cell($row, $col)) { #Judge if cell is defined
          my $value = $cell -> value();
          $value =~ s/[\s+]//g;
          $covergroup->{"bin_value"} = $value;
        } else { #undefined cell
            if($current_covtype eq "coverpoint") {
              die "***Error***: BinValue of row $excel_row for covertype 'coverpoint' must be specified! \nExit from script.\n";
            }
        }
        #printf "bin_value of row %d: %s\n", $row, $value;
      }
    }
    push(@cvgrps, $covergroup);
  }
}

sub gen_covgroup_def {
  my $cvgrp_started_flag;
  my $covpoint_started_flag;

  my $covgrp_def_file = defined $BlockName ? "${BlockName}_covgrp_def.sv" : "covgrp_def.sv";
  open my $fh, ">$covgrp_def_file" or die "Can not open $covgrp_def_file: $!";
  foreach my $cvgrp (@cvgrps) {
    #************************generage covergroup row*******************************
    if($cvgrp->{"covergroup_name"} ne "") {
      if($cvgrp_started_flag) {
        print $fh "  }\n";
        print $fh "  option.per_instance = 1;\n";
        print $fh "endgroup\n";
        $cvgrp_started_flag = 0;
        $covpoint_started_flag = 0; #coverpoint can not stride over covergroup, otherwise } would be printed at the begining
      }
      if(defined $cvgrp->{'trigger_event'} && $cvgrp->{'trigger_event'} ne "") {
        print $fh "covergroup $cvgrp->{'covergroup_name'} @($cvgrp->{'trigger_event'});\n";
      } else {
        print $fh "covergroup $cvgrp->{'covergroup_name'};\n";
      }
      $cvgrp_started_flag = 1;
    }
    #*********************************generage coverpoint row*****************
    if($cvgrp->{"cover_type"} ne ""){
      if($covpoint_started_flag) {
        print $fh "  }\n";
        $covpoint_started_flag = 0;
      }
      if(defined $cvgrp->{"point_name"} && $cvgrp->{"point_name"} ne "") {
        if(defined $cvgrp->{"point_condition"} && $cvgrp->{'point_condition'} ne "") {
          print $fh "    $cvgrp->{'point_name'}: $cvgrp->{'cover_type'} $cvgrp->{'variable_name'} iff($cvgrp->{'point_condition'}) {\n";
        } else {
          print $fh "    $cvgrp->{'point_name'}: $cvgrp->{'cover_type'} $cvgrp->{'variable_name'} {\n";
        }
      } else {
        if(defined $cvgrp->{"point_condition"} && $cvgrp->{'point_condition'} ne "") {
          print $fh "    $cvgrp->{'cover_type'} $cvgrp->{'variable_name'} iff($cvgrp->{'point_condition'}) {\n";
        } else {
          print $fh "    $cvgrp->{'cover_type'} $cvgrp->{'variable_name'} {\n";
        }
      }
      $covpoint_started_flag = 1;
    }
    #***********************generage bin row*************************************
    if(defined $cvgrp->{"bin_name"} && $cvgrp->{"bin_name"} ne "") {
      if($cvgrp->{"bin_name"} =~ /ignore_bins/) {
        print $fh "      $cvgrp->{'bin_name'};\n";
      } else {
        if(defined $cvgrp->{"bin_condition"} && $cvgrp->{'bin_condition'} ne "") {
          print $fh "      bins  $cvgrp->{'bin_name'} = {$cvgrp->{'bin_value'}} iff($cvgrp->{'bin_condition'});\n";
        } else {
          print $fh "      bins  $cvgrp->{'bin_name'} = {$cvgrp->{'bin_value'}};\n";
        }
      }
    }
  }
  #******************************generage tails*******************************************************
  print $fh "  }\n";
  print $fh "  option.per_instance = 1;\n";
  print $fh "endgroup\n";
  $cvgrp_started_flag = 0;
  close($fh);
  print "$covgrp_def_file generated in current directory.\n";
}

sub gen_covgroup_new {
  my $covgrp_new_file = defined $BlockName ? "${BlockName}_covgrp_new.sv" : "covgrp_new.sv";
  open my $fh, ">$covgrp_new_file" or die "Can not open $covgrp_new_file: $!";
  foreach my $cvgrp (@cvgrps) {
    if($cvgrp->{"covergroup_name"} ne "") {
      if($used_in_class) {
        print $fh "$cvgrp->{'covergroup_name'} = new();\n";
      } else {
        print $fh "$cvgrp->{'covergroup_name'} $cvgrp->{'covergroup_name'}_inst = new();\n";
      }
    }
  }
  foreach my $cvgrp (@cvgrps) {
    if($cvgrp->{"covergroup_name"} ne "") {
      if($used_in_class) {
        print $fh "$cvgrp->{'covergroup_name'}.set_inst_name(\"$cvgrp->{'covergroup_name'}\");\n";
      } else {
        print $fh "$cvgrp->{'covergroup_name'} $cvgrp->{'covergroup_name'}_inst.set_inst_name(\"$cvgrp->{'covergroup_name'}\");\n";
      }
    }
  }
  close($fh);
  print "$covgrp_new_file generaged in current directory.\n";
}

sub gen_covgroup_sample{
  my $covgrp_sample_file = defined $BlockName ? "${BlockName}_covgrp_sample.sv" : "covgrp_sample.sv";
  open my $fh, ">$covgrp_sample_file" or die "Can not open $covgrp_sample_file: $!";
  foreach my $cvgrp (@cvgrps) {
    if($cvgrp->{"covergroup_name"} ne "") {
      if($used_in_class) {
        print $fh "$cvgrp->{'covergroup_name'}.sample();\n";
      } else {
        print $fh "$cvgrp->{'covergroup_name'}_inst.sample();\n";
      }
    }
  }
  close($fh);
  print "$covgrp_sample_file generaged in current directory.\n";
}

#########################################################################################################################
# Main
#########################################################################################################################
parse_args();
read_excel();
gen_covgroup_def();
gen_covgroup_new();
gen_covgroup_sample();
