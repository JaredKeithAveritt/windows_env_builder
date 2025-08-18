#!/bin/bash

set main_dir=${PWD##*/}
envName=p311a-local
envDir=${main_dir}/envs/${envName}
packageDir=${envDir}-packages
mkdir ${packageDir}

exec > >(tee -i ${envName}.log) 2>&1

echo "## ############################################ ##"
echo "##  To see the progress, use:                   ##"
echo "##  tail -n +1 -f ${envName}.log                ##"
echo "## ############################################ ##"


# Create -load.bash script#
cat <<EOL > "${envDir}-load.bash"
#!/bin/bash

#module reset
#module load 
#echo 'module list'
source ${envDir}/bin/activate
#conda activate ${envDir}
#export LD_LIBRARY_PATH=

#-------------------lammps executable----------------------#
export lmp="${envDir}-packages/lammps-kokkos-mliap/build/lmp"

EOL


chmod +x ${envDir}-load.bash


conda create --name HIPNN-01 python=3.11
conda activate HIPNN-01
pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
pip3 install matplotlib
pip3 install h5py
pip3 install tqdm
pip3 install cython
pip3 install pandas
pip3 install scipy
pip3 install zarr
pip3 install ase
pip3 install RDkit
pip3 install ipykernel

echo " ## ############################################ ##"
echo " ##                Compiling FEFF                ##"
echo " ## ############################################ ##"


git clone https://github.com/pyscal/pyscal3.git
pushd pyscal3
#git checkout tags/3.2.6
push pyscal3/
pip3 install -r requirements.txt
pip3 install .
python setup.py build
popd
check pyscal3
pip show pyscal3

echo "## ############################################ ##"
echo "##     Installing Pyiron and its depdencies     ##"
echo "## ############################################ ##"

pip3 install pyiron-atomistics
pip3 install pyiron-base
pip3 install pyiron
pushd packages
git clone https://github.com/lanl/hippynn.git
pushd hippynn
#git checkout torch-load-weights_only-fix
#pip install -e ./
git fetch origin pull/163/head:pr-163
git checkout pr-163
pip install -e ./
popd

python -m ipykernel install --user --name=HIPNN-01



