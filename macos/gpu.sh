#!/bin/sh
ioreg -l | grep \"PerformanceStatistics\" | cut -d '{' -f 2 | tr '|' ',' | tr -d '}' | tr ',' '\n' | grep 'Temp\|Fan\|Power\|Clock\|Utilization'
