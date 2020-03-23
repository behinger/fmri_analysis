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
p3TA='./anat/'$bids'_desc-occipitalcrop_T1w.nii'
pAcBias='./anat/'$bids'_desc-occipitalcropBet_T1w.nii.gz'
pFc='./func/'$bids'_desc-occipitalcropMeanBias_bold.nii'

pFc_in_Ac='./func/'$bids'_desc-occipitalcropMeanBias_space-ANATCROPPED_bold.nii'
pFc_in_A='./func/'$bids'_desc-occipitalcropMeanBias_space-ANAT_bold.nii'
pAc_in_A='./anat/'$bids'_desc-occipitalcrop_space-ANAT_T1w.nii'
pAc_in_Fc='./anat/'$bids'_desc-occipitalcrop_space-FUNCCROPPED_T1w.nii'
pA_in_Fc='./anat/'$bids'_desc-anatomical_space-FUNCCROPPED_T1w.nii'

### 3T to croppedAnat ###
pAc_in_A='./anat/'$bids'_desc-occipitalcrop_space-ANAT_T1w.nii'

convert_xfm -omat './coreg/'$bids'_from-3TANAT_to-FUNCCROPPED.mat' -concat  './coreg/'$bids'_from-ANAT_to-FUNCCROPPED.mat' './coreg/'$bids'_from-3TANAT_to-ANAT.mat'



done
echo 'Done!'
