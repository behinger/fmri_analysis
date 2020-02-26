#!/bin/bash
set -e
# Align mean functional image to 3T nu anatomy (used for retinotopy) and calculate inverse XFM to be used to transform ROIs to mean functional space.
_tmp=${subjectlist:='S10'}
_tmp=${bidsdir:='SubjectData'}
_tmp=${TASK:='WM'}


for SID in $subjectlist
do

cd $bidsdir/derivates/preprocessing/$SID/ses-01/

# Align fast corrected func to cropped anat:q!
bids=$SID'_ses-01'
echo $bids
extradata=$bidsdir'/'$SID'/ses-01/extra_data/'
angle8=$extradata'/'$SID'_ses-mri01_acq-3D08WBfatflipAngle8_dir-COL_run-1_echo-1.nii'
angle48=$extradata'/'$SID'_ses-mri01_acq-3D08WBfatflipAngle48_dir-COL_run-1_echo-1.nii'

angle8_tmp='./anat/'$bids'_acq-IrEpi_desc-angle8_bold.nii'
angle48_tmp='./anat/'$bids'_acq-IrEpi_desc-angle48_bold.nii'

echo $angle8
echo $angle48
echo $angle8_tmp
echo $angle48_tmp

irepi='./anat/'$bids'_desc-IrEPI.nii'
echo $irepi

fslmaths $angle8  -Tmean $angle8_tmp
fslmaths $angle48 -Tmean $angle48_tmp

fslmaths $angle48_tmp -div $angle8_tmp $irepi

gunzip -f './anat/*.nii.gz'
done



