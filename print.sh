#!/bin/bash
#
# Created to easily print out bank/cc statements at the end of the year (taxes)
#
# USAGE: ./print.sh "regexp_pattern" -- where pattern might be something like 
#  accountNumber_month.pdf (eg ./print.sh "accountNumber*.pdf"
#
# NOTES: set environment $PRINTER to the default printer prior to running

for f in $1
do
  echo "Printing: $f"
  lpr $f
done
