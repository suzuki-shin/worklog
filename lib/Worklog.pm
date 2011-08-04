package Worklog;
use strict;
use warnings;
#use Smart::Comments;
use DBIx::Simple;
use DateTime;
use DateTime::Duration;
use Exporter;
use Config::Auto;
our @ISA    = qw(Exporter);
our @EXPORT = qw(insert summary list);
my $conf = Config::Auto::parse('conf/worklog.conf', format => 'yaml');
my $DSN = 'dbi:SQLite:dbname=' . $conf->{'worklog_dir'} . $conf->{'db_name'};

my $dt_now = DateTime->now( time_zone => 'Asia/Tokyo' );
my $db     = DBIx::Simple->connect($DSN) or die DBIx::Simple->error;

# 作業ログをINSETする
sub insert {
    my %ARGV = @_;
    die "bad type. $ARGV{'type'} cannot use at insert.\n" if ($ARGV{'type'} eq 'JOB');

    my $now  = _get_datetime_str( $dt_now );

    my $last_data = $db->query('SELECT id, start, end FROM log ORDER BY id DESC LIMIT 1')->hashes;
    unless (defined $last_data) {       # テーブルが無ければ作成する
        $db->query(
            'CREATE TABLE log
                (id INTEGER PRIMARY KEY, start DATETIME, end DATETIME,
                 type TEXT, project TEXT, content TEXT, time INTEGER)'
        ) or die DBIx::Simple->error;
        $last_data = $db->query('SELECT id, start, end FROM log ORDER BY id DESC LIMIT 1')->hashes;
    }
### $last_data

    if (defined $last_data->[0] && (! defined($last_data->[0]{'end'}))) {
        my $last_id    = $last_data->[0]{'id'};
        my $last_start = $last_data->[0]{'start'};

        my ($ls_year, $ls_month, $ls_day, $ls_hour, $ls_minute, $ls_second)
            = _split_datetime_str($last_start);

        my $dt_last = DateTime->new(
            time_zone => 'Asia/Tokyo',
            year      => $ls_year,
            month     => $ls_month,
            day       => $ls_day,
            hour      => $ls_hour,
            minute    => $ls_minute,
            second    => $ls_second
        );

        my $dur  = $dt_now->delta_ms($dt_last);
        my $time = $dur->delta_minutes;
        $db->query(
            'UPDATE log SET end = ?, time = ? WHERE id = ?',
            $now, $time, $last_id) or die $db->error;
    }

    if ($ARGV{'type'} ne 'END') { # END（一日の終わり）だったら新しいレコードをINSERTしない
        $ARGV{'type'}    ||= 'OTHERS';
        $ARGV{'project'} ||= 'others';

        $db->query(
            'INSERT INTO log (start, type, content, project) VALUES (?, ?, ?, ?)',
            $now, $ARGV{'type'}, $ARGV{'content'}, $ARGV{'project'}) or die $db->error;
    }

    print $db->query( 'SELECT * FROM log ORDER BY id DESC LIMIT 2' )->text('table')
        or die $db->error;
}

# （開始日と終了日を指定した期間の）のtype毎, project毎の時間を表示
sub summary {
    my %ARGV = @_;
### %ARGV
    my $start = $ARGV{'start'} || $dt_now->ymd . ' 00:00:00';
    my $end = $ARGV{'end'} || $dt_now->ymd . ' 23:59:59';
    my $type_summary = $db->query(
        'SELECT SUM(time), type FROM log WHERE start >= ? AND end <= ? GROUP BY type',
        $start, $end)->text('table') or die $db->error;
    my $project_summary = $db->query(
        'SELECT project, SUM(time) FROM log WHERE start >= ? AND end <= ? GROUP BY project',
        $start, $end)->text('table') or die $db->error;
    my $content_summary = $db->query(
        'SELECT project, SUM(time), content FROM log WHERE start >= ? AND end <= ? GROUP BY content, project ORDER BY project',
        $start, $end)->text('table') or die $db->error;

    print "from $start until $end\n\n$type_summary===================\n\n$project_summary===================\n\n$content_summary\n";
#     print $db->query('select "ALL", sum(time) from log where start >= ?',
#                      $dt_now->ymd)->text('table') or die $db->error;
}

# （今日、今週、今月）の一覧表示
sub list {
    my %ARGV = @_;
    my $dt_weekstart = _get_weekstart($dt_now);
    my $dt_monthstart = _get_monthstart($dt_now);
    my $date = $ARGV{'term'} eq 'today' ? $dt_now->ymd
             : $ARGV{'term'} eq 'week'  ? $dt_weekstart->ymd
             : $ARGV{'term'} eq 'month' ? $dt_monthstart->ymd
                                        : $dt_now->ymd;
### $date
    my %where = (start => { '>=', $date });
    if ($ARGV{'type'}) {
        $where{'type'} = $ARGV{'type'} eq 'JOB'
            ? [qw(DEV PROGRAM WORK MAIL MTG DIRECTION ESTIMATE SCHEDULE)]
            : $ARGV{'type'};
    }
    if ($ARGV{'project'}) { $where{'project'} = $ARGV{'project'}; }
    my @order = qw(id);
    print $db->select('log', 'id, time, type, project, content, start, end',
                      \%where, \@order)->text('table') or die $db->error;
    my $sum = $db->select('log', 'sum(time)', \%where)->text('table') or die->$db->error;
    print "============================\n$sum\n";
}

sub _get_datetime_str {
    my $dt = shift;
    return $dt->ymd . ' ' . $dt->hms;
}

sub _get_weekstart {
    my $dt = shift;
    return DateTime->now( time_zone => 'Asia/Tokyo' )->subtract( days => $dt->dow );
}

sub _get_monthstart {
    my $dt = shift;
    return DateTime
        ->last_day_of_month( year => $dt->year, month => $dt->month )
        ->subtract( months => 1 )
        ->add( days => 1 );
}

sub _split_datetime_str {
    my $datetime_str = shift;

    my ($ymd, $hhmmss)           = split(/\s/, $datetime_str);
    my ($year, $month, $day)     = split(/\-/, $ymd);
    my ($hour, $minute, $second) = split(/:/, $hhmmss);

    return ($year, $month, $day, $hour, $minute, $second);
}


1;
