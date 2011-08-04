#!/usr/bin/perl
use strict;
use warnings;
#use Smart::Comments;
use FindBin::libs;
use Worklog;
use App::Options(
    values => \%ARGV,
    option => {
        action  => 'type=/^(insert|summary|list)$/; required;',
        type    => 'type=/^(DEV|PROGRAM|SCHEDULE|WORK|MAIL|ESTIMATE|MANAGE|DIRECTION|REST|REVIEW|MTG|OTHERS|JOB|END)$/;',
        content => 'type=string;',
        project => 'type=string;',
        term    => 'type=/^(today|week|month)$/; default=today',
        start   => 'type=string;',
        end     => 'type=string;',
    },
);

### %ARGV
### @Worklog::EXPORT
### @Worklog::TYPES

if    ($ARGV{'action'} eq 'insert')  { insert(%ARGV); }
elsif ($ARGV{'action'} eq 'summary') { summary(%ARGV); }
elsif ($ARGV{'action'} eq 'list')    { list(%ARGV); }
