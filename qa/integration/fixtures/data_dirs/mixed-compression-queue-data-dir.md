# Summary

The logstash data directory contains a queue for pipeline `main` containing:

 - ACK'd events (from a page that is not fully-ack'd)
 - raw CBOR-encoded events
 - zstd-compressed events with different compression goals

# Pages
~~~
1	258	821AACAC	page.0	CBOR(stringref)
2	343	3BE717E8	page.0	CBOR(stringref)
3	332	3439807A	page.0	CBOR(stringref)
4	258	C04209D4	page.0	CBOR(stringref)
5	343	3DFB08E8	page.0	CBOR(stringref)
6	332	44B0315D	page.0	CBOR(stringref)
7	258	90D25985	page.0	CBOR(stringref)
8	343	DAFD5712	page.0	CBOR(stringref)
9	332	AB6A81DF	page.0	CBOR(stringref)
10	258	157EA7A6	page.0	CBOR(stringref)
11	258	02C0F7A2	page.0	CBOR(stringref)
12	343	0005E8A8	page.0	CBOR(stringref)
13	332	C2DA39EA	page.1	CBOR(stringref)
14	258	377D623C	page.1	CBOR(stringref)
15	343	9F76657C	page.1	CBOR(stringref)
16	332	50B51A98	page.1	CBOR(stringref)
17	258	827848CC	page.1	CBOR(stringref)
18	343	8325D121	page.1	CBOR(stringref)
19	332	E1A1378B	page.1	CBOR(stringref)
20	258	1BBDAA1A	page.1	CBOR(stringref)
21	254	19C85DF6	page.1	ZSTD(258)
22	317	AD5DC7CC	page.1	ZSTD(343)
23	325	BB8CE48C	page.1	ZSTD(332)
24	254	27D38856	page.1	ZSTD(258)
25	317	67A7D2F3	page.2	ZSTD(343)
26	325	888AF9B2	page.2	ZSTD(332)
27	254	CAA2FDE3	page.2	ZSTD(258)
28	317	2985771A	page.2	ZSTD(343)
29	325	89197F51	page.2	ZSTD(332)
30	254	A9E292EE	page.2	ZSTD(258)
31	258	243FC2C1	page.2	CBOR(stringref)
32	219	2E2E0BDF	page.2	ZSTD(258)
33	261	5ED17F40	page.2	ZSTD(343)
34	280	86BA1E80	page.2	ZSTD(332)
35	218	6A7B8C41	page.2	ZSTD(258)
36	262	08E69C4C	page.2	ZSTD(343)
37	277	CD32DEBD	page.2	ZSTD(332)
38	218	43101D61	page.2	ZSTD(258)
39	261	A22033DE	page.3	ZSTD(343)
40	279	8F1FE0FA	page.3	ZSTD(332)
41	218	FF56D05C	page.3	ZSTD(258)
42	258	7077981D	page.3	CBOR(stringref)
43	343	7748A127	page.3	CBOR(stringref)
44	332	B4A0C82C	page.3	CBOR(stringref)
45	258	96FB0308	page.3	CBOR(stringref)
46	343	40B77975	page.3	CBOR(stringref)
47	332	D5571FDC	page.3	CBOR(stringref)
48	258	BF3FC517	page.3	CBOR(stringref)
49	343	1BC62146	page.3	CBOR(stringref)
50	332	418FD829	page.3	CBOR(stringref)
51	258	DB40747E	page.3	CBOR(stringref)
52	224	7629AF30	page.4	ZSTD(258)
53	264	D450FC21	page.4	ZSTD(343)
54	284	43F91F18	page.4	ZSTD(332)
55	224	C61DB7BA	page.4	ZSTD(258)
56	264	F9547DBC	page.4	ZSTD(343)
57	281	3DBB71E5	page.4	ZSTD(332)
58	225	8ACDB484	page.4	ZSTD(258)
59	264	8256E2D2	page.4	ZSTD(343)
60	281	D76156A2	page.4	ZSTD(332)
61	225	EDC6147B	page.4	ZSTD(258)
62	258	D3AB1EF4	page.4	CBOR(stringref)
63	220	4851D677	page.4	ZSTD(258)
64	225	C8DCE54A	page.4	ZSTD(258)
65	251	3D1E0F5F	page.4	ZSTD(258)
66	258	1C5637CB	page.4	CBOR(stringref)
67	343	09AE6714	page.5	CBOR(stringref)
68	332	4A97AC77	page.5	CBOR(stringref)
69	254	D1E43C69	page.5	ZSTD(258)
70	317	B6A2361D	page.5	ZSTD(343)
71	325	A44CE35F	page.5	ZSTD(332)
72	225	B69C7923	page.5	ZSTD(258)
73	265	FEBC2D45	page.5	ZSTD(343)
74	286	5FA5C389	page.5	ZSTD(332)
75	221	C36048C0	page.5	ZSTD(258)
76	262	E988C90B	page.5	ZSTD(343)
77	280	6C98308C	page.5	ZSTD(332)
~~~

# CHECKPOINTS

~~~
# CHECKPOINT mixed-compression-queue-data-dir/queue/main/checkpoint.0
VERSION [            0001]: 1
PAGENUM [        00000000]: 0
1UNAKPG [        00000000]: 0
1UNAKSQ [0000000000000005]: 5
MINSEQN [0000000000000001]: 1
ELEMNTS [        0000000C]: 12
CHECKSM [        4AFA3119]
# CHECKPOINT mixed-compression-queue-data-dir/queue/main/checkpoint.1
VERSION [            0001]: 1
PAGENUM [        00000001]: 1
1UNAKPG [        00000000]: 0
1UNAKSQ [000000000000000D]: 13
MINSEQN [000000000000000D]: 13
ELEMNTS [        0000000C]: 12
CHECKSM [        70829F7B]
# CHECKPOINT mixed-compression-queue-data-dir/queue/main/checkpoint.2
VERSION [            0001]: 1
PAGENUM [        00000002]: 2
1UNAKPG [        00000000]: 0
1UNAKSQ [0000000000000019]: 25
MINSEQN [0000000000000019]: 25
ELEMNTS [        0000000E]: 14
CHECKSM [        4ABFB50A]
# CHECKPOINT mixed-compression-queue-data-dir/queue/main/checkpoint.3
VERSION [            0001]: 1
PAGENUM [        00000003]: 3
1UNAKPG [        00000000]: 0
1UNAKSQ [0000000000000027]: 39
MINSEQN [0000000000000027]: 39
ELEMNTS [        0000000D]: 13
CHECKSM [        95B393C6]
# CHECKPOINT mixed-compression-queue-data-dir/queue/main/checkpoint.4
VERSION [            0001]: 1
PAGENUM [        00000004]: 4
1UNAKPG [        00000000]: 0
1UNAKSQ [0000000000000034]: 52
MINSEQN [0000000000000034]: 52
ELEMNTS [        0000000F]: 15
CHECKSM [        9B602904]
# CHECKPOINT mixed-compression-queue-data-dir/queue/main/checkpoint.head
VERSION [            0001]: 1
PAGENUM [        00000005]: 5
1UNAKPG [        00000000]: 0
1UNAKSQ [0000000000000043]: 67
MINSEQN [0000000000000043]: 67
ELEMNTS [        0000000B]: 11
CHECKSM [        B5F33B10]
~~~