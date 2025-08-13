# Summary

The logstash data directory contains a queue containing:

 - ACK'd events (from a page that is not fully-ack'd)
 - raw CBOR-encoded events
 - deflate-compressed events with different compression ratios

# Pages
~~~
1	386	09303C2B	page.0	CBOR(known)
2	386	60213EC4	page.0	CBOR(known)
3	386	2B5A03B4	page.0	CBOR(known)
4	386	0C2A1D63	page.0	CBOR(known)
5	386	98BF5320	page.0	CBOR(known)
6	386	12961E51	page.0	CBOR(known)
7	386	B2B31EB8	page.0	CBOR(known)
8	386	6C52C3A1	page.0	CBOR(known)
9	386	A6F18E72	page.0	CBOR(known)
10	386	6AF34E8E	page.0	CBOR(known)
11	386	C8FD6460	page.1	CBOR(known)
12	386	17DBA0EC	page.1	CBOR(known)
13	386	E01C3729	page.1	CBOR(known)
14	386	23356C6B	page.1	CBOR(known)
15	386	285EC9F2	page.1	CBOR(known)
16	217	3B5E6A30	page.1	DEFLATE(fastest)
17	219	0BFB8BCF	page.1	DEFLATE(fastest)
18	220	559B446B	page.1	DEFLATE(fastest)
19	219	78FD2D81	page.1	DEFLATE(fastest)
20	219	B05865D0	page.1	DEFLATE(fastest)
21	221	8A0C1AE5	page.1	DEFLATE(fastest)
22	219	90C5CF52	page.1	DEFLATE(fastest)
23	220	49A5C28A	page.1	DEFLATE(fastest)
24	218	64D07E10	page.2	DEFLATE(fastest)
25	219	B94B9BA9	page.2	DEFLATE(fastest)
26	220	FE4A8839	page.2	DEFLATE(fastest)
27	219	D14C97AC	page.2	DEFLATE(fastest)
28	220	50E7C8DB	page.2	DEFLATE(fastest)
29	220	E92E09D6	page.2	DEFLATE(fastest)
30	219	8EFDC43D	page.2	DEFLATE(fastest)
31	386	9F8669A9	page.2	CBOR(known)
32	386	EAB6DC68	page.2	CBOR(known)
33	386	77BFC64A	page.2	CBOR(known)
34	386	C6DFF1C6	page.2	CBOR(known)
35	386	03348319	page.2	CBOR(known)
36	386	3C3AB761	page.2	CBOR(known)
37	386	AFAE06D9	page.3	CBOR(known)
38	386	DC9922A6	page.3	CBOR(known)
39	386	0782934F	page.3	CBOR(known)
40	386	4CAB5FB2	page.3	CBOR(known)
41	386	EC861477	page.3	CBOR(known)
42	386	F63FC4D4	page.3	CBOR(known)
43	386	0652619E	page.3	CBOR(known)
44	386	40544039	page.3	CBOR(known)
45	386	F90E7EB6	page.3	CBOR(known)
46	211	F72C0744	page.3	DEFLATE(default)
47	216	94DC834D	page.3	DEFLATE(default)
48	217	BFB763CE	page.4	DEFLATE(default)
49	215	2345D002	page.4	DEFLATE(default)
50	216	771433DE	page.4	DEFLATE(default)
51	216	404A6D24	page.4	DEFLATE(default)
52	217	2FA23916	page.4	DEFLATE(default)
53	215	B8799605	page.4	DEFLATE(default)
54	217	A05795C9	page.4	DEFLATE(default)
55	215	E5927940	page.4	DEFLATE(default)
56	386	903804C8	page.4	CBOR(known)
57	386	5C51DD15	page.4	CBOR(known)
58	386	70ECFC95	page.4	CBOR(known)
59	386	6AA9AEFE	page.4	CBOR(known)
60	386	141DE14B	page.4	CBOR(known)
61	386	8F22229A	page.5	CBOR(known)
62	386	CAC721B1	page.5	CBOR(known)
63	386	0AED21EB	page.5	CBOR(known)
64	386	6169B815	page.5	CBOR(known)
65	386	0E702D5E	page.5	CBOR(known)
66	214	5A2D04E9	page.5	DEFLATE(maximum)
67	386	FB39B2CF	page.5	CBOR(known)
68	214	BF504C7C	page.5	DEFLATE(maximum)
69	386	DF5B98B6	page.5	CBOR(known)
70	212	579EBE80	page.5	DEFLATE(fastest)
~~~

# CHECKPOINTS

~~~
# CHECKPOINT mixed-compression-queue-data-dir/queue/main/checkpoint.0
VERSION [            0001]: 1
PAGENUM [        00000000]: 0
1UNAKPG [        00000000]: 0
1UNAKSQ [0000000000000007]: 7
MINSEQN [0000000000000001]: 1
ELEMNTS [        0000000A]: 10
CHECKSM [        C3C52167]
# CHECKPOINT mixed-compression-queue-data-dir/queue/main/checkpoint.1
VERSION [            0001]: 1
PAGENUM [        00000001]: 1
1UNAKPG [        00000000]: 0
1UNAKSQ [000000000000000B]: 11
MINSEQN [000000000000000B]: 11
ELEMNTS [        0000000D]: 13
CHECKSM [        28208590]
# CHECKPOINT mixed-compression-queue-data-dir/queue/main/checkpoint.2
VERSION [            0001]: 1
PAGENUM [        00000002]: 2
1UNAKPG [        00000000]: 0
1UNAKSQ [0000000000000018]: 24
MINSEQN [0000000000000018]: 24
ELEMNTS [        0000000D]: 13
CHECKSM [        33401485]
# CHECKPOINT mixed-compression-queue-data-dir/queue/main/checkpoint.3
VERSION [            0001]: 1
PAGENUM [        00000003]: 3
1UNAKPG [        00000000]: 0
1UNAKSQ [0000000000000025]: 37
MINSEQN [0000000000000025]: 37
ELEMNTS [        0000000B]: 11
CHECKSM [        664CD0D8]
# CHECKPOINT mixed-compression-queue-data-dir/queue/main/checkpoint.4
VERSION [            0001]: 1
PAGENUM [        00000004]: 4
1UNAKPG [        00000000]: 0
1UNAKSQ [0000000000000030]: 48
MINSEQN [0000000000000030]: 48
ELEMNTS [        0000000D]: 13
CHECKSM [        4057847E]
# CHECKPOINT mixed-compression-queue-data-dir/queue/main/checkpoint.head
VERSION [            0001]: 1
PAGENUM [        00000005]: 5
1UNAKPG [        00000000]: 0
1UNAKSQ [000000000000003D]: 61
MINSEQN [000000000000003D]: 61
ELEMNTS [        0000000A]: 10
CHECKSM [        C404251C]
~~~