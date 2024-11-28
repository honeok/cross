#!/usr/bin/perl
use strict;
use warnings;

# 获取 CPU 和内存占用最多的前 10 个进程
my $cpu_command = "ps -eo pid,%cpu,%mem,comm --sort=-%cpu | head -n 11";  # 排序按 CPU 占用
my $mem_command = "ps -eo pid,%cpu,%mem,comm --sort=-%mem | head -n 11";  # 排序按内存占用

# 获取 CPU 使用最多的前 10 个进程
print "Top 10 Processes by CPU Usage:\n";
print "PID      CPU(%)   MEM(%)   Command\n";
print "-" x 50 . "\n";
my @cpu_processes = `$cpu_command`;

foreach my $line (@cpu_processes) {
    next if $line =~ /^PID/;  # 跳过标题行
    chomp $line;
    
    # 跳过空行
    next if $line =~ /^\s*$/;
    
    my ($pid, $cpu, $mem, $command) = split(/\s+/, $line);
    
    # 如果某些列为空，设置默认值以确保格式对齐
    $pid ||= '-';
    $cpu ||= '0.0';
    $mem ||= '0.0';
    $command ||= 'N/A';
    
    # 确保只输出有效数据
    next if $pid eq '-' || $cpu eq '0.0' || $mem eq '0.0' || $command eq 'N/A';
    
    printf "%-8s %-9s %-9s %s\n", $pid, $cpu, $mem, $command;
}

print "\n";

# 获取内存使用最多的前 10 个进程
print "Top 10 Processes by Memory Usage:\n";
print "PID      CPU(%)   MEM(%)   Command\n";
print "-" x 50 . "\n";
my @mem_processes = `$mem_command`;

foreach my $line (@mem_processes) {
    next if $line =~ /^PID/;  # 跳过标题行
    chomp $line;
    
    # 跳过空行
    next if $line =~ /^\s*$/;
    
    my ($pid, $cpu, $mem, $command) = split(/\s+/, $line);
    
    # 如果某些列为空，设置默认值以确保格式对齐
    $pid ||= '-';
    $cpu ||= '0.0';
    $mem ||= '0.0';
    $command ||= 'N/A';
    
    # 确保只输出有效数据
    next if $pid eq '-' || $cpu eq '0.0' || $mem eq '0.0' || $command eq 'N/A';
    
    printf "%-8s %-9s %-9s %s\n", $pid, $cpu, $mem, $command;
}
