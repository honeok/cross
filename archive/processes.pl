#!/usr/bin/perl
use strict;
use warnings;

# 获取CPU和内存占用最多的前10个进程
my $cpu_command = "ps aux --sort=-%cpu | head -n 11";
my $mem_command = "ps aux --sort=-%mem | head -n 11";

# 获取CPU使用最多的前10个进程
print "Top 10 Processes by CPU Usage:\n";
print "USER      PID      CPU(%)   MEM(%)   COMMAND\n";
print "-" x 70 . "\n";
my @cpu_processes = `$cpu_command`;

foreach my $line (@cpu_processes) {
    next if $line =~ /^USER/;  # 跳过标题行
    chomp $line;
    
    # 跳过空行
    next if $line =~ /^\s*$/;
    
    my @fields = split(/\s+/, $line);
    
    # 确保格式对齐
    my ($user, $pid, $cpu, $mem, @command) = @fields;
    my $command = join(" ", @command);  # 合并命令行参数
    
    # 如果某些列为空，设置默认值以确保格式对齐
    $user ||= '-';
    $pid ||= '-';
    $cpu ||= '0.0';
    $mem ||= '0.0';
    $command ||= 'N/A';
    
    # 确保只输出有效数据
    next if $pid eq '-' || $cpu eq '0.0' || $mem eq '0.0' || $command eq 'N/A';
    
    # 输出完整的命令行
    printf "%-9s %-8s %-9s %-9s %s\n", $user, $pid, $cpu, $mem, $command;
}

print "\n";

# 获取内存使用最多的前10个进程
print "Top 10 Processes by Memory Usage:\n";
print "USER      PID      CPU(%)   MEM(%)   COMMAND\n";
print "-" x 70 . "\n";
my @mem_processes = `$mem_command`;

foreach my $line (@mem_processes) {
    next if $line =~ /^USER/;  # 跳过标题行
    chomp $line;
    
    # 跳过空行
    next if $line =~ /^\s*$/;
    
    my @fields = split(/\s+/, $line);
    
    # 确保格式对齐
    my ($user, $pid, $cpu, $mem, @command) = @fields;
    my $command = join(" ", @command);  # 合并命令行参数
    
    # 如果某些列为空，设置默认值以确保格式对齐
    $user ||= '-';
    $pid ||= '-';
    $cpu ||= '0.0';
    $mem ||= '0.0';
    $command ||= 'N/A';
    
    # 确保只输出有效数据
    next if $pid eq '-' || $cpu eq '0.0' || $mem eq '0.0' || $command eq 'N/A';
    
    # 输出完整的命令行
    printf "%-9s %-8s %-9s %-9s %s\n", $user, $pid, $cpu, $mem, $command;
}