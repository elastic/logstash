OBJECTS=offline offline.o

default: offline

clean:
	rm -f $(OBJECTS)
offline: offline.o
	$(CC) -o $@ $<
