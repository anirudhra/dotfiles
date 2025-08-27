## Wireguard port forwarding in DD-WRT

* Access the Router Interface: Open your web browser and go to your DD-WRT router's IP address to access its web interface.
* Navigate to Port Forwarding Settings:
  * Click on the NAT / QoS tab.
  * Select the Port Range Forward subtab.
  * Create a New Port Forwarding Rule:
  * In the Application field, enter a descriptive name for your rule, such as "WireGuard".
  * Start Port: Enter the public port your WireGuard server is configured to use. The default for WireGuard is 51820, so you would enter 51820 here.
  * End Port: Enter the same port number as the start port, 51820, as WireGuard typically uses a single port.
  * Protocol: Select UDP from the dropdown menu, as WireGuard operates exclusively over the UDP protocol.
  * Destination IP Address: Leave this field blank or set it to the internal IP address of your WireGuard server or the device that will act as the server if it's behind the DD-WRT router.
* Enable the Rule: Ensure the rule is enabled. Click Save and Apply
