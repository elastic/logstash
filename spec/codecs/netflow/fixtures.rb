# encoding: utf-8

# NetFlow v9 Test Data Based on http://www.cisco.com/en/US/technologies/tk648/tk362/technologies_white_paper09186a00800a3db9.html
def netflow_v9_header(options = {:record_count => 1})
  count = [options[:record_count]].pack("n").unpack("cc")
  [
    0x00, 0x09, # Version: 9
    count,      # Count: Number of FlowSet Records in this packet
    0x00, 0x4C, 0xAF, 0x8E, # System Time: 01:23:45.678 since boot
    0x53, 0x3E, 0x09, 0xB1, # UNIX Time: 2014-04-04T01:24:01Z
    0x00, 0x00, 0xBE, 0xEF, # Sequence Number: 48879
    0x00, 0x00, 0x00, 0x00, # Source ID: 0
  ].flatten.pack('C*')
end

def netflow_v9_template_flowset_simple
  [
    0x00, 0x00, # FlowSet ID = 0 (NetFlow v9 Template)
    0x00, 0x24, # Length: 36 bytes (including the ID and Length)
    0x01, 0x41, # Template ID: 321 (must be < 255)
    0x00, 0x07, # Field Count: 7 Fields
    # Field 1
    0x00, 0x01, # IN_BYTES
    0x00, 0x04, # Length: 4 bytes
    # Field 2
    0x00, 0x02, # IN_PKTS
    0x00, 0x04, # Length: 4 bytes
    # Field 3
    0x00, 0x04, # PROTOCOL
    0x00, 0x01, # Length: 1 bytes
    # Field 4
    0x00, 0x07, # L4_SRC_PORT
    0x00, 0x02, # Length: 2 bytes
    # Field 5
    0x00, 0x08, # IPV4_SRC_ADDR
    0x00, 0x04, # Length: 4 bytes
    # Field 6
    0x00, 0x0B, # L4_DST_PORT
    0x00, 0x02, # Length: 2 bytes
    # Field 7
    0x00, 0x0C, # IPV4_DST_ADDR
    0x00, 0x04, # Length: 4 bytes
  ].flatten.pack('C*')
end

def netflow_v9_data_flowset_simple(options = {:record_count => 1})
  payload = [
    # Field 1
    0x00, 0x01, 0xF4, 0x00, # IN_BYTES: 128000
    # Field 2
    0x00, 0x00, 0x04, 0x00, # IN_PKTS: 1024
    # Field 3
    0x11, # PROTOCOL: 17 (UDP)
    # Field 4
    0x30, 0x39, # L4_SRC_PORT: 12345
    # Field 5
    0x0A, 0x01, 0x02, 0x03, # IPV4_SRC_ADDR: 10.1.2.3
    # Field 6
    0x15, 0xB7, # L4_DST_PORT: 5559
    # Field 7
    0x0A, 0x04, 0x05, 0x06, # IPV4_DST_ADDR: 10.4.5.6
  ] * options[:record_count]
  length = payload.length + 4
  # Padding to 32-bit boundary
  unless length % 4 == 0
    padding = 4 - length % 4
    payload << [0x00] * padding
    length += padding
  end
  [
    0x01, 0x41, # FlowSet ID = 321 (data formatted according to template 321)
    [length].pack("n").unpack("cc"), # Length (incl. ID, Length, and Padding)
    payload
  ].flatten.pack('C*')
end

def netflow_v9_template_flowset_complex
  [
    0x00, 0x00, # FlowSet ID = 0 (NetFlow v9 Template)
    0x00, 0x30, # Length: 48 bytes (including the ID and Length)
    0x01, 0xC8, # Template ID: 456 (must be < 255)
    0x00, 0x0A, # Field Count: 10 Fields
    # Field 1
    0x00, 0x06, # TCP_FLAGS
    0x00, 0x01, # Length: 1 byte
    # Field 2
    0x00, 0x08, # IPV4_SRC_ADDR
    0x00, 0x04, # Length: 4 bytes
    # Field 3
    0x00, 0x0A, # INPUT_SNMP
    0x00, 0x02, # Length: 2 bytes
    # Field 4
    0x00, 0x0C, # IPV4_DST_ADDR
    0x00, 0x04, # Length: 4 bytes
    # Field 5
    0x00, 0x0E, # OUTPUT_SNMP
    0x00, 0x02, # Length: 2 bytes
    # Field 6
    0x00, 0x15, # LAST_SWITCHED
    0x00, 0x04, # Length: 4 bytes
    # Field 7
    0x00, 0x16, # FIRST_SWITCHED
    0x00, 0x04, # Length: 4 bytes
    # Field 8
    0x00, 0x52, # IF_NAME
    0x00, 0x10, # Length: 16 bytes
    # Field 9
    0x00, 0x53, # IF_DESC
    0x00, 0x20, # Length: 32 bytes
    # Field 10
    0x00, 0x59, # FORWARDING_STATUS
    0x00, 0x01, # Length: 1 byte
  ].flatten.pack('C*')
end

def netflow_v9_data_flowset_complex
  [
    0x01, 0xC8, # FlowSet ID = 456 (data formatted according to template 456)
    0x00, 0x4C, # Length: 76 (incl. ID, Length, and Padding)
    # Field 1: TCP_FLAGS
    0x13, # FIN (0x01) | SYN(0x02) | ACK(0x10)
    # Field 2: IPV4_SRC_ADDR
    0x0A, 0x01, 0x02, 0x03, # IPV4_SRC_ADDR: 10.1.2.3
    # Field 3: INPUT_SNMP
    0x00, 0x01, # ifIndex = 1
    # Field 4: IPV4_DST_ADDR
    0x0A, 0x04, 0x05, 0x06, # IPV4_SRC_ADDR: 10.4.5.6
    # Field 5: OUTPUT_SNMP
    0x00, 0x02, # ifIndex = 2
    # Field 6: LAST_SWITCHED
    0x00, 0x4C, 0x9C, 0x06, # System Time: 01:23:40.678 since boot
    # Field 7: FIRST_SWITCHED
    0x00, 0x4C, 0x88, 0x7E, # System Time: 01:23:35.678 since boot
    # Field 8: IF_NAME
    "FE1/0".ljust(16, "\0").bytes, # (null-padded to 16 bytes)
    # Field 9: IF_DESC
    "FastEthernet 1/0".ljust(32, "\0").bytes, # (null-padded to 32 bytes)
    # Field 10: FORWARDING_STATUS
    0x42, # Forwarded not Fragmented (Reason Code 66)
    # Padding to 32-bit boundary
    0x00, 0x00
  ].flatten.pack('C*')
end

