#!/usr/bin/env python

# Copyright 2017 neurodata (http://neurodata.io/)
# Written by Disa Mhembere (disa@jhu.edu)
#
# This file is part of knor.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Note these tests only work from the knor repo

from knor import knor
import numpy as np

FN = "../../test-data/matrix_r50_c5_rrw.bin"

def dim_test_c_comp():
    data = np.random.random((10,3))
    return knor.Kmeans(data, 4)

def dim_test_c_im():
    data = np.random.random((10,3))
    centers = np.random.random((3,3))
    return knor.Kmeans(data, centers)

def dexm_test_c_comp():
    centers = 8
    return knor.KmeansEM(FN, centers, nrow=50, ncol=5)

def dexm_test_c_im():
    centers = np.random.random((2,5))
    return knor.KmeansEM(FN, centers, nrow=50, ncol=5)

def test_err():
    try:
        knor.KmeansEM(FN, 7.2, nrow=50, ncol=5)
    except Exception, msg:
        print "Successful test: CORRECTLY fails with message: {}".format(msg)

print "\n\n***************TEST******************\n\n"
print dim_test_c_comp()
print "\n\n***************TEST******************\n\n"
print dim_test_c_im()
print "\n\n***************TEST******************\n\n"
print dexm_test_c_comp()
print "\n\n***************TEST******************\n\n"
print dexm_test_c_im()
print "\n\n***************TEST******************\n\n"
test_err()