#!/bin/bash
set -e
# Align mean functional image to 3T nu anatomy (used for retinotopy) and calculate inverse XFM to be used to transform ROIs to mean functional space.
_tmp=${subjectlist:='S10'}
_tmp=${bidsdir:='SubjectData'}

_tmp=${task:='localizer'}

for SID in $subjectlist
do

cd $bidsdir/derivates/preprocessing/$SID/ses-01/

# Align fast corrected func to cropped anat:q!
bids=$SID'_ses-01'
echo $bids


pA48='./anat/'$bids'_acq-IrEpi_desc-angle48_bold.nii'
pAdiv='./anat/'$bids'_desc-IrEPImasked.nii'
pFc='./func/'$bids'_task-'$task'_desc-occipitalcropMeanBias_bold.nii'

pAdiv_in_pFc='./anat/'$bids'_desc-IrEPImasked_space-FUNCCROPPED.nii'

### pFc to pA48  ###

flirt -in  $pFc \
      -ref $pA48 \
      -omat './coreg/'$bids'_from-FUNCCROPPED_to-IREPI.mat' -cost normcorr -dof 6 -interp trilinear -searchrx -10 10 -searchry -10 10 -searchrz -10 10

### croppedAnat to croppedFun ###
# Create inverse transform
echo 'inverting'
convert_xfm -inverse './coreg/'$bids'_from-FUNCCROPPED_to-IREPI.mat' -omat './coreg/'$bids'_from-IREPI_to-FUNCCROPPED.mat' 
echo 'applying'
# apply it
flirt -in  $pAdiv\
      -ref $pFc \
      -out $pAdiv_in_pFc \
      -init './coreg/'$bids'_from-IREPI_to-FUNCCROPPED.mat' -applyxfm
gunzip -f $pAdiv_in_pFc'.gz'



done
echo 'Done!'