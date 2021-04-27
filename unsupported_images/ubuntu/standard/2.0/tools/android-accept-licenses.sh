#!/usr/bin/expect -f

set timeout 1800
set cmd [lindex $argv 0]
set licenses [lindex $argv 1]

spawn {*}$cmd
expect {
    "Do you accept the license '*'*" {
        exp_send "y\r"
        exp_continue
    }
    "Accept? (y/N): " {
        exp_send "y\r"
        exp_continue
    }
    "Review licenses that have not been accepted (y/N)? " {
        exp_send "y\r"
        exp_continue
    }
    eof
}

lassign [wait] pid spawnid os_error waitvalue

if {$os_error == 0} {
    exit $waitvalue
} else {
    exit 1
}
