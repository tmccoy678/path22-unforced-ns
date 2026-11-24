#!/usr/bin/env Rscript

options(digits=17)

args <- commandArgs(trailingOnly = TRUE)
root <- normalizePath(file.path(dirname(sub("^--file=", "", grep("^--file=", commandArgs(), value=TRUE)[1])), ".."))
workbench <- normalizePath(file.path(root, ".."))
out <- file.path(root, "data")
requested_cases <- c("path22_music", "phase_erased_control")
index <- 1L
while (index <= length(args)) {
  if (args[index] == "--out" && index < length(args)) {
    out <- args[index + 1L]
    index <- index + 2L
  } else if (args[index] == "--case" && index < length(args)) {
    requested_cases <- args[index + 1L]
    if (!requested_cases %in% c("path22_music", "phase_erased_control")) stop("unknown --case")
    index <- index + 2L
  } else {
    stop(sprintf("unknown argument: %s", args[index]))
  }
}
dir.create(out, recursive=TRUE, showWarnings=FALSE)

path_file <- file.path(workbench, "riemann-green-spiral", "data", "riemann_paths.tsv")
N <- 64L
box <- 2*pi
dx <- box/N
nu <- 0.01
sigma <- 0.18
target_energy <- 1.0
max_dt <- 0.005
outputs <- c(0, 0.05, 0.10, 0.20, 0.35, 0.50)

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

deposit <- function(score) {
  A <- list(array(0,c(N,N,N)), array(0,c(N,N,N)), array(0,c(N,N,N)))
  for (m in seq_along(sdep)) {
    g <- pdep[m,]/dx
    lo <- floor(g)
    f <- g-lo
    for (bx in 0:1) for (by in 0:1) for (bz in 0:1) {
      w <- (if (bx==0) 1-f[1] else f[1]) *
           (if (by==0) 1-f[2] else f[2]) *
           (if (bz==0) 1-f[3] else f[3])
      ix <- (lo[1]+bx) %% N + 1L; iy <- (lo[2]+by) %% N + 1L; iz <- (lo[3]+bz) %% N + 1L
      for (cpt in 1:3) A[[cpt]][ix,iy,iz] <- A[[cpt]][ix,iy,iz] + w*score[m]*tdep[m,cpt]*quad[m]
    }
  }
  A
}

project <- function(v) {
  dot <- kx*v[[1]] + ky*v[[2]] + kz*v[[3]]
  z <- list((v[[1]]-kx*dot/k2_safe)*mask,
            (v[[2]]-ky*dot/k2_safe)*mask,
            (v[[3]]-kz*dot/k2_safe)*mask)
  for (j in 1:3) z[[j]][1,1,1] <- 0+0i
  z
}

construct <- function(score) {
  A <- deposit(score)
  filt <- exp(-0.5*sigma*sigma*k2)*mask
  ah <- lapply(A, function(x) fftn(x)*filt)
  uh <- list(1i*(ky*ah[[3]]-kz*ah[[2]]),
             1i*(kz*ah[[1]]-kx*ah[[3]]),
             1i*(kx*ah[[2]]-ky*ah[[1]]))
  uh <- project(uh)
  e <- 0.5*sum(vapply(uh, function(x) sum(Mod(x)^2), 0.0))/N^6
  fac <- sqrt(target_energy/e)
  lapply(uh, function(x) x*fac)
}

# Fixed complete-arclength annular contact set.
sr <- unique(c(seq(0,L,by=0.25),L))
pr <- curve(sr); tr <- tangent(sr)
nr <- matrix(0,nrow=length(sr),ncol=3); br <- nr
ref <- diag(3)[which.min(abs(tr[1,])),]
nr[1,] <- unit3(ref-sum(ref*tr[1,])*tr[1,]); br[1,] <- cross3(tr[1,],nr[1,])
for (i in 2:length(sr)) {
  q <- nr[i-1,]-sum(nr[i-1,]*tr[i,])*tr[i,]
  if (sqrt(sum(q*q)) < 1e-10) {
    ref <- diag(3)[which.min(abs(tr[i,])),]
    q <- ref-sum(ref*tr[i,])*tr[i,]
  }
  nr[i,] <- unit3(q); br[i,] <- cross3(tr[i,],nr[i,])
}
theta <- 2*pi*(0:7)/8
radius <- 0.22

interp <- function(a, x) {
  g <- (x %% box)/dx; lo <- floor(g); f <- g-lo; ans <- 0
  for (bx in 0:1) for (by in 0:1) for (bz in 0:1) {
    w <- (if (bx==0) 1-f[1] else f[1]) *
         (if (by==0) 1-f[2] else f[2]) *
         (if (bz==0) 1-f[3] else f[3])
    ans <- ans + w*a[(lo[1]+bx)%%N+1L,(lo[2]+by)%%N+1L,(lo[3]+bz)%%N+1L]
  }
  ans
}

circulation <- function(uh) {
  u <- lapply(uh, ifftn); g <- numeric(length(sr))
  for (i in seq_along(sr)) {
    vals <- numeric(8)
    for (j in 1:8) {
      er <- cos(theta[j])*nr[i,] + sin(theta[j])*br[i,]
      et <- -sin(theta[j])*nr[i,] + cos(theta[j])*br[i,]
      x <- pr[i,] + radius*er
      vals[j] <- sum(vapply(1:3, function(cpt) interp(u[[cpt]],x)*et[cpt],0.0))
    }
    g[i] <- 2*pi*radius*mean(vals)
  }
  g
}

metrics <- function(uh, g0) {
  specsum <- sum(vapply(uh, function(x) sum(Mod(x)^2),0.0))
  energy <- 0.5*specsum/N^6
  divh <- 1i*(kx*uh[[1]]+ky*uh[[2]]+kz*uh[[3]])
  divrms <- sqrt(sum(Mod(divh)^2)/N^6)
  gradrms <- sqrt(sum(k2*(Mod(uh[[1]])^2+Mod(uh[[2]])^2+Mod(uh[[3]])^2))/N^6)
  u <- lapply(uh, ifftn)
  speed <- sqrt(u[[1]]^2+u[[2]]^2+u[[3]]^2)
  gt <- circulation(uh)
  w <- rep(1,length(gt)); w[c(1,length(w))] <- 0.5
  inner <- function(a,b) sum(w*a*b)
  amp <- sqrt(inner(gt,gt)/inner(g0,g0))
  cosine <- inner(gt,g0)/sqrt(inner(gt,gt)*inner(g0,g0))
  c(energy=energy, divergence=divrms/max(gradrms,1e-30), max_speed=max(speed),
    shape_cosine=cosine, amplitude_ratio=amp, retention=max(0,cosine)*min(1,amp))
}

rhs <- function(uh) {
  u <- lapply(uh, ifftn)
  wh <- list(1i*(ky*uh[[3]]-kz*uh[[2]]),
             1i*(kz*uh[[1]]-kx*uh[[3]]),
             1i*(kx*uh[[2]]-ky*uh[[1]]))
  w <- lapply(wh, ifftn)
  rot <- list(u[[2]]*w[[3]]-u[[3]]*w[[2]],
              u[[3]]*w[[1]]-u[[1]]*w[[3]],
              u[[1]]*w[[2]]-u[[2]]*w[[1]])
  nh <- project(lapply(rot, function(x) fftn(x)*mask))
  list(value=lapply(1:3, function(j) nh[[j]]-nu*k2*uh[[j]]),
       max_speed=max(sqrt(u[[1]]^2+u[[2]]^2+u[[3]]^2)))
}

advance <- function(uh, dt) {
  k1 <- rhs(uh)
  mid <- project(lapply(1:3, function(j) uh[[j]] + 0.5*dt*k1$value[[j]]))
  k2r <- rhs(mid)
  project(lapply(1:3, function(j) uh[[j]] + dt*k2r$value[[j]]))
}

run_case <- function(name, score) {
  uh <- construct(score)
  g0 <- circulation(uh)
  rows <- list(); t <- 0; e0 <- metrics(uh,g0)["energy"]
  for (oi in seq_along(outputs)) {
    goal <- outputs[oi]
    while (t < goal-1e-13) {
      r <- rhs(uh)
      dt <- min(max_dt, 0.25*dx/max(r$max_speed,1e-30), goal-t)
      uh <- advance(uh,dt); t <- t+dt
      e <- 0.5*sum(vapply(uh,function(x) sum(Mod(x)^2),0.0))/N^6
      if (!is.finite(e) || e > e0*(1+1e-8)) stop(sprintf("%s energy gate failed at t %.17g",name,t))
    }
    m <- metrics(uh,g0)
    if (any(!is.finite(m)) || m["divergence"] > 1e-10) stop(sprintf("%s diagnostic gate failed at t %.17g",name,t))
    rows[[oi]] <- data.frame(case=name,time=goal,energy=m["energy"],energy_fraction=m["energy"]/e0,
                             normalized_divergence=m["divergence"],max_speed=m["max_speed"],
                             shape_cosine=m["shape_cosine"],amplitude_ratio=m["amplitude_ratio"],retention=m["retention"],
                             trace_pass=(m["shape_cosine"]>=0.5 && m["amplitude_ratio"]>=0.1 && m["retention"]>=0.05))
  }
  do.call(rbind,rows)
}

primary_score <- envelope*(1+0.40*cos(phase))
control_score <- envelope
rows <- list()
if ("path22_music" %in% requested_cases) rows[[length(rows)+1L]] <- run_case("path22_music",primary_score)
if ("phase_erased_control" %in% requested_cases) rows[[length(rows)+1L]] <- run_case("phase_erased_control",control_score)
result <- do.call(rbind, rows)
write.table(result,file.path(out,"evolution.tsv"),sep="\t",row.names=FALSE,quote=FALSE)

hash <- strsplit(system2("/usr/bin/shasum",c("-a","256",path_file),stdout=TRUE)," ")[[1]][1]
meta <- data.frame(metric=c("path_samples","source_arclength","transformed_arclength","domain","resolution","viscosity",
                            "gaussian_sigma","deposit_spacing_max","whisker_ring_spacing_max","whisker_radius",
                            "contacts_per_ring","ring_count","contact_count","minimum_radial_offset","initial_energy_each_case",
                            "body_force","path_input_sha256"),
                   value=c(nrow(p),sprintf("%.17g",L0),sprintf("%.17g",L),"periodic_[0,2pi)^3",N,nu,sigma,0.05,0.25,radius,
                           8,length(sr),8*length(sr),radius,target_energy,"identically_zero",hash))
write.table(meta,file.path(out,"construction.tsv"),sep="\t",row.names=FALSE,quote=FALSE)
for (case_name in requested_cases) {
  cat(sprintf("WRB_NS2_CASE_COMPLETE case=%s final_retention=%.17g\n",
              case_name,tail(result$retention[result$case==case_name],1)))
}
