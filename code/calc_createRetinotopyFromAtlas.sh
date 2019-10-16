#!/bin/bash
set -e

_tmp=${subjectlist:='S10'}
_tmp=${bidsdir:='SubjectData'}
_tmp=${task:='sustained'}
# activate venv

module load anaconda3 # donders infrastructure
#source activate $bidsdir/../../../venv_sequence
#source activate /project/3018028.04/benehi/$task/venv_sequence

source activate fmri

# for old venv
# source $bidsdir/../../../venv/bin/activate



for SID in $subjectlist
do

cd $bidsdir/derivates/freesurfer/$SID/ses-01/


# named benson14 but is actually benson17 ...
export SUBJECTS_DIR=$bidsdir/derivates/freesurfer/$SID/
python3 -m neuropythy benson14_retinotopy --verbose ses-01

mkdir -p $bidsdir/derivates/preprocessing/$SID/ses-01/label

mri_convert --reslice_like mri/rawavg.mgz mri/benson14_varea.mgz '../../../preprocessing/'$SID'/ses-01/label/'$SID'_ses-01_desc-varea_space-ANAT_label.nii' --resample_type nearest -ns 1 
mri_convert --reslice_like mri/rawavg.mgz mri/benson14_angle.mgz '../../../preprocessing/'$SID'/ses-01/label/'$SID'_ses-01_desc-angle_space-ANAT_label.nii' --resample_type nearest -ns 1
mri_convert --reslice_like mri/rawavg.mgz mri/benson14_eccen.mgz '../../../preprocessing/'$SID'/ses-01/label/'$SID'_ses-01_desc-eccen_space-ANAT_label.nii' --resample_type nearest -ns 1
mri_convert --reslice_like mri/rawavg.mgz mri/benson14_sigma.mgz '../../../preprocessing/'$SID'/ses-01/label/'$SID'_ses-01_desc-sigma_space-ANAT_label.nii' --resample_type nearest -ns 1


done
