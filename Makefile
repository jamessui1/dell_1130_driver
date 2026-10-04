# Makefile for Dell 1130 Apple Silicon CUPS Driver

CXX       ?= clang++
CC        ?= clang
ARCH      ?= arm64
CXXFLAGS  ?= -O2 -g -Wall -arch $(ARCH) -Isrc/include -Isrc/jbigkit -DTHREADS=2 -DCACHESIZE=30
CFLAGS    ?= -O2 -g -Wall -arch $(ARCH) -Isrc/jbigkit
LDFLAGS   ?= -arch $(ARCH) -lcups -lpthread

BUILD_DIR ?= build
BIN_DIR   ?= bin
DIST_DIR  ?= dist

JBIG_SRCS = src/jbigkit/jbig85.c src/jbigkit/jbig_ar.c
JBIG_OBJS = $(patsubst src/jbigkit/%.c,$(BUILD_DIR)/jbigkit/%.o,$(JBIG_SRCS))

SPLIX_SRCS = src/algo0x0d.cpp src/algo0x0e.cpp src/algo0x11.cpp src/algo0x13.cpp \
             src/algo0x15.cpp src/algorithm.cpp src/band.cpp src/bandplane.cpp \
             src/cache.cpp src/colors.cpp src/compress.cpp src/core.cpp \
             src/document.cpp src/page.cpp src/ppdfile.cpp src/printer.cpp \
             src/rastertoqpdl.cpp src/rendering.cpp src/request.cpp src/semaphore.cpp \
             src/qpdl.cpp
SPLIX_OBJS = $(patsubst src/%.cpp,$(BUILD_DIR)/%.o,$(SPLIX_SRCS))

TARGET = $(BIN_DIR)/rastertoqpdl

all: $(TARGET)

$(TARGET): $(SPLIX_OBJS) $(JBIG_OBJS) | $(BIN_DIR)
	$(CXX) -o $@ $(SPLIX_OBJS) $(JBIG_OBJS) $(LDFLAGS)

$(BUILD_DIR)/%.o: src/%.cpp | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(BUILD_DIR)/jbigkit/%.o: src/jbigkit/%.c | $(BUILD_DIR)/jbigkit
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR) $(BUILD_DIR)/jbigkit $(BIN_DIR) $(DIST_DIR):
	mkdir -p $@

clean:
	rm -rf $(BUILD_DIR) $(BIN_DIR) $(DIST_DIR)

pkg: $(TARGET) | $(DIST_DIR)
	./scripts/build_pkg.sh

.PHONY: all clean pkg
