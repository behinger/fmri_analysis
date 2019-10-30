#!/bin/bash
set -e

_tmp=${subjectlist:='S10'}
_tmp=${bidsdir:='SubjectData'}

_tmp=${task:='localizer'}


for SID in $subjectlist
do

cd $bidsdir/derivates/preprocessing/$SID/ses-01/
echo 'Moving Visual Labels to Funccropped'

#/project/3018012.20/data/pilot/bids/derivates/preprocessing/sub-91/ses-01/


#ref='./func/'$SID'_ses-01_task-'$task'_acq-rsep3d08mmipat4x2partialbrain_desc-occipitalcropMeanBias_bold.nii'
ref='./func/'$SID'_ses-01_task-'$task'_desc-occipitalcropMeanBias_bold.nii'
inToRef='./coreg/'$SID'_ses-01_from-ANAT_to-FUNCCROPPED.mat'


for label in 'varea' 'eccen' 'sigma' 'angle'
do

in='label/'$SID'_ses-01_desc-'$label'_space-ANAT_label.nii'
out='label/'$SID'_ses-01_desc-'$label'_space-FUNCCROPPED_label.nii.gz'

flirt -in $in -applyxfm -init $inToRef -out $out -paddingsize 0.0 -interp nearestneighbour  -ref $ref

gunzip -f $out

done


done