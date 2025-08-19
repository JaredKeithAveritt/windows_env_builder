#!/bin/bash

main_dir=${PWD}
envName=p311a-local
envDir=${main_dir}/envs/${envName}
packageDir=${envDir}-packages
mkdir envs
mkdir ${packageDir}
cd envs

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
export lmp="${envDir}-packages/lammps/build/lmp"

EOL


chmod +x ${envDir}-load.bash

wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
# do not allow conda init!!!!

source ~/miniconda3/etc/profile.d/conda.sh
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r

sudo apt install g++
sudo apt install gfortran
sudo apt install cmake
sudo apt update
sudo apt install -y mpich libmpich-dev
sudo apt install -y nvidia-cuda-toolkit
sudo apt update
sudo apt install -y ffmpeg pkg-config

conda create --prefix $envDir python=3.11 -y
conda activate $envDir
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
pip3 install numpy

echo " ## ############################################ ##"
echo " ##                Compiling FEFF                ##"
echo " ## ############################################ ##"

git clone https://github.com/pyscal/pyscal3.git
pushd pyscal3
#git checkout tags/3.2.6
pip3 install -r requirements.txt
pip3 install .
python setup.py build
popd
#check pyscal3
pip show pyscal3


mkdir FEFF
pushd ${packageDir}/PythonPath/FEFF
tar -xzf feff85L.tgz
pushd feff85L
pushd MONO
rm Compile

cat > Compile <<'EOF'
#!/bin/bash
set -euo pipefail

# settings
F77=gfortran
flags='-O2 -ffree-line-length-none -static -std=legacy -fmax-errors=5 -w'

# compile
$F77 $flags -o opconsat  opconsat_tot.f90
$F77 $flags -o eps2exc   eps2exc_tot.f
$F77 $flags -o feff85L   feff85L.f
EOF

chmod +x Compile
./Compile

popd
popd
popd

echo "## ############################################ ##"
echo "##     Installing Pyiron and its depdencies     ##"
echo "## ############################################ ##"

pip3 install pyiron-atomistics
pip3 install pyiron-base
pip3 install pyiron


cd $packageDir

git clone https://github.com/JaredKeithAveritt/hippynn
pushd hippynn
pip install -e ./
popd


git clone https://github.com/JaredKeithAveritt/lammps-UQ-MLIAP-Interface/ lammps
pushd lammps
mkdir build
pushd build

. build_lammps_local.sh

make -j 8
make install-python


python -m ipykernel install --user --name=HIPNN-01



