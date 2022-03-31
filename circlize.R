# SET WORKING DIRECTORY
setwd("/mnt/14C608D4C608B7CE/blast/sankey/")

# IMPORT LIBRARY
library(circlize)

# INPUT DATA
chord<-read.csv("chord.csv", header=T, as.is=T, check.names=FALSE)
table <-read.table('chord2.txt')
mat<-as.matrix(table)
nm = unique(unlist(dimnames(mat)))
group = structure(c("Aedes","Aedes","Aedes","Aedes","Aedes","Aedes","Aedes","Aedes","Culex","Culex","Culex","Culex","Culex","Culiseta","Culiseta","Coquillettidia","Coquillettidia","Anopheles","Anopheles","Anopheles","Anopheles","Anopheles","Anopheles","Uranotaenia"), names = nm)
group

# GENERATE CHORDGRAM
chordDiagram(mat, group =group, annotationTrack = c("name","grid"))
for(si in get.all.sector.index()) {
  xlim = get.cell.meta.data("xlim", sector.index = si, track.index = 1)
  ylim = get.cell.meta.data("ylim", sector.index = si, track.index = 1)
  circos.axis(sector.index =si,major.at=c(0,1,2,3,4),labels.cex=0.5,minor.ticks=0)
    }

