#!/usr/bin/make -f
# -*- mode: makefile-gmake; coding: utf-8 -*-
#
# SPDX-FileCopyrightText: 🄯 2020 Peter J. Mello <admin@petermello.net>
#
# SPDX-License-Identifier: MPL-2.0

BASH_PATH ::= $(shell which bash)
SHELL     ::= $(shell realpath -Leq $(BASH_PATH) || echo /bin/sh)
UNAME     ::= $(shell uname)


all: eol install


eol:
ifeq ($(UNAME),Linux)
	CONVERT_TO_LF ::= $(shell dos2unix -ic $(CURDIR)/vivaldi/hooks/*.js)
	dos2unix -c ascii $(CONVERT_TO_LF)
endif

install:


.PHONY: all eol install
