# Copyright 2024 ACCESS-NRI and contributors. See the top-level COPYRIGHT file for details.
# SPDX-License-Identifier: Apache-2.0

# Restore the ACLs on an experiment's directory tree.
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
# exp_name: name of the experience we want to modify the ACLs. Format: YYYY-MM-DD_<exp-title>
#

# Parameters:
wg_project=$(stat -c '%G' $0)
wg_root=/g/data/${wg_project}

# Inputs:
exp_name=$1
exp_path=${wg_root}/experiments/${exp_name}
if [ ! -d ${exp_path} ]; then
    echo "FAIL: The experiment directory, ${exp_path}, does not exist."
    exit 1
fi

# ACLs to set:
writer_acl=group:${wg_project}_w:rwX
default_writer_acl=default:${writer_acl}
mask_acl=mask::rwX

# Set ACLs
echo setfacl -R -m ${writer_acl} -m ${default_writer_acl} -m ${mask_acl} ${exp_path}/*