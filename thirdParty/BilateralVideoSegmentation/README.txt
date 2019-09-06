This is a personal reimplementation of the method described in the following paper:

Bilateral Space Video Segmentation
CVPR 2016
Nicolas Maerki, Oliver Wang, Federico Perazzi, Alexander Sorkine-Hornung

The code is released for research purposes only. If you use this software you must
cite the above paper!

This is only a naive implementation of the above paper. It is written for 
clarity of understanding, and is totally unoptimized (i.e. IT'S SLOW!).

Furthermore, the method does no caching at all, and therefore
uses LOTS of memory. Try it out first on small videos, and if you would like to extend it to 
cache information in and out of memory, please feel to commit your changes =). 

-----------------------------------------------------------------------------

GRAPHCUT

This method also uses a third party GraphCut library:
http://vision.csd.uwo.ca/code/

If you use this you have to cite their works as well! Please refer to the
webpage for the most up to date information.


DATA

The datasets included originate from the FBMS-59 dataset: 
http://lmb.informatik.uni-freiburg.de/resources/datasets/

The datasets are provided only for research purposes and without any warranty. 
Any commercial use is prohibited. When using the BMS-26 or FBMS-59 in your 
research work, you should cite the following papers, respectively:

T. Brox, J. Malik
Object segmentation by long term analysis of point trajectories, 
European Conference on Computer Vision (ECCV), September 2010.

P. Ochs, J. Malik, T. Brox
Segmentation of moving objects by long term video analysis, 
IEEE Transactions on Pattern Analysis and Machine Intelligence, 2014.