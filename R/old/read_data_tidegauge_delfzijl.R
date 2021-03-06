#===============================================================================
# read tide gauge data from Delfzijl, The Netherlands
#
# Questions? Tony Wong (twong@psu.edu)
#===============================================================================


#=====================
# function to read the tide gauge data set(s)
read_data <- function(dat.dir, filetype, septype){
  files.tg <- list.files(path=dat.dir, pattern=filetype)
  data <- read.table(paste(dat.dir,files.tg[1],sep=''), header = TRUE, sep=septype)
  if(length(files.tg) > 1) {
    for (ff in 2:length(files.tg)) {
      data <- rbind(data, read.table(paste(dat.dir,files.tg[ff],sep=''), header = TRUE, sep=septype))
    }
  }
  return(data)
}
#=====================


dat.dir <- '~/codes/EVT/data/tide_gauge_Europe/Delfzijl_Oddo_data/'
data <- read_data(dat.dir=dat.dir, filetype='txt', septype='\t')

# convert sea levels from cm to mm, consistent with the other European data
data$sl <- 10* data$sl

year  <- as.numeric(substr(as.character(data$date), start=1, stop=4))
month <- as.numeric(substr(as.character(data$date), start=5, stop=6))
day   <- as.numeric(substr(as.character(data$date), start=7, stop=8))

year.unique <- unique(year)
year.unique <- year.unique[order(year.unique)]
lsl.mean <- rep(NA, length(year.unique))
lsl.max <- rep(NA, length(year.unique))
lsl.mon.mean <- rep(NA, 12*length(year.unique))
lsl.mon.max <- rep(NA, 12*length(year.unique))
data$sl.norm <- data$sl


# TODO
# TODO - fix for data gaps or incomplete years (can check first/last points in the year, or maxikappam difference between two points)
# TODO
# will want to convert all dates/times into a standard format (number of days
# after 1880?)

for (t in 1:length(year.unique)) {
  ind.this.year <- which(year==year.unique[t])
  lsl.mean[t] <- mean(data$sl[ind.this.year])
  data$sl.norm[ind.this.year] <- data$sl[ind.this.year] - lsl.mean[t]
  lsl.max[t] <- max(data$sl.norm[ind.this.year])
}

# skip for now
print('skipping subtracting off average annual cycle for now - can refine later if you want to do anything finer than annual block maxima')
if(FALSE) {
# get an monthyl average annual cycle, for removing annual cycle (by division?)
avg.ann.cycle <- rep(NA, 12)
for (m in 1:12) {
  ind.this.month <- which(month==m)
  avg.ann.cycle[m] <- mean(data$sl.norm[ind.this.month])
}

# get the monthly maxima, subtracting off the annual cycle (so we retain units)
for (t in 1:length(year.unique)) {
  ind.this.year <- which(year==year.unique[t])
  for (m in 1:12) {
    itmp <- (t-1)*12 + m
    ind.this.month <- which(month==m)
    ind.this.year.and.month <- intersect(ind.this.year, ind.this.month)
    lsl.mon.max[itmp] <- max(data$sl.norm[ind.this.year.and.month]-avg.ann.cycle[m])
  }
}
} # end skip for now


# clip to only the years that overlap with the historical temperature forcing
# (1880-2016) only clip beginning; have projection at other end.

if(year.unique[1] <= time_forc[1]) {
  ind.clip <- which(year.unique < time_forc[1])
  year.unique <- year.unique[-ind.clip]
  lsl.max <- lsl.max[-ind.clip]
} else if(year.unique[1] > time_forc[1]) {
  ind.clip <- which(time_forc < year.unique[1])
  time_forc <- time_forc[-ind.clip]
  temperature_forc <- temperature_forc[-ind.clip]
}

# empirical survival function values
esf.levels <- lsl.max[order(lsl.max)]
esf.values <- seq(from=length(lsl.max), to=1, by=-1)/(length(lsl.max)+1)

# set up object for passing through aclibration routines
data_calib <- vector('list', 2); names(data_calib) <- c('year_unique','lsl_max')
data_calib$year_unique <- year.unique
data_calib$lsl_max <- lsl.max

#===============================================================================
# End
#===============================================================================
