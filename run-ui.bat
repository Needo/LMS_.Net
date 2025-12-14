@echo off
echo Starting LMS UI...
cd LMSUI
set NODE_OPTIONS=--openssl-legacy-provider
ng serve --open --port 4200
