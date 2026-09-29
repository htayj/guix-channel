;;; GNU Guix package for eidelen/DicomToMesh.

(define-module (tay packages dicom2mesh)
  #:use-module (tay packages starred-d-h)
  #:use-module (guix build-system cmake)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages image-processing))

(define-public dicom2mesh
  (let ((commit "c552b4fd6c6776dab7437f83fb06cb6264f5e831")
        (revision "0"))
    (package
      (name "dicom2mesh")
      ;; Upstream tags no release.  The debian/changelog of the pinned tree
      ;; names this state 0.823.
      (version (git-version "0.823" revision commit))
      ;; Reuse the channel's immutable codeload snapshot of exactly COMMIT
      ;; (Nix-base32 0d3sq4b69iw6hdkgirhfr7bhlf4lsxczk7b9vpi4r1nb5kanwzjf)
      ;; instead of repeating the origin.  The tree has no .gitmodules.
      (source (package-source eidelen-dicomtomesh-source))
      (build-system cmake-build-system)
      (arguments
       (list
        ;; TESTDICOM2MESH and TESTDICOM2MESHLIB each make CMake FetchContent
        ;; GoogleTest v1.17.0 from the network, which the isolated build
        ;; cannot do.  The installed program is exercised by the channel
        ;; smoke test instead.
        #:tests? #f
        #:configure-flags
        #~(list "-DBUILD_GUI=OFF"
                "-DUSE_VTK_DICOM=OFF"
                "-DTESTDICOM2MESH=OFF"
                "-DTESTDICOM2MESHLIB=OFF"
                ;; Fail the configure step rather than reach the network
                ;; should any FetchContent declaration become active.
                "-DFETCHCONTENT_FULLY_DISCONNECTED=ON")
        #:phases
        #~(modify-phases %standard-phases
            (add-after 'unpack 'add-missing-includes
              (lambda _
                ;; These files use std::cout, std::setprecision, and
                ;; unqualified cout/cerr/endl while relying on transitive
                ;; includes that GCC 14 and VTK 9.6 no longer provide.
                (substitute* "lib/src/meshVisualizer.cpp"
                  (("#include \"meshVisualizer\\.h\"" line)
                   (string-append line "\n#include <iomanip>\n#include <iostream>")))
                (substitute* "dicom2mesh/src/dicom2mesh.cpp"
                  (("#include \"volumeVisualizer\\.h\"" line)
                   (string-append line "\n#include <iomanip>\n\n"
                                  "using namespace std;"))))))))
      ;; Upstream calls find_package(VTK REQUIRED) without components, so
      ;; vtk-config.cmake resolves the dependencies of every module in the
      ;; Guix VTK build (Python3, HDF5, Qt, ...).  Mirror VTK's own inputs
      ;; so they stay in step with the upstream Guix package.
      (inputs (modify-inputs (package-inputs vtk)
                (prepend vtk)))
      (home-page "https://github.com/eidelen/DicomToMesh")
      (synopsis "Convert DICOM or PNG image volumes into 3D surface meshes")
      (description
       "dicom2mesh is a command-line tool that builds a 3D surface mesh from a
DICOM image series or from a list of PNG slices.  It extracts an iso surface
from the volume and can reduce, filter, smooth, and center the resulting mesh
before exporting it as an OBJ, STL, or PLY file.  This package builds only
the command-line program; the optional Qt interface and the extended
vtk-dicom reader are disabled.")
      (license license:expat))))
