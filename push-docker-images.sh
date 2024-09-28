#!/bin/bash
########### Script to push all docker images on the node to your private docker registry
## you should edit the REG variable with your docker registry
## Exit codes 
##    1: RESERVED
##    2: means Invalid Credentials
##    3: means crictl error to list images
##    4: means error in tagging the image
##    5: means error in pushing the image to the registry


#Get All Images on the node in array

#Define your private docker registry
REG=docker.tony.local
USR="admin"
PASS="admin"


#Login to your registry
podman login ${REG} -u ${USR} -p $PASS  || { echo " Failed to Login to ${REG} " ; exit 2; }

#Get All Images on the node in array
IMAGES=$(sudo podman images --noheading --format "{{.Repository}}:{{.Tag}}"  || { echo 'Failed to get images' ; exit 3; })

#For Loop on all images 
for i in $IMAGES;
do

#skip any tagged images with <none>
  TAG=$( echo ${i##*:} )
  if [ "${TAG}" = "<none>" ] ; then
     continue ;
  fi

#Tag images with the new private registry
  OLDREG=$( echo ${i%%/*} )
  NEWIMG=($( echo ${i} | sed -e "s/${OLDREG}/${REG}/g" ))
  sudo podman tag ${i} ${NEWIMG} || { echo "Failed to Tag image ${i}" ; exit 4; }

#pushing the image to the new private registry
  echo "Pushing image ${i} as ${NEWIMG}"
  sudo -E podman push ${NEWIMG} || { echo "Failed to Push image ${NEWIMG} " ; exit 5; }
  echo "${NEWIMG} is successfully Pushed "

done

exit 0
