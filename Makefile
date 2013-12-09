
NAGAQUEEN_DIR := ../nagaqueen
NAGAQUEEN_LEG := $(NAGAQUEEN_DIR)/grammar/nagaqueen.leg
NAGAQUEEN_C := source/oc/frontend/nagaqueen/NagaQueen.c
NAGAQUEEN_LIB := libs/libnagaqueen.a

.PHONY: oc clean

all: $(NAGAQUEEN_LIB) oc

oc:
	@echo "Compiling oc..."
	rock -v

clean:
	rock -x

$(NAGAQUEEN_LIB): $(NAGAQUEEN_C)
	@echo "Compiling nagaqueen..."
	mkdir -p libs
	gcc -c -O3 -std=gnu99 -w -o nagaqueen.o $^
	ar rs $@ nagaqueen.o
	rm -f nagaqueen.o

$(NAGAQUEEN_C): $(NAGAQUEEN_LEG)
	greg $^ > $@

