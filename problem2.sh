#!/bin/bash

# Capture data into temp file
curl -L -s 'http://finance.yahoo.com/d/quotes.csv?s=AAPL+CSCO+GE+VZ+MSFT&f=spc1' > data/problem2_temp.csv
cat data/problem2_temp.csv|tr -d '"'| sed -e 's|,|\ |g' >data/problem2.output
# Uncomment next line to view temp file before cleanup
rm data/problem2_temp.csv

