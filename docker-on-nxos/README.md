== Prerequisites ==

* NX-OS version 9.2(1) or newer
  * Nexus 9000 switches with >8GB RAM
  * Nexus 9000v virtual switch
  * Either: HTTP support enabled (preferred)
  * Or: Supported CA signed SSL certificate
* DEVNET Sandbox “Open NX-OS with Nexus 9Kv Lab” Reservation
* VPN Connection into the Sandbox

== Installation ==

* (On Nexus switch) Enable HTTP tcp/80 (if needed)

```
! Enter config mode
configure terminal
!
! Enable HTTP NXAPI Support
nxapi http port 80
!
! Exit
end
```

* (On server) Activate Python 3.6 (or newer) virtual environment

```python
python3 config_docker.py -t NXOS_MGMT_IP
```
