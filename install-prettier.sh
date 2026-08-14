#!/bin/bash

command -v prettier >/dev/null || mise use -g prettier@3.9.6
command -v prettierd >/dev/null || mise use -g npm:@fsouza/prettierd@0.29.0
