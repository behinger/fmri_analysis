#!/bin/bash
set -e
echo "starting freesurfer"

# Run freesurfer on T1
module unload freesurfer
module load freesurfer/6.0

# This allows for e.g. export subjectlist= ... previous to running the command
_tmp=${SID:='S9'}
_tmp=${bidsdir:='SubjectData'}


T1Path=$(find $bidsdir'/'$SID'/ses-01/anat/'| grep _T1w.nii)
echo 'looking for this anatomical image:' $T1Path

export SUBJECTS_DIR=$bidsdir/derivates/freesurfer/$SID/
# ses-01 is done in recon-all call, no Idea how to do better sorry!
mkdir -p $SUBJECTS_DIR
recon-all -i $T1Path -subjid 'ses-01' -cw256 -all -hires

# incase you need to continue a reconstruction because it stopped
#recon-all -make all  -subjid 'ses-01' -cw256 -all -hires

