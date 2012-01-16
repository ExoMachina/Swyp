#!/bin/bash

echo "installing libSwyp documentation-- 'appledoc' must be installed <see github>"

appledoc -o ./tempdocs \
--project-name libSwÿp \
--project-company "Swÿp" \
--company-id com.swyp  \
./libSwyp/
