#!/bin/bash
if [ -f /config/startupFinished ]; then
    exit
fi
if [ ! -f /config/cloud/gce/FIRST_BOOT_COMPLETE ]; then
mkdir -p /config/cloud/gce
cat <<'EOF' > /config/installCloudLibs.sh
#!/bin/bash
echo about to execute
checks=0
while [ $checks -lt 120 ]; do echo checking mcpd
    tmsh -a show sys mcp-state field-fmt | grep -q running
    if [ $? == 0 ]; then
        echo mcpd ready
        break
    fi
    echo mcpd not ready yet
    let checks=checks+1
    sleep 10
done
echo loading verifyHash script
if ! tmsh load sys config merge file /config/verifyHash; then
    echo cannot validate signature of /config/verifyHash
    exit
fi
echo loaded verifyHash
declare -a filesToVerify=("/config/cloud/f5-cloud-libs.tar.gz" "/config/cloud/f5-cloud-libs-gce.tar.gz" "/var/config/rest/downloads/f5-appsvcs-3.26.1-1.noarch.rpm")
for fileToVerify in "${filesToVerify[@]}"
do
    echo verifying "$fileToVerify"
    if ! tmsh run cli script verifyHash "$fileToVerify"; then
        echo "$fileToVerify" is not valid
        exit 1
    fi
    echo verified "$fileToVerify"
done
mkdir -p /config/cloud/gce/node_modules/@f5devcentral
echo expanding f5-cloud-libs.tar.gz

tar xvfz /config/cloud/f5-cloud-libs.tar.gz -C /config/cloud/gce/node_modules/@f5devcentral
echo expanding f5-cloud-libs-gce.tar.gz
tar xvfz /config/cloud/f5-cloud-libs-gce.tar.gz -C /config/cloud/gce/node_modules/@f5devcentral
echo cloud libs install complete
touch /config/cloud/cloudLibsReady
EOF
echo 'Y2xpIHNjcmlwdCAvQ29tbW9uL3ZlcmlmeUhhc2ggewpwcm9jIHNjcmlwdDo6cnVuIHt9IHsKICAgICAgICBpZiB7W2NhdGNoIHsKICAgICAgICAgICAgc2V0IGhhc2hlcyhmNS1jbG91ZC1saWJzLnRhci5neikgMDRjZDliMTYxZjYxOWJmMGYwNmY1MjQ2NmY3ZTE4OTE5MTI3MzdiOGI1MGJkYTRmZTUyMWVkZDZmN2Y1NDgxOGM3MDVkODdmNzQ1YzRmMzc5NjRjOWFiODBiY2I2Zjc1NTU5NjkxN2Q4YjgzYmZmY2ExMjRlODdkN2Y1ZWZhYmQKICAgICAgICAgICAgc2V0IGhhc2hlcyhmNS1jbG91ZC1saWJzLWF3cy50YXIuZ3opIDA5MWVhN2IxOGFjYTdmMThhMGVjMzc3YTY4ODZkNWQ2NjZjYzgxMzQ5ZWFmYTU3MjVhYjA3NThkZGNjMTdjMTBlMDM3MzcxOTUzODRlYWZkNjNjMTE3ZDI1OTEzYzE1YTExMjg0ZDJjYzNiMjIxZDdiYTNjMzE0MjIxNzIxNDJiCiAgICAgICAgICAgIHNldCBoYXNoZXMoZjUtY2xvdWQtbGlicy1henVyZS50YXIuZ3opIGU3OTczYTFmZTg1YjVhODMyYzVlY2QxY2ZjZTY2YjQzYjg0ZTQyY2YyYTA2YjI3NTE3MzRmNzk4MTJkZTE4N2VlMWFkODczMGExMjljYjA4MTk4YTQ1MjE1N2M0NjZiYjg3MTgwYzE3ZGZkMmUwOWI0OWJlNmVmZTllOWE1N2ZlCiAgICAgICAgICAgIHNldCBoYXNoZXMoZjUtY2xvdWQtbGlicy1nY2UudGFyLmd6KSBjZDk1YTVjYzM2YzM5ZjgwZjk1NDc2YWQwMDBmN2RjYzIxYTlmZWY0MTRjOGVkYWM4MmJlMmU0OTFjMGZhOWViYTUxYjE0NWY3NWJhMGYzYzBkYWU0OGUxYzczMTQzMjIxN2IzYmI3MDBmNzFmZTE5MTIxNTJkYmU0MzllODk2NwogICAgICAgICAgICBzZXQgaGFzaGVzKGY1LWNsb3VkLWxpYnMtb3BlbnN0YWNrLnRhci5neikgNWM4M2ZlNmE5M2E2ZmNlYjVhMmU4NDM3YjVlZDhjYzlmYWY0YzE2MjFiZmM5ZTZhMDc3OWY2YzIxMzdiNDVlYWI4YWUwZTdlZDc0NWM4Y2Y4MjFiOTM3MTI0NWNhMjk3NDljYTBiN2U1NjYzOTQ5ZDc3NDk2Yjg3MjhmNGIwZjkKICAgICAgICAgICAgc2V0IGhhc2hlcyhmNS1jbG91ZC1saWJzLWNvbnN1bC50YXIuZ3opIGEzMmFhYjM5NzA3M2RmOTJjYmJiYTUwNjdlNTgyM2U5YjVmYWZjYTg2MmEyNThiNjBiNmI0MGFhMDk3NWMzOTg5ZDFlMTEwZjcwNjE3N2IyZmZiZTRkZGU2NTMwNWEyNjBhNTg1NjU5NGNlN2FkNGVmMGM0N2I2OTRhZTRhNTEzCiAgICAgICAgICAgIHNldCBoYXNoZXMoYXNtLXBvbGljeS1saW51eC50YXIuZ3opIDYzYjVjMmE1MWNhMDljNDNiZDg5YWYzNzczYmJhYjg3YzcxYTZlN2Y2YWQ5NDEwYjIyOWI0ZTBhMWM0ODNkNDZmMWE5ZmZmMzlkOTk0NDA0MWIwMmVlOTI2MDcyNDAyNzQxNGRlNTkyZTk5ZjRjMjQ3NTQxNTMyM2UxOGE3MmUwCiAgICAgICAgICAgIHNldCBoYXNoZXMoZjUuaHR0cC52MS4yLjByYzQudG1wbCkgNDdjMTlhODNlYmZjN2JkMWU5ZTljMzVmMzQyNDk0NWVmODY5NGFhNDM3ZWVkZDE3YjZhMzg3Nzg4ZDRkYjEzOTZmZWZlNDQ1MTk5YjQ5NzA2NGQ3Njk2N2IwZDUwMjM4MTU0MTkwY2EwYmQ3Mzk0MTI5OGZjMjU3ZGY0ZGMwMzQKICAgICAgICAgICAgc2V0IGhhc2hlcyhmNS5odHRwLnYxLjIuMHJjNi50bXBsKSA4MTFiMTRiZmZhYWI1ZWQwMzY1ZjAxMDZiYjVjZTVlNGVjMjIzODU2NTVlYTNhYzA0ZGUyYTM5YmQ5OTQ0ZjUxZTM3MTQ2MTlkYWU3Y2E0MzY2MmM5NTZiNTIxMjIyODg1OGYwNTkyNjcyYTI1NzlkNGE4Nzc2OTE4NmUyY2JmZQogICAgICAgICAgICBzZXQgaGFzaGVzKGY1Lmh0dHAudjEuMi4wcmM3LnRtcGwpIDIxZjQxMzM0MmU5YTdhMjgxYTBmMGUxMzAxZTc0NWFhODZhZjIxYTY5N2QyZTZmZGMyMWRkMjc5NzM0OTM2NjMxZTkyZjM0YmYxYzJkMjUwNGMyMDFmNTZjY2Q3NWM1YzEzYmFhMmZlNzY1MzIxMzY4OWVjM2M5ZTI3ZGZmNzdkCiAgICAgICAgICAgIHNldCBoYXNoZXMoZjUuYXdzX2FkdmFuY2VkX2hhLnYxLjMuMHJjMS50bXBsKSA5ZTU1MTQ5YzAxMGMxZDM5NWFiZGFlM2MzZDJjYjgzZWMxM2QzMWVkMzk0MjQ2OTVlODg2ODBjZjNlZDVhMDEzZDYyNmIzMjY3MTFkM2Q0MGVmMmRmNDZiNzJkNDE0YjRjYjhlNGY0NDVlYTA3MzhkY2JkMjVjNGM4NDNhYzM5ZAogICAgICAgICAgICBzZXQgaGFzaGVzKGY1LmF3c19hZHZhbmNlZF9oYS52MS40LjByYzEudG1wbCkgZGUwNjg0NTUyNTc0MTJhOTQ5ZjFlYWRjY2FlZTg1MDYzNDdlMDRmZDY5YmZiNjQ1MDAxYjc2ZjIwMDEyNzY2OGU0YTA2YmUyYmJiOTRlMTBmZWZjMjE1Y2ZjMzY2NWIwNzk0NWU2ZDczM2NiZTFhNGZhMWI4OGU4ODE1OTAzOTYKICAgICAgICAgICAgc2V0IGhhc2hlcyhmNS5hd3NfYWR2YW5jZWRfaGEudjEuNC4wcmMyLnRtcGwpIDZhYjBiZmZjNDI2ZGY3ZDMxOTEzZjlhNDc0YjFhMDc4NjA0MzVlMzY2YjA3ZDc3YjMyMDY0YWNmYjI5NTJjMWYyMDdiZWFlZDc3MDEzYTE1ZTQ0ZDgwZDc0ZjMyNTNlN2NmOWZiYmUxMmE5MGVjNzEyOGRlNmZhY2QwOTdkNjhmCiAgICAgICAgICAgIHNldCBoYXNoZXMoZjUuYXdzX2FkdmFuY2VkX2hhLnYxLjQuMHJjMy50bXBsKSAyZjIzMzliNGJjM2EyM2M5Y2ZkNDJhYWUyYTZkZTM5YmEwNjU4MzY2ZjI1OTg1ZGUyZWE1MzQxMGE3NDVmMGYxOGVlZGM0OTFiMjBmNGE4ZGJhOGRiNDg5NzAwOTZlMmVmZGNhN2I4ZWZmZmExYTgzYTc4ZTVhYWRmMjE4YjEzNAogICAgICAgICAgICBzZXQgaGFzaGVzKGY1LmF3c19hZHZhbmNlZF9oYS52MS40LjByYzQudG1wbCkgMjQxOGFjOGIxZjE4ODRjNWMwOTZjYmFjNmE5NGQ0MDU5YWFhZjA1OTI3YTZhNDUwOGZkMWYyNWI4Y2M2MDc3NDk4ODM5ZmJkZGE4MTc2ZDJjZjJkMjc0YTI3ZTZhMWRhZTJhMWUzYTBhOTk5MWJjNjVmYzc0ZmMwZDAyY2U5NjMKICAgICAgICAgICAgc2V0IGhhc2hlcyhmNS5hd3NfYWR2YW5jZWRfaGEudjEuNC4wcmM1LnRtcGwpIDVlNTgyMTg3YWUxYTYzMjNlMDk1ZDQxZWRkZDQxMTUxZDZiZDM4ZWI4M2M2MzQ0MTBkNDUyN2EzZDBlMjQ2YThmYzYyNjg1YWIwODQ5ZGUyYWRlNjJiMDI3NWY1MTI2NGQyZGVhY2NiYzE2Yjc3MzQxN2Y4NDdhNGExZWE5YmM0CiAgICAgICAgICAgIHNldCBoYXNoZXMoYXNtLXBvbGljeS50YXIuZ3opIDJkMzllYzYwZDAwNmQwNWQ4YTE1NjdhMWQ4YWFlNzIyNDE5ZThiMDYyYWQ3N2Q2ZDlhMzE2NTI5NzFlNWU2N2JjNDA0M2Q4MTY3MWJhMmE4YjEyZGQyMjllYTQ2ZDIwNTE0NGY3NTM3NGVkNGNhZTU4Y2VmYThmOWFiNjUzM2U2CiAgICAgICAgICAgIHNldCBoYXNoZXMoZGVwbG95X3dhZi5zaCkgMWEzYTNjNjI3NGFiMDhhN2RjMmNiNzNhZWRjOGQyYjJhMjNjZDllMGViMDZhMmUxNTM0YjM2MzJmMjUwZjFkODk3MDU2ZjIxOWQ1YjM1ZDNlZWQxMjA3MDI2ZTg5OTg5Zjc1NDg0MGZkOTI5NjljNTE1YWU0ZDgyOTIxNGZiNzQKICAgICAgICAgICAgc2V0IGhhc2hlcyhmNS5wb2xpY3lfY3JlYXRvci50bXBsKSAwNjUzOWUwOGQxMTVlZmFmZTU1YWE1MDdlY2I0ZTQ0M2U4M2JkYjFmNTgyNWE5NTE0OTU0ZWY2Y2E1NmQyNDBlZDAwYzdiNWQ2N2JkOGY2N2I4MTVlZTlkZDQ2NDUxOTg0NzAxZDA1OGM4OWRhZTI0MzRjODk3MTVkMzc1YTYyMAogICAgICAgICAgICBzZXQgaGFzaGVzKGY1LnNlcnZpY2VfZGlzY292ZXJ5LnRtcGwpIDQ4MTFhOTUzNzJkMWRiZGJiNGY2MmY4YmNjNDhkNGJjOTE5ZmE0OTJjZGEwMTJjODFlM2EyZmU2M2Q3OTY2Y2MzNmJhODY3N2VkMDQ5YTgxNGE5MzA0NzMyMzRmMzAwZDNmOGJjZWQyYjBkYjYzMTc2ZDUyYWM5OTY0MGNlODFiCiAgICAgICAgICAgIHNldCBoYXNoZXMoZjUuY2xvdWRfbG9nZ2VyLnYxLjAuMC50bXBsKSA2NGEwZWQzYjVlMzJhMDM3YmE0ZTcxZDQ2MDM4NWZlOGI1ZTFhZWNjMjdkYzBlODUxNGI1MTE4NjM5NTJlNDE5YTg5ZjRhMmE0MzMyNmFiYjU0M2JiYTliYzM0Mzc2YWZhMTE0Y2VkYTk1MGQyYzNiZDA4ZGFiNzM1ZmY1YWQyMAogICAgICAgICAgICBzZXQgaGFzaGVzKGY1LWFwcHN2Y3MtMy41LjEtNS5ub2FyY2gucnBtKSBiYTcxYzZlMWM1MmQwYzcwNzdjZGIyNWE1ODcwOWI4ZmI3YzM3YjM0NDE4YTgzMzhiYmY2NzY2ODMzOTY3NmQyMDhjMWE0ZmVmNGU1NDcwYzE1MmFhYzg0MDIwYjRjY2I4MDc0Y2UzODdkZTI0YmUzMzk3MTEyNTZjMGZhNzhjOAogICAgICAgICAgICBzZXQgaGFzaGVzKGY1LWFwcHN2Y3MtMy4xOC4wLTQubm9hcmNoLnJwbSkgZTcyZWU4MDA1YTI3MDcwYWMzOTlhYjA5N2U4YWE1MDdhNzJhYWU0NzIxZDc0OTE1ODljZmViODIxZGIzZWY4NmNiYzk3OWU3OTZhYjMxOWVjNzI3YmI1MTQwMGNjZGE4MTNjNGI5ZWI0YTZiM2QxMjIwYTM5NmI1ODJmOGY0MDAKICAgICAgICAgICAgc2V0IGhhc2hlcyhmNS1hcHBzdmNzLTMuMjAuMC0zLm5vYXJjaC5ycG0pIGQ0YmJhODg5MmEyMDY4YmI1M2Y4OGM2MDkwZGM2NWYxNzcwN2FiY2EzNWE3ZWQyZmZmMzk5ODAwNTdmZTdmN2EyZWJmNzEwYWIyMjg0YTFkODNkNzBiNzc0NmJlYWJhZDlkZjYwMzAxN2MwZmQ4NzI4Zjc0NTc2NjFjOTVhYzhkCiAgICAgICAgICAgIHNldCBoYXNoZXMoZjUtYXBwc3Zjcy0zLjI1LjAtMy5ub2FyY2gucnBtKSAyNmYxOWJkYWFhODFjYmUwNDIxYjNlMDhjMDk5ODdmOWRkMGM1NGIwNWE2MjZkNmEyMWE4MzZiMzQyNDhkMmQ5ZDgzMDk1ZjBkYWFkOGU3YTRhMDY4ZTllZjk5Yjg5ZmJjZDI0NmFlOGI2MTdhYzJiMjQ1NjU5OTE1N2QwZThiMwogICAgICAgICAgICBzZXQgaGFzaGVzKGY1LWFwcHN2Y3MtMy4yNi4xLTEubm9hcmNoLnJwbSkgYjQ2MGUxMTY3OWQzOGE5NjU0OWI1MDQxZGVmMjdiNDE5ZjFhNDFjOGY3ODhmOWY4YzdhMDM0YWE1Y2I1YThjOWZkMTUxYzdjNDM5YmViZDA5M2ZjZDg1Y2Q4NjU3ZjFjMDY0NTUxZDkzMzc1NjZmOWZjN2U5NTA2YzU1ZGMwMmMKICAgICAgICAgICAgc2V0IGhhc2hlcyhmNS1jbG91ZC1mYWlsb3Zlci0xLjEuMC0wLm5vYXJjaC5ycG0pIDE1YTQ0MGMyOTlmOWU0YWY4NmEzZDBmNWIwZDc1YjAwNTQzODViOTVlNDdjM2VmMTE2ZDJlMGJmYjAwNDFhMjZkY2JmNTQ5MDI4ZTJhMjZkMmM3MThlYzYxNDQ2YmQ2NTdiZTM4ZmJiY2Q5ZGI3ODFlZmU1NDE0YzE3NGFjNjhjCiAgICAgICAgICAgIHNldCBoYXNoZXMoZjUtY2xvdWQtZmFpbG92ZXItMS4zLjAtMC5ub2FyY2gucnBtKSAxOTY4MWViMzNkOWY5MTBjOTEzZjgxODAxOTk0ODVlYjY1M2I0YjVlYmVhYWUwYjkwYTZjZTgzNDFkN2EyMmZlZDhkMjE4MTViNWJhMTQ4YzQ2ODg1MmQyMGNjMjZmYWQ0YzQyNDJlNTBlY2MxODRmMWY4NzcwZGFjY2VkNmY2YQogICAgICAgICAgICBzZXQgaGFzaGVzKGY1LWNsb3VkLWZhaWxvdmVyLTEuNC4wLTAubm9hcmNoLnJwbSkgNDllOTEwOGEwNzBlMGM4NzEzYWViN2IzMzA2NjIzNTg1NDJlNjFiN2M1M2E5ZDQ1MTA4ZDM3YTliZjUyNDZmOWU0YWFhZTEwY2M2MTA2NDgwMWRjY2NkMjBiZmQ1MTA4MzQ3YjBmNjk0NTEwZTdlY2UwN2Y5NmM0NWJhNjgzYjAKICAgICAgICAgICAgc2V0IGhhc2hlcyhmNS1jbG91ZC1mYWlsb3Zlci0xLjUuMC0wLm5vYXJjaC5ycG0pIDMzYTdlMmQwNDcxMDZiY2NlNjgxNzU3YTY1MjQwYmZhY2VkZDQ4ZTEzNTY3ZTA1ZmRiMjNhNGIyNjlkMjY2YWE1MDAxZjgxMTU4YzM5NjRkYzI5N2YwNDI4ZGIzMWM5ZGY0MjgwMDI4OThkMTkwMjg1YjM0OWM1OTQyMmE1NzNiCiAgICAgICAgICAgIHNldCBoYXNoZXMoZjUtY2xvdWQtZmFpbG92ZXItMS42LjEtMS5ub2FyY2gucnBtKSBjMWI4NDJkYTIxYjhkMWJhMjFiNmViNjNjODU5OGE5ZWE5OTg2ZDVkYWRkYzIxZTRkMjgwZTFkNmIwOWQzZGIxZGU4YWM3ZGU1Yzg0ZWRmMDdiNDNlNGFmMDNkYWY4ZmU3NDdhNDA0OGY2NTczZDk1NTIwNjM1MmNkZTJjZWM2NQogICAgICAgICAgICBzZXQgaGFzaGVzKGY1LWNsb3VkLWZhaWxvdmVyLTEuNy4xLTEubm9hcmNoLnJwbSkgMTRmZjBjZDJiYjQ5NzgwY2MwYWUzMDIxYzRmYzhmY2MwOTZlM2ZjZTIyNTgwOTZhNGFhMDI2ZDZkMzdkZTcyOGNhNzM0NWJmZTNhNzkwMzFlMzM2ZTc0ZDI1YTJiNDBmZjI4MzI0YzJjNzUyYmYwZWU3MWI3ZmM4OWI2ZmM4ZmUKICAgICAgICAgICAgc2V0IGhhc2hlcyhmNS1jbG91ZC1mYWlsb3Zlci0xLjguMC0wLm5vYXJjaC5ycG0pIDIzMDg2ZDFjYmYzY2IyNGVhYzdlYmEyMzA1MTU2YzYwMGZhMjFmMWI4OTYzMjFhMmZhNTIyNWQzMzFkN2U0MTQ3MWVkYjNmNTM2ODE0NGQ4Njg0OGE0NTIwYjFlMDA1YzAxNDQ4NWZmNDUxZTdkYTY0MjkwNTNmNThiZmU4Y2U0CgogICAgICAgICAgICBzZXQgZmlsZV9wYXRoIFtsaW5kZXggJHRtc2g6OmFyZ3YgMV0KICAgICAgICAgICAgc2V0IGZpbGVfbmFtZSBbZmlsZSB0YWlsICRmaWxlX3BhdGhdCgogICAgICAgICAgICBpZiB7IVtpbmZvIGV4aXN0cyBoYXNoZXMoJGZpbGVfbmFtZSldfSB7CiAgICAgICAgICAgICAgICB0bXNoOjpsb2cgZXJyICJObyBoYXNoIGZvdW5kIGZvciAkZmlsZV9uYW1lIgogICAgICAgICAgICAgICAgZXhpdCAxCiAgICAgICAgICAgIH0KCiAgICAgICAgICAgIHNldCBleHBlY3RlZF9oYXNoICRoYXNoZXMoJGZpbGVfbmFtZSkKICAgICAgICAgICAgc2V0IGNvbXB1dGVkX2hhc2ggW2xpbmRleCBbZXhlYyAvdXNyL2Jpbi9vcGVuc3NsIGRnc3QgLXIgLXNoYTUxMiAkZmlsZV9wYXRoXSAwXQogICAgICAgICAgICBpZiB7ICRleHBlY3RlZF9oYXNoIGVxICRjb21wdXRlZF9oYXNoIH0gewogICAgICAgICAgICAgICAgZXhpdCAwCiAgICAgICAgICAgIH0KICAgICAgICAgICAgdG1zaDo6bG9nIGVyciAiSGFzaCBkb2VzIG5vdCBtYXRjaCBmb3IgJGZpbGVfcGF0aCIKICAgICAgICAgICAgZXhpdCAxCiAgICAgICAgfV19IHsKICAgICAgICAgICAgdG1zaDo6bG9nIGVyciB7VW5leHBlY3RlZCBlcnJvciBpbiB2ZXJpZnlIYXNofQogICAgICAgICAgICBleGl0IDEKICAgICAgICB9CiAgICB9CiAgICBzY3JpcHQtc2lnbmF0dXJlIFlaSTV2YmZiWm5WM3U1UHBNV0tlMXBWV2h4amxwYmw1bFo4ZWJVU2FRaXFHQkVyQjg3ZzU1R0FwQ2hmZTRLR0I0OUZNSVhUWjlEQ0dOZzNBOU9WM1ZaTk13cE5LTHM1N0V2cUZ6UEx3QlhPN2NNT1MybUlJVkJ5RzR3VU8zYk90NzJvUVk5VHVSUURQUFZOb0RlNlB0djFMSCs5R0NVV1NzVHBDRXVVdmwvTjdqL0hIUm1sV1QyREVvcnY4WmNJTldmckl4N09hNVBHQURSNnNLSm9vQUlud3A2SkZPK0FRRlR0Q056Vkp5RWljY2syTjh5clZTVFVxc01WTjJZY2Ftdyt4ZEtXVVQySUR5ZUNvZEdCaC8zOGp4ZkNPMlp6bUh3VnBlSWo1N1ZQcGlHTWlXMHZkSFF6UXl3L096K2FtR2RlQUJKMS84b053NFh0WkY0SGR2QT09CiAgICBzaWduaW5nLWtleSAvQ29tbW9uL2Y1LWlydWxlCn0=' | base64 -d > /config/verifyHash
cat <<'EOF' > /config/waitThenRun.sh
#!/bin/bash
while true; do echo "waiting for cloud libs install to complete"
    if [ -f /config/cloud/cloudLibsReady ]; then
        echo "Running f5-cloud-libs Version:"
        f5-rest-node /config/cloud/gce/node_modules/@f5devcentral/f5-cloud-libs/scripts/onboard.js --version
        break
    else
        sleep 10
    fi
done
"$@"
EOF
cat <<'EOF' > /config/cloud/gce/collect-interface.sh
#!/bin/bash
echo "MGMTADDRESS=$(/usr/bin/curl -s -f --retry 20 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/1/ip' -H 'Metadata-Flavor: Google')" >> /config/cloud/gce/interface.config
echo "MGMTMASK=$(/usr/bin/curl -s -f --retry 20 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/1/subnetmask' -H 'Metadata-Flavor: Google')" >> /config/cloud/gce/interface.config
echo "MGMTGATEWAY=$(/usr/bin/curl -s -f --retry 20 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/1/gateway' -H 'Metadata-Flavor: Google')" >> /config/cloud/gce/interface.config
echo "INT1ADDRESS=$(/usr/bin/curl -s -f --retry 20 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip' -H 'Metadata-Flavor: Google')" >> /config/cloud/gce/interface.config
echo "INT1MASK=$(/usr/bin/curl -s -f --retry 20 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/subnetmask' -H 'Metadata-Flavor: Google')" >> /config/cloud/gce/interface.config
echo "INT1GATEWAY=$(/usr/bin/curl -s -f --retry 20 'http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/gateway' -H 'Metadata-Flavor: Google')" >> /config/cloud/gce/interface.config
chmod 755 /config/cloud/gce/interface.config
reboot
EOF
cat <<'EOF' > /config/cloud/gce/custom-config.sh
#!/bin/bash
source /config/cloud/gce/interface.config
MGMTNETWORK=$(/bin/ipcalc -n ${MGMTADDRESS} ${MGMTMASK} | cut -d= -f2)
INT1NETWORK=$(/bin/ipcalc -n ${INT1ADDRESS} ${INT1MASK} | cut -d= -f2)
PROGNAME=$(basename $0)
function error_exit {
echo "${PROGNAME}: ${1:-\"Unknown Error\"}" 1>&2
exit 1
}
function wait_for_ready {
   checks=0
   ready_response=""
   while [ $checks -lt 120 ] ; do
      ready_response=$(/usr/bin/curl -sku admin:$passwd -w "%{http_code}" -X GET  https://localhost:${mgmtGuiPort}/mgmt/shared/appsvcs/info -o /dev/null)
      if [[ $ready_response == *200 ]]; then
          echo "AS3 is ready"
          break
      else
         echo "AS3" is not ready: $checks, response: $ready_response
         let checks=checks+1
         if [[ $checks == 60 ]]; then
           bigstart restart restnoded
         fi
         sleep 5
      fi
   done
   if [[ $ready_response != *200 ]]; then
      error_exit "$LINENO: AS3 was not installed correctly. Exit."
   fi
}
declare -a tmsh=()
date
echo 'starting custom-config.sh'
source /usr/lib/bigstart/bigip-ready-functions
wait_bigip_ready
tmsh+=(
"tmsh modify sys software update auto-phonehome disabled"
"tmsh modify sys global-settings mgmt-dhcp disabled"
"tmsh delete sys management-route all"
"tmsh delete sys management-ip all"
"tmsh create sys management-ip ${MGMTADDRESS}/32"
"tmsh create sys management-route mgmt_gw network ${MGMTGATEWAY}/32 type interface"
"tmsh create sys management-route mgmt_net network ${MGMTNETWORK}/${MGMTMASK} gateway ${MGMTGATEWAY}"
"tmsh create sys management-route default gateway ${MGMTGATEWAY}"
"tmsh create net vlan external interfaces add { 1.0 } mtu 1460"

"tmsh create net self self_external address ${INT1ADDRESS}/32 vlan external"
"tmsh create net route ext_gw_interface network ${INT1GATEWAY}/32 interface external"
"tmsh create net route ext_rt network ${INT1NETWORK}/${INT1MASK} gw ${INT1GATEWAY}"
"tmsh create net route default gw ${INT1GATEWAY}"
"tmsh modify sys management-dhcp sys-mgmt-dhcp-config request-options delete { ntp-servers }"
'tmsh save /sys config'
)
for CMD in "${tmsh[@]}"
do
    if $CMD;then
        echo "command $CMD successfully executed."
    else
        error_exit "$LINENO: An error has occurred while executing $CMD. Aborting!"
    fi
done
    wait_bigip_ready
    date
    ### START CUSTOM TMSH CONFIGURATION
    mgmtGuiPort="443"
    passwd=$(f5-rest-node /config/cloud/gce/node_modules/@f5devcentral/f5-cloud-libs/scripts/decryptDataFromFile.js --data-file /config/cloud/gce/.adminPassword)
    file_loc="/config/cloud/custom_config"
    url_regex="^(https?|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]$"
    if [[ "default" =~ $url_regex ]]; then
       response_code=$(/usr/bin/curl -sk -w "%{http_code}" "default" -o $file_loc)
       if [[ $response_code == 200 ]]; then
           echo "Custom config download complete; checking for valid JSON."
           cat $file_loc | jq .class
           if [[ $? == 0 ]]; then
               wait_for_ready
               response_code=$(/usr/bin/curl -skvvu admin:$passwd -w "%{http_code}" -X POST -H "Content-Type: application/json" -H "Expect:" https://localhost:${mgmtGuiPort}/mgmt/shared/appsvcs/declare -d @$file_loc -o /dev/null)
               if [[ $response_code == *200 || $response_code == *502 ]]; then
                   echo "Deployment of custom application succeeded."
               else
                   echo "Failed to deploy custom application; continuing..."
                   echo "Response code: ${response_code}"
               fi
           else
               echo "Custom config was not valid JSON, continuing..."
           fi
       else
           echo "Failed to download custom config; continuing..."
           echo "Response code: ${response_code}"
       fi
    else
       echo "Custom config was not a URL, continuing..."
    fi
### END CUSTOM TMSH CONFIGURATION
EOF
cat <<'EOF' > /config/cloud/gce/custom-config2.sh
#!/bin/bash
echo about to execute
checks=0
while [ $checks -lt 120 ]; do echo checking mcpd
    tmsh -a show sys mcp-state field-fmt | grep -q running
    if [ $? == 0 ]; then
        echo mcpd ready
        break
    fi
    echo mcpd not ready yet
    let checks=checks+1
    sleep 10
done
source /config/cloud/gce/interface.config
tmsh delete sys management-ip all
tmsh create sys management-ip ${MGMTADDRESS}/32
tmsh save sys config
EOF
checks=0
while [ $checks -lt 12 ]; do echo checking downloads directory
    if [ -d "/var/config/rest/downloads" ]; then
        echo downloads directory ready
        break
    fi
    echo downloads directory not ready yet
    let checks=checks+1
    sleep 10
done
if [ ! -d "/var/config/rest/downloads" ]; then
    mkdir -p /var/config/rest/downloads
fi
/usr/bin/curl -s -f --retry 20 -o /config/cloud/f5-cloud-libs.tar.gz https://cdn.f5.com/product/cloudsolutions/f5-cloud-libs/v4.25.0/f5-cloud-libs.tar.gz
/usr/bin/curl -s -f --retry 20 -o /config/cloud/f5-cloud-libs-gce.tar.gz https://cdn.f5.com/product/cloudsolutions/f5-cloud-libs-gce/v2.9.1/f5-cloud-libs-gce.tar.gz
/usr/bin/curl -s -f --retry 20 -o /var/config/rest/downloads/f5-appsvcs-3.26.1-1.noarch.rpm https://cdn.f5.com/product/cloudsolutions/f5-appsvcs-extension/v3.26.1/f5-appsvcs-3.26.1-1.noarch.rpm
chmod 755 /config/verifyHash
chmod 755 /config/installCloudLibs.sh
chmod 755 /config/waitThenRun.sh
chmod 755 /config/cloud/gce/custom-config.sh
chmod 755 /config/cloud/gce/custom-config2.sh
chmod 755 /config/cloud/gce/collect-interface.sh
mkdir -p /var/log/cloud/google
echo "No analytics."
touch /config/cloud/gce/FIRST_BOOT_COMPLETE
nohup /usr/bin/setdb provision.extramb 1000 &>> /var/log/cloud/google/install.log < /dev/null &
nohup /usr/bin/setdb restjavad.useextramb true &>> /var/log/cloud/google/install.log < /dev/null &
nohup /usr/bin/curl -s -f -u admin: -H "Content-Type: application/json" -d '{"maxMessageBodySize":134217728}' -X POST http://localhost:8100/mgmt/shared/server/messaging/settings/8100 | jq . &>> /var/log/cloud/google/install.log < /dev/null &
nohup /config/installCloudLibs.sh >> /var/log/cloud/google/install.log < /dev/null &
nohup /config/waitThenRun.sh f5-rest-node /config/cloud/gce/node_modules/@f5devcentral/f5-cloud-libs/scripts/onboard.js --db provision.managementeth:eth1 --host localhost -o /var/log/cloud/google/mgmt-swap.log --log-level info --signal MGMT_SWAP_DONE >> /var/log/cloud/google/install.log < /dev/null &
nohup /config/waitThenRun.sh f5-rest-node /config/cloud/gce/node_modules/@f5devcentral/f5-cloud-libs/scripts/runScript.js --file /config/cloud/gce/collect-interface.sh --cwd /config/cloud/gce -o /var/log/cloud/google/interface-config.log --wait-for MGMT_SWAP_DONE --log-level info >> /var/log/cloud/google/install.log < /dev/null &
elif [ ! -f /config/cloud/gce/SECOND_BOOT_COMPLETE ]; then
nohup /config/waitThenRun.sh f5-rest-node /config/cloud/gce/node_modules/@f5devcentral/f5-cloud-libs/scripts/onboard.js --host localhost --signal ONBOARD_DONE --port 443 --ssl-port 443 -o /var/log/cloud/google/onboard.log --log-level info --install-ilx-package file:///var/config/rest/downloads/f5-appsvcs-3.26.1-1.noarch.rpm --ntp time.google.com --tz UTC --modules ltm:nominal >> /var/log/cloud/google/install.log < /dev/null & 
nohup /config/waitThenRun.sh f5-rest-node /config/cloud/gce/node_modules/@f5devcentral/f5-cloud-libs/scripts/runScript.js --file /config/cloud/gce/custom-config.sh --cwd /config/cloud/gce -o /var/log/cloud/google/custom-config.log --wait-for ONBOARD_DONE --signal CUSTOM_CONFIG_DONE --log-level info >> /var/log/cloud/google/install.log < /dev/null &
touch /config/cloud/gce/SECOND_BOOT_COMPLETE
else
nohup /config/waitThenRun.sh f5-rest-node /config/cloud/gce/node_modules/@f5devcentral/f5-cloud-libs/scripts/runScript.js --file /config/cloud/gce/custom-config2.sh --cwd /config/cloud/gce -o /var/log/cloud/google/custom-config2.log --signal CUSTOM_CONFIG2_DONE --log-level info >> /var/log/cloud/google/install.log < /dev/null &
touch /config/startupFinished
fi