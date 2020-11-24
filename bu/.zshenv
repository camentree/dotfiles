package_directory="/restricted/projectnb/frares"

export PATH="$package_directory/miniconda3/bin:$PATH"
export JULIA_PKGDIR="$package_directory/simulation/.julia/v0.6"
export JULIA_DEPOT_PATH="$package_directory/simulation/.julia/v1.5"
export R_LIBS="$package_directory/simulation/.R/v4"
export LD_LIBRARY_PATH="$SCC_R_DIR/lib64/R/lib:LD_LIBRARY_PATH"
export CONDA_ENVS_PATH="$package_directory/simulation/.conda/envs"
export CONDA_PKGS_DIRS="$package_directory/simulation/.conda/pkgs"

