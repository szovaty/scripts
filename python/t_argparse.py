#!/usr/bin/python

import argparse

foo = ['-f', '--foo', '--foo2']
foo.append('-x')
act='store'
help_s=''

print foo

parser = argparse.ArgumentParser()
parser.add_argument('-t','--test')
parser.add_argument(*foo,action=act,help=help_s)

args = parser.parse_args()

print args
