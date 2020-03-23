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


pA=$(find $bidsdir'/'$SID'/ses-01/anat/'| grep _T1w.nii)
pAc='./anat/'$bids'_desc-occipitalcrop_T1w.nii'
pAcBias='./anat/'$bids'_desc-occipitalcropBet_T1w.nii.gz'
pFc='./func/'$bids'_desc-occipitalcropMeanBias_bold.nii'

pFc_in_Ac='./func/'$bids'_desc-occipitalcropMeanBias_space-ANATCROPPED_bold.nii'
pFc_in_A='./func/'$bids'_desc-occipitalcropMeanBias_space-ANAT_bold.nii'
pAc_in_A='./anat/'$bids'_desc-occipitalcrop_space-ANAT_T1w.nii'
pAc_in_Fc='./anat/'$bids'_desc-occipitalcrop_space-FUNCCROPPED_T1w.nii'
pA_in_Fc='./anat/'$bids'_desc-anatomical_space-FUNCCROPPED_T1w.nii'

#echo 'removing skull from anatomical cropped'
# Brain Extract Anatomical Cropped
bet $pAc $pAcBias -Z -f 0.2 -g 0

echo 'Aligning functional image to cropped anatomy...'

### croppedFunc to croppedAnat ###

flirt -in  $pFc \
      -ref $pAcBias \
      -out $pFc_in_Ac \
      -omat './coreg/'$bids'_from-FUNCCROPPED_to-ANATCROPPED.mat' -cost corratio  -dof 12 -interp trilinear #-searchrx -10 10 -searchry -10 10 -searchrz -10 10
gunzip -f $pFc_in_Ac'.gz'

### croppedAnat to croppedFun ###
# Create inverse transform
echo 'Generating Cropped Anat to Cropped Func'
convert_xfm -omat './coreg/'$bids'_from-ANATCROPPED_to-FUNCCROPPED.mat' -inverse './coreg/'$bids'_from-FUNCCROPPED_to-ANATCROPPED.mat'

# apply it
flirt -in  $pAc\
      -ref $pFc \
      -out $pAc_in_Fc \
      -init './coreg/'$bids'_from-ANATCROPPED_to-FUNCCROPPED.mat' -applyxfm
gunzip -f $pAc_in_Fc'.gz'

### AnatCropped to anat
flirt -in  $pAc \
      -ref $pA \
      -out $pAc_in_A \
      -omat './coreg/'$bids'_from-ANATCROPPED_to-ANAT.mat' -cost corratio  -dof 6 -interp trilinear -nosearch 


### Anat to croppedFun ###
echo 'Mapping Anat to Cropped Func'
convert_xfm -omat './coreg/'$bids'_from-ANAT_to-ANATCROPPED.mat' -inverse './coreg/'$bids'_from-ANATCROPPED_to-ANAT.mat'
convert_xfm -omat './coreg/'$bids'_from-ANAT_to-FUNCCROPPED.mat' -concat  './coreg/'$bids'_from-ANATCROPPED_to-FUNCCROPPED.mat' './coreg/'$bids'_from-ANAT_to-ANATCROPPED.mat'

flirt -in  $pA \
      -ref $pFc \
      -out $pA_in_Fc \
      -init './coreg/'$bids'_from-ANAT_to-FUNCCROPPED.mat' -applyxfm -paddingsize 50

gunzip -f $pA_in_Fc'.gz'


### croppedFun to Anat ###
convert_xfm -omat './coreg/'$bids'_from-FUNCCROPPED_to-ANAT.mat' -inverse './coreg/'$bids'_from-ANAT_to-FUNCCROPPED.mat'

echo 'Mapping cropped Func to Anat'
flirt -in  $pFc \
      -ref $pA \
      -out $pFc_in_A \
      -init './coreg/'$bids'_from-FUNCCROPPED_to-ANAT.mat' -applyxfm

gunzip -f $pFc_in_A'.gz'



done
echo 'Done!'
