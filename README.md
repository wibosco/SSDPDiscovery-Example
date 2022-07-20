[![Build Status](https://github.com/wibosco/SSDPDiscovery-Example/actions/workflows/workflow.yml/badge.svg)](https://github.com/wibosco/SSDPDiscovery-Example/actions/workflows/workflow.yml)
<a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.0-orange.svg?style=flat" alt="Swift" /></a>
<a href="https://twitter.com/wibosco"><img src="https://img.shields.io/badge/twitter-@wibosco-blue.svg?style=flat" alt="Twitter: @wibosco" /></a>

# SSDPDiscovery-Example
A Swift example project on how to use SSDP to discover services on the network as shown in this article - https://williamboles.com/discovering-whats-out-there-with-ssdp/

iOS 14 introduced a range of privacy features, one of which was to limit an app access to the local network. Especially if that app is attempting to discover what is on that network using multicasting (which is exactly what this example project is demonstrating). As such, in order to run this example on a device you will need to request that the `com.apple.developer.networking.multicast` entitlement is enabled from Apple (the example works on the simulator without the entitlement being enabled). See this [note](https://developer.apple.com/news/?id=0oi77447) for more details.
