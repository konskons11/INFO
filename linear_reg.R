# SET WORKING DIRECTORY
setwd("/mnt/14C608D4C608B7CE/blast/regres/")

# INPUT DATA
reg<- read.csv("linear_reg.tsv", header=F, as.is=T, check.names=FALSE, sep='\t')
fit=lm(mosquito_individuals_ratio~NGS_reads_ratio,data=reg)
summary(fit)

# GENERATE DIAGRAM
plot(reg)
require(ggplot2)
require(ggiraphExtra)
g<-ggplot(reg,aes(y=NGS_reads_ratio,x=mosquito_individuals_ratio))+geom_point(size = 8)+geom_smooth(method = "lm", size=7 )+ 
  theme(panel.grid.major = element_blank(), panel.grid.minor
        = element_blank(),panel.background = element_blank(), axis.line = element_line(colour = "black"))

# SAVE DIAGRAM AS IMAGE
ggsave("reg.png", g,width=40, height=20)
