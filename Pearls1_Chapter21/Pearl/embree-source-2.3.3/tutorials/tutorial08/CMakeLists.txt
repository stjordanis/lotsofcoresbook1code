## ======================================================================== ##
## Copyright 2009-2014 Intel Corporation                                    ##
##                                                                          ##
## Licensed under the Apache License, Version 2.0 (the "License");          ##
## you may not use this file except in compliance with the License.         ##
## You may obtain a copy of the License at                                  ##
##                                                                          ##
##     http://www.apache.org/licenses/LICENSE-2.0                           ##
##                                                                          ##
## Unless required by applicable law or agreed to in writing, software      ##
## distributed under the License is distributed on an "AS IS" BASIS,        ##
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. ##
## See the License for the specific language governing permissions and      ##
## limitations under the License.                                           ##
## ======================================================================== ##

INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR})

IF (__XEON__ AND BUILD_TUTORIALS)
  ADD_EXECUTABLE(tutorial08 extensions/api.cpp extensions/catmullclark.cpp extensions/subdivisionmesh.cpp extensions/triangulatemesh.cpp tutorial08_device.cpp tutorial08.cpp )

  TARGET_LINK_LIBRARIES(tutorial08 embree tutorial image transport tutorial_device)
ENDIF()

IF (__XEON__ AND BUILD_TUTORIALS_ISPC)
  ADD_ISPC_EXECUTABLE(tutorial08_ispc tutorial08.cpp tutorial08_device.ispc)
  TARGET_LINK_LIBRARIES(tutorial08_ispc embree tutorial image transport tutorial_device_ispc)
ENDIF()

IF (NOT __XEON__ AND __HOST__)
  ADD_EXECUTABLE(tutorial08_xeonphi  tutorial08.cpp )
  TARGET_LINK_LIBRARIES(tutorial08_xeonphi embree tutorial image transport_host)
ENDIF()

IF (NOT __XEON__ AND NOT __HOST__)
  INCLUDE (icc_xeonphi)
  ADD_ISPC_EXECUTABLE(tutorial08_xeonphi_device tutorial08_device.ispc)
  TARGET_LINK_LIBRARIES(tutorial08_xeonphi_device embree_xeonphi transport_device tutorial_xeonphi_device_ispc)
ENDIF()

