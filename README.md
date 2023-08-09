# Opensips::Mi

[![Build Status](https://travis-ci.org/staskobzar/opensips-mi.png?branch=master)](https://travis-ci.org/staskobzar/opensips-mi)
[![Code Climate](https://codeclimate.com/github/staskobzar/opensips-mi.png)](https://codeclimate.com/github/staskobzar/opensips-mi)
[![Gem Version](https://badge.fury.io/rb/opensips-mi.png)](http://badge.fury.io/rb/opensips-mi)
[![Coverage Status](https://coveralls.io/repos/staskobzar/opensips-mi/badge.png?branch=master)](https://coveralls.io/r/staskobzar/opensips-mi)

OpenSIPs management interface library.
This library supports following management interfaces OpenSIPs modules:

- mi_datagram
- mi_http
- mi_xmlrpc

> version 1+ supports only new MI jsonrpc used by opensips v3+.
> if you need older version with a plain text MI protocol install
> this library version 0.0.11

## Installation

Add this line to your application's Gemfile:

    gem 'opensips-mi'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install opensips-mi

## Connecting management interfaces

### Generic function to connect mi

Using generic function to connect management interface:

```ruby
require 'opensips/mi'
Opensips::MI.connect INTERFACE, PARAMS
```

Parameters:

_INTRFACE_ - interface name. One of the following:

- :datagram
- :http
- :xmlrpc

_PARAMS_ - connection parameters. Depends on interface. See below.

This function will raise exceptions if there are parameters' or environment errors.
Function returns instance of one of the following classes:

- Opensips::MI::Transport::Datagram
- Opensips::MI::Transport::HTTP
- Opensips::MI::Transport::Xmlrpc

### Datagram

```ruby
require 'opensips/mi'
opensips = Opensips::MI.connect :datagram,
                                :host => "199.188.10.100",
                                :port => 8809,
                                :timeout => 3
```

**Parameters hash:**

- host: Hostname or IP address of OpenSIPs server
- port: Datagram port. See mi_datagram module configuration parameter: `modparam("mi_datagram", "socket_name", "udp:192.168.2.133:8080")`
- timeout: Timeout in seconds to wait send/recv commands. Optional. Default 5 seconds.

### HTTP

```ruby
require 'opensips/mi'
opensips = Opensips::MI.connect :http,
                                :url => "http://192.168.0.1:8000/mi",
                                :timeout => 5
```

**Parameters hash:**

- url: HTTP MI url. Check OpenSIPS module mi_http for setting of IP, port and root path.
- timeout: Timeout in seconds to wait send/recv commands. Optional. Default 5 seconds.

### XMLRPC

```ruby
require 'opensips/mi'
opensips = Opensips::MI.connect :xmlrpc,
                                :url => "http://192.168.0.1/rpc",
                                :timeout => 5
```

**Parameters hash:**

- url: HTTP MI url. Check OpenSIPS module mi_http for setting of IP, port and root path.
- timeout: Timeout in seconds to wait send/recv commands. Optional. Default 5 seconds.

### Command function

Function "_command_" expects fifo command as a first argument, followed by command parameters.
Command parameters' description can be found in module documentation. For example:

```ruby
require 'opensips/mi'
opensips = Opensips::MI.connect :http,
                                :url => 'http://10.0.0.1/mi'

opensips.command('which')
opensips.command('get_statistics', 'dialog','tm')
```

### Command method interface

It is also possible to use command names as a method interface. Parameters can be passed as array or hash too.
Library will automatically fit it to defined protocol.

```ruby
require 'opensips/mi'
opensips = Opensips::MI.connect :datagram,
                                :host => "192.168.122.128",
                                :port => 8809

opensips.which
opensips.get_statistics('dialog','tm')
opensips.uptime
opensips.ul_show_contact('location', 'alice')
opensips.lb_status([1, 0])

# NOTE: named parametters can be used in hash.
# Make sure you are using correct names
opensips.log_level({level: 3, pid: 1})
```

### Response

Command function returns hash with root key `:result` and hash/array of respons data
or root key `:error` with message or more data.

Example of response of "uptime" command:

```ruby
{:result=>{
    "Now"=>"Wed Aug  9 19:41:28 2023",
    "Up since"=>"Wed Aug  9 18:44:18 2023",
    "Up time"=>"3430 [sec]"
    }
}
```

Error response example:

```ruby
{:error=>{
    "code"=>-32602,
    "message"=>"Invalid params",
    "data"=>"Bad PID"
    }
}
```

### Helper methods

## Dialog methods

Dialog methods are interface to `t_uac_dlg` function of OpenSIPs' _tm_ (transactions) module.

### Interface to t_uac_dlg function of transaction (tm) module

Very cool method from OpenSIPs. Can generate and send SIP request method to a destination UAC.
Example of usage:

- Send NOTIFY with special Event header to force restart SIP phone (equivalent of Asterisk's "sip notify peer")
- Send PUBLISH to trigger notification which changes device state
- Send REFER to transfer call
- etc., etc., etc.

**Headers**

Headers parameter "hf" is a hash of headers of format:

```
header-name => header-value
```

Example:

```
hf["From"] => "Alice Liddell <sip:alice@wanderland.com>;tag=843887163"
```

Special "nl" header with any value is used to input additional "\r\n". This is
useful, for example, in message-summary event to separate application body. This is
because t_uac_dlg expects body parameter as an xml only.

Thus, using multiple headers with same header-name is not possible.
However, it is possible to use multiple header-values comma separated (rfc3261, section 7.3.1):

```
hf["Route"] => "<sip:alice@atlanta.com>, <sip:bob@biloxi.com>"
```

Which is equivalent to:

```
Route: <sip:alice@atlanta.com>
Route: <sip:bob@biloxi.com>
```

If there are no To and From headers found, then exception ArgumentError is raised. Also when
body part is present, Content-Type and Content-length fields are required.

**Parameters**

- method: SIP request method (NOTIFY, PUBLISH etc)
- ruri: Request URI, ex.: sip:555@10.0.0.55:5060
- hf: Headers array. Additional headers will be added to request. At least "From" and "To" headers must be present. Headers' names are case-insensitive.
- nhop: Next hop SIP URI (OBP); use "." if no value.
- socket: Local socket to be used for sending the request; use "." if no value. Ex.: udp:10.130.8.21:5060
- body: (optional, may not be present) request body (if present, requires the "Content-Type" and "Content-length" headers)

**Example of usage**

```ruby
opensips.uac_dlg "NOTIFY", "sip:alice@127.0.0.1:5066",
                  {
                    "From"  => "<sip:alice@wanderland.com>;tag=8755a8d01a12f7e903a6f4ccaf393f04",
                    "To"    => "<sip:alice@wanderland.com>",
                    "Event" => "check-sync"
                  }
```

### NOTIFY check-sync like event

NOTIFY Events to restart phone, force configuration reload or report for some SIP IP phone models.
Wrapper to `uac_dlg` function.
The events list was taken from Asterisk configuration file (sip_notify.conf)
Note that SIP IP phones usually should be configured to accept special notify
event. For example, Polycom configuration option to enable special event would be:

```
  voIpProt.SIP.specialEvent.checkSync.alwaysReboot="1"
```

This function will generate To/From/Event headers. Will use random tag for From header.

_NOTE_: This function will not generate To header tag. This is not complying with
SIP protocol specification (rfc3265). NOTIFY must be part of a subscription
dialog. However, it works for the most of the SIP IP phone models.

**Parameters**

- uri: Valid client contact URI (sip:alice@10.0.0.100:5060). To get client URI use _ul_show_contact => contact_ function
- event: One of the events from EVENTNOTIFY constant hash
- hf: Header fields. Add To/From header fields here if you do not want them to be auto-generated. Header field example: `hf['To'] => '<sip:alice@wanderland.com>'`

**Example of usage**
Will reboot Polycom phone:

```ruby
opensips.event_notify 'sip:alice@127.0.0.1:5060', :polycom_check_cfg
```

**List of available events' keys:**

- :astra_check_cfg
- :aastra_xml
- :digium_check_cfg
- :linksys_cold_restart
- :linksys_warm_restart
- :polycom_check_cfg
- :sipura_check_cfg
- :sipura_get_report
- :snom_check_cfg
- :snom_reboot
- :cisco_check_cfg
- :avaya_check_cfg

### Presence MWI

Send message-summary NOTIFY Event to update phone voicemail status.

**Parameters**

- uri: Request URI (sip:alice@wanderland.com:5060). To get client URI use `ul_show_contact` function, _contact_ value
- vmaccount:Message Account value. Ex.: sip:\*97@asterisk.com
- new: Number of new messages. If more than 0 then Messages-Waiting header will be "yes". Set to 0 to clear phone MWI
- old: (optional) Old messages
- urg_new: (optional) New urgent messages
- urg_old: (optional) Old urgent messages

**Example of usage**

```ruby
opensips.mwi_update 'sip:alice@wanderland.com:5060', 'sip:*97@voicemail.pbx.com', 5
```

---

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
