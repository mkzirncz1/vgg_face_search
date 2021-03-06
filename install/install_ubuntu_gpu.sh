#!/bin/bash

# - This script is to be run in a clean Ubuntu 14.04 LTS machine, by a sudoer user.
# - VGG_FACE_SRC_FOLDER should not exist
# - All python dependencies are installed in a python virtual environment to avoid conflicts with pre-installed python packages
# - Make sure the NVIDIA CUDA Toolkit is installed and that 'nvcc' is reachable. See the commented environment variable
#   definitions below. The same variables should be available when actually running the service, and should be added to:
#     * $VGG_FACE_SRC_FOLDER/service/start_backend_service.sh
#     * $VGG_FACE_SRC_FOLDER/pipeline/start_pipeline.sh
# - This script does not include the use of cuDNN. If you want to use it, you will need to change the Makefile.config of
#   caffe-fast-rcnn and recompile it.

#export PATH=/usr/local/cuda/bin:$PATH
#export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64:/usr/local/lib
VGG_FACE_INSTALL_FOLDER="$HOME"
VGG_FACE_SRC_FOLDER="$VGG_FACE_INSTALL_FOLDER/vgg_face_search"
VGG_FACE_DEPENDENCIES_FOLDER="$VGG_FACE_SRC_FOLDER/dependencies"

# update repositories
sudo apt-get update

# Caffe  dependencies
sudo apt-get install -y cmake
sudo apt-get install -y pkg-config
sudo apt-get install -y libgoogle-glog-dev
sudo apt-get install -y libhdf5-serial-dev
sudo apt-get install -y liblmdb-dev
sudo apt-get install -y libleveldb-dev
sudo apt-get install -y libprotobuf-dev
sudo apt-get install -y protobuf-compiler
sudo apt-get install -y libopencv-dev
sudo apt-get install -y libatlas-base-dev
sudo apt-get install -y libsnappy-dev
sudo apt-get install -y libgflags-dev
sudo apt-get install -y --no-install-recommends libboost-all-dev
sudo apt-get install -y wget unzip

# pip and other python dependencies
sudo apt-get install -y python-pip
sudo apt-get install -y python-dev
sudo apt-get install -y gfortran
sudo apt-get install -y libz-dev libjpeg-dev libfreetype6-dev
sudo apt-get install -y python-opencv

# setup folders and download git repo
cd $VGG_FACE_INSTALL_FOLDER
wget https://gitlab.com/vgg/vgg_face_search/-/archive/master/vgg_face_search-master.zip -O /tmp/vgg_face_search.zip
unzip /tmp/vgg_face_search.zip -d $VGG_FACE_INSTALL_FOLDER/
mv $VGG_FACE_INSTALL_FOLDER/vgg_face_search*  $VGG_FACE_SRC_FOLDER
sed -i 's/CUDA_ENABLED = False/CUDA_ENABLED = True/g' $VGG_FACE_SRC_FOLDER/service/settings.py
sed -i 's/resnet50_256/senet50_256/g' $VGG_FACE_SRC_FOLDER/service/settings.py

# create virtual environment and install python dependencies
cd $VGG_FACE_SRC_FOLDER
sudo pip install virtualenv
virtualenv .
source ./bin/activate
pip install simplejson==3.8.2
pip install Pillow==2.3.0
pip install numpy==1.13.3
pip install Cython==0.27.3
pip install scipy==0.18.1
pip install matplotlib==2.1.0
pip install scikit-image==0.13.1
pip install protobuf==3.0.0
pip install easydict==1.7
pip install pyyaml==3.12
pip install dill==0.2.8.2

# install face-py-faster-rcnn
wget https://github.com/playerkk/face-py-faster-rcnn/archive/9d8c143e0ff214a1dcc6ec5650fb5045f3002c2c.zip -P /tmp
unzip /tmp/9d8c143e0ff214a1dcc6ec5650fb5045f3002c2c.zip -d $VGG_FACE_DEPENDENCIES_FOLDER/
mv $VGG_FACE_DEPENDENCIES_FOLDER/face-py-faster-rcnn-* $VGG_FACE_DEPENDENCIES_FOLDER/face-py-faster-rcnn
wget https://github.com/rbgirshick/caffe-fast-rcnn/archive/0dcd397b29507b8314e252e850518c5695efbb83.zip -P /tmp
unzip /tmp/0dcd397b29507b8314e252e850518c5695efbb83.zip -d $VGG_FACE_DEPENDENCIES_FOLDER/face-py-faster-rcnn
rm -r $VGG_FACE_DEPENDENCIES_FOLDER/face-py-faster-rcnn/caffe-fast-rcnn
mv $VGG_FACE_DEPENDENCIES_FOLDER/face-py-faster-rcnn/caffe-fast-rcnn-* $VGG_FACE_DEPENDENCIES_FOLDER/face-py-faster-rcnn/caffe-fast-rcnn
cd $VGG_FACE_DEPENDENCIES_FOLDER/face-py-faster-rcnn/lib
make
mkdir $VGG_FACE_DEPENDENCIES_FOLDER/face-py-faster-rcnn/data/faster_rcnn_models
cd $VGG_FACE_DEPENDENCIES_FOLDER/face-py-faster-rcnn/data/faster_rcnn_models
wget http://supermoe.cs.umass.edu/%7Ehzjiang/data/vgg16_faster_rcnn_iter_80000.caffemodel

# download SENet modifications to caffe (Sep 2017) and apply them to caffe-fast-rcnn
wget https://github.com/lishen-shirley/SENet/archive/c8f7b4e311fc9b5680047e14648fde86fb23cb17.zip -P /tmp
unzip /tmp/c8f7b4e311fc9b5680047e14648fde86fb23cb17.zip -d $VGG_FACE_DEPENDENCIES_FOLDER/
mv $VGG_FACE_DEPENDENCIES_FOLDER/SENet* $VGG_FACE_DEPENDENCIES_FOLDER/SENet
CAFFE_FASTER_RCNN_FOLDER="$VGG_FACE_DEPENDENCIES_FOLDER/face-py-faster-rcnn/caffe-fast-rcnn"
cp -v $VGG_FACE_DEPENDENCIES_FOLDER/SENet/include/caffe/layers/* $CAFFE_FASTER_RCNN_FOLDER/include/caffe/layers/
cp -v $VGG_FACE_DEPENDENCIES_FOLDER/SENet/src/caffe/layers/* $CAFFE_FASTER_RCNN_FOLDER/src/caffe/layers/

# download models
cd $VGG_FACE_SRC_FOLDER/models
wget http://www.robots.ox.ac.uk/~vgg/data/vgg_face2/256/senet50_256.caffemodel
wget http://www.robots.ox.ac.uk/~vgg/data/vgg_face2/256/senet50_256.prototxt

# download static ffmpeg
wget https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz -O /tmp/ffmpeg-release-amd64-static.tar.xz
tar -xf /tmp/ffmpeg-release-amd64-static.tar.xz -C $VGG_FACE_DEPENDENCIES_FOLDER/
mv $VGG_FACE_DEPENDENCIES_FOLDER/ffmpeg*  $VGG_FACE_DEPENDENCIES_FOLDER/ffmpeg
sed -i "s|ffmpeg|${VGG_FACE_DEPENDENCIES_FOLDER}/ffmpeg/ffmpeg|g" $VGG_FACE_SRC_FOLDER/pipeline/start_pipeline.sh

# remove all zips
rm -rf /tmp/*.zip
rm -rf /tmp/*.tar*

# compile caffe-fast-rcnn
cd $VGG_FACE_DEPENDENCIES_FOLDER/face-py-faster-rcnn/caffe-fast-rcnn
cp Makefile.config.example Makefile.config
sed -i 's/# WITH_PYTHON_LAYER/WITH_PYTHON_LAYER/g' Makefile.config
sed -i 's/\/usr\/include\/python2.7/\/usr\/include\/python2.7 \/usr\/local\/lib\/python2.7\/dist-packages\/numpy\/core\/include/g' Makefile.config
make all
make pycaffe

# compile shot detector
cd $VGG_FACE_SRC_FOLDER/pipeline
mkdir build
cd build
cmake -DBoost_INCLUDE_DIR=/usr/include/ ../
make

# make cv2 available in the virtualenv
ln -s /usr/lib/python2.7/dist-packages/cv2.so $VGG_FACE_SRC_FOLDER/lib/python2.7/cv2.so

# some minor adjustments
sed -i 's/source ..\//source /g' $VGG_FACE_SRC_FOLDER/service/start_backend_service.sh
sed -i 's/source ..\//source /g' $VGG_FACE_SRC_FOLDER/pipeline/start_pipeline.sh
