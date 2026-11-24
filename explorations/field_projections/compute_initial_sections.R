#!/usr/bin/env Rscript

options(digits=17)

script_arg <- grep("^--file=", commandArgs(), value=TRUE)[1]
here <- normalizePath(dirname(sub("^--file=", "", script_arg)))
repo <- normalizePath(file.path(here, "..", ".."))
workbench <- normalizePath(file.path(repo, ".."))
out <- file.path(here, "output")
dir.create(out, recursive=TRUE, showWarnings=FALSE)

# Frozen construction parameters from source/evolve_path22.R.
N <- 64L
box <- 2*pi
dx <- box/N
nu <- 0.01
sigma <- 0.18
target_energy <- 1.0
grid_n <- 161L

cross3 <- function(a,b) c(a[2]*b[3]-a[3]*b[2], a[3]*b[1]-a[1]*b[3], a[1]*b[2]-a[2]*b[1])
unit3 <- function(x) x/sqrt(sum(x*x))
fftn <- function(x) fft(x)
ifftn <- function(x) Re(fft(x, inverse=TRUE)/length(x))

k <- c(0:(N/2-1), seq(-N/2, -1))
kx <- array(rep(k, times=N*N), c(N,N,N))
ky <- array(rep(rep(k, each=N), times=N), c(N,N,N))
kz <- array(rep(k, each=N*N), c(N,N,N))
k2 <- kx*kx + ky*ky + kz*kz
mask <- k2 <= (N/3)^2
k2_safe <- k2
k2_safe[1,1,1] <- 1

path_file <- file.path(workbench, "riemann-green-spiral", "data", "riemann_paths.tsv")
raw <- read.delim(path_file, check.names=FALSE)
p <- raw[raw$path_id == 22, c("x","y","z")]
stopifnot(nrow(p) == 2677, all(is.finite(as.matrix(p))))
d <- sqrt(rowSums((as.matrix(p[-1,]) - as.matrix(p[-nrow(p),]))^2))
s0 <- c(0, cumsum(d))
L0 <- tail(s0,1)
scale <- 0.10
L <- scale*L0
mid <- (apply(p,2,min) + apply(p,2,max))/2
sp <- lapply(p, function(v) splinefun(s0, v, method="natural"))
curve <- function(s) {
  ss <- s/scale
  cbind(pi + scale*(sp[[1]](ss)-mid[1]),
        pi + scale*(sp[[2]](ss)-mid[2]),
        pi + scale*(sp[[3]](ss)-mid[3]))
}
tangent <- function(s) {
  ss <- s/scale
  q <- cbind(sp[[1]](ss, deriv=1), sp[[2]](ss, deriv=1), sp[[3]](ss, deriv=1))
  q/sqrt(rowSums(q*q))
}

sdep <- seq(0, L, length.out=ceiling(L/0.05)+1)
pdep <- curve(sdep)
tdep <- tangent(sdep)
dsdep <- L/(length(sdep)-1)
quad <- rep(dsdep, length(sdep)); quad[c(1,length(quad))] <- dsdep/2
envelope <- sin(pi*sdep/L)^4
phase <- 2*pi*(5*sdep/L + 0.25*sin(2*pi*sdep/L))
primary_score <- envelope*(1+0.40*cos(phase))

deposit <- function(score) {
  A <- list(array(0,c(N,N,N)), array(0,c(N,N,N)), array(0,c(N,N,N)))
  for (m in seq_along(sdep)) {
    g <- pdep[m,]/dx
    lo <- floor(g)
    f <- g-lo
    for (bx in 0:1) for (by in 0:1) for (bz in 0:1) {
      wt <- (if (bx==0) 1-f[1] else f[1]) *
            (if (by==0) 1-f[2] else f[2]) *
            (if (bz==0) 1-f[3] else f[3])
      ix <- (lo[1]+bx) %% N + 1L
      iy <- (lo[2]+by) %% N + 1L
      iz <- (lo[3]+bz) %% N + 1L
      for (cpt in 1:3) {
        A[[cpt]][ix,iy,iz] <- A[[cpt]][ix,iy,iz] + wt*score[m]*tdep[m,cpt]*quad[m]
      }
    }
  }
  A
}

project <- function(v) {
  dot <- kx*v[[1]] + ky*v[[2]] + kz*v[[3]]
  result <- list((v[[1]]-kx*dot/k2_safe)*mask,
                 (v[[2]]-ky*dot/k2_safe)*mask,
                 (v[[3]]-kz*dot/k2_safe)*mask)
  for (j in 1:3) result[[j]][1,1,1] <- 0+0i
  result
}

construct <- function(score) {
  A <- deposit(score)
  filt <- exp(-0.5*sigma*sigma*k2)*mask
  ah <- lapply(A, function(x) fftn(x)*filt)
  uh <- list(1i*(ky*ah[[3]]-kz*ah[[2]]),
             1i*(kz*ah[[1]]-kx*ah[[3]]),
             1i*(kx*ah[[2]]-ky*ah[[1]]))
  uh <- project(uh)
  energy <- 0.5*sum(vapply(uh, function(x) sum(Mod(x)^2), 0.0))/N^6
  factor <- sqrt(target_energy/energy)
  lapply(uh, function(x) x*factor)
}

interp_scalar <- function(a, position) {
  g <- (position %% box)/dx
  lo <- floor(g)
  f <- g-lo
  answer <- 0
  for (bx in 0:1) for (by in 0:1) for (bz in 0:1) {
    wt <- (if (bx==0) 1-f[1] else f[1]) *
          (if (by==0) 1-f[2] else f[2]) *
          (if (bz==0) 1-f[3] else f[3])
    answer <- answer + wt*a[(lo[1]+bx)%%N+1L,
                            (lo[2]+by)%%N+1L,
                            (lo[3]+bz)%%N+1L]
  }
  answer
}

sample_plane <- function(name, center, basis_a, basis_b, limit_a, limit_b, scalar, global_max) {
  a <- seq(-limit_a, limit_a, length.out=grid_n)
  b <- seq(-limit_b, limit_b, length.out=grid_n)
  rows <- vector("list", grid_n*grid_n)
  index <- 1L
  for (j in seq_along(b)) {
    for (i in seq_along(a)) {
      position <- center + a[i]*basis_a + b[j]*basis_b
      value <- interp_scalar(scalar, position)
      rows[[index]] <- data.frame(a=a[i], b=b[j], vorticity=value,
                                  normalized=value/global_max)
      index <- index+1L
    }
  }
  table <- do.call(rbind, rows)
  write.table(table, file.path(out, paste0(name, ".tsv")), sep="\t",
              row.names=FALSE, quote=FALSE)
  table
}

uh <- construct(primary_score)
energy <- 0.5*sum(vapply(uh, function(x) sum(Mod(x)^2), 0.0))/N^6
divh <- 1i*(kx*uh[[1]]+ky*uh[[2]]+kz*uh[[3]])
divrms <- sqrt(sum(Mod(divh)^2)/N^6)
gradrms <- sqrt(sum(k2*(Mod(uh[[1]])^2+Mod(uh[[2]])^2+Mod(uh[[3]])^2))/N^6)
normalized_divergence <- divrms/max(gradrms,1e-30)

wh <- list(1i*(ky*uh[[3]]-kz*uh[[2]]),
           1i*(kz*uh[[1]]-kx*uh[[3]]),
           1i*(kx*uh[[2]]-ky*uh[[1]]))
w <- lapply(wh, ifftn)
omega <- sqrt(w[[1]]^2+w[[2]]^2+w[[3]]^2)
omega_max <- max(omega)

s_mid <- L/2
center <- as.numeric(curve(s_mid))
t_mid <- as.numeric(tangent(s_mid))
endpoints <- rbind(curve(0), curve(L))
horizontal_chord <- c(endpoints[2,1]-endpoints[1,1], endpoints[2,2]-endpoints[1,2], 0)
horizontal_chord <- unit3(horizontal_chord)
vertical <- c(0,0,1)
reference <- diag(3)[which.min(abs(t_mid)),]
normal_1 <- unit3(reference-sum(reference*t_mid)*t_mid)
normal_2 <- unit3(cross3(t_mid,normal_1))

horizontal <- sample_plane("horizontal", center, c(1,0,0), c(0,1,0),
                           pi, pi, omega, omega_max)
vertical_section <- sample_plane("vertical_chord", center, horizontal_chord, vertical,
                                 pi, pi, omega, omega_max)
normal_section <- sample_plane("carrier_normal", center, normal_1, normal_2,
                               1.0, 1.0, omega, omega_max)

path_hash <- strsplit(system2("/usr/bin/shasum", c("-a","256",path_file), stdout=TRUE), " ")[[1]][1]
receipt <- c(
  "PATH 22 UNFORCED NS INITIAL VORTICITY SECTIONS",
  "date=2026-11-24",
  sprintf("resolution=%d",N),
  sprintf("plane_grid=%d",grid_n),
  sprintf("viscosity=%.17g",nu),
  "body_force=identically_zero",
  sprintf("initial_energy=%.17g",energy),
  sprintf("normalized_divergence=%.17g",normalized_divergence),
  sprintf("global_vorticity_max=%.17g",omega_max),
  sprintf("carrier_center=%.17g,%.17g,%.17g",center[1],center[2],center[3]),
  sprintf("carrier_tangent=%.17g,%.17g,%.17g",t_mid[1],t_mid[2],t_mid[3]),
  sprintf("horizontal_plane_max_fraction=%.17g",max(horizontal$normalized)),
  sprintf("vertical_plane_max_fraction=%.17g",max(vertical_section$normalized)),
  sprintf("normal_plane_max_fraction=%.17g",max(normal_section$normalized)),
  "common_scale=global_3d_vorticity_max",
  sprintf("path_input_sha256=%s",path_hash)
)
writeLines(receipt, file.path(out,"receipt.txt"))
cat(paste(receipt, collapse="\n"),"\n")
