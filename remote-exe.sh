#!/usr/bin/expect -f
set ipaddress [lindex $argv 0]
set port [lindex $argv 1]
set username [lindex $argv 2]
set passwd [lindex $argv 3]
set cmd [lindex $argv 4]
set timeout 600

spawn ssh $ipaddress -p$port -l$username
expect {
    "yes/no" { send "yes\r";
               exp_continue }
    "assword:" { send "$passwd\r" }
}

expect -re "~](\$|#)"
send "$cmd \r"
expect -re "~](\$|#)"
send "exit\r"

