#!/usr/bin/expect -f
set ipaddress [lindex $argv 0]
set port [lindex $argv 1]
set username [lindex $argv 2]
set passwd [lindex $argv 3]
set file [lindex $argv 4]
set pwd [lindex $argv 5]
set timeout 600

spawn scp $file $ipaddress:$pwd 
expect {
    "yes/no" { send "yes\r";
               exp_continue }
    "assword:" { send "$passwd\r" }
}
expect eof
