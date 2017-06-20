# distutils: language = c++

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

from libcpp.vector cimport vector
from libcpp.string cimport string
import numpy as np
cimport numpy as np
import ctypes
import sys
from exceptions import NotImplementedError

# Metadata
__version__ = "0.0.1"
__author__ = "Disa Mhembere"
__maintainer__ = "Disa Mhembere <disa@jhu.edu>"
__package__ = "knor"

cdef extern from "kmeans_types.hpp" namespace "kpmeans::base":
    cdef cppclass kmeans_t:
        kmeans_t()
        kmeans_t(const size_t, const size_t, const size_t,
                 const size_t, const unsigned*,
                 const size_t*, const vector[double]&)
        const void _print() const
        const void write(const string dirname) const
        void set_params(const size_t nrow, const size_t ncol,
                const size_t iters, const size_t k)
        size_t nrow
        size_t ncol
        size_t iters
        size_t k
        vector[unsigned] assignments
        vector[size_t] assignment_count
        vector[double] centroids

cdef class Pykmeans_t:
    cdef kmeans_t c_kmeans_t      # hold a C++ instance which we're wrapping
    def __cinit__(self, const size_t nrow, const size_t ncol, const size_t iters,
             const size_t k, vector[unsigned]& assignments_buf,
             const vector[size_t]& assignment_count_buf,
             const vector[double]& centroids):
        self.c_kmeans_t = kmeans_t(nrow, ncol, iters, k, assignments_buf.data(),
                assignment_count_buf.data(), centroids)

    def _print(self):
        return self.c_kmeans_t._print()

    def write(self, const string dirname):
        return self.c_kmeans_t.write(dirname)

    def get_nrow(self):
        return self.c_kmeans_t.nrow

    def get_k(self):
        return self.c_kmeans_t.k

    def get_iters(self):
        return self.c_kmeans_t.iters

    def get_ncol(self):
        return self.c_kmeans_t.ncol

    def get_clusters(self):
        return self.c_kmeans_t.assignments

    def get_sizes(self):
        return self.c_kmeans_t.assignment_count

    def get_centroids(self):
        return self.c_kmeans_t.centroids

    def __richcmp__(self, other, int op):
        if op == 2: # 2 is __eq__
            if isinstance(other, self.__class__):
                return np.array_equal(self.get_clusters(),
                        other.get_clusters()) and\
                    np.array_equal(self.get_sizes(), other.get_sizes()) and\
                    np.array_equal(self.get_centroids(),
                            other.get_centroids()) and\
                    np.array_equal(self.get_iters(), other.get_iters())
            else:
                return False

    def set_params(self, const size_t nrow, const size_t ncol,
            const size_t iters, const size_t k):
        return self.c_kmeans_t.set_params(nrow, ncol, iters, k)

# cdef extern from "util.hpp" namespace "kpmeans::base":
    # cpdef get_num_omp_threads()
    # cpdef get_num_nodes()

cdef extern from "knori.hpp" namespace "kpmeans::base":
    kmeans_t kmeans(double* data, const size_t nrow,
        const size_t ncol, const unsigned k, size_t max_iters,
        unsigned nnodes, unsigned nthread,
        double* p_centers, string init,
        double tolerance, string dist_type,
        bint omp, bint numa_opt)

def build_defaults(kwargs):
    DEFAULT_ARGS = {"max_iters": sys.maxint, "nnodes": 1,
        "nthread": 2, "p_centers": None,
        "init": "kmeanspp", "tolerance": -1, "dist_type": "eucl",
        "omp": False, "numa_opt": False}

    for k in DEFAULT_ARGS.iterkeys():
        if k not in kwargs:
            kwargs[k] = DEFAULT_ARGS[k]

def Pykmeans(np.ndarray[double, ndim=2] data,
        centers, **kwargs):
    """
    @type data: numpy.matrixlib.defmatrix.matrix
    @param data: a numpy matrix, ndarray, list
    @param centers: either the pre-initialized centers or the number of centers
    """

    build_defaults(kwargs)
    nrow = np.shape(data)[0]
    ncol = np.shape(data)[1]
    max_iters = kwargs["max_iters"]
    nnodes = kwargs["nnodes"]
    nthread = kwargs["nthread"]
    cdef p_centers = kwargs["p_centers"]
    init = kwargs["init"]
    tolerance = kwargs["tolerance"]
    dist_type = kwargs["dist_type"]
    omp = kwargs["omp"]
    numa_opt = kwargs["numa_opt"]

    # C order only
    if np.isfortran(data):
        data = data.transpose()

    cdef kmeans_t ret
    # Centers in-memory
    if isinstance(centers, int) or isinstance(centers, long):
        ret = kmeans(&data[0,0], nrow, ncol,
                centers, max_iters, nnodes, nthread, NULL,
                init, tolerance, dist_type, omp, numa_opt)
    else:
        raise NotImplementedError("Only numeric centers supported!\n")

    return Pykmeans_t(ret.nrow, ret.ncol, ret.iters, ret.k)
