# Copyright 2024 ACCESS-NRI and contributors. See the top-level COPYRIGHT file for details.
# SPDX-License-Identifier: Apache-2.0

# Restore the ACLs on an experiment's directory tree.
# The experiment folder gets the ACLs stored in the corresponding file under acl_files/
# All files and folders in the directory tree, owned by the person who runs the
# script, will have the following ACLs set:
# group:<project_w>:rwX
# default:group:<project_w>:rwX
# mask::rwX
#
# Any other existing ACL will not be modified.
#
# This script needs to be run by all the owners of files and directories if all
# files and directories need to be affected.
# 
# Input: 
# exp_name: name of the experience we want to restore the ACLs. Format: YYYY-MM-DD_<exp-title>
#

# Parameters:
wg_project=$(stat -c '%G' $0)
wg_root=/g/data/${wg_project}

# Inputs:
exp_name=$1
if [ -z ${exp_name} ]; then 
    echo "FAIL: You need to specify the experiment on the command line:"
    echo "./restore_acl_experiment.sh <exp_name>"
    exit 1
fi

exp_path=${wg_root}/experiments/${exp_name}
if [ ! -d ${exp_path} ]; then
    echo "FAIL: The experiment directory, ${exp_path}, does not exist."
    exit 1
fi

if [ $(stat -c '%U' ${exp_path}) == $USER ]; then
    # Restore ACLs on experiment directory
    echo Restore ACLs on the experiment directory $exp_name
    acl_filename=${wg_root}/admin/acl_files/${exp_name}
    setfacl --restore=${acl_filename}
fi

# ACLs to set on files and subdirectories
writer_acl=group:${wg_project}_w:rwX
default_writer_acl=default:${writer_acl}
mask_acl=mask::rwX

# Set ACLs on files owned by the person running the script
# We want to exclude ${exp_path} from the find results so we set mindepth=1.
my_files=$(find ${exp_path}  -mindepth 1 -user $USER)
if [ ! -z $my_files ]; then
    echo Restore ACLs in files and directories owned by $USER within the experiment
    setfacl -R -m ${writer_acl} -m ${default_writer_acl} -m ${mask_acl} ${my_files}
else
    echo No file or directory in the experiment owned by this user $USER
fi
