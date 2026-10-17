# OpenWrt Recovery Guide: Linksys MX4300 / LN1301

This guide covers the recovery process for a Linksys MX4300 router that is experiencing a silent kernel boot crash (indicated by a solid blue/purple LED accompanied by a total loss of LAN port network response and DHCP failure).

## Prerequisites (Fedora / Linux Host)

- An Ethernet cable connecting your laptop to **LAN Port 1** on the router.
- OpenWrt default fallback IP: `192.168.1.1`

---

## Step 1: Force Hardware Failsafe Mode (WPS Method)

Standard reset buttons can fail if the operating system crashes during late boot stages. Bypassing the corrupted overlay partition requires forcing a hardware override during the early boot sequence:

1. Unplug the router's power cable.
2. Plug the power cable back in.
3. **Immediately begin tapping (spamming) the physical WPS button rapidly** (2–3 times per second). Keep spamming it continuously through the early solid light and initial flashing light phases.
4. **Verification:** If successful, the standard boot sequence will abort, and the LED will change to a **rapidly flashing red light**. This confirms the router is idling in OpenWrt Failsafe Mode.

---

## Step 2: Configure the Host Network Interface

Failsafe Mode does not run a DHCP server. You must manually assign a static IP to your laptop's Ethernet adapter within the `192.168.1.x` subnet to establish communication.

1. Open a terminal and identify your wired network interface name:

   ```bash
   ip link show
   ```

2. Manually flush any dynamic profiles and assign a static IP (`192.168.1.254`):

   ```bash
   sudo ip addr flush dev <your_interface_name>
   sudo ip addr add 192.168.1.254/24 dev <your_interface_name>
   sudo ip link set dev <your_interface_name> up
   ```

---

## Step 3: Connect to the Router via SSH

Modern Qualcomm `ipq807x` targets utilize encrypted SSH connections for safety drops instead of unencrypted Telnet.

1. From the terminal, bypass local host key checking to establish a direct connection to the minimal recovery root shell:

   ```bash
   ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.1
   ```

2. Accept the connection if prompted. You will be greeted by the OpenWrt recovery terminal prompt: `root@(none):/#`

---

## Step 4: Wipe Corrupted Configuration Data

Format the broken user configuration block layout stored on the system flash storage overlay and trigger a clean restart:

1. Execute the factory reset utility:

   ```bash
   firstboot -y
   ```

2. Force an immediate system reboot:

   ```bash
   reboot -f
   ```

---

## Step 5: Post-Recovery Cleanup

1. Disconnect or close your SSH session.
2. While the router reboots (takes 2–3 minutes), revert your laptop's network settings back to automatic configuration to receive a fresh local network lease:

   ```bash
   # Revert to managed network control (NetworkManager default)
   sudo ip addr del 192.168.1.254/24 dev <your_interface_name>
   ```

3. Once the router finishes booting normally, open your browser and navigate to **`http://192.168.1.1`** to access a fresh OpenWrt LuCI dashboard setup screen.
