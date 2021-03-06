# ------------------------------------------------------------------------------
#' Script to simulate data, ground truth graphs and noisy priors for individual
#' hotspots
#'
#' @author Johann Hawe
#'
# ------------------------------------------------------------------------------

log <- file(snakemake@log[[1]], open="wt")
sink(log)
sink(log, type="message")

# ------------------------------------------------------------------------------
print("Prep libraries, scripts and params")

library(igraph)
library(graph)
library(BDgraph)

source("scripts/priors.R")
source("scripts/lib.R")
source("scripts/simulation/lib.R")

# ------------------------------------------------------------------------------
# Snakemake params and inputs

# inputs
fdata <- snakemake@input[["data"]]
franges <- snakemake@input[["ranges"]]
fpriors <- snakemake@input[["priors"]]

# outputs
fout <- snakemake@output[[1]]

# params
sentinel <- snakemake@params$sentinel
threads <- snakemake@threads
runs <- 1:as.numeric(snakemake@params$runs)

# ------------------------------------------------------------------------------
print("Loading data.")

data <- readRDS(fdata)
nodes <- colnames(data)
ranges <- readRDS(franges)
priors <- readRDS(fpriors)

# restrict to priors for which we also have data available
priors <- priors[rownames(priors) %in% nodes, colnames(priors) %in% nodes]

# ------------------------------------------------------------------------------
print(paste0("Running ", length(runs), " simulations."))

# we use bdgraph.sim internally, we need to set the number of threads which it
# uses to avoid threading issues:
RhpcBLASctl::omp_set_num_threads(1)
RhpcBLASctl::blas_set_num_threads(1)

simulations <- mclapply(runs, function(x) {
  
  set.seed(x)
  
  # create the hidden and observed graphs
  graphs <- create_prior_graphs(priors, sentinel, threads=1)
  
  print(paste0("Run ", x, " done."))
  
  # simulate data for ggm
  return(simulate_data(graphs, sentinel, data, nodes, threads=1))
  
}, mc.cores = threads)

names(simulations) <- paste0("run_", runs)

# ------------------------------------------------------------------------------
print("Saving results.")

save(file=fout, simulations, priors, ranges, nodes, data,
     runs, fdata, franges, fpriors)

# ------------------------------------------------------------------------------
print("SessionInfo:")
sessionInfo()
sink()
sink(type="message")
