#!/bin/bash

sudo parted -a optimal /dev/vdb mklabel gpt && sudo parted -a optimal /dev/vdb mkpart primary 0% 100% &&
sudo mkfs.ext4 /dev/vdb1 &&
sudo e2label /dev/vdb1 artifact-volume &&

sudo mkdir /media/volume &&
sudo mount /dev/vdb1 /media/volume &&

cd /media/volume &&
sudo mkdir artifact_store &&
sudo chown ubuntu artifact_store &&
sudo mkdir metrics_store &&
sudo chown ubuntu metrics_store

